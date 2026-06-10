# Phase 4.7 CSR/IDU Residual Coverage Delta

Status: coverage-delta-pass

Base coverage: `flow/v2_pipeline/phase_04_06_ras_recovery_coverage/coverage`

Directed coverage: `flow/v2_pipeline/phase_04_07_csr_idu_residual_coverage/coverage.dat`

Merged coverage: `flow/v2_pipeline/phase_04_07_csr_idu_residual_coverage/coverage/coverage.info`

## DUT Coverage Delta

| Metric | Base | Merged | Delta | Target | Status |
| --- | ---: | ---: | ---: | ---: | --- |
| Line | 1363/1432 (95.18%) | 1374/1432 (95.95%) | +11 lines | 100% | not-closed |
| Toggle | 12733/20252 (62.87%) | 12745/20252 (62.93%) | +12 toggles | >=85% | not-closed |
| Functional | not implemented | not implemented | 0 bins | >=95% | coverplan-required |

## Target Module Delta

| Module | Line Base | Line Merged | Line Delta | Toggle Base | Toggle Merged | Toggle Delta |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| csr.v | 114/137 (83.21%) | 122/137 (89.05%) | +8 | 543/2518 (21.56%) | 553/2518 (21.96%) | +10 |
| idu.v | 87/92 (94.57%) | 90/92 (97.83%) | +3 | 598/682 (87.68%) | 600/682 (87.98%) | +2 |

## Directed Behavior Checked

- Direct CSR stimulus reads `cycleh` and `instreth` high-counter mux arms.
- Direct CSR stimulus explicitly writes and reads back `mepc` and `mcause`.
- Direct CSR stimulus writes an unsupported CSR and confirms the default write path ignores it.
- Direct IDU stimulus decodes `FENCE`, `FENCE.I`, `BLTU`, `BGEU`, and a reserved branch funct3 default case with `illegal=1`.

## Remaining Closure

Coverage is still not closed. Remaining line residuals are defensive defaults (`alu.v` unknown ALU op, `div.v` FSM default, selected decode defaults) plus toggle and functional coverage targets. These need assertion/waiver review and functional cover bins rather than more architectural directed tests.
