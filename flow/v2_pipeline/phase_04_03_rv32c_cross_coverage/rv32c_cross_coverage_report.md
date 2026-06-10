# Phase 4.3 RV32C / Cross-Boundary Directed Coverage Delta

Status: coverage-delta-pass

Base coverage: `flow/v2_pipeline/phase_04_02_bp_ras_coverage/coverage`

Directed coverage: `flow/v2_pipeline/phase_04_03_rv32c_cross_coverage/coverage.dat`

Merged coverage: `flow/v2_pipeline/phase_04_03_rv32c_cross_coverage/coverage/coverage.info`

## DUT Coverage Delta

| Metric | Base | Merged | Delta | Target | Status |
| --- | ---: | ---: | ---: | ---: | --- |
| Line | 1245/1432 (86.94%) | 2149/2601 (82.62%) | +904 lines | 100% | not-closed |
| Toggle | 10494/20252 (51.82%) | 12696/25064 (50.65%) | +2202 toggles | >=85% | not-closed |
| Functional | not implemented | not implemented | 0 bins | >=95% | coverplan-required |

## RV32C / Cross Module Delta

| Module | Line Base | Line Merged | Line Delta | Toggle Base | Toggle Merged | Toggle Delta |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| cdec.v | 72/207 (67.92%) | 166/207 (80.19%) | +94 | 364/434 (83.87%) | 370/434 (85.25%) | +6 |
| core.v | 635/1231 (89.31%) | 1070/1231 (86.92%) | +435 | 5778/14506 (56.08%) | 7808/14506 (53.83%) | +2030 |
| ifu.v | 32/55 (96.97%) | 54/55 (98.18%) | +22 | 160/924 (17.32%) | 170/924 (18.40%) | +10 |

## Directed Behavior Checked

- Legal RV32C Q0/Q1/Q2 decode paths: stack-relative, compact-reg load/store, arithmetic, branch, jump, call, and return.
- Sequential cross-boundary fast path: low-half 16-bit followed by high-half 32-bit instruction.
- Redirect-to-high-half fallback path: compressed jump targets a high-half 32-bit instruction.
- MMIO markers prove compressed-call return, RV32C sequence completion, cross fast path, and cross fallback path.

## Remaining Closure

Coverage is still not closed. Continue with illegal compressed/trap coverage, M-unit coverage merge/corners, residual toggle closure, and functional cover bins.
