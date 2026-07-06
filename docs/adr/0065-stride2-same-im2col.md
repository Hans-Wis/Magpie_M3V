# ADR-0065 — F1.4: stride-2 + SAME-padding conv via software im2col (zero RTL)

- Status: **accepted**
- Date: 2026-07-06
- Deciders: User (F1.4 pick), Claude (PL/verify), Grok (architecture review)
- Related: ADR-0042 (per-channel conv + K-tiling), ADR-0061 (MobileNet depthwise via
  block-diagonal), ADR-0064 (benchmark/perf pivot, F1 roadmap)
- Review: `docs/reviews/2026-07-06_f14_stride2_im2col_grok.md`

## Context

The Conv2D offload path lowered only **VALID, stride-1** convs (`im2col()` hard-asserted
`stride == 1`). MLPerf **VWW** (MobileNetV1) and **ResNet-8** need **stride-2** convs with
**SAME** padding; KWS's production first conv is stride-2 too. The open question (per the
§0 mission: avoid missing circuit that forces heavy software) was whether stride-2 needs new
RTL.

## Decision

Implement stride-2 + VALID/SAME padding as a **pure software `im2col()` change — zero new
RTL.** Stride and padding are fully determined by *which* int8 values land in `rows[M][K]`;
the mat_engine / CQ / DMA only ever see a dense `[M×K]·[K×N]` GEMM and have no notion of
`H/W/S/pad`. This is the same "offload path is sufficient" lesson as ADR-0061 (depthwise).

Mechanics (`sim/models/tflm_runtime.py`):
- `conv_out_geometry()`: TFLM geometry — SAME `oh = ceil(H/S)`,
  `pad_total = max((oh-1)*S + K - H, 0)`, `pad_before = pad_total // 2` (remainder at
  bottom/right — TFLM's **asymmetric** split, the #1 bit-exactness pitfall).
- `im2col()`: samples `x[oy*S+ky-pt][ox*S+kx-pl][ci]`; **out-of-bounds taps are filled with
  the INPUT ZERO-POINT** (`input_zp`), so padded taps contribute 0 through the existing
  `input_offset*sum(w)` fold — the correct quantized-conv semantic (bites only when
  `input_zp ≠ 0`). K order `(ky,kx,ci)` matches the `[cout,kh,kw,cin]→[cout,K]` weight
  flatten. Backward-compatible (stride-1 VALID default → identical rows).

**Scope:** stride-2 VALID+SAME, dilation=1 (explicitly excluded until a gated model needs it).

## Verification (authority = bit-exact vs real TFLM through the real mat_engine)

`sim/gates/gate_96_stride2_conv_e2e.py` — a `[1,6,6,8] → Conv2D 3×3 c8 stride-2 SAME →
[1,3,3,8] → Dense(8)` int8 model (`build_model_stride2.py`), golden = BUILTIN_REF TFLM
inference. All of Grok's green-wash guards:
- config lock (stride==2, padding==same); output-shape lock (oh,ow==3, not the stride-1 6/4);
- row-count lock (M=9, not stride-1's 16/36);
- **asymmetric SAME** case (pad_top=0 ≠ pad_bottom=1) with **non-zero input_zp (=-86)**;
- intermediate row spot-check (bottom pixel's OOB taps == input_zp, in-bounds == strided x);
- **bit-exact e2e through the real mat_engine RTL on Verilator** (no DPI stub);
- provenance regen; and regression (stride-1 gate_50/gate_82 stay green).

Result: **3/3 pass**; stride-1 conv/depthwise regression green.

## Consequences

- Clears the **stride-2** part of the VWW / ResNet-8 / KWS blockers (bench.yaml narrowed).
  Remaining, honestly: VWW = full-model host codegen; ResNet-8 = fused residual-add; KWS =
  global-avg-pool. These are software/mechanism items, not circuit gaps.
- **Perf caveat (recorded):** software im2col does scalar, non-contiguous gathers and
  materializes the full `[M×K]` matrix; stride-2 cuts M ~4× but raises gather irregularity.
  A hardware strided-gather / fused-im2col DMA is **perf lever #2** (after mat_engine
  throughput) — correctness now, bandwidth later. End-to-end may be im2col-bound before the
  mat_engine limits.
