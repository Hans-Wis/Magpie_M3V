# Phase 4.1 CSR/IRQ Directed Coverage Delta

Status: coverage-delta-pass

Base coverage: `flow/v2_pipeline/phase_03_06_multi_seed_coverage/coverage`

Directed coverage: `flow/v2_pipeline/phase_04_01_csr_irq_coverage/coverage.dat`

Merged coverage: `flow/v2_pipeline/phase_04_01_csr_irq_coverage/coverage/coverage.info`

## DUT Coverage Delta

| Metric | Base | Merged | Delta | Target | Status |
| --- | ---: | ---: | ---: | ---: | --- |
| Line | 818/1054 (77.61%) | 1214/1432 (84.78%) | +396 lines | 100% | not-closed |
| Toggle | 7500/12246 (61.24%) | 10738/20252 (53.02%) | +3238 toggles | >=85% | not-closed |
| Functional | not implemented | not implemented | 0 bins | >=95% | coverplan-required |

## CSR Module Delta

| Metric | Base | Merged | Delta |
| --- | ---: | ---: | ---: |
| CSR line | 43/137 (47.25%) | 117/137 (85.40%) | +74 lines |
| CSR toggle | 208/2518 (16.15%) | 473/2518 (18.78%) | +265 toggles |

## Directed Behavior Checked

- CSR write/set/clear on `mscratch`.
- Unknown CSR read returns zero.
- `cycle` and `instret` counters are non-zero.
- External IRQ pulse can set `mip.MEIP` while global MIE is disabled.
- Enabling global MIE takes the pending external IRQ.
- Handler observes external interrupt `mcause`, trap-entry `mstatus`, and returns through `mret`.

## Remaining Closure

Coverage is still not closed. Continue with BP/RAS loop/call-return directed coverage, RV32C decode corner coverage, M-unit corner merge, and functional cover bins.
