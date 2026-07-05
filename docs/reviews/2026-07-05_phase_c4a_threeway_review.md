# Phase-C C4a (full widening add/sub) — review + verification record (2026-07-05)

Instrs: `vwaddu` `vwadd` `vwsubu` `vwsub` (.vv/.vx/.wv/.wx) (Zve32x). ADR-0056 §5 C4a.

## Legs
- **Grok (architecture)**: `docs/reviews/2026-07-05_phase_c_plan_grok.md` §4 — widening EMUL
  (dest 2*SEW, EMUL_dest=2*EMUL_src) and require_noover overlap rules.
- **Spike golden probe**: vs2=0xFF vs1=1 -> vwaddu 256, vwadd 0, vwsubu 254, vwsub -2,
  vwaddu.wv 257, vwsub.wv 255. Encodings f6=110xxx (f6[2]=wide, f6[1]=sub, f6[0]=signed).
- **Spike lockstep**: `make c4a` -> 159 commits bit-exact (all 8 add/sub x .vv/.vx/.wv/.wx
  x SEW 8/16; vd==vs2-wide legal case; vwaddu.vv-vd==vs2 narrow-overlap illegal terminator).
  Regression: kernel/pool/vwide/grid/vrand(1324) green — the op_waddw->op_waddsub
  generalization did not disturb the Phase-0 vwmul.vv/vwadd.wv kernel path. Gate gate_69.

## Implementation note
Generalized op_waddw (vwadd.wv only) into op_waddsub (f6=110xxx). Per-SEW: na=vs2, nb=
(opmvv?vs1:rs1), wa=wide vs2; narrows sign/zero-extend per f6[0]; wopa=ws_wide?wa:na_x;
ws_res=ws_sub?(wopa-nb_x):(wopa+nb_x). vwmul.vv preserved as a separate prod branch.
Overlap: vd==vs1 illegal only for OPMVV forms (is_opmvv gate — OPMVX vs1 field is rs1);
vd==vs2 illegal only when vs2 narrow (widen_narrow_vs2 = vwmul or .vv/.vx). vwadd.wv
(vd==vs2 wide) stays legal, preserving the kernel accumulate.

## Gemini full-context review — verdict
**Completely clean, fully compliant — no RTL change from review.** Verified: (a)
sign/zero extension per f6[0] at SEW 8/16; (b) wide-vs2 used unextended; (c) subtract
direction op_a - ext(vs1); (d) overlap legality gates (is_opmvv for vs1, widen_narrow_vs2
for vs2); (e) legacy vwmul.vv + vwadd.wv kernel accumulate preserved.
