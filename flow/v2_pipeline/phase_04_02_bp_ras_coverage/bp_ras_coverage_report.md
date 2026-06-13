# Phase 4.2 BP/RAS Directed Coverage Delta

Status: coverage-delta-pass

Base coverage: `flow/v2_pipeline/phase_04_01_csr_irq_coverage/coverage`

Directed coverage: `flow/v2_pipeline/phase_04_02_bp_ras_coverage/coverage.dat`

Merged coverage: `flow/v2_pipeline/phase_04_02_bp_ras_coverage/coverage/coverage.info`

## DUT Coverage Delta

| Metric | Base | Merged | Delta | Target | Status |
| --- | ---: | ---: | ---: | ---: | --- |
| Line | 1329/2071 (64.17%) | 1376/2071 (66.44%) | +47 lines | 100% | not-closed |
| Toggle | 9565/20356 (46.99%) | 9758/20356 (47.94%) | +193 toggles | >=85% | not-closed |
| Functional | not implemented | not implemented | 0 bins | >=95% | coverplan-required |

## BP/RAS Module Delta

| Module | Line Base | Line Merged | Line Delta | Toggle Base | Toggle Merged | Toggle Delta |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| bp.v | 51/59 (86.44%) | 59/59 (100.00%) | +8 | 219/872 (25.11%) | 272/872 (31.19%) | +53 |
| ras.v | 12/24 (50.00%) | 21/24 (87.50%) | +9 | 22/660 (3.33%) | 46/660 (6.97%) | +24 |
| core.v | 620/874 (70.94%) | 639/874 (73.11%) | +19 | 4147/7580 (54.71%) | 4231/7580 (55.82%) | +84 |

## Directed Behavior Checked

- Backward branch loop trains taken history and exits with a not-taken outcome.
- Second backward branch loop exercises another predictor entry.
- Nested `jal ra` calls push multiple return addresses into RAS.
- Nested `ret` instructions pop RAS and return to the caller path.
- MMIO markers prove loop exit, nested call bodies, return path, and second loop completion.

## Remaining Closure

Coverage is still not closed. Continue with RV32C decode corner coverage, M-unit coverage merge/corners, and functional cover bins.
