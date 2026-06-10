# Phase 4.4 Illegal Compressed Trap + M-Unit Coverage Delta

Status: coverage-delta-pass

Base coverage: `flow/v2_pipeline/phase_04_03_rv32c_cross_coverage/coverage`

Directed coverage: `flow/v2_pipeline/phase_04_04_illegal_munit_coverage/coverage.dat`

Merged coverage: `flow/v2_pipeline/phase_04_04_illegal_munit_coverage/coverage/coverage.info`

## DUT Coverage Delta

| Metric | Base | Merged | Delta | Target | Status |
| --- | ---: | ---: | ---: | ---: | --- |
| Line | 1285/1432 (89.73%) | 1356/1432 (94.69%) | +71 lines | 100% | not-closed |
| Toggle | 11004/20252 (54.34%) | 12672/20252 (62.57%) | +1668 toggles | >=85% | not-closed |
| Functional | not implemented | not implemented | 0 bins | >=95% | coverplan-required |

## Illegal/M-Unit Module Delta

| Module | Line Base | Line Merged | Line Delta | Toggle Base | Toggle Merged | Toggle Delta |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| cdec.v | 101/106 (95.28%) | 106/106 (100.00%) | +5 | 370/434 (85.25%) | 370/434 (85.25%) | +0 |
| core.v | 645/711 (90.72%) | 672/711 (94.51%) | +27 | 6239/10304 (60.55%) | 7279/10304 (70.64%) | +1040 |
| div.v | 65/92 (70.65%) | 88/92 (95.65%) | +23 | 489/1166 (41.94%) | 753/1166 (64.58%) | +264 |
| mul.v | 35/43 (81.40%) | 43/43 (100.00%) | +8 | 653/1014 (64.40%) | 915/1014 (90.24%) | +262 |

## Directed Behavior Checked

- M-unit signed/unsigned multiply variants and divide/remainder corner behavior.
- Divide-by-zero and signed overflow results are checked in firmware before the marker store.
- Legal `C.JALR` decode path is executed before the M-unit completion marker.
- Illegal compressed reserved/RV32-invalid/default encodings propagate to the terminal trap path.

## Remaining Closure

Coverage is still not closed. Continue with residual line/toggle triage, functional cover bins, and final waiver review for structurally unreachable or out-of-scope behavior.
