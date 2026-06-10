# Phase 4.3 RV32C / Cross-Boundary Directed Coverage

Status: coverage-delta-pass candidate

This phase adds a directed RV32C decode and cross-boundary pre-fetch coverage
test. It is not CPU sign-off closure.

Scope:

- Exercise legal RV32C decode paths across Q0/Q1/Q2 in `cdec.v`.
- Exercise compressed load/store, arithmetic, branch, jump, call, return, and
  stack-relative forms.
- Exercise sequential low-half compressed followed by high-half 32-bit
  instruction, which uses the residue pre-fetch fast path.
- Exercise redirect to high-half 32-bit instruction, which uses the fallback
  cross-boundary path.
- Merge coverage on top of Phase 4.2.

Out of scope:

- Illegal compressed trap semantics.
- Spike lockstep for every compressed corner in this phase.
- Coverage closure. Remaining misses still need directed tests or waivers.
