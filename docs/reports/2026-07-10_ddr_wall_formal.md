# DDR 牆正式報告 — 校準後有效頻寬 + decode tok/s 投影(取代基線報告 §A 之絕對值)

Date: 2026-07-10 · 基線:`2026-07-10_ddr_wall_realsize_baseline.md`(§B/§C compute
結論不變)· 量測:`tb_ml_v2_gemm` + `axi_ddr_latency_model`,q_proj B1.1 rail,
全組合 **byte-exact**(gate_94 契約)。

## 1. 校準(×16 修正 —— 重大)

Magpie_DDR G0-D1 鎖 **DDR4-3200 ×16**(pin 峰值 6.4GB/s)。G2 目標「≤6
controller-cyc/column」@800MHz、column=16B → **連續流上限 ≈2.13GB/s,不是
4.8GB/s**(4.8 源自 ADR-0004 舊 ×64 匯流排算式,×16 下不成立)。COL_CYC(NPU
460MHz,128b beat=1 column)換算:pin≈1.15、G2≈3.45、G1(13)≈7.5。

## 2. 實測矩陣(q_proj rail,bytes_rd=5,376B,dma_busy / 有效 B/cyc)

| SKU | SRAM | COL=1(≈pin) | COL=3/4(≈G2) | COL=7/8(≈G1) |
|---|---|---|---|---|
| 128b(LANES=2) | 435 | 1,226(**4.58 B/cyc**) | 1,928/2,279(**2.86/2.41**) | 3,332/3,683(1.64/1.48) |
| 256b(LANES=4)* | 251 | 1,042(5.42) | 1,376/1,543(4.06/3.60) | 2,044/2,211(2.70/2.49) |

\* 256b beat=2 columns,同一顆 DDR 對映 COL_CYC×2:256b@COL7 ≈ 128b@G2,實測
2.70 vs 2.86 B/cyc 互證。mat_busy 全程恆定(808/680)。

**核心事實:現行 per-tile burst 模式下,G2 校準點的有效頻寬 ≈2.86 B/cyc
(1.3GB/s),只有連續流上限(4.63 B/cyc)的 62%、pin(13.9 B/cyc)的 21%** ——
短 burst 反覆付首拍延遲 + 單 outstanding 空窗吃掉了大半。

## 3. Decode tok/s 投影(4.5MB/層、18 層、460MHz、完美 overlap)

| 情境 | 有效 B/cyc | cyc/層 | tok/s |
|---|---|---|---|
| G1 現況校準 + 現行 burst 模式 | ~1.6 | ~2.9M | **~8.7** |
| G2 達標 + 現行 burst 模式 | ~2.86 | ~1.65M | **~15.5** |
| G2 + 長 burst(連續流上限) | 4.63 | ~1.02M | **~25** |
| 近 pin col + 長 burst(實測 COL=1) | ~4.6–5.4 | ~0.92M | **~27** |
| ×16 pin 理論(13.9 B/cyc,需消滅全部空窗) | 13.9 | 339k | ~75(不可達之上界) |
| (參照)4.8GB/s 假設 —— 基線報告/Grok 用值 | 10.4 | 454k | 56(**×16 下不成立**) |

**結論:×16 DDR4-3200 這一顆,工程做滿(G2 + 長 burst + prefetch/double-buffer
+ overlap)落點 ≈25–30 tok/s;50–60 tok/s 需要「減字節」(權重駐留/更低位元量化
/層融合)或更寬/更快 DRAM(×32、或多 rank),不是 M3V 側再優化能補的。**
Magpie_DDR ADR-0004 的「50 tok/s」宣稱在 ×16 G0-D1 下需修訂(跨線事項,已標)。

## 4. 槓桿排序(實測背書,取代基線 §D 的 BW 細項)

1. **Burst 拉長 + streaming 權重 layout**(col-low 對齊、≥256-beat 流)+
   **prefetch/double-buffer(64–128KB)**:同一 DRAM 上 2.86→4.6 B/cyc(**~1.6×**),
   且是 overlap 的前提 —— M3V 側第一優先。
2. **Magpie_DDR G2 col-streamer**(13→6):1.6→2.86 B/cyc(**~1.8×**)—— 該線第一優先。
3. **單 outstanding 空窗**:COL=1 實測只到 pin 的 1/3 → prefetch 深度/第二 AR 評估
   進 streaming-tile 契約設計(基線 §D-3)。
4. compute 鏈(E1b/RoPE/QK-norm/softmax):所有 DDR 情境下 compute(287–353k)
   均低於牆(≥920k)→ **decode 側壓力解除,重心確認移往 prefill/功耗**(基線
   §B 結論在校準後更成立)。
5. **50+ tok/s 路線裁示項**:減字節(int4/權重共享/駐留熱層)或 DRAM 加寬 ——
   屬產品級決策,非本輪工程項。

## 5. 誠實界

模型未含 refresh/bank 交錯/W→R turnaround(向樂觀偏);burst 模式 = 現行 B1.1
tile 形狀(向悲觀偏,長 burst 版待 streaming 契約落地重測);tok/s 假設 18 層
4.5MB/層與完美 overlap;真 Magpie_DDR RTL 簽核掛接為該線 G4 後事項。全部數字
可由 gate_94 + 本報告矩陣命令重現。
