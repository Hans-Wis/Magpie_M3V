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

## MAC-engine internal split (S_RUN vs S_RSC) — measured

Of the 5,658 mat-engine busy cycles across the whole layer:
- **S_RUN (actual MAC): 1,104 cycles** = **0.29% of wall-clock**.
- **S_RSC (requant): 4,290 cycles** = 76% of engine busy (**~4× the MAC cycles**).
- other (LOADACC/CFG): 264.
- **Spatial packing = 50.0%**: 141,312 useful MACs / (1,104 × 256 = 282,624 MAC-slots). Exactly
  half the lanes compute zeros — the seq=4→8 pad on the M/N dimension. Vanishes at seq = mult of 8.

**Reframing "the 256-MAC engine is 98.5% idle":** the array is not the bottleneck and adding MACs
is pointless — it does the entire layer's matrix work in 1,104 cycles. It is idle because
(a) **requant dominates its own busy time 4×**, and (b) it is gated behind DMA + scalar spin-poll:
GEMM steps are 116k wall-clock but the engine is busy only 5.6k → idle ~95% even *within* GEMM
steps, waiting on weight DMA (35k) and synchronous core orchestration (~76k core* in GEMM steps).

**MAC-utilization levers (besides RVV), by measured value:**
1. **De-serialize GEMM orchestration (temporal — the big one):** double-buffer weights (engine runs
   while next tile's B loads), autonomous tile sequencing (no return-to-firmware spin-poll between
   tiles). Attacks the ~76k core* + overlaps the 35k DMA inside GEMM steps.
2. **Fuse per-input GEMMs:** Q/K/V share input hin → one N=96 pass; gate+up share hff → one N=256
   pass. One weight load + one resident activation instead of 2–3, amortizes requant setup.
3. **Amortize requant (S_RSC 4,290, 4× the MAC):** requant is per-8×8-tile fixed cost; at seq=4 half
   its outputs are padding. Filling M=8 (real seq / more batched rows) halves the wasted requant.
4. **Keep activations resident (fusion):** each GEMM currently reloads its input shared→TCM; a fused
   in-NPU layer keeps intermediates in DTCM and removes the reload DMA the engine waits behind.
5. **Do NOT add MACs / widen the array:** S_RUN is 0.29% of wall-clock; a 512-MAC array saves ~550
   of 375,672 cycles. The 50% spatial waste is a seq=4 artifact, gone at production seq.

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

## Optimization loop (measure → change → verify bit-exact → repeat)

Harness: `profile_gemma_layer.py` (score) + the S0–S5 bit-exact gates (safety net). Baseline
375,672.

### Cycle 1 — RVV residual add ✅ (committed b4258c7)
Enabled the EN_RVV=1 vexu on the sequencer (march += `zve32x_zvl128b`, `_start` sets
`mstatus.VS`). Vectorized MAT_EWISE_ADD_REQUANT — a plain `(acc+bias)>>SHIFT` that is int32-safe.
- **residual 19,251 → 6,306 cyc (3.05×); layer 375,672 → 349,824 (−6.9%).** Bit-exact + no
  regression (S0–S3, TFLM FC/CNN).
- Toolchain lessons: `vsext.vf2/.vf4` mixed with a byte load hits a `-Os` vtype-inference bug →
  illegal-instruction trap; the `vwcvt` (=`vwadd.vx`) widening idiom lowers with correct vtype.
  Widening/narrowing are m1-only in this vexu.

### The wall: the requant-heavy 69% is not trivially vectorizable
RMSNorm / RoPE / ewise-mul (the bulk of the 259k nonlinear) all end in a **gemmlowp srdhm**
requant that needs a **64-bit intermediate** (`acc * mult`, up to 2^56) — but **Zve32x is
ELEN=32** (no 64-bit vector elements). srdhm's round-half-away rounding + truncate-toward-zero
also does not match any RVV `vsmul`/`vssra` rounding mode, so a one-instruction swap is not
bit-exact. Two ways forward (each a real cycle, not a swap):
1. **vmulh-based srdhm reconstruction** — build the 64-bit product from `vmulh`(hi)+`vmul`(lo)
   and reproduce the nudge/truncation in int32 (~8–10 vector ops/elem). Required for ewise-mul
   because its requant **must stay bit-identical to the mat_engine hardware srdhm** (shared
   authority — cannot change its rounding).
2. **Golden reformulation to RVV-native rounding** — legitimate ONLY for the Gemma-private ops
   (RMSNorm rsqrt/requant, RoPE) whose golden this line owns; redefine the fixed-point to use
   `vsmul`+`vssra` rounding in BOTH golden and firmware, re-verify bit-exact + fp32 bound. Unlocks
   RMSNorm (134k, the single biggest family). Needs an ADR (changes the S1/layer golden).

### GEMM double-buffer / de-spin — deprioritized by measurement
The engine is busy only 5,658 cyc; at most ~5.6k of the 35k DMA can hide behind compute. High
blast radius (shared GEMM firmware path) for a small ceiling. The larger GEMM cost is the ~76k
core orchestration, better attacked by **fusing Q/K/V and gate/up** (runtime-only, bit-exact) than
by double-buffering.

**Loop conclusion:** residual (clean, plain-shift) was the only trivially-vectorizable op and is
banked at 3×. The dominant remaining wins (RMSNorm/RoPE/ewise) are gated by ELEN=32 + gemmlowp
rounding and need path 1 or 2 above — the next cycles, each with its own bit-exact re-verify.

## Reproduce

`python sim/tools/profile_gemma_layer.py` (needs Verilator; builds npu_top+cpu_m1 once, runs the
22-step chain). TB counters are additive (`NPU_PROFILE` line) and do not affect gate pass/fail.
