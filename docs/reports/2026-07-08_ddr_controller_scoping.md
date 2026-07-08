# 自建 DDR controller scoping — 對接 Synopsys DWC DDR4 MultiPHY,取代 uMCTL2

- **Date:** 2026-07-08 · **Author:** Claude · **需求:** 客戶用 **Synopsys DDR PHY**(`a9soc/design/ddrphy`);我們**自建一顆 DDR controller** 對接它(經 DFI),**功能取代競爭者用的 Synopsys uMCTL2**(`a9soc/design/ddrc`)。
- **結論:可行,但這是大 IP(多月工程)。** 本檔=範圍界定 + 架構分塊 + 分階段計畫 + 誠實工作量 + 復用機會。**先確認範圍再落 RTL**(同 §2 鐵律)。

---

## 1. 目標 PHY(掃 `ddrphy` 實測)

**Synopsys DWC DDR4 MultiPHY**(PUB v3.20a · ACX48 命令 + DATX8/DATX4X2 資料 · TSMC28HPCP18 · 279 頂層埠 · 硬 macro + `stub/`)。兩個**我們 controller 必須驅動的介面**:

### (a) DFI(controller ↔ PHY,data/command)— ~DFI 2.1/3.1
| 群 | 訊號 | 方向(對 controller) |
|---|---|---|
| 命令 | `dfi_address[15:0]` `dfi_cke` `dfi_cs_n` | out(依命令排程驅動 DRAM 命令)|
| 寫 | `dfi_wrdata[143:0]` `dfi_wrdata_en[8:0]` `dfi_wrdata_mask[17:0]` | out |
| 讀 | `dfi_rddata[143:0]` `dfi_rddata_valid[8:0]` `dfi_rddata_dbi_n[17:0]` · `dfi_rddata_en[8:0]` | in(en 是 out)|
| init | `dfi_init_start`(out)→ `dfi_init_complete`(in) | |
| update | `dfi_ctrlupd_req/ack`(VT 補償)· `dfi_phyupd_req/ack/type`(PHY 主動)| |
| 低功耗 | `dfi_lp_ctrl_req/data_req/ack/wakeup` `dfi_dram_clk_disable` | |
| 位元組致能 | `dfi_data_byte_disable[8:0]` | out(9 lane=8 data+1 ECC)|

**144-bit DFI = 72-bit(64 data + 8 ECC)× 2:1 freq ratio**(controller 端 clk = DRAM 半速)。

### (b) PUB config(training/校準)= **APB**
`ddrphy_pclk` `paddr[31:0]` `penable` `pwdata[31:0]` `ddrphy_prdata[31:0]`——**controller(或 host firmware)寫 PUB 暫存器**做 write-leveling / gate / read-write eye centering / DDR4 VREF training。PUB 內建 training 引擎(BIST/DCU),controller 觸發 + 等 `dfi_init_complete`。

## 2. 我們要建的 controller = 這些塊

| 塊 | 職責 | 複雜度 |
|---|---|---|
| **AXI4 slave 前端** | SoC 面(128-bit 對齊我們資料-AXI + NPU;40-bit addr、ID、qos)· AW/W/B/AR/R · outstanding/reorder buffer | 中(可復用我們 AXI infra + a9soc `axi_x2x_64b128b` width 轉換)|
| **位址映射** | AXI addr → rank/bank-group/bank/row/col(可配置 interleave)| 低-中 |
| **命令排程引擎** | activate/read/write/precharge/refresh 仲裁 + open/close-page policy + read/write grouping(bus 效率)| **高**(competitive 關鍵)|
| **DDR3/4 timing FSM** | tRCD/tRP/tRAS/tRC/tRFC/tFAW/tWR/tRTP/tWTR/tCCD… per-bank 計時器(JEDEC)| **高** |
| **refresh 管理** | auto-refresh tREFI、all-bank/per-bank、溫度補償 | 中 |
| **DFI master** | 依排程驅 dfi_address/cke/cs_n;寫路 dfi_wrdata/en/mask;讀路 dfi_rddata_en→capture rddata/valid;DFI 寫/讀 latency(dfi_t_phy_wrlat / dfi_t_rddata_en)對齊 | **高**(PHY 契約)|
| **PHY init/training 編排** | dfi_init_start;經 APB 配 PUB + 觸發 training;dfi_ctrlupd/phyupd 握手(VT drift)| **高**(PHY-specific) |
| **APB config 前端** | host 寫 controller timing/map/init 暫存器 | 低 |
| **(可選)ECC** | SECDED(72-bit)· scrub | 中 |
| **(可選)低功耗** | self-refresh、power-down、DFI LP 握手 | 中 |

**參考規模**:uMCTL2 頂層 18,747 行 + 數十子模組。競爭級全功能 controller = **多月、多人 IP**。

## 3. 分階段計畫(MVP → 全功能;每階段 §2 架構確認 + Spike/BFM 驗證)

- **P0 DFI/PHY bring-up**:DFI master 最小(init_start→init_complete)+ 經 APB 跑 PHY 內建 training + 一筆固定 write/read（用 PHY 的 DFI + Synopsys DDR memory model / BFM）。**證能驅動這顆 PHY**。
- **P1 單通道 DDR3 功能**:AXI4 slave(單 outstanding,先對齊我們 NPU 128-bit)→ 位址映射 → 命令 FSM(open-page)→ timing FSM(DDR3-1600 一組 timing)→ refresh → DFI。**單筆 AXI 讀寫 e2e bit-exact vs DRAM model**。
- **P2 效能**:多 outstanding + 命令排程(read/write grouping、bank 平行、page policy)+ AXI 亂序回應。**bandwidth/latency 對標 uMCTL2**。
- **P3 強固/產品**:ECC(SECDED)、低功耗(self-refresh)、DDR4 支援、多 rank、頻率切換、AXI QoS。
- **P4 簽核**:AXI protocol-check(VCS/formal)+ DDR JEDEC compliance(BFM)+ DFI compliance + DC PPA(TSMC28)+ coverage。

**取代宣稱門檻**(同 NPU 取代 Coral 的紀律):對 uMCTL2 的**功能對等清單**逐項綠燈 + 權威證據(DDR BFM/JEDEC compliance、AXI scoreboard、DFI 波形),非「看起來像」。

## 4. 復用機會(降工作量)

- **我們的 AXI infra**(M1-M3:`axi_full_arbiter`、`axil_to_full`、AXI4-full master/slave 經驗、寬度縮放)→ AXI 前端。
- **a9soc `axi_x2x_64b128b`**(現成 AXI 64↔128 width 轉換)→ SoC 面寬度對接。
- **PHY 內建 PUB training**(BIST/DCU/eye)→ 我們**不用自寫類比 training**,只編排(APB + DFI init)。**這是最大省力點**——training 難的部分 PHY 已含。
- **DDR memory model / BFM**(Synopsys DDR verif kit,`dwc_ddr4_multiphy_verif_quickstart.pdf`)→ 驗證環境現成。
- **JEDEC DDR3/4 spec** = 架構契約(同 RISC-V spec 之於 CPU)。

## 5. 誠實評估

- **可行**:DFI + PUB-APB 介面清楚、PHY training 自帶、有 BFM/model、我們有 AXI/DC/memory-compiler 全鏈能力。**無不可克服障礙**。
- **但工作量大**:命令排程 + timing FSM + DFI 契約 + PHY 編排是 DDR controller 的難核心,competitive 全功能=多月。**建議先 P0(DFI/PHY bring-up)證能驅動這顆 PHY**,再逐階段。
- **licensed IP 界線**:uMCTL2 / DWC PHY 是加密 Synopsys IP——**觀察 DFI/APB 埠與 JEDEC 契約做對接與功能對等,不複製其 RTL**(同 CVA6 clean-room 規則)。PHY 我們**只驅動**(它是客戶採用的黑盒 macro),controller 是我們**自建**。

**下一步(建議):P0 DFI/PHY bring-up 架構確認**(DFI 時序契約 + PUB training 序 + BFM 環境)→ Grok/Codex review → 實作最小 DFI master + 一筆 read/write vs DDR model → 證可驅動 PHY。之後才談全 controller。
