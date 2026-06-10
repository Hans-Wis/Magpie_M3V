# Phase 3.5 - Deterministic Random Spike Lockstep

Purpose: scale from directed lockstep to reproducible pseudo-random RV32IMC
stimulus before adopting Google RISC-V DV.

This phase uses a local deterministic generator:

- fixed seed by default: `SEED=20260607`
- bounded instruction count by default: `COUNT=48`
- generated assembly artifact: `firmware.S`
- generator source: `gen_random_program.py`

The grammar is intentionally constrained:

- RV32I ALU register/immediate operations
- naturally aligned byte/halfword/word load-store
- RV32M multiply/divide/remainder with non-zero divisor register
- optional compressed initialization/move/add instructions
- no privileged state, CSR, interrupt, atomics, self-modifying code, or loops

Run:

```sh
make -C flow/v2_pipeline/phase_03_05_random_lockstep -B random_lockstep.log
python -m pytest tests/gates/gate_03_05_random_lockstep.py
```

This remains bounded pseudo-random DV, not Google RISC-V DV or coverage
closure.
