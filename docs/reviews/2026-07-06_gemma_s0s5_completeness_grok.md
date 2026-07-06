# Gemma-3 Decoder S0–S5 — Circuit Completeness (Architecture Judgment)

**Premise:** Tier-C `gemma_quant.py` is the hex checkpoint authority; RTL must reproduce it, not `gemma_ref.py` fp32.

---

## Per-slice answers

### S0 — MLP GeGLU

| Sub-op | Unit |
|--------|------|
| gate/up/down GEMM | `mat_engine` + CQ |
| gelu_tanh | LUT in TCM + scalar `lbu(table[q+128])` or RVV `vrgather` |
| ⊙ | RVV `vmul` (masked) |
| mul-requant | RVV `vsmul` / narrow + shift (per-tensor formula from golden) |

1. **Bit-exact?** Yes — if LUT bytes and per-tensor requant match SSOT.
2. **Gap?** None.
3. **rsqrt** — N/A.
4. **LUT** — Scalar loop over hidden=64 is fine and green-wash-safe; `vrgather` works in m1 chunks (vlmax=4) if table is staged in VR — not required.
5. — 
6. **Hardest pitfall:** gelu index `q+128` vs signed int8; **guard:** dump 256-entry LUT hex + first GEMM→gelu→mul chain byte-exact.
7. —

---

### S1 — post-attn RMSNorm + residual

| Sub-op | Unit |
|--------|------|
| x², sum, mean | RVV `vmul` + reduction |
| rsqrt | **Integer Q31 poly / NR** on RV32IM or RVV — **not** scalar F |
| γ mul, scale | RVV `vmul` + requant |
| residual | RVV `vadd` |

1. **Bit-exact?** Yes — on integer rsqrt path matching golden.
2. **Gap?** None — **unless** firmware uses `fsqrt`+`fdiv`; that breaks Tier-C.
3. **rsqrt:** **Q31 integer** is cleanest. Tier-C is fixed-point end-to-end; scalar F introduces a different numeric contract even if fp32-bound in gate_83.
4. — 
5. — 
6. **Hardest pitfall:** iteration count / rounding of Q31 rsqrt; **guard:** freeze poly coeffs + NR steps in SSOT; single-vector hex after norm.
7. —

---

### S2 — Q/K/V + QK-norm + RoPE

| Sub-op | Unit |
|--------|------|
| Q/K/V proj | `mat_engine` ×3 |
| QK-norm | same as S1 rsqrt path |
| RoPE | Q15 sin/cos tables in TCM + RVV mul/add on (x₁,x₂) pairs |

1. **Bit-exact?** Yes.
2. **Gap?** None.
4. — 
5. **RoPE pitfall:** Q15 × int32 → shift/saturation order; table index = `pos * head_dim/2 + i`; interleaved vs split head layout must match golden.
6. **Hardest pitfall:** rotation pair layout (Gemma convention); **guard:** one-head Q/K hex at pos=0,1,2,3 before QKᵀ.
7. —

---

### S3 — QKᵀ + mask + softmax + AV

| Sub-op | Unit |
|--------|------|
| QKᵀ | `mat_engine` |
| causal + sliding mask | RVV compare + `vmerge` / vmin |
| softmax max | RVV reduction |
| exp | LUT in TCM (same pattern as gelu) |
| sum | RVV reduction |
| reciprocal | **Integer fixed-point** (golden algo) — RV32IM/RVV mul+shift; **not** generic `vdiv` unless golden uses it |
| AV | `mat_engine` |

1. **Bit-exact?** Yes — if reciprocal matches golden's method, not Spike/softfloat semantics.
2. **Gap?** None at circuit level; **firmware contract** must replicate golden reciprocal, not pick a new one.
5. **Reciprocal pitfall:** `1/sum` with small sums, rounding (`rdbpot`-style), zero-mask rows; exp LUT input = `score - max` scaling must match golden bit-width.
6. **Hardest pitfall:** full softmax chain (max-sub → exp → sum → recip → mul); **guard:** 4×4 attention weights hex post-softmax, seq≥4 with causal+window mask.
7. —

---

### S4 — attn residual + GQA

| Sub-op | Unit |
|--------|------|
| GQA broadcast (nh=4, nkv=1) | RVV `vmv`/`vrgather`/splat + DMA stride |
| residual | RVV `vadd` |

1. **Bit-exact?** Yes.
2. **Gap?** None.
6. **Hardest pitfall:** K/V head-0 broadcast to 4 Q heads — memory layout / stride; **guard:** attn output hex before residual, nh/nkv layout frozen.
7. —

---

### S5 — full layer + scale handoff

| Sub-op | Unit |
|--------|------|
| subgraph glue | CQ + DMA + RV32IM sequencer |
| scale propagation | firmware registry (SSOT from gate_83) |
| buffers | DTCM 32KB — ping-pong / in-place schedule |

1. **Bit-exact?** Yes — circuit-sufficient; risk is orchestration.
2. **Gap?** None for RTL; DTCM pressure is a **firmware scheduling** constraint, not missing hardware.
6. **Hardest pitfall:** wrong scale id between subgraphs (compound drift); **guard:** end-to-end layer output hex + `DTCM<=32KB` assert + frozen scale table diff-empty vs gate_83.
7. —

---

## Cross-cutting (Q3–Q5)

**3. rsqrt:** Integer Q31 per golden. Scalar F is only valid if Tier-C explicitly defines that path — it does not for a gemmlowp/int8 stack.

**4. gelu/exp LUT:** Both scalar `lbu` and RVV `vrgather` are bit-exact feasible. 256 entries > vlmax does **not** force scalar — gather indexes into a loaded VR slice or memory-backed index loop. Scalar loop is acceptable and simpler for green-wash (nonlinear on NPU core, not host).

**5. softmax recip + RoPE Q15:** Match golden's (a) exp input quantization width, (b) reciprocal algorithm + rounding, (c) masked-row sentinel (e.g. -inf → 0), (d) RoPE Q15 product width before >>15. Units pitfall: treating Q15 as float or using `fdiv` for `1/sum`.

---

## Overall verdict

**COMPLETE — circuit-sufficient, zero new RTL** for representative dims (hidden=64, head_dim=16, nh=4, nkv=1, seq=4, inter=128) vs Tier-C hex checkpoint.

All nonlinear ops map to existing units: **LUT-in-TCM + RVV/RV32IM integer**, not host/TB. GEMM stays on proven `mat_engine` path.

**Recommended order & risk:**

```
S0 (GEMM+LUT+mul-requant)  → low   — reuses mat_engine + gelu LUT
S1 (rsqrt integer contract)→ med   — nail Q31 SSOT early
S2 (RoPE tables/layout)    → med   — layout bugs are silent
S3 (softmax chain)         → HIGH  — most sequential fixed-point glue
S4 (GQA broadcast)         → med   — stride/layout
S5 (integration)           → med   — scale handoff + DTCM schedule
```

**Real gaps:** none requiring RTL. Residual risks are **firmware numeric contracts** (rsqrt/recip/scale SSOT) and **DTCM scheduling** — both gate-guardable without new hardware.
GROK_DONE exit=0
