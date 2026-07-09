# CLAUDE.md — `SOC/Magpie_M3V` · 自建 RV32 NPU(目標:功能取代 Google Coral NPU)

> ⭐ **本 repo = Magpie_M3V**,fork 自 M1A(`~/project/SOC/Magpie_M1A`,remote=`parent`,完整歷史)。
> **design_id = `cpu_m3v` / `magpie_m3v`**(物理路徑沿用 `design/cpu_m1/`;身分以 design_id 為準)。identity gate = `gates/gate_00_identity_m3v.py`。
> **clean-room 自建**:M3V 是自建(非 import)。M1/M1A 的證據不得由本線宣稱。繼承自 M1 的「AI 設計 flow / IDE / north-star」**不適用本線**(工程交付線)。
>
> **逐步進度 SSOT = memory `m3v-progress.md`**(每步都記+gotcha)。ADR 在 `docs/adr/`;phase 設計確認在 `design/npu/docs/*_design.md`;三方 review 在 `docs/reviews/`;PPA/perf 在 `docs/reports/`。**本檔只放「使命 + 紀律 + 現況指標 + gotcha」——歷史細節查 memory/ADR/git。**

---

## §0 使命 — 這顆 NPU 必須「取代」Google Coral NPU

**North Star:M3V 的 NPU 必須能『功能取代』Google Coral NPU(Kelvin)。** 不是參考、不是類似——是**可替換的功能對等**:同一 ML workload(TFLM int8 推論)在我們 NPU 上跑出正確結果,ISA/記憶體/卸載契約與 Coral 對齊到足以承接其開源軟體路徑(clang-RVV + TFLM;Google 閉源 IREE 不可用,故走 ISA-parity)。

**衡量成功**:對 Coral 的功能對等清單(§3)逐項綠燈,每項都有 **Spike lockstep / bit-accurate golden / scoreboard** 的權威證據——不是「看起來像」。

> ⛔ **最高優先鐵律:每個階段先確認 NPU 架構設計(對 Coral)再實作。** 見 §2。沒有架構確認不落 RTL。

---

## §1 架構與現況

**兩核 SoC**:`cpu_m1`(host)`--AXI-->` NPU domain。
- **cpu_m1 = 參數化單一 spine**(ADR-0032):`EN_RVC/EN_BP/EN_RAS/EN_F/EN_RVV`。host = 全開;NPU = stripped run-to-completion sequencer(**RV32IMF EN_F=1**),從 TCM 取指、驅動 RVV/矩陣。
- **NPU domain(`design/npu/`)**:`npu_top`(AXI4-Lite CSR / TCM / DECERR)、`npu_dma`(AXI4-full,寬度隨 LANES SKU)、`npu_tcm`(真 TSMC28 dual-port SRAM macro)、mat_engine(256-MAC)、npu_ml_ctrl(v2 tile sequencer)、command-queue、level IRQ。
- **記憶體映射(以 RTL 為準)**:NPU_CSR `0x3000` / DTCM 32KB `0x3001` / ITCM 8KB `0x3002`(Harvard,ADR-0044)/ SHARED_MEM(權重+CQ ring)`0x8000`。core-local CSR 窗 `0x0002`(CQ consumer)。

**現況 = 功能面 / 完整 Zve32x / SoC 兩核 / 架構優化 / 全 DC-synth 皆完成**(§3 對 Coral 8 列全 GREEN-leaning;逐項證據見 memory)。摘要:
- **scalar RV32IMF**(ADR-0050)· **RVV Zve32x 整數+LMUL mf8..m8 全檔位**(ADR-0055-0060;唯缺非-unit-stride 記憶體=誠實 trap)· **矩陣 256-MAC+requant** · TFLM FC/MLP/CNN + **MobileNet + Gemma-3 270M decoder 層** e2e bit-exact。
- **SoC `soc_m3v_top`**(ADR-0068):host `--AXI-->` npu_top,PLIC/IRQ、npu_dma 寬度隨 LANES(q_proj 軌 13,350→1,129 cyc,11.8×)。mat_engine v2(ADR-0067)+ RMSNorm→RVV。
- **物理**:全設計 DC-synthesizable + npu_top timing-closed(真 TCM SRAM macro)。**Fmax 優化**(fexu fdiv/fsqrt + vexu vdiv 迭代化 + FMA 2-stage,皆 bit-exact 零回歸)把 npu_top 從 **166.7MHz → ~460MHz(2.8×)、area −50%**,critical path 已移出 CPU core 到 mat_engine 256-MAC 累加器。報告 `docs/reports/2026-07-09_fdiv_multicycle_poc.md`;per-block PPA 見 memory。

**驗證迴圈(一鍵重跑,Verilator DUT + Spike golden + riscv64-unknown-elf-gcc firmware)**:
- host lockstep = `flow/v2_pipeline/phase_03_*`;NPU core = `phase_20_npu_core_lockstep`(`make directed`/`random SEED=n`/`coverage`);vector = `phase_22_vector_csr_lockstep`(`make b1/grid/s1/vrand/f2/frand/…`)。
- gate 三分家(見 §4.3):`gates/` · `sim/gates/` · `dv/gates/`。

---

## §2 每階段「NPU 架構設計確認」(鐵律)

每個 phase / 缺漏開工前,**先做架構設計確認**,產物入 ADR(或 `design/npu/docs/*_design.md`),經 review 才寫 RTL:
1. **Coral 對照**:對應 Coral 哪個機制?差異是否影響「可取代」?(Grok 出架構判斷;Gemini 出全上下文對照)
2. **契約**:介面 / CSR / memory-map / ABI / command 編碼。牽涉 SSOT(CQ、矩陣 op)先凍結 schema(RTL + host header + golden 共用一份)。
3. **驗證計畫**:權威 golden(Spike lockstep / bit-accurate NumPy / AXI scoreboard)+ gate 名 + 通過門檻 + green-wash 守衛。
4. **review 後才實作**:Codex 外科實作 → Claude 跑權威驗證 → commit。**沒有架構確認不落 RTL。**

---

## §3 Coral 功能對等清單(取代 = 逐項綠燈 + 權威證據)

| 面向 | Coral | 我們的對等 | 狀態 |
|---|---|---|---|
| 純量 ISA | RV32IMF_Zbb | RV32IMF(sequencer EN_F=1) | ✅ ADR-0050,gate_60/61 |
| 向量 | RVV Zve32x + vtype/vl/vstart/vxsat | 標準 Zve32x 整數+LMUL 全檔 + 向量-CSR lockstep | ✅ ADR-0055-0060,gate_40/41/56-81 |
| 矩陣 | 256-MAC outer-product int8→int32 + acc + requant | 256-MAC + acc + scale/ZP requant + NumPy golden | ✅ ADR-0037/40,gate_45/46 |
| 記憶體 | ITCM 8K/DTCM 32K,128-bit | Harvard ITCM/DTCM + banked + 真 SRAM macro | ✅ ADR-0044,gate_52 |
| 卸載 | doorbell→DMA→compute→writeback→IRQ | 雙向 DMA + CQ ring + DONE/ERR/FULL | ✅ ADR-0033/35/38 |
| 例外/控制 | traps + abort/reset | NPU trap-to-host ERR_CAUSE + soft_reset | ✅ ADR-0038/47,gate_47/54 |
| 軟體 | TF→MLIR→IREE(閉源) | 開源 clang-RVV + TFLM + 自建 CQ encoder | ✅ ADR-0041,gate_49 |
| 除錯 | RVVI/RVFI | NPU trace port(v1 insn/mem/mtval/mstatus) | ✅ ADR-0045/48,gate_53(PARTIAL) |

**門檻**:每項用 §2 的權威證據背書(誠實界)。目前 8 列全 GREEN-leaning。

---

## §4 規則(不可協商)

1. **Reference policy**:RISC-V spec = 架構契約。Coral 是 Apache-2.0,可觀察/借用(標 provenance);借架構想法要 ADR。正確性權威 = 本線自身 **Spike lockstep + gate**。CVA6/Synopsys 等 licensed IP 可觀察埠/參數不可複製 RTL。
2. **ADR-per-decision**:任何架構決策/偏離寫 `docs/adr/NNNN-*.md`(MADR)。含每階段架構確認(§2)。
3. **Phase gate 三分家**:`gates/`(基本電路/core-unit/scalar pipeline)· `sim/gates/`(系統功能:NPU/AXI/CQ/RVV/mat/benchmark e2e)· `dv/gates/`(coverage)。gate 是 `gate_*.py`(非 `test_*.py`),用明確檔路徑跑。前關綠才進下一步。
4. **驗證權威 = Spike lockstep + bit-accurate golden + scoreboard**。cpu_m1 **可修改但必改必驗**(ADR-0032:host commit-trace 等價;NPU rv32im(f) lockstep)。
5. **模擬引擎政策**:**Verilator**(`--binary --timing`,in-sandbox)+ **VCS**(signoff,**OUTSIDE-SANDBOX**,licensed-EDA 路徑)。**iverilog 不使用**。OSS(verilator/spike/yosys)不受 sandbox 限制。DC/PDK/SRAM macro = licensed,不進 git(`.gitignore` 已擋 `*.db/*.lib/sram_*`)。
6. **誠實界**:未跑 = `not-run` 不假綠;docs 不得宣稱 RTL 沒做的東西;「取代 Coral」宣稱必逐項證據背書。
7. **filelist 三處同步**:加/改 RTL 要同步 `phase_20`+`phase_22` Makefile 的 NPU_SRCS/CPU_SRCS(曾漏致 RVV/F lockstep 靜默壞)。
8. **code-first / token 紀律**:機械工序碼化;大 bytes 交 Gemini 濃縮再進 Claude。

---

## §5 co-work 分工(三方 + Gemini,已實測)

| 角色 | 定位 | 何時 / 呼叫 |
|---|---|---|
| **Claude(我)** | PL / 唯一 committer / 跑權威 lockstep+scoreboard / green-wash 守衛 | 全程;每可驗證子步 commit 前把關 |
| **Grok** | 架構師 / DV 計畫 / spec | 每階段架構確認先出。`grok -p "…"`(需加「Do NOT use tools」) |
| **Codex** | 外科式 RTL 實作 + 自驗 Verilator | 架構確認+ADR accepted 後。`codex exec -s workspace-write "…" </dev/null`(只動指定檔;其 sandbox DC license 常壞→DC 我自跑) |
| **Gemini** | 全上下文 review(整包 RTL + Coral datasheet + 全 ADR 一致性) | 大範圍 review / 缺漏對照。`gemini --yolo --skip-trust -p`(key 存 session scratchpad `.gemini_env`,非 repo/memory) |

**green-wash 守衛(Claude 強制,任一觸犯即退)**:縮測試 scope、在 TB 而非 RTL 關功能、lockstep 用錯 `--isa`、跳過 trace-diff、用 IMEM 假冒 TCM、docs 過度宣稱。
**心跳**:背景 agent/長 job,Claude 每 ≤5 分鐘確認(判活看 CPU time `ps -o etimes,time`);死了立刻換手。**重點用中文。**

---

## §6 目錄 / 關鍵文件

- `design/cpu_m1/`(host + NPU 參數化 spine)· `design/npu/`(NPU RTL/dv/docs/sw)· `gates/`+`sim/gates/`+`dv/gates/`· `sim/`(系統功能驗證)· `dv/`(coverage/lint/cdc)· `flow/v2_pipeline/phase_*`(可重跑 lockstep + EDA)· `flow/dc_tsmc28/`(DC + memory-compiler)· `flow/state/`(cpu_m3v 證據)。
- **SSOT / 起點**:memory `m3v-progress.md`(逐步進度)· `docs/adr/`(決策)· `design/npu/docs/*_design.md`(phase 設計確認)· `docs/reviews/`(三方 review)· `docs/reports/`(PPA/perf,含 `gemma_opt_ledger.md`)。
- **契約文件**:`design/npu/docs/00_isa_contract.md` / `01_axi_fabric_spec.md`;`docs/Magpie-M3V-RV_NPU_Design_Spec.html`(頂層架構 + 兩-AXI + command 編碼參考)。**實作真值以本 repo RTL 為準**。
- **platform/lib**(直接 import):`pipeline` · `sim`(Verilator)· `spike_ref`(golden)· `riscv_rand` · `wave` · `parsers`。
- **~/EDA/**:跨計畫 EDA 筆記(`13` memory compiler · `14` DC/Presto synthesis)。

---

## §7 下一步 + recurring gotcha

**下一步序(User 裁示)**:soc_m3v_top DC / RMSNorm 全模型 H=640(descriptor 加寬/chunk)/ 其他非線性 RVV 化(RoPE/Softmax/ewise-mul,同 RMSNorm pattern)/ HW region guard(M3b-3-full)/ v2 Phase A.2(K>64 多 chunk)/ VCS/Spyglass/coverage 簽核 / (可選)mat_engine MAC 累加樹 pipeline 續衝 Fmax >460MHz。**每項先走 §2 鐵律。**

**recurring gotcha(踩過的坑,務必記得)**:
- **filelist 三處同步**(§4.7):RVV/F lockstep gate「8 秒快速失敗」= build MODMISSING(filelist 漏檔)**非** lockstep 發散。
- **DC/Presto 要 declaration-before-use**(Verilator 2-pass 容忍 forward-ref);修法 = 純宣告重排(RHS byte-for-byte,零邏輯改)。DC `-parameters` 改設計名 → `current_design [lindex [get_designs npu_top*] 0]`。lib=`flow/dc_tsmc28/lib_setup.tcl`。**compile_ultra 對組合 vdiv/float-div pathologically 慢 → 用 `FAST=1`(`compile -map_effort medium`)**。
- firmware **`-mno-relax`**(DUT/Spike `la` 位址編碼一致)。
- **`pkill -f <pat>` 會殺自身 shell**(命令列含 pat)→ 用 `kill <pid>` 或 `pgrep -x`。判活看 `ps -o etimes,time`(zombie 會騙 pgrep)。
- signed `>>>` 在 unsigned ternary context 變邏輯移 → 用自決定 signed 中間 wire;signed×unsigned 用 `$signed({1'b0,b})`;`sgA<<38` 在窄 context=0 → 先零延伸。
- masked body op 寫 v0 = illegal(每新 RVV op 加進 q_illegal);**Spike 實跑 > 第三方 spec flag**(legality 必 probe)。
- 多拍化(fdiv/fsqrt/vdiv/FMA)pattern:special case 1 拍組合、normal case 迭代/2-stage 經 stall(busy 併進 pipe stall);**stall 計數器須獨立於 m_stall**(否則死鎖);flush 清 state。signed 除法走 unsigned magnitude + 補碼 fixup + bz/sov override。
- **GitHub 顯示 SVG**:用 markdown `![](path.svg)`,SVG 需明確 px width/height + version、**移除 `<style>`(sanitizer 會剝)**、樣式全 inline(參考 `docs/img/*.svg`)。
