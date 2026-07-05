# Phase-E E2 (segment stub) — three-way review + verification record (2026-07-05)

ADR-0058 §2 E2. vlseg<nf>/vsseg<nf> minimal stub (nf=2..8, EEW=SEW, LMUL=1, unmasked,
vstart=0, unit-stride). User-approved minimal scope after Grok flagged full segment as
a high-cost/high-green-wash-risk vmem-FSM rewrite.

## Legs
- **Spike probes (authority)**: vlseg2/3 deinterleave, vsseg2 re-interleave; encoding =
  unit-stride vle/vse with nf field bits[31:29]=nf-1.
- **Spike lockstep**: make e2 -> 90 commits bit-exact (vlseg2/3/4 loads, vsseg2/vsseg2e16
  stores, SEW 8/16/32, **partial-vl tail-undisturbed** case). vmem unit-stride regression
  stays 110 (non-segment FSM path unchanged); vrand(1324) green. Gate gate_78.

## Three-way review (Codex + Grok + Gemini)
- **Codex — found 1 real bug (fixed)**: segment loads corrupted TAIL lanes for vl<VLMAX.
  The unit-stride path seeds vm_buf<=vd_old, but the segment path drained the FULL 128-bit
  seg_buf (stale tail) to vd..vd+nf-1, so tail lanes got garbage instead of undisturbed.
  The directed test only observed active lanes (vse vl=4), MASKING it — exactly the
  green-wash Codex warned about. Fix: blend the drain byte-wise with the old field register
  vrf[vd+p] for bytes >= vl*EEW (seg_drain). Added a partial-vl (vl=2, VLMAX=8) test with a
  pre-colored destination tail, observed at VLMAX -> lockstep confirms the tail is preserved.
- **Grok — in-scope structurally correct**: address walk rs1+i*nf*EEW+f*EEW, store source
  vrf[vd_i+f] (vd_i is the vs3 field on stores), wstrb/lane, vd+nf<=32 bound. Did not catch
  the tail bug.
- **Gemini — API quota-blocked** this round.

Codex catching a tail-corruption green-wash on a risky FSM change is precisely why the
architect gated segment behind a minimal stub and why surgical review matters here.
