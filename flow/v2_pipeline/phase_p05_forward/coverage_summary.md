# P05 Forward Unit Coverage Summary

- TB: `IP/cpu_m1/dv/tb/tb_forward_unit.v`
- DUT scope: `IP/cpu_m1/rtl/forward.v` only
- Vector result: `PASS: forward unit 1404/1404 vectors`
- Token record: no active Codex goal token budget was available from `get_goal`

## Test Content

- Independent golden model computes the forwarding truth table from raw predicates, separate from DUT internals.
- Covered for both `rs1` and `rs2`: no match, EX/MEM match, EX/WB match, both match with EX/MEM priority, match with write-enable deasserted, match to `x0`, and EX/MEM load no-forward behavior.
- `forward.v` has no explicit fwd-valid output ports; the TB asserts the observable selected operand values.
- Forwarded EX/MEM data, EX/WB data, RFU fallback data, register indexes, valid/write-enable bits, and load bits are driven through distinct toggling patterns.

## Verilator

- Command: `make -C flow/v2_pipeline/phase_p05_forward verilator`
- Coverage data: `coverage/coverage.dat`
- LCOV info: `coverage/coverage.info`
- Toggle-only LCOV info: `coverage/coverage_toggle.info`
- Source-line coverage for `forward.v`: 28/28 executable DA records, 100.00%
- Raw toggle coverage for `forward.v`: 448/448 toggle BRDA records, 100.00%

## VCS / URG

- Command: `make -C flow/v2_pipeline/phase_p05_forward urg`
- URG report: `vcs/urgReport/mod1.html`
- Branch coverage for module `forward`: 6/6, 100.00%
- Condition/expression coverage for module `forward`: 43/43, 100.00%
- VCS toggle coverage for module `forward`: 450/450 bits, 100.00%
- VCS line coverage for module `forward`: not reported by URG for this continuous-assignment-only module; Verilator line coverage is used for the Tier-2 line metric.

## Tier-2 Delta

All measured forward-unit DUT metrics meet or exceed Tier-2 targets:

- line: target 100%, measured 100.00% by Verilator
- branch: target 100%, measured 100.00% by VCS/URG
- expr/cond: target >=95%, measured 100.00% by VCS/URG
- toggle: target >=95%, measured 100.00% by Verilator and VCS/URG

No DUT metric is below Tier-2, and no uncovered DUT point remains in the final reports. Do not mark this gate green here; final approval is owned by the gate reviewer.
