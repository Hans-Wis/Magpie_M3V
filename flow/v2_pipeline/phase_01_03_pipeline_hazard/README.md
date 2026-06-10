# Phase 1.3 Pipeline Hazard

Status: structural-lint-pass target, not yet directed-sim-qualified.

This phase fixes the first Magpie_M1-owned hazard-control contract for the
active Ch2 lab08e target:

- EX/MEM over EX/WB forwarding priority
- load result exclusion from EX/MEM forwarding
- load-use stall while the producer load is in EX/MEM
- mul/div busy stall while the M unit is active
- IF/EX hold or bubble behavior under stall/flush
- EX/MEM and EX/WB bubble behavior under wrong-path conditions
- data-memory, CSR, and RF write side-effect suppression on redirect/IRQ
- redirect priority and recovery target selection

Current evidence:

- `tests/gates/gate_01_03_pipeline_hazard.py`
- Verilator lint-only on local lab08e RTL top `core`

Not yet closed:

- Directed RAW/load-use/muldiv hazard simulation suite
- Assertion checks for no wrong-path RF/CSR/memory side effects
- VCD-reviewed hazard cases
- Line/toggle/functional coverage
- Spike lockstep
