# Phase 3.6 - Multi-Seed Random Lockstep and Coverage

Purpose: scale Phase 3.5 from one deterministic pseudo-random seed to a small
reproducible seed ladder, while collecting first-pass Verilator line/toggle
coverage data.

Default seed ladder:

- `20260607`
- `20260608`
- `20260609`
- `20260610`
- `20260611`

Each seed uses `COUNT=48` generated instructions. The grammar is intentionally
constrained:

- RV32I ALU register/immediate operations
- naturally aligned byte/halfword/word load-store
- RV32M multiply/divide/remainder with non-zero divisor register
- optional compressed initialization/move/add instructions
- no privileged state, CSR, interrupt, atomics, self-modifying code, or loops

Run:

```sh
make -C flow/v2_pipeline/phase_03_06_multi_seed_coverage -B multi_seed_coverage.log
python -m pytest tests/gates/gate_03_06_multi_seed_coverage.py
```

Artifacts:

- per-seed runs under `runs/seed_<seed>/`
- `seed_summary.csv`
- `coverage/merged_coverage.dat`
- `coverage/coverage.info`
- `coverage/annotated/`
- `multi_seed_coverage_report.md`

This is still bounded pseudo-random DV, not Google RISC-V DV or coverage
closure. Line coverage remains a measurement here; uncovered lines still need
reason, directed closure, or waiver in a later coverage phase.
