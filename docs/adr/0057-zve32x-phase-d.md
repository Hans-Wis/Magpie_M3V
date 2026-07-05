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
- **D1b 完成(2026-07-05,@<pending>)= vmsbf/vmsof/vmsif.m(mask dest)+ viota.m(vector dest)**:
  - decode:VMUNARY0 f6=010100,vs1 選 op(vmsbf=00001/vmsof=00010/vmsif=00011/viota=10000)。F=vs2 首個
    active set bit;vmsbf i<F、vmsof i==F、vmsif i<=F;viota vd[i]=# active set bits in [0,i)。
  - datapath:單一 always@* scan(mbits=active set bit,run/preset 追蹤 [0,i) 的 count/any-set);
    vms_raw 依 op 選;vms bits 經 seg8/16/32 走既有 compare **mask_dest res_cmp 路**(op_vms 加 mask_dest);
    viota 走 res_viota per-SEW → q_wdata。m1-only、vstart≠0 illegal、masked viota 寫 v0 illegal。
  - **Spike-probe 再推翻 Grok**:Grok 判「vms* vd==v0 always illegal」,實跑 vmsif.m v0,v2(unmasked vd==v0)
    正常執行 → vms* 當 compare 處理(mask-dest,vd==v0 合法)。empty mask:vmsbf/vmsif=全 1、vmsof/viota=全 0。
  - **Spike lockstep 67 commits**(四 op masked/unmasked/empty + viota SEW8/16/32 + viota@vstart≠0 terminator);
    回歸整 suite(b3 mask_dest/s1 compares/pool/vrand 1324)綠。gate_75。
  - **三方**:Grok(vd==v0 flag 被 Spike 推翻)+ Spike golden(authority)+ Gemini **fully clean**(prefix 邏輯含
    no-set-bit / viota count / mask-vs-vector dest / m1+vstart / latch-free / SEW slicing 六項 verified,無改)。
- **D2 完成(2026-07-05)= slides vslideup/vslidedown(.vx/.vi)+ vslide1up/vslide1down(.vx)= PHASE-D 收齊**:
  - decode:f6=001110(up)/001111(down);OPIVX/OPIVI=slide(off=rs1/uimm)、OPMVX=slide1(off=1,注入
    rs1[SEW-1:0] 於 0/vl-1)。datapath=**barrel-shift**(vs2_up=vs2<<off*SEW、vs2_dn=vs2>>off*SEW zero-fill)。
    m1 + fractional LMUL(整數 m2/m4 grp_only_illegal)。
  - **legality 全 Spike-probe(Grok 連兩點皆錯)**:vstart≠0→illegal(非 honored,全域規則);slideup-family
    vd==vs2→illegal(require_noover),slidedown vd==vs2 legal;masked slide 寫 v0 illegal。
  - **Spike lockstep 132 commits**;回歸整 suite 綠;gate_76。
  - **三方(Codex+Grok+Gemini)**:**Codex 抓 1 真 bug** —— fractional-LMUL vslidedown zero-fill 用實體
    vlmax(16)非 fractional vlmax_el(e8/mf2 VLMAX=8 off=2→lanes 6,7 誤回 vs2[8/9] 非 0;fractional 到達
    slide 路未 trap,m1 firmware 遮蔽)。修=dn_v 加 `gi+off<vlmax_el` guard + directed e8/mf2 test。**Grok
    獨立抓同一 bug** + 確認其餘 clean。**Gemini API-blocked(503)**。多 agent review 價值:m1 directed test
    無法暴露的 fractional 分歧被兩獨立 reviewer 抓到。
- **Phase-D 完成(D1a mask-scan / D1b mask-prefix / D2 slides)。**
