# Phase-C C2 (integer MAC) — review + verification record (2026-07-05)

Instrs: `vmacc` `vnmsac` `vmadd` `vnmsub` (Zve32x). ADR-0056 §5 C2.

## Legs
- **Grok (architecture)**: `docs/reviews/2026-07-05_phase_c_plan_grok.md` §3 — operand roles
  (vmacc/vnmsac multiplicands vs1,vs2 + addend old-vd; vmadd/vnmsub multiplicands vs1,old-vd
  + addend vs2), vd-overlap legal/required. Implementation matches exactly.
- **Spike golden probe**: vd=10,vs1=3,vs2=5 -> vmacc=25, vnmsac=-5, vmadd=35, vnmsub=-25.
  Encodings disassembled: 101101/101111/101001/101011. RTL matched every element.
- **Spike lockstep**: `make c2` -> 154 commits bit-exact (4 MAC x vv/vx x SEW 8/16/32,
  explicit vd==vs1 and vd==vs2 overlap cases that must not trap, e32/m2 group smoke,
  masked-vmacc-writing-v0 illegal terminator). Regression: 12 vector targets green incl
  grid/pool/vrand(1324). Gate gate_68.

## Implementation note
Dedicated per-SEW loops: a=vs2, b=(opmvv?vs1:rs1), d=vd_old; prod_ab=a*b (vs1*vs2),
prod_db=d*b (vs1*vd), both SEW-truncated. r = vmacc?d+prod_ab : vnmsac?d-prod_ab :
vmadd?prod_db+a : a-prod_db. Low SEW bits are sign-agnostic (two's complement). vd is
the accumulator read via vd_old; no generic overlap illegality is applied, so vd==vs1/
vs2 stays legal. Joins beats_op so m2/m4 groups iterate via VM_GRP + atomic WB (each
part reads its own pre-commit vd_old — nr-aligned groups are equal-or-disjoint).

## Gemini full-context review — verdict
**Clean, fully compliant — no RTL change from review.** Verified: (a) operand roles
match the spec per instr; (b) low-SEW truncation sign-agnostic; (c) group-path vd_old
reads correct (aligned groups equal-or-disjoint, no cross-element dependency); (d)
OPMVV vs1 / OPMVX rs1 operand select.
