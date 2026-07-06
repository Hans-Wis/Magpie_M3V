# Magpie_M1A — DESIGN FREEZE Declaration

Date: 2026-06-13 · Owner: PL (Claude) · User directive: freeze M1A, fork M1V (RVV + TC-GEMV).

## Freeze

- **RTL is FROZEN** as of the commit this document lands on (annotated tag **`m1a-rtl-freeze-v1.0`**).
  No further edits under `design/cpu_m1/rtl/` on this line. The Phase-A scalar+memory work this line
  earned — pipelined-MUL issue-decoupling (A1), Zba/Zbb/Zbs+Zicond (A2, `bmu.v`), dual-bank TCM
  (A3, `dtcm.v`) — plus the inherited M1 spine, lockstep evidence, coverage and DC-trial snapshots,
  all refer to this RTL state.
- **Still allowed on M1A after freeze**: documentation, Tier-2 sign-off packaging, evidence re-runs
  that do not modify RTL. Any such commit must not touch `design/cpu_m1/rtl/`.
- A re-open of M1A RTL (e.g. a customer bug, or back-porting an M1V fix) requires a new ADR +
  un-freeze declaration + full regression; otherwise new feature work lands on the M1V line.

## Why freeze here

M1A's scope (ADR-0026) was scalar + memory groundwork (Phase A) with vector/GEMV (Phase B/C) as
ADR-gated future work. The vector (RVV Zve32x) and tightly-coupled GEMV engine are a large,
independent design+verification surface (new EXU, vector hazards, vector-retire lockstep
equivalence, custom-0 decode, DMA double-buffer). Per the User directive (2026-06-13), that work
moves to a dedicated successor line so M1A's scalar/TCM evidence stays clean and frozen as a
deliverable baseline, and M1V can iterate on vector RTL without churning M1A's signed artifacts.

## Successor line

- **Magpie_M1V** (vector / ML-acceleration line: **RVV 1.0 Zve32x VLEN=128 dual-beat** + **TC-GEMV
  int8/int4 custom engine**; scope in `Magpie_M1V/docs/adr/0027-m1v-scope.md`) continues at
  **`~/project/SOC/Magpie_M1V`** — a full-history clone of this repo forked at the
  `m1a-rtl-freeze-v1.0` tag.
- Identity is hard-separated: M1V uses `design_id = cpu_m1v / magpie_m1v` everywhere; M1V's
  `flow/state` starts EMPTY (fresh evidence only; provenance records the fork SHA). **M1A Tier-2 /
  Phase-A evidence is never claimable by M1V** — M1V re-earns its own gates, lockstep, and coverage
  under the new identity (`gate_00_identity_m1v`). Physical path `design/cpu_m1/` is retained to avoid
  churn in Makefiles/gates; identity is by `design_id`, not path.

## Lineage

```
Magpie_M1   (m1-rtl-freeze-v1.0  @4e6e1d4)   RV32IMC scalar 4-stage — frozen Tier-2 baseline
   └─ Magpie_M1A (m1a-rtl-freeze-v1.0)        + pipelined-MUL / Zb* / Zicond / dual-bank TCM — frozen here
        └─ Magpie_M1V                          + RVV Zve32x / TC-GEMV — active vector/ML line
```
