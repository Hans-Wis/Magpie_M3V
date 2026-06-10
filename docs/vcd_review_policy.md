# Magpie_M1 VCD Review Policy

VCD is a review artifact, not a raw dump by default. Each phase must define what
the reviewer needs to decide before choosing trace depth, scopes, and dump
windows. The goal is enough observability to debug the phase intent without
turning every regression into a full hierarchy waveform.

## Rules

1. Every simulation phase that produces a VCD must provide a phase-local
   `vcd_manifest.md`.
2. The manifest must list review questions, required signals, dump windows,
   default trace settings, full-debug settings, and known blind spots.
3. The default VCD must include all required signals from the manifest.
4. The default VCD should avoid full core hierarchy tracing unless the phase
   explicitly needs it.
5. A full-debug escape hatch must exist for deep triage.
6. The gate must check VCD existence, required signal presence, and a reasonable
   size envelope.
7. If a VCD is simplified, the report must state what was intentionally omitted.

## Phase Defaults

| Phase | Default intent | Required default visibility | Typical window | Full-debug trigger |
|---|---|---|---|---|
| 1.1 fetch/RV32C/pre-fetch smoke | Confirm boot progress, compressed boot sequence, I-port activity, LED MMIO, BTN1 IRQ reset | TB controls, LED, reset, IRQ pulse, I/D memory ports, wrapper-level `dbg_pc/dbg_instr/dbg_state` | reset release, IRQ edge/return/reset window | PC/decode mismatch, pre-fetch/cross-boundary failure, unexpected trap |
| 1.2 decode/execute RV32IMC | Directed execute debug once sim exists | commit/retire, decoded instr, rs/rd indices, ALU op/result, MD op/result, RF writeback | each failing directed case plus first mismatch | any scoreboard mismatch requiring internal operand tracing |
| 1.3 pipeline hazard | Directed hazard debug once sim exists | ID/EX rs indices, EX/MEM and EX/WB rd/writeback, forwarding selects/data, stall, bubble/valid, memory/CSR/RF write enables | RAW/load-use/muldiv hazard windows | wrong-path side effect or unexplained stall/forward decision |
| 1.4 BP/RAS/redirect | Predictor and recovery debug | predicted/actual taken, RAS top/push/pop, redirect cause/target, valid/bubble | branch/JAL/JALR/return tests | target mismatch or repeated mispredict |
| 2.0 trap/IRQ | trap entry/exit debug | CSR write/read, mtvec/mepc/mcause/mstatus/mie/mip, trap_enter/exit, mret, IRQ pulse/pending | trap entry through return | CSR mismatch or nested timing issue |
| 2.1 memory wrapper | valid-ready and byte lane debug | imem/dmem valid/ready, addr, rdata/wdata, wstrb, load result, wrapper state | stalls, backpressure, byte/half tests | protocol deadlock or lane mismatch |
| 3.0 Spike lockstep | first mismatch debug | commit PC/instr/rd/data, trap metadata, first mismatch context | short window around first mismatch | any ISS mismatch |

Phase labels in this table correspond to Phase 1.1, Phase 1.2, Phase 1.3,
Phase 1.4, Phase 2.0, Phase 2.1, Phase 3.0, and later closure/sign-off phases.

## Phase 1.1 Current Policy

Default command:

```sh
make -B sim.log
```

Default trace settings:

```text
TRACE_DEPTH=2
REVIEW_TRACE=1
RUN_ARGS=
```

Deep debug command:

```sh
make clean
make TRACE_DEPTH=5 REVIEW_TRACE=0 RUN_ARGS=+full_vcd
```

The default Phase 1.1 VCD intentionally excludes the full `u_core` hierarchy.
It exposes wrapper-level debug wires instead. This keeps the waveform useful for
review while reducing size from roughly 110 MB to roughly 11 MB for the current
smoke run.
