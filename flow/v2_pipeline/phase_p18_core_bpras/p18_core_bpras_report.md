# P18 Core BP/RAS Recovery Integration Report

Status: report-only, not gate-green

Spike lockstep: PASS: P18 BP/RAS lockstep matched 92 commits

## core.v Toggle Delta

| Source | Hit/Total | Toggle % |
| --- | ---: | ---: |
| BEFORE baseline (`phase_p15_core_datapath` merged) | 4185/5426 | 77.13% |
| P18 directed alone | 3314/5426 | 61.08% |
| AFTER baseline + P18 | 4268/5426 | 78.66% |
| DELTA closed | +83 toggles | +1.53 pp |

Only `core.v` P18 roster signals are attributed here. BP/RAS leaf table/stack internals remain P13/P14-owned.

## Directed Fixtures

- taken/not-taken backward branch pairs
- 4+ taken updates at one branch offset plus repeated not-taken outcomes
- two taken branches separated by 64 bytes to share bp.v index bits [6:1]
- JAL/RET call-return with RAS push/pop
- poisoned RA return to force RAS target mismatch recovery
- JAL target training and wrong-path IF clear through redirect

## P18-Owned Roster Signals Now Covered

- `bp_upd_pc[21:20]`
- `ex_mem_bp_upd_pc_r[21:20]`
- `ex_mem_pred_ras_target_r[2, 21:20]`
- `if_ex_pred_ras_target[2, 21:20]`
- `ras_top[2, 21:20]`

## P18-Owned Roster Signals Still Uncovered

### REACHABLE

- `bp_upd_pc[0, 31:22]`: REACHABLE: add higher/alternating branch PCs that toggle the remaining update-PC bits.
- `ex_bp_upd_pc[0, 31:22]`: REACHABLE: add higher/alternating branch PCs before the EX update latch.
- `ex_mem_bp_upd_pc_r[0, 31:22]`: REACHABLE: add higher/alternating branch PCs that reach EX/MEM update registers.
- `ex_mem_pred_ras_target_r[1:0, 19:8, 31:22]`: REACHABLE: add return targets with the remaining high-bit pattern and a RAS-predicted return.
- `ex_target_mispredict`: REACHABLE: keep target-alias branches until predicted-taken wrong-target is observed.
- `if_ex_pred_target[0, 19:10, 31:22]`: REACHABLE: add target-alias trained branches whose predicted target reaches IF/EX.
- `redirect_target[31:22]`: REACHABLE: add BP and RAS recoveries to targets with the remaining high-bit pattern.

### STRUCTURAL

- `mem_ras_actual_target[0]`: STRUCTURAL: core.v line 846 masks JALR/RAS actual target with `& ~32'd1`.
- `redirect_target[0]`: STRUCTURAL: core.v lines 1045-1048 select only aligned recovery targets; the JALR arm masks with `& ~32'd1`.

### cross-slice

- `bp_predict_target[0, 19:10, 31:22]`: P13_BP_LEAF/P18 boundary: BTB target storage bits are leaf-owned; P18 owns use in redirect/fetch priority.
- `if_ex_pred_ras_target[1:0, 19:8, 31:22]`: P14_RAS_LEAF/P18 boundary: low alignment bits originate from RAS-pushed return PCs; P18 observes integration only.
- `ras_push_val[0, 31:22]`: P16_IF/P18 boundary: return-address low alignment is PC-size/fetch alignment; P18 owns push orchestration, not PC alignment closure.
- `ras_top[1:0, 19:8, 31:22]`: P14_RAS_LEAF/P18 boundary: stack storage and pointer internals are leaf-owned; P18 observes top-value integration only.

## Anti-Green-Wash Notes

- Spike lockstep mismatch is fail; no mismatch was waived by this analyzer.
- Missing fixture coverage is classified `REACHABLE`, not structural.
- Structural classification is used only for signals with an exact `core.v` alignment/mask citation.
- Cross-slice/leaf entries name the owner and are not claimed as P18 closure.

## Token Record

- Codex goal token tracker was not active for this turn (`get_goal` returned no active goal/budget).
- Session transcript is mirrored by `.run/p18_bpras/codex_impl.log`.
