# P06 Hazard Unit Coverage Summary

- TB: `IP/cpu_m1/dv/tb/tb_hazard_unit.v`
- DUT scope: `IP/cpu_m1/rtl/hazard.v` only
- Vector result: `PASS: hazard unit 1096/1096 vectors`
- Token record: no active Codex goal token budget was available from `get_goal`

## Test Content

- Standalone unit testbench with an independent golden model for the observable `stall` equation.
- Explicit named vectors cover default/no-stall, load-use `rs1`, load-use `rs2`, load-use both operands, load producer matching neither operand, `rd=x0` suppression, muldiv busy stall, and muldiv not-busy no-stall.
- Exhaustive predicate matrix covers the load-use terms: `id_valid`, `em_valid`, `em_is_load`, `em_rd_we`, `em_rd_idx != x0`, and source match class (`neither`, `rs1`, `rs2`, `both`), crossed with muldiv and WB-unused signal toggles.
- Additional register-index sweeps drive all `rs1`, `rs2`, `em_rd_idx`, and `wb_rd_idx` bits through both toggle directions.

## Verilator

- Command: `make -C flow/v2_pipeline/phase_p06_hazard verilator`
- Coverage data: `coverage/coverage.dat`
- LCOV info: `coverage/coverage.info`
- Toggle-only LCOV info: `coverage/coverage_toggle.info`
- Source-line coverage for `hazard.v`: 17/17 executable DA records, 100.00%
- Raw toggle coverage for `hazard.v`: 66/66 toggle BRDA records, 100.00%

## VCS / URG

- Command: `make -C flow/v2_pipeline/phase_p06_hazard urg`
- URG report: `vcs/urgReport/mod1.html`
- Branch coverage for module `hazard`: no branch objects reported by URG for this continuous-assignment-only module.
- Condition/expression coverage for module `hazard`: 28/28, 100.00%
- VCS toggle coverage for module `hazard`: 68/68 bits, 100.00%
- VCS line coverage for module `hazard`: not reported by URG for this continuous-assignment-only module; Verilator line coverage is used for the Tier-2 line metric.

## Tier-2 Delta

All measured hazard-unit DUT metrics meet or exceed Tier-2 targets:

- line: target 100%, measured 100.00% by Verilator
- branch: target 100%, no branch objects reported by VCS/URG
- expr/cond: target >=95%, measured 100.00% by VCS/URG
- toggle: target >=95%, measured 100.00% by Verilator and VCS/URG

No measured DUT metric is below Tier-2, and no uncovered DUT condition remains in the final reports. Do not mark this gate green here; final approval is owned by the gate reviewer.
