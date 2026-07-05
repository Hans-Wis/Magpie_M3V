# Phase-D D1a (vid.v/vcpop.m/vfirst.m) — review + verification record (2026-07-05)

ADR-0057 §4 D1a. Instrs: vid.v (vector-dest index), vcpop.m / vfirst.m (scalar-dest mask scan).

## Legs
- Grok arch (docs/reviews/2026-07-05_phase_d_plan_grok.md). **Its vcpop/vfirst "vstart-exempt"
  claim was empirically WRONG** — Spike traps vcpop at vstart!=0 (B4 lesson repeating).
- Spike golden: mask {2,3,6} -> vcpop 3 / vfirst 2 / vid [0..7]; masked v0={3,6,7} -> vcpop 2 /
  vfirst 3; empty mask -> vcpop 0 / vfirst -1 (XLEN all ones).
- Spike lockstep: make d1a -> 41 commits bit-exact (vid x SEW 8/16/32; vcpop/vfirst
  unmasked/masked/empty; vid@vstart!=0 illegal terminator). Regression: full vector suite
  incl kernel/pool/vrand(1324) green. Gate gate_74.

## Cross-module fix (idu.v)
vcpop/vfirst write a scalar GPR, but idu.v's rd_we only recognized vmv.x.s. Extended to
opv_scalar_rd = vmv.x.s | vcpop | vfirst (all OPMVV f6=010000, vs1 field distinguishes).
Gated by is_vexec so EN_RVV=0 host is unaffected. This was the root cause of the initial
lockstep mismatch (dut rd=0 vs spike rd=x11).

## Gemini review — all 4 findings dismissed (with justification)
1. "always @flow/... syntax error" — FALSE POSITIVE (recurring diff-misread; actual is
   always @*, proven by lint + lockstep; same hallucination as C3/C4d).
2. "missing vstart!=0 check" — FALSE POSITIVE; the global q_vstart!=0 rule (vexu.v) covers
   all known_op incl these; the vid@vstart=1 terminator trapped (lockstep-confirmed).
3. "m2 silently mis-executes" — ALREADY HANDLED; grp_only_illegal traps m2/m4 mask-scan
   (!beats_op term), so no mis-execution. m1-only is a documented scope-cut (DUT stricter
   than Spike, untested), consistent with the reduction scope.
4. "vid vs2 field must be 10100" — Gemini confused funct6 (010100) with the vs2 field. Real
   point is a reserved-encoding edge (vid with vs2!=0) the assembler never emits; canonical
   vid.v (vs2=0) is lockstep-verified. Low priority / latent.
