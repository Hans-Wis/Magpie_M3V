# Phase-D D1b (vmsbf/vmsof/vmsif + viota) — review + verification record (2026-07-05)

ADR-0057 §4 D1b. vmsbf.m/vmsof.m/vmsif.m (mask dest) + viota.m (vector dest).

## Legs
- Grok arch (docs/reviews/2026-07-05_phase_d_plan_grok.md). **Its "vms* vd==v0 always
  illegal" claim was empirically WRONG** — Spike executed vmsif.m v0,v2 (unmasked,
  vd==v0) fine; vms* are treated like compares (mask-dest, vd==v0 legal).
- Spike golden: mask {2,3,6} -> vmsbf 0x03 / vmsif 0x07 / vmsof 0x04 / viota
  [0,0,0,1,2,2,2,3]; masked v0={3,6,7} (active-set {3,6}) -> viota vd[3,6,7]=0,1,2;
  empty mask -> vmsbf/vmsif all 1s, vmsof/viota all 0.
- Spike lockstep: make d1b -> 67 commits bit-exact (all 4 ops, masked/unmasked/empty,
  viota at SEW 8/16/32, viota@vstart!=0 illegal terminator). Regression full vector
  suite incl b3(mask_dest)/s1(compares)/pool/vrand(1324) green. Gate gate_75.

## Implementation note
One always@* scan over mbits[i]=(i<vl)&vs2_data[i]&(vm||v0_data[i]); run/preset track
count/any-set in [0,i). vms_raw = vmsbf?~(preset|mbits[i]) : vmsif?~preset :
(~preset&mbits[i]); viota_pk[i]=count before i. vms bits route via seg8/16/32 into the
existing compare mask_dest res_cmp path (op_vms added to mask_dest); viota via res_viota
per SEW into q_wdata. m1-only (grp_only_illegal), vstart!=0 illegal (global), masked
viota writing v0 illegal.

## Gemini review — fully clean, no RTL change
Verified all 6: (a) vmsbf/vmsif/vmsof prefix logic incl the no-set-bit case (vmsbf/vmsif
all 1s, vmsof all 0 — matches spec, my RTL correct); (b) viota prefix count (masked
skips inactive), 5-bit run no overflow; (c) vms mask-dest (vd==v0 ok) vs viota
vector-dest (masked-vd0 illegal); (d) m1-only + vstart + masked-viota-v0; (e) latch-free;
(f) SEW slicing of viota counts + vms mask bits.
