# ADR-0004: M-unit Result Latch for Pipeline v2

Status: **accepted**

Date: 2026-06-07

## Context

Phase 3.5 deterministic random Spike lockstep found the first non-directed
architectural mismatch in the active `lab08e` productization line:

- failing seed: `20260607`
- failing generated program count: `48`
- first mismatch before fix: `div a6, a2, t5`
- expected Spike writeback: `x16 = 0x0000007b`
- observed DUT writeback: `x16 = 0x00000000`

The copied Ch2 `lab08e` core selected the M-unit result through decode-time
state around the `mul`/`div` done boundary. Under the Phase 3.5 random sequence,
the pipeline could advance with an unstable or wrong M-unit result selection.

## Decision

Magpie_M1 now treats the active M operation type and completed result as
pipeline state:

- latch whether the active M operation is divide/remainder or multiply,
- latch the completed M-unit result into `md_result_q`,
- expose `md_result_valid` as the execute-to-memory advance condition,
- clear the valid bit only when the latched result advances into the pipeline.

This makes the writeback source independent of the current decode instruction
once an M operation has started.

## Consequences

- `IP/cpu_m1/rtl/core.v` is now a local Magpie_M1 RTL
  deviation from the copied `lab08e` source.
- Phase 3.4 remains the directed regression for hand-authored RV32IMC/M
  sequences.
- Phase 3.5 is the deterministic random regression that found and closes the
  observed divide-result mismatch for seed `20260607`.
- This does not close all M-extension verification. Additional directed M
  corner tests, more random seeds, Google RISC-V DV, and line/toggle coverage
  are still required before CPU IP qualification.
