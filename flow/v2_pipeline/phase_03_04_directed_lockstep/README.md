# Phase 3.4 - Expanded Directed Spike Lockstep

Purpose: scale the bounded Phase 3.0 Spike lockstep slice before moving to
random or Google RISC-V DV stimulus.

This phase keeps the same architectural comparison fields as Phase 3.0:

- commit `pc`
- instruction encoding
- destination register
- writeback data

The directed program expands instruction and microarchitectural coverage:

- RV32C compressed arithmetic and compressed load/store,
- byte/halfword/word memory operations,
- taken and not-taken branches,
- `jal` and `jalr` return path,
- multiply and divide/remainder,
- load-use and forwarding-sensitive producer/consumer chains.

This is still bounded directed DV, not random DV, riscv-dv, or coverage
closure.

Run:

```sh
make -C flow/v2_pipeline/phase_03_04_directed_lockstep -B directed_lockstep.log
python -m pytest tests/gates/gate_03_04_directed_lockstep.py
```
