---
status: accepted
date: 2026-07-06
supersedes: []
governs: MobileNet-class depthwise-separable block e2e — host lowering (tflm_aot), no RTL change
authority: TFLM BUILTIN_REF interpreter golden + Spike/NumPy gemmlowp + RTL bit-exact (gate_82)
---

# ADR-0061 — MobileNet depthwise-separable block e2e(架構確認 + 實作記錄)

承 ADR-0039/0041/0042(TFLM FC/MLP/CNN e2e)。North Star = 功能取代 Coral,終需跑真實
MobileNet-class 模型。本 ADR 建立**第一個 depthwise-separable block e2e**,並回答關鍵
架構問題:**depthwise conv 是否需要 RVV strided/indexed 或新 datapath?→ 不需要。**

## §1 架構確認(Coral 對照 + 可行性)
- **Coral 對照**:MobileNet = depthwise-separable conv(depthwise 3×3 per-channel spatial
  + pointwise 1×1)+ pooling + FC,全 int8。depthwise 是 MobileNet 的核心、也是唯一非-標準-
  GEMM 的算子。
- **問題**:depthwise `out[p][c] = Σ_tap in[p+tap][c]·k[c][tap]`,channel c 在 input 與
  kernel **耦合**,不是 mat_engine 的 shared-K GEMM(`acc[r][c]=Σ_k a[r][k]·b[c][k]`,
  a/b 獨立)。
- **關鍵映射(zero RTL / zero runtime change)= block-diagonal conv**:把 depthwise 降成
  **標準 conv,但權重 block-diagonal(channel-masked)**:`w[c][k] = dwkernel[c][tap]`
  當 `channel(k)==c` 否則 `0`,over 完整 im2col `K=kh·kw·cin`。則
  `out[p][c] = Σ_{k=0}^{K-1} rows[p][k]·w[c][k] = Σ_{channel(k)==c} patch·kernel` =
  **精確 depthwise int32 累加**(被歸零的 off-channel taps 在 int8×int8→int32 貢獻恰 0)。
  per-channel requant 走既有 RESCALE_PC。代價 = ~1/8 陣列利用率;**mat_engine/npu_dma/
  conv-lowering 既有路證明足夠**(Explore agent 可行性分析 + 本 ADR 實測)。
- **pointwise 1×1 = 純 GEMM**(K=cin)→ 既有 conv 路原樣。
- **scope(本片,誠實界)**:VALID padding + stride-1(既有 im2col 限制)。MobileNet 的
  SAME padding + stride-2 是**純 host im2col/pooling codegen 缺口**(非 datapath、非 RVV),
  列為 follow-up。

## §2 契約 + 實作
- **offline**(`IP/npu/sw/tflm_aot/build_model_dw.py`):Keras `[1,6,6,8] → DepthwiseConv2D
  3×3 VALID relu → Conv2D 1×1 cout=8 relu` → full-int8 tflite → BUILTIN_REF golden(全中間層)。
  `_dw_block_diagonal`:DEPTHWISE weight `[1,kh,kw,cin]` → block-diagonal `[cout=cin][K=72]`
  於 runtime im2col k-order `(ky,kx,ci)→k=(ky·kw+kx)·cin+ci`;per-channel scale 沿 cin→cout。
- **runtime = 零改動**:兩層都 emit 成 `kind="conv"`,走既有 `lower_layer_v2`(im2col GEMM
  + K-chunking 72→64+8 + fold `bias+input_offset·Σw` + RESCALE_PC + STORE)。
- **RTL = 零改動**:mat_engine/npu_dma/npu_tcm 原樣。

## §3 驗證計畫 + 結果(三重權威)
1. **NumPy(gemmlowp 忠實 requant)== TFLM golden bit-exact**:block-diagonal DW + PW 逐
   pixel 逐 channel 符(架構確認,獨立於 RTL)。
2. **RTL == TFLM golden bit-exact**(gate_82,`tb_npu_tflm_model`):round1 DW block-diagonal
   conv(K=72 chunked 64+8,16 pixel=2 row-group)→ **depthwise 中間層 bit-exact**;round2
   1×1 conv over **實際 RTL DW 輸出** → **final bit-exact**。
3. **provenance**:TF regen 全 artifact byte-exact。
- green-wash 守衛:per-channel scale distinct(8 個)assert、K 必 chunk(≥2)assert、
  pointwise 必 1×1 assert、round2 餵**真 RTL DW 輸出**(非 golden)驗鏈路。
- **三方 review**:**Codex + Grok 皆「no green-wash or correctness issue found」**——
  逐項驗:①golden 取自真 DEPTHWISE_CONV_2D(非 block-diagonal 自證,不可繞)②k-order
  `(ky,kx,ci)` 與 im2col + `[1,kh,kw,cin]` 一致(對稱 shape 未遮蔽 transpose——round1
  bit-exact 釘死 row-major)③fold 全-row sum 對 block-diagonal 塌回 9-tap ④round2 NHWC
  reshape 正確(round1 綠即證)⑤scope 誠實(未宣稱跑 native DEPTHWISE op / stride-2 / SAME)。
  Gemini quota-blocked(同 E2/E3/F)。

## §4 結論(對 North Star / Coral)
- **NPU 可跑 MobileNet-class depthwise-separable block e2e bit-exact,零 RTL 改動、零新
  RVV 記憶體**。depthwise **不需** strided/indexed(走 offload 路);Zve32x Phase-E tail
  的 strided/indexed 維持 deferred(誠實 scope-cut,見報告 `2026-07-06_zve32x_completeness.md`)。
- **剩餘(全 host 軟體,非 datapath)**:SAME padding + stride-2(im2col/pool codegen)、
  variable-window global-avg-pool、multi-layer driver → 完整 MobileNet 的 follow-up。
- gate = `tests/gates/gate_82_tflm_depthwise_e2e.py`。
