## summary
PASS(>=100k): 114216 total matched commits vs Spike across 10 seeds.

## divergences
None. No seed produced a DUT/Spike mismatch; no divergence artifact was generated.

## throughput
84.35 commits/sec; simulator Verilator; wall-clock 1354.00 sec.

## gate_status
`pytest -q tests/gates/gate_03_09_riscvdv_lockstep.py`: 3 passed. Explicit full gates: `pytest -q $(find tests/gates -maxdepth 1 -type f -name 'gate_*.py' | sort)`: 180 passed. gate_03_09 verdict PASS.

## provenance
Seeds 2026060801..2026060810 from command: `python3 flow/v2_pipeline/phase_03_09_riscvdv_lockstep/run_riscvdv_lockstep.py --start-seed 2026060801 --seeds 120 --instr-cnt 20000 --target-commits 100000 --max-cycles 10000000`.

## tokens
Not available from local runtime/API telemetry.
