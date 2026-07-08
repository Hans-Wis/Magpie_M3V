# npu_top full-DC PPA — 全 NPU + 真 TCM SRAM macro(TSMC28）

- **Date:** 2026-07-08 · **Author:** Claude · **Flow:** 真 Synopsys DC + TSMC28 std-cell + **真 TSMC28 dual-port SRAM macro**(TCM)· `flow/dc_tsmc28/synth_npu_top.tcl USE_SRAM_MACRO=1`
- **狀態:⚠️ mid-optimization 快照(非簽核）。** compile_ultra 在此環境對這設計 pathologically 慢(組合 vdiv/float-div + 大設計 + thrashing),跑 ~2h16m(DC 內部)/ >130min 牆鐘後於 Phase-40 優化**手動中止**取收斂值(User 裁示)。

---

## 1. 綜合對象

`npu_top` 旗艦 SKU(MAT_LANES=4 / DMA_DATA_W=256 / ML_V2_EN=1):**RV32IMF 核心 + 全 Zve32x vexu + fexu + 256-MAC mat_engine + npu_dma + npu_ml_ctrl + fabric + 真 TCM SRAM macro**。**TCM = 9 顆真 dual-port SRAM macro**(8× DTCM 1024×32 + 1× ITCM 2048×32),elaborate+link 確認 `SRAM_MACRO_INSTANCES=9`。

## 2. 收斂快照(compile_ultra QoR 表最後列,elapsed 2:16:49 @ CLK 2.0ns)

| 指標 | 值 | 註 |
|---|---|---|
| **Total cell area** | **≈ 742,455 µm²** | 全 npu_top **std-cell logic**;**TCM SRAM = macro,面積另計**(不在此 cell area) |
| **Worst Neg Slack** | **3.55 ns @ 2.0 ns clock** | **timing 未收於 500 MHz**;粗估 Fmax ≈ 1000/(2.0+3.55) ≈ **180 MHz**(loose,mid-compile) |
| **Leakage power** | ≈ 583,693 nW ≈ **0.58 mW** | dynamic power 未取(report_power 未跑=compile 中止前）|
| Setup cost / DRC cost | 3533.5 / 248.1 | 優化 cost 指標 |

## 3. 對照(per-block PPA,已簽的)

| 塊 | area | 頻率 | 來源 |
|---|---|---|---|
| mat_engine 256-MAC | 83,868 µm² | ~1.0 GHz(ADR-0053）| ADR-0067/gate_84 |
| npu_dma @256b | 1,143 µm² | @1.2ns | M3c |
| cpu_m1_top(host,無 vexu) | 26,298 µm² | 699 MHz | phase_05_01 |
| **全 npu_top(本報告)** | **~742,455 µm²** | ~180 MHz(loose)| 本快照 |

全 NPU ~742K µm² 量級合理(RVV core + fexu + 256-MAC + fabric);比 per-block 加總大,因含整合邏輯 + 全 RV32IMF core + 全 Zve32x vexu(vdiv/segment/gather 等)。

## 4. 誠實界(必讀)

1. **非簽核數字**:mid-optimization 快照(Phase-40 中止),非 optimization-complete;area/timing 可能再變(area 從 748,985 收到 742,455,仍在降;WNS 未收斂)。
2. **timing 未收**:WNS 3.55@2.0ns → 500MHz 不過。**需正式 timing-constrained pass**(合理 clock target + SDC + 多 corner）拿真 Fmax。整合關鍵路徑疑似 vexu 組合 vdiv 或跨塊路(非 SRAM——SRAM 讀是 registered,路被斷開）。
3. **Option B registered-read 界(見 `npu_tcm_sram_wrapper_design.md` §7.1)**:USE_SRAM_MACRO netlist 的讀 timing(SRAM registered)**非 cycle-equivalent 到 sim**(sim 組合）。**area/leakage/macro timing arc 可信;throughput/cycle/tape-out 頻率不可宣稱**。
4. **dynamic power 未取**（compile 中止前 report_power 未跑）。
5. **compile 環境問題**:compile_ultra 對這設計(~30 vexu vdiv + fexu float div 的 DesignWare 結構化）在 WSL2 pathologically 慢。**下次建議**:(a) 用 `compile -map_effort medium`(非 compile_ultra)快出粗略 PPA;或 (b) 合理 clock(如 CLK 3.0-4.0ns)+ 分區綜合;或 (c) 對 vdiv/float-div 加 `set_dont_touch` / 多拍化(Phase 7 記過的 mat/fexu 多拍化偏離)。

## 5. 結論

**全 NPU(含真 TCM SRAM macro)可綜合 + area 收斂 ≈ 742K µm²(std-cell logic）+ leakage ≈ 0.58 mW**。TCM 已從 black-box 升級為 **9 顆真 TSMC28 dual-port SRAM macro**。**timing 未收(WNS 3.55@2.0ns)= 需正式 timing pass 拿 Fmax**;dynamic power 待重跑。這確立了「全設計可綜合 + 含真記憶體 macro」的里程碑;精確 Fmax/power 簽核留正式 timing-constrained 重跑(較快設定)。

**產物**:`reports/dc_npu_top/`(check_design.rpt)· log `flow/dc_tsmc28/dc_overnight_20260708_201004.log`(完整）。重跑:`USE_SRAM_MACRO=1 bash flow/dc_tsmc28/run_overnight_dc.sh`(或改 `compile` 較快)。
