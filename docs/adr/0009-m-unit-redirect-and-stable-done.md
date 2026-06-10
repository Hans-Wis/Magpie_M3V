# ADR-0009: M-unit Redirect Kill and Stable Done Contract

Status: **accepted**

Date: 2026-06-08

## Context

J13 enabled the full RV32IMC-noCSR riscv-dv scope after J12 had passed with
load/store and branch/jump. Seed `2026060801` exposed a real pipeline
interaction around the M unit:

- a taken branch at `pc=0x17a4` redirected to `pc=0x17ba`,
- the wrong-path instruction at `pc=0x17a6` was `mulhsu zero,s3,a3`,
- the decode-stage M start asserted in the redirect cycle and stalled fetch,
- the redirected PC was driven, but synchronous instruction memory was not
  enabled, so the target instruction fetch used stale data.

The original `rem s10,s8,gp` failure at `pc=0x1478` was the same risk class as
ADR-0004: M results and completion were observable on a done boundary where the
pipeline had to infer whether the result was stable and still associated with
the instruction that started the operation.

## Decision

The local Magpie_M1 RTL now treats redirects as kills for in-flight decode-side
M starts and gives M-unit completion a stable result contract:

- branch/jump redirects override the normal fetch stall gating,
- decode cannot start a new M operation on redirect or redirect warmup cycles,
- active M state and completed M result-valid state are cleared on redirect,
- `mul` and `div` compute and latch their result before asserting `done`.

The riscv-dv harness also instantiates the core with a reset PC matching the ELF
base so DUT and Spike execute from the same architectural address space.

## Consequences

- `core.v`, `mul.v`, `div.v`, and `ifu.v` are local clean-room RTL deviations
  from copied Ch2 sources.
- M-unit `done` now means the corresponding result is already stable for the
  pipeline to capture.
- Multiply/divide/remainder completion latency increases by one cycle where the
  new stable-done register is used.
- The J13 riscv-dv runner remains RV32IMC with CSR generation disabled; CSR is
  still out of scope for this ADR.
