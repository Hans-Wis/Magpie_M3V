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
- **C3 / C2 / C4 / C5 __**(續,照 §2 順序)。
