# P03 LSU Unit Coverage Summary

- TB: `IP/cpu_m1/dv/tb/tb_lsu_unit.v`
- DUT scope: `IP/cpu_m1/rtl/lsu.v` only
- Vector result: `PASS: lsu unit 431/431 vectors`

## Verilator

- Command: `make -C flow/v2_pipeline/phase_p03_lsu verilator`
- Coverage data: `coverage/coverage.dat`
- LCOV info: `coverage/coverage.info`
- Source-line coverage for `lsu.v`: 43/43 executable DA records, 100.00%
- Raw toggle coverage for `lsu.v`: 396/396 toggle records, 100.00%
- `funct3` default load arm: covered, annotated `lsu.v` line 106 count 12
- `funct3` default store arm: covered, annotated `lsu.v` lines 70-72 count 236

## VCS / URG

- Command: `make -C flow/v2_pipeline/phase_p03_lsu urg`
- URG report: `vcs/urgReport/mod1.html`
- Branch coverage for module `lsu`: 19/19, 100.00%
- Condition/expression coverage for module `lsu`: 4/4, 100.00%
- VCS toggle coverage for module `lsu`: 396/396, 100.00%

## Tier-2 Delta

All measured LSU DUT metrics meet or exceed Tier-2 targets:

- line: target 100%, measured 100.00%
- branch: target 100%, measured 100.00%
- expr/cond: target >=95%, measured 100.00%
- toggle: target >=95%, measured 100.00%

Do not mark this gate green here; Claude owns final approval.
