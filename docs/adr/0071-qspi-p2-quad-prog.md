# 0071 — QSPI P2:quad(1-4-4 0xEB)XIP + program/erase CSR

- Status: accepted(User 裁示 2026-07-09「P2」;分級承 ADR-0069 §Decision P2)
- Date: 2026-07-09
- Deciders: User(裁示)、Grok(契約 review)、Claude(PL)
- 前置:P0(ADR-0069,gate_85–88)、P1(ADR-0070,gate_89/90)皆綠。

## Context

P0 只搬單線 0x03 XIP(讀-only、預燒 flash)。P2 補兩塊:**quad 1-4-4 讀**(4× 取指
頻寬)與 **program/erase**(現場更新 flash 的硬體路;P0 誠實界「不宣稱自更新」自此
解除——解除範圍見 §Honesty)。M6 來源檔(experiment lineage,**零 DV**,同 P0 以
unproven IP 規格接入):`qspi_xip_quad.sv`(同 native read-channel,pin 層 4-lane
io_o/io_oe/io_i)、`qspi_master_p2.sv`、`qspi_prog.sv`(start/op{PP,SE,BE,CE}/busy/
done/RDSR-WIP poll + 256B 寫緩衝讀口)、`spi_cmd.sv`(WREN/RDSR 引擎)。verbatim +
provenance(M6 @14db08b),不 silent-fork。

## Decision / Contract(凍結)

### 1. Pin 層統一(頂層 breaking change,一次到位)

`qspi_si`(out)/`qspi_so`(in)→ **`qspi_io_o[3:0]` / `qspi_io_oe[3:0]` /
`qspi_io_i[3:0]`**(pad 三分式,無 inout;io0=SI、io1=SO 慣例)。單線引擎驅動
oe=4'b0001,quad 依 `io_oe` 展開 4'b1111/4'b0000。所有 soc TB + `spi_nor_model`
一次改齊(機械性)。

### 2. QSPI CSR block(新自建 `design/soc/qspi/qspi_csr.v`,@`0x4100_0000` 4KB)

| 暫存器(base+) | 名 | 行為 |
|---|---|---|
| `+0x00` | MODE | bit0 QUAD_EN(reset=0=單線 0x03;**boot 恆單線**,quad 由軟體開) |
| `+0x04` | PROG_CTRL | 寫觸發:bit[1:0]=op(0=PP/1=SE/2=BE/3=CE)、bit8=start(W1P) |
| `+0x08` | PROG_ADDR | flash byte 位址(PP/SE/BE 用) |
| `+0x0C` | PROG_LEN | PP byte 數 1..256 |
| `+0x10` | STATUS | RO:bit0=busy、bit1=done(讀清)、[15:8]=最後 RDSR |
| `+0x100..+0x1FC` | WBUF | 256B PP 寫緩衝(64 word,W-only) |

- 掛 `periph_axil_shim` 後(同 uart/clint/gpio pattern)。
- **`soc_axil_decode` ROUTE 3→4-bit**(ADR-0070 已預告;第 9 碼=QSPI_CSR)。

### 3. SPI bus 所有權/序列化(front 擴充,單一仲裁點)

- 三個引擎共用 pins:XIP-單線、XIP-quad(MODE 選其一)、PROG。**front 為唯一
  pin mux**。
- **PROG 取得 bus 前必先關閉 continuous-read stream(CS 拉高)**;PROG busy 期間
  XIP AR **stall(hold arready 低),不 error**;PROG start 在 XIP read in-flight 時
  等 idle 才啟動。單 outstanding 不變。
- **MODE 切換僅在 front idle 時生效**(寫入緩存,idle 邊界套用)。軟體契約:執行中
  程式碼不得在自己取指的窗上切模式/編程(業界 XIP 慣例,程式應駐 imem/RAM 執行
  該類操作);HW 只保證序列化不保證效能。
- PROG done IRQ **不做**(STATUS poll;PLIC ID3 續保留)——記錄為 P2 誠實界。

### 4. spi_nor_model 擴充(權威仍是自建 model + gate)

- `0xEB` 1-4-4:cmd 單線 io0、addr+mode byte 4-lane、dummy、data 4-lane;
  mode byte=0xA5 → continuous-read(免重發 cmd)。**協定以 qspi_xip_quad.sv 的
  實際時序為契約**(Magpie_QSPI 家族慣例,非特定 vendor 晶片——誠實記錄)。
- program/erase:WREN(0x06)必要、PP(0x02,**AND 寫入語意**——未先 erase 的
  bit 只能 1→0)、SE(0x20,4KB→0xFF)、BE(0xD8,64KB)、CE(0xC7)、
  RDSR(0x05,WIP/WEL);WIP 在 PP/erase 後保持固定模擬拍數再清(讓 poll 路徑
  真的被走到)。

### 5. 時序表(凍結——gate golden 對此表 + flash 映像,不對 RTL 波形;Grok 去循環)

| 相位 | 拍數(SCLK) | lane |
|---|---|---|
| 0xEB opcode | 8 | 1(io0) |
| addr 24b | 6 | 4 |
| mode byte 0xA5 | 2 | 4 |
| dummy | 4 | Hi-Z(oe=0) |
| data / 32-bit word | 8 | 4(2 nibbles/byte) |

- continuous:mode=0xA5 → CS 保持低,連續 word 免重發 cmd/addr/mode/dummy;
  非連續位址 → CS↑ 重開全 frame。
- **CS↑ 條件(次序凍結)**:①in-flight read 完成 → ②CS↑ → ③才允許 PROG grant
  或 MODE 套用。**MODE 寫入於 PROG busy / stream 活躍時緩存,idle 邊界生效**。
- **PROG 恆單線**(WREN/PP/SE/BE/CE/RDSR 全走 io0/io1,與 MODE 無關;Grok 阻斷項 a)。
- **oe 互斥**:pin mux 交接處 io_oe 不得雙驅動(XIP↔PROG 交接 directed 檢查)。
- WIP 拍數(model 凍結):PP=64、SE=128、BE=256、CE=512 sysclk(抽象值,非真
  tPP/tSE——誠實界)。PP 頁對齊:跨 256B 頁 = 韌體責任(model 依 NOR 慣例頁內
  wrap,gate 不測跨頁);SE/BE 位址對齊下取整;**CE 忽略 PROG_ADDR**。

## Verification(gates;全 Verilator,Codex 禁碰 licensed EDA)

- `gate_91_qspi_quad_readback`(unit):gate_85 全 battery 在 quad 路重跑(cold/
  warm/I-D 交錯 re-seek/write-SLVERR/映像外 0xFFFFFFFF/idle I 優先)+ **單→quad→單
  MODE 切換中資料 bit-exact** + quad warm(continuous mode byte)實證 +
  **continuous 活躍時切 MODE → 下一筆必 cold**(Grok)。
- `gate_92_qspi_prog`(SoC e2e):imem-boot 韌體經 CSR —— SE → XIP 讀全 0xFF →
  WBUF+PP 圖樣 → XIP 讀回 bit-exact(單線與 quad 各一次)→ **STATUS busy 曾為 1
  且 done 落地、done 讀清**(WIP poll 路真走)→ **PROG 期間發 XIP 讀 = stall 後
  正確完成**(序列化 directed)→ AND-寫語意(重 PP 未 erase 區 → 只 1→0)→
  **busy 中 start 忽略** → **PROG 後第一筆 XIP 必 cold**(單+quad)→ **PROG busy
  中寫 MODE → idle 後才生效**(Grok)。
- `gate_93_qspi_quad_e2e`(SoC):imem-boot 韌體開 MODE.QUAD → D-side XIP 讀
  bit-exact vs 映像 → **跳進 XIP 駐留常式執行並返回**(quad 取指真走)→ quad
  warm>0。**不宣稱 quad 冷 boot**(reset 恆單線)——誠實界。
- 無回歸:gate_85–90 + soc_irq/smoke + gate_88(pin 層 breaking change 全 TB 重驗)
  + **oe 互斥斷言進 TB**(XIP↔PROG 交接無雙驅動,Grok)。

## Honesty(P2 完成後的宣稱邊界)

- 解除:「flash 現場更新」→ **有硬體路 + gate_92 證據**(仍限 PP/SE/BE/CE、
  poll-based、單 outstanding)。
- 保留:quad 冷 boot 不宣稱(恆單線 boot);prog IRQ 未做;協定契約 =
  Magpie_QSPI 慣例非 vendor 晶片相容性;真實 flash 時序(tPP/tSE)未建模——
  WIP 拍數為模擬抽象。

## Consequences

- decode 4-bit(空碼 7 個,後續 slave 無近期加寬壓力)。
- 頂層 pin 契約 breaking(si/so→io[3:0]);FPGA/合成腳位表要跟(後續 flow 事項)。
- 實作序:D1 = pin 統一 + quad(gate_91/93)→ D2 = CSR + prog(gate_92),
  每步獨立 commit;Codex 派工拆小(≤15min 教訓)。
