# Magpie_M1 v2 pipeline IP target — Ch2 lab08e

This directory contains the Ch2 `lab08e` RTL copied as the Magpie_M1 v2
pipeline IP target reference.

- Source: `~/project/lab/CPU/Ch2/lab08e/rtl`
- Copied on: 2026-06-07
- Variant status: active-signoff-baseline, not yet Magpie_M1 qualified RTL
- ISA family: RV32IMC + Zicsr + Zifencei
- Microarchitecture: 4-stage pipeline + BP + RAS + RV32C + pre-fetch buffer
- Reported Ch2 FPGA target: 85 MHz formal PASS, WNS +0.017 ns
- Key units: `core`, `ifu`, `idu`, `cdec`, `alu`, `lsu`, `rfu`, `csr`,
  `mul`, `div`, `forward`, `hazard`, `bp`, `ras`

The intent is to turn lab08e from a lab result into a reusable Magpie_M1 CPU IP
variant. This requires hardening around IP interfaces, commit trace, DV,
coverage, lint, FPGA/PPA, and customer handoff evidence.

Required IP-hardening work:

- Wrap the synchronous Ch2 I/D memory ports into the Magpie_M1 valid-ready
  `imem`/`dmem` contract or explicitly ADR the v2 memory protocol.
- Define one architectural commit trace for RV32IMC Spike lockstep.
- Add directed tests for compressed fetch/decode, cross-boundary pre-fetch,
  RAS return prediction, branch predictor redirect, RAW forwarding, load-use
  stall, mul/div busy stall, flush, wrong-path suppression, CSR/trap, and IRQ
  timing.
- Add line/toggle/function coverage closure and residual analysis.
- Add FPGA-based PPA reports as tracked evidence, not just lab notes.
