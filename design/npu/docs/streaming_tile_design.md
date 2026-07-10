# Streaming-tile 契約 + double-buffer(設計確認草案,§2 —— 待 Grok review)

Status: **REVIEWED — Grok 通過架構方向(docs/reviews/2026-07-10_strip_streaming_grok.md);
三前置已併入 §6,契約細節於 ADR-0073 凍結後落 RTL**
Date: 2026-07-10 · 依據:`2026-07-10_ddr_wall_formal.md`(2.86 B/cyc@G2-cal、
短 burst 首拍稅、單 outstanding 空窗)· 真尺寸基線 §C(320 tiles/proj 編排稅)

## 1. 問題(兩個假設同時失效)

1. v2/CQ 假設「權重已常駐 SHARED_MEM」—— 真尺寸 5.57MB/層不可常駐,必須
   DDR 串流。
2. 現行 per-tile(K=64×N=64=4KB)短 burst 反覆付首拍延遲 → G2-cal 只到
   2.86 B/cyc(連續流上限 62%)。

## 2. 核心提案:v2 strip-streaming(#1 與 #2/A.2 合一)

- **Strip = 全-K × N=64 tile 條**(K=640 → 40KB int8;GEMM 天然消費單位)。
- **權重 blob 佈局(契約)**:DDR 內按「層 → proj → strip 序 → K-major」
  連續排列,col-low page-hit 對齊;一個 strip = 一條 ≤256-beat INCR burst 鏈
  (128b × 256 beat = 4KB/burst,strip = 10 burst 背靠背)——首拍稅攤提 10×,
  目標有效 ≥4.0 B/cyc@G2-cal(gate 驗)。
- **Double-buffer:2×40KB = 80KB**(64–128KB 預算內;實體 = npu domain 新
  strip-SRAM,dual-bank ping-pong;**不佔 DTCM**)。npu_ml_ctrl 計算 strip s
  時,DMA 預取 strip s+1 入另一 bank。
- **A.2 同時解決**:mat_engine 對 strip 內 K-chunk(64)連續累加(ACC bank
  不清),K=640 = 10 chunk —— strip 編排 = 硬體迴圈(npu_ml_ctrl 擴充),
  **per-proj 編排稅 320 tiles×6op → ~10 strip 級 launch**,真尺寸強制項落地。
- activation 常駐 TCM(B1 activation-stationary 不變);writeback 路不變。

## 3. 介面/契約增訂(凍結候選,Grok review 標的)

- CQ/ml_v2 descriptor 增 strip 模式:`W_BASE(DDR)`、`STRIP_BYTES`、
  `N_STRIPS`、`K_CHUNKS`;**廢除「權重 TCM 位址」假設**(fast path)。通用
  CQ 路(gate_46 類)不動 —— two-tier 誠實延續(M3b-2 先例)。
- npu_dma:strip 預取 = burst 鏈產生器(位址連續,無 4KB 跨越,單 outstanding
  背靠背 AR);ERR_ALIGN 語意沿用。
- **正確性不依賴時序**:任一 DDR stall 下 bit-exact(gate_94 已立基線);
  buffer 交換 handshake = compute-done ∧ prefetch-done(雙 rendezvous,無
  搶跑)。
- KV/activation 流量與 weight 流互斥窗(decode 時間軸 = 純 weight 大流;
  Grok 先前判準)。

## 4. 驗證計畫

1. `gate_97_strip_stream`:ddr_latency_model 三 preset 下 strip-GEMM
   bit-exact vs 非串流 golden + **故意 stall 注入**仍 exact + **B/cyc ≥4.0
   @G2-cal** 效能斷言(perf gate 與功能 gate 分列)。
2. `gate_98_strip_orchestration`:strip launch 編排稅實測(目標 per-proj
   ≤ ~2k core*)+ ml_v2 既有 gate_67 零回歸。
3. BW scoreboard(bytes vs cyc 帳)+ burst 紀律 checker(model 內建)沿用。
4. DC 快掃 strip-SRAM(80KB)面積參考(非 signoff)。

## 5. 待 Grok review 的判斷點

(a) strip-SRAM vs DTCM 擴容的取捨;(b) 80KB(2×40KB)vs 更小 strip 分段
(K=320×2)的 buffer/效率 trade;(c) 單 outstanding 背靠背 AR 是否足以貼
G2 連續流(或需 2-AR);(d) descriptor 契約欄位完備性;(e) H=640 下 N 尾段
(640=10×64 整除,無尾)與其他 proj 形狀(N=1024/2048/640)的一般化。

## 6. Grok review 併入(進 ADR-0073 的凍結項)

1. **DMA = 硬體 burst 鏈**:一條 strip 命令觸發 10×256-beat burst 自動續 AR
   (禁止 per-burst 回 ml_ctrl 軟體下發 —— 否則單 outstanding 空窗再現)。
2. **ACC clear 邊界 = strip**;僅 strip 內 K-chunk 連續累加;**rendezvous
   (compute-done ∧ prefetch-done)= 唯一 bank 交換點**,RTL 斷言。
3. **descriptor 完整欄位 + illegal 表 + residual 政策**:N_STRIPS=ceil(N/64)、
   K/N 尾段 mask/pad 契約寫死(本模型全整除仍必須凍結);同一 strip 硬體迴圈
   服務所有 proj(僅 descriptor 參數化,禁 per-proj RTL 特化)。
4. 契約缺口收口:首 strip PREFILL 冷啟動、命令邊界 bank 狀態 reset、two-tier
   mode bit/illegal 組合、W_BASE 4KB 對齊 + 緊排(免跨頁驗證)、prefetch bus
   ERR → drain + ACC 作廢 + ERR_CAUSE 新碼、soft_reset 清 DMA 鏈/bank/ACC/
   rendezvous。
5. 效能斷言(B/cyc≥4.0)與功能 bit-exact **分列 assertion**(green-wash 守衛)。
6. 本階段不做:2-AR、半-K strip 主路徑、權重回 DTCM(Grok 明確)。
