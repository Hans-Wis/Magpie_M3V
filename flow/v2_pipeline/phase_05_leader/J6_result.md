## summary
NEW overall 98.61% (71/72 bins); was 94.44% (68/72 bins).

## hazard_group
| bin | hit? | how |
| --- | --- | --- |
| cg_hazard_flush:hazard:load_use | hit | `stim_load_use.S` executes `lw` followed immediately by dependent `addi` (`addi s2,s1,1`). |
| cg_hazard_flush:hazard:muldiv_busy | hit | `stim_muldiv_busy.S` issues back-to-back mul/div in `id_is_muldiv` window while `md_busy` is high. |
| cg_hazard_flush:hazard:fetch_stall | hit | `stim_fetch_stall.S` redirects to unaligned 32-bit target at `0x82` causing `at_cross_boundary` fallback `fetch_stall`. |
| cg_hazard_flush:hazard:mem_stall | no | still unreachable in core-local harness (`mem_stall` stuck low). |

## stimulus_added
Added directed stimuli: `stim_load_use.S`, `stim_muldiv_busy.S`, `stim_fetch_stall.S`; integrated into `TESTS` in `flow/v2_pipeline/phase_04_08_functional_coverage/Makefile`.

## provenance
`vcs`=X-2025.06, `urg`=X-2025.06, host=`eda`; command flow `make clean all` in phase directory with vdb runs for `random_arith branch_bp_ras csr_ops irq_mret misalign m_ext ecall illegal load_use muldiv_busy fetch_stall`; merge `URG=.../urg -full64 -lca -flex_merge code_union -dir coverage/compile.vdb coverage/vdb/*.vdb -report urgReport`.

## gate_status
`python3 -m pytest tests/gates/gate_*.py -q`: 176 passed in 7.55s. `gate_03_08_lockstep_revalidate` PASS.

## issues_or_waivers
Remaining uncovered hazard bin: `cg_hazard_flush:hazard:mem_stall`; waiver recorded as `waive` in `uncovered_bins.csv` with reason `not driven by core-local random harness` and reachability `reachable through cpu_m1_top wait-state memory wrapper`.

## tokens
No goal token budget was active for this task; token accounting unavailable.
