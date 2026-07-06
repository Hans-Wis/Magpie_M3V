# Gemma-3 decoder layer — RTL cycle profile (2026-07-07)

Measured on the verified S0–S5 chain via `sim/tools/profile_gemma_layer.py` (tb_npu_tflm_model
cycle counters, gated doorbell→DONE per step). Representative dims: seq=4, hidden=64, nh=4,
head_dim=16, intermediate=128. **Measurement, not projection** — the "improvement" numbers
below the table are estimates.

## Per-step (cycles)

| step | kind | total | mat | dma | ret | core* |
|---|---|---:|---:|---:|---:|---:|
| RMSNorm_in | nonlin | 24276 | 0 | 203 | 17766 | 24073 |
| q_proj | GEMM | 13347 | 680 | 3618 | 6628 | 9049 |
| k_proj | GEMM | 3492 | 170 | 906 | 1762 | 2416 |
| v_proj | GEMM | 3492 | 170 | 906 | 1762 | 2416 |
| QK-norm_q | nonlin | 30087 | 0 | 233 | 21380 | 29854 |
| QK-norm_k | nonlin | 7899 | 0 | 83 | 5576 | 7816 |
| RoPE_q | nonlin | 26121 | 0 | 289 | 18917 | 25832 |
| RoPE_k | nonlin | 6957 | 0 | 139 | 4982 | 6818 |
| QK^T | GEMM | 3072 | 146 | 518 | 1613 | 2408 |
| softmax | nonlin | 6948 | 0 | 249 | 3432 | 6699 |
| AV | GEMM | 5751 | 284 | 905 | 3049 | 4562 |
| o_proj | GEMM | 13347 | 680 | 3618 | 6628 | 9049 |
| RMSNorm_postattn | nonlin | 24051 | 0 | 203 | 17645 | 23848 |
| residual_1 | nonlin | 19251 | 0 | 235 | 13822 | 19016 |
| RMSNorm_preffn | nonlin | 24342 | 0 | 203 | 17824 | 24139 |
| gate_proj | GEMM | 26598 | 1360 | 7236 | 13189 | 18002 |
| up_proj | GEMM | 26598 | 1360 | 7236 | 13189 | 18002 |
| gelu_LUT | nonlin | 8991 | 0 | 355 | 6323 | 8636 |
| ewise_mul | nonlin | 36966 | 0 | 419 | 26071 | 36547 |
| down_proj | GEMM | 20856 | 808 | 6963 | 9808 | 13085 |
| RMSNorm_postffn | nonlin | 23979 | 0 | 203 | 17625 | 23776 |
| residual_2 | nonlin | 19251 | 0 | 235 | 13824 | 19016 |

`mat` = mat_engine busy, `dma` = dma_busy|wb_busy, `ret` = sequencer instructions retired,
`core*` = total − mat − dma (scalar-core active incl. spin-wait/orchestration).

## Totals

- **Wall-clock (sum of step doorbell→DONE): 375,672 cycles** (~376 µs @ 1 GHz).
- Nonlinear steps: **259,119 (69.0%)**.
- GEMM steps: 116,553 (31.0%) — but **mat-engine busy only 5,658 (1.5% of wall-clock)**.
- DMA busy (all): 34,955 (9.3%).
- **Scalar sequencer-core active ≈ 335,059 (~89%)**.

## Findings (some overturn the pre-measurement analysis)

1. **The 256-MAC engine is idle 98.5%** — real matrix work is 5,658 cycles. The accelerator is
   almost never the bottleneck at these dims.
2. **The scalar sequencer core is the universal bottleneck (~89% wall-clock)** — both nonlinear
   compute (69%) and GEMM orchestration.
3. **GEMM steps are scalar-orchestration bound, not matrix bound** (overturns the pre-measurement
   guess): e.g. gate_proj total 26,598 vs mat 1,360 + dma 7,236 → ~18,000 cycles are the core
   synchronously spin-polling `wait_done`. The firmware serializes LOAD_W→OP→RESCALE→STORE with
   no engine/DMA overlap.
4. Pre-measurement estimate (nonlinear ~27k) was 10× low: 64-bit int ops + the freestanding
   `__ashrdi3` variable 64-bit shift compiled as a **per-element function call** in the
   RMSNorm/RoPE/requant inner loops + CPI.

## Prioritized opportunities (projected)

| # | action | target | projected |
|---|---|---|---|
| 1 | **Vectorize nonlinear firmware with RVV Zve32x** (vexu already verified; gelu/exp via verified vrgather) | 259k (69%) | nonlinear 4–8×, layer ~2× |
| 2 | **De-spin GEMM firmware / pipeline tiles** (issue next LOAD_W while engine runs; stop synchronous polling) | ~76k of GEMM spin overhead | GEMM step ~2–3× |
| 3 | **Fuse the whole layer into one in-NPU CQ program** (intermediates in DTCM; drop host round-trips + reload DMA) | DMA 35k + per-step reload | additive |
| 4 | **Remove per-element `__ashrdi3`** in rsqrt/requant (fixed shift or full-RVV) | RMSNorm family 134k | significant |
| 5 | softmax reciprocal-multiply instead of per-element uint32 divide | softmax (scales with seq²) | significant at real seq |

Doing #1 + #2 → rough estimate 259k→~70k, 116k→~50k → **layer ~3×**, all on already-verified
datapaths guarded by the S0–S5 bit-exact goldens.

## Reproduce

`python sim/tools/profile_gemma_layer.py` (needs Verilator; builds npu_top+cpu_m1 once, runs the
22-step chain). TB counters are additive (`NPU_PROFILE` line) and do not affect gate pass/fail.
