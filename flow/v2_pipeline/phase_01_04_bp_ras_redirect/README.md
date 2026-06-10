# Phase 1.4 BP / RAS / Redirect

Status: structural-lint-pass target, not yet directed-sim-qualified.

This phase fixes the first Magpie_M1-owned predictor and redirect contract for
the active Ch2 lab08e target:

- 64-entry 2-way branch predictor structure
- 2-bit saturating counter update and LRU replacement
- RV32C-aware BP indexing with `PC[1]`
- JALR exclusion from BP update
- RAS top/push/pop behavior
- 32-bit and 16-bit return prediction trigger
- RAS target mismatch recovery
- redirect priority: IRQ, MRET, RAS target mismatch, BP direction mismatch
- redirect target selection for branch/JAL/JALR/not-taken recovery
- prefetch residue and pipeline flush interaction on redirect

Current evidence:

- `tests/gates/gate_01_04_bp_ras_redirect.py`
- Verilator lint-only on local lab08e RTL top `core`

Not yet closed:

- Directed BP taken/not-taken update tests
- Directed RAS call/return and mismatch tests
- Directed JALR recovery tests
- VCD-reviewed predictor/redirect cases
- Line/toggle/functional coverage
- Spike lockstep

VCD policy note:

- This structural phase does not generate a VCD.
- When directed predictor simulation is added, create a phase-local
  `vcd_manifest.md` following `docs/vcd_review_policy.md` before treating the
  waveform as review evidence.
