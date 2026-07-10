# Grok 效能重估 — +64-128KB SRAM/FIFO + Magpie_DDR 後端(2026-07-10)

> 前提:DDR4-3200 ×16(6.4GB/s 峰值,~4.8GB/s 有效)、128b AXI 單 outstanding、Gemma-3 270M 真尺寸每層權重 ~4.5-5MB int8 每 token 串流。CLI 存留結論段(預算分配/cycle 圖像/tok-s 表/新 gate/陷阱表/最終攻擊序)。Claude 獨立算帳印證:10.4 B/cyc@460MHz、~530k cyc/層(5.5MB)、18 層 ≈48-59 tok/s,與 Magpie_DDR ADR-0004 的 50 tok/s 目標一致。

| Weight PP | **2×16KB=32KB** |
| KV | **24KB（~48 tok）** |
| FIFO+CQ | **8KB** |

**不要：** 試圖用 64–128KB「常駐一層權重」（差兩個數量級）。  
**可以：** 用 PP 把 **SHARED_MEM 從「偽全量權重池」改成「滑動 weight 窗」**——這是架構語意變更，不是加一塊 RAM 而已。

Weight tile 尺寸直覺：32KB @10.4 B/cyc ≈ **3.1k cyc 填滿**；同 tile MAC=32k/256≈**128 cyc** → **PP 的意義是重疊「下一個 3.1k 的 DMA」與「當前 128c 的算 + 非線性」**，不是讓 MAC 吃飽。

### 每層 cycle 圖像（decode, 1 token, 4.5MB）

假設 **L 層**（見下 tok/s）；\(T_c^{\text{now}}\)≈250k，\(T_c^{\text{opt}}\)≈60k（量級）。

| 階段 | \(T_s\) | \(T_c\) | **\(T_{\text{wall}}\)/layer** | 備註 |
|---|---|---|---|---|
| **(i) 僅 buffer+overlap**（controller 已達 4.8） | 431k | 250k | **≈431k** | 相對 serial \(T_s+T_c\) 省 ~250k |
| **(i') 僅 buffer+overlap**（controller 卡 13/6） | 933k | 250k | **≈933k** | overlap 救不了 col 低效 |
| **(ii) +G2→4.8GB/s** | 431k | 250k | **≈431k** | 若從 (i') 來 = **主加速** |
| **(iii) +compute 鏈做完** | 431k | 60k | **≈431k** | **decode tok/s 幾乎不變**；headroom 350k；prefill 大變 |

**飽和點（decode）：**  
\[
T_{\text{token}} \approx N_{\text{layer}} \times T_{\text{stream}}(+ \text{小尾：KV、CQ、層間})
\]
再壓 compute **不增加 tok/s**，除非減字節（量化/稀疏/權重常駐/層融合少載）。

### tok/s @460MHz

**假設 \(N_{\text{layer}}=18\)**（270M 級常見量級；若實作為 24，下表 ×18/24）。

| 方案 | cyc/token | tok/s @460MHz |
|---|---|---|
| (i') PP only, 差 controller | 18×933k ≈ **16.8M** | **≈27** |
| (i)/(ii)/(iii) stream@4.8, 4.5MB | 18×431k ≈ **7.76M** | **≈59** |
| 同，5.0MB 權重 | 18×479k ≈ **8.62M** | **≈53** |
| 理論 pin 全開 6.4GB/s、75%→仍 ~4.8 | — | **仍 ~55–60**（page 帽） |
| 若 N=24, 4.5MB, G2 | 24×431k≈**10.3M** | **≈45** |

**解碼吞吐飽和 ≈ 50–60 tok/s（N=18, 4.5MB, 4.8GB/s, 完美 overlap）**；G2 從「半速 controller」拉上來是 **27→59** 這種跳變，compute 鏈是 **59→59**。

Prefill（權重每層 1 次、S 大）：tok 等價吞吐由 **compute+S² attn** 定，**那時 RVV/v2 鏈回到第一排**。

---

## 4. 新驗證 / gates（必加）

| Gate / 模型 | 要鎖什麼 | 通過門檻建議 |
|---|---|---|
| **DDR latency-realistic BFMs**（替換 1-cyc shared SRAM stand-in） | open-page hit/miss、tRCD/tRP、col 間隔 13 vs 6、4KB 邊界、SINGLE outstanding | 長 INCR 權重流達到 **≥X% of 4.8GB/s**（X=85 作 G2 目標） |
| **BW scoreboard** | 每層 bytes_read（weight/KV/desc）vs cycle | decode wall **∈ [0.95,1.05]×\(B/ BW_{\text{eff}}\)** |
| **Overlap / ping-pong 正確性** | A 填時 B 算、無 read-after-write 腐蝕、tile 邊界 | bit-exact vs 現 golden；**故意插 DDR stall** 仍 exact |
| **Burst 紀律** | 不跨 4KB、addr col-low 連續、len | checker：違規即 fail |
| **Single-outstanding 壓力** | 僅 1 AR；短 vs 長 burst 效率曲線 | 文檔化 \(\eta(L)\)；短 burst 不得宣稱 4.8 |
| **KV 一致性** | 寫新 token、滑窗驅逐、層索引 | host 可見 vs NPU attn 讀集合一致；S=64/128/256 |
| **雙流衝突（若做）** | weight DMA vs KV fill 同 master | 無死鎖、無靜默掉 beat；或明確 time-slice 契約 |
| **回歸：既有 mat/v2/RVV lockstep** | 搬到「權重經 DMA 窗」後 | phase_20/22 + gemma e2e **不得**只在 1-cyc SRAM 綠 |
| **G2 控制器 gate 對齊** | col ≤6 的 **系統級** 證據 | 不單看 controller 單測，要看 **npu_dma 為 sole master 的端到端 GB/s** |

**Sim 策略：** M3V 內 **可參數化 DDR latency model**（L、page hit rate、col spacing）；signoff 再掛真 Magpie_DDR + 兩邊 gate 交叉。

---

## 5. 現況 M3V 陷阱（會擋計劃）

| 陷阱 | 為何致命 | 要什麼 |
|---|---|---|
| **Shared mem = 1-cyc SRAM 替身** | 所有 cycle 數（含 307k、11.8×）**低估 DDR wall 一個數量級**；優化序會誤判 | 立即把 e2e 性能敘事拆成 **compute-bound 證據** vs **BW-bound 投影** |
| **npu_dma ↔ Magpie_DDR 皆 SINGLE outstanding** | 長流 OK；**KV 隨機/跨 layer 與 weight 交錯** 會插入 \(L\) 氣泡；RD FIFO16 救不了 | 契約寫清：**decode 時間軸 = 純 weight 大流，KV 走 on-chip 或時間片**；否則要 2-AR |
| **v2 / CQ 假設「權重已在 SHARED_MEM」** | 4.5MB 無法常駐；現程式/描述符若一次指全層 W | **descriptor 改 streaming tile 窗**；v2 不假設 residency |
| **TCM/SHARED 寫口寬度 vs 128b DMA** | 窄口 → DMA 寫入成為第二 BW 牆（on-chip） | 量 **TCM 寫 B/cyc**；目標 ≥ DDR 有效（≥10–16 B/cyc） |
| **Harvard ITCM/DTCM + mat 讀口** | 雙緩衝若與 DTCM 單口搶，overlap 死 | 端口會計進 scoreboard |
| **權重每 token 全量重載（軟體契約）** | 硬體再快也 **≥431k×N** | 產品若要 >60 tok/s：必須 **減流量**（非只加 RVV） |
| **filelist/鎖步仍以「TCM 預載」當 truth** | green-wash 風險 | 性能 gate 與功能 lockstep **分家** |
| **256b DMA SKU vs 128b DDR slave** | 寬 DMA 接窄 DDR 無增益，只多 mux | 先 **128b 端到端貼 BW**，再談 256 |
| **開頁映射 col-low** | 描述符/stride 若按 row-major 錯維度 → 變 page-miss 流 | 權重 layout **強制與 col-low 一致** 的 ABI/gate |

---

## 攻擊序（最終一頁）

**Decode 產品路徑：**  
1) **端到端有效權重 BW**（G2 col≤6 + 長 INCR + 4KB/page 紀律 + 必要時修 npu_dma 氣泡）  
2) **64–128KB：weight PP 為主（~½），KV 窗次之，FIFO/CQ 其餘** → wall=\(\max(T_s,T_c)\)  
3) **軟體/CQ streaming tile 契約**（消滅「整層 W 在 shared」假設）  
4) **AXI128 驗證飽和；256 僅在測出 fabric 不足時**  
5) **Compute RVV/v2 鏈** → 主收益在 **prefill / headroom / 功耗**，**不**承諾 decode tok/s  
6) KV SRAM 當 **延遲與端口** 優化，不當 BW 銀彈  

**數量級北極星（N=18, 4.5MB, 460MHz, 完美 overlap, 4.8GB/s）：**  
**~431k cyc/layer → ~7.8M cyc/tok → ~59 tok/s**；再往上必須 **少搬權重**，不是再砍 30k RVV。
