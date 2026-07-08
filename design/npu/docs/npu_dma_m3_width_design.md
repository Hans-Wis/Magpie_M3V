# soc M3 — npu_dma AXI 寬度隨 LANES SKU 縮放（DMA 頻寬 /2 /4 /8）· for review

- **Status:** DESIGN（待 Grok 架構 + Codex 整合實況 review）· 2026-07-08 · Claude
- **上位:** ADR-0068 §2.5（兩-AXI,資料 AXI 寬度隨 LANES）· 承 soc M1/M2（@b8f0fbc）
- **鐵律:** 全用本地 IP;功能權威 = 各寬度 bit-exact vs 既有 golden + 實測 DMA cycle 下降;**default DMA_DATA_W=32 = 建構上零回歸**。

---

## §0 目標 + 為什麼是最大槓桿

perf 台帳實測:v2 Phase B 後 **q_proj 殘餘 ~80% 是 DMA**（權重串流）。DMA cycle ∝ bytes / bus_width。
現 `npu_dma` = **32-bit（1 字/beat）**。拓寬到 `DMA_DATA_W`:
- 128-bit → 4 字/beat → **DMA cycle ~/4**
- 256-bit → 8 字/beat → **DMA cycle ~/8**

這是 bus 層對 DMA 瓶頸的正解,與 Phase B（activation-stationary,減冗餘 bytes）互補:B 減 bytes 數,寬 bus 減每-byte 時間。**隨 LANES SKU 縮放**:寬 MAC 吃權重快,bus 寬度跟上避免餓死（balanced design）。

## §1 Coral 對照

Coral(Kelvin)記憶體埠 **128-bit**。我們做 **64/128/256 可選（隨 LANES SKU）**——SKU=LANES 同時定 MAC 數 + bus/TCM 埠寬。對「可取代」:同一 workload,窄 SKU 省面積、寬 SKU 追吞吐,涵蓋 Coral 的 128-bit 點且可上下。

## §2 現有資料路（32-bit,實作真值）

- **npu_dma.v**（201 行）:AXI4-full master,`m_rdata/m_wdata[31:0]`、`arsize=010`(4B)、`wstrb=4'hF`。FSM:讀 S_AR→S_R（每 beat `buf_addr++` 寫 1 字進 TCM buffer）;寫 S_AW→S_W（每 beat `buf_raddr++` 讀 1 字）。`len_beats`=32-bit 字數;`cur_addr += beats×4`;4KB 邊界 + ≤256 beats/burst。buffer 介面 = TCM DMA 埠。
- **npu_tcm.v**:`reg [31:0] mem[0:WORDS-1]`,**8-way word-interleaved banks**（bank=word_addr[2:0]）。DMA 寫埠 `dma_we/dma_waddr/dma_wdata[31:0]`=**1 字/拍**;engine 讀 `eng_a_rdata[255:0]`=8 連續字組合讀（已寬!）。
- **axi_full_sram.v**:`rdata/wdata[31:0]`、`wstrb[3:0]`。
- **關鍵瓶頸**:即使 AXI 給 8 字/beat,若 TCM 寫埠仍 1 字/拍 → DMA 每 beat 花 8 拍寫 = 無益。**故 TCM DMA 寫埠必須加寬**（DATA_W/32 字/拍,寫 DATA_W/32 連續 banks——契合現有 8-bank 結構,如同 engine 讀）。

## §3 M3 設計:`DMA_DATA_W` 參數化（default 32,寬路 opt-in）

新參數 `DMA_DATA_W ∈ {32,64,128,256}`,`WPB = DMA_DATA_W/32`（words per beat）。**default=32 → WPB=1 → 行為與今完全相同（零回歸）**。

貫穿改動（全參數化,`DMA_DATA_W=32` 時退化為現況）:
1. **npu_dma.v**:`m_rdata/m_wdata/buf_wdata/buf_rdata` → `[DMA_DATA_W-1:0]`;`m_arsize/m_awsize = $clog2(DMA_DATA_W/8)`;`m_wstrb` → `[DMA_DATA_W/8-1:0]`（全 1）。位址/beat 算術:`cur_addr += beats×(DMA_DATA_W/8)`;`len` 語義 = **beats（寬 beat）** 或 保持 word-count 再 /WPB（見 §7 Q1）;4KB 邊界改用 `DMA_DATA_W/8` 對齊。buffer 介面每 beat 搬 WPB 字。
2. **npu_tcm.v**:新增/參數化 **寬 DMA 寫埠**:`dma_wdata[DMA_DATA_W-1:0]` 一拍寫 WPB 連續字（`for gw in 0..WPB-1: mem[dma_waddr+gw] <= dma_wdata[gw*32+:32]`,對齊 WPB）。`DMA_DATA_W=32` → 單字（現況)。讀埠（writeback egress）同理寬化或保持窄（§7 Q2）。engine 256-bit 讀埠不動。
3. **axi_full_sram.v**:`rdata/wdata[DMA_DATA_W-1:0]`、`wstrb[DMA_DATA_W/8-1:0]`;mem 組織為 WPB-字並行（或本身 DMA_DATA_W 寬）。
4. **npu_top.v + soc 資料 AXI（arbiter/decode/M3 資料匯流排）**:寬度貫穿參數化;host 控制側（M2 plic/csr）維持窄 32（控制 AXI）——只**資料 AXI（npu_dma↔SRAM）**加寬。
5. **對齊契約**:寬 DMA 要求 weights 在 SRAM + TCM 對齊 `DMA_DATA_W/8` bytes;descriptor/firmware/golden 佈局須滿足（現 ml_v2 佈局多為 32B 對齊,256-bit 友善;需驗）。

## §4 LANES 耦合（SKU）

建議耦合（可獨立設,預設綁定):`LANES=1→DMA_DATA_W=64` · `LANES=2→128` · `LANES=4→256`。SKU 一參數定 MAC + bus + TCM 埠寬 = balanced。M3 先讓 `DMA_DATA_W` 獨立可設 + 文件記耦合;gate 掃 64/128/256。

## §5 驗證計畫

- **零回歸（建構性）**:`DMA_DATA_W=32`（default）→ **所有既有 gate（45/46/48/49/50/51/52/gemma/ml_v2/soc_smoke/soc_irq）位元不變**（RTL 退化為現況)。跑一輪確認。
- **寬路 bit-exact**:`DMA_DATA_W=128/256` 於 **gate_67 ml_v2 q_proj 路** 對同一 golden **bit-exact**（bytes 不變),證寬化不改數值。
- **實測 DMA cycle 下降**:gate_67 breakdown（mat/dma/other）在 128/256 下 **dma 分項 ~/4、~/8**（對 32-bit baseline dma=1539 於 B1.1);列入台帳。
- **多寬度掃**:新 `gate_npu_dma_width`（仿 gate_84_mat_lanes_sku）:64/128/256 各 rebuild、weight-load bit-exact + cycle 下降斷言。
- **green-wash 守衛**:寬化必真在 RTL 資料路（AXI arsize/beat 真變寬,非 TB 造假);TCM 真 WPB-並行寫（bank-parallel,非序列化假冒);cycle 下降真來自 beat 數減少（波形/breakdown 佐證,非改 golden)。
- **（可選）DC PPA**:寬 SRAM/DMA 面積增量 vs cycle 收益,補 ADR-0051 PPA 系列。

## §6 里程碑內範圍（M3a）+ 之後

- **M3a（本步）**:讀/權重-載入路寬化（主導成本）+ default-32 零回歸 + gate_67 寬路 bit-exact + cycle 下降實測。
- **M3b（之後）**:writeback（TCM→SRAM 寫）路寬化（結果 16 字,收益小,可選);soc 資料 AXI 實體兩-bus 分域（M2 已邏輯分,M3b 實體);npu_dma len/burst 泛化長尾。

## §7 開放問題（給 review）

1. **len 語義**:`len_beats` 現數 32-bit 字。寬化後保持「數字數、內部 /WPB 成 beats」（firmware/descriptor 不改,只要求對齊）vs 改「數寬 beats」（descriptor 改）?傾向**保持字數 + /WPB**（零 firmware 改,只加對齊約束),但 remainder（字數非 WPB 倍數)須處理:尾 beat 用 wstrb 部分寫或要求 WPB 對齊 len。
2. **writeback 寬化 M3a 收 or M3b**:STORE 結果 16 字,寬化收益小、但為對稱 + arbiter 一致或許一起做?傾向 M3a 只讀路寬、寫路保持窄（or 同寬但不強求),review 定。
3. **TCM 寬寫 vs bank-仲裁**:WPB-並行寫 DATA_W/32 連續字,是否與 engine 讀/core 寫/checker 撞 bank?B1 review 曾記 DMA 寫 vs RESCALE 寫撞（npu_tcm 給 DMA 寫優先)。寬寫加劇?需確認 bank-conflict/優先。
4. **對齊強制**:weights 佈局是否已 `DMA_DATA_W/8` 對齊（256→32B)?ml_v2 佈局多 32B 對齊,但 header/act 需查;不對齊 → 退窄 or trap?
5. **axi_full_sram 寬化**:mem 改 DATA_W 寬 vs WPB-字並行陣列?後者對 host 窄寫（M1/M2 控制側 32-bit 經 bridge）較友善——SRAM 需同時服窄（host len0 lite）+ 寬（npu_dma burst)?雙寬度埠 or 統一寬 + host 側 WPB 對齊?
6. **DMA_DATA_W vs LANES 綁定**:M3 先獨立參數 + 文件耦合,還是硬綁 `DMA_DATA_W=64×LANES`?傾向獨立（驗證彈性),SKU wrapper 再綁。

## §8 Review resolutions（Grok APPROVE-WITH-CHANGES + Codex needs-changes,2026-07-08）

兩份 review 收斂,方向 APPROVE。定案（含 file:line by Codex）:

1. **SRAM 讀寬 = TCM 寫寬 = 同等 gating**（Grok #1 最重要）:speedup = **min(AXI, SRAM_read, TCM_write)**。只寬 AXI+TCM 而 SRAM 32-bit 讀 8 次 = 無益。**M3a 必含 SRAM 讀寬化**。實作（Codex #3）:`axi_full_sram` 內部保持 32-bit 字陣列 + **寬 AXI slave 組/拆 WPB 字**（wide DMA beat）+ byte-lane steering（窄 32-bit host 寫,經 axil_to_full awsize=2)。同一陣列服窄 host + 寬 NPU。
2. **len 語義**:保持 **32-bit 字數** + 內部 `beats=ceil(len/WPB)`（零 firmware/descriptor 改）。**weight fast path 強制 `len%WPB==0` + `base%(DMA_DATA_W/8)==0` → 否則 ERR_ALIGN**（不靜默退窄、不 floor-drop tail、不 ceil-overwrite;tail-lane stale 是靜默 correctness bug,Grok+Codex #1 一致）。ml_v2/gate_67 佈局已 8-字對齊（128/272/152/16),M3a 直接合規。
3. **npu_dma FSM 寬化**（Codex #1）:FSM 形狀不變;`m_rdata/m_wdata/buf_wdata/buf_rdata`→`[DMA_DATA_W-1:0]`、`m_arsize/awsize=$clog2(DMA_DATA_W/8)`、`m_wstrb`寬、`buf_addr/buf_raddr += WPB`、`cur_addr += beats*WPB*4`、4KB cap 用寬 beats。
4. **writeback = 窄 beat on 寬 bus**（Codex #6）:M3a STORE 保持 `awsize=2`、1 字/beat、正確 wstrb lane,**跑在寬 AXI 介面上**（非另接窄通道）。故「寬介面 + 窄寫交易」安全;「只改 m_rdata 寬」不安全。
5. **TCM WPB 寫**（Codex #2）:`for gw in 0..WPB-1: mem[dma_waddr+gw]<=dma_wdata[gw*32+:32]`（WPB≤8 契合 8-bank）。**M3a `npu_ml_ctrl` 序列化 → DMA-vs-RESCALE/eng_we 不重疊**（B1/B1.1 已序列化),現 whole-port 優先 dma>eng>core>host 夠用。**double-buffer overlap（未來）需 per-bank 仲裁 or engine write-grant/backpressure**（記為 M3b+ 前提）。bank-budget checker 只計讀 → **擴寫側**（P1）。
6. **LANES 硬綁**（Grok #4）:`DMA_DATA_W = 64×LANES`（LANES∈{1,2,4}→64/128/256）+ **elaboration assert** 擋非法組合;DV-only override behind `ifdef DV`。回歸 default 在 LANES=4 top 上跑 `DMA_DATA_W=32` 證退化。
7. **零回歸建構性**（Codex #4,fragile 點）:`DMA_DATA_W=32`→WPB=1→行為同今。守 `$clog2`→3-bit size、wstrb 寬常數、generate WPB=1、位址對齊不可 round 到 DMA_DATA_W/8（保 word-align)、SRAM rlast/latency。**驗:所有既有 gate 位元不變**。
8. **green-wash 守衛**（Grok #8):speedup 斷言 = beat 數真減（波形/breakdown);**flag「寬 AXI + 窄 SRAM shim」假象**——SRAM 必真寬讀（一拍供 WPB 字,非內部 8 次序列);TCM 真 WPB 並寫。cycle 下降不得靠改 golden。

**M3a 觸及檔（Codex #7）**:`npu_dma.v`、`npu_tcm.v`、`axi_full_sram.v`、`axi_full_arbiter_2x1.v`、`axil_to_full.v`、`npu_top.v`、`design/soc/soc_m3v_top.v` + DV mem（`axi_full_rwmem.v` 等）+ gate_67 寬度/cycle 檢查。**M3a 只讀/載入路寬;writeback 窄-on-寬;CQ sequencer 泛化對齊留 M3b。**

**M3a 驗收**:①`DMA_DATA_W=32` 全既有 gate 零回歸 ②`128/256` 於 gate_67 ml_v2 bit-exact（bytes 不變) ③gate_67 breakdown dma 分項 128→~/4、256→~/8 ④新 `gate_npu_dma_width` 掃 + ERR_ALIGN 負測 ⑤ARSIZE 真變寬斷言。

**下一步:實作 M3a（Codex 外科,照 §8;default-32 零回歸先,寬路 opt-in via LANES/DMA_DATA_W）→ 各寬度 bit-exact + cycle 實測 → commit。M3b=writeback 寬化 + CQ 泛化對齊;M3c=全 SKU + DC PPA。**
