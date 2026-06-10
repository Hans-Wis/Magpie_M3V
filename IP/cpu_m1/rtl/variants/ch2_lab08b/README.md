# Magpie_M1 v2 pipeline reference — Ch2 lab08b

This directory contains the Ch2 `lab08b` RTL copied as the first Magpie_M1 v2
pipeline integration baseline.

- Source: `~/project/lab/CPU/Ch2/lab08b/rtl`
- Copied on: 2026-06-07
- Variant status: reference-integration, not Magpie_M1 sign-off RTL
- ISA family: RV32IM + Zicsr
- Microarchitecture: 4-stage pipeline with branch prediction
- Key units: `core`, `ifu`, `idu`, `alu`, `lsu`, `rfu`, `csr`, `mul`, `div`,
  `forward`, `hazard`, `bp`

This variant is intentionally separate from the v1 multi-cycle FSM path. v1
remains the active sign-off baseline until the v2 pipeline wrapper, gates,
Spike lockstep, coverage, and lint/PPA evidence are closed.

Known integration work before v2 qualification:

- Wrap the synchronous Ch2 I/D memory ports into the Magpie_M1 valid-ready
  `imem`/`dmem` contract.
- Define one architectural commit trace for Spike lockstep.
- Add directed tests for RAW forwarding, load-use stall, mul/div busy stall,
  redirect, flush, wrong-path suppression, CSR/trap, and IRQ timing.
- Add coverage and lint gates for this variant.
