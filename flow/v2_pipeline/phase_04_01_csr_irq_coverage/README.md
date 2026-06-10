# Phase 4.1 - CSR/IRQ Directed Coverage Closure

Purpose: add targeted CSR/IRQ stimulus to the Phase 3.6 multi-seed coverage
baseline and report DUT-only line/toggle coverage delta.

This phase targets the highest-risk uncovered bucket from Phase 4.0:
`csr_irq_trap`.

Run:

```sh
make -C flow/v2_pipeline/phase_04_01_csr_irq_coverage -B csr_irq_coverage.log
python -m pytest tests/gates/gate_04_01_csr_irq_coverage.py
```

Directed behavior:

- CSR write/set/clear on `mscratch`
- unknown CSR read returns zero
- `cycle` and `instret` counters increment
- external IRQ pulse sets `mip.MEIP` while global MIE is disabled
- enabling global MIE takes the pending external IRQ
- handler observes `mepc`, external IRQ `mcause`, trap-entry `mstatus`, and
  returns through `mret`

Coverage accounting:

- Sign-off headline is DUT-only; testbench coverage is excluded.
- Phase 4.1 merges its `coverage.dat` with Phase 3.6
  `coverage/merged_coverage.dat`.
- This phase is coverage closure progress, not coverage closure.

Outputs:

- `sim.log`
- `coverage.dat`
- `coverage/merged_with_phase_04_01.dat`
- `coverage/coverage.info`
- `module_delta.csv`
- `csr_irq_coverage_report.md`
- `wave.vcd`
