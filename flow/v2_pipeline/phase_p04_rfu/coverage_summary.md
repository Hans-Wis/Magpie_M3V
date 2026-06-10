# P04 RFU Unit Coverage Summary

- TB: `IP/cpu_m1/dv/tb/tb_rfu_unit.v`
- DUT scope: `IP/cpu_m1/rtl/rfu.v` only
- Vector result: `PASS: rfu unit 10613/10613 vectors`
- Token record: no active Codex goal token budget was available from `get_goal`

## Verilator

- Command: `make -C flow/v2_pipeline/phase_p04_rfu verilator`
- Coverage data: `coverage/coverage.dat`
- LCOV info: `coverage/coverage.info`
- Toggle-only LCOV info: `coverage/coverage_toggle.info`
- Source-line coverage for `rfu.v`: 8/8 executable DA records, 100.00%
- Raw toggle coverage for `rfu.v`: 226/226 toggle records, 100.00%
- x0 read returns zero: covered on both read ports
- x0 write suppression: covered by writes to `rd_idx == 0`
- Read-during-write same-index behavior: covered as old value before the write edge, new value after the write edge
- Register-array write diversity: x1..x31 written with zero/all-ones, alternating, walking-1, and walking-0 patterns; no uncovered register-array bit was reported

## VCS / URG

- Command: `make -C flow/v2_pipeline/phase_p04_rfu urg`
- URG report: `vcs/urgReport/mod1.html`
- Branch coverage for module `rfu`: 6/6, 100.00%
- Condition/expression coverage for module `rfu`: 13/13, 100.00%
- VCS toggle coverage for module `rfu`: 226/226, 100.00%

## Tier-2 Delta

All measured RFU DUT metrics meet or exceed Tier-2 targets:

- line: target 100%, measured 100.00%
- branch: target 100%, measured 100.00%
- expr/cond: target >=95%, measured 100.00%
- toggle: target >=95%, measured 100.00%

Do not mark this gate green here; final approval is owned by the gate reviewer.
