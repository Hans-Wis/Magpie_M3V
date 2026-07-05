# Phase-C C3 (non-sum reductions) — review + verification record (2026-07-05)

Instrs: `vredsum` `vredand` `vredor` `vredxor` `vredminu` `vredmin` `vredmaxu`
`vredmax` `.vs` (Zve32x). ADR-0056 §5 C3.

## Legs
- **Grok (architecture)**: `docs/reviews/2026-07-05_phase_c_plan_grok.md` — C3 = pure
  control extension of the existing vredsum FSM; recommended 2nd (de-risks reduction
  corners early). (Grok's vl=0 "identity=vs2[0]" note was NOT used — vl=0 is a no-op
  here: q_vrf_we=0, matching Spike; verified against the proven vredsum path instead.)
- **Spike golden probe**: vredsum @ vstart=2 -> illegal trap (reduction vstart must be
  0); confirms the both-trap terminator matches the DUT global rule.
- **Spike lockstep**: `make c3` -> 98 commits bit-exact (all 8 reductions x SEW 8/16/32
  over signed/unsigned boundary data so minu!=min, maxu!=max; seed via vmv.s.x;
  vstart!=0 illegal terminator). Regression: 12 vector targets green incl grid/pool/
  vrand(1324) (the vredsum generalization did not regress the kernel path). Gate gate_67.

## Implementation note
Generalized `op_redsum` -> `op_red` (OPMVV f6=000xxx; f6[2:0] picks the combine).
32-bit accumulator: min/max (101/111) sign-extend seed+elements for a signed compare,
everything else zero-extends; only red_acc[SEW-1:0] commits. Kept the original scope:
vm=1 only and m1-only. Masked / group reductions stay deferred-illegal (the DUT is
intentionally MORE restrictive there than Spike, so those cases are not tested — an
honest documented gap, not a lockstep divergence).

## Gemini full-context review — findings + disposition
- **Rank 1 "fatal syntax bug" (`always @flow/...` corrupted sensitivity list) — FALSE
  POSITIVE.** Gemini misread the diff text; the actual RTL (vexu.v:767) is `always @*
  begin`, which is why Verilator lint AND the 98-commit lockstep both pass (a corrupted
  sensitivity list would not compile). No change.
- **Rank 2 — logic 100% correct.** Gemini verified min/max sign/zero extension at all
  SEW, accumulator-modulo equivalence for sum/and/or/xor, loop boundary guards, and
  no-latch inference. No change.
