# `dv/` — Design-Quality Verification (coverage · lint · CDC/RDC)

This tree holds the **design-quality** verification of Magpie_M3V — did we exercise the
RTL structurally, and is it structurally clean — as distinct from:
- **functional** verification (does it compute the right answer) → `sim/` + `tests/gates/`,
- **basic-circuit** unit tests → `tests/gates/` (see the repo layout).

> Authority note (G1): coverage is **completeness** evidence, not correctness — every
> number here is backed by a Spike-lockstep / bit-exact test elsewhere. `not-run` stays
> `not-run`; nothing is green-washed.

## Layout

| Path | What | Status |
|---|---|---|
| `dv/coverage/` | **Instruction + code coverage** (ADR-0063 V1+V5, frozen) | ✅ done |
| `dv/coverage/isa_cov.py` · `isa_scope.json` · `collect.sh` · `isa_cov_report.json` | ISA coverage: Spike-log ingester + SSOT + report. gate: `gate_90` | ✅ RV32IMC 100%, Zve32x non-seg 100% |
| `dv/coverage/verilator/` | Code coverage: `run_cov.sh` (5-DUT), `combine_cov.py`, `codecov_report.json`. gate: `gate_91` | ✅ line 77% |
| `dv/fixtures/` | shared DV fixtures | — |
| `dv/lint/` | **Spyglass lint** (M3V) — ADR-0063 **V2**, extends ADR-0006 lint contract to npu/RVV/mat | ⏳ pending (V2) |
| `dv/cdc_rdc/` | **CDC / RDC / X-prop** (M3V) — ADR-0063 V2; single-clock ⇒ RDC-focus (`domain_rstn`, ADR-0047) | ⏳ pending (V2) |

## How to run (coverage)

```bash
# instruction coverage (Spike logs across the regression -> ISA gap report)
dv/coverage/collect.sh
# code coverage (5-DUT Verilator line+toggle -> per-file report)
dv/coverage/verilator/run_cov.sh
# gates (fast, read the committed baselines)
pytest tests/gates/gate_90_isa_coverage.py tests/gates/gate_91_verilator_codecov.py
```

## Not-yet-migrated (honest)

The M1-era Spyglass lint (`flow/v2_pipeline/phase_05_00_lint/`, gated by
`gate_05_00_lint`) and CDC/x-prop (`flow/v2_pipeline/phase_p_cdc_rdc_xprop/`) are **M1
legacy** (their filelists reference M1 modules and use flow-relative paths). They are NOT
migrated here — the M3V lint/CDC/RDC signoff is **ADR-0063 V2** and lands in `dv/lint/` +
`dv/cdc_rdc/` when done (V2 has one prep item already: a `vexu.v` WIDTHEXPAND was cleared).

## GitHub-readiness note

Repo hygiene debt (Stage 4 de-vendoring): generated logs in `flow/v2_pipeline/phase_*`
(`spike.log`, `sim.log`, `firmware.hex`) are historically tracked and should be gitignored;
external-PDK links (`Magpie_X3`/`X6`) in the DC/APR flow must be isolated before public.
