---
status: proposed
date: 2026-07-06
governs: Full-circuit functional verification + instruction/code/functional coverage signoff (VCS/Verilator/Spyglass/Spike)
authority: Spike lockstep + bit-accurate golden + scoreboard = CORRECTNESS; coverage = COMPLETENESS evidence only
---

# ADR-0063 — 全電路功能驗證 + coverage 簽核(專案 roadmap)

User 裁示:硬體支援分析告一段落,轉入「把整個電路做功能驗證 + VCS/Verilator/Spyglass/
Spike 指令與 code coverage」。本 ADR = 專案章程(phasing / DUT / 方法 / gate / green-wash
守衛)。DV 架構全文 `docs/reviews/2026-07-06_dv_coverage_plan_grok.md`(§5 Grok DV 角色)。

## §0 鐵律:coverage ≠ correctness
**Spike lockstep / bit-accurate golden / scoreboard = 正確性權威**(不變)。**coverage(指令/
行/功能)= 「有沒有看遍」的完整度證據,不是「對不對」的判準。** 每個 coverage-closing 測試
仍必自檢(lockstep/scoreboard);coverage% 永不取代 lockstep(green-wash 守衛 G1)。

## §1 工具矩陣(已實測可用)
| 工具 | 版本 | 角色 | sandbox |
|---|---|---|---|
| **Verilator** | 5.046 | line+toggle+expr coverage · CI 快速迭代 | **in-sandbox** |
| **Spike** | — | ISA golden(lockstep)· `--log-commits` 指令覆蓋來源 | in-sandbox |
| **VCS** | X-2025.06-SP1 | line/cond/branch/tgl/**fsm** + **SV covergroups** · 簽核權威 · urg 合併 | **OUTSIDE-SANDBOX**(`_eda_cwd_guard`,Codex danger-full-access 或 user 跑)|
| **Spyglass** | X-2025.06-SP1 | lint / **RDC** / x-prop(CDC 極小=單一 clock)| OUTSIDE-SANDBOX |
| urg / verdi | X-2025.06 | UCDB 合併 / debug | OUTSIDE-SANDBOX |

## §2 分層 DUT(全電路 = 分層,不只單元)
| Tier | DUT | 內容 | 簽核 |
|---|---|---|---|
| **T0** | `cpu_m1_top`(host 組態)| scalar RV32IMC+Zba/Zbb/Zbs+Zicond,host 路徑 | 必 |
| **T1** | `npu_top`(NPU 組態)| **RVV Zve32x + scalar-F + mat_engine + npu_dma + CQ + npu_tcm + trap** | 必 |
| **T2** | **`soc_m3v_top`(整合)** | host `--AXI-->` NPU + fabric + shared-mem + IRQ aggregator | **全電路必需** |
| T3 | 子區塊深 FSM | 針對性 FSM 收斂(整合 sim 慢時)| nice-to-have |
> **T2 現況待查:是否已有 host+NPU 單一整合 top?**(見 `cpu_m1_soc_top` host-SoC + `tb_npu_top`
> NPU-integration TB;整合兩核的 `soc_m3v_top` 可能需建 —— V3b 首要交付)。**不得只用 block-level
> DUT 宣稱 full-circuit coverage。**

**需顯式 state+transition 覆蓋的 FSM**:vexu `VM_GRP/VMVR/VM_SEGWR`(群組/segment/LMUL body/
vstart)· mat_engine `S_*`(CFG→LOAD→RUN→RSC→STORE→FIN + ADR-0053 pipe)· npu_dma(AR/R/AW/W/B
+ SLVERR abort + 2D/strided)· CQ sequencer(ring consume/doorbell/FULL/ERR/batch-prefetch)·
npu_axil_regs(CTRL.start/soft_reset/DONE/ERR_CAUSE + ADR-0047 hard-reset)· npu_tcm arbiter
(core vs DMA vs AXI-lite)。

## §3 Phasing(V0→V8)
| 相 | 名稱 | 交付 | 依賴 | 平行 |
|---|---|---|---|---|
| **V0** | 基建 | coverage SSOT(`isa_coverage.yaml`/`isa_exclusions.yaml`)· spike-log ingester · merge 腳本 · waiver DB | — | — |
| **V1** | **指令覆蓋** | 從既有 spike.log(phase_20/21/22/23 + gates)建 ISA tracker · per-ext mnemonic 報告 · exclusion ledger | V0 | V2 |
| **V2** | **Spyglass 靜態** | lint clean(擴 ADR-0006 契約到 npu/RVV/mat)· **RDC**(domain_rstn/ADR-0047)· x-prop · CDC 確認單 clock | V0 | V1/V3 |
| **V3a** | block 功能 | 全 ~125 gates + 4 lockstep harness 綠 = 正確性地板 | V0 | V1/V2 |
| **V3b** | **整合 top 功能** | 建/確認 `soc_m3v_top` + directed/random 跨域 lockstep(fabric/doorbell/IRQ/Harvard 載入競態)| V3a | — |
| **V4** | **功能覆蓋(VCS)** | SV covergroups + cross bins(§5)· UCDB/suite | V3b | V5 |
| **V5** | code cov · Verilator | line+toggle+expr · nightly merge · gap triage | V3a | V4/V6 |
| **V6** | code cov · VCS 簽核 | line/cond/branch/tgl/fsm · urg · waiver 簽核 | V3b+V4 | V5 |
| **V7** | 雙 sim 一致 | VCS↔Verilator line-hit 一致(Jaccard ≥98%)· 分歧 triage | V5+V6 | — |
| **V8** | 簽核包 | ADR + gate 證據 · raw/effective/waived · known-gaps doc | V1–V7 | — |

**推薦序**:V0 →(V1 指令覆蓋[便宜,吃既有 spike.log] ∥ V2 Spyglass[獨立] ∥ V3a[正確性地板])
→ V3b 整合 top → (V4 covergroups ∥ V5 Verilator cov) → V6 VCS 簽核 → V7 雙 sim → V8。

## §4 指令覆蓋(V1)方法 + 誠實 exclusion
- **來源 = Spike `--log-commits`**(非 DUT disasm;Spike 本就是 lockstep golden)。
- **SSOT `flow/coverage/isa_coverage.yaml`**:ext(i/m/f/zba/zbb/zbs/zicond/zicsr/zve32x/zvl128b)×
  mnemonic × status。**parser `platform/lib/isa_cov.py`** 吃 commit log → 正規化 → 按 opcode/funct
  分桶 → per-ext %。
- **exclusion ledger `isa_exclusions.yaml`**(三桶,誠實界):
  | 桶 | 對 % 處理 | 例 |
  |---|---|---|
  | `excluded-scope-cut` | **移出分母** | strided/indexed/ff mem、vrgatherei16、masked-reduction |
  | `excluded-illegal-npu` | 移出分母 | C 擴充在 NPU(EN_RVC=0)|
  | `uncovered-in-scope` | **計入未覆蓋** | 其餘未打到 |
  - exclusion 必引 ADR 段;ledger 縮水無新覆蓋 → gate fail(G6)。**打到 scope-cut op 只給 warning
    不給 credit**(G7,防 rogue firmware 假灌)。vill/illegal ladder 算 CSR 覆蓋非算術 op 覆蓋。

## §5 Code + Functional coverage
- **分工**:Verilator = line/toggle/expr,in-sandbox nightly(快速 gap 偵測);**VCS = line/cond/
  branch/tgl/fsm 簽核權威 + SV covergroups**(OUTSIDE-SANDBOX)。合併:`verilator_coverage`(OSS)/
  `urg` UCDB(VCS);**不裸合併兩引擎**,V7 出 delta 報告。
- **目標(effective,誠實)**:VCS line ≥95% · branch/cond ≥90% · **FSM 可達 state 100%** · transition
  ≥95%;Verilator CI line ≥90% · toggle ≥80%。waiver:靜態不可達(Spyglass UNR / formal)+ ADR
  waiver ID,每 block ≤2% line 預算。
- **功能 vplan(covergroup 家族,VCS 簽核;Verilator 側用 Python trace-based surrogate 做 CI 趨勢
  非簽核)**:`cg_rvv_op × sew × lmul × mask × vl-edge`(最高優先;scope-cut 打 IGNORE_BIN)· `cg_axi`
  (burst LEN 0/1/15 / SLVERR / DECERR / W-before-AW / core-DMA overlap)· `cg_mat`(cmd × requant-mode
  × tail)· `cg_cq`(ring empty/partial/full/wrap / ERR ladder / CQ-vs-CSR 等價)· `cg_trap`(ADR-0038
  ladder + abort/soft_reset)· `cg_csr`(host FS/VS/fcsr + NPU CTRL/STATUS/ERR/vector-CSR 窗)。

## §6 Green-wash 守衛(coverage campaign 專屬)
G1 coverage≠correctness(lockstep 綠才准 coverage gate)· G2 禁 toggle-only 測試(必自檢)·
G3 raw+effective 並列,簽核只認 effective · G4 waiver 必 ADR-ID+owner+review · G5 雙 sim 一致
(Jaccard≥98%)· G6 exclusion ledger 縮水即 fail · G7 打到 scope-cut op 不給 credit · G8 covergroup
必 sample DUT 階層非 TB · G9 Spike `--isa` 必對齊 lockstep · G10 `flow/state/cpu_m3v_coverage.json`
每相,缺=紅 · G11 覆蓋取全回歸 union 非單一 golden · G12 waiver 定期 Codex/Gemini 稽核。
**+ ADR-0006 既知風險**:`parse_spyglass` regex 曾把「error」誤當「errors」假綠——parse/condense
步驟是本線已知假綠面,V2 必用嚴格 pattern + 反向 self-test。

## §7 Gate band + ADR
- **gate band = `gate_90..98`**(V0..V8;與既有 gate_00..83 分開,避免撞號)。
- **ADR**:本 roadmap = ADR-0063;方法細節隨相落 sub-ADR(0064 ISA-cov 方法 / 0065 code-cov 簽核 /
  0066 vplan / 0067 green-wash+雙sim,開工時才寫,不預佔內容)。

## §8 現況 / 首步(V0+V1 便宜早收)
1. **V0**:`flow/coverage/{isa_coverage,isa_exclusions}.yaml` + `platform/lib/isa_cov.py`(spike-log
   ingester)。
2. **V1**:對 phase_20/21/22/23 + gates 既有 spike.log 跑 ingester → 首份 ISA gap 報告(零新 sim)。
3. **V2**(平行):Spyglass 用 M3V filelist 重跑 → lint/RDC 現況。
4. **V3b**:確認/建 `soc_m3v_top` 整合 DUT(全電路的先決條件)。
- **must-have 簽核**:lockstep+整合 top 綠 · ISA 100% in-scope + ledger 凍結 · VCS line≥95%/FSM
  可達 100% · covergroup(mat/CQ/AXI/trap)100% defined bins · RVV cross ≥90% in-scope · Spyglass
  lint/RDC clean · 雙 sim ≥98% · waiver <5%/block。
