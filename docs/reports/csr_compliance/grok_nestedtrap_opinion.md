**1. Per RISC-V Privileged Spec (M-mode, sync exception taken from M-mode code)**

Hardware must perform a full trap entry on every synchronous exception, even when already in M-mode:

- `mepc` ← exact virtual address of the instruction that caused the exception (precise).
- `mcause` ← exception code (interrupt bit = 0).
- `mtval` ← appropriate value (address for misaligned/access, 0 or instr bits for illegal/breakpoint, etc.).
- `mstatus`:
  - `MPP` ← 3 (M)
  - `MPIE` ← prior value of `MIE`
  - `MIE` ← 0
- All of the above are **unconditional overwrites**. M-mode has only a single-level "stack" in `mstatus` (MPP/MPIE). There is no deeper hardware nesting for `mepc`/`mcause`.

Synchronous exceptions are taken **regardless of `mstatus.MIE`** (MIE gates only async interrupts). This is explicitly allowed and required behavior; the spec does not suppress or defer sync traps while in M-mode.

**2. SIMPLE handler with no mepc/mcause save/restore across nested trap**

The original `mepc` **is architecturally clobbered**. On the later `mret` (the one the handler intended for the outer trap), `mret` will resume to the PC of the nested faulting instruction (or wherever `mepc` was left after the inner trap), not the original pre-trap PC.

This is **expected hardware behavior**. The divergence (DUT `mret` at 0x1f0e lands at 0x1d9c handler code while Spike's stream ends cleanly) is therefore a **handler-design / test artifact** unless the DUT either:
- took a trap on an instruction that should not have trapped, or
- wrote an incorrect `mepc` value for the nested trap.

If the handler executes any load/store/CSR/memory op that can raise a sync exception (misaligned store, etc.) without first doing `csrr mepc` + save to scratch/stack, the outer return PC is lost by design. Spike will do exactly the same thing on the same instruction sequence.

**3. DUT behavior (mret at 0x1f0e resumes to 0x1d9c)**

It is **consistent with hardware correctly overwriting `mepc` on a nested trap** + the handler not having saved/restored the outer `mepc` before the `mret`.

It does **not** by itself prove a DUT bug. The key observation is that the `mret` instruction itself committed at the same PC (0x1f0e) on both sides; only the *resume PC* differed. That means the value of `mepc` at the moment of `mret` differed.

Possible real bugs (to be proven, not assumed):
- Nested trap taken on an instruction that is legal and should not trap (DUT vs Spike memory/alignment model mismatch).
- `mepc` written with wrong PC on the nested entry (off-by-4/2 regression on the M-mode trap path, PC of the wrong pipeline stage, PC after a compressed instr, etc.).
- `mepc[0]` masking or precise-PC logic not applied on the nested (M-mode) entry path.
- mstatus MPP/MPIE interaction that indirectly affects later `mret` or handler control flow (unlikely to directly change the `mepc` read by `mret`, but can affect MIE on return).

The fact that it only appears with nested traps and that single-trap `mepc` was recently fixed makes the "nested entry path missed the precise-mepc fix" or "different PC source when trap is taken while MPP==M" the leading candidates if a real RTL bug exists.

**4. Root-cause checklist (RTL, focused on csr.v + trap entry + mret)**

Check these 3-5 things in priority order:

1. **Nested trap `mepc` write path**: In the trap-entry logic, is the exact same "precise exception PC" (the PC of the faulting instruction, post any prior fixes) selected for `mepc` when the trap is taken from M-mode (current privilege = M, or `mstatus.MPP == M` at entry) vs from the original mode? Trace the `mepc` write enable and data source for both cases; look for a bypass, a different pipeline register, or "pc+4" logic that only applies on the M-mode path.

2. **Interaction with J17 precise-mepc + mepc[0] fixes**: Confirm the off-by-4 and `[0]` masking logic is exercised on *every* synchronous exception write to `mepc`, including the second (nested) one. Check whether the fix was conditioned on "not in handler" or on a pipeline state that is different after the first `csrrw mscratch`.

3. **mcause / trap cause on the nested instruction**: For the specific instruction whose PC ends up in the post-`mret` commit (the one at/near 0x1d9c), what cause was written? Cross-check against the actual operation (misaligned store? access fault? illegal CSR?). If DUT took a trap here but Spike did not (or vice versa) on identical bytes, this is the primary divergence source.

4. **mret + any intervening CSR writes**: At the `mret` at 0x1f0e, verify `mret` reads the live `mepc` (no write to `mepc` between the nested trap and this `mret` from the handler's `csrrw mscratch` or other ops). Also check that the handler's context-save `csrrw` itself is not accidentally writing `mepc` or that a later handler instruction is not the one that actually clobbered it.

5. **mstatus single-level stack side effects**: After the nested trap, `MPIE` holds the (already-cleared) `MIE`. On the inner `mret` (if any), MIE is restored from that 0. Then the outer `mret` at 0x1f0e sees whatever `MIE` state resulted. While this shouldn't change the PC `mret` produces, it can affect whether subsequent interrupts or handler logic behave differently; capture `mstatus` before/after each trap and the final `mret`.

Most likely real bug (if any): the nested (M-mode) trap entry path in `csr.v` / exception logic did not receive the full precise-`mepc` treatment from J17. Most likely non-bug: the handler executed a faulting op without saving `mepc` first, which is legal but makes the final `mret` return to the nested PC.

**5. DV harness / riscv-dv practice for nested sync traps**

Nested synchronous traps are **generally out of scope** (or treated as noise) for straightforward per-commit instruction-stream lockstep.

Standard practice in riscv-dv + Spike co-simulation:
- The default/generated M-mode handler is intentionally minimal (often a single `csrrw` swap with `mscratch`, a signature write, and `mret` or test termination). It is **not** re-entrant / nesting-safe for arbitrary sync exceptions.
- The generator and harness try to avoid instructions inside the handler that can fault (dedicated safe scratch area, restricted CSR usage, alignment-aware stores, etc.). However, with truly random streams and compressed instructions, seeds can still produce a misaligned load/store, illegal access, or other sync fault inside the handler code.
- When a nested trap occurs, `mepc` (and the return PC of the outer `mret`) is lost unless the handler explicitly saved it. Many setups therefore either:
  - Filter / waive seeds that produce a trap while already in M-mode (detect via `mstatus.MPP==3` at trap time, or by `mepc` landing inside the handler address range).
  - Terminate the test on the first trap (no resume expected inside a long random sequence).
  - Or upgrade the handler to save `mepc`/`mcause`/`mtval` + minimal GPRs before any potentially trapping operation, and restore before the outer `mret`.
- riscv-dv has some support for nested-trap testing in specific configurations, but the basic RV32IMC random-instruction lockstep flows used for "unblocking synchronous traps" typically expect the handler to be effectively non-nesting or to end the test on trap.

**Recommendation for this harness**: Treat seeds that produce a nested sync trap (trap taken while `MPP==M`) as "handler nesting encountered" and either exclude them from the per-commit lockstep comparison or require an upgraded nesting-safe handler (save `mepc` early) before counting them as failures. The current divergence is the classic symptom of a non-nesting-safe handler + random instruction that happens to fault inside it. Only after the handler is hardened (or such cases are filtered) does a remaining mismatch become a credible DUT `mepc`/trap-entry bug.
