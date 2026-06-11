# CLAUDE.md — `SOC/Magpie_M1` CPU IP 開發線

> 本檔是 **Magpie_M1** 子專案的 charter + 新 session 上手指南。
> 讀完這份,你應該知道:**這專案要做什麼、照哪條 flow 走、有哪些工具/技能、規則是什麼、現在在哪一步**。
> 上層大戰略見 [`~/project/CLAUDE.md`](../../CLAUDE.md);IP-flow 方案見 [`~/project/doc/ip_flow_plan_of_record.md`](../../doc/ip_flow_plan_of_record.md)(PoR)。

---

## §0 這是什麼 / North Star

**Magpie_M1 = 一顆從零開始的 CPU IP**,用 **IP-first** 的方式開發,目的是**把 AI Design IDE 的「CPU IP 開發 flow」走通並補強**。

要記住的大前提(來自上層大戰略):**產品是「可移交的 AI 設計 flow + IDE」,不是某顆晶片。** Magpie_X6(RV64 SoC)是上一個驗證載體,我們從它**實際跑過的 gate 萃取出三條 IP flow**(CPU / BUS / Peripheral)。**Magpie_M1 是 CPU flow 的「greenfield 範例」**——用一顆乾淨、從頭走完整 CPU flow 的 IP,證明這條 flow 可被新計畫照抄,並反過來補強 IDE / platform 對 IP 開發的支援。

衡量成功:**M1 的 CPU IP 沿 ADR/spec 推導出的 development gates 逐關綠燈(對 Spike per-commit lockstep 過),且整段過程在 AI Design IDE 裡可 review;同時把走的過程中發現的缺口回灌成 platform/IDE 能力。**

> ⚠️ **第一個動作不是寫 RTL,是開 ADR 決定 ISA scope + 微架構**(見 §8、`docs/adr/0001-isa-scope.md`)。本檔刻意不替你決定 ISA;那是新 session 要重新討論的事。

---

## §1 必讀 / 與平台、X6 的關係

| 文件 | 為什麼讀 |
|---|---|
| [`~/project/CLAUDE.md`](../../CLAUDE.md) | 大戰略、治理規則、子專案地圖、引擎陣營 |
| [`~/project/doc/ip_flow_plan_of_record.md`](../../doc/ip_flow_plan_of_record.md) | **IP-flow PoR**:三條 flow 定義、ip.json schema、ipcat、IDE IP Catalog、status taxonomy、執行順序 |
| `~/project/platform/flow/ip_flows.json` | **CPU flow 的機器可讀定義**(Phase A Step 1 產出;若尚未存在,先建它——見 PoR §2) |
| `SOC/Magpie_X6/docs/adr/` | 前一條線的 CPU 決策(X1 核重用、fetch-redirect 修正…)——可合法參考,需記錄 provenance/license 與 M1 自身驗證證據 |
| `SOC/Magpie_X6/tests/gates/` | CPU flow 各 stage 的**真實 gate 範例**(gate_06_fetch / 07_exec / 08_cpu / 09_isa / 10_irq / 12_13_riscvdv …);M1 的 gate 仿其結構但獨立撰寫 |

**M1 vs X6**:X6 是 metadata-first 漸進改造(不搬 RTL);**M1 是 greenfield,可以一開始就用 IP-native 結構**(`IP/cpu_m1/` 內含 rtl/dv/docs),當作 IP flow 的乾淨示範。

---

## §2 CPU IP 開發 flow(★ 要照走的主軸,萃取自 X6)

這裡的 **stage 是 development stage / phase gate**,不是 pipeline stage。依序執行,每個 development stage 一個 `tests/gates/gate_NN_*.py`,前一關綠才進下一關。實際 gate list 由 ADR-0002 的 active ISA scope 與微架構推導;active target=`RV32IMC_Zicsr_Zifencei` + Ch2 lab08e 4-stage pipeline。`design_id = cpu_m1` 貫穿所有 artifact。

| # | stage | 要做什麼 | gate(本專案要寫)| 用的 skill / lib |
|---|---|---|---|---|
| 0 | **isa_scope** | 定義支援的 ISA + 架構契約(寫 `IP/cpu_m1/docs/spec.md` + ADR-0002);active=`RV32IMC_Zicsr_Zifencei` | gate_00_spec(doc/metadata 檢查)| — |
| 1.0 | **pipeline_reference** | 把 Ch2 lab08e RTL 落地為 IP target:provenance + filelist + ip.json variant metadata + Verilator lint-only | gate_10_pipeline_v2_reference | `sim`(lint-only)|
| 1.1 | **fetch_rv32c_prefetch** | 取指 + RV32C decompress + cross-boundary pre-fetch residue buffer(PC +2/+4、0-cycle assemble / fallback)| gate_01_01_fetch_rv32c_prefetch | `sim` |
| 1.2 | **decode_execute_rv32imc** | RV32I/M decode + ALU + mul/div + regfile(x0 invariant)| gate_01_02_decode_execute_rv32imc | `sim` |
| 1.3 | **pipeline_hazard** | forwarding / load-use stall / mul-div busy stall / flush 優先序 / wrong-path 抑制 | gate_01_03_pipeline_hazard | `sim` + `wave` |
| 1.4 | **bp_ras_redirect** | branch predictor 更新 + RAS return predict/recovery + mispredict redirect | gate_01_04_bp_ras_redirect | `sim` + `wave` |
| 1.99 | **phase1_closure** | 關閉 Phase 1 structural bring-up；把 directed/coverage/Spike residuals 轉交後續 phase | gate_01_99_phase1_closure | `pytest` |
| 2.0 | **trap_interrupt** | Zicsr + M-mode trap(illegal / ecall / ebreak / mret)+ IRQ timing + 16-bit instr mepc | gate_02_00_trap_interrupt | `sim` |
| 2.1 | **mem_wrapper** | imem/dmem 固定延遲 → `valid/ready` wrapper;load/store byte lane / sign-zero ext / misalign policy | gate_02_01_mem_wrapper | `sim` |
| 3.0 | **spike_lockstep** | **對 Spike per-commit 等效**(RV32IMC 隨機程式 + golden trace)| gate_03_00_spike_lockstep | `spike_ref` + `riscv_rand`(platform/lib)|
| 4.0 | **coverage** | line(100% 或逐行 waiver)+ toggle + functional coverage | gate_04_00_coverage | `sim(coverage=True)` |
| 5.0 | **lint_synth_ppa_signoff** | Spyglass lint(+ DC synth / PPA handoff)| gate_05_00_lint / gate_05_01_synth_ppa | `spyglass-lint` / `dc-synth`(licensed,**OUTSIDE-SANDBOX**)|

> Stage 表由 `IP/cpu_m1/ip.json` 的 `gate_map` 推導,phase 採階層式編號(例如 1.1/1.2),gate 檔名也採 `gate_01_02_*` 形式避免誤讀成第 12 個大階段。ISA scope 或微架構改變(如導入 A、或改 pipeline 深度)時,先改 ADR + ip.json gate_map,本表隨之重生。
> lab08e 是**第一方內部 RTL**,已 FPGA 85 MHz formal PASS,但**從未對 Spike 做 ISS 等效**——`copy + lint-only ≠ qualified`(見 `docs/v2_pipeline_full_verification_report.md`)。第一個真正 RTL 工是 **stage 8 mem_wrapper(固定延遲→valid-ready)+ expose commit-trace**,接著 **stage 9 spike_lockstep**(真 bug 最可能在此冒)。

**正確性權威 = cosim 等效(對 Spike)+ pytest gate**,不是 `cargo test`、不是「看起來會跑」。`spike_lockstep` 是 CPU IP 的核心驗證關。

---

## §3 治理規則(承上層大戰略,不可協商)

1. **Reference policy / License-compliant reuse**(承上層 ADR `~/project/docs/adr/0001-license-compliant-reuse.md`):RISC-V spec 是架構契約。第三方碼經 **SPDX/license review** 後可重用——**permissive(Apache-2.0 / BSD / MIT / Solderpad SHL)可納入商用 IP**,須保留 license header + 著作權、標 `// Modified by Magpie`、彙整 `THIRD_PARTY_NOTICES`、**開 ADR**(repo/SHA/檔/license/範圍/驗證)、provenance 入 `ip.json`;**copyleft(GPL/AGPL、未隔離 MPL/LGPL)不抄進 RTL 交付物**(QEMU=GPL 僅外部 sim)。reference 設計(`~/project/RISC-V/reference/` 的 Rocket/ibex/CVA6=Apache/Solderpad)可觀察+借用;每模組標 origin。正確性權威仍是 **M1 自身 Spike lockstep + gate**。
2. **ADR for any deviation**:任何架構決策/偏離寫 `docs/adr/NNNN-title.md`(MADR 格式)。借來的想法也要 ADR。
3. **Phase gate**:每 stage 有 `tests/gates/gate_NN_*.py`,前一 gate 未綠不進下一步。
4. **Licensed-EDA sandbox 政策**:`vcs/vlogan/dc_shell/pt_shell/spyglass/jaspergold/formality…` **不在 Codex sandbox 內跑**;規劃時標 `OUTSIDE-SANDBOX`,交主機 / 使用者執行。OSS(`verilator/iverilog/yosys`)不在此限。
5. **code-first / token-economy**:機械可重複工序(跑工具、解 log、抽 metric、評 gate、寫 state、查 graph、組 report)一律 Python(`platform/lib/` + skill `scripts/`);**LLM 只在真正需要推理時出場**(架構/RTL/新失敗 debug)。跑通一次即碼化。
6. **transparency / 自動報告**:gate 跑完用 `platform/lib/pipeline.record_step` 寫 MCP state + action log;`pipeline.build_report` 產 HTML 報告。重複性報告 code 產、不每次 LLM 重寫。
7. **製程目標**:數位 sign-off 主目標 = TSMC 28HPC+。
8. **Layer 1 誠實**:design-graph / cpu-graph 結果是線索不是事實;查 `data_quality` / `parser_tier` / `warnings`,永不變成 CI gate 斷言。

---

## §4 目錄結構(IP-native)

```
SOC/Magpie_M1/
├── CLAUDE.md                 ← 本檔
├── IP/
│   └── cpu_m1/               ★ 這顆 CPU IP
│       ├── ip.json           IP manifest(PoR schema;kind=cpu, flow=cpu, design_id=cpu_m1)
│       ├── rtl/              CPU IP 的 RTL(從 stage 2 起長出來)
│       ├── dv/
│       │   ├── tb/           testbench + 記憶體模型 + cosim harness
│       │   └── sim/          filelist(.f);可由 ipcat 從 ip.json 生成
│       └── docs/             IP spec(spec.md)+ 微架構筆記
├── docs/
│   ├── adr/                  專案 ADR(0001 = ISA scope 決策,先開這個)
│   └── spec/                 介面/ISA scope spec
├── tests/gates/             gate_NN_*.py(對應 ADR/spec 推導出的 development stages)
├── flow/
│   ├── sim/  lint/          gate 跑出來的 build/log/coverage
│   └── state/               MCP state(*.state.json)+ actions.jsonl ← IDE 靠它發現本設計
└── dv/fixtures/             committed 測試程式 / hex(可重現、無 toolchain 依賴)
```

**設計 id = `magpie_m1`**(gate 的 `pipeline.record_step(state, "magpie_m1", stage, gate, …)`)。一旦 `flow/state/*.state.json` 存在,**AI Design IDE 的專案選單就會列出 magpie_m1**(IDE 掃 `**/flow/state/*.state.json` 發現設計)。

---

## §5 工具與技能(你手上有什麼)

### Layer 1 context provider(查結構,別盲讀)
- **design-graph**(全域註冊):`designgraph_status` 看狀態;`missing` → `designgraph_rebuild(root=<M1 路徑>)`。RTL 長出來後用它查 module/port/instance/hierarchy。探索問題經 **Explore agent**,別在主 session 跑大型 explore 工具。
- **cpu-graph**(CPU 語意層):若已註冊,用 `cpu_graph_isa_coverage(target=spec_only)` 看 ISA 缺口、`cpu_graph_instr_semantics(mnemonic=…)` 取 spec ground-truth、`cpu_graph_decoder_diff(… vs spec_only)` 查 spec 合規。可作合法參考,但需保留 provenance/license 與 M1 自身驗證證據。

### platform/lib(code-first 原語,直接 import)
`pipeline`(record_step / build_report)· `sim`(Verilator lint/run,支援 `trace=True` 出 VCD、`coverage=True`)· `state`(MCP state_node)· `parsers`(log→metrics)· `spike_ref`(Spike golden trace)· `riscv_rand`(隨機程式產生)· `review`(RTL review)· `wave`(VCD→events/WaveDrom + cosim lockstep)· `rtlstruct`(模組階層)· `report` · `journal` · `ipcat`(IP catalog,PoR Phase A 產出)。

gate 取 platform/lib 的慣例(照 X6):
```python
def platform_lib(start):
    d = start
    for _ in range(8):
        c = os.path.join(d, "platform", "lib")
        if os.path.isfile(os.path.join(c, "pipeline.py")): return c
        d = os.path.dirname(d)
    raise RuntimeError("platform/lib not found")
```

### platform/skills(一鍵工序)
`regression`(Verilator/VCS + Spike lockstep)· `spyglass-lint`(licensed)· `dc-synth`(licensed)· `rtl-review` · `wave-review`。後段 cosim/coverage/lint-synth gates 直接用。

### AI Design IDE(展示 + review)
```sh
python3 ~/project/platform/design-ide/server.py --port 8810 --bind 127.0.0.1   # 開 http://127.0.0.1:8810/ide
```
分頁:**Code review**(行內 finding)· **Schematic**(可導航 block diagram)· **Waveform**(選 VCD,GTKWave 式)· **Gates**(gate 矩陣,點 .py/log)· **Report/Docs**(reports/ADR/slice/plan 選單)。左欄 **Modules**(Filter)+ RTL files + **專案選單**(會列出 magpie_m1)。**IP Catalog** 分頁(PoR Phase A 待建)會讀 `ip.json` 顯示 M1 在 flow 上走到哪一 stage。

---

## §5.5 co-work 分工(四方:Claude / Codex / Grok / Gemini)

> **最新模式 2026-06-08(取代以下舊版),經本輪 J1–J15 實測 + 各自武器定位。**
> 四方按「武器」分工,Claude 是唯一 commit 者與驗收之記(integrity backbone)。

| 角色 | 工具 | 武器 / 為什麼是它 | 實測注意 |
|---|---|---|---|
| **整合者 / Tech Lead / 唯一 committer** | **Claude Code(我)** | MCP(design-graph/cpu-graph)、memory、repo 狀態、clean-room、多步 agentic 編排與謹慎編輯;**逐波獨立驗收(sha/gate/lockstep)、把關誠實界** | 本輪靠此擋下多次 green-wash/scope 縮水(c.lui 手算、拒收 J14 破狀態) |
| **Bug 獵手 / Reviewer / 單模組實作** | **Codex**(gpt-5.5 重活 / `gpt-5.3-codex-spark` 收斂活) | 外科手術式精準找 bug + 修單模組(本輪抓修 ~6 真 DUT bug + 自修 Spike harness) | ⚠️ 會「為了過而**縮 scope / 留爛攤**」(J11 arith-only、J14 留 16 fail)→ **PL 必查 scope+完整性+不放水** |
| **DV 架構師 / Roadmap / Spec 對照** | **Grok**(`/home/edauser/.local/bin/grok`,`grok -p`) | 脈絡整合 + ADR/設計史納入判斷 + web search;適合寫 DV test plan、規劃驗證策略、查最新工具/ISA | 🆕 **尚未實測**,先在規劃類任務試水(如剩餘 DV roadmap)再信任 |
| **Corpus 容器 / 長文件 & log 分析** | **Gemini**(`--yolo --skip-trust`) | **~1M 超大上下文**:一次吞整包 RTL + 完整 RISC-V spec(Unpriv+Priv)+ 全 ADR + 長 log/coverage。產 context pack 餵其他三人 **省 token** | **別降格成文書**:可做需全上下文的真驗證(整本 Priv-spec 對 csr.v/trap 逐條 compliance、跨 26 檔全域一致性 naming/reset/X-prop)——這類只有它做得到 |

**運作流(RV64 等後續沿用)**:Gemini 吞 spec+全 RTL+docs → context pack/compliance 矩陣/log 摘要 → 餵 Grok(規劃)+ Codex(找 bug/實作)+ Claude(編排/寫/commit)。真相層 = design-graph/cpu-graph + git(單一 source of truth)。

**決策流(User 裁示 2026-06-08)**:Claude 面對非瑣碎決策時,**先徵詢 Grok 意見(`grok -p`,需加「Do NOT use tools」否則 headless 報錯),再由 Claude 整合成最佳決策並負責**(Claude 仍是唯一 committer + 驗收之記;producer≠approver 不變)。Grok 意見背景跑、不 block 全隊。動機:本輪 Grok 多次抓到 Claude 漏的真問題(nested-trap=handler 產物之正確重判、對抗審查抓出 write_tohost 截斷的 masking 風險 + overclaim)。

**負載平衡(2026-06-08)**:避免「3 個等 1 個 Codex」——每 agent 常備獨立佇列(Grok/Gemini 永遠有不依賴當前 Codex job 的工作),並行化 Codex(不互踩的不同檔同時跑)與真瓶頸 riscv-dv gen/sim(平行生成+sim),Claude 事件驅動整合、唯一序列點=commit。

**護欄不變**:producer≠approver(Claude 驗收)、report-faithfully(不假造/不放水/scope 誠實)、每 run provenance、授權 EDA 經 Codex 必 `-s danger-full-access`、Layer-1 誠實、權威=Spike lockstep+pytest。**Token 紀律**:大 bytes 交 Gemini 濃縮再進 Claude。

**守則:決策必附 agent 優先序(User 裁示 2026-06-11)**:每次向 User 徵詢決策(AskUserQuestion 或「下一步做哪個」),**一律先諮詢 agents(Grok 為主,必要時 Codex/Gemini)對「計畫上最優先/最佳的順序」之意見,整合成一個排序清單呈現**,再讓 User 選。即:不要只丟選項,要附上「agents 建議的優先排序 + 理由」。承 [[grok-standing-decision-advisor]] 決策流;Grok 意見背景跑、不 block。

**守則:agent 執行心跳 + 中文重點(User 裁示 2026-06-11)**:
- **5-min 進度心跳**:任何背景 agent / 長 job(Codex/Gemini/Grok、Verilator/Spike/DC、riscv-dv farm…)執行中,**Claude 每 ≤5 分鐘給一次進度提示**(還在跑/已完成/卡住),不可放著不管。**判活看 CPU time 不是只看輸出大小**(`ps -o etimes,time` — elapsed 走但 CPU=0 = 卡死,如本輪 Codex 兩度卡在 `Reading additional input from stdin`)。背景啟 agent 一律 `< /dev/null` 餵空 stdin,避免 headless 卡讀。job 死了要**立刻發現並換手或重起**,不空等。
- **重點用中文**:給 User 的關鍵結論 / 決策 / 風險 / 進度,**用中文描述**(技術術語、檔名、指令、code 保留原文)。

---

### (舊版存查)§5.5 簡化版 Claude / Codex / Gemini

> 決策日 2026-06-08(User 裁示,**簡化版**,取代先前 Claude=orchestrator 的版本)。
> 動機:先前讓 Codex 當 producer 跑 RTL 太重(spark 背景跑 mem_wrapper 收斂慢、互踩),改回 **Claude 親自執行**為主軸。

| 角色 | 定位 | 做 | 不做 |
|---|---|---|---|
| **Claude Code** | **Executor / Architect**(主力) | 親自寫 RTL/tb/gate、跑 Verilator/Spike/build、開 ADR、`record_step`、最終整合與判定 | — |
| **Codex** | **Independent reviewer**(只審) | read-only 審查 Claude 產出(RTL/gate/邏輯)、找 bug、寫 findings;承 platform-0002 separation-of-duties | 不產 RTL、不改檔、不自審自發 IDE 報告(producer≠approver) |
| **Gemini** | **基本資料處理 / shell 執行** | 跑指定 shell 指令並回報結果、解析/濃縮大 log → 小表、breadth 枚舉(uncovered-line / address grid) | 不下架構決策、不判 gate |

**Token 紀律(仍然要,2026-06-08 User 加強)**:大 bytes(raw log / URG dump / Codex review / J*_result 全文 / divergence trace)交給 **Gemini 濃縮成 ~10 行小表/決策摘要**再進 Claude;**Claude 不直讀巨檔**。驗收 Codex 成果的標準 loop:Codex 修 → **Gemini 讀 result+log+divergence 出濃縮 PL 決策摘要(matched 數/下一個 divergence/有無回歸/red flag)** → Claude 只讀摘要 + 跑 `pytest -q`(看 pass 數)+ 裁決。實證:Codex review 534KB → Gemini 2.7KB(↓~99.5%)。

**headless 調用**:
- Codex 審查:`codex exec -m gpt-5.5 -s read-only -c approval_policy=never "<review prompt>" > review.log`(深度審查不省 model);全輸出落檔,只讀濃縮 findings。
- Gemini:`gemini --yolo --skip-trust -p "<prompt>"`(`--yolo` 才會自動寫檔,否則卡 plan-mode;`--skip-trust` 過信任目錄)。
- **授權 EDA(VCS/Spyglass/DC…)經 Codex 跑,必須 `-s danger-full-access`,不可用 `-s workspace-write`**:後者的 sandbox 會 `--unshare-net` 隔離網路 → 連不到 license server → license wait/fail(假象像「license 競用」)。OSS(verilator/spike)兩者皆可。承 platform ADR-0009「授權 EDA 免 sandbox」。
- 每次把 `tokens used` 記進 run provenance。

**護欄(承上層,不可協商)**:① producer≠approver(platform-0007:Claude 產→Codex 審,Claude 不自審自發 IDE 報告);② report-faithfully(沒實跑=`waived/unavailable`,永不假造);③ 每 run 記 provenance(tool/host/command+log/state/actions);④ Layer-1 誠實:findings=線索不是事實,**永不變 gate 斷言**;⑤ 正確性權威仍是 **Spike lockstep + pytest gate**。

---

## §6 引擎陣營
| 用途 | 引擎 | sandbox? |
|---|---|---|
| 模擬 / 波形 | **Verilator**(OSS,cosim/smoke/coverage)· VCS+URG(signoff)| Verilator OK / VCS OUTSIDE |
| golden / lockstep | **Spike**(`platform/lib/spike_ref`)| OK |
| lint / CDC | **Spyglass** | OUTSIDE |
| 合成 | **DC** | OUTSIDE |
| STA | PrimeTime | OUTSIDE |

---

## §7 Session 啟動 checklist
0. `python3 ~/project/platform/lib/journal.py recap`(省 context,看問過/決過什麼);關鍵決策順手 `journal.py add`。
1. 讀本檔 §2(flow)+ §8(現況)。
2. 要探索 codebase:design-graph(經 Explore agent),別盲讀。
3. 動 RTL/架構:reference policy + ADR + phase gate。
4. licensed EDA 步驟標 `OUTSIDE-SANDBOX`,別在 sandbox 跑。
5. gate 跑完:`pipeline.record_step` 寫 state + `build_report`;確認 IDE 能看到 magpie_m1。

---

## §8 現況 / 下一步(2026-06-08 更新)

**TL;DR(2026-06-08,PL 主導 Codex/Gemini 推進)**:flow **0→5.0 全綠**——mem_wrapper(Spike 等效,ADR-0005)、misalign(mcause 4/6)、重跑式 lockstep gate(gate_03_08,補 cached-log 漏洞)、**functional coverage 100%(72/72,gate_04_08)**、**Spyglass lint PASS**(0 error)、**DC synth/PPA trial**(~699MHz / 26298µm² / 15.85mW,TSMC28HPC+)。**176 gates pass,零假造**。

> **⚠️ 下一個 work item(最高優先,新 session 接手)= `BUG-XBOUND-0001`**:riscv-dv 大規模 lockstep(J8)在 commit 5 對 Spike 發散——壓縮指令把對齊推成奇半字後,**連續 cross-boundary 32-bit 取指組裝錯**(`addi@0x0e` 被誤判 illegal)。真 RTL bug,**非 harness**。完整交接 + repro + 修法計畫見 [`docs/reports/bug_xbound_0001/findings.md`](docs/reports/bug_xbound_0001/findings.md)。修法為 delicate cross-boundary RTL(ifu/core,**不交 Spark**),clean-room + ADR + 重驗(176 gates + lockstep + coverage 須不回歸),修好後 resume J8 衝 ≥100k commits。
>
> 其餘殘留(roadmap,非阻擋功能):多 corner synth(ss/ff)、2 條 hold violator(APR)、PPA vectorless power。
>
> **Co-work 運作**(本輪驗證):Claude=PL/judge(逐波獨立驗收 sha/gate/lockstep)、Codex 執行(gpt-5.5 較重整合 / `gpt-5.3-codex-spark` 收斂任務,品質見 [[journal]])、Gemini 文件。**授權 EDA 經 Codex 必須 `-s danger-full-access`(見 §5.5)**。

---

**(以下為較早 2026-06-07 背景)狀態**:採用 Option 1 修正版。ADR-0001 已 superseded-for-implementation；ADR-0002 已 accepted 並將 Ch2 `lab08e` 升為 active implementation baseline。`gate_00_spec` 已通過並寫入 `flow/state/magpie_m1.isa_scope.state.json`。目標是把 4-stage + BP + RAS + RV32C + pre-fetch 從 lab 變成實用 IP,但尚未 qualified。

**第一步(新 session 重新討論的主題)= flow stage 1「isa_scope」**:
1. **以 `docs/adr/0002-pipeline-v2-ch2-integration.md` 為 active scope**。ADR-0001 只保留歷史 FSM 決策。
2. 填 `IP/cpu_m1/docs/spec.md`(ISA scope + 介面契約)。
3. 寫 `tests/gates/gate_00_spec.py`(doc/spec 存在性 + 基本檢查),record_step(stage 起點)→ 讓 magpie_m1 出現在 IDE。
4. 之後照 ADR/spec 推導出的 development gates:lab08e reference → fetch/RV32C/pre-fetch → decode_execute_RV32IMC → pipeline_hazard → BP/RAS/redirect → trap/IRQ → mem_wrapper → **spike_lockstep** → coverage → lint/synth/PPA。
5. lab08e 已整合到 `IP/cpu_m1/rtl`;這是 active productization target,但尚未 qualified。qualification 必須補 valid-ready wrapper、RV32C/pre-fetch/RAS/BP/pipeline directed tests、Spike lockstep、coverage、lint/PPA gates。

**平台側並行(可選,補強 IP flow)**:PoR Phase A —— `platform/flow/ip_flows.json`、`ipcat.py`、IDE **IP Catalog** 分頁。M1 是它的第一個 greenfield 消費者。

---

## §9 誠實界 / status taxonomy
- stage 狀態用:`pass / fail / waived / partial / not-run / not-applicable / risk / unknown`(顏色見 PoR §6)。
- 未跑的 stage = `not-run`,不假裝綠;scope 外的功能(如無中斷)= `not-applicable`,不算 fail。
- cosim 未過 = `fail` 或 `risk`,**據實**;cpu_m1 在 `spike_lockstep` gate 前不可宣稱「verified」。
- 所有 CPU/VCD/dashboard artifact 帶 `design_id=cpu_m1`,與 X6 的 cpu_seq/cpu_x1 證據永不混。
