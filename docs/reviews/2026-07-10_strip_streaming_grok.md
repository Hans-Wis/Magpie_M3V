# Grok review — strip-streaming 設計確認(2026-07-10)

> 判定:架構方向通過(strip=全K×N64、2×40KB ping-pong、單 outstanding 背靠背 burst 鏈、A.2 併入)。進 ADR 三前置 + 契約缺口 7 項 + hazard 表。CLI 存留結論段。

| 2048 | 32 | 無 |

**目前形狀全整除 64 → 無 N 尾**。H=640、K=640 亦整除 K-chunk。

**必須寫死的一般化規則（即使本模型無尾）**：
1. **N residual**：`N % 64 ≠ 0` → 最後 strip 有效寬 + pad/mask 契約（mat 是否算 pad 列、writeback 是否裁切）。
2. **K residual**：`K % 64 ≠ 0` → 最後 chunk 有效長 + ACC 貢獻（A.2 必答）。
3. **N_STRIPS = ceil(N/64)**，不是 `N/64` 靜默截斷。
4. **不同 proj 共用同一 strip 硬體迴圈**；只改 descriptor（`N_STRIPS`/`W_BASE`/`K_CHUNKS`），勿 per-proj 特化 RTL。

---

## 契約缺口（簡表）

1. **Strip 內 burst 鏈狀態**：DMA 是「一條 CQ 啟動整條 10-burst」還是「ml_ctrl 逐 burst 下發」？影響 ERR 中止粒度與 soft_reset。
2. **Prefetch 啟動時機**：proj 首 strip 冷啟動（無 s−1）→ 同步 fill bank0 再開算；descriptor 是否 `PREFILL=1`。
3. **Bank 生命週期 vs CQ 多命令**：下一 proj / 下一層是否允許跨命令保留 bank？建議 **每 strip-mode 命令邊界 bank 狀態 reset**。
4. **與通用 CQ（gate_46）的 two-tier 邊界**：mode bit 位置、舊 descriptor 相容、illegal 組合表。
5. **DDR 位址對齊與 4KB 邊界**：`W_BASE % 4KB == 0` 且 strip 緊排 → 自動無跨頁；若允許 `W_STRIDE` 非緊排，要再驗每 burst 不跨 4KB。
6. **錯誤路徑**：prefetch bus ERR 時 compute 是否 drain、ACC 是否作廢、host `ERR_CAUSE` 碼。
7. **效能契約分列**：功能 exact 與 `B/cyc≥4.0` 必須分 assertion（草案已寫，ADR 要釘死，避免 green-wash 綁死）。

---

## Overlap / 正確性 hazard

| Hazard | 嚴重度 | 處置 |
|---|---|---|
| **搶跑**：prefetch 未完成就切 bank | 致命 | 雙 rendezvous（compute-done ∧ prefetch-done）—— **同意，寫進 RTL 斷言** |
| **ACC 跨 strip 誤累**：strip 邊界未 clear | 致命 | strip 邊界 **必須 ACC clear**；僅 **strip 內 K-chunk** 連續累加 |
| **DMA 寫 bank 與 mat 讀同 bank** | 致命 | bank 所有權硬互斥；交換只在 rendezvous |
| **單 outstanding 下 AR 間軟體 gap** | 效能 | burst 鏈須 **硬體自動續 AR**，禁止 per-burst 回 ml_ctrl 再發（否則空窗再現） |
| **stall 注入下 bit-exact** | 正確性 | 不依賴時序——同意；gate_97 必含 **隨機/固定 DDR stall** |
| **KV/act 與 weight 並發** | 中（本階段） | decode 時間軸互斥可接受；若未來 prefill 並發，需 AXI 優先級/時窗契約，**本 ADR 標非目標** |
| **K-chunk 內 v2 tile 與 strip 編排雙層** | 中 | 釐清：**外層 strip loop（新）+ 內層既有 K=64 tile/MAC**；避免兩套 sequencer 搶 mat |
| **首 strip / 末 strip 特例** | 中 | 首：prefill only；末：prefetch 停、只等 compute |
| **REQ/ACK 與 soft_reset 競態** | 中 | reset 清 DMA 鏈 + bank valid + ACC + rendezvous 狀態 |

---

## 總評（可進 ADR-0073 的條件）

**架構方向通過**：strip = 全-K×N=64、DDR K-major 連續、2×40KB ping-pong、單 outstanding 背靠背 burst 鏈、A.2 併入 strip 內 ACC、正確性不綁時序——與測得 DDR wall 與預算一致。

**進 ADR 前補三刀**：
1. descriptor 完整欄位 + illegal 表 + residual 政策（即使本模型無尾）。  
2. DMA = **硬體 burst 鏈**（非軟體逐 burst）。  
3. ACC clear 邊界 = **strip**；rendezvous = **唯一** bank 交換點。

**不建議本階段做**：2-AR、半-K strip 主路徑、權重塞回 DTCM。
