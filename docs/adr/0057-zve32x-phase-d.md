---
status: accepted
date: 2026-07-05
supersedes: []
governs: Zve32x Phase-D (mask-scan + slides) — vexu.v / idu.v
authority: Spike --isa=rv32imf_zve32x_zvl128b lockstep (phase_22)
---

# ADR-0057 — Zve32x Phase-D 掩碼掃描 + 位移(架構確認 + 實作記錄)

Roadmap = ADR-0054 §3 Phase-D。承 Phase-A/B/C(整數算術 + 乘法/MAC/reduction/widening/
vsmul 全綠)。Phase-D 補 **mask population/scan + cross-lane slides** —— 通用 RVV kernel
(compaction/argmax/sliding-window)需要的最後一塊非-permutation 功能。

## §1 Coral 對照
Coral 的 RVV 軟體路徑對 mask-scan(vcpop/vfirst/viota)+ slides(vslide)有需求(sparse /
sliding-window / normalization)。補齊後 vexu 對「開源 RVV kernel drop-in」再進一步。

## §2 子片(Grok 架構確認 2026-07-05,全文 docs/reviews/2026-07-05_phase_d_plan_grok.md)
順序 **D1a(vid)→ D1b(vcpop/vfirst)→ D2a(slide1)→ D1c(vmsbf/vmsof/vmsif)→ D1d(viota)
→ D2b(slideup/down)**。實作合併為:D1a(vid+vcpop+vfirst)、D1b(vms*+viota)、D2a(slide1)、
D2b(slideup/down)。

## §3 契約 / 驗證
權威 golden = Spike lockstep。scalar-dest(vcpop/vfirst)走 q_scalar 路(如 vmv.x.s);
mask-dest(vms*)/vector-dest(vid/viota)走 vd 寫路。每片 gate + directed + illegal terminator。

## §4 實作結果
- **D1a 完成(2026-07-05,@<pending>)= mask-scan 簡單集 vid.v / vcpop.m / vfirst.m**:
  - decode:OPMVV,vs1 欄選 op。VWXUNARY0 f6=010000:vcpop(vs1=10000→scalar rd)、vfirst
    (vs1=10001→scalar rd)。VMUNARY0 f6=010100:vid(vs1=10001→vd[i]=i,vs2 忽略)。maskable
    (active=vm||v0[i]);**m1-only**(m2/m4 grp_only_illegal);**vstart≠0 illegal**。
  - **Spike-probe 推翻 Grok**:Grok 判 vcpop/vfirst「vstart-exempt 不可 trap」,**實跑 Spike vcpop
    @vstart≠0 = illegal trap** → 用既有全域 vstart 規則即匹配,無 carve-out(B4 教訓再現:Spike 實跑 >
    第三方 flag)。
  - **跨模組修 idu.v**:vcpop/vfirst 寫 scalar GPR rd,但 idu.v 的 rd_we 原僅認 vmv.x.s。擴為
    `opv_scalar_rd = vmv.x.s | vcpop | vfirst`(皆 OPMVV f6=010000,vs1 欄分)。host EN_RVV=0 由
    is_vexec gate 掉,無 host 影響。
  - datapath:vcpop/vfirst 用 16-wide always@* scan(vs2_data[mk] & (vm||v0[mk]) & mk<vl),
    cpop_cnt/vfirst_res 走 q_scalar,q_scalar_we 加兩者(vl==0 也寫);vid 用 res_vid loops(vd[i]=i)。
  - **Spike lockstep 41 commits**:vid×SEW8/16/32 + vcpop/vfirst(unmasked/masked v0/empty→0,-1)
    + vid@vstart≠0 illegal terminator。golden mask{2,3,6}→vcpop 3/vfirst 2/vid[0..7];masked
    v0={3,6,7}→vcpop 2/vfirst 3。回歸整 vector suite(含 kernel/pool/vrand 1324)綠。gate_74。
  - **三方**:Grok arch(vstart flag 被 Spike 推翻)+ Spike golden(authority)+ Gemini 4 findings
    **全 dismiss**:#1 always@flow syntax=false positive(實際 always@*,同 C3/C4d 誤讀)、#2 vstart 檢查
    =已由全域規則處理(terminator 證)、#3 m2 mis-execute=grp_only_illegal 已 trap(非 mis-exec;m1-only
    scope-cut)、#4 vid vs2=Gemini 把 funct6 當 vs2(reserved-encoding edge,assembler 不 emit)。
- **D1b / D2a / D2b __**(續:D1b vmsbf/vmsof/vmsif/viota → D2a vslide1up/down → D2b vslideup/down)。
