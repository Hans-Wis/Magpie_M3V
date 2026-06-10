## summary
NEW overall: 100.00% (72/72); mem_stall bin hit: yes

## evidence
`WRAPPER_MEMSTALL_HIT cycle=1 cp_hazard=0001 imode=3 dmode=1` from `logs/wrapper_memstall.sim.log`

## files_added
- `flow/v2_pipeline/phase_04_08_functional_coverage/tb_wrapper_func_cov.sv`

## provenance
- host: `eda`
- vcs: `/soft/synopsys/vcs/X-2025.06-SP1/bin/vcs`
- urg: `/soft/synopsys/vcs/X-2025.06-SP1/bin/urg`
- merge_cmd: `/soft/synopsys/vcs/X-2025.06-SP1/bin/urg -full64 -lca -flex_merge code_union -dir coverage/compile.vdb coverage/vdb/*.vdb -report urgReport`
- wrapper merge inputs: 8 existing vdbs + `coverage/vdb/wrapper_memstall.vdb`

## gate_status
- `pytest -q tests/gates/*.py`: 176 passed
- `pytest -q tests/gates/gate_04_08_functional_coverage.py tests/gates/gate_03_08_lockstep_revalidate.py`: 6 passed (including lockstep PASS)

## bind_unchanged
`flow/v2_pipeline/phase_04_08_functional_coverage/cpu_m1_func_cov_bind.sv` was not edited; byte-identical.

## tokens
- `make run_tests.stamp` succeeded with wrapper wait-mode coverage run and merged VDBs.
- `make functional_coverage_report.md` produced 100% and empty `uncovered_bins.csv`.
