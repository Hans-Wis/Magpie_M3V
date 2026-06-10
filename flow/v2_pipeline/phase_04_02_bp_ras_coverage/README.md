# Phase 4.2 - BP/RAS Directed Coverage Closure

Purpose: add targeted branch predictor and return-address-stack stimulus to the
Phase 4.1 merged coverage baseline and report DUT-only line/toggle coverage
delta.

Run:

```sh
make -C flow/v2_pipeline/phase_04_02_bp_ras_coverage -B bp_ras_coverage.log
python -m pytest tests/gates/gate_04_02_bp_ras_coverage.py
```

Directed behavior:

- backward branch loop trains taken history and exits with a not-taken outcome
- a second branch loop exercises another predictor entry
- nested `jal ra` calls push RAS entries
- nested `ret` instructions pop RAS and return to the caller path
- MMIO markers prove loop exit, nested call bodies, return path, and second
  loop completion

Coverage accounting:

- Baseline is Phase 4.1 merged coverage.
- Sign-off headline is DUT-only; testbench coverage is excluded.
- This phase is coverage closure progress, not coverage closure.

Outputs:

- `sim.log`
- `coverage.dat`
- `coverage/merged_with_phase_04_02.dat`
- `coverage/coverage.info`
- `module_delta.csv`
- `bp_ras_coverage_report.md`
- `wave.vcd`
