# IP/npu — Magpie_M3V net-new NPU domain (cpu_m1-derived, loosely-coupled over AXI)

This directory holds **all net-new NPU + fabric RTL/DV** for the M3V line.

## Architecture (User directive 2026-07-03)

```
cpu_m1 (frozen host, main CPU, AXI4-Lite master)
   │  AXI4-Lite  (control: configure/kick NPU CSRs)
   │  AXI4-full + DMA (data: weight/activation streaming)   ┌── IRQ ──┐
   ▼                                                        │         │
NPU core (= copy of cpu_m1 scalar, MODIFIED)  ──────────────┘         │
   + vector/GEMV/matrix EXU  + local ITCM/DTCM  + AXI slave/master ────┘
```

Two RISC-V cores on an AXI fabric — the CoralNPU SoC shape, but the ML companion is **built from
our own cpu_m1 scalar** (copied + modified), not imported CoralNPU (that is the sibling M1V line).

## Why this directory exists (freeze boundary)

`IP/cpu_m1/` is the **frozen M1A scalar core** (tag `m1a-rtl-freeze-v1.0`) — the *host / main CPU*,
byte-identical to the freeze. The NPU core is a **copy** of that RTL placed here and then modified,
so the frozen host is never touched and the freeze is not violated.

## What goes here (loosely-coupled AXI route, per ADR-0031)

- `rtl/` — NPU core (cpu_m1-derived) + vector/GEMV/matrix EXU + local TCM + AXI slave/master;
  AXI fabric (interconnect, addr decode, AXI4-full + DMA); two-core SoC top.
- `dv/tb/`, `dv/sim/` — testbenches + filelists (NPU scalar lockstep, GEMV cosim, AXI scoreboard, ML e2e).
- `docs/` — NPU microarch, ISA/vector-extension spec, AXI memory map, roofline analysis.

## Verification (SPLIT authority — honest)

- Host cpu_m1: per-commit Spike lockstep (unchanged, frozen).
- NPU scalar spine: standalone Spike lockstep (still cpu_m1-derived → Spike-golden).
- NPU vector/GEMV: Spike `--extension` or bit-accurate C golden model.
- Boundary: AXI transaction scoreboard. System: two-core ML e2e.

## What does NOT go here

- **Not** imported CoralNPU RTL, **not** a tightly-coupled custom-0 unit inside the host pipeline.
  CoralNPU is reference-only (microarch shapes + SW API).

## Status

Scaffold only. No RTL until `docs/adr/0031-m3v-hybrid-npu-scope.md` is accepted and Phase 0
(benchmark baseline + roofline + AXI memory map) is recorded.
