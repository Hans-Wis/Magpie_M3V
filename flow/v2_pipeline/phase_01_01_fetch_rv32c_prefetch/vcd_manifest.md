# Phase 1.1 VCD Manifest

Phase: fetch/RV32C/pre-fetch smoke

## Review Questions

- Did reset release and instruction fetch begin correctly?
- Did the firmware execute compressed boot instructions?
- Did the I-port continue to provide instructions while the LED counter ran?
- Did BTN1 create an external interrupt pulse?
- Did the core return from the IRQ and reset the LED sequence?
- Did no unexpected trap occur during the smoke run?

## Required Signals

Testbench:

- `clk`
- `btn0`
- `btn1`
- `led[3:0]`
- `transitions`
- `saw_irq_reset`

Wrapper / core boundary:

- `dut.resetn`
- `dut.btn1_pulse`
- `dut.trap`
- `dut.i_mem_addr[31:0]`
- `dut.i_mem_en`
- `dut.i_mem_rdata[31:0]`
- `dut.d_mem_valid`
- `dut.d_mem_addr[31:0]`
- `dut.d_mem_wdata[31:0]`
- `dut.d_mem_wstrb[3:0]`
- `dut.out_byte_en`
- `dut.out_byte[3:0]`
- `dut.dbg_pc[31:0]`
- `dut.dbg_instr[31:0]`
- `dut.dbg_state[2:0]`

## Dump Windows

- Window 1: reset release and first instruction activity, 0 ns to 2 us.
- Window 2: pre-IRQ, BTN1 edge, IRQ return, and post-IRQ LED reset, 240 us to
  290 us.
- The remainder of the smoke run is log-observed only.

## Default Trace Settings

```text
TRACE_DEPTH=2
REVIEW_TRACE=1
RUN_ARGS=
```

`REVIEW_TRACE=1` disables full `u_core` hierarchy tracing and exposes
wrapper-level debug wires for review.

## Full Debug Escape Hatch

```sh
make clean
make TRACE_DEPTH=5 REVIEW_TRACE=0 RUN_ARGS=+full_vcd
```

Use full debug only when the review VCD cannot answer the failure, such as an
unexpected trap, compressed decode mismatch, or pre-fetch/cross-boundary bug.

## Size Envelope

- Expected default size: around 11 MB for the current smoke run.
- Gate warning threshold: review any default VCD above 25 MB.
- Gate failure threshold: default VCD above 50 MB without an updated manifest.

## Known Blind Spots

- Internal `u_core` IF/ID/EX/MEM/WB nets are intentionally omitted by default.
- `cdec` internal case choices are not visible by default.
- Internal BP/RAS arrays are not visible by default.
- Full hierarchy tracing is required for root-cause debug below wrapper-level
  PC/instruction/state observations.
