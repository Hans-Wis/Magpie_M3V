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
- **E2 segment = DEFER(見 §1)。其餘 Phase-E(gather/compress/indexed/strided/ff)未做。**
