# ADR Draft: Bit-Exact E2E Verification — One Gemma-3 Decoder Layer (Slice 0)

**Status:** Proposed (first implementation slice)  
**Authority:** Self-contained NumPy fixed-point golden + existing gemmlowp/mat_engine proof  
**Target DUT:** Magpie_M3V NPU (int8 `mat_engine` 8×8 GEMM + gemmlowp requant, Zve32x int, scalar RV32IMF, contiguous DMA, 32 KB DTCM)

**Representative sim dims (not production 270M):**

| Parameter | Value |
|---|---|
| `hidden_size` | 64 |
| `head_dim` | 16 |
| `n_heads` | 4 |
| `n_kv_heads` | 1 (GQA) |
| `seq_len` | 4 |
| `intermediate_size` | 128 |
| `sliding_window` | 4 (full window at this seq) |

---

## 1. Golden Authority — Non-Circular, Defensible

### 1.1 Three-tier authority (no torch/TFLite)

```
Tier A — Semantic reference (fp32 NumPy, NON-pass/fail for bit-exact)
    Gemma-3 decoder math from public spec; independent of RTL.
         │
         ▼ bounded quant error check only
Tier B — Quant + fixed-point contract (YAML SSOT, PRE-RTL)
    Per-tensor: scale, ZP, symmetric/asymmetric, accumulator width,
    requant recipe (= gemmlowp, already gate-proven).
         │
         ▼ bit-exact pass/fail
Tier C — Fixed-point golden (NumPy implements Tier B algorithms)
    Same polynomials, LUTs, softfloat steps as RTL will use.
         │
         ▼ byte-identical at checkpoints
DUT (Verilator + Spike lockstep / scoreboard)
```

**Non-circularity rules:**

1. **Tier B precedes RTL.** Quant params and nonlinear recipes live in `gemma3_layer0_quant.yaml` (SSOT → `.h` / golden / test vectors). RTL does not define scales.
2. **Tier C is algorithmic, not fitted.** Coefficients for rsqrt/exp/gelu come from documented approximations (minimax derivation, gemmlowp spec, or exported `softfloat-3` semantics) — not tuned to make DUT pass.
3. **GEMM is anchored to existing proof.** Int8 GEMM golden = gemmlowp int32 MAC → `(acc * mult + round) >> shift` per channel, already validated vs `mat_engine` in FC/MLP/CNN gates. LLM slice **reuses that kernel**, not a new matmul golden.
4. **fp32 Tier A is a sanity bound, not the golden.** Pass: `|int_dequant(x) - fp32(x)| ≤ 0.5 * scale` (or per-channel equivalent) at each quant boundary. Fail Tier A alone does not block slice green; fail Tier C does.

### 1.2 Precise bit-exact claim

> **Claim (slice-local):** At each named checkpoint tensor `T_k` (see §3), DUT memory contents are **byte-identical** to Tier C NumPy output for dtype, shape, layout, and scale metadata defined in SSOT.

**Not claimed:**

- Bit-exact to HuggingFace / Gemma-3 fp32 weights or activations
- Bit-exact across arbitrary `(hidden, seq)` without re-deriving quant grids
- Numerical identity between fp32 Tier A and int8 Tier C (only bounded error)

**Evidence ladder per slice:**

| Check | Method |
|---|---|
| GEMM checkpoints | mat_engine replay vs gemmlowp golden (existing scoreboard pattern) |
| Nonlinear checkpoints | Tier C NumPy vs DUT dump, hex diff |
| End-to-end slice | All checkpoints + Tier A bound at slice output |
| Regression | Spike lockstep on scalar-F ops; vector CSR lockstep on Zve32x elementwise |

---

## 2. Quantization Scheme + Nonlinear Implementation

### 2.1 Per-sub-op precision split

| Sub-op | Execution path | Rationale |
|---|---|---|
| Q/K/V/O projections | **int8 per-channel GEMM** | Proven `mat_engine` path |
| QKᵀ (`[seq,hd] × [hd,seq_kv]`) | **int8 GEMM**, int32 acc, per-query-row requant | Same engine; GQA broadcasts K/V weights |
| AV (`attn × V`) | **int8 GEMM** | Same engine |
| MLP gate / up / down | **int8 per-channel GEMM** | Reuses FC/MLP runtime |
| RMSNorm (×4) + QK-norm (×2) | **int32 vector accum** → fixed-point stats → int8 out | Cannot close in int8; no vector FP |
| RoPE | **int32 rotate** with **precomputed Q15 sin/cos table** (TCM) | Deterministic; no runtime trig |
| Causal + sliding mask | **int32 score mask** (add large negative constant) | Before softmax LUT |
| Softmax | **int32 logits** → LUT exp → int32 sum → LUT/div reciprocal | No FP in hot path |
| GeGLU `gelu_tanh(gate)*up` | Gate/up stay int8 through GEMM; **gelu on dequant int32**; mul in **Zve32x int32** | See §2.2(c) |

**Scale propagation rule (SSOT):** Each GEMM output carries `(scale_out, zp_out)` computed as gemmlowp product-of-input-scales × weight-scale; nonlinear ops consume explicit `(scale_in → scale_out)` entries in YAML — no implicit float.

### 2.2 Nonlinear bit-exact recipes (RTL == NumPy)

**(a) rsqrt in RMSNorm**

| Choice | **Fixed-point minimax polynomial on u32 variance estimate** |
|---|---|
| Why not scalar-F | FPU is scalar-only; norm runs per-row vector reduction — mixing F rsqrt with int8 vector multiply creates staging ambiguity |
| Why not LUT alone | rsqrt needs wide dynamic range; 16-bit LUT + NR refinement is larger than 4-term poly |
| **Algorithm** | `sum_sq = Σ x_i²` (Zve32x widening MAC, int32); `mean_sq = sum_sq / n` (rounding defined: trunc toward zero); `y = rsqrt(mean_sq + ε)` via **Q31 poly** on normalized mantissa (range reduction: find MSB, evaluate `P(t)` in int64, rescale); `out_i = x_i * y * (1+w_i)` in int64 → requant int8 |
| Bit-exact hook | Same `P[]`, same ε=`1e-6` fp32-equivalent in Q31, same rounding at each multiply-shift; NumPy uses integer-only `numpy.int64` mirror |

**(b) exp in softmax**

| Choice | **LUT + int32 linear interpolation (optional) or direct LUT on quantized delta** |
|---|---|
| Why not scalar-F | 4×4 attention scores = 16 exps — F works, but int32 score path → F → int8 attn weights adds 3 format conversions; LUT stays in score domain |
| Why not vector poly | exp range for masked scores needs ~10-bit index; LUT is simpler to match exactly |
| **Algorithm** | `delta_j = score_j - max(scores)` (int32); `idx = clamp(delta * inv_step, 0, N-1)`; `exp_j = LUT[idx]` (int32, pre-normalized so sum fits int32); `attn_j = (exp_j * inv_sum) >> shift` → int8 or Q0.15 fixed per head |
| SSOT | `LUT_EXP[int32]` 512 entries, `inv_step` Q16, `inv_sum` via **integer Newton** or 512-entry `LUT_RCP` on sum |

**(c) gelu_tanh in GeGLU**

| Choice | **Scalar RV32IMF (softfloat-3 faithful) on dequantized gate row** |
|---|---|
| Why not vector int poly | GELU tanh-approx needs `x³` and nested tanh — 5+ terms; reproducing in Zve32x int without a proven lockstep contract is high risk |
| Why scalar-F wins here | ADR-0050 already proves **bit-exact F lockstep vs Spike rv32imf**; `intermediate=128, seq=4` → ≤512 scalar calls; NumPy golden calls **same softfloat reference** (Python port of fexu ops or subprocess to native test harness) |
| **Algorithm** | `g_i = dequant(gate_i, scale_gate)` → softfloat `gelu_tanh(g_i)` → `q_i = requant(gelu_i, scale_gelu)`; `out_i = q_i * up_i` (int32 mul, Zve32x vuint) → requant → down GEMM |
| Bit-exact hook | Golden does not use `np.tanh`; it calls `sf_gelu_tanh_f32()` with documented RNE at each softfloat op |

**Summary — cleanest exact-match trio:**

```
RMSNorm rsqrt  → vector int + Q31 polynomial
Softmax exp    → int32 LUT (+ int reciprocal)
GeGLU gelu     → scalar softfloat-3 (proven lockstep path)
```

---

## 3. Scope / Slicing — Recommendation

### 3.1 Do **not** one-shot the full layer

Full layer introduces **≥6 new mechanisms** at once (4× RMSNorm, QK-norm, RoPE, GQA broadcast, sliding mask, softmax LUT, GeGLU). Debug surface is unbounded; DTCM pressure (~32 KB) forces staging decisions that obscure failures.

### 3.2 Slice order (MobileNet-style)

| Slice | Scope | Reuses | **One new mechanism** |
|---|---|---|---|
| **S0 (FIRST)** | **MLP GeGLU block** | 3× int8 GEMM + requant (gate_48/49 path), Zve32x mul | **gelu_tanh via scalar-F** |
| S1 | Post-attn RMSNorm + residual | S0 infra | rsqrt polynomial |
| S2 | Q/K/V projections + QK-norm + RoPE | GEMM + S1 rsqrt | **RoPE Q15 table apply** |
| S3 | QKᵀ GEMM + mask + softmax + AV | GEMM + S2 | **softmax LUT** |
| S4 | Full attention residual compose | S1–S3 | GQA broadcast wiring only (no new math) |
| S5 | Full decoder layer (4 norms + attn + MLP) | All | Integration / scale handoff |

### 3.3 Why S0 = MLP GeGLU first

1. **Maximal GEMM reuse:** Three per-channel int8 GEMMs identical to proven TFLM FC/MLP kernels (different weight shapes only).
2. **Exactly one new mechanism:** `gelu_tanh` scalar-F pipeline — mirrors “MobileNet depthwise = conv + one new op.”
3. **DTCM fit (closed form):**

   ```
   gate:  4×128  int8  = 512 B
   up:    4×128  int8  = 512 B
   gelu:  4×128  int32 = 2 KB
   prod:  4×128  int32 = 2 KB
   down input + weights + acc buffers < 16 KB total staging
   ```

4. **Bit-exact checkpoints are dense:** 6 tensors (input, post-gate-GEMM, post-gelu, post-mul, post-down-GEMM, output) — easy hex diff.

### 3.4 S0 test harness

```
Host loads: hidden[4,64] int8, W_gate, W_up, W_down + scales (DMA)
NPU runs:   down( gelu_tanh(gate(x)) ⊙ up(x) )   # no RMSNorm yet
Host dumps: checkpoints → compare Tier C golden
Gate:       gate_gemma3_s0_geglu.py (new)
```

Input is **pre-quantized int8 hidden state** (fixture from Tier C, not live attn output) — defers norm/attn coupling.

---

## 4. Green-Wash Risks + Guards

| Risk | Guard |
|---|---|
| “Bit-exact Gemma-3” without fp32 bound | ADR states claim = **Tier C checkpoint identity**; Tier A bound reported separately |
| fp32 NumPy used as pass/fail golden | CI fails if test compares against `float32` tensors without `FIXEDPOINT_GOLDEN=1` |
| New GEMM requant formula for LLM | **Forbidden:** must call existing gemmlowp kernel; lint checks import path |
| gelu uses `np.tanh` / libm in golden | Golden must import `softfloat_gelu_tanh`; unit test: golden == Spike rv32imf snippet |
| RMSNorm ε, `(1+w)` weight format wrong | SSOT constants `GEMMA3_RMS_EPS`, `GEMMA3_NORM_ONE_PLUS_W`; cross-check Tier A fp32 |
| RoPE θ/base, partial-rotation convention | S2 blocked until RoPE ADR cites Gemma-3 config values; golden vectors include pre-RoPE Q/K |
| GQA head broadcast bug | S4 uses **n_kv_heads=1, n_heads=4** explicitly; golden repeats K/V on head axis with logged stride |
| Sliding-window off-by-one | Dedicated test `seq=4, window=2` after full-window green |
| Softmax “close enough” tolerance | **No float rtol** at checkpoints; int32 LUT entries compared hex-exact |
| seq=1 only (masks degenerate) | Minimum `seq_len=4`; causal + window-2 cases mandatory before S5 |
| TB computes gelu/norm instead of RTL | Scoreboard reads **DTCM dumps only**; nonlinear in TB = immediate fail (lint) |
| DTCM silent overlap | Linker script + `gate_*` asserts peak stack+heap+activations ≤ 32 KB with 10% guard band |
| Wrong Spike `--isa` for vector slice | Zve32x lockstep flag enforced in Makefile (existing phase_22 discipline) |
| Scale drift across slice boundary | Each slice output documents `scale_out`; next slice input must match SSOT or explicit requant op |
| Hidden 64 “green” extrapolated to 270M | ADR marks dims **representative**; no production claim until shape-parametric golden regen |

---

## 5. Deliverables for S0 (first PR)

1. `docs/adr/00XX-gemma3-decoder-layer0-verification.md` — this architecture, frozen Tier B YAML schema  
2. `design/npu/sw/gemma3/gemma3_layer0_quant.yaml` — scales, checkpoint names, gelu softfloat contract  
3. `design/npu/sw/gemma3/golden/gemm_geglu_s0.py` — Tier C NumPy (int GEMM via gemmlowp mirror + softfloat gelu)  
4. `design/npu/sw/gemma3/firmware/s0_geglu_main.c` — DMA load, 3 GEMMs, scalar-F gelu loop, Zve32x mul, dump  
5. `tests/gates/gate_gemma3_s0_geglu.py` — checkpoint hex diff + Tier A bound + DTCM budget assert  
6. Fixture: `tests/fixtures/gemma3_s0_vectors.hex` — generated from golden, committed

**S0 exit criterion:** All 6 checkpoints byte-identical; Tier A max error within quant bound; gate green in Verilator lockstep flow; zero new GEMM microcode.

---

## 6. Decision summary

| # | Decision |
|---|---|
| 1 | **Tier B/C fixed-point golden is authority;** fp32 is bounded sanity only; GEMM anchored to proven gemmlowp |
| 2 | **GEMM everywhere projections allow;** rsqrt=vector Q31 poly; exp=LUT; gelu_tanh=scalar softfloat-3 |
| 3 | **First slice = MLP GeGLU (S0):** 3 reused GEMMs + one new gelu_tanh mechanism |
| 4 | **Guards:** no float golden pass, no TB-side nonlinear, SSOT scales, hex checkpoints, seq≥4 mask tests, honest claim wording |

This is ready to land as ADR + `gate_gemma3_s0_geglu` implementation without torch/transformers. If you want the next step, I can expand S0’s YAML checkpoint schema and the exact `gelu_tanh` softfloat opcode sequence to match your existing `fexu` implementation.
