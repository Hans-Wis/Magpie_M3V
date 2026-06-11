# Magpie_M1 — DESIGN FREEZE Declaration

Date: 2026-06-11 · Owner: PL (Claude) · User directive: freeze M1, fork M1A.

## Freeze

- **RTL is FROZEN** as of the commit this document lands on (annotated tag **`m1-rtl-freeze-v1.0`**).
  No further edits under `IP/cpu_m1/rtl/` on this line. The 309-gate xfail-free suite, Spike-lockstep
  evidence, and the §01 effective-coverage sign-off snapshots (toggle 92.4% / line 90.0% / branch 93.1%
  / expr 95.3%) refer to this RTL state.
- **Still allowed on M1 after freeze**: documentation, Tier-2 sign-off packaging (SHA-locked DV
  checklist, DV-lead signature flow), evidence re-runs that do not modify RTL. Any such commit must not
  touch `IP/cpu_m1/rtl/`.
- A re-open of M1 RTL (e.g. a customer bug) requires a new ADR + un-freeze declaration + full
  regression; otherwise fixes land on the M1A line.

## Successor line

- **Magpie_M1A** (performance upgrade: pipelined MUL, Zba/Zbb/Zbs+Zicond, TCM/bandwidth, RVV Zve32x,
  TC-GEMV; evaluation in `docs/reports/m1a_performance_evaluation.md`, measured baseline in
  `docs/reports/m1_benchmark_baseline.md`) continues at **`~/project/SOC/Magpie_M1A`** — a
  full-history clone of this repo forked at the freeze tag.
- Identity is hard-separated: M1A uses `design_id = cpu_m1a / magpie_m1a` everywhere; M1A's
  `flow/state` starts EMPTY (fresh evidence only; provenance records the fork SHA). **M1 Tier-2
  evidence is never claimable by M1A** (per §9 evidence-separation; M1A re-earns its own gates).
