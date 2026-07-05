# Phase-D D2 (slides) — three-way review + verification record (2026-07-05)

ADR-0057 §4 D2. vslideup/vslidedown(.vx/.vi) + vslide1up/vslide1down(.vx).

## Legs
- **Spike probes (authority, overrode Grok's spec claims TWICE)**: vslideup vd==vs2 ->
  ILLEGAL (require_noover; Grok said legal); vslidedown vd==vs2 -> legal; vstart!=0 ->
  ILLEGAL for both (Grok said honored); vslide1 injects rs1[SEW-1:0] at 0 / vl-1.
- **Spike lockstep**: make d2 -> 132 commits bit-exact (all slide forms x SEW 8/16/32;
  .vx/.vi; masked slideup/slidedown/slide1down; off>=vl edges; fractional-LMUL e8/mf2
  vslidedown zero-fill; vslideup-vd==vs2 overlap illegal terminator). Regression full
  vector suite incl d1a/d1b/c5/pool/vrand(1324) green. Gate gate_76.

## Three-way review (Codex + Grok + Gemini)
- **Codex — found 1 real bug (fixed)**: fractional-LMUL vslidedown zero-fill used the
  PHYSICAL vlmax (16) not the fractional vlmax_el. e8/mf2 (VLMAX=8) off=2 -> lanes 6,7
  returned physical vs2[8],vs2[9] instead of 0. Fractional LMUL reaches the slide path
  (grp_parts=1, not trapped), so this was a live divergence, only masked because the m1
  firmware uses VLMAX=16. Fix: guard dn_v with `{gi}+off_c < vlmax_el` (per SEW). Added a
  directed e8/mf2 vslidedown test (16 bytes loaded at m1 so physical lanes 8+ nonzero) ->
  lockstep now confirms lanes 6,7 == 0.
- **Grok — independently found the SAME fractional-LMUL bug**; otherwise confirmed clean:
  slide1 inject index + rs1 truncation, vstart!=0 illegal (not honored), slide_illegal =
  op_slideup && vd==vs2 (slidedown legal), masked-vd0 for op_slide, active/mask/tail.
  Noted test gaps (masked vslidedown) -> masked vslidedown/slide1down added.
- **Gemini — API-blocked (persistent 503, model overloaded)** this round; the two
  substantive legs (Codex + Grok) both caught the one real bug and agreed on the rest.

Both independent reviewers converging on the fractional-LMUL zero-fill is the multi-agent
review value: a live correctness gap the m1-only directed test could not surface.
