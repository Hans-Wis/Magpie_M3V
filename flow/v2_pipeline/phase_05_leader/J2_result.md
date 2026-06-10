## summary
Functional coverage overall: 0.00% (0/72 bins), threshold 0%; 6 covergroups authored. VCS blocked before simulation on license wait, so measured coverage is waived/unavailable.

## per_group
| covergroup | hit% | notable uncovered bins |
| --- | ---: | --- |
| cg_opcode_instr_class | 0.00 | all 13 bins; VCS unavailable |
| cg_alu_m_funct | 0.00 | all 21 bins; VCS unavailable |
| cg_load_store | 0.00 | all 12 bins; VCS unavailable |
| cg_branch_jump_bp_ras | 0.00 | all 10 bins; VCS unavailable |
| cg_hazard_flush | 0.00 | all 6 bins; VCS unavailable |
| cg_csr_trap | 0.00 | all 10 bins; VCS unavailable |

## files_added
flow/v2_pipeline/phase_04_08_functional_coverage/functional_coverplan.md
flow/v2_pipeline/phase_04_08_functional_coverage/cpu_m1_func_cov_bind.sv
flow/v2_pipeline/phase_04_08_functional_coverage/tb_random_func_cov.sv
flow/v2_pipeline/phase_04_08_functional_coverage/Makefile
flow/v2_pipeline/phase_04_08_functional_coverage/analyze_functional_coverage.py
tests/gates/gate_04_08_functional_coverage.py

## provenance
host=eda; vcs=/soft/synopsys/vcs/X-2025.06-SP1/bin/vcs, banner Chronologic VCS X-2025.06-SP1_Full64; urg=/soft/synopsys/vcs/X-2025.06-SP1/bin/urg, X-2025.06-SP1 not executed.
commands: make -C flow/v2_pipeline/phase_04_08_functional_coverage clean all; python3 analyze_functional_coverage.py; pytest tests/gates/gate_*.py -q.

## gate_status
python3 -m pytest tests/gates/gate_*.py -q: 168 passed in 9.62s.

## issues_or_waivers
VCS compile entered license wait before simulation; no URG merge/report was produced. Every uncovered bin is listed in uncovered_bins.csv with waiver_candidate=waive and reachability "rerun under licensed VCS".

## tokens
Not tool-reported in this session.
