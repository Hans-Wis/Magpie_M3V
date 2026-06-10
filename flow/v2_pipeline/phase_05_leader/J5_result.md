## summary
NEW overall functional coverage: 94.44% (68/72 bins); was 55.56% (40/72).

## per_group
| covergroup | OLD% | NEW% | remaining-uncovered |
| --- | ---: | ---: | --- |
| cg_opcode_instr_class | 69.23 | 100.00 | none |
| cg_alu_m_funct | 80.95 | 100.00 | none |
| cg_load_store | 91.67 | 100.00 | none |
| cg_branch_jump_bp_ras | 0.00 | 100.00 | none |
| cg_hazard_flush | 50.00 | 33.33 | hazard:load_use; hazard:muldiv_busy; hazard:fetch_stall; hazard:mem_stall |
| cg_csr_trap | 0.00 | 100.00 | none |

## stimulus_added
Merged VCS tests: random_arith seed 20260607 count 48; branch_bp_ras; csr_ops; irq_mret (+irq_at_0x80 +stop_after_mret); misalign; m_ext; ecall; illegal.

## files_added_or_changed
flow/v2_pipeline/phase_04_08_functional_coverage/{Makefile,tb_random_func_cov.sv,analyze_functional_coverage.py,stim_branch_bp_ras.S,stim_csr_ops.S,stim_irq_mret.S,stim_misalign.S,stim_m_ext.S,stim_ecall.S,stim_illegal.S}; tests/gates/gate_04_08_functional_coverage.py.

## provenance
host=eda; vcs_version=X-2025.06; urg=/soft/synopsys/vcs/X-2025.06-SP1/bin/urg; key command: make clean all in phase_04_08_functional_coverage. Merge cmd: urg -full64 -lca -flex_merge code_union -dir coverage/compile.vdb coverage/vdb/*.vdb -report urgReport.

## gate_status
python3 -m pytest tests/gates/gate_*.py -q: 176 passed in 8.10s. gate_03_08_lockstep_revalidate included in full suite: PASS.

## issues_or_waivers
Remaining uncovered hazard_flush bins are not from the requested 0% groups. load_use/muldiv_busy/fetch_stall remain reachable with tighter hazard-directed timing; mem_stall requires a wait-state/top-level memory wrapper because this core-local harness ties mem_stall low. Waiver candidates: mem_stall only.

## tokens
No explicit Codex goal token budget was active; token accounting unavailable from goal tool.
