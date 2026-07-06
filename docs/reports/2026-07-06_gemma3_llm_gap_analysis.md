# Gemma 3 LLM 推論 — Zve32x 缺口評估

> 日期 2026-07-06 · HEAD `eb5b3a5` · 承 `2026-07-06_zve32x_completeness.md`(該報告針對
> CNN;本報告把 workload 換成 **Gemma 3 LLM 推論**)· 方法 = 我方能力(vexu.v/fexu.v/
> mat_engine.v code-check)× Gemma-3 算子圖 × Grok 架構交叉檢查(`scratchpad/grok_gemma.log`)。

## 0. 結論(誠實界)

**Gemma 3 int8/int4 推論在現有 stack 上「功能可表達」——正確性所需的 ISA 新增 = 0。**
沒有任何 Gemma-3 算子被**架構性阻塞**。真正的限制是 **① 系統(記憶體容量/頻寬)② 吞吐**,
不是缺 opcode。Zve32x 的「缺口」(vluxei / masked-reduction / vlse / 更寬 gather)全是
**效能/便利**,非功能。

> 關鍵背景:**Coral Kelvin 本身也是 Zve32x 整數 + scalar-F**。凡 Coral 用 int8+LUT+scalar
> 做的(softmax、GELU、rsqrt),我方同樣做得到 = **parity,非缺口**。

## 1. Gemma-3 算子 → 我方 primitive

| Gemma-3 元件 | 主要 primitive | 覆蓋 |
|---|---|---|
| token embedding | host 算 offset → **contiguous row DMA**(unit-stride)→ vle | ✅(系統受限)|
| Q/K/V/O 投影、MLP gate/up/down | **mat_engine int8 GEMM + per-channel requant** | ✅ |
| GQA head repeat | vmv/splat/vrgather(m1) | ✅ |
| RoPE | vmul/vadd/vsub + half-swap(vslide/vrgather)+ **預算 sin/cos 表** splat | ✅ |
| QKᵀ / attn@V | GEMM 或 RVV dot(vredsum)| ✅ |
| scale(√d)| vsmul / scalar | ✅ |
| causal + sliding-window mask | vmseq/vmslt + mask logicals + **vmerge** | ✅ |
| softmax | vredmax → vsub → exp(poly/LUT/scalar)→ vredsum → 倒數(vdiv/reciprocal)| ✅(kernel-heavy)|
| RMSNorm | vmul 平方 → vredsum → **scalar-F rsqrt** → vsmul weight | ✅ |
| GeGLU/GELU | vmul(gate ⊙ GELU(up)),GELU via poly/LUT/scalar | ✅ |
| int4 權重解包 | **vand/vsrl/vor** nibble unpack → mat 路 | ✅ |
| residual add | vadd | ✅ |
| KV cache 讀寫 | 佈局 `[..][seq][head_dim]`(head_dim 連續)→ **unit-stride** vle/vse + scalar 外迴圈 | ✅(佈局紀律)|

## 2. 六個關鍵疑點的判定

- **(a) 超越函數(GELU/exp/tanh)**:int8 LLM 標準做法 = 寬化 fixed-point + LUT 或
  **低階多項式**。**不需 vluxei**:
  - **fixed-point 多項式(推薦,零缺口)**:GELU/exp/SiLU 用 minimax 多項式,Horner 以
    **vmul/vmac/vadd/vsra** 求值 + shift/mask 做 range-reduction —— **全用我方既有整數
    向量 op,無需 LUT/gather**。這是「零 ISA 缺口」的乾淨向量路。
  - **scalar LUT**:extract → `lw table[idx]`(DTCM)→ 回寫。功能完整,慢。
  - **vrgather-LUT 限制(誠實補述,較 Grok 保守)**:vrgather **m1 ≤16 entries**,裝不下
    256-entry 表 → 只適合 ≤16-entry 小表;完整表得 scalar 或多項式。
- **(b) causal-masked softmax**:**不需 masked reduction**。`vmerge(mask, scores, −INF)`
  → 無遮罩 vredmax;sum 前把遮罩 lane merge 成 0 → vredsum。canonical 替代。
- **(c) RMSNorm rsqrt**:**scalar-F 足夠**(每 norm group 一次 rsqrt;hidden reduce 走
  vector)。vector rsqrt 需 Zve32f = 反 Coral-parity,不做。
- **(d) KV-cache**:佈局 head_dim 連續 → **unit-stride 足夠**。vlse 只在拒絕佈局紀律
  (`[head_dim][seq]`)時才需 → 低 ROI。
- **(e) embedding gather**:**host contiguous row DMA 足夠**(autoregressive decode 一次
  一 token)。vluxei 只加速 batch-prefill 隨機索引。大 vocab(~256K)表在外部記憶體 =
  **系統**,非 RVV 缺。
- **(f) RoPE sin/cos**:**預算表 + splat 足夠**,runtime 無超越函數。

## 3. 缺口分級(Gemma-3,依 ROI)

| 級別 | 項目 | 阻塞 Gemma? | 說明 |
|---|---|---|---|
| **A 功能阻塞** | **無** | — | 全算子圖今日可表達 |
| **B 系統(主宰)** | TCM 容量 / 權重+KV DRAM 頻寬 | 否(慢)| **270M/1B 權重 + KV 佔 wall-clock;32KB DTCM 裝不下模型,必 stream**——比任何 opcode 大 |
| C Zve32x 便利 | **vluxei/vsuxei** | 否 | 加速 LUT-softmax/GELU + wide embedding prefill(= Phase-E 已 deferred 項)|
| C | **masked vredmax/vredsum** | 否 | softmax/RMSNorm 更省(免 vmerge+sentinel)|
| C | vrgather >m1 / vrgatherei16 | 否 | 更寬 LUT uop |
| D 低 ROI | vlse | 否 | 只在拒絕佈局紀律時 |
| — 不做 | **vector FP(Zve32f)** | 否 | scalar-F 已夠;向量 FP **反 Coral-parity** |

**真正的 Zve32x ISA 缺(對 Gemma-3)= vluxei、masked-reduction、vlse、wider-gather ——
全部效能/便利,零功能阻塞;且恰好 = Phase-E 已記錄的 deferred 項。**

## 4. 底線 + 對 roadmap 的建議

- **功能上**:Gemma-3 270M/1B int8/int4 **今日可正確跑出 token**(慢、記憶體頻寬綁定,
  一如任何小型 edge NPU 跑 1B LLM)。**零 ISA 新增**。
- **實用延遲**:優先序 = **① 系統(KV 策略 + 權重 streaming + 記憶體 sizing)**(非 RVV)
  → ② `vluxei` + masked-reduction(Phase-E 回收,若量測證明 softmax/prefill 主宰)。
- **不要為 LLM 加 Zve32f**——scalar-F 已覆蓋 rsqrt,且破壞 Coral-parity 敘事。
- **落地建議**:Gemma-3 先當 **firmware/kernel 練習**(在現有 ISA 上),用 §2(a) 多項式
  activation + §2(b) vmerge-softmax + scalar rsqrt;**先做一個 decoder-layer e2e bit-exact**
  (如 MobileNet block 那樣)驗證,再依量測決定是否回收 Phase-E vluxei/masked-reduction。

## 5. 誠實界聲明
- 「功能可表達」= 可跑出正確 token(有 golden 背書時);**尚未實作任何 LLM kernel**
  (softmax/RMSNorm/attention 在 NPU sw 目前為 0,grep 證)——這是 **kernel 工作**,非 ISA 缺。
- 「取代 Coral 於 LLM」的真門檻 = **系統(記憶體/頻寬)+ kernel 庫**,非向量 ISA;
  向量面已達 Coral-class(同為 Zve32x 整數 + scalar-F)。
