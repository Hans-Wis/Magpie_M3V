# Magpie_M1 DV Plan — Async-Interrupt Lockstep (P1.1) + Length-Delta Triage Gate

**Target**: RV32IMC_Zicsr_Zifencei, M-mode only.  
**Core problem**: interrupts are inherently non-deterministic; length deltas in riscv-dv lockstep are a frequent symptom that must be made deterministic for comparison and then automatically classified when they still occur.

---

## ITEM A — Async-interrupt lockstep (roadmap P1.1)

### Deterministic IRQ Injection (required for any lockstep)

Define the global time base as **architectural retired-instruction count** (only commits that update architectural state and advance the PC past the instruction; speculative / multi-cycle internal steps do not count).

**DUT (Verilator TB) side**:
- Expose/snoop the pipeline commit signal. Maintain a `retired_count` that increments exactly once per retired instruction.
- Stimulus block (parameter or stimulus table) selects one or more injection points: `(inject_at_retire, irq_mask, hold_cycles)`.
- When `retired_count == inject_at_retire` (after the commit of that instruction), the TB drives the requested irq line(s) high: `timer_irq_i` (MTI, mip[7]), `software_irq_i` (MSI, mip[3]), `external_irq_i` (MEI, mip[11]).
- Irq remains asserted until the handler clears the corresponding mip bit (or for a fixed hold time for edge cases). The exact `(inject_at_retire, irq_mask)` tuple is written to the run log and to a side-band memory location the test can read for self-checking.

**Spike side (via spike_ref / cosim harness)**:
- After both models have matched state through `inject_at_retire` and the same instruction has retired on Spike, the harness forces the interrupt into Spike *before* the next `step()`.
- Implementation: `STATE.mip->write_with_mask(irq_mask, irq_mask)` (or equivalent public `processor_t` / `state_t` API) on the target core. This makes mip pending for the *next* instruction fetch.
- Because Spike is single-cycle semantic, the pending interrupt is evaluated on the subsequent instruction exactly as the DUT pipeline will see the now-asserted external irq at its equivalent architectural boundary.

**Sequenced / multiple interrupts**:
- Supply an ordered list of `(retire_count, mask)` tuples. The harness applies them in order on both sides at the matching retired count. This is the only way to get reproducible priority, preemption, and "irq arrives while previous handler still running" scenarios.

Injection at a fixed PC is an acceptable secondary key (used for directed tests), but retire count is primary because it is independent of pipeline timing and branch history.

### Trap / Interrupt State Comparison

Final GPR + CSR snapshot is insufficient. The harness must emit a **trap_event** record on every trap entry and on every `mret`.

Minimum fields per event (produced identically by DUT trace generator and by Spike instrumentation):
- `retire_count` at the point the trap is taken (the instruction whose PC is saved)
- `pc` (interrupted PC → mepc value)
- `mcause` (written by hardware)
- `mepc` (written by hardware)
- `mstatus` before the trap and after (MIE→0, MPIE←old MIE, MPP←M, etc.)
- `handler_entry_pc` (first instruction actually executed in handler)
- On `mret`: `retire_count` of the `mret`, restored `mepc`, restored `mstatus`

The cosim post-processor builds two parallel lists of trap events and requires:
- identical count of entries,
- identical `(mcause, mepc)` tuples in order,
- identical number of instructions executed between each entry and its matching `mret` (handler length),
- final architectural state (x1–x31, mstatus, mie, mip, mepc, mcause, mtvec, mscratch, …) identical after the last `mret`.

Optional but recommended: also record the exact retire count at which the irq line was asserted vs. the retire count at which the trap was taken (latency check).

### riscv-dv Configuration for Interrupt Tests

Use a dedicated config (or `directed_interrupt` + `random_interrupt` mix):
- `enable_interrupt: 1`
- `m_mode_interrupt: 1`
- `interrupt_handler: <M-mode only handler>` (generated or hand-supplied). Handler must be minimal, save/restore only live registers, clear the specific mip bit for level-triggered irqs, then `mret`. For priority/nesting tests the handler deliberately re-enables MIE.
- `no_ebreak` / `no_ecall` unless intentionally testing those codes alongside interrupts.
- For WFI coverage: generate tests containing `wfi`; the deterministic injector asserts the irq a few instructions after the `wfi` retires.
- For compressed-boundary coverage: the generator must emit both 16-bit and 32-bit instructions around the chosen injection points (or the injector must be allowed to land on any retire count).

Directed seeds are used first for each individual irq type + MIE=0/1 + mie bit off + compressed landing + mul/div landing + WFI. Random seeds with retire-count injection are used for regression volume.

### Pass Criteria

A seed is considered a lockstep pass only when **all** of the following hold:
1. Commit-by-commit architectural match (PC, instr, GPR write data, CSR write data) up to the first injection point.
2. Trap event lists are identical (count, mcause, mepc, handler length).
3. Final state after all `mret`s matches.
4. The test program itself writes a PASS code to tohost.
5. No un-handled pending interrupts remain at the end unless the test intentionally left them.

Any length delta or trap mismatch causes the seed to be routed through the length-delta triage gate (ITEM B) before it can be labeled pass or benign.

### Likely Pitfalls

- **MIE / mie write timing**: a CSR write that sets MIE=1 on the same retire count that an irq is injected can be sampled before or after the write depending on pipeline stage vs. Spike’s evaluation point.
- **Compressed mepc**: mepc must point exactly at the 16-bit or 32-bit interrupted instruction (PC values are always halfword-aligned; bit 0 is always 0). Off-by-2 or odd mepc produces wrong resume or illegal-instruction on re-fetch.
- **Multi-cycle ops (mul/div/iterative div)**: the interrupt must be taken after the op retires, with mepc pointing at the *next* instruction. Taking it with mepc still on the mul/div itself is a bug.
- **Priority**: when multiple bits are set in mip and enabled in mie with MIE=1, the taken mcause must be deterministic and match the documented priority (MEI usually highest, then MSI/MTI; implementation must be consistent).
- **mret on wrong path / during flush**: an mret in the shadow of a mispredict or pipeline flush must not commit.
- **Handler re-entrancy**: if the handler re-enables MIE, a second irq (still pending) produces a nested trap before the first mret. The triage must distinguish this from a real resume bug.
- **tohost reachable from handler**: an early or erroneous branch to tohost from inside a handler produces a length delta that looks like “test passed” but hid a control-flow error.
- **Retire definition skew**: Spike’s `insn_retired` vs. DUT’s commit signal must count exactly the same instructions (no bubbles, no traps counted twice, no debug steps).
- **First few instructions**: crt0 / mtvec setup / stack initialization must be identical before any injection is attempted.

---

## ITEM B — "length-delta triage" automated gate

**Purpose**: Before any riscv-dv seed that produced a commit-count delta is labeled pass or "benign", force a deterministic one-line root-cause classification based on the last ~10 commits of each side. The classification is machine-readable and becomes part of the seed artifact and gate log.

### Data Captured (mandatory)

The lockstep run must emit two commit logs (one per model) with at minimum these columns per retired instruction:

```
retire_id,pc_hex,instr_hex,rd,rd_val_hex,csr_addr,csr_val_hex,mcause,mepc_hex,priv
```

In addition, at end-of-test (first side writes tohost or hits max_instr) the following metadata is captured:
- `final_retire_dut`, `final_retire_spike`
- `tohost_addr` (from test binary or constant), `tohost_written_by`, `tohost_value`
- `final_mstatus`, `final_mie`, `final_mip`, `final_mcause`, `final_mepc` (both sides)
- `mtvec` value programmed by the test
- `first_divergence_retire` = smallest i where the retired PC or instr at retire i differs (or 0 if only final counts differ)

The triage script receives the tail of 10 commits (or fewer) from each log ending at the respective final retire, plus the metadata block.

### Decision Rules (executed in order; first match wins)

All comparisons are on the captured tail + metadata. No disasm required beyond "is this a branch/jump/mret/csrw to mstatus/mie/mip" (can be done from instr bits or a tiny static table).

1. **early-tohost-bad-branch**  
   `tohost_addr` appears in one tail’s PC list and the immediately preceding instruction is a taken branch/jump (jal, jalr, any conditional branch that resolved taken, or C equivalent). The other side’s tail at the corresponding retire range does not contain tohost.  
   Output: `LENGTH_DELTA: early-tohost-bad-branch @retire=NNN (DUT PC=0x80001234 branch to tohost; Spike continued mainline)`

2. **handler-length-diff**  
   Exactly one side shows an extra trap entry (mcause written in its tail) whose handler execution length (commits between that entry and the next mret in the same tail) accounts for ≥80 % of the observed delta, and the PCs of the extra segment lie inside the [mtvec, mtvec+handler_max] region.  
   Output: `LENGTH_DELTA: handler-length-diff (delta=+9; DUT 11 instr in MTI handler @mepc=0x80000f10, Spike 2 instr before mret)`

3. **nested-trap-resume**  
   The longer tail contains more mret records than the shorter tail, or contains a second mcause write between a prior mcause and its matching mret, and a recent CSR write in the window set mstatus.MIE=1.  
   Output: `LENGTH_DELTA: nested-trap-resume (DUT mcause seq 0x80000007 then 0x80000003 inside handler before mret)`

4. **mepc-compressed-boundary**  
   delta ∈ {1,2}, at least one of the last mcause/mepc pairs has mepc whose low bits are inconsistent with the instruction length at that address (16-bit instr with mepc ending 0b00 vs 0b10, or mepc bit 0 set), or the resume PC after mret on one side lands inside a 32-bit instruction.  
   Output: `LENGTH_DELTA: mepc-compressed-boundary (mepc=0x8000123e vs 0x80001240 around 16-bit instr)`

5. **muldiv-interrupt-timing**  
   The instruction at the mepc of the last trap (or the instruction immediately before divergence) is a mul/mulh/mulhu/div/rem/remu (or C form), and the two sides disagree on whether mepc points at that instruction or at the following one.  
   Output: `LENGTH_DELTA: muldiv-interrupt-timing (mepc inside M-cycle op)`

6. **mie-mstatus-sampling**  
   A CSR write to mstatus or mie (or immediate form) appears in the 3 commits before the last trap on one side, the irq was injected within ±2 retires of that write, and exactly one side took the trap on the instruction following the CSR write while the other executed one more mainline instruction.  
   Output: `LENGTH_DELTA: mie-mstatus-sampling (irq sampled before vs after MIE write)`

7. **unknown-divergence** (fallback)  
   Emit the raw delta, the last 3 PCs+instrs from each tail, and the last non-zero mcause/mepc from each side.  
   Output: `LENGTH_DELTA: unknown-divergence (delta=+14; DUT last PCs 0x8000f0a0/0x8000f0a4/... Spike 0x8000f0a0/0x80001000(tohost))`

### Integration into the Gate

- The triage script is invoked by the spike_lockstep gate (or the riscv-dv regression driver) for every seed where `abs(final_retire_dut - final_retire_spike) > 0` (or >1 if a documented 1-instr WFI artifact is tolerated).
- It prints exactly one `LENGTH_DELTA: ...` line and writes a small `triage_delta.json` containing the classification, the 10-line windows, and the metadata.
- The gate treats any classification that is not in a (initially empty) benign whitelist as a hard failure for that seed. Adding a class to the benign whitelist requires manual review + justification recorded in the gate log or an ADR note.
- The classification string is the primary field shown in batch regression summaries and in the IDE gate matrix.

This turns every length delta into an immediately actionable, reproducible symptom instead of an opaque "counts differed" failure.
