# Phase 3.0 Spike Lockstep

Status: `spike-lockstep-pass` after `make -C flow/v2_pipeline/phase_03_00_spike_lockstep -B lockstep.log`
and `tests/gates/gate_03_00_spike_lockstep.py` pass.

This phase creates the first vertical slice from RTL execution to Spike
architectural comparison. It intentionally starts with a short directed program
instead of random DV.

## Compared Fields

- commit PC
- instruction encoding
- destination register number
- destination writeback data

## Directed Program

The fixture covers:

- compressed `c.li` / `c.addi`
- RV32I integer ALU
- store and load through local RAM
- taken branch
- RV32M `mul`
- `ebreak` terminator, excluded from comparison

## Limits

- No interrupts or CSR comparison in this first lockstep slice.
- No Google RISC-V DV seeds.
- No coverage closure.
- Store side effects are covered indirectly through the subsequent load and
  writeback comparison.
