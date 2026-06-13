# Phase 4.3 RV32C / Cross-Boundary Directed Coverage Delta

Status: coverage-delta-pass

Base coverage: `flow/v2_pipeline/phase_04_02_bp_ras_coverage/coverage`

Directed coverage: `flow/v2_pipeline/phase_04_03_rv32c_cross_coverage/coverage.dat`

Merged coverage: `flow/v2_pipeline/phase_04_03_rv32c_cross_coverage/coverage/coverage.info`

## DUT Coverage Delta

| Metric | Base | Merged | Delta | Target | Status |
| --- | ---: | ---: | ---: | ---: | --- |
| Line | 1376/2071 (66.44%) | 1412/2071 (68.18%) | +36 lines | 100% | not-closed |
| Toggle | 9758/20356 (47.94%) | 9822/20356 (48.25%) | +64 toggles | >=85% | not-closed |
| Functional | not implemented | not implemented | 0 bins | >=95% | coverplan-required |

## RV32C / Cross Module Delta

| Module | Line Base | Line Merged | Line Delta | Toggle Base | Toggle Merged | Toggle Delta |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| cdec.v | 70/101 (69.31%) | 98/101 (97.03%) | +28 | 364/434 (83.87%) | 370/434 (85.25%) | +6 |
| core.v | 639/874 (73.11%) | 645/874 (73.80%) | +6 | 4231/7580 (55.82%) | 4255/7580 (56.13%) | +24 |
| ifu.v | 22/22 (100.00%) | 22/22 (100.00%) | +0 | 99/462 (21.43%) | 102/462 (22.08%) | +3 |

## Directed Behavior Checked

- Legal RV32C Q0/Q1/Q2 decode paths: stack-relative, compact-reg load/store, arithmetic, branch, jump, call, and return.
- Sequential cross-boundary fast path: low-half 16-bit followed by high-half 32-bit instruction.
- Redirect-to-high-half fallback path: compressed jump targets a high-half 32-bit instruction.
- MMIO markers prove compressed-call return, RV32C sequence completion, cross fast path, and cross fallback path.

## Remaining Closure

Coverage is still not closed. Continue with illegal compressed/trap coverage, M-unit coverage merge/corners, residual toggle closure, and functional cover bins.
