# Phase-C C5 (vsmul) — review + verification record (2026-07-05)

Instr: `vsmul` (.vv/.vx) — signed saturating rounding fractional multiply (Zve32x).
ADR-0056 §5 C5. **Completes Phase-C.**

## Legs
- **Spike golden probe**: OPIVV/OPIVX f6=100111 (f3-disjoint from vmulh OPMV* and
  vmv<nr>r OPIVI). SEW8 legal (Spike executes it — resolves Grok's "maybe illegal"
  flag). rnu: 64*64>>7=32, -128*-128->127 (vxsat set), 64*3>>7 rounds 1->2.
- **Spike lockstep**: `make c5` -> 95 commits bit-exact (vsmul x .vv/.vx x SEW 8/16/32
  across all four vxrm modes over fractional/saturating data; vxsat via csrr; e32/m2
  group smoke; masked-vsmul-writing-v0 illegal terminator). Regression: full Phase-C
  (C1-C4d) + S2/S3/grid/pool/vrand(1324) green. Gate gate_73.

## Two real issues caught by lockstep (both fixed)
1. **>>>-in-unsigned-context logical-shift bug (the recurring gotcha).** `(p >>> 7) +
   {15'b0, inc}` made the whole expression unsigned, turning the arithmetic shift into
   a LOGICAL shift — negative products zero-filled into large positives and falsely
   saturated (idx=16: dut 0x7f vs spike 0xe0=-32). Fixed by computing the shift in a
   self-determined signed wire: `wire signed [15:0] sh = p >>> 7;` then `rnd = sh + inc`.
2. **Group-EMUL store green-wash.** The m2 smoke first used `vse32.v v8` under an m2
   vtype (EMUL=2, 32 bytes) — mem_illegal in the DUT (out of scope) but Spike executes
   it. The comparator truncates to DUT length, so the divergence "passed" while the m2
   vsmul result was never actually observed. Fixed by storing v8/v9 separately under m1.

## Gemini full-context review — verdict
**Completely clean, fully spec-compliant — no further RTL change.** Verified: (1) f6
disjointness + masked-v0 legality; (2) genuinely arithmetic shift (called out the fix);
(3) all four vxrm rounding increments; (4) saturation only on (-2^(SEW-1))^2 with vxsat
wired into part_sat_or + grp_sat_q for LMUL>1.
