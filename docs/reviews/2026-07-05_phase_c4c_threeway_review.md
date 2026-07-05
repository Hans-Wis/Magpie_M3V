# Phase-C C4c (widening MAC) — review + verification record (2026-07-05)

Instrs: `vwmaccu` `vwmacc` `vwmaccsu` `vwmaccus` (Zve32x). ADR-0056 §5 C4c.

## Legs
- **Spike golden probe (operand-role authority)**: vs2=-128 vs1/rs1=255 vd=0 ->
  vwmaccu 32640, vwmacc 128, vwmaccsu -128, vwmaccus -32640. This pinned the notorious
  su/us sign-role SWAP: vwmaccsu = signed(vs1)*unsigned(vs2); vwmaccus =
  unsigned(rs1)*signed(vs2) (= same formula as vwmulsu's p_su). Encodings f6=111100/
  111101/111111/111110 (vwmaccus .vx only).
- **Spike lockstep**: `make c4c` -> 151 commits bit-exact (all 4 MAC x .vv/.vx (vwmaccus
  .vx only) x SEW 8/16 with a reseeded accumulator; vwmaccu.vv-vd==vs2 narrow-overlap
  illegal terminator). Regression: kernel/pool/vwide/grid/vrand(1324) green. Gate gate_71.

## Implementation note
Added to the g_w8/g_w16 widening loops: p_maccsu = nbs*$signed({1'b0,na}) (signed vs1 *
unsigned vs2); mac_prod = maccu?p_uu : macc?p_ss : maccsu?p_maccsu : p_su (vwmaccus
reuses p_su); macc_res = mac_prod + vd_old_wide (mod 2^(2*SEW)); r = op_wmaccany?
macc_res : op_wmulany?prod : ws_res. vwmaccus gated OPMVX-only. op_widen /
widen_narrow_vs2 / known_op include op_wmaccany (vd==vs1/vs2 illegal, require_noover).

## Gemini full-context review — verdict
**Fully clean, functionally correct — no RTL change from review.** Verified: (a) the 4
sign variants incl the maccsu/maccus swap (matched goldens -128 / -32640); (b)
accumulator width + mod 2^(2*SEW); (c) vwmaccus .vx-only gating; (d) decoder/overlap
inclusion of op_wmaccany; (e) non-disturbance of the C4a/C4b/kernel paths.
