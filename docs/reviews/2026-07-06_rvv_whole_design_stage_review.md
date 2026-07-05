# RVV Zve32x whole-design STAGE review (Grok + Codex) — 2026-07-06

Holistic cross-cutting review of the entire RVV Zve32x implementation in vexu.v (1769
lines, Phase A-E), complementing the per-slice reviews. Baseline: all 29 lockstep
targets pass vs Spike --isa=rv32imf_zve32x_zvl128b (~3300 commits, 0 fail) at 4c96ca6.

## Implemented surface (Phase A-E)
Config/CSR; unit-stride vle/vse 8/16/32 (EEW!=SEW); vmv.x.s/.s.x/vmerge/vmv.v.*/vmv<nr>r;
int ALU (add/sub/rsub, bitwise, shifts, min/max, compares, mask logicals); sat/avg/scale
(vsadd/vssub/vaadd/vasub/vssrl/vssra/vnclip, vxsat/vxrm); narrow/ext (vnsrl/vnsra, vzext/
vsext); carry (vadc/vsbc/vmadc/vmsbc); mul (vmul/vmulh*); MAC (vmacc/vnmsac/vmadd/vnmsub);
vsmul; reductions (vredsum/and/or/xor/minu/min/maxu/max); widening full (vwadd/vwsub/vwmul/
vwmacc/vwredsum families); mask-scan (vid/vcpop/vfirst/vmsbf/vmsof/vmsif/viota); slides
(vslideup/down, vslide1up/down); vrgather.vv/.vx/.vi; divide (vdivu/vdiv/vremu/vrem);
segment (vlseg/vsseg m1/m2/m4 EMUL groups). LMUL: m1 + m2/m4 groups (beats_op) + fractional.

## Verdict: no concrete correctness bug found; design is coherent
Both reviewers independently concluded the whole design is coherent:
- **Decode aliasing — clean.** Every shared f6 (100111, 001110/001111, 010000, 100000-
  100011, 100101, 101101/101111, 000000, 110000/110001) is disjoint by f3 class (+ vm /
  vs1 / vs2 sub-decode). No two ops alias; no valid in-scope op falls to !known_op.
- **known_op vs result routing — complete.** Every vector-writing known_op routes via an
  explicit q_wdata arm, mask_dest, group staging, or the default same-width res8/16/32.
  (My own mechanical check confirmed: the 10 ops without an explicit arm all reach the
  default path or op_widen.) Scalar-dest (vmv.x.s/vcpop/vfirst) and local-FSM ops
  (vmvr/segment) are correctly excluded from q_vrf_we.
- **beats_op / mask_dest / masked-vd0 / q_grp_w — coherent.** m1-only scope-cuts
  (reductions, mask-scan D1, slides, vrgather) form an intentionally-stricter-than-Spike
  profile that TRAPS (grp_only_illegal), not garbage. masked-vd0 covers every vector body
  op; the "missing" ones are mask-dest / scalar-dest / forced-vm=1 / local-FSM / m1-scope.

## Cross-cutting VERIFY items — all checked CLEAN
- **vzext/vsext (op_vext)**: in known_op + routed in q_wdata. OK.
- **vrgatherei16 (f6=001110 OPIVV)**: matches neither op_vslideup (opivx/opivi) nor
  op_vrgather (f6=001100) -> correctly !known_op -> illegal. Deferred, NOT partial-decoded.
- **vse @ vstart!=0**: Spike-probed RESUMES (stored elements 2,3); the vmem FSM starts at
  vm_vstart -> also resumes. No mismatch (Grok's concern unfounded).
- **LONG-STANDING LATENT RESOLVED — vle32.v @ e32/mf2**: Spike traps it (illegal vtype:
  LMUL < SEW/ELEN sets vill); the DUT ALSO traps it. A 12-commit lockstep on the exact
  sequence matched (both stop at the same pc). It was NEVER a bug — both trap via vill.

## Applied fixes (both safe cleanups, lockstep re-verified)
1. **idu.v scalar-rd gating**: opv_vwx0 gated on is_op_v (not is_vexec, which also covers
   LOAD-FP/STORE-FP) so an illegal mem encoding with f3=010 & f6=010000 cannot assert
   scalar rd_we. Squashed by the trap today, but a cleaner classification (Codex).
2. **Stale segment scope comment** (vexu.v): updated from "LMUL=1 stub" to the actual
   m1/m2/m4 EMUL-group scope.

## Residual technical debt (documented, not bugs)
- Combinational per-element divide (timing deviation; real HW would sequence it — F4 class).
- Local-FSM VRF writers (vmv<nr>r.v, segment loads) rely on the drained-start / no-mid-op-
  flush invariant (core issues m_start only when the pipeline behind is empty).
- m1-only scope-cuts (reductions/mask-scan/slides/vrgather at m2/m4 trap; Spike executes).
- Deferred: vrgatherei16, vcompress, indexed/strided memory, fault-only-first, m8 arith,
  masked reductions, segment EEW!=SEW/masked. All trap (honest, not silent).
