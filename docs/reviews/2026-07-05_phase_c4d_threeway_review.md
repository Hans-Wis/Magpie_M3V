# Phase-C C4d (widening sum reduction) — review + verification record (2026-07-05)

Instrs: `vwredsum` `vwredsumu` `.vs` (Zve32x). ADR-0056 §5 C4d.

## Legs
- **Spike golden probe (encoding + authority)**: OPIVV f6=110000 vwredsumu / 110001
  vwredsum (disjoint from OPMVV vwaddu/vwadd by f3). seed=3 vs2={5,-1,127,-128} ->
  vwredsum 6, vwredsumu 518.
- **Spike lockstep**: `make c4d` -> 39 commits bit-exact (vwredsum/vwredsumu x SEW 8/16
  over signed/unsigned data so vwredsum != vwredsumu; vwredsum-at-vstart!=0 illegal
  terminator). Regression: c4a/b/c + c1/c2/c3 + vwide/pool/kernel/grid/vrand(1324)
  green. Gate gate_72.

## Implementation note
Separate res_wred block (the C3 narrow reduction couldn't be reused — seed is 2*SEW,
vs2 extends SEW->2*SEW). 32-bit accumulator: seed = SEW8? ext(vs1_data[15:0]) :
vs1_data[31:0]; each vs2 element sign/zero-extends to 32 per op; commit
wred_acc[2*SEW-1:0]. wred_illegal on SEW32 (2*SEW=64, no e64). op_wred in known_op +
grp_only_illegal (m2/m4 deferred); vstart!=0 via the global rule; vm=1 only.

## Gemini full-context review — findings + disposition
- **Rank 1 "critical always @flow/... syntax bug" — FALSE POSITIVE (recurring).**
  Gemini misread the diff text; the actual RTL (vexu.v:941) is `always @* begin`, which
  is why Verilator lint AND the 39-commit lockstep both pass (a broken sensitivity list
  would not compile). No change. (Same hallucination it produced on C3.)
- **Spec checks (a)-(f) all clean.** Verified seed width/extension, vs2 sign/zero
  extend, loop bounds, 2*SEW commit slice, OPIVV/OPMVV disjointness, no-latch.
