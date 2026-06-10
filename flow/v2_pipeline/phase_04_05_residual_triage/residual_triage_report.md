# Phase 4.5 Residual Coverage Triage

Status: residual-triage-pass

Source coverage: `flow/v2_pipeline/phase_04_04_illegal_munit_coverage/coverage`

## Coverage Status

- DUT line coverage: 1035 / 1054 = 98.20%
- DUT uncovered lines: 19
- DUT toggle coverage: 8235 / 12246 = 67.25%
- Functional coverage: not implemented; coverplan-required.
- Coverage closure status: not closed.

## Residual Category Counts

| Category | Count |
| --- | ---: |
| alu_default | 1 |
| branch_unsigned_and_default | 2 |
| csr_explicit_write_mepc_mcause | 2 |
| csr_high_counters | 2 |
| csr_write_default | 1 |
| decode_default_alu_op | 2 |
| div_fsm_default | 1 |
| fence_decode | 1 |
| ras_mispredict_recovery | 4 |
| ras_push_edge | 3 |

## Waiver Status

| Waiver | Count |
| --- | ---: |
| none | 14 |
| waiver-candidate | 5 |

No waiver is approved by this phase. `waiver-candidate` means the line is a plausible defensive/default path, but owner approval is still required.

## Next Closure Actions

- Add directed RAS mispredict and RAS pointer edge coverage.
- Add directed CSR high-counter and explicit mepc/mcause/default-write coverage or waivers.
- Add directed FENCE/FENCE.I and unsigned branch decode coverage.
- Add SVA/FSM assertion or waiver for defensive default states.
- Build functional coverage bins and close or waive them.
