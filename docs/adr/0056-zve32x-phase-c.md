---
status: accepted
date: 2026-07-05
supersedes: []
governs: Zve32x Phase-C (multiply + reduction) — vexu.v
authority: Spike --isa=rv32imf_zve32x_zvl128b lockstep (phase_22)
---

# ADR-0056 — Zve32x Phase-C 乘法 + reduction 補齊(架構確認 + 實作記錄)

Roadmap = ADR-0054 §3 Phase-C。承 ADR-0055(Phase-B 整數核心 B1-B4 收齊)。目標:vexu
從「通用整數向量 + carry + whole-reg move」再補上 **乘法 / MAC / 非-sum reduction / 完整
widening / vsmul**,朝「完整 Zve32x drop-in」收斂。

## §1 Coral 對照(§2 第 1 問)
Coral(Kelvin)ML datapath 依賴整數乘法 + MAC(卷積/FC 內積)與 reduction(pooling/softmax
前處理)。Phase-C 讓標準開源 RVV kernel 的乘法/MAC/reduction 直接落 vexu(而非只走 mat_engine
的 outer-product),補齊「任何 Coral Zve32x 程式 drop-in」的通用向量算術面。

## §2 子片(Grok 架構確認 2026-07-05,cost/risk 排序)
全文 `docs/reviews/2026-07-05_phase_c_plan_grok.md`。順序 **C1→C3→C2→C4→C5**:

| 片 | 內容 | 依賴 / 風險 |
|---|---|---|
| **C1** | same-width mul:vmul/vmulh/vmulhu/vmulhsu | 基礎 SEW×SEW→2SEW 積 + low/high 取;後片皆掛此 |
| **C3** | 非-sum reduction:vredand/or/xor/minu/min/maxu/max | 純 vredsum FSM 控制擴充,複用既有 min/max/bitwise;快 |
| **C2** | MAC:vmacc/vnmsac/vmadd/vnmsub | 複用 C1 積 + add/sub;3-read + vd-overlap(accumulator,合法) |
| **C4** | widening 全套:vwaddu/vwsub[u]/vwadd(.vv/.vx)/vwmulu/vwmulsu/vwmacc[u/su/us]/vwredsum[u] | 面積最大;EMUL×2 dest 群組 + 2SEW WB commit |
| **C5** | vsmul(定點分數乘 + vxrm 捨入) | 最少複用、最 spec-sensitive;e16/e32(SEW8 可能 illegal 待 Spike 證) |

## §3 契約(§2 第 2 問)
- 無新 CSR / memory-map。乘法走既有 per-SEW datapath + beats_op 群組;MAC 讀 old-vd(3-read);
  widening 走既有 2SEW dest EMUL 規則;reduction 走 vredsum 迴圈。
- 權威 golden = Spike lockstep（逐 element vse+lw)。sign matrix 逐項 Spike-probe 釘死。

## §4 驗證計畫(§2 第 3 問)+ green-wash 守衛
- 每片 `tests/gates/gate_NN`：directed sign-corner 網格 + m2 群組 smoke + illegal terminator
  + prior-target 回歸。ISA 字串固定 `rv32imf_zve32x_zvl128b`(green-wash 守衛)。
- masked body op 寫 v0 = illegal(每片檢查加入);tail undisturbed;arithmetic vstart≠0 illegal。

## §5 實作結果
- **C1 完成(2026-07-05,@<pending>)= same-width integer multiply**:
  - decode:OPMVV/OPMVX f6 mul=100101 / mulh=100111 / mulhu=100100 / mulhsu=100110;
    f3 與 vsll(OPIV*,f6=100101)、vmv&lt;nr&gt;r(OPIVI,f6=100111)disjoint。
  - datapath:**專屬 per-SEW generate loops**(g_mul8/16/32,鏡射 widening loop 風格)形完整
    2*SEW 積再取 low(vmul,sign-agnostic)或 high(mulh/mulhu/mulhsu);ss/uu/su 用**自決定
    signed/unsigned wire**(`p_su = as * $signed({1'b0,b})`:a 符延伸、b 零延伸——避 signed-in-
    ternary 零延伸陷阱)。operand b = is_opmvv? vs1 : scalar(rs1,截 SEW)。
  - 整合:op_muls 加進 known_op + beats_op(m2/m4 群組經 part_res/grp_stage)+ masked-vd0 檢查;
    part_res / q_wdata 加 op_muls?res_mul。
  - **Spike golden probe**(-2^31×2):vmul=0 / vmulh=−1(0xFFFFFFFF)/ vmulhu=1 / vmulhsu=−1——
    RTL 逐項符。**Spike lockstep --isa=rv32imf_zve32x_zvl128b 125 commits**:四變體×vv/vx×SEW8/16/32
    sign 邊界矩陣 + e32/m2 群組 smoke + masked-vmul-寫-v0 illegal terminator。回歸 13 vector targets
    綠(含 vmem/s3/vrand 1324)。gate_66。
  - **三方**:Grok arch confirm(sign matrix/f6/f3-disjoint 全符)+ Spike golden(authority)+
    **Gemini 全上下文判 clean fully compliant**(signed-unsigned idiom / low-bit vmul / operand
    select / masking+groups 四項皆 verified,無 issue)。
- **C3 完成(2026-07-05,@<pending>)= 非-sum reductions vred{and,or,xor,minu,min,maxu,max}.vs**:
  - decode:既有 op_redsum 泛化為 **op_red = is_opmvv && f6[5:3]==000 && vm**(f6[2:0] 選 combine;
    min/max 101/111 signed、minu/maxu 100/110 unsigned)。f6=000000 = 原 vredsum。
  - datapath:32-bit accumulator red_acc,seed=vs1[0];**min/max 對 seed+element 符延伸到 32b 做 signed
    compare、其餘零延伸**(只 commit red_acc[SEW-1:0]);逐 element case combine。vl==0 = no-op(q_vrf_we=0
    因 vstart<vl 為 false,match Spike)。**scope 沿用原 vredsum:vm=1 only + m1-only**(masked/group
    reduction 仍 deferred-illegal——DUT 較 Spike **嚴**,故不測,誠實 gap 非 lockstep 分歧)。
  - **Spike lockstep 98 commits**:八 reduction × SEW8/16/32 sign 邊界(minu≠min、maxu≠max)+ vmv.s.x 設 seed
    + vredsum@vstart≠0 illegal terminator(Spike 實跑確認 both trap)。回歸 12 targets 綠(含 grid/pool/vrand
    1324,vredsum 泛化無回歸)。gate_67。
  - **三方**:Grok arch(reduction=vredsum FSM 擴充;其 vl=0 identity 註記**未採**——vl=0 是 no-op 非 vs2[0])
    + Spike golden(authority)+ **Gemini**:Rank-1「fatal syntax bug(always @flow/... 壞 sensitivity list)」
    = **false positive**(誤讀 diff;實際 vexu.v:767 = `always @*`,lint+lockstep 皆過即證),Rank-2 判 logic
    100% correct(min/max 符號/accumulator-modulo/boundary guard/no-latch 全 verified)。**無 RTL 改動**。
- **C2 完成(2026-07-05,@<pending>)= 整數 MAC vmacc/vnmsac/vmadd/vnmsub**:
  - decode:OPMVV/OPMVX f6 vmacc=101101 / vnmsac=101111 / vmadd=101001 / vnmsub=101011;f3 與
    vsra/vnsra/vssra/vnclip(OPIV*,同 f6)disjoint。**vd = accumulator**(讀 vd_old;vd-overlap
    with vs1/vs2 **合法**,不套任何 generic overlap illegality)。scalar 取代 vs1(.vx)。
  - datapath:專屬 per-SEW loops,a=vs2、b=(opmvv?vs1:rs1)、d=vd_old;prod_ab=a*b、prod_db=d*b(截
    SEW);r = vmacc?d+prod_ab : vnmsac?d−prod_ab : vmadd?prod_db+a : a−prod_db。**low SEW bits
    sign-agnostic**(二補數)。op_mac 加 known_op/beats_op/masked-vd0/part_res/q_wdata。
  - **Spike golden probe(vd=10,vs1=3,vs2=5)→ macc 25 / nmsac −5 / madd 35 / nmsub −25 逐項符**;
    lockstep 154 commits(四 MAC×vv/vx×SEW8/16/32 + **vd==vs1/vd==vs2 overlap 合法(不 trap)** +
    e32/m2 群組 + masked-vmacc-v0 terminator)。回歸 12 targets 綠;gate_68。
  - **三方**:Grok arch(operand roles 全符)+ Spike golden(authority)+ **Gemini clean fully
    compliant**(operand roles / low-SEW truncation / group-path vd_old / operand select 四項
    verified,無 review 修)。
- **C4a 完成(2026-07-05,@<pending>)= full widening add/sub vwaddu/vwadd/vwsubu/vwsub(.vv/.vx/.wv/.wx)**:
  - decode:既有 op_waddw(僅 vwadd.wv)泛化為 **op_waddsub = f6[5:3]==110 && (opmvv||opmvx) && vm**;
    f6[2]=wide-vs2(.wv/.wx)、f6[1]=sub、f6[0]=signed。
  - datapath(擴既有 g_w8/g_w16 widening loops):na=vs2、nb=(opmvv?vs1:rs1)、wa=wide vs2;narrow 依
    f6[0] 符/零延伸;wopa=ws_wide?wa:na_x;ws_res=ws_sub?(wopa−nb_x):(wopa+nb_x)。vwmul.vv 保留為獨立
    prod 分支。overlap(require_noover):vd==vs1 僅 OPMVV illegal(is_opmvv gate,OPMVX 的 vs1 欄=rs1)、
    vd==vs2 僅 vs2 narrow 時 illegal(widen_narrow_vs2=vwmul||.vv/.vx);**vwadd.wv vd==vs2 wide 合法**
    (保 kernel accumulate)。SEW≤16、fractional LMUL、vm=1 only(同既有 widening scope)。
  - **Spike golden(vs2=0xFF,vs1=1):vwaddu 256 / vwadd 0 / vwsubu 254 / vwsub −2 / vwaddu.wv 257 /
    vwsub.wv 255 逐項符**;lockstep 159 commits(8 add/sub × .vv/.vx/.wv/.wx × SEW8/16 + vd==vs2-wide
    合法 + narrow-overlap illegal terminator)。回歸 kernel/pool/vwide/grid/vrand 綠(op_waddw→op_waddsub
    泛化不擾 Phase-0 kernel 路徑)。gate_69。
  - **三方**:Grok arch(EMUL/require_noover)+ Spike golden(authority)+ **Gemini completely clean fully
    compliant**(sign/zero ext、wide-vs2、subtract direction、overlap gates、legacy kernel 保留 五項
    verified,無 review 修)。
- **C4b/c/d / C5 __**(續:C4b widening mul vwmulu/vwmulsu → C4c widening MAC vwmacc[u/su/us] → C4d widening
  reduction vwredsum[u] → C5 vsmul)。
