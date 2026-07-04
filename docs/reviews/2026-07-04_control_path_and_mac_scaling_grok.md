# Grok 分析歸檔:M3V 控制路徑延遲 + MAC 縮放彈性(2026-07-04,User 轉交)

> 供「架構優化評估」階段(功能補齊之後)使用。裁示順序:功能補齊 → 架構優化評估 → VCS/Spyglass/coverage。

## 控制路徑延遲(RTL 實際行為)
- CSR 寫(GO)→ 第一個 MAC ≈ **1–2 拍**(registered mat_go 脈衝 + S_IDLE→S_RUN);CSR 寫 dbus_ready 同拍。
- CSR 讀(poll STATUS)有 `core_csr_rd_pending` → **每次 poll 多 1 拍**(Coral 若 LSU 直連可省)。
- **軟體序列化才是大頭**:一次 MAT_OP 至少 3 條 store(A/B/CTRL),單發 4-stage vs Coral 3-stage 4-wide → **差距常是 10+ 拍**,非 1–2 拍。

## 時序有利面(M3V)
| 區塊 | 相對 Coral | Fmax 影響 |
|---|---|---|
| cpu_m1 單發 | Coral DispatchV2 4-wide scoreboard 複雜得多 | scalar 較易收時序 |
| CSR→mat_go | registered pulse(1 拍) | 控制路徑有利 |
| 外掛 mat_engine | 與 core 解耦、邊界清楚 | 模塊級 timing closure 較好 |

- 既有證據:**cpu_m1_top 單體 DC trial(TSMC 28HPC+)~699 MHz setup WNS=0**;npu_top/mat_engine/vexu 未 synthesis。

## 時序不利面(M3V)
- mat_engine **單拍 256-MAC 組合樹**(4-lane mul + adder tree + acc 同拍)、2×256b 讀窗大 mux/fanout——npu_top critical path 幾乎必在此,非 scalar 那 1–2 拍。

## 路線選項(縮放/形狀)
- **A. 維持外掛、內部微架構升級(Grok 建議)**:MAC 樹流水化、128b 埠(weight-stationary 配合)、double-buffer;不動 cpu_m1/CQ。
- B. 靠攏 Coral:MAC 併入 RVV 後端 / 硬體 VCQ——失去模塊彈性,等於重做 RVV 整合。
- C. systolic / multi-engine:利於 512/1024,但面積/驗證/descriptor 語義全要擴。

## MAC 縮放表(8×8 tile,lane 數 = MAC/64)
| MAC/拍 | lanes | a/b 頻寬 | TCM 要求 |
|---|---|---|---|
| 64 | 1 | 64b+64b | 降配置即可 |
| 128 | 2 | 128b+128b | 單 128b 埠或 2×64b |
| 256 | 4 | 256b+256b | 現況(2×256b 窗) |
| 512 | 8 | 512b+512b | 512b 埠或 2-cycle 餵料 |
| 1024 | 16 | 1024b+1024b | 多 cycle / multi-engine / 更大 tile |

**結論(待評估階段確認)**:傾向路線 A——保留「scalar 編排 + 外掛加速器」,在 mat_engine 內做流水 MAC + 頻寬匹配;軟體序列化差距由 double-buffer/批次 descriptor 補。
