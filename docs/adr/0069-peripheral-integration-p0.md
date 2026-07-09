# 0069 — soc_m3v_top 周邊整合 P0:QSPI-XIP(M6 reuse)+ UART + CLINT

- Status: accepted(User 裁示 2026-07-09「P0 這三項先行」)
- Date: 2026-07-09
- Deciders: User(裁示)、Grok(架構 review)、Claude(PL)
- Design SSOT: `design/npu/docs/peripheral_integration_design.md`(§4.1a 語意凍結)
- Review: `docs/reviews/2026-07-09_peripheral_integration_grok.md`

## Context

soc_m3v_top(ADR-0068)現況 host boot = `axil_imem` `$readmemh`(sim-only),
`mtip/msip` tie-0,無 console。datasheet §5.2 明文部署程式來源 =「Executable ROM or
XIP flash behind imem wrapper」。盤點結論(design doc §6):UART/CLINT/dm/dtm 樹內已有
(M1A fork first-party)未掛載;**SPI/QSPI/XIP 為唯一無本地 IP 的缺口**。

Coral 對照(M1V1 observe-only 實證):Kelvin 為 host 前門 AXI 載入,無 flash/XIP —
**本整合是部署工程項,非 Coral 對等項**,不動 §3 記分板、不新增對 Coral 宣稱。

## Decision

P0 三項先行(P1=debug dm/dtm 掛載+GPIO、P2=QSPI quad+program/erase,後續再裁):

1. **QSPI-XIP**:reuse Magpie_M6 自建 IP(ADR-0003 條件):
   - 檔:`qspi_xip.sv` + `qspi_master_p0.sv` → `design/soc/qspi/`(32-bit 原生核心;
     **不搬** 64-bit `qspi_axi_rom`/M6 axi_pkg 生態)
   - Provenance:source repo `~/project/SOC/Magpie_M6` `rtl/soc/peripheral/qspi/`,
     commit **14db08b**(qspi 檔最後改動 48b75b9);上游 Apache-2.0 + SPDX header 保留,
     copy 時加註 provenance 行
   - 本線自建:AXI4-Lite read-only adapter、I/D 2:1 arbiter(I 優先)、I-side decode
   - **M6 QSPI 於源 repo 零功能 DV → 按 unproven IP 接入,本線 gate 為唯一放行條件**
2. **UART**:掛載本地 `design/cpu_m1/soc/uart.v`(16550-subset TX+THRE)+ 薄 AXI4-Lite
   wrapper。
3. **CLINT**:掛載本地 `design/cpu_m1/soc/clint.v`(RV32 原生 mtime/mtimecmp/msip),
   `mtip/msip` 真接 host。

## Contract(凍結)

| 窗 | Base | Size | 附註 |
|---|---|---|---|
| QSPI XIP | `0x4000_0000` | 16MB | read-only;寫 → SLVERR;映像外讀 = `0xFFFF_FFFF`(NOR 語意,越界防護=韌體 bounds,同 M3b-3 誠實界) |
| UART | `0x1000_0000` | 256B | PLIC source **2** = THRE IRQ(NPU 保持 ID 1=M2 既有契約;ADR 原寫 src1 係未查 npu 已佔,amended) |
| CLINT | `0x0200_0000` | 64KB | msip/mtimecmp/mtime,RV32 雙字存取 |

- `soc_axil_decode` ROUTE 2→**3-bit**,新增 UART/CLINT/XIP(D 側)三 slave 埠組。
- I-bus:I-decode 二路(imem `0x0` / XIP `0x4000_0000`);`HOST_RESET_PC` param
  (sim=0x0,部署=0x4000_0000);同一 ELF 出雙映像(linker VMA=0x4000_0000)。
- QSPI 前端:I/D 2:1(I 優先、transaction granularity、單 outstanding、交錯僅致
  continuous-read re-seek 效能差);mode-0、0x03、SCLK=clk/2(分頻 CSR=P2)。
- P0 無 program/erase → flash = 預燒(TB `$readmemh`);不宣稱現場自更新。

## Verification(權威;green-wash 守衛)

自寫 `spi_nor_model.v`(M6 無 flash model)。gates:`gate_85`(readback + **I/D 交錯
re-seek** + 寫窗 SLVERR + sub-word lane + 映像外 + off-window DECERR)、`gate_86`
(同 ELF 雙 boot 結果一致、**純 XIP 取指**跑 q_proj 卸載 bit-exact vs gate_46 golden、
非 perf gate、timeout 放寬)、`gate_87`(UART tx scoreboard + THRE→PLIC src1
claim/complete + mtimecmp→mtip→trap + msip directed + 未編程 mtip 恆 0)、`gate_88`
(部署一條龍 smoke)。host Spike lockstep 範圍不縮;filelist 三處同步(§4.7)。

## Consequences

- soc_m3v_top 得到非 `$readmemh` 的部署 boot/儲存故事;host timer/console 可用。
- decode/fabric 改動集中一輪(三項共用),避免重複動同批檔。
- 風險集中於 unproven QSPI IP — 由 gate_85 arbiter/err 壓力先行擋下;實作序
  A(UART+CLINT)→ B(QSPI)→ C(smoke),每步獨立 commit 可回退。
