# Phase-C C4b (widening multiply) — review + verification record (2026-07-05)

Instrs: `vwmul` `vwmulu` `vwmulsu` (.vv/.vx) (Zve32x). ADR-0056 §5 C4b.

## Legs
- **Spike golden probe**: vs2=-128 vs1=255 -> vwmul 128 (0x0080), vwmulu 32640 (0x7F80),
  vwmulsu -32640 (0x8080); vwmulsu.vx rs1=-1 (=255 unsigned) -> -32640. Encodings
  f6=111011/111000/111010 (OPMVV/OPMVX).
- **Spike lockstep**: `make c4b` -> 109 commits bit-exact (vwmul/vwmulu/vwmulsu x .vv/.vx
  x SEW 8/16 sign matrix; vwmulu.vv-vd==vs2 narrow-overlap illegal terminator).
  Regression: kernel/pool/vwide/grid/vrand(1324) green — extending op_wmul to OPMVX +
  adding u/su did not disturb the Phase-0 vwmul.vv kernel path. Gate gate_70.

## Implementation note
Extended op_wmul to OPMVX and added op_wmulu/op_wmulsu (op_wmulany). The g_w8/g_w16
widening loops now compute all three full 2*SEW products (p_ss=nas*nbs, p_uu=na*nb,
p_su=nas*$signed({1'b0,nb}) — signed vs2 * unsigned vs1); prod = wmulu?p_uu : wmulsu?
p_su : p_ss; r = op_wmulany?prod:ws_res (shares the C4a add/sub loop). op_widen /
widen_narrow_vs2 / known_op all use op_wmulany. vwmul.vv defaults to p_ss = nas*nbs,
byte-identical to the Phase-0 kernel op.

## Gemini full-context review — verdict
**Clean, fully compliant — no RTL change from review.** Verified: (a) product sizing +
p_su sign-mix (matched golden -32640) at SEW 8/16, SEW32 correctly gated illegal;
(b) prod mux selection; (c) op_wmulany gating vs C4a ws_res in the shared loop;
(d) vwmul.vv kernel byte-for-byte preserved; (e) op_widen/widen_narrow_vs2/known_op
decoder updates.
