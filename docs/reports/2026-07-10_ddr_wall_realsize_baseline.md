# DDR 牆 Step-1 基線 — latency model 實測 + 真尺寸 compute 微基準

Date: 2026-07-10 · 設計確認:`design/npu/docs/ddr_wall_step1_design.md` ·
gates:`gate_94_ddr_latency_model` / `gate_95_realsize_compute`(可重跑)·
Grok 前置分析:`docs/reviews/2026-07-10_perf_ddr_budget_grok.md`

## A. DDR-latency 軌實測(ml_v2 q_proj,`axi_ddr_latency_model`)

三個 preset 全 **byte-exact**(時序不改資料 = overlap 正確性基線)+ 4KB/INCR
紀律 checker 實證會 fire。q_proj B1.1 rail(12,800B 權重讀):

| 記憶體 | total cyc | mat_busy | **dma_busy** | other |
|---|---|---|---|---|
| 1 拍 SRAM 替身(現行全部數字的前提) | 1,129* | 680 | 251 | ~200 |
| DDR model `COL_CYC=1`(理想) | 5,209 | 680 | **4,336** | 193 |
| DDR model `COL_CYC=6`(G2 達標) | 21,739 | 680 | **20,856** | 203 |
| DDR model `COL_CYC=13`(G1 現況) | 44,857 | 680 | **43,984** | 193 |

\* 1,129 為 @256b SKU 先前量測;本 TB 預設 32b SKU,SRAM 基線 dma=251 同量級。

**校準誠實界**:本 TB 為 32b DMA SKU,`COL_CYC` 按每 AXI beat 計 → 絕對值對
128b 原生 beat 悲觀 ~4×。**量級結論不受影響**:mat=680 恆定、dma 漲 17–175×,
**牆完全由記憶體側主宰**;G1→G2(13→6)= rail 直接 2.06×,印證 Grok「G2 是跳變
級槓桿」。後續:preset 對映到 128b beat + NPU/controller 時鐘比的正式校準表。

## B. 真尺寸 compute 微基準(NPU 核,TCM 級 1 拍記憶體,kernel verbatim 摘錄)

| Kernel | 尺寸 | cyc/op | 每層次數 | 每層小計 |
|---|---|---|---|---|
| rmsnorm_rvv | 640 | 16,984 | ×4 | 67,936 |
| rmsnorm_rvv(QK-norm) | 160 | 5,104 | ×5(4Q+1K 假設) | 25,520 |
| **ewise_mul_scalar** | **2048** | **93,252** | ×1 | **93,252** |
| ewise_add_rvv | 640 | 12,810 | ×2 | 25,620 |
| rope_scalar | 160 | 10,637 | ×5 | 53,185 |
| softmax_scalar | 4 / 64 / 256 | 352 / 5,482 / 21,992 | ×4 heads | 1.4k / 21.9k / **88k** |

**非線性合計 ≈ 287k(seq=64)~ 353k(seq=256)/層**,vs ~431k cyc/層 DDR 串流牆
(4.8GB/s、@460MHz、~4.5MB 權重):**現況剛好貼牆**;E1b(ewise→RVV,93k→~15k 預期)
+ RoPE RVV(53k→~15k)後 ≈ **170–230k,穩定藏於串流之下**——Grok 估算(~250k)獲數據
支持,「compute 必須壓到牆下才能全額 overlap」成立。

## C. 新發現(toy 幾何隱藏的強制項)

真尺寸 gate/up_proj = **(2048/64)×(640/64) = 320 tiles/proj**(toy 僅 16)。
未上 v2 的通用 CQ 編排稅 = 320 × 6 op × ~187 cyc ≈ **359k/proj** —— 單一 proj 即
超過全部非線性合計。**mat_engine v2 全層化(含 K>64 multi-chunk Phase A.2)在真
尺寸不是優化,是強制項**,優先級升至與 E1b 同級。

## D. 攻擊序定案建議(數據背書)

1. **端到端有效 BW**(Magpie_DDR G2 + 128b 校準 + double-buffer 64–128KB 配置)
   —— decode tok/s 唯一槓桿(27→59 級)
2. **v2 全層化 + Phase A.2(K>64)** —— 真尺寸強制項(§C)
3. **E1b ewise_mul RVV**(93k→~15k)+ **RoPE RVV**(53k→~15k)—— 把 compute 壓進牆下
4. **QK-norm RVV**(25.5k→~8k)—— 模板複用,低風險
5. **softmax recip+RVV 契約預埋** —— seq=256 時 88k/層,隨 seq 惡化(§B 實證)

誠實界:微基準無 CQ 編排稅/無 DMA;層合成用列明的 op-count 假設;DDR 絕對值
待 128b 校準;真 Magpie_DDR RTL 簽核掛接為該線 G4 之後事項。
