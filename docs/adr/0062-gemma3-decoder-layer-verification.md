---
status: accepted
date: 2026-07-06
supersedes: []
governs: Gemma-3 decoder-layer bit-exact e2e verification (LLM workload) — sw/gemma, sliced S0..S5
authority: Tier-C self-contained NumPy fixed-point golden (bit-exact) + fp32 reference (bounded sanity) + gemmlowp/mat_engine proof + Spike lockstep
---

# ADR-0062 — Gemma-3 decoder-layer bit-exact e2e(架構確認 + S0 foundation)

承 Gemma-3 gap 分析(`docs/reports/2026-07-06_gemma3_llm_gap_analysis.md`:LLM 功能可表達、
零 ISA 缺)。User 裁示:照 MobileNet 那樣做一個 **Gemma-3(270M 結構)decoder layer
e2e bit-exact**。本 ADR = 架構確認(Grok 全文 `docs/reviews/2026-07-06_gemma3_layer_plan_grok.md`)
+ 已驗證的數值 foundation。**誠實界:full-layer RTL 是多片工程(S0..S5),非 MobileNet
那種 runtime 直接復用;本 ADR 落地 foundation + 凍結計畫,S0 RTL 為下一片。**

## §1 環境現實 + golden 權威(非循環)
- **無 torch/transformers/HF**(已探)→ 無法載真 Gemma-3 270M 權重。故同 MobileNet(random-
  weight Keras),用 **Gemma-3 270M 結構 + 確定性 random 權重 + 小代表性 dims**(sim 可跑)。
- **三層權威(Grok)**:
  - **Tier A = fp32 NumPy reference**(`gemma_ref.py`,Gemma-3 公開 spec 數學)——**bounded
    sanity,非 bit-exact pass/fail**。
  - **Tier B = 量化契約(SSOT)**:per-tensor/per-channel scale、accumulator 寬度、requant
    recipe(= gemmlowp,已 gate 證 vs mat_engine)。**先於 RTL 凍結,RTL 不定義 scale。**
  - **Tier C = fixed-point golden**(`gemma_quant.py`,實作 Tier B 演算法)——**bit-exact
    權威**;RTL/kernel 必逐 checkpoint byte-identical。
- **非循環守則**:①Tier B 先於 RTL ②係數 algorithmic 非 fitted(gelu LUT 由 documented
  gelu_tanh 生,非調參)③GEMM golden = 既證 gemmlowp kernel(不新造 matmul golden)
  ④fp32 只做 `|dequant−fp32| ≤ bound` 邊界檢查。
- **精確 bit-exact 宣稱**:每個 named checkpoint,DUT 記憶體 == Tier C NumPy 輸出 byte-
  identical。**不宣稱** bit-exact 對 HF Gemma-3 權重、不宣稱 fp32==int8。

## §2 量化 + nonlinear 實作(RTL==NumPy 的乾淨法)
| sub-op | 路徑 |
|---|---|
| Q/K/V/O、gate/up/down proj、QKᵀ、AV | **int8 per-channel GEMM**(mat_engine,已證)|
| RMSNorm×4 + QK-norm×2 | int32 向量 reduce → **rsqrt = Q31 fixed-point 多項式** → int8 |
| RoPE | int32 rotate + **預算 Q15 sin/cos 表**(TCM)|
| causal + sliding mask | int32 score + 大負常數 |
| softmax | int32 logits → **exp LUT** → int32 sum → 整數倒數 |
| GeGLU gelu_tanh | **256-entry int8→int8 LUT**(由 documented gelu_tanh 生,bit-exact table)|
- **nonlinear 三選**:rsqrt=向量 Q31 poly · exp=LUT · gelu=LUT(或 scalar softfloat-3,
  ADR-0050 F lockstep 已證)。**gelu 採 LUT**(最簡 bit-exact:golden 與 RTL 共用同表)。

## §3 切片(MobileNet-style,一片一新機制)
| 片 | 範圍 | 復用 | 新機制 |
|---|---|---|---|
| **S0(首)** | **MLP GeGLU**(gate/up/down 3 GEMM + gelu + mul)| conv/FC GEMM+requant | **gelu_tanh LUT + int mul-requant** |
| S1 | post-attn RMSNorm + residual | S0 | rsqrt Q31 poly |
| S2 | Q/K/V proj + QK-norm + RoPE | GEMM + S1 | RoPE Q15 表 |
| S3 | QKᵀ + mask + softmax + AV | GEMM + S2 | softmax exp LUT |
| S4 | attention residual compose | S1-S3 | GQA broadcast 佈線 |
| S5 | full decoder layer | 全 | 整合 / scale handoff |

## §4 已驗證 foundation(本 ADR 落地)
- **`design/npu/sw/gemma/gemma_ref.py`**:fp32 Gemma-3 decoder layer(sandwich RMSNorm(1+w)
  + QK-norm + RoPE half-split + GQA nh=4/nkv=1 + causal + gelu_tanh GeGLU)。self-check:
  in[4,64]→out[4,64] finite。
- **`design/npu/sw/gemma/gemma_quant.py`**:Tier C int8 **S0 GeGLU** golden(2 GEMM per-channel
  gemmlowp + 256-entry gelu LUT + int mul-requant + down GEMM)。**Tier A 邊界:out 對 fp32
  max_abs_err=0.0125 / range 0.569 = rel 2.2%**(量化誤差有界,sanity 通過)。
- 小代表性 config(hidden=64/head_dim=16/nh=4/nkv=1/seq=4/inter=128)——**dims 代表性,
  非 production 270M**(誠實界;結構/機制與 270M 一致)。

## §5 綠洗守衛(Grok,強制)
fp32 不得當 bit-exact pass/fail;nonlinear 不得在 TB/host 算(必 RTL);gelu golden 不得用
`np.tanh` 當 RTL 路徑(用 documented LUT,兩邊同表);SSOT scale 凍結;checkpoint hex-exact
無 float rtol;seq≥4 且 causal/window mask 必測;DTCM ≤32KB budget assert;dims 代表性不外推
270M production 宣稱。

## §6 狀態 / 下一步
- **✅ 全層 S0..S5 完成 = Gemma-3 decoder layer 整層 e2e bit-exact on RTL(2026-07-06)**:
  - **S1**(@6573052)= RMSNorm+residual:新 CQ op `MAT_RMSNORM`(degree-3 mantissa rsqrt poly,
    coeffs 走 golden param blob = 零 firmware 常數,非循環 SSOT)+ `MAT_EWISE_ADD_REQUANT`;
    freestanding `__ashldi3/__lshrdi3/__ashrdi3`(64-bit var shift,-nostdlib),row-mean 除法
    留 32-bit 避 `__divdi3`。gate `gate_gemma3_s1_rtl`。
  - **S2**(@9e933da)= Q/K/V proj + QK-norm + RoPE:proj 複用 mat_engine;QK-norm 複用
    `MAT_RMSNORM`(H=head_dim,新 `emit_rmsnorm_rows`);新 `MAT_ROPE`(neox rotate-half + Q15
    cos/sin 表 + gemmlowp requant)。gate `gate_gemma3_s2_rtl`(7 checkpoint)。
  - **S3**(@745cf24)= QK^T + causal mask + softmax + AV,**head-batched(GQA nkv=1)**:
    QK^T/AV 複用 per-channel GEMM(key-dim padding 到 8);新 `MAT_SOFTMAX`(per-row causal,
    `EXP_LUT[mx-s]`,`prob=(e*127+sm/2)/sm` uint32 除法)。gate `gate_gemma3_s3_rtl`。
  - **S4+S5**(@54cec19)= 全層整合(**零新 op**):`gemma_quant_layer.layer_int8` scale-chained
    整層 golden;`gate_gemma3_layer_rtl` 把整條 ~20 步鏈跑在 RTL、逐步餵前一步真輸出、**每個
    checkpoint(RMSNorm_in/proj/QK-norm/RoPE/QK^T/softmax/AV/o_proj/x_mid[S4]/preffn/gelu/mul/
    down/x_out[S5])byte-identical**。fp32 bound:x_mid 2.9%、x_out 7.4%。
  - firmware text 2108→3980B(ITCM 8K,充裕)。18 gemma test 全綠。
- **本 ADR(原文)= foundation + 計畫凍結**(fp32 ref + Tier C S0 golden 已驗)。
- **✅ S0 GeGLU RTL e2e 完成(@69212c1)**:3 GEMM 走 mat_engine;nonlinear(gelu 256-LUT、
  mul-requant)走 sequencer 韌體,經新 CQ op `MAT_ACT_LUT`/`MAT_EWISE_MUL`(nonlinear-in-RTL,
  非 host);host-chained 5-step,每 checkpoint(gate/gelu/up/prod/out)對 Tier-C **hex-exact**。
  gate = `sim/gates/gate_gemma3_s0_geglu.py`(2/2);全 6 tflm gate 不回歸(16/16)。
  完整性 review(Grok+Codex)+ golden requant 修(對 mat_golden bit-exact,§ADR-0062 non-circular)
  見 `docs/reports/2026-07-06_gemma_s0s5_completeness.md`;TCM-relocation blocker 修法見
  `docs/reports/2026-07-06_gemma_s0_e2e_blocker.md`。
- **下一步(全層已達標後)**:多層堆疊 / 真 270M 權重(需 torch/HF 環境,目前無)/ 非-unit-stride
  KV-cache(deferred);或轉架構優化(attention GEMM padding-to-8 的 throughput、softmax/rsqrt
  多拍化)。皆非本 ADR 範圍。
- gate(foundation)= `sim/gates/gate_83_gemma3_foundation.py`(golden 自洽 + fp32 bound);
  RTL e2e = `gate_gemma3_s0_geglu` / `_s1_rtl` / `_s2_rtl` / `_s3_rtl` / `_layer_rtl`。
