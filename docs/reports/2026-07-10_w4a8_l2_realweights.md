# W4A8 真權重 L2 評估 — 定案報告(ADR-0072 RTL 前置 #1)

Date: 2026-07-10 · 模型:gemma-3-270m-it(unsloth ungated 鏡像,536MB bf16)·
harness:`design/npu/sw/gemma/w4a8_l2_eval.py` + `w4a8_l2_ablation.py`(純 NumPy
全模型前向,18 層/H=640/hd=256/GQA/雙 rope/sw=512,tied lm_head)· 768 tokens
自備語料。**維度修正**:真 head_dim=256 → 每層 GEMM 權重 = 5.57MB int8
(Phase-0 表的 4.96MB 為 hd=160 假設,以本檔為準)。

## 1. 主結果(composed = 生產路徑 W4→int8-grid)

| scheme | PPL | ΔPPL vs bf16 | logit-KL | top-1 |
|---|---|---|---|---|
| bf16 | 12.07 | — | 0 | 1.000 |
| int8 per-tensor(現況代理) | 13.28 | +10.0% | 0.074 | 0.898 |
| W4A8 **sym g=64** composed | 18.88 | **+56%** | 0.637 | 0.753 |
| W4A8 sym g=32 composed | 16.30 | +35% | 0.490 | 0.766 |

**小模型 W4-RTN 風險證實**:對稱 RTN g=64 掉分不可接受級。

## 2. 歸因與補救(ablation)

- **A. composed 二次捨入代價小**:pure 17.45 vs composed 18.88 → 主損失是
  W4 RTN 本身,不是 int8-grid 方案 —— **ADR-0072 的 DMA-dequant 架構不背鍋**。
- **B. 非對稱(uint4+zp)大幅回血**:**asym g=32 → PPL 13.52,幾乎追平 int8
  (13.28)**;asym g=64 → 16.96(不夠)。
- **C. 敏感度集中**:v_proj(13.24)與 down_proj(12.88)是痛點;
  q/k/o/gate/up 單獨 W4 幾乎無損(12.1–12.5)→ 混合精度有明確候選集。

## 3. 選項與吞吐(真 5.57MB/層、18 層、460MHz;B/cyc 取正式報告實測點)

| 方案 | bytes/層 | PPL(已測) | @G2 2.86 | @長burst 4.63 | @近pin 5.4 |
|---|---|---|---|---|---|
| W8(現況) | 5.57MB | 13.28 | 13.1 | 21.2 | 24.8 |
| W4 sym g=64(不可接受) | 2.96MB | 18.88 | 24.7 | 39.9 | 46.6 |
| **W4 asym g=32** | **3.31MB** | **13.52** | 22.1 | 35.8 | 41.7 |
| 混合:v/down W8 + 餘 W4 sym g64 | 3.65MB | 未測(候選) | 20.0 | 32.4 | 37.8 |

**含 residency 組合**(Grok 帳法,常駐 1/3 層):asym g=32 有效流量 ~2.2MB/層
→ @長burst ~54、@近pin ~63 tok/s —— **50–60 目標以「W4 asym g=32 + burst +
residency」達成,品質代價 ≈ int8 現況 +2%**。

## 4. 建議(待 User 裁示)

1. **主路線:W4 非對稱 g=32**(uint4 + per-group zp;DMA dequant 加一步減 zp,
   HW 代價小)—— PPL 13.52 ≈ int8 現況;ADR-0072 格式 SSOT 需修訂
   (asym + zp 表 + g=32 default)。
2. 備選強化(可後續疊加):AWQ-lite 等效縮放(有機會把 g=64 救回、再省 10%
   流量)、混合精度(v/down W8)—— 均為 PTQ 範疇,不動架構。
3. Grok 契約 review(RTL 前置 #2)於 SSOT 修訂後執行。

## 5. 誠實界

768-token 自備語料(PPL 絕對值僅供排序,非 benchmark 宣稱);composed 已含
生產二次捨入但 `(M_g,SH)` 定點捨入未含(L1 golden 收口);KL/top-1 在 asym
g=32 仍高於 int8(0.25 vs 0.07 / 0.83 vs 0.90)——下游任務敏感度未評;A8
activation 誤差未疊加。全部可由兩支腳本重現。
