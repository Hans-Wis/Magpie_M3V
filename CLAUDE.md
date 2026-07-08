# CLAUDE.md — `SOC/Magpie_M3V` · 自建 RV32 NPU（目標:功能取代 Google Coral NPU）

> ⭐ **本 repo = Magpie_M3V**。fork 自 `m1a-rtl-freeze-v1.0`(M1A @ 51a6fe0,完整歷史,remote=parent → `~/project/SOC/Magpie_M1A`);祖系 M1 @ 4e6e1d4。
> **design_id = `cpu_m3v` / `magpie_m3v`**(物理路徑沿用 `design/cpu_m1/`;身分以 design_id 為準)。identity gate = `gates/gate_00_identity_m3v.py`。
> **與 sibling 硬隔離**:M1V = IMPORT CoralNPU(ADR-0030);**M3V = 自建**。M1/M1A/M1V 的證據不得由本線宣稱;flow/state 從空白重新掙。
> **框架註記**:繼承自 M1/M1A 的「AI 設計 flow / IDE 示範 / north-star」**不適用本線**(同 M1V,屬工程交付線)。舊 M1 charter 全文見 git 歷史 / parent repo。

---

## §0 使命 — 這顆 NPU 必須「取代」Google Coral NPU

**North Star(User 裁示 2026-07-03,升級):M3V 的 NPU 必須能『功能取代』Google Coral NPU(Kelvin)。**
不是「參考」、不是「類似」——是**可替換的功能對等**:同一 ML workload(TFLM int8 推論)能在我們的 NPU 上跑出正確結果,ISA/記憶體/卸載契約與 Coral 對齊到足以承接其軟體路徑(開源 RVV + TFLM;Google 閉源 `coral-opt`/IREE 不可用,故走 ISA-parity 讓標準開源鏈套用)。

**衡量成功**:對 Coral 的**功能對等清單**(§3)逐項綠燈,且每項都有 **Spike lockstep / bit-accurate golden / scoreboard** 的權威證據——不是「看起來像」。

> ⛔ **鐵律:每個階段都要先確認 NPU 架構設計(對 Coral)再實作。** 見 §2。任何階段開工前,先產/更新該階段的**架構設計確認**(對 Coral 對照 + 契約 + 驗證計畫,寫進 ADR),經 review 才落 RTL。這是本線最高優先的紀律。

---

## §1 架構與現況

**兩核 SoC**:`cpu_m1`(主 host CPU）`--AXI-->` NPU domain。
- **cpu_m1 現在是「參數化單一 spine」**(ADR-0032,取代原「凍結複製」構想):`EN_RVC/EN_BP/EN_RAS`(+ 規劃中 `FETCH_SRC=TCM`)。host = 全開;NPU = stripped run-to-completion sequencer,從 TCM 取指、驅動 RVV/矩陣。
- **NPU domain(`design/npu/`)**:`npu_top`(AXI4-Lite CSR@0x3000 / TCM@0x3001 / DECERR 解碼)、`npu_dma`(AXI4-full 突發)、`npu_tcm`、level IRQ。淨新 ML datapath(RVV Zve32x + GEMV/矩陣 + writeback DMA + command-queue)長在這裡。

**記憶體映射(以實作為準)**:NPU_CSR **0x3000_xxxx** / DTCM 32KB **0x3001_xxxx** / **ITCM 8KB 0x3002_xxxx**(ADR-0044 Harvard;鏡像載入契約)/ SHARED_MEM(權重+CQ ring)**0x8000_xxxx**。(plan HTML 早稿的 0x4000 作廢。)

**已建置 + 已驗證(Verilator + Spike lockstep,gates green)**:
| Phase | 內容 | 證據 |
|---|---|---|
| 0 | 開源 RVV Zve32x toolchain 在 Spike ISS 跑通(clang int8 dot,不靠 Google 閉源鏈) | `gate_p0_toolchain_iss` |
| 1 + 1.5 | AXI4-Lite fabric + AXI4-full **read** DMA + TCM + IRQ;bus 協定硬化(W-before-AW/WSTRB/DECERR/LEN0/RRESP) | `gate_20/25/27/28` |
| 2 Step 2 | cpu_m1 參數化 `EN_RVC/EN_BP/EN_RAS`(host-equivalent) | host lockstep 重跑(directed/trap/random 對 Spike 相符)+ 雙組態 lint |
| P0① | **result writeback DMA**(npu_dma 雙向;Coral 卸載迴圈兩半齊)ADR-0033 | `gate_29`(writeback scoreboard + SLVERR abort) |
| 2 Step 4 | **NPU core 進 socket**(ADR-0034):stripped cpu_m1 於 npu_top 內從真 npu_tcm 取指;CTRL.start 閘 reset;DONE mailbox→STATUS/IRQ | `gate_30..34`:directed 1164 + random **8×10,809 commits** lockstep(rv32im 無 C)、DMA-vs-core 仲裁真重疊、strip coverage(bp/ras/cdec 零 points) |
| P0② | **Command queue**(ADR-0035):shared-mem ring @0x8000 + TAIL doorbell;sequencer 經 core-local CSR 窗 0x0002_xxxx 當 consumer;v4 §06 SSOT(YAML→.vh/.h/.py);LOAD_W/STORE/FENCE 可執行,OP/RESCALE 誠實 ERR | `gate_35..39`:SSOT regen-diff、ring wrap/FULL、**CQ vs 直接 CSR 執行等價**(AXI 交易級)、ERR ladder、consume 全鏈 lockstep 298/298 |
| 3A(P0④) | **vector CSR + vset{i}vl{i}**(ADR-0036):`EN_RVV` 參數(host=0);vtype/vl/vstart/vxsat/vcsr/vlenb + vill + mstatus.VS;**vector-CSR lockstep 契約上線**(checkpoint 紀律) | `gate_40/41`:vsetvli 網格 134/134 + vill ladder 51/51 vs Spike `zve32x_zvl128b`;抓到並修復 vx 別名組 CSR 轉發 bug |

**驗證迴圈可用**:`flow/v2_pipeline/phase_03_0*/Makefile`(host)+ `phase_20_npu_core_lockstep/`(NPU:`make directed` / `make random SEED=n` / `make coverage`)= **Verilator(DUT)+ Spike(golden)+ riscv64-unknown-elf-gcc(firmware)** 一鍵重跑。baseline tag `m3v-pre-phase2-cpu`。

**Roadmap(對 Coral 對等,含缺漏 folded — 見 `docs/reviews/2026-07-03_coral_gap_review.md`)**:
- **P0 缺漏:全部完成(2026-07-04)** ✅ ①writeback ②command queue ③矩陣 64-MAC+requant ④vector-CSR lockstep(隨 Phase 3)⑤traps/abort(ADR-0038,gate_47)。RING_OVERRUN 偵測 deferred(host-side ABI)。
- Phase 3 RVV ✅(3A-3D,kernel=240)→ Phase 4 矩陣 64-MAC+requant ✅ → **Phase 6 首戰 ✅(ADR-0039:TFLM int8 FC 六 corner bit-exact e2e,gate_48)** → **256 MAC/cycle ✅(ADR-0040,throughput gate 實測)** → **TFLM runtime AOT ✅(ADR-0041:真 .tflite 2 層 MLP 多 op 鏈接 bit-exact,gate_49)** → **CNN ✅(ADR-0042:Conv2D per-channel + K-chunking,gate_50)+ 卸載收尾 ✅(ADR-0043:2D/strided DMA + host producer ABI,gate_51)** → **列 4 記憶體 ✅(ADR-0044:ITCM 8K/DTCM 32K Harvard + banked DTCM,gate_52)** → **列 8 RVFI/RVVI-lite ✅(ADR-0045:lockstep 換源自 trace port 全符,gate_53;PARTIAL,v1=insn/mem/mtval)** → **功能補齊中(User 裁示:功能→架構優化→簽核)**:列 6 hard-reset ✅(ADR-0047,gate_54)→ 列 8 trace v1 ✅(ADR-0048:insn/mem/mtval/mstatus,列 8 GREEN-leaning)→ **RVV Phase-A 收齊 S1-S4 ✅(ADR-0049;POOL 對 TFLM bit-exact 含 half-away 引理,gate_56-59;列 2 GREEN-leaning)** → **scalar F 全套 ✅(ADR-0050 F1-F4:fexu softfloat-3 忠實轉寫 + fcsr/FS 契約 + F-reg lockstep;directed 135+269 + random ~5.5K commits vs Spike rv32imf;gate_60/61;列 1 GREEN,F4 組合邏輯=Phase 7 多拍化偏離已記)** → **功能補齊完成** → **架構優化 ✅(ADR-0051/52/53:mat_engine ~730MHz→~1.0GHz)** → **完整 Zve32x 產品規格 ✅(Phase-B~F 全收齊,ADR-0055-0060,gate_62-81)** → **MobileNet + Gemma-3 270M 層 e2e ✅** → **SoC 兩核系統 ✅(ADR-0068:soc_m3v_top M1 minimal→M2 PLIC/IRQ→M3a/b/c npu_dma 寬度隨 LANES;q_proj 11.8×)** → **RMSNorm→RVV ✅(層 -42k cyc)** → **全設計 DC-synthesizable ✅(@8b783a0;npu_top PPA 隔夜 job)** → 續:npu_top 隔夜 PPA / soc DC / VCS/Spyglass/coverage 簽核。**詳見 §7 重啟指南(SSOT=memory `m3v-progress.md`)。**
- **P1**:NPU traps/ERR_CAUSE、cache flush-before-doorbell、ITCM/DTCM sizing(8K/32K)、strided/2D DMA、RVVI/RVFI trace。
- **scope-cut(已記錄):** L0 I-cache、clock/power gating、double-buffer。(scalar F 已於 ADR-0050 回收完成。)

---

## §2 每階段「NPU 架構設計確認」(鐵律)

每個 phase / P0 缺漏開工前,**先做架構設計確認**,產物入 ADR(或 phase spec doc),經 review 才寫 RTL:
1. **Coral 對照**:這階段對應 Coral 的哪個機制?我們的設計與 Coral 的差異、是否影響「可取代」?(Gemini 出全上下文對照;Grok 出架構判斷)
2. **契約**:介面 / CSR / memory-map / ABI / command 編碼 —— 若牽涉 SSOT(如 CQ、矩陣 op),先凍結 schema(RTL + host header + golden 共用)。
3. **驗證計畫**:權威 golden(Spike lockstep / bit-accurate NumPy / AXI scoreboard)+ gate 名 + 通過門檻;列出 green-wash 守衛。
4. **review 後才實作**:Codex 外科實作 → Claude 跑權威驗證 → commit。**沒有架構確認不落 RTL。**

---

## §3 Coral 功能對等清單(取代 = 逐項綠燈 + 權威證據)

| 面向 | Coral | 我們的對等目標 | 狀態 |
|---|---|---|---|
| 純量 ISA | RV32IM**F**_Zbb | RV32IMF(sequencer EN_F=1);參數化 stripped sequencer | ✅ GREEN(ADR-0050,gate_60/61) |
| 向量 | RVV Zve32x VLEN128 + vtype/vl/vstart/vxsat | 標準 RVV Zve32x + **向量 CSR lockstep 契約** | P0 ④,Phase 3 |
| 矩陣 | 256-MAC outer-product int8→int32 + 8×8×32b acc + requant | 64→256 MAC + acc + scale/ZP requant + NumPy golden | P0 ③,Phase 4/5 |
| 記憶體 | ITCM 8K/DTCM 32K,128-bit | ITCM/DTCM sizing + 128-bit port | P1 |
| 卸載 | doorbell→DMA cmd+weights→compute→**DMA writeback**→IRQ | **雙向 DMA** + command-queue ring + DONE/ERR/FULL | P0 ①②⑤ |
| 例外/控制 | traps + abort/reset | NPU trap-to-host ERR_CAUSE + 真 abort/soft_reset | P0 ⑤ / P1 |
| 軟體 | TF→MLIR→IREE(閉源) | 開源 clang-RVV + TFLM + 自建 CQ encoder | Phase 0 部分 ✅ |
| 除錯 | RVVI/RVFI | NPU trace port | P1 |

**取代宣稱的門檻**:整清單綠燈前不得宣稱「可取代 Coral」;每項用 §2 的權威證據背書(誠實界)。

---

## §4 規則(不可協商)

1. **Reference policy**:RISC-V spec = 架構契約。Coral 是 **Apache-2.0**,可觀察/借用(標 provenance);借架構想法要 ADR。正確性權威 = 本線自身 **Spike lockstep + gate**。
2. **ADR-per-decision**:任何架構決策/偏離寫 `docs/adr/NNNN-*.md`(MADR)。含每階段架構確認(§2)。
3. **Phase gate**:每階段 `gate_*.py`,前關綠才進下一步。**gate 三分家(reorg Stage 3)**:`gates/`(基本電路/core-unit/scalar pipeline)· `sim/gates/`(系統功能:NPU/AXI/CQ/RVV/mat/benchmark e2e,含共用 harness `gate_20_axi_fabric`)· `dv/gates/`(coverage gate_90/91)。gate 是 `gate_*.py`(非 pytest 預設 `test_*.py`),用明確檔路徑跑。
4. **驗證權威 = Spike lockstep + bit-accurate golden + scoreboard**。cpu_m1 **可修改但必改必驗**(ADR-0032:host commit-trace 等價;NPU rv32im lockstep)。`gate_10` 已從「byte-identical 凍結」改為「trace 等價 + ADR-governed」。
5. **模擬引擎政策(User 裁示)**:**Verilator**(`--binary --timing`,in-sandbox)+ **VCS**(signoff,**OUTSIDE-SANDBOX**,經 licensed-EDA 路徑,Codex `-s danger-full-access` 或使用者跑)。**iverilog 不使用**。OSS(verilator/spike/yosys)不受 sandbox 限制。
6. **誠實界**:未跑 = `not-run` 不假綠;docs 不得宣稱 RTL 沒做的東西(Codex 稽核已抓過一輪,見 gap review §D)。「取代 Coral」宣稱必逐項證據背書。
7. **code-first / token 紀律**:機械工序碼化;大 bytes 交 Gemini 濃縮再進 Claude。

---

## §5 co-work 分工(三方 + Gemini,已實測)

| 角色 | 定位 | 何時 |
|---|---|---|
| **Claude(我)** | PL / 唯一 committer / 驗收之記 / **跑權威 lockstep+scoreboard** | 全程;每可驗證子步 commit 前把關 |
| **Grok** | 架構師 / DV 計畫 / spec | 每階段架構確認先出(`grok -p`,需加「Do NOT use tools」) |
| **Codex** | 外科式 RTL 實作 + 自驗 Verilator | 架構確認+ADR accepted 後(`codex exec -s workspace-write`,只動指定檔) |
| **Gemini** | **全上下文**:整包 RTL + Coral datasheet + 全 ADR 一致性/合規對照 | 大範圍 review / 缺漏對照(`gemini --yolo --skip-trust -p`;key 存 session scratchpad `.gemini_env`,非 repo/memory) |

**green-wash 守衛(Claude 強制,任一觸犯即退)**:縮測試 scope、在 TB 而非 RTL 關功能、lockstep 用錯 `--isa`、跳過 trace-diff、用 IMEM 假冒 TCM、docs 過度宣稱。
**心跳**:背景 agent/長 job 執行,Claude 每 ≤5 分鐘確認(判活看 CPU time,`ps -o etimes,time`);死了立刻換手。**重點用中文**。

---

## §6 目錄 / 工具 / 關鍵文件

- `design/cpu_m1/`(host + NPU 參數化 spine)· `design/npu/`(NPU domain RTL/dv/docs/sw)· **`gates/`+`sim/gates/`+`dv/gates/`(gate 三分家,見規則 §4.3)**· `sim/`(系統功能驗證:models/patterns/run_bench)· `dv/`(coverage/lint/cdc)· `flow/v2_pipeline/phase_03_0*/`(可重跑 lockstep)· `flow/state/`(cpu_m3v 證據)。
- **關鍵文件**:`docs/adr/0031`(scope)· `0032`(cpu 參數化+驗證)· `docs/reviews/2026-07-03_multiagent_review.md`(架構 review)· `docs/reviews/2026-07-03_coral_gap_review.md`(**Coral 缺漏對照**)· `design/npu/docs/00_isa_contract.md` / `01_axi_fabric_spec.md` · **`rv32_npu_design_plan_v4.html`(v0.2,設計報告參考,User 2026-07-03)**——含 **§06 Command 編碼 Spec v0.1**(128-bit descriptor + opcode 表 MAT.CFG/LOAD_W/OP/RESCALE/STORE/ACC_CLR/FENCE + MAC 陣列/acc/執行單元數量 + L1→L5 下降對照);**§06 是 CQ/矩陣的 SSOT 設計參考**(P0②③ 缺漏的設計基準,實作時 RTL 解碼器 + IREE codegen + NumPy golden 共用同一份)。`rv32_npu_design_plan.html`(v0.1)已 superseded。**注意**:設計報告的記憶體映射(0x4000/ITCM/DTCM)與 IREE-plugin/RVVI 為藍圖;**實作真值以本 repo RTL 為準**(NPU_CSR 0x3000 / TCM 0x3001;開源 clang-RVV)。· 參考 lab `~/project/lab/CPU/Ch5_NPU`(Coral de-blackbox)。
- **platform/lib**(直接 import):`pipeline`(record_step/build_report)· `sim`(Verilator)· `spike_ref`(golden)· `riscv_rand`· `wave`· `parsers`。gate 取 platform/lib 慣例照 X6/M1。

---

## §7 現況 / 下一步

> ⭐ **重啟指南(2026-07-08,@fc06ae5;session 極長後 checkpoint)**:**逐步進度 SSOT = memory `m3v-progress.md`**
> (每步都記,含 gotcha);逐項 ADR 在 `docs/adr/`;各 phase 設計確認在 `design/npu/docs/*_design.md`(§6/§8=review resolutions);
> 三方 review 全文在 `docs/reviews/`;PPA/perf 報告在 `docs/reports/`(含 `gemma_opt_ledger.md` 優化台帳)。

**A. 功能面 + 完整 Zve32x = 完成**。§3 對 Coral 8 列全 GREEN-leaning。scalar F 全套(RV32IMF,ADR-0050)、
RVV **Zve32x 整數+LMUL(mf8..m8)全檔位 Phase-B~F 收齊**(ADR-0055-0060,gate_62-81;唯缺=非-unit-stride 記憶體,
誠實 trap)、矩陣 256-MAC+requant、TFLM FC/MLP/CNN + **MobileNet + Gemma-3 270M decoder 層** e2e bit-exact。

**B. SoC 兩核系統 + 架構優化 = 完成(M1→M3c 全綠)**:cpu_m1(host)`--AXI-->` npu_top(NPU)。
- **soc_m3v_top**(ADR-0068):M1 minimal(真 host 驅動卸載 bit-exact)→ M2 PLIC/IRQ(真中斷,meip 解法=直接 cpu_m1_top+axil_bridge)
  → **M3a/b/c npu_dma AXI 寬度隨 LANES SKU**(DMA_DATA_W=64×LANES hard-bind;讀+寫路寬化+narrow two-tier 通用 CQ 安全;
  DC PPA 寬 DMA ~free)→ **q_proj 軌 13,350→1,129 cyc(11.8×)**。
- **mat_engine v2**:PA tile sequencer(npu_ml_ctrl)+ activation-stationary + header-trim(ADR-0067,gate_67);
  DC step0-3(ADR-0051/52/53:mat_engine ~730MHz→~1.0GHz)。
- **軟體軌**:**RMSNorm→RVV Zve32x**(ADR/design `rmsnorm_rvv_design.md`;層 349,824→307,458,flip 0/256;golden=獨立
  Spike-validated rvv_bitmodel,非湊 RTL)。

**C. 全設計 DC-synthesizable = 完成(@8b783a0);npu_top 全 compile PPA = 隔夜 job(@fc06ae5)**:
- 核心 RTL 的 Verilator-style forward-ref(decl-after-use)DC/Presto 拒 → **純宣告重排(byte-for-byte RHS,零邏輯改)**:
  idu/core/vexu/npu_top/npu_axil_regs。npu_top 旗艦(MAT_LANES=4/DMA_DATA_W=256/ML_V2_EN=1)elaborate+link **Presto-clean**
  (TCM black-box `flow/dc_tsmc28/npu_tcm_bb.v`;**npu core = RV32IMF EN_F=1**)。零回歸驗:RVV+F gate_56-81+60/61 = **76 passed**。
- **npu_top 全 compile_ultra ~40-60 分(vexu RVV 組合 vdiv + fexu float divider 多),延後隔夜跑**:
  `nohup bash flow/dc_tsmc28/run_overnight_dc.sh > /tmp/dc_overnight.out 2>&1 &`
  → 產出 `reports/dc_npu_top/ppa_summary.txt` + `flow/dc_tsmc28/DONE_NPU_TOP_PPA` marker → **下次 session 看 marker 補 PPA 報告**。
- **既有 per-block PPA**:mat_engine 83,868µm²(256-MAC)· npu_dma 1,143µm²(256b,ADR/M3c)· cpu_m1_top-host 26,298µm²/699MHz。

**D. 下一步序(User 裁示)**:npu_top 隔夜 PPA 收尾 + soc_m3v_top DC / RMSNorm 全模型 H=640(descriptor 加寬/chunk)/
其他非線性 RVV 化(RoPE/Softmax/ewise-mul,同 RMSNorm pattern)/ HW region guard(M3b-3-full)/ v2 Phase A.2(K>64 多 chunk)/
VCS/Spyglass/coverage 簽核。

**測試/工具重點 + recurring gotcha**:
- vector lockstep = `flow/v2_pipeline/phase_22_vector_csr_lockstep`(`make b1/grid/s1/vrand/c2/…`);host lockstep=`phase_03_*`;
  NPU core=`phase_20_npu_core_lockstep`。firmware **`-mno-relax`**(DUT/Spike la 位址編碼一致)。
- **filelist 三處同步(CLAUDE.md §4.3):加/改 RTL 要同步 `phase_20`+`phase_22` Makefile 的 NPU_SRCS/CPU_SRCS**——曾漏
  npu_ml_ctrl/fexu 致 RVV/F lockstep gate 靜默壞掉(gate 8 秒快速失敗=build MODMISSING 非 lockstep 發散)。
- **DC/Presto 要 declaration-before-use**(Verilator 2-pass 容忍 forward-ref);修法=純宣告重排(RHS byte-for-byte)。
  DC `-parameters` 改設計名 → `current_design [lindex [get_designs npu_top*] 0]`。lib=`flow/dc_tsmc28/lib_setup.tcl`。
- **`pkill -f <pat>` 會殺自身 shell**(命令列含 pat)→ 改 `kill <pid>` 或 `pgrep -x`;判活看 `ps -o etimes,time`。
- signed `>>>` 在 unsigned ternary context 變邏輯移 → 用自決定 signed 中間 wire;signed*unsigned 用 `$signed({1'b0,b})`。
- masked body op 寫 v0 = illegal(每新 RVV op 加進 q_illegal 檢查);Spike 實跑 > 第三方 spec flag(legality 必 probe)。
- **co-work(§5):Grok 架構 review(`grok -p`,加「Do NOT use tools」)+ Codex 外科實作/RTL-reality review(`codex exec -s workspace-write`,
  需 `</dev/null`;其 sandbox DC license 常壞→DC 我自跑)。Claude 跑權威 lockstep/gate + green-wash 守衛。每 phase 走 §2 鐵律。**
