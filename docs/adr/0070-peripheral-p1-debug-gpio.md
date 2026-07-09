# 0070 — 周邊整合 P1:debug dm/dtm 掛載 + GPIO(soc_m3v_top)

- Status: accepted(User 裁示 2026-07-09「P1」;架構分級承 ADR-0069/design doc §3)
- Date: 2026-07-09
- Deciders: User(裁示)、Grok(契約 review)、Claude(PL)
- Design SSOT: `design/npu/docs/peripheral_integration_design.md`(P1 列)

## Context

ADR-0069 P0(QSPI-XIP/UART/CLINT)已完成(gate_85–88 綠)。P1 = 計劃明文
(ADR-0068 §2「debug:JTAG/DMI」「GPIO」)但非部署阻斷的兩項。debug IP 樹內已有
(`design/cpu_m1/soc/{dm,dtm}.v`,ADR-0021 lineage,RV32 原生,`dtm` 內含 TAP+DMI+`dm`);
GPIO 無 IP,小自建。

## Decision / Contract(凍結)

### 1. debug 掛載(不新寫 debug 邏輯,純 SoC 佈線)

- `soc_m3v_top` 新增 JTAG 埠:`jtag_tck/jtag_tms/jtag_tdi`(in)、`jtag_tdo`(out)、
  `dm_ndmreset`(out —— **P1 僅輸出不回灌 resetn**,系統 reset 拓樸留給整合者,
  同 M1A `cpu_m1_soc_jtag_top` 慣例;誠實界:ndmreset 未閉環)。
- `dtm` 接線:`hart_havereset = !resetn`(M1A 慣例);`halt_req/resume_req/acc_*` →
  host `dm_*` 埠(現為 tie-0);`hart_halted/debug_mode` 回接。
- 契約即 riscv-debug v0.13.2 之既有 dm/dtm 實作;不改 cpu_m1 core。此 dtm 變體
  **無 SBA、單 hart**(上游即如此,誠實記錄);TAP idle 時 `halt_req` 必須不 sticky
  (Grok #9)。TCK/sysclk CDC 沿 dtm 內部既有處理(同 M1A 已證拓樸)。

### 2. GPIO(新 IP `design/soc/gpio.v`,自建 first-party)

| 暫存器(base+) | 名 | 行為 |
|---|---|---|
| `+0x00` | OUT | RW;驅動 `gpio_out[N-1:0]` |
| `+0x04` | IN | RO;`gpio_in` 經 **2FF 同步** 讀回 |
| `+0x08` | DIR | RW;1=output(驅動 `gpio_oe`);reset=0 全輸入 |

- N=16(param)。base **`0x1100_0000`**(64KB 窗,現 DECERR 空窗);經
  `periph_axil_shim`(同 uart/clint pattern,registered rdata)。
- **reset 值凍結**:OUT=0、DIR=0(全輸入)——首次 DIR=1 不得驅動垃圾(Grok #6)。
- **寬度語意凍結**:`[31:16]` 讀 0 寫忽略(WARL-ignore);byte strobe 只低半字有效
  (Grok #7)。IN 為 2FF 同步,只保證 polling/靜態圖樣語意,不宣稱多腳同拍邊沿
  一致(Grok #8)。
- `soc_axil_decode` 加第 8 個 route code(3-bit 恰滿;再加 slave 就要 4-bit——記錄)。
- **P1 無 GPIO IRQ**(輸入 polling;PLIC ID4 保留給未來 GPIO,ID3 已保留 QSPI P2)。
- 頂層 pads:`gpio_out/gpio_oe`(out)、`gpio_in`(in)。

## Verification(權威)

- `gate_89_debug_jtag_soc`(**smoke,非 full debug 簽核**——abstract write/CSR/
  memory/ndmreset 不在範圍,Grok #10):TB 對 `soc_m3v_top` JTAG 腳 bit-bang(參考
  M1A `tb_debug_jtag` 任務庫):IDCODE → **dmcontrol.dmactive=1**(Grok #9)→
  haltreq → `hart_halted` 斷言(韌體 heartbeat 計數器停走)→ abstract read GPR
  (已知值,如 crt0 設的 sp)bit-exact → resume → heartbeat 恢復遞增;並斷言
  **JTAG idle 全程 halt_req 不 assert**。
- `gate_90_gpio`:韌體寫 DIR/OUT 圖樣、TB 斷言 pad 值 **與 `gpio_oe`**(DIR=0 時
  斷言 oe==0,不只看 out,Grok #12);TB 驅動 `gpio_in` 圖樣後 **等 ≥3 sysclk 再讓
  韌體讀**(2FF,Grok #11),韌體讀 IN 寫回 shared-mem flag,TB 斷言;含 reset 後
  OUT=0/DIR=0 檢查。
- 無回歸:gate_85–88 + soc_irq/smoke **在 dm/dtm 真掛載(非 tie-off)狀態下**重跑
  ——debug 不活動時 halt/abstract 輸入必須靜默(Grok #13)。host lockstep 範圍不變。
- gate 內嵌 filelist 同步(§4.7 延伸:soc gate 檔案清單)。

## Consequences

- P2(QSPI quad / program-erase)後續獨立裁示。
- decode 3-bit 用滿;下一個 slave 觸發 4-bit 加寬。
- ndmreset 閉環(系統 reset 拓樸)為後續項,P1 不宣稱。
