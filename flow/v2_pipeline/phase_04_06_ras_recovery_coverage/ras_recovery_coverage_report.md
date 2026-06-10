# Phase 4.6 RAS Recovery + Pointer Edge Coverage Delta

Status: coverage-delta-pass

Base coverage: `flow/v2_pipeline/phase_04_04_illegal_munit_coverage/coverage`

Directed coverage: `flow/v2_pipeline/phase_04_06_ras_recovery_coverage/coverage.dat`

Merged coverage: `flow/v2_pipeline/phase_04_06_ras_recovery_coverage/coverage/coverage.info`

## DUT Coverage Delta

| Metric | Base | Merged | Delta | Target | Status |
| --- | ---: | ---: | ---: | ---: | --- |
| Line | 1356/1432 (94.69%) | 1363/1432 (95.18%) | +7 lines | 100% | not-closed |
| Toggle | 12672/20252 (62.57%) | 12733/20252 (62.87%) | +61 toggles | >=85% | not-closed |
| Functional | not implemented | not implemented | 0 bins | >=95% | coverplan-required |

## RAS Module Delta

| Module | Line Base | Line Merged | Line Delta | Toggle Base | Toggle Merged | Toggle Delta |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| core.v | 672/711 (94.51%) | 676/711 (95.08%) | +4 | 7279/10304 (70.64%) | 7281/10304 (70.66%) | +2 |
| ras.v | 21/24 (87.50%) | 24/24 (100.00%) | +3 | 50/660 (7.58%) | 105/660 (15.91%) | +55 |

## Directed Behavior Checked

- Core integration firmware poisons `ra` before `ret` to force RAS target mismatch.
- The testbench observes `mem_ras_mispredict` and same-cycle RAS recovery redirect.
- The predicted-return MMIO marker is treated as wrong-path and must not commit.
- A direct `ras` instance covers empty and non-empty same-cycle push+pop pointer edges.

## Remaining Closure

Coverage is still not closed. Continue with CSR high-counter/write coverage, FENCE/FENCE.I, unsigned branch decode/default triage, defensive default assertions/waivers, and functional cover bins.
