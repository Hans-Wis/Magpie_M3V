# Phase 2.1 mem_wrapper — Codex independent review + Claude triage

- Producer: Claude Code. Reviewer: Codex (gpt-5.5, read-only, ~105k Codex tokens).
- Verdict (Codex): issues-found (3). Triage (Claude): 1 doc-clarified, 1 false-positive (disproven), 1 accepted-minor.

| id | sev | finding | triage | resolution |
|----|-----|---------|--------|------------|
| F1 | P1 | Waited D access could re-issue after ready → duplicate store on bus (MMIO-unsafe) | **FALSE POSITIVE (disproven)** | `ex_mem_advance_to_wb` fires whenever `!mem_stall`, so a store leaves EX/MEM the same cycle it issues — never "held in EX/MEM after issuing". Empirical: accepted D-write bus xfers = **6, constant across all wait modes incl. concurrent I+D waits** (Codex's exact scenario). Locked in as a standing assertion in `run_equiv.sh` (`dw_ok`). |
| F2 | P1 | `mcycle` (cycle_cnt) increments during `mem_stall` → not suppressed | **NOT A BUG (spec-correct), documented** | RISC-V `mcycle` counts elapsed clock cycles; wait cycles are real elapsed cycles, so it must keep counting. It is a free-running counter, not an instruction-commit effect. `minstret` *is* gated (latency-independent). Equivalence/Spike lockstep compares `{pc,rd,wdata}` and excludes timing CSRs. Documented as the intentional freeze exception in ADR-0005. |
| F3 | P2 | Boot-prime not reset-clean: `primed` X before first reset edge; `primed<=1` outside reset `else` can override reset assign | **ACCEPTED (minor)** | The NBA override is intentional (prime the reset vector during reset, like the native always-on BRAM). Verilator 2-state inits regs to 0; reset is asserted at power-on, so the X-before-reset window is not exercised. Left as-is; revisit if a 4-state/gate-level run needs it. |

## not-covered (Codex) — status
- tb counted only `{pc,rd,wdata}` → **now also counts D-write bus xfers** (F1 invariant). ✔
- timing CSRs (`mcycle`) under waits → out of equivalence scope by design (ADR-0005). ✔ documented
- dedicated misalign program / mcause 4-6 assertion → **open** (misalign logic exercised indirectly + bug fixed; a directed misalign test is a follow-up).
- cycle/bit-identical 0-wait (only commit-stream proven) → acceptable; 0-wait collapses to native by construction.
- MMIO / non-idempotent stores → **open** (RAM-only fixture); covered once a peripheral/bus is attached.
- bare-core==Spike proven separately (81-commit lockstep re-run), not by tb_equiv. ✔ acknowledged
