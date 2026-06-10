# P02 ALU Unit Coverage Summary

- TB: `IP/cpu_m1/dv/tb/tb_alu_unit.v`
- DUT scope: `IP/cpu_m1/rtl/alu.v` only
- Vector result: `PASS: alu unit 382/382 vectors`

## Verilator

- Command: `make -C flow/v2_pipeline/phase_p02_alu verilator`
- Coverage data: `coverage/coverage.dat`
- LCOV info: `coverage/coverage.info`
- Source-line coverage for `alu.v`: 31/31, 100.00%
- Raw toggle coverage for `alu.v`: 542/542, 100.00%
- Line 67 default arm: covered, LCOV `DA:67,2`

## VCS / URG

- Command: `make -C flow/v2_pipeline/phase_p02_alu urg`
- URG report: `vcs/urgReport/mod0.html`
- Branch coverage for module `alu`: 13/13, 100.00%
- Condition/expression coverage for module `alu`: 2/2, 100.00%
- VCS toggle coverage for module `alu`: 542/542, 100.00%

## Tier-2 Delta

All requested ALU DUT metrics meet or exceed Tier-2 targets:

- line: target 100%, measured 100.00%
- branch: target 100%, measured 100.00%
- expr/cond: target >=95%, measured 100.00%
- toggle: target >=95%, measured 100.00%

No uncovered ALU DUT points remain in these reports.
