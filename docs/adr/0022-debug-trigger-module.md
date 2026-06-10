# ADR-0022 — Debug Trigger Module (HW breakpoints + watchpoints)

- Status: accepted (design); implementation gated by no-regression + OpenOCD HW-breakpoint smoke
- Date: 2026-06-10
- Deciders: Claude (PL), Grok (core-integration advice). Extends the debug MVD (ADR-0021). Original M1
  `trigger.v` informed by ibex (Apache-2.0, observe+borrow per license-compliant-reuse ADR-0001) + the
  RISC-V Debug Spec mcontrol6.

## Context

The MVD (ADR-0021) gives halt/resume/step + SW breakpoints (ebreak). SW breakpoints can't break in ROM/
flash (read-only code) and can't watch data. The **Trigger Module** adds HW comparators: instruction
breakpoints (PC match) and watchpoints (load/store address match) — non-intrusive, ROM-capable.

## Decision (per Grok + ibex/spec)

- **Module** `IP/cpu_m1/soc/trigger.v` (or rtl/): **4 triggers** (2 execute + 2 load/store), **mcontrol6
  (type=6)** only; `tinfo` advertises type 6. CSRs: `tselect`, `tdata1`(mcontrol6), `tdata2`(compare
  value), `tinfo`. M-only fields used: execute/load/store, **match=0 (exact)**, **action=1 (enter debug)**,
  **m=1**, u/s=0, chain=0, `size` for watchpoints. Skip timing/chaining in v1.
- **EXECUTE trigger** (instruction breakpoint): compare the **correct-path PC in EX** (post-RV32C-
  decompress; NOT fetch PC — wrong-path + cross-boundary residue would false-fire). On match, fire at the
  **WB retire boundary** (same gate as `wb_take_irq`) but **suppress the matched instruction's retire**.
  **`dpc = matched PC`** (not `pc_next`) — spec "before executes" ⇒ the instr never retires.
- **LOAD/STORE trigger** (watchpoint): compare the **effective address in MEM** (post-align/mask);
  "before" semantics — block the WB retire, **`dpc = that load/store's PC`**. RV32C: PC is the compressed
  op's PC; addr compare unchanged.
- **Debug entry**: reuse the MVD `debug_mode`/flush/redirect machinery; add `debug_entry_reason`
  {halt, trigger_exec, trigger_ld, trigger_st}. Halt: `dpc←pc_next`; **trigger: `dpc←triggering PC`**.
- **Anti re-fire** (critical): on a trigger hit, set a **per-trigger suppress/hit** that holds until
  `PC ≠ tdata2` (or `tselect` cleared) — **mandatory on `dret` resume to the same PC**, else instant
  re-entry. Single-step inherently steps off; the HW suppress covers non-step resume.

## Verification (mandatory)
- **Highest-risk corner first** (Grok): EXECUTE trigger on an **RV32C cross-boundary / odd-halfword PC**
  (a `c.*` then a 32-bit instr spanning the residue) — assert the assembled/EX/WB PC vs `tdata2` match and
  `dpc` are all correct (one wrong bit ⇒ illegal-insn or wrong dpc). Same hot-spot as the cross-boundary bugs.
- Directed: set tdata1/tdata2 for a PC trigger → hart halts in debug at that PC (`dpc`=matched), resume
  steps off without re-fire. Watchpoint on a store address → halts on the access (`dpc`=store PC).
- **OpenOCD HW breakpoint**: `bp <addr> 4 hw` (or `reg`/`mwr`) → real OpenOCD sets a HW breakpoint via
  tdata, hart halts at it. (Uses the from-source OpenOCD with remote_bitbang.)
- **No regression**: 273 gates + arch-test 74/74 + MVD/CLINT/PLIC/UART directed unchanged.

## Consequences
- **+** ROM/flash breakpoints + data watchpoints + non-intrusive debug — real embedded debug capability.
- **−** Delicate core change: PC/addr compare taps + trigger→debug-entry with `dpc=triggering PC` + retire
  suppression + anti-re-fire. PL-reviewed; full re-verify. Mitigated by reusing the proven MVD debug-entry path.
