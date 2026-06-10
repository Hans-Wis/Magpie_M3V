# Phase 4.2 BP/RAS Directed Coverage Delta

Status: coverage-delta-pass

Base coverage: `flow/v2_pipeline/phase_04_01_csr_irq_coverage/coverage`

Directed coverage: `flow/v2_pipeline/phase_04_02_bp_ras_coverage/coverage.dat`

Merged coverage: `flow/v2_pipeline/phase_04_02_bp_ras_coverage/coverage/coverage.info`

## DUT Coverage Delta

| Metric | Base | Merged | Delta | Target | Status |
| --- | ---: | ---: | ---: | ---: | --- |
| Line | 946/1054 (89.75%) | 1245/1432 (86.94%) | +299 lines | 100% | not-closed |
| Toggle | 7904/12246 (64.54%) | 10494/20252 (51.82%) | +2590 toggles | >=85% | not-closed |
| Functional | not implemented | not implemented | 0 bins | >=95% | coverplan-required |

## BP/RAS Module Delta

| Module | Line Base | Line Merged | Line Delta | Toggle Base | Toggle Merged | Toggle Delta |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| bp.v | 51/59 (86.44%) | 59/59 (100.00%) | +8 | 217/872 (24.89%) | 270/872 (30.96%) | +53 |
| ras.v | 12/24 (50.00%) | 21/24 (87.50%) | +9 | 21/660 (3.18%) | 45/660 (6.82%) | +24 |
| core.v | 399/711 (94.55%) | 635/711 (89.31%) | +236 | 3533/10304 (72.43%) | 5778/10304 (56.08%) | +2245 |

## Directed Behavior Checked

- Backward branch loop trains taken history and exits with a not-taken outcome.
- Second backward branch loop exercises another predictor entry.
- Nested `jal ra` calls push multiple return addresses into RAS.
- Nested `ret` instructions pop RAS and return to the caller path.
- MMIO markers prove loop exit, nested call bodies, return path, and second loop completion.

## Remaining Closure

Coverage is still not closed. Continue with RV32C decode corner coverage, M-unit coverage merge/corners, and functional cover bins.
