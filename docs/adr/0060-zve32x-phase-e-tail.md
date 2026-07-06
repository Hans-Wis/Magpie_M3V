---
status: accepted
date: 2026-07-06
supersedes: []
governs: Zve32x Phase-E tail (vcompress + remaining permutation/memory) — vexu.v
authority: Spike --isa=rv32imf_zve32x_zvl128b lockstep (phase_22)
---

# ADR-0060 — Zve32x Phase-E tail(架構確認 + 實作記錄)

承 ADR-0058(E1 vdiv / E2 segment / E3 vrgather)+ ADR-0059(Phase-F m8)。Phase-E
長尾 = vcompress、strided(vlse/vsse)、indexed(vluxei/vsuxei)、fault-only-first
(vle*ff)、vrgatherei16、masked reductions。Grok 架構判斷全文
`docs/reviews/2026-07-06_phase_e_tail_plan_grok.md`。

## §1 ROI 排序(Grok + Coral/TFLM 對照)
| 序 | 項目 | ROI | 裁決 |
|---|---|---|---|
| **1** | **vcompress.vm** | 中高——compiler 在 compare→mask compaction / classification head emit | **do-now(本片)** |
| 2 | strided vlse/vsse | 高——depthwise/stride conv、NHWC row | do-now(次片,vmem FSM) |
| 3 | indexed vluxei/vsuxei | 高——gather/scatter | do-now(vmem FSM 復用 segment) |
| 4 | vle*ff | 中——需 vl CSR 副作用 | 待 object-dump 證據 |
| 5 | masked reductions(vred* vm=0) | 中 | defer(scope-cut,vm=1-only 誠實界) |
| 6 | vrgatherei16 | 低——16-bit index EMUL 群組 | defer(承 E3) |

## §2 vcompress.vm — 架構確認 + 契約
- **Coral 對照**:Coral Zve32x 曝 compress;compiler-emitted RVV(非只手寫)parity 需之。
- **encoding**:OPMVV f6=010111,**vm=1**(v0 不用,mask 是 explicit vs1 operand)。
  **encoding 修一次**:vcompress 編碼 vm=1(非 0);初版 `!vm` 誤 decode → DUT 誤 trap
  (pc=0x38,Spike 執行故非 both-trap)→ 改 `vm`。
- **語義(Spike-probe 釘死)**:mask = **vs1 的 bit i**(非 element LSB,非 v0);
  `j=0; for i in [0,vl): if vs1_bit[i]: vd[j++]=vs2[i]`;positions [j,vl) 與 [vl,vlmax)
  **undisturbed**(empty-mask 0x00 + pre-color 0x99 test 證 tail 保舊)。probe:mask 0x4D
  over [10..17] → [10,12,13,16]。
- **legality**:vstart≠0 illegal(全域非-mem 規則)· overlap vd==vs2/vs1 illegal
  (require_noover,`compress_illegal`)· **m1-only**——LMUL>1 由既有 `grp_only_illegal`
  (vcompress 非 beats_op)自動 trap,零新碼(誠實 scope-cut,同 reduction;LMUL>1 需
  *跨暫存器全域 running-j* scatter,破壞 VM_GRP per-part 獨立模型,defer)· vd==v0 合法
  (無 v0-mask 衝突)。
- **RTL shape**:vexu permute path(非 vmem、非 group FSM)。組合 running-index scatter:
  per-SEW unrolled always@* 迴圈 `res_compress[cpwj*SEW +: SEW] = vs2[i]`(variable-base
  part-select 實現 running j),default `res_compress=vd_old`(tail undisturbed)。
  q_wdata mux + known_op + compress_illegal;q_vrf_we 沿用(正常 vector 寫)。

## §3 驗證計畫 + 結果
- **Spike golden(authority)**:`phase_22 make ecmp` = **88 commits bit-exact**。涵蓋:
  e8 mask 0x4D→[10,12,13,16]、all-active identity、**empty-mask tail-undisturbed
  (pre-color 0x99)**、e16 mask 0x35、e32 mask 0x0A、**partial-vl=5 tail-undisturbed**、
  vd==vs2 overlap illegal terminator(DUT+Spike 同 trap)。
- **回歸全綠**:e3/d2/d1b/f(m8 155)/b3/c5/s1/pool/grid/**vrand 1324**。
- gate = `tests/gates/gate_81_rvv_vcompress.py`。

## §4 三方 review
- **Spike lockstep = 正確性權威(88c bit-exact)**。
- **Codex(surgical)= no correctness bug found**(running-index scatter、variable-base
  part-select 無 out-of-range/latch、mask=vs1-bit、legality/tail/decode-aliasing 全 clean;
  唯一泛提 = SEW>32 vtype 議題屬 diff 外、Zve32x 合法 vtype 下不觸)。
- **Grok(架構)= no correctness bug found**(五項逐查:part-select 邊界 cpwj≤15/latch
  none、mask-bit、m1-only/vstart/overlap/vd==v0-legal、tail=vd_old default、f6=010111
  無 collision)。**minor(非 bug)**:e8 有 `cpwj<16` 防禦守衛、e16/e32 省略——迴圈上限
  + vlmax 已證安全,defensive asymmetry 保留。
- **Gemini = quota-blocked**(同 E2/E3/F;free-tier daily quota 用盡)。
- green-wash 守衛:tail-undisturbed 用 pre-color(非只觀 packed lanes)+ empty-mask +
  partial-vl 專打;overlap 用 illegal terminator 驗 both-trap;mask 讀 vs1-bit 非 v0
  (encoding vm=1 已強制)。**encoding vm=1 教訓**:vcompress 是唯一 mask-在-vs1 的 op,
  vm bit 反直覺=1(bring-up 初版 `!vm` 誤 trap,objdump bit25 一看即定位)。

## §5 狀態
vcompress 完成。Phase-E 長尾剩:strided(次片,ROI#1)→ indexed → (defer)ff/masked-
reduction/vrgatherei16。完整 Zve32x 再進一步。
