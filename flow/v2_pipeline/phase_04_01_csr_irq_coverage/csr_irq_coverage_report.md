# Phase 4.1 CSR/IRQ Directed Coverage Delta

Status: coverage-delta-pass

Base coverage: `flow/v2_pipeline/phase_03_06_multi_seed_coverage/coverage`

Directed coverage: `flow/v2_pipeline/phase_04_01_csr_irq_coverage/coverage.dat`

Merged coverage: `flow/v2_pipeline/phase_04_01_csr_irq_coverage/coverage/coverage.info`

## DUT Coverage Delta

| Metric | Base | Merged | Delta | Target | Status |
| --- | ---: | ---: | ---: | ---: | --- |
| Line | 1207/2071 (58.28%) | 1329/2071 (64.17%) | +122 lines | 100% | not-closed |
| Toggle | 9096/20356 (44.68%) | 9565/20356 (46.99%) | +469 toggles | >=85% | not-closed |
| Functional | not implemented | not implemented | 0 bins | >=95% | coverplan-required |

## CSR Module Delta

| Metric | Base | Merged | Delta |
| --- | ---: | ---: | ---: |
| CSR line | 88/278 (31.65%) | 131/278 (47.12%) | +43 lines |
| CSR toggle | 403/3772 (10.68%) | 567/3772 (15.03%) | +164 toggles |

## Directed Behavior Checked

- CSR write/set/clear on `mscratch`.
- Unknown CSR read returns zero.
- `cycle` and `instret` counters are non-zero.
- External IRQ pulse can set `mip.MEIP` while global MIE is disabled.
- Enabling global MIE takes the pending external IRQ.
- Handler observes external interrupt `mcause`, trap-entry `mstatus`, and returns through `mret`.

## Remaining Closure

Coverage is still not closed. Continue with BP/RAS loop/call-return directed coverage, RV32C decode corner coverage, M-unit corner merge, and functional cover bins.
