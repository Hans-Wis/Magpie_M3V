# DDR controller 對接評估 — 客戶採用 Synopsys DWC uMCTL2 ddrc

- **Date:** 2026-07-08 · **Author:** Claude · **問題:** 客戶若採用 `a9soc/design/ddrc` 這顆 DDR controller,我們的 Magpie_M3V NPU SoC 能否對接?
- **結論:可以對接。** 最佳匹配 = 我們的 **LANES=2 / 128-bit 資料-AXI SKU**,直接插進 ddrc 的 128-bit AXI4 slave 埠;其餘 SKU 加標準 AXI width converter。

---

## 1. ddrc 是什麼(掃 `.../ddrc/src` 實測)

**Synopsys DesignWare `DWC_ddr_umctl2`**(業界標準 DDR Enhanced Memory Controller,18,747 行頂層)。組態:

| 項 | 值 | 來源 |
|---|---|---|
| DRAM 型 | **DDR3**(DDR4/LPDDR 關)· 64-bit · BL8 · 1 rank · FREQ_RATIO 1:1 | cc_constants |
| **SoC 面 = AXI4 slave** | **資料 128-bit**(`UMCTL2_A_DW=128`,各埠 `PORT_DW=128`)· **addr 40-bit** · **ID 12-bit** · 多埠 max 16(`UMCTL2_A_NPORTS=16`)| cc_constants + 頂層埠 |
| AXI 埠訊號 | 完整 AXI4:aw/w/b/ar/r + arsize/arburst/arlock/arcache/arqos/aruser/awuser(a2x bridge)| DWC_ddr_umctl2.v |
| **Config = APB** | 32-bit data / 12-bit addr(host 開機寫 timing/init 暫存器)| `UMCTL2_APB_DW=32/AW=12` |
| **PHY 面 = DFI**(505 dfi_ 訊號)| dfi_address/cs/wrdata/wrdata_mask/rddata → 接 **DDR3 PHY**(客戶/板端另備)| DWC_ddr_umctl2.v |

架構:`AXI master(SoC)→ [a2x AXI-to-XPI]→ ddrc core → DFI → DDR3 PHY → DDR3`。ECC(SECDED)在 `mr/`。

## 2. 我們的側(Magpie_M3V 資料-AXI)

- `npu_dma` = **AXI4-full master**,`DMA_DATA_W = 64×LANES`(64/128/256-bit,ADR-0068 §2.5 + M3a),INCR burst ≤256 beats、不跨 4KB、**single-outstanding**、**32-bit addr**、**無 ID/qos/user/lock**。
- host bridge(`axil_to_full`)也在資料-AXI 上。
- 現接 `axi_full_sram`(**代 DDR**)——本就設計成之後換真 DDR。**ddrc 就是那條真 DDR 路。**

## 3. 對接相容性逐項

| 面向 | ddrc slave | 我們 master | 對接 |
|---|---|---|---|
| **協定** | AXI4 slave | AXI4-full master | ✅ 同族 |
| **資料寬** | **128-bit** | 64/128/256(隨 LANES)| **LANES=2/128 = 直接匹配** ✅✅;256 加 256→128 downsizer;64 加 upsizer |
| **位址** | 40-bit | 32-bit | ✅ 我們 32 → zero-ext 進 40;0x8000 區映射到 DDR base |
| **ID** | 12-bit | 無(single-outstanding)| ✅ awid/arid 綁 0 |
| **AXI4-extra**(qos/user/lock/cache)| 有 | 不驅動 | ✅ 綁預設(qos=0/cache=0/lock=0/user=0/prot=0)|
| **burst** | AXI4 INCR | INCR ≤256/不跨 4KB | ✅ |
| **outstanding** | 多筆 | 1 筆 | ✅ 我們保守(1 筆),ddrc 容多筆 |
| **config** | APB(32b/12b)| host 有 AXI-lite master(control AXI,M2)| ⚠️ 需 **AXI-lite→APB bridge**(標準)寫 ddrc 暫存器 |
| **PHY** | DFI out | 無 | ⚠️ 需 **DDR3 DFI PHY**(客戶/板端;非我們 SoC 提供)|

## 4. 整合路徑(ddrc 取代 axi_full_sram)

```
現況:   npu_dma + host-bridge → axi_full_arbiter_2x1 → axi_full_sram(代 DDR)
換 ddrc: npu_dma + host-bridge → arbiter
           → [AXI adapter: (256→128 downsizer if LANES=4) + 綁 ID/qos/user/cache/lock + addr zero-ext]
           → ddrc AXI4 slave 埠(128-bit)→ a2x → ddrc core → DFI → DDR3 PHY → DDR3
     host control AXI → [AXI-lite→APB bridge] → ddrc APB config(開機寫 timing/DRAM init)
```

**需新增(全標準積木,無架構障礙)**:
1. **AXI width/feature adapter**:LANES=4(256)→ 128 downsizer;綁未驅動的 AXI4 訊號;addr 32→40 zero-ext。(LANES=2 免 downsizer,只綁訊號。)
2. **AXI-lite→APB bridge**:host 寫 ddrc 暫存器(timing/init;standard Synopsys DW_apb or 自寫小橋)。
3. **DDR3 DFI PHY**(客戶/板端提供;搭配 Synopsys DWC DDR PHY 或相容 DFI PHY)。
4. **開機序**:host 先 APB 配 ddrc + PHY training,DDR ready 後才發 NPU 卸載(現 M2 doorbell/fence 序 + 加 DDR-ready gate)。

## 5. 結論

**可以對接。** 我們的資料-AXI(ADR-0068 §2.5 兩-AXI 的寬資料匯流排)本就對齊業界 DDR controller 的 AXI4 slave 埠——**128-bit SKU(LANES=2)直插 ddrc 128-bit 埠**,零 width 轉換;256/64 SKU 用標準 AXI width converter。差異全是**標準積木**(width adapter + AXI-lite→APB config bridge + 客戶端 DFI PHY),**無架構級障礙**。

**這反向驗證了 M3 的設計方向**:資料 AXI 隨 LANES 縮放到 128/256-bit(ADR-0068 §2.5 / M3a),128-bit 正是 DDR3-64 uMCTL2 的埠寬。

**誠實界**:本評估基於 RTL 埠/參數靜態對照(未實跑 co-sim);正式對接需:①AXI adapter + APB bridge RTL + lint ②ddrc timing 暫存器序(依 DDR3 顆粒 datasheet)③DFI PHY(第三方)④AXI protocol-check(VCS/formal)/ DDR BFM co-sim 端到端。ddrc 是**加密/licensed Synopsys IP**(觀察埠/參數即可評估對接,不複製其 RTL)。
