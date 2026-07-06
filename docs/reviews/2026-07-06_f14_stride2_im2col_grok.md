## 1. Zero-RTL thesis — correct, with one software-contract caveat

**Verdict: circuit-sufficient for stride-2 VALID + SAME-pad standard Conv2D**, assuming dilation=1 and the existing GEMM path (im2col rows → `lower_layer_v2` → CQ → mat_engine → per-channel requant → store).

Stride and padding are fully determined by **which int8 values land in `rows[n][K]`**. The mat_engine/CQ/DMA only see a dense `[M × K] × [K × N]` GEMM; they have no notion of `H`, `W`, `S`, or pad. That matches your architecture.

**No hidden RTL gap** for correctness, if:
- im2col is the sole place that maps `(oy, ox, ky, kx, ci)` → linear index with `oy*S+ky`, `ox*S+kx`
- SAME pad cells are filled with **`input_zp`** (raw quantized storage value), not literal 0
- `lower_layer_v2` row count `M = oh*ow` and `K = Kh*Kw*Ci` reflect the new geometry

**Non-RTL risks** (still F1.4 scope):
- **Buffer sizing / CQ batching** in firmware or host runtime may assume stride-1 `oh/ow` — contract bug, not mat_engine bug
- **Shared-mem footprint** for the im2col matrix must be recomputed for new `M`; no new opcode needed

Strided/2D DMA (ADR-0043) is a **bandwidth/perf** lever for gather, not a correctness requirement for F1.4.

---

## 2. int8 correctness — `input_zp` padding is right; preserve geometry + fold chain

**Padding with `input_zp` is the correct TFLM asymmetric-int8 semantic.** TFLM conv runs in the “input_offset” domain: effective term is `(q - input_zp) * w`. Padded positions at `q = input_zp` contribute 0, which matches your fold `acc += input_offset * sum(w)` with `input_offset = -input_zp`.

**Must preserve unchanged** (already on stride-1 path):
- Per-channel `weight_scale`, `output_multiplier`, `output_shift`, `output_zp`
- Bias in accumulator domain **before** requant (TFLM order)
- Min/max clamp after requant
- Per-channel requant applies per output channel across all spatial outputs — strided `M` does not change that

**Real pitfalls are geometric, not requant:**
| Pitfall | Why it breaks bit-exact |
|--------|-------------------------|
| Wrong `oh/ow` formula | Off-by-one vs TFLM `PaddingType::kSame` |
| Asymmetric pad split | TF/TFLM distributes `pad_total` unevenly (e.g. top≠bottom); “symmetric pad” is wrong |
| Pad with 0 instead of `input_zp` | Wrong when `input_zp ≠ 0` (common) |
| VALID vs SAME conflation | Same kernel/stride can differ in `M` and pad |

No new interaction with bias fold or output clamp **if** im2col only changes *which* activations enter the dot product; the mat_engine math stays identical.

---

## 3. Scope — ship VALID + SAME together; defer dilation

**F1.4 should be stride-2 VALID + SAME together** if the goal is VWW + ResNet-8 unblock. Those models use SAME (or equivalent) early; VALID-only does not close F1.4.

**Split only for debug**, not delivery:
- Phase A: stride-2 VALID (isolates indexing)
- Phase B: SAME on top (isolates pad distribution)

No reason to split for signoff if the gate already uses full-model TFLM golden.

**Dilation: out of scope** for F1.4 unless you prove a target layer needs `dilation>1`. Standard ResNet-8 / VWW are `dilation=1`. Document explicit exclusion; add when a gated model requires it.

Also out of scope unless already supported: depthwise/group conv, fused activations beyond what TFLM export already folds.

---

## 4. Green-wash guards for the gate

Minimum assertions so the test cannot pass on stride-1 or fake equivalence:

1. **Config lock**: test metadata asserts `stride_h == stride_w == 2` and `padding == SAME` (or explicit VALID case); fail if stride=1.
2. **Output shape lock**: assert `oh, ow` match TFLM tensor shapes for that layer — not the stride-1 reference shape (e.g. 32×32, K=3, S=2 VALID → 15×15, not 30×30).
3. **Row-count lock**: assert `M = oh*ow` passed to CQ/mat path differs from stride-1 baseline on the **same** input tensor.
4. **TFLM golden, named layer**: bit-exact compare against real `.tflite` inference for a layer (or full model) that **requires** S=2+SAME — not a synthetic stride-1 CNN re-labeled.
5. **Asymmetric SAME case**: at least one testcase where `pad_top ≠ pad_bottom` or `pad_left ≠ pad_right` (even H/W + S=2 provokes this).
6. **Non-zero `input_zp`**: padding semantics only bite when `input_zp ≠ 0`; include such a layer.
7. **No TB shortcut**: im2col runs on firmware/host production path, not a Verilator DPI stub that injects precomputed stride-1 rows.
8. **Intermediate spot-check** (strong): for one pixel, log or compare a row against NumPy/TFLM reference gather — proves strided indices, not just final output collision.
9. **Regression**: existing stride-1 gate_50 (or equivalent) still green — proves you didn’t break the fold path.

---

## 5. Performance caveat — worth recording

Yes — record explicitly:

| Today (F1.4) | Future lever |
|-------------|--------------|
| Software im2col: scalar gathers, non-contiguous reads for S=2 | Hardware strided-gather / fused im2col DMA |
| Materializes full `[M×K]` in shared mem | Could stream patches into mat_engine without full expansion |
| S=2 cuts `M` ~4× but **increases gather irregularity** vs S=1 | Lower CPU/firmware time + lower memory traffic |

Functional replaceability does not require hardware im2col now. This is **perf lever #2** (after mat_engine throughput): correctness now, bandwidth/latency later. Note for MLPerf: end-to-end may be bound by im2col on the host or NPU scalar core before mat_engine limits.

---

**Bottom line:** Your thesis holds. F1.4 is a **quantized-geometry + im2col contract** change; RTL stays untouched. Success hinges on **TFLM-identical SAME pad amounts/distribution** and gates that **prove S=2 changed `M` and sampling**, not just final tensors matching by accident.
