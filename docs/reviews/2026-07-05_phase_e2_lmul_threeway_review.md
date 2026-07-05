# Phase-E E2 (segment) LMUL>1 extension — three-way review (2026-07-05)

Extended the segment stub from LMUL=1 to LMUL m1/m2/m4 (EMUL register groups) so the
compiler's actual `vlseg2e8@m2` emission runs. ADR-0058 §2 E2.

## Motivation (empirical)
User asked whether the two compiler-emitted Phase-E ops are covered. Re-checking the
autovectorized TFLM kernels: BOTH emit at LMUL=m2 (`vdiv.vv @ e32 m2`, `vlseg2e8.v @ e8
m2`). vdiv was already covered (beats_op, m2 verified in gate_77). The segment STUB was
LMUL=1 only -> the compiler's m2 vlseg was NOT covered (DUT trapped it). User chose to
extend segment to LMUL>1.

## Design
Field f occupies L registers {vd+f*L .. vd+f*L+L-1}; element i -> physical register
offset p = f*L + i/epr, lane = i%epr (epr = 16>>vsew). seg_bufi = (seg_fld<<log2L) +
i/epr. Load captures into seg_buf[seg_bufi]; drain writes nf*L registers with a
per-register tail blend (reg-in-group r = p&(L-1); active bytes = clamp(vl - r*epr, 0,
epr)*EEW). vm_idx widened to [5:0] (VLMAX up to 64).

## Verification
make e2 -> 147 commits bit-exact: LMUL=1 (nf 2/3/4, SEW 8/16/32), **vlseg2e8@m2** (the
compiler emission), @m4, partial-vl across a group boundary (per-register tail blend),
vsseg@m2, and an unaligned-vd (vlseg2e8@m2 vd=v1) illegal terminator. vmem unit-stride
regression stays 110; vrand(1324) green. Gate gate_78.

## Three-way review (Codex + Grok + Gemini)
- **Codex — found 1 real bug (fixed)**: seg_ok was missing the register-group ALIGNMENT
  check. For m2/m4 each field is an L-register group, so vd must be L-aligned; my legality
  only checked vd+nf*L<=32. vlseg2e8@m2 vd=v1 (unaligned) executed in the DUT while Spike
  traps it (Spike-confirmed) -- a green-wash hole (my tests used aligned vd=v8). Fix: add
  (vd_i & (L-1))==0 to seg_ok; changed the terminator to the unaligned case (both trap now).
  Codex's 3rd catch this phase (D2 fractional, E2-stub tail, E2-m2 alignment).
- **Grok — confirmed the rest correct**: seg_bufi/lane, per-register tail blend (incl the
  straddling register), drain count nf*L, store source, byte walk, vm_idx[5:0] non-seg
  safety. Its "drain-width" note resolved: the check-then-increment order means vmvr_p
  never exceeds 7.
- **Gemini — API quota-blocked**.
