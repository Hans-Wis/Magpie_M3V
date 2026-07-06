# `gates/` — basic-circuit gates

Fast, deterministic **basic-circuit** verification: core-unit RTL structure and the scalar
RV32IMC pipeline (identity, decode/execute, hazard/forward, BP/RAS, trap, ALU/LSU/mul/div/CSR
units, lint, PPA). One `gate_NN_*.py` per bring-up stage.

This is the "does the basic circuit hold" tier. The other two gate homes are separate concerns:

| Home | Concern |
|---|---|
| `gates/` (here) | basic-circuit / core-unit / scalar-pipeline structure |
| [`sim/gates/`](../sim/gates/) | **system-functional** — NPU/AXI/CQ, RVV vector, mat-engine, TFLM/MobileNet/MLPerf/Gemma e2e |
| [`dv/gates/`](../dv/gates/) | **coverage** — ISA + Verilator code coverage (ADR-0063) |

Run a gate directly (they are `gate_*.py`, not pytest's default `test_*.py`, so pass the file):

```bash
python3 -m pytest gates/gate_00_identity_m3v.py -q
```

Note: some gates here are inherited from the `Magpie_M1` baseline snapshot and assert on M1-era
RTL signal names / identity fields the M3V parameterized core (ADR-0032) has evolved past — those
are known-stale and tracked for cleanup (see `EXTERNAL_DEPS.md` §5), not portability regressions.
