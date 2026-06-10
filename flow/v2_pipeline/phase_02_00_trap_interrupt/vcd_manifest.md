# Phase 2.0 Trap / Interrupt VCD Manifest

Status: required for directed CSR/IRQ waveform review.

## Review Questions

- Was the external IRQ injected while the target 16-bit instruction at
  `PC=0x80` was in the pipeline?
- Did the WB trap entry candidate save `mepc=0x82` rather than `0x84`?
- Did the handler observe `mepc=0x82` and `mcause=0x8000000b`?
- Did `mret` resume at the instruction after the interrupted 16-bit
  instruction?

## Required Signals

- `clk`, `resetn`, `irq_external_pulse`, `trap`
- `dbg_pc`, `dbg_instr`, `dbg_state`
- `i_mem_addr`, `i_mem_en`, `i_mem_rdata`
- `d_mem_valid`, `d_mem_addr`, `d_mem_wdata`, `d_mem_wstrb`
- `injected_irq`, `saw_irq_entry`, `stored_mepc`, `stored_mcause`
- full-debug escape hatch includes `dut.u_csr` and WB internal signals

## Dump Windows

The default VCD covers reset release through IRQ entry, handler stores, and
`mret` resume. The test is short enough that no mid-run dump gaps are used.

## Trace Settings

- Default: `TRACE_DEPTH=2`
- Full debug: `make clean && make TRACE_DEPTH=5 RUN_ARGS=+full_vcd`

## Size Envelope

Expected default waveform size: under 20 MB. If it exceeds that, the phase must
either tighten signal scope or document why deeper hierarchy is needed.

## Known Blind Spots

- This is a directed single-case IRQ timing test, not complete CSR coverage.
- It does not replace Spike lockstep or line/toggle coverage.
