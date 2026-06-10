# Phase 4.0 Coverage Residual Analysis

Status: residual-analysis-pass

Input coverage: `flow/v2_pipeline/phase_03_06_multi_seed_coverage/coverage/coverage.info`

DUT line coverage: 818 / 1054 (77.61%)

Total line coverage including testbench: 894 / 1130 (79.12%)

DUT uncovered lines: 236

Total uncovered lines including testbench: 236

DUT toggle coverage: 7500 / 12246 (61.24%)

Total toggle coverage including testbench: 7971 / 12830 (62.13%)

Coverage closure status: not closed. Line coverage target remains 100%.

Toggle coverage target is >=85%; current value is measured but not closed.

Functional coverage target is >=95%; functional cover bins are not implemented yet.

The sign-off headline excludes testbench coverage. Testbench coverage is tracked only as supporting data.

## Coverage Target Status

| Metric | Target | Current | Status |
| --- | ---: | ---: | --- |
| DUT line | 100% | 77.61% | not-closed |
| DUT toggle | >=85% | 61.24% | measured-not-closed |
| Functional | >=95% | not implemented | coverplan-required |

## Category Counts

| Category | Count |
| --- | ---: |
| bp_ras_redirect | 59 |
| csr_irq_trap | 58 |
| directed_gap | 57 |
| hazard_forwarding | 3 |
| m_extension_corner | 9 |
| reset_or_interface | 6 |
| rv32c_corner | 44 |

## Reachability Counts

| Reachability | Count |
| --- | ---: |
| environment_limited | 6 |
| reachable | 230 |

## Module Summary

| Module | Scope | Line Hit / Total | Line % | Toggle Hit / Total | Toggle % | Uncovered |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| core.v | dut | 349 / 422 | 82.70% | 3332 / 4878 | 68.31% | 73 |
| csr.v | dut | 43 / 91 | 47.25% | 208 / 1288 | 16.15% | 48 |
| cdec.v | dut | 63 / 106 | 59.43% | 359 / 434 | 82.72% | 43 |
| bp.v | dut | 34 / 59 | 57.63% | 197 / 872 | 22.59% | 25 |
| idu.v | dut | 74 / 91 | 81.32% | 583 / 678 | 85.99% | 17 |
| ras.v | dut | 12 / 24 | 50.00% | 21 / 660 | 3.18% | 12 |
| div.v | dut | 62 / 71 | 87.32% | 488 / 686 | 71.14% | 9 |
| ifu.v | dut | 16 / 22 | 72.73% | 56 / 462 | 12.12% | 6 |
| alu.v | dut | 29 / 31 | 93.55% | 536 / 542 | 98.89% | 2 |
| hazard.v | dut | 16 / 17 | 94.12% | 63 / 66 | 95.45% | 1 |
| forward.v | dut | 28 / 28 | 100.00% | 448 / 448 | 100.00% | 0 |
| lsu.v | dut | 43 / 43 | 100.00% | 396 / 396 | 100.00% | 0 |
| mul.v | dut | 33 / 33 | 100.00% | 587 / 610 | 96.23% | 0 |
| rfu.v | dut | 16 / 16 | 100.00% | 226 / 226 | 100.00% | 0 |
| tb_random_lockstep.v | testbench | 76 / 76 | 100.00% | 471 / 584 | 80.65% | 0 |

## Residual List

Every uncovered line is listed in `uncovered_lines.csv` with reason, reachability, closure plan, owner/date, and waiver status.

## Next Closure Actions

- Merge Phase 3.7 directed M-unit hazard coverage into the coverage database.
- Add directed CSR/trap/IRQ coverage tests using Phase 2.0/3.1 programs.
- Add BP/RAS/redirect directed coverage tests.
- Add RV32C quadrant/funct3 legal and illegal decode vectors.
- Add functional coverage bins for ISA class, trap cause, redirect type, forwarding source, and M-unit corner bins.
