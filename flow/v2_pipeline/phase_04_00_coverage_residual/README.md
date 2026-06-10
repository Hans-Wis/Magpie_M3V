# Phase 4.0 - Coverage Residual Analysis

Purpose: convert Phase 3.6 Verilator coverage measurement into a traceable
residual list before attempting closure.

Input:

- `flow/v2_pipeline/phase_03_06_multi_seed_coverage/coverage/coverage.info`
- `flow/v2_pipeline/phase_03_06_multi_seed_coverage/coverage/merged_coverage.dat`
- `flow/v2_pipeline/phase_03_06_multi_seed_coverage/coverage/annotated/`

Run:

```sh
python3 analyze_coverage.py
python -m pytest tests/gates/gate_04_00_coverage.py
```

Outputs:

- `module_coverage_summary.csv`
- `uncovered_lines.csv`
- `coverage_residual_report.md`

This phase does not close coverage. The current line coverage measurement is
77.61% DUT-only (818 / 1054). The total line coverage including the testbench
is 79.12% (894 / 1130), but testbench coverage is not used as the sign-off
headline.

The current DUT toggle coverage is 61.24% (7500 / 12246), below the >=85%
target. Functional coverage bins are not implemented yet, so the >=95%
functional target remains coverplan-required. Every uncovered line is listed
with a provisional reason, reachability assessment, and closure plan.
