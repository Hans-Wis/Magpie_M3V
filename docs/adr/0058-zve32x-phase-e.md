---
status: accepted
date: 2026-07-05
supersedes: []
governs: Zve32x Phase-E (divide + special memory) — vexu.v
authority: Spike --isa=rv32imf_zve32x_zvl128b lockstep (phase_22)
---

# ADR-0058 — Zve32x Phase-E 除法 + 特殊記憶體(架構確認 + 實作記錄)

Roadmap = ADR-0054 §3 Phase-E。承 Phase-A/B/C/D 全綠。Phase-E = 昂貴/低頻的長尾
(vdiv、gather/compress、indexed/strided/segment memory、fault-only-first)。**據
可替代性實測**(TFLM 自動向量化只漏 `vdiv` + `vlseg`),Phase-E 優先做 **E1 vdiv**。

## §1 子片 + Grok 架構判斷(全文 docs/reviews/2026-07-05_phase_e_plan_grok.md)
- **E1 vdiv = 立即做**:localized(vexu-only)、Spike-clear、combinational per-element
  divide OK(functional lockstep;真 HW 多拍序列化,timing deviation 記錄如 fexu F4)。
- **E2 segment(vlseg/vsseg)= DEFER(架構 scope-cut)**:非 decode shim,而是 vmem FSM 重寫
  (element×field 雙迴圈、multi-reg scoreboard、EMUL 暫存器群組 nf×LMUL≤8、EEW≠SEW 轉換)。
  **高 green-wash 風險 + 低 Coral/TFLM 收益**(TFLM 用 unit-stride + strided(Phase-D),
  AoS segment 罕見;實測編譯器只在 naive maxpool emit 一次 vlseg)。escape hatch:若特定
  kernel 需要,只做 `nf=2, eew=sew, LMUL=1, vm=1, vstart=0` stub;否則待 vmem FSM 通用
  多欄位重構時,與 indexed/gather 一併做。prerequisite:vmem spec 修訂定義 segment =
  element-major/field-minor 巢狀迴圈 + 暫存器群組寫合約 + 逐 (nf,LMUL,EEW,SEW) corner
  Spike litmus。

## §2 實作結果
- **E1 完成(2026-07-05,@<pending>)= vdivu/vdiv/vremu/vrem**:
  - decode:OPMVV/OPMVX f6 100000/100001/100010/100011(f3 與 vsaddu/vsadd/vssubu/vssub
    OPIV* 同 f6 但 disjoint)。vd = vs2 op vs1(/rs1)。
  - datapath:per-SEW 組合除法;special cases:`bz=(b==0)` → 無號 /0=all-1s、%0=dividend;
    有號 /0=-1、%0=dividend;`sov=(a==MIN && b==-1)` → 有號溢位 div=MIN、rem=0;有號除法
    向零截斷(Verilog $signed / 、$unsigned() cast 保位)。op_vdivr 加 known_op/beats_op(m2/m4)/
    masked-vd0/part_res/q_wdata。**combinational divide = timing deviation(記錄,同 F4;真 HW 序列化)**。
  - **Spike golden(全 special case)**:a/0→FF/-1、a%0→a、MIN/-1→MIN,0、-20/3→-6 r-2 逐項符;
    lockstep 97 commits(4 op×.vv/.vx×SEW8/16/32 + m2 群組 + masked-v0 terminator);回歸整 suite
    (c1/c2/d2/pool/vrand 1324)綠。gate_77。
  - **三方**:Grok arch(E1 do-now,E2 defer)+ Spike golden(authority)+ **Gemini clean fully
    compliant**(decode disjoint / special cases+constants / signed-div trunc+$unsigned / masking
    五項 verified,無 review 修)。
- **E2 完成(2026-07-05,minimal stub,User 核准)= segment load/store vlseg<nf>/vsseg<nf>**:
  scope=nf=2..8, EEW=SEW, LMUL=1, unmasked, vstart=0, unit-stride(out-of-scope LMUL>1/EEW≠SEW/masked
  刻意 illegal=DUT 較 Spike 嚴,scope-cut 不測)。實作=vmem FSM 擴充:seg_off byte 累加 + seg_fld field
  計數 + vm_idx element;load 逐 beat 存 seg_buf[field][element],末拍 VM_SEGWR 逐 reg 排空到 vd..vd+nf-1
  (唯一 vrf 寫 block,q_vrf_we=0 如 vmvr);store 逐 beat 從 vrf[vd_i+seg_fld] 取。Spike lockstep 90c
  (vlseg2/3/4 + vsseg2 + SEW8/16/32 + partial-vl tail);vmem 非-segment 路不變(110);gate_78。
  **三方 Codex+Grok+Gemini:Codex 抓真 bug=segment load tail lanes(vl<VLMAX)排空整 seg_buf(stale tail)
  而非 undisturbed;directed test 只觀 active lane 遮蔽(green-wash!)。修=drain byte-wise blend 舊 field
  register(seg_drain)+ partial-vl test 驗。Grok in-scope 結構正確(未抓 tail)。Gemini quota-blocked。**
  - **E2 擴 LMUL>1(@e7ede7b,User 裁示——實測編譯器 vlseg2e8 在 m2 emit)**:stub LMUL=1 → **m1/m2/m4**(EMUL
    暫存器群組)。field f = L 暫存器群組 {vd+f*L..};element i → 實體 reg offset p=f*L+i/epr、lane=i%epr;
    seg_bufi=(seg_fld<<log2L)+i/epr;drain nf*L 暫存器 + **per-register tail blend**(reg-in-group r=p&(L-1),
    active bytes=clamp(vl−r*epr,0,epr)*EEW)。vm_idx 加寬 [5:0](VLMAX≤64)。seg_ok:m1/m2/m4、nf*L≤8、
    vd+nf*L≤32、**vd L-對齊**、EEW=SEW、vstart=0。lockstep 147c(LMUL=1 + vlseg2e8@m2 編譯器 emission +
    m4 + partial-vl 跨群組 + 非對齊 vd terminator);vmem 110/vrand 1324 綠。**三方:Codex 抓真 bug=seg_ok
    缺暫存器群組對齊檢查(vlseg2e8@m2 vd=v1 DUT 執行但 Spike trap=green-wash,對齊 vd test 遮蔽)→ 修加
    (vd&(L-1))==0 + 非對齊 terminator 驗。Grok 確認其餘正確。Gemini quota-blocked。Codex 本 phase 第 3 次抓
    green-wash(D2 fractional / E2-stub tail / E2-m2 align)。**
- **E3 完成(2026-07-05)= vrgather.vv/.vx/.vi**:vd[i]=(index>=vlmax)?0:vs2[index],index=vs1[i](SEW)/
  rs1/uimm。OPIVV/OPIVX/OPIVI f6=001100。m1 組合 crossbar(idx[3:0]/[2:0]/[1:0] 選 lane,OOR 用
  **vlmax_el** fractional-aware→0)。require_noover:vd==vs2 illegal、.vv vd==vs1 illegal;vstart≠0
  illegal(全域);masked-vd0。**vrgatherei16(f6=001110 OPIVV)deferred**(16-bit index 需 EMUL>1 index
  群組)。lockstep 73c(.vv/.vx/.vi×SEW8/16/32+OOR+broadcast+masked+overlap terminator);回歸全綠;
  gate_79。**三方:Codex + Grok 皆 no correctness bug(crossbar/OOR-vlmax_el/index source/legality
  全 verified;Grok 確認 OOR 用完整 idx 非截斷 mux bits 故無 fractional aliasing)。Gemini quota-blocked。**
- **其餘 Phase-E(vcompress/indexed/strided/ff/vrgatherei16)未做。剩 Phase-F(m8)。**
