# npu_top full-DC PPA — 全 NPU + 真 TCM SRAM macro(TSMC28)

- **Date:** 2026-07-08(初稿快照)→ **2026-07-09 timing-constrained 重跑(本文為準)** · **Author:** Claude
- **Flow:** 真 Synopsys DC(`compile -map_effort medium`,FAST=1)+ TSMC28 std-cell + **9 顆真 TSMC28 dual-port SRAM macro**(TCM)· `flow/dc_tsmc28/synth_npu_top.tcl FAST=1 CLK_PERIOD=6.0 USE_SRAM_MACRO=1`
- **狀態:✅ timing-closed(setup MET,WNS=0,0 violating paths)。** 這是正式 timing-constrained pass,取代初稿的 mid-optimization 快照。

> **為何不用 `compile_ultra`:** 此設計含 ~30 個組合 `vdiv` + `fexu` 組合浮點除法(DesignWare 結構化),`compile_ultra` 的積極 datapath restructuring 在此環境 pathologically 慢(>2h 未收)。`compile -map_effort medium` 在 **~3h**(含 area↔timing 多輪震盪收斂)跑到 **setup 全 MET**,拿到乾淨 Fmax + dynamic power。

---

## 1. 綜合對象

`npu_top` 旗艦 SKU(MAT_LANES=4 / DMA_DATA_W=256 / ML_V2_EN=1):**RV32IMF 核心 + 全 Zve32x vexu + fexu + 256-MAC mat_engine + npu_dma + npu_ml_ctrl + fabric + 真 TCM SRAM macro**。TCM = **9 顆真 dual-port SRAM macro**(8× DTCM 1024×32 banked + 1× ITCM 2048×32),`SRAM_MACRO_INSTANCES=9` link 確認。

## 2. 簽核數字(timing-constrained,CLK 6.0 ns)

### Timing(setup)— **MET**
| 指標 | 值 |
|---|---|
| Critical Path Length | **5.93 ns** |
| Critical Path Slack | **0.00 ns**(MET) |
| Total Negative Slack | 0.00 ns |
| Violating paths | **0** |
| **Fmax** | **≈ 166.7 MHz**(1000/6.0;intrinsic path 5.93ns → ~168MHz) |
| Worst path | `u_npu_core/u_core/if_ex_instr_reg[21]` → `ex_mem_f_data_r_reg[26]`(**fexu 浮點 datapath**) |

**Fmax 由組合 `fexu` 浮點 + `vexu` `vdiv` datapath 鎖定**——這是已記錄的 Phase-7 多拍化偏離(ADR-0050 F4 組合浮點 / Phase-E 組合 vdiv)。非 SRAM 路(SRAM 讀是 registered,路被斷開)。多拍化這兩塊即可再往上推。

### Timing(hold)— pre-CTS,預期
Worst Hold −0.08 ns(762 paths,TNS −19.01)。ideal-clock 綜合下的 hold 違例屬正常,**P&R 真 clock tree 階段修**,此階段不處理。

### Area(Total cell area **820,600 µm²**)
| 分項 | µm² |
|---|---|
| Combinational | 483,960 |
| Buf/Inv | 42,498 |
| Noncombinational(FF) | 40,423 |
| **Macro/Black Box(9× TCM SRAM)** | **296,217** |
| **Total cell area** | **820,600** |
| std-cell logic(= Total − SRAM) | ~524,383 |
| Cells | 743,696 |

> ⚠️ 與初稿快照的差異更正:SRAM macro 面積(296,217 µm²)**含在 Total cell area 內**(report_area 的 Macro/Black Box 列),不是「另計」。std-cell 邏輯 ≈ 524K µm²,SRAM macro ≈ 296K µm²。

### Power(report_power −analysis_effort low,ideal clock)
| 指標 | 值 |
|---|---|
| Cell Internal Power | 14.80 mW(93%) |
| Net Switching Power | 1.16 mW(7%) |
| **Total Dynamic Power** | **15.96 mW** |
| Cell Leakage Power | 0.94 mW(938.78 µW) |
| **Total Power** | **16.90 mW** |

## 3. 對照(per-block PPA,已簽的)

| 塊 | area | 頻率 | 來源 |
|---|---|---|---|
| mat_engine 256-MAC | 83,868 µm² | ~1.0 GHz(ADR-0053) | ADR-0067/gate_84 |
| npu_dma @256b | 1,143 µm² | @1.2ns | M3c |
| cpu_m1_top(host,無 vexu) | 26,298 µm² | 699 MHz | phase_05_01 |
| **全 npu_top(本報告)** | **820,600 µm²(含 296K SRAM macro)** | **166.7 MHz** | 本簽核 pass |

全 NPU ~524K µm² std-cell 邏輯 + ~296K µm² SRAM macro,量級合理(RVV core + fexu + 256-MAC + fabric + 9 顆 TCM)。Fmax 166.7MHz 受組合除法/浮點路限,非 datapath 本質上限。

## 4. 誠實界(必讀)

1. **timing 已收(setup MET,WNS 0 @ 6.0ns,0 violating)** — 這是本 pass 的核心成果,取代初稿「WNS 3.55 未收」快照。
2. **Fmax = 166.7 MHz 受組合 `fexu` 浮點 + `vexu` vdiv 鎖定**(worst endpoint = `ex_mem_f_data_r`)。要更高頻須把這兩塊多拍化(Phase-7 已記的偏離)——此為架構優化 step 4 候選。
3. **Option B registered-read 界**(見 `npu_tcm_sram_wrapper_design.md` §7.1):USE_SRAM_MACRO netlist 的 SRAM 讀 timing(registered)**非 cycle-equivalent 到 sim**(sim 組合)。**area/power/timing arc 可信;throughput/cycle 頻率不由此宣稱**。
4. **hold 違例(762)= pre-CTS 正常**,留 P&R 真 clock tree 修,非本階段議題。
5. **power 為 ideal-clock、analysis_effort low 的估算**(非 gate-level VCD annotated);量級參考,精細 power 需 activity-annotated 重跑。
6. **compile 環境註記**:`compile_ultra` 對此設計 pathologically 慢;本 pass 用 `compile -map_effort medium` + `set_max_area 0`,經多輪 area↔timing 震盪(area 1.10M→0.82M)收斂到 setup-MET。

## 5. 結論

**全 NPU(含 9 顆真 TCM SRAM macro)timing-closed 綜合完成:Fmax ≈ 166.7 MHz @ TSMC28、Total cell area 820,600 µm²(std-cell 524K + SRAM macro 296K)、Total Power 16.90 mW(dynamic 15.96 + leakage 0.94)。** setup 全 MET、0 violating paths、DRC clean。這是「全設計可綜合 + timing 收斂 + 含真記憶體 macro + 有 Fmax/power」的完整簽核里程碑。剩餘上頻空間在組合 `fexu`/`vdiv` 多拍化(Phase-7)。

**產物**:`reports/dc_npu_top/`(dc.qor/area/power/timing.rpt + ppa_summary.txt + check_design.rpt)。重跑:`FAST=1 CLK_PERIOD=6.0 MAT_LANES=4 DMA_DATA_W=256 ML_V2_EN=1 USE_SRAM_MACRO=1 dc_shell -f flow/dc_tsmc28/synth_npu_top.tcl`。
