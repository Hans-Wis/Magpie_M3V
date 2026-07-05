# Phase-F (LMUL=m8) 三方 review — 2026-07-06

Governs ADR-0059。change = 開通 m8(8-register group)給 same-width `beats_op`,延伸
既有 m1/m2/m4 的 VM_GRP multi-beat FSM 到 8 parts。

## 驗證權威
Spike lockstep `--isa=rv32imf_zve32x_zvl128b`,`phase_22 make f` = **155 commits bit-exact**
(m8 vadd.vv/.vx e8/e16 + vmsltu/vmseq→mask + vl=0/1 + masked mu + unaligned-vd@m8 illegal
terminator DUT+Spike 同 trap)。回歸:vmem 110 / e1 97 / e2 147 / b3 178 / c5 95 / d2 132 /
pool 176 / s1 87 / s3 72 / grid 146 / vrand 1324 全綠。gate_80。

## Codex(surgical,read-only)— 抓到 1 枚真 bug ✅
`cfg_illegal = vill || (lmul_m8 && !op_vmvr && !beats_op)`(初版)讓 **m8 記憶體 op 溜過**:
`vle8.v@m8` f3=000 → `op_add=1` → `beats_op=1` → `cfg_illegal=0`;`int_sh` 不含 m8 →
`vlmax_el=16`(m1 span)→ `mem_span=16` → `emul_ok=true` → `mem_illegal=0` → **靜默當 m1
截斷 load 執行**(Spike 會 EMUL=8 執行 8 reg,divergence)。m8 group-EMUL 記憶體是 out-of-scope
scope-cut,應 trap(DUT stricter)。
**修**:`cfg_illegal = vill || (lmul_m8 && !op_vmvr && !(beats_op && !is_vmem))`。與 m2/m4
群組記憶體經 `emul_ok` trap 的行為一致。修後全綠。

## Grok(架構)— no correctness bug(但漏 m8-mem alias)
width/termination(`grp_p[2:0]`/`elem_base≤112`/`{1'b0,grp_p}+4'd1==grp_parts`)、`vl_ones`
[7:0](vll==128 shift-by-128→0→−1=all ones,SystemVerilog/Verilator well-defined)、atomic
WB `w_vd+7≤31`(grp_align_illegal 保 vd mod-8)、`cfg_illegal`、`grp_mask_acc` bit-127 —— 五項
全 verified。**未抓 Codex 的 m8 記憶體 aliasing**(延續 surgical > architectural 對 aliasing gap)。

## Gemini(全上下文)— quota-blocked
free-tier daily quota 用盡(同 E2/E3/E-vrgather review)。

## 結論
1 真 bug(Codex)修畢並回歸驗證;架構/width/mask 面 clean(Grok + Spike)。Phase-F accepted。
