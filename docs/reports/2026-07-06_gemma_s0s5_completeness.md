# Gemma-3 decoder S0–S5 completeness review + golden fix (F1.5/F1.6 gate)

Date: 2026-07-06 · Reviewers: Grok (architecture), Codex (implementation-reality), Claude (verify)
Anchors: `2026-07-06_gemma_s0s5_completeness_{grok,codex}.md`

## Question
Can the **current circuit** execute a full Gemma-3 decoder layer (S0–S5, representative dims)
**bit-exact** vs the Tier-C fixed-point golden — with **zero new RTL**?

## Verdict (synthesis)
**Circuit-complete: no missing arithmetic unit.** Both reviewers agree every Gemma sub-op maps
to an existing unit — GEMM → `mat_engine`; gelu/exp → LUT-in-TCM via scalar `lbu`; mul-requant,
mask, reduction, RoPE, reciprocal → RVV Zve32x / RV32IM integer. GEMM stays on the proven path.

But "complete" required clearing two concrete blockers the reviews found:

1. **[FIXED] Tier-C golden requant diverged from the proven `mat_engine`.** Codex empirically
   replayed S0 and found `gemma_quant.srdhm()` used Python `>>` (rounds negatives toward −∞)
   while `mat_golden`/`mat_engine.v` truncate toward zero → **85/256 `out` bytes differed**. Left
   unfixed, an S0 RTL gate would have failed a wrong golden (or been green-washed to match it).
   Fix: `gemma_quant` now imports `srdhm`/`rdbpot` from `mat_golden` (single proven authority)
   and `qmul` enforces the tflm flush/left-shift contract. Verified: **0 bytes differ**, gate_83
   still green. (Grok, architecture-only, did not catch this — Codex running the numbers did.)

2. **[OPEN — S3 design decision] softmax int32 logits.** ADR-0062 says softmax consumes int32
   logits, but `mat_engine` only exposes **rescaled int8** output, not raw int32 accumulators.
   Zero-RTL options: (a) RVV int32 dot-product for QKᵀ, or (b) redefine logits as requantized
   int8. Option (c) int32 accumulator export would need new RTL. **Decision deferred to S3;**
   default lean = (a)/(b) to keep zero-RTL.

## rsqrt / reciprocal contract (both reviewers)
Use **integer fixed-point** (Q31 rsqrt poly; golden-defined reciprocal), **not** scalar-F
`fsqrt`/`fdiv`. The Tier-C golden is fixed-point end-to-end; scalar F is a different numeric
contract (even if fp32-bounded in gate_83). The golden defines the reference; RTL must equal it.

## Per-slice status + risk (Grok order)
| Slice | New mechanism | Circuit path | Risk |
|---|---|---|---|
| S0 MLP GeGLU | gelu LUT + int mul-requant | mat_engine ×3 + scalar `lbu` LUT + RVV vmul/requant | low (golden now fixed) |
| S1 RMSNorm+residual | rsqrt | RVV reduce + Q31 poly + vadd | med — freeze Q31 SSOT early |
| S2 QKV+QK-norm+RoPE | RoPE Q15 tables | mat_engine + RVV rotate + TCM table | med — layout bugs silent |
| S3 QKᵀ+mask+softmax+AV | softmax exp LUT + recip | mat_engine/RVV + LUT + int recip | **HIGH** + int32-logit decision |
| S4 attn residual + GQA | GQA broadcast | RVV splat/stride + vadd | med — nkv=1→nh=4 layout |
| S5 full layer | integration | CQ + DMA + scale handoff | med — scale-id drift, DTCM≤32KB |

## Answer to "是否完整"
**Yes, circuit-complete (zero new RTL) for representative dims** — subject to firmware numeric
contracts matching the Tier-C golden. The completeness review's concrete value: it **fixed a
real 85/256-byte golden bug** before implementation and **scoped the one open design point (S3
int32 logits)**. Implementation is 6 firmware+gate slices (S0 next), each checkpoint hex-exact.
