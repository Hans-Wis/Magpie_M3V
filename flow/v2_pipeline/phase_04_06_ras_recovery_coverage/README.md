# Phase 4.6 RAS Recovery + Pointer Edge Coverage

Status: coverage-delta-pass

This phase targets the Phase 4.5 residual RAS lines:

- `core.v` RAS target mispredict recovery.
- `ras.v` same-cycle push+pop empty/non-empty pointer edges.

The core integration program intentionally poisons `ra` before a `ret`. IF predicts
the normal return address from RAS, while EX resolves the actual `jalr` target to
`actual_return`. The testbench requires `mem_ras_mispredict`, the RAS recovery
redirect, and the actual-return MMIO marker. The predicted-return marker is a
wrong-path side effect and fails the test if it commits.

A direct `ras` instance in the same simulation covers pointer-edge behavior that
firmware cannot naturally generate in the 4-stage pipeline.

Coverage is merged on top of Phase 4.4. This phase is still coverage closure
work, not final sign-off: functional bins and remaining CSR/FENCE/branch/default
residuals are outside this phase.
