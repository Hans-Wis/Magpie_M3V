# J19 — nested-trap: verify-then-fix (Grok-informed) — HONEST INTERIM

Status: **INCOMPLETE** (Codex driver run was stopped by PL after >1h: the 20k-commit
serial campaign was too slow to emit even one seed result — this is exactly the
serial-riscv-dv bottleneck the new script-farm decision removes). Codex's harness
edits are landed + syntactically valid; the scaled campaign + final self-revalidation
did NOT complete. Sections below report only what is actually evidenced.

## summary
- Decisive check (Grok-informed): the nested-trap divergence is a HANDLER-DESIGN
  artifact, not a DUT bug — confirmed by Grok's spec opinion and by the fact that the
  previously-failing seeds pass once the handler/ waiver path is in place.
- Codex landed two harness mechanisms in run_riscvdv_lockstep.py:
  `matched_nested_trap_waiver` and `watchdog_trap_waiver` (waive a seed only when the
  per-commit prefix matches up to the nesting point, carrying pc/instr/mcause/mtval +
  Spike-exception evidence).
- Per Codex's run log, the formerly-failing nested-trap seeds now pass/waive cleanly:
  2026061801 (1713 commits, 6 sync-traps), 2026061802/03/04/05 reported clean.

## scope
Sync-trap streams (ecall/ebreak/illegal/misaligned) — smoke-validated on 5 seeds.
Out of scope (unchanged): async interrupts. Timing CSRs excluded-not-faked.
NOT yet done (PL follow-up, Phase 1): (a) replace the fragile write_tohost `dut[:i+2]`
truncation with Grok's safe per-side exit-trim; (b) independently AUDIT the two waiver
functions for masking (producer≠approver — Codex produced, Claude must verify the
prefix truly matches and the waive reason is genuinely the nesting point); (c) the
scaled (>=100k) sync-trap campaign — deferred to the parallel script farm.

## divergences
None confirmed as real DUT bugs in this wave. The nested-trap mismatches are handler
artifacts (waived with evidence). Pending PL audit of the waiver logic before any of
these seeds count toward a zero-divergence claim.

## revalidate
Full gate suite at stop: 182 passed / 1 failed (this gate, due to the interrupted
campaign leaving summary=INCOMPLETE + no finalized result). All other gates green
(gate_02_00/02_02/02_03 trap, gate_02_01 mem_wrapper, gate_03_08 lockstep,
gate_04_08 coverage). Full-mix 100k (J16) artifact stands from before (pre-dates the
budget/truncation harness changes).

## tokens
Codex J19 driver run stopped by PL after ~1h wall-clock (mostly serial riscv-dv gen).
