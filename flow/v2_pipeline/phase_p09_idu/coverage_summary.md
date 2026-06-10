# P09 IDU Unit Coverage Summary

Status: NOT GREEN

## Runs

- Verilator: PASS: idu unit 68/68 vectors
- VCS: PASS: idu unit 68/68 vectors

## Coverage

| Tool | Scope | Line | Branch | Cond/Expr | Toggle |
| --- | --- | ---: | ---: | ---: | ---: |
| Verilator | idu.v | 97.83% | n/a | n/a | 100.00% (`coverage_toggle.info`) |
| VCS/URG | module idu | 100.00% | 100.00% | 100.00% | 87.94% |

## Tier-2 Check

Required: line 100%, branch 100%, expr/cond 95%, toggle 95%.

- Line: FAIL under Verilator, 97.83%.
- Branch: PASS under VCS, 100.00%.
- Cond/expr: PASS under VCS, 100.00%.
- Toggle: FAIL under VCS, 87.94%.

## Notes

- VCS/URG marks `idu.v:173` and `idu.v:185` covered through X-funct3 default-arm vectors.
- Verilator remains two-state for these vectors and reports `idu.v:173` and `idu.v:185` uncovered.
- VCS toggle misses include structural constant fields: `csr_zimm[31:5]`, `imm_b[0]`, `imm_u[11:0]`, and `imm_j[0]`.
