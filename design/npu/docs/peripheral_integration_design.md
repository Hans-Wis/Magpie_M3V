# soc_m3v_top 周邊整合 — 架構設計確認(§2)

Status: **ACCEPTED — User 裁示 P0 三項先行(2026-07-09);契約凍結於 ADR-0069;P1/P2 待後續裁示**
Date: 2026-07-09
Sources: M6 周邊盤點 / M3V 缺口盤點 / M1V1 Coral 整合契約盤點(本檔 §6 evidence)

## 1. Coral 對照(§2-1)

M1V1 的真 Kelvin 整合證實:**Coral NPU 本體無 boot ROM/flash/XIP** — host 韌體前門 AXI
寫 ITCM/DTCM、CSR 設 PC/CTRL 踢跑、poll STATUS(`fw_dense.c` 實測序列)。M3V 的
CQ+DMA+doorbell 卸載契約已超出此模型(§3 列 5 GREEN)。

→ **本次周邊整合不是 Coral 功能對等項,是「SoC 可獨立部署」工程項**:真晶片上
host 程式碼與 NPU 權重必須有非 `$readmemh` 的來源(datasheet §5.2:「Executable ROM
or XIP flash behind imem wrapper」)。不影響 §3 記分板,不新增對 Coral 宣稱。

## 2. 現況與缺口

- 現況 boot:host `RESET_PC=0x0` ← `axil_imem`(32KB,`$readmemh` 預載,**sim-only**)。
- `soc_m3v_top` 現掛:NPU `0x3000_0000` / PLIC `0x0C00_0000` / shared SRAM `0x8000_0000`(64KB)/ 其餘 DECERR。`mtip/msip/debug` 全 tie-0。
- 樹內已有未掛 IP(M1A fork 帶入,first-party Apache-2.0):`design/cpu_m1/soc/{clint,uart,dm,dtm,axil_bootrom}.v`。
- **樹內完全沒有的:SPI/QSPI/XIP** ← 由 M6 `rtl/soc/peripheral/qspi/` 補(全自建 Apache-2.0、有 SPDX,無 vendor IP/flash model;ADR-0003 reuse 條件可滿足)。

## 3. 需求分級(提案)

| 級 | 周邊 | IP 來源 | 理由 |
|---|---|---|---|
| P0 | **QSPI XIP(單線 0x03 continuous-read)** | M6 `qspi_xip.sv`+`qspi_master_p0.sv`(32-bit 原生)+ **自寫薄 AXI4-Lite read-only adapter**(不搬 64-bit `qspi_axi_rom`) | 唯一無本地 IP 的計劃缺口;boot + 權重儲存的部署來源 |
| P0 | **UART(TX+THRE IRQ)** | 本地 `design/cpu_m1/soc/uart.v` + 薄 AXI4-Lite wrapper(不搬 M6 64-bit `uart_m6/uart_axi`) | ADR-0068 §2 明文;console/bring-up |
| P0 | **CLINT(mtime/mtimecmp/msip)** | 本地 `design/cpu_m1/soc/clint.v`(RV32 原生) | ADR-0068 §2;host timer/軟中斷,csr.v 只有 mtip input |
| P1 | debug dm/dtm 掛載 | 本地(ADR-0021 lineage,RV32 原生) | 計劃提及;非部署阻斷 |
| P1 | GPIO | 無 IP,小自建 | 計劃提及;無急迫 workload |
| P2 | QSPI quad(1-4-4 0xEB)/ `qspi_prog`(program/erase CSR) | M6 experiment 檔 | 效能/現場更新;先單線證通路 |

## 4. 契約(§2-2)

### 4.1 Memory map 增訂(control AXI,32-bit)

| 窗 | Base | Size | 備註 |
|---|---|---|---|
| CLINT | `0x0200_0000` | 64KB | 沿 ADR-0020 慣例 |
| UART | `0x1000_0000` | 256B | 沿 ADR-0020;PLIC src1 |
| **QSPI XIP** | **`0x4000_0000`** | 16MB | **不能用 M6 的 `0x8000_0000`(M3V shared SRAM 已佔)**;`0x4000_0000` 現為 DECERR 空窗 |
| QSPI CSR(P2) | `0x4100_0000` | 4KB | prog/erase/quad 模式切換用,P0 不建 |

- `soc_axil_decode` ROUTE 2-bit 已滿(4 碼全用)→ **加寬 3-bit** + 新增 slave 埠組。
- PLIC sources 7-bit 現只用 bit0(NPU):**bit1=UART THRE、bit2=QSPI(P2)**,餘保留。
- XIP 取指:host `M_AXI_I` 側新增 I-decode(imem `0x0` / XIP `0x4000_0000` 二選)。
  D-bus 同窗可讀(權重從 flash 載入 shared SRAM 的路徑)→ QSPI 控制器前置 **2:1
  arbiter(I 優先)**,單 outstanding(qspi_xip 本身單流)。
- Boot 模式:`HOST_RESET_PC` param 化(sim=0x0 imem;部署=0x4000_0000 XIP)。TB/gate
  兩種都跑。

### 4.1a QSPI 前端語意凍結(Grok R1/R2/R3,ADR 定稿必含)

- **拓樸**:`M_AXI_I`-read + `M_AXI_D`-read → 2:1 arbiter(I 固定優先,transaction
  granularity,無搶佔)→ 單一 `qspi_xip` → SPI pins。全鏈**單 outstanding**;I/D 允許
  交錯,交錯造成 continuous-read 位址跳躍時 controller 重開 0x03 序列(warm→cold
  re-seek),**正確性不依賴位址連續,只有效能差**。
- **對齊/寬度**:XIP 窗只保證 **word-aligned 32-bit 讀**(取指/字讀皆滿足);sub-word
  讀由 adapter 以 word 讀回傳對應 byte lane(AXI4-Lite 讀本無 strobe,合法);**寫
  XIP 窗 → SLVERR**(read-only)。
- **容量/越界**:窗 16MB;實際 flash 映像 ≤ 窗。映像外讀回傳 NOR 語意(model 未燒
  區 = `0xFFFF_FFFF`),不 err —— 越界防護與 shared SRAM 同級(韌體 bounds,誠實
  記錄同 M3b-3 限制)。
- **雙 boot 同 ELF**:linker script 以 `0x4000_0000` 為 text/rodata VMA 出 flash 映像;
  imem-boot 用同一 ELF 的 objcopy hex(VMA 平移)。gate_86 斷言兩路同結果。
- **SCLK**:P0 沿 M6 `qspi_master_p0` mode-0、SCLK=clk/2;分頻 CSR 屬 P2。
- **誠實界**:P0 無 program/erase → **flash 內容 = 預燒**(TB `$readmemh`);「現場
  自更新」在 P2 之前不宣稱。

### 4.2 Reuse 憑證(ADR-0003 條件)

M6 QSPI 檔搬入 `design/soc/qspi/`:保留 Apache-2.0 header + SPDX + 上游 repo(Magpie_M6
`rtl/soc/peripheral/qspi/`)+ commit hash;一份 ADR 記 what/why/source/license。本地
uart/clint/dm/dtm 本就 first-party in-tree,掛載不需新 provenance。

## 5. 驗證計畫(§2-3)

M6 的 QSPI **零功能 DV、無 flash model** — 驗證全部本線自建:

1. **SPI-NOR TB model 自寫**(mode-0、0x03/(P2:0xEB)、`$readmemh` 映像;`design/npu/dv/tb/spi_nor_model.v`)。
2. `gate_85_qspi_xip_readback`(**含 arbiter 主風險,Grok V1**):word 讀全窗抽樣 +
   末 4B 邊界、cold(reset 後首讀)/warm(continuous 中)、**I/D 交錯**(連續 D 讀
   中插 I-fetch,含位址跳躍迫使 re-seek)、**寫 XIP 窗 → SLVERR**、sub-word 讀 byte
   lane 正確、映像外讀 = `0xFFFF_FFFF`、off-window → DECERR,全部 vs flash 映像
   bit-exact。
3. `gate_86_xip_boot_e2e`:`RESET_PC=0x4000_0000`,**同一 ELF** 出 flash 映像與 imem
   hex 兩路 boot,指令+常數全在 flash(**禁 TB 旁路/force imem 偷渡,Grok V5**),
   host 從 flash 取指執行完整 q_proj 卸載,權威 = 既有 AXI scoreboard + 結果 bit-exact
   vs gate_46 golden + 兩 boot 路結果一致。**非 performance gate**;TB timeout 依 XIP
   慢一個數量級放寬(timeout ≠ 功能錯)。
4. `gate_87_uart_clint`:UART tx scoreboard(byte 序列)+ THRE IRQ 經 PLIC bit1
   claim/complete;CLINT mtimecmp → mtip → host trap handler directed(復用 phase_03
   trap 基建)+ **msip 軟中斷 directed** + **CLINT 未編程時 mtip 恆 0**(防 tie-1
   殘留)。
4a. `gate_88_deploy_smoke`(合成一條龍,Grok V4):XIP boot → UART 印 banner →
   CLINT timer tick → NPU offload 完整跑,單 gate 覆蓋部署主路徑。
5. **host lockstep 不變**:周邊 MMIO 屬 device 域,Spike lockstep 維持既有 phase_03/20/22 範圍(green-wash 守衛:不得為周邊縮 lockstep scope)。
6. filelist 同步:`soc_m3v_top` 相關 TB filelist + 若觸 cpu_m1 檔則 phase_20/22(§4.7)。

## 6. Evidence(盤點出處)

- M6:`rtl/soc/peripheral/qspi/*`(10 檔 1003 行,全 Apache-2.0 自建;live=`qspi_axi_rom`→`qspi_xip`→`qspi_master_p0`,其餘 experiment lineage);`rv64_soc_top` map(ROM `0x8000_0000` 16MB=reset vector);**該 repo 無 QSPI TB/flash model**;ADR-0002(周邊 adopt 策略)/ADR-0003(reuse 政策)。
- M3V:`design/soc/soc_m3v_top.v` + `soc_axil_decode.v`(ROUTE 滿)/ `design/cpu_m1/soc/` 未掛 IP / datasheet §5.2 XIP 明文 / ADR-0068 §2「UART/Timer/GPIO + JTAG/DMI」/ PLIC 6 條空 source。
- M1V1(observe-only):Kelvin front-door AXI 載入契約(`m1v_coralnpu_interface.md` §5、`fw_dense.c`),無 flash/XIP。
