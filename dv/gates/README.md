# `dv/gates/` — coverage gates

The **coverage** gates (ADR-0063), co-located with `/dv` because they assert the coverage
baselines produced under [`dv/coverage/`](../coverage/):

| Gate | Asserts |
|---|---|
| `gate_90_isa_coverage.py` | instruction coverage: RV32IMC 100%, Zve32x non-segment op-forms 100%, exclusion ledger frozen |
| `gate_91_verilator_codecov.py` | Verilator line+toggle code coverage on the owned datapath (vexu/fexu/mat/bmu/…) |

Authority note (G1): coverage is **completeness**, not correctness — every number is backed by a
Spike-lockstep / bit-exact test elsewhere.

```bash
python3 -m pytest dv/gates/gate_90_isa_coverage.py dv/gates/gate_91_verilator_codecov.py -q
```
