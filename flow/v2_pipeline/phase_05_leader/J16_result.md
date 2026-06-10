## summary
TOTAL matched commits: 103,766; seeds: 31 (`2026061601..2026061631`); verdict: PASS>=100k.

## scope
Included: RV32I arithmetic/logical/compare/shift, RV32C compressed, load/store, branch/jump, RV32M multiply/divide, M-mode supported CSR instructions.
Documented excluded: random sync-trap-stream (`ECALL`/`EBREAK`/illegal), interrupts. Also excluded by generator scope: riscv-dv SYNCH/fence stream, unaligned load/store, A/F/D/V, unsupported privileged behavior.
Timing CSRs remain comparator-excluded, not faked.

## divergences
none. Summary JSON has `divergences=[]` and `unresolved_real_dut_divergences=0`; `flow/v2_pipeline/phase_03_09_riscvdv_lockstep/divergence/` is absent after the J16 run reset.

## throughput
55.33 commits/sec; wall-clock 1,875.46 sec (31.26 min).
Run log: `flow/v2_pipeline/phase_03_09_riscvdv_lockstep/J16_fullmix_run.log`.
Summary: `flow/v2_pipeline/phase_03_09_riscvdv_lockstep/riscvdv_lockstep_summary.json`.

## gate_status
`python3 -m pytest tests/gates/gate_*.py -q`: PASS, 180 passed in 11.19s. `gate_03_09` verdict: PASS from J16 JSON/result criteria.

## tokens
not metered by local tooling.
