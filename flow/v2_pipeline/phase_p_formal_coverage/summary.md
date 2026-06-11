# Magpie M1 Tier-2 Formal Coverage Closure

Target: >=90% VC Formal proof-reachable / COI coverage for modules already proven in `phase_p_formal`.

Date: 2026-06-11

Run command:

```sh
flow/v2_pipeline/phase_p_formal_coverage/run_vcf_formal_coverage.sh
```

Coverage data source:

* `read_file ... -cov all`
* `check_fv -block`
* `analyze_fv_coverage -hierdepth 100`
* `report_fv_coverage -hierdepth 100`
* Covered/uncovered lists from `report_fv_coverage -list_covered/-list_uncovered`

| Module | Formal coverage | Total regs in report | Uncovered regs | Properties proven | >=90% |
| --- | ---: | ---: | ---: | ---: | :---: |
| alu | 100/100 | 0 | 0 | 3/3 | yes |
| rfu | 100/100 | 1 | 0 | 4/4 | yes |
| forward | 100/100 | 0 | 0 | 8/8 | yes |
| lsu | 100/100 | 0 | 0 | 1/1 | yes |
| csr | 10/100 | 20 | 18 | 6/6 | no |

Overall Tier-2 formal coverage closure: **not met** because `csr` is below the 90% target.

## Tool Note

VC Formal emitted all requested FPV and coverage reports, then returned `vcf_exit=3` after each module during process teardown with `terminate called without an active exception`. The report files were written before the abort. The property tables show all assertions proven for every module.

## Justified Unreachable

No uncovered item is accepted as justified-unreachable in this run.

The only uncovered items are in `csr`; they are architectural/debug/PMP state registers outside the current assertion COI, not proven-unreachable logic:

* `mie_meie`
* `mie_mtie`
* `mie_msie`
* `mtvec_base`
* `mscratch`
* `mepc_reg`
* `mcause_reg`
* `mtval_reg`
* `ext_pending`
* `cycle_cnt`
* `instret_cnt`
* `dcsr_ebreakm_reg`
* `dcsr_cause_reg`
* `dcsr_step_reg`
* `dpc_reg`
* `dscratch0_reg`
* `pmpaddr_r`
* `pmpcfg_r`

The existing CSR bind proves only `mstatus_val` reserved-field and MPP invariants, so these CSR registers remain outside the proof-reachable COI. Closing `csr` requires additional CSR assertions or a documented formal waiver/exclusion policy for state that is intentionally out of scope.
