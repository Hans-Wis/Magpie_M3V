# Magpie_M1 Phase 1 Closure Report

Status: **phase1-structural-closure-pass / not CPU-qualified**

Date: 2026-06-07

## Scope

Phase 1 closes lab08e active RTL bring-up and structural productization for:

- active variant `v2_pipeline_ch2_lab08e`
- ISA target `RV32IMC_Zicsr_Zifencei`
- 4-stage pipeline with BP, RAS, RV32C, pre-fetch residue, forwarding, stalls,
  redirect recovery, CSR/IRQ hooks

Phase 1 closure means the RTL is integrated, lint-parsable, smoke-runnable, and
structurally checked against the active microarchitecture.

It does not mean the CPU IP is functionally qualified; the CPU IP must remain `not-yet-qualified`
until Phase 2 through Phase 5 evidence is produced and reviewed.

## Closed Phase 1 Gates

| Phase | Gate | Status | Evidence |
|---|---|---|---|
| 1.0 | pipeline reference | pass | lab08e copied, provenance recorded, Verilator lint-only |
| 1.1 | fetch/RV32C/pre-fetch | smoke-sim-pass | local firmware, `sim.log`, focused review `wave.vcd`, VCD manifest |
| 1.2 | decode/execute RV32IMC | structural-lint-pass | IDU/ALU/RFU/MUL/DIV/core structural checks, lint-only |
| 1.3 | pipeline hazard | structural-lint-pass | forwarding/stall/bubble/side-effect suppression checks, lint-only |
| 1.4 | BP/RAS/redirect | structural-lint-pass | BP/RAS/redirect priority/recovery checks, lint-only |
| 1.99 | Phase 1 closure | pass target | this report plus closure gate |

## VCD Review

Phase 1.1 is the only Phase 1 gate with simulation waveform evidence today. Its
VCD is intentionally focused, governed by:

- `docs/vcd_review_policy.md`
- `flow/v2_pipeline/phase_01_01_fetch_rv32c_prefetch/vcd_manifest.md`

The default waveform keeps top-level and wrapper-level review signals and avoids
full `u_core` hierarchy tracing. Full debug remains available with:

```sh
make clean
make TRACE_DEPTH=5 REVIEW_TRACE=0 RUN_ARGS=+full_vcd
```

Phase 1.2, 1.3, and 1.4 do not generate directed simulation VCDs yet. When
those directed sims are added, each must add a phase-local `vcd_manifest.md`
before the waveform is accepted as review evidence.

## Residuals Transferred Out Of Phase 1

| Residual | Target phase | Status |
|---|---|---|
| Directed RV32I/M/C execute tests | Phase 2/3 qualification path | not-run |
| Directed hazard and wrong-path assertion tests | Phase 2/3 qualification path | not-run |
| Directed BP/RAS/redirect tests | Phase 2/3 qualification path | not-run |
| CSR/trap/IRQ timing | Phase 2.0 | not-run |
| Magpie_M1 valid-ready memory wrapper | Phase 2.1 | not-run |
| Commit trace + Spike lockstep | Phase 3.0 | not-run |
| Google RISC-V DV | Phase 3.0 after deterministic directed path | not-run |
| Line coverage 100% or line-by-line reasons | Phase 4.0 | not-run |
| Lint/synth/FPGA PPA sign-off | Phase 5.0 | not-run |

## Closure Decision

Phase 1 can close as **structural bring-up complete** when the closure gate
passes. The CPU IP must remain `not-yet-qualified` until Phase 2 through Phase 5
evidence is produced and reviewed.
