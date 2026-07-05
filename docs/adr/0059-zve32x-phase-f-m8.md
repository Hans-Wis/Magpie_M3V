---
status: accepted
date: 2026-07-06
supersedes: []
governs: Zve32x Phase-F (LMUL=m8) — vexu.v, core.v
authority: Spike --isa=rv32imf_zve32x_zvl128b lockstep (phase_22)
---

# ADR-0059 — Zve32x Phase-F:LMUL=m8(架構確認 + 實作記錄)

Roadmap = ADR-0054 §3 Phase-F(最後一階,m8)。承 Phase-A/B/C/D/E 全綠。m8 = 8-register
group,是 Zve32x 唯一還沒開的 LMUL。開通後可宣稱「任何 Coral Zve32x 程式的 LMUL 設定
(mf8..m8)drop-in」。

## §1 架構確認(Coral 對照 + Grok 判斷 + Spike 探測)
- **Coral 對照**:Coral Kelvin 用 Zve32x VLEN128;m8 是標準 LMUL 檔位,自動向量化在大迴圈
  會 emit m8 以攤 loop overhead。功能對等要求 m8 可執行(非 optional)。
- **Spike 探測(authority,非第三方 spec)**:vlmax e8=128 / e16=64 / e32=32
  (`LMUL*VLEN/SEW`,m8 **提高** vlmax)。**Grok 一度誤判 m8 降 vlmax(與 mf8 搞混),
  以 Spike 實跑推翻**(延續本線「Spike > 第三方 spec flag」教訓,見 B4/D2/Phase-F)。
  vd/vs 需 mod-8 對齊(vadd v9@m8 → illegal,探測確認 DUT+Spike 皆 trap)。tail 暫存器
  (vl<vlmax)undisturbed。
- **scope**:in = 所有 same-width `beats_op`(add/sub/bitwise/shift/min-max/compare/
  mul/mac/sat/vsmul/carry/vdiv);out = widening/reduction/mask-scan/gather/slide → m8
  **illegal**(`cfg_illegal`,誠實界:m8 EMUL>8 或 SEW-doubling 超出 8-reg 群組)。
  compare 出**單一** mask register(m1 dest),只有 vd 群組路走 8 beat。

## §2 契約
- decode/legality:`grp_parts = m8?8:m4?4:m2?2:1`([3:0]);`cfg_illegal = vill ||
  (lmul_m8 && !op_vmvr && !beats_op)`(m8 只留 beats_op + vmvr 合法);`grp_amask`
  m8→5'd7(vd/vs mod-8 對齊檢查,`grp_align_illegal`)。
- FSM/staging:`VM_GRP` 8-beat(`grp_p [2:0]` 0..7、`part_off`、`elem_base [7:0]`
  最大 16×7=112);staging `grp_stage[0:7]`;終止比較 `{1'b0,grp_p}+4'd1==grp_parts`。
- WB atomic group commit:`w_parts>=4` 寫 stage[2..3]、`w_parts==8` 寫 stage[4..7]
  (vd..vd+7);跨模組 port `q_grp_parts/w_parts/ex_*_grp_parts_r/vexu_q_grp_parts`
  全 [2:0]→[3:0]。
- **compare mask vl_ones 修正(latent bug,Phase-F 抓到)**:`vl_ones = (128'h1 <<
  q_vl[7:0]) - 1`。舊 `q_vl[6:0]` 在 vl==128(m8 e8)aliases 128→0 → vl_ones=0 →
  compare 結果全丟。改 [7:0]:vl==128 → shift-by-128(≥width→0)→ −1 填滿 128 mask
  位。vl≤127 行為不變(回歸證)。

## §3 驗證計畫 + 結果
- **Spike golden(authority)**:`phase_22 make f` vs `--isa=rv32imf_zve32x_zvl128b`,
  **155 commits 全符**。涵蓋:m8 vadd.vv/.vx @ e8(vlmax=128)/e16(vlmax=64)、
  compare→mask(vmsltu.vx 半群組 pattern + vmseq.vv 全 1)、vl=0(不寫)、vl=1、
  masked mu(masked-off 保舊)、**unaligned-vd@m8 illegal terminator(DUT+Spike 同
  trap)**。策略:群組源在 m1 逐 reg distinct splat(每 reg 16-elem step pattern),
  m8 運算後再逐 reg vse+lw 觀察(group-EMUL mem out-of-scope,沿用既有觀察法)。
- **回歸全綠**:vrand 1324、pool 176、b1/b2/b3(carry)/c1/c5(vsmul)/d2(slide)/
  e1(vdiv)/e2(segment m2/m4)—— width 變更 + vl_ones 修正無回歸。
- gate = `tests/gates/gate_80_rvv_f_m8.py`。

## §4 三方 review
- **Spike lockstep = 正確性權威(155c bit-exact,+ 修正後回歸全綠)**。
- **Codex(surgical,read-only)抓到一枚真 bug**:`cfg_illegal` 加 `!beats_op` 後,**m8
  記憶體 op 溜過**——`vle8.v@m8` 的 f3=000 alias `op_add`→`beats_op=1`→`cfg_illegal=0`;
  且 `int_sh` 不含 m8 → `mem_illegal` 以 m1-span 判 `emul_ok=true` → **靜默當 m1 截斷執行**
  而非 trap(m8 group-EMUL 記憶體是 out-of-scope、DUT-stricter scope-cut)。**修**:
  `cfg_illegal = vill || (lmul_m8 && !op_vmvr && !(beats_op && !is_vmem))` —— m8 只對
  **非記憶體** beats_op(VM_GRP 8-beat 算術路)+ vmvr 合法;m8 記憶體維持 illegal(與
  m2/m4 群組記憶體經 `emul_ok` trap 的行為一致)。修後 vmem 110 / e2 147 / vrand 1324 全綠。
  (這是 Codex 本產品規格線第 4 次抓 green-wash/真 gap:C5 group-store、D2 fractional、
  E2-stub tail、E2-m2 align 之後。)
- **Grok(架構)= no correctness bug**(width/termination/vl_ones/WB/cfg_illegal/mask
  五項全 verified)——**但漏掉 Codex 抓的 m8 記憶體 alias**(延續「surgical > architectural
  對 aliasing 類 gap」觀察)。
- **Gemini = quota-blocked**(同 E2/E3;free-tier daily quota 用盡)。
- green-wash 守衛:group-EMUL mem out-of-scope(誠實界,用 splat 建源 + m1 觀察);
  unaligned-vd 用 illegal terminator 驗 DUT/Spike 同 trap(非只觀 active lane)。

## §5 狀態
Phase-F 完成 → **完整 Zve32x LMUL 全檔位(mf8..m8)上線**。Zve32x 產品規格 roadmap
(ADR-0054)整數/LMUL 面收齊;剩長尾 = Phase-E 未做項(vcompress/indexed/strided/
fault-only-first/vrgatherei16/masked reductions),低頻、TFLM 自動向量化不 emit。
