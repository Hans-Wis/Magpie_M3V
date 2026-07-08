# npu_dma AXI-width PPA — M3c full-SKU DC sweep (TSMC28)

- **Date:** 2026-07-08 · **Author:** Claude · **Flow:** real Synopsys DC + TSMC28 (28HPC+ tcbn28hpcplusbwp40p140 tt 0.9V 25C), in-sandbox
- **Scope:** ADR-0068 §M3 / M3c — quantify the **area/power cost of the wide-DMA datapath** vs the measured **DMA cycle benefit**, extending the ADR-0051 DC-PPA series.
- **Script:** `flow/dc_tsmc28/synth_npu_dma.tcl` (`DMA_DATA_W` env sweep, CLK_PERIOD=1.2ns). Reports in `reports/dc_npu_dma/W{32,64,128,256}/`.

## What was synthesized

`npu_dma` (the DMA datapath + burst FSM), **std-cell only** — the TCM/SRAM mem arrays are macros and are NOT synthesized (their port-width macro cost is separate, noted below). This isolates the **width-scaling logic cost** (m_rdata/m_wdata/wstrb, wide↔word lane-steering muxes, WPB burst math), the same std-cell-only methodology as the ADR-0051 mat_engine flow.

## Results (all @ 1.2 ns = 833 MHz, iso-frequency)

| DMA_DATA_W | SKU | Area µm² | Δ vs 32 | Dyn µW | Leak nW | Slack ns |
|---|---|---|---|---|---|---|
| 32 | (regression) | 689.3 | — | 485.1 | 524 | +0.36 |
| 64 | LANES=1 | 809.5 | +17% | 504.7 | 613 | +0.12 |
| 128 | LANES=2 | 919.3 | +33% | 519.8 | 692 | +0.05 |
| 256 | LANES=4 | 1142.8 | **+66%** | 543.7 | 848 | +0.04 |

**Area breakdown (32 → 256):** combinational 358.6 → 808.2 µm² (+125%); **noncombinational (flops) 330.7 → 334.7 µm² (+1%, flat)**. The growth is entirely the **combinational wide datapath** (lane muxes / wstrb); the FSM/control sequential is width-independent. 8× the data width costs only **1.66× area** — sub-linear, same shape as the LANES MAC-tree PPA (ADR-0067).

All four widths **meet 1.2 ns** (positive slack); slack narrows with width (256b at +0.04) but the datapath is not the Fmax limiter at this clock.

## PPA verdict: the wide-DMA datapath is essentially free vs the compute

- **Absolute cost is tiny.** `npu_dma` at 256b = **1,143 µm²**, vs **mat_engine 256-MAC = 83,868 µm²** (ADR-0067/gate_84). The wide-DMA datapath is **~1.4% of the engine area**; the 32→256 delta (+453 µm²) is **~0.5%** of the engine.
- **Cycle benefit is large.** Same-SKU coupling (DMA_DATA_W=64×LANES): ml_v2 q_proj **dma 1539 → 251** cyc across M3a+M3b-1 (read+write wide, ~6.1×), q_proj wall-clock **2,425 → 1,129** cyc (2.15× on this workload; full trajectory 13,350 → 1,129 = 11.8×).
- **Conclusion:** paying ~450 µm² of combinational logic (≈0.5% of the engine) to cut DMA cycles ~6× is a **clear PPA win**. The balanced-design SKU story holds: scaling MAC (LANES) and the DMA/bus width together is justified — the bus never becomes the area bottleneck.

## Honest caveats

1. **SRAM/TCM macro port width NOT captured.** This is std-cell `npu_dma` only. A real 256-bit-port SRAM/TCM macro costs more than a 32-bit-port macro (macro selection + peripheral logic); that delta is separate and would come from the memory compiler, not DC std-cell synthesis. The **datapath logic** cost — what M3c set out to measure — is what is reported here.
2. **Arbiter / axi_full_sram AXI-slave logic** (WPB assemble/disassemble) also scale with width and are not in this `npu_dma`-only number; they are small combinational blocks of the same character (sub-linear lane muxing) and do not change the conclusion.
3. Iso-frequency @1.2 ns; the 256b slack (+0.04) shows headroom is thinning — a wider-still or faster-clock SKU would want a pipeline stage on the DMA datapath (not needed at current targets).

## Provenance

`flow/dc_tsmc28/synth_npu_dma.tcl` + `lib_setup.tcl` (TSMC28 std-cell db). Re-run: `cd flow/dc_tsmc28 && for W in 32 64 128 256; do DMA_DATA_W=$W CLK_PERIOD=1.2 dc_shell -f synth_npu_dma.tcl; done`. npu_dma.v declaration order was adjusted (pure reorder, no logic change — Verilator-tolerated forward refs → Presto/DC declaration-before-use) so DC elaborates; re-verified lint + gate_npu_dma_width bit-exact.
