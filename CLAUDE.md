# CLAUDE.md — `SOC/Magpie_M3V` · 自建 RV32 NPU（目標:功能取代 Google Coral NPU）

> ⭐ **本 repo = Magpie_M3V**。fork 自 `m1a-rtl-freeze-v1.0`(M1A @ 51a6fe0,完整歷史,remote=parent → `~/project/SOC/Magpie_M1A`);祖系 M1 @ 4e6e1d4。
> **design_id = `cpu_m3v` / `magpie_m3v`**(物理路徑沿用 `IP/cpu_m1/`;身分以 design_id 為準)。identity gate = `tests/gates/gate_00_identity_m3v.py`。
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
- **NPU domain(`IP/npu/`)**:`npu_top`(AXI4-Lite CSR@0x3000 / TCM@0x3001 / DECERR 解碼)、`npu_dma`(AXI4-full 突發)、`npu_tcm`、level IRQ。淨新 ML datapath(RVV Zve32x + GEMV/矩陣 + writeback DMA + command-queue)長在這裡。

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
- Phase 3 RVV ✅(3A-3D,kernel=240)→ Phase 4 矩陣 64-MAC+requant ✅ → **Phase 6 首戰 ✅(ADR-0039:TFLM int8 FC 六 corner bit-exact e2e,gate_48)** → **256 MAC/cycle ✅(ADR-0040,throughput gate 實測)** → **TFLM runtime AOT ✅(ADR-0041:真 .tflite 2 層 MLP 多 op 鏈接 bit-exact,gate_49)** → **CNN ✅(ADR-0042:Conv2D per-channel + K-chunking,gate_50)+ 卸載收尾 ✅(ADR-0043:2D/strided DMA + host producer ABI,gate_51)** → **列 4 記憶體 ✅(ADR-0044:ITCM 8K/DTCM 32K Harvard + banked DTCM,gate_52)** → **列 8 RVFI/RVVI-lite ✅(ADR-0045:lockstep 換源自 trace port 全符,gate_53;PARTIAL,v1=insn/mem/mtval)** → **功能補齊中(User 裁示:功能→架構優化→簽核)**:列 6 hard-reset ✅(ADR-0047,gate_54)→ 列 8 trace v1 ✅(ADR-0048:insn/mem/mtval/mstatus,列 8 GREEN-leaning)→ **RVV Phase-A 收齊 S1-S4 ✅(ADR-0049;POOL 對 TFLM bit-exact 含 half-away 引理,gate_56-59;列 2 GREEN-leaning)** → **scalar F 全套 ✅(ADR-0050 F1-F4:fexu softfloat-3 忠實轉寫 + fcsr/FS 契約 + F-reg lockstep;directed 135+269 + random ~5.5K commits vs Spike rv32imf;gate_60/61;列 1 GREEN,F4 組合邏輯=Phase 7 多拍化偏離已記)** → **功能補齊完成** → **架構優化(ADR-0051 DC 量測 / 0052 CQ batch / 0053 requant pipe:mat_engine ~730MHz→~1.0GHz)** → **完整 Zve32x 產品規格中(ADR-0054 roadmap;Phase-B B1✅ B2✅、B3 進行中)** → 續:npu_top 全 DC / VCS/Spyglass/coverage 簽核。**詳見 §7 重啟指南。**
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
3. **Phase gate**:每階段 `tests/gates/gate_*.py`,前關綠才進下一步。
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

- `IP/cpu_m1/`(host + NPU 參數化 spine)· `IP/npu/`(NPU domain RTL/dv/docs/sw)· `tests/gates/`(Verilator/lockstep gates)· `flow/v2_pipeline/phase_03_0*/`(可重跑 lockstep)· `flow/state/`(cpu_m3v 證據)。
- **關鍵文件**:`docs/adr/0031`(scope)· `0032`(cpu 參數化+驗證)· `docs/reviews/2026-07-03_multiagent_review.md`(架構 review)· `docs/reviews/2026-07-03_coral_gap_review.md`(**Coral 缺漏對照**)· `IP/npu/docs/00_isa_contract.md` / `01_axi_fabric_spec.md` · **`rv32_npu_design_plan_v4.html`(v0.2,設計報告參考,User 2026-07-03)**——含 **§06 Command 編碼 Spec v0.1**(128-bit descriptor + opcode 表 MAT.CFG/LOAD_W/OP/RESCALE/STORE/ACC_CLR/FENCE + MAC 陣列/acc/執行單元數量 + L1→L5 下降對照);**§06 是 CQ/矩陣的 SSOT 設計參考**(P0②③ 缺漏的設計基準,實作時 RTL 解碼器 + IREE codegen + NumPy golden 共用同一份)。`rv32_npu_design_plan.html`(v0.1)已 superseded。**注意**:設計報告的記憶體映射(0x4000/ITCM/DTCM)與 IREE-plugin/RVVI 為藍圖;**實作真值以本 repo RTL 為準**(NPU_CSR 0x3000 / TCM 0x3001;開源 clang-RVV)。· 參考 lab `~/project/lab/CPU/Ch5_NPU`(Coral de-blackbox)。
- **platform/lib**(直接 import):`pipeline`(record_step/build_report)· `sim`(Verilator)· `spike_ref`(golden)· `riscv_rand`· `wave`· `parsers`。gate 取 platform/lib 慣例照 X6/M1。

---

## §7 現況 / 下一步

> ⭐ **重啟指南(2026-07-05,session 極長後 checkpoint)**:詳細進度看 memory `m3v-progress.md`
> (每步都記);逐項 ADR 在 `docs/adr/`;三方 review 全文在 `docs/reviews/2026-07-05_*`。

**A. 功能面 = 完成(§3 對 Coral 8 列全 GREEN-leaning,紅燈 0)**。scalar F 全套(RV32IMF,ADR-0050)、
RVV Phase-A(S1-S4)、矩陣 256-MAC+requant、TFLM FC/MLP/CNN e2e bit-exact、卸載/記憶體/trap/trace 皆綠。
**功能補齊完成**。可替代性報告 `docs/reports/2026-07-03_replaceability_status.md`(row 1 GREEN)。

**B. 架構優化(進行中,User 裁示序:功能→優化→簽核)**:
- **step 0 mat_engine DC 量測 ✅(ADR-0051)**:真 Synopsys DC + TSMC28(`flow/dc_tsmc28/`,in-sandbox
  可跑,`common_shell_ex` 進程)。**推翻假設**:critical path 是 requant(非 MAC)。
- **step 2 CQ autonomous MAT_OP ✅(ADR-0052 @ec3ac1e)**:批次預取 descriptor(消軟體序列化稅);
  含 User 核准的 weight region 0x680→0x700 memory-map bump(footprint 撞牆)。
- **step 3 requant 流水化 ✅(ADR-0053 @f8403d4)**:2-stage pipe cut 在 32×32 乘後;**DC 證
  mat_engine ~730MHz→~1.0 GHz**,新 critical path = MAC(step 4 候選,standby)。
- 未做:step 1 npu_top 全 DC(需 TCM SRAM macro);step 4 S_RUN pipe(standby)。

**C. 完整 Zve32x(產品規格,User 裁示;roadmap ADR-0054)**:目標=可宣稱「任何 Coral Zve32x 程式
drop-in」(**不做 full RVV 1.0**——Coral 也只 Zve32x)。Phase-B(整數核心)→C(乘法/reduction)→
D(mask-scan/slides)→E(gather/compress/indexed/segment/vdiv)→F(m8)。
- **B1 ✅(bitwise/shift/vrsub,@6659e9d + fix @b7505ab)**、**B2 ✅(narrowing+extension,@568ff3b,三方 review)**。
- **B3(carry vadc/vsbc/vmadc/vmsbc)= 進行中**:Grok spec 已存 `docs/reviews/2026-07-05_phase_b3_carry_spec_grok.md`;
  vadc/vsbc 出 vector(carry-in=v0,強制 active)、vmadc/vmsbc 出 mask(照 compare res_cmp 路徑)。**下一步:照 spec 實作 → Spike lockstep `--isa=zve32x_zvl128b` → 三方 review → commit。**
- B4 whole-reg move(vmv1r/2r/4r/8r)待做。

**D. 待查 latent(誠實界)**:`vle32.v @ e32/mf2`(vlmax=2)DUT trap illegal——Grok/Gemini 判與 B2 無關的
vsetvli/vmem fractional-LMUL 議題,**可能真 bug,需與 Spike 並跑確認**。

**測試/工具重點**:vector lockstep = `flow/v2_pipeline/phase_22_vector_csr_lockstep`(`make b1/b2/grid/s1/vrand`;
firmware 用 **`-mno-relax`** 讓 DUT/Spike la 位址編碼一致;m2+ group-EMUL memory ops out-of-scope,用
vmv.v.x splat 建群組源、vmv.x.s 觀察)。**recurring bug:signed `>>>` 在 unsigned ternary context 變邏輯移**
——用自決定 signed 中間 wire。**masked body op 寫 v0 = illegal**(每新 op 都要加進 q_illegal 該檢查——B1/B2 各被 review 抓過)。
