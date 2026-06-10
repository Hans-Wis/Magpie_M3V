# Phase 3.7 - Mul/Div Hazard Directed Lockstep

Purpose: directly regress the ADR-0004 M-unit result latch and stall/advance
path after Phase 3.5 found a divide writeback mismatch.

This phase stresses:

- back-to-back `mul` / `div` / `rem` operations,
- immediate use of M results by ALU operations,
- M result used as a store data source,
- M result used as a load/store address component,
- load-use around M result consumers,
- branch compare using an M result,
- divide-by-zero and signed overflow architectural corners.

Run:

```sh
make -C flow/v2_pipeline/phase_03_07_muldiv_hazard -B muldiv_hazard.log
python -m pytest tests/gates/gate_03_07_muldiv_hazard.py
```

This is bounded directed DV. It is not random DV, Google RISC-V DV, or coverage
closure.
