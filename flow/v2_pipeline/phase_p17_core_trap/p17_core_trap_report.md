# P17 Core Trap Coverage Delta

Status: analysis-pass-not-gate-green

Directed coverage: `flow/v2_pipeline/phase_p17_core_trap/coverage.dat`

Trap/IRQ/MRET events observed: 8

## Owned Core Signals

| Signal | Covered Toggles | Total Toggles | Status |
| --- | ---: | ---: | --- |
| `id_mem_align_error` | 2 | 2 | covered |
| `id_mem_misaligned` | 2 | 2 | covered |
| `ex_mem_is_misaligned_r` | 2 | 2 | covered |
| `ex_mem_is_misaligned_store_r` | 2 | 2 | covered |
| `ex_wb_is_misaligned_r` | 2 | 2 | covered |
| `ex_wb_is_misaligned_store_r` | 2 | 2 | covered |
| `wb_take_data_trap` | 2 | 2 | covered |
| `wb_take_sync_trap` | 2 | 2 | covered |
| `wb_take_irq` | 2 | 2 | covered |
| `wb_trap_enter` | 2 | 2 | covered |
| `wb_trap_exit` | 2 | 2 | covered |
| `wb_trap_pc_for_mepc` | 18 | 64 | reachable |
| `wb_trap_cause` | 10 | 64 | covered_structural_bits |
| `wb_trap_mtval` | 64 | 64 | covered |
| `ex_wb_is_mret_r` | 2 | 2 | covered |
| `irq_pending` | 2 | 2 | covered |

## Classification

- Covered: P17 directed fixture toggled the Verilator points listed above.
- Reachable: any missing owned signal remains reachable and requires more fixture work; no fixture gap is marked structural.
- Structural: `wb_trap_cause` upper/unused cause-code bits are tied by the literal cause mux at `IP/cpu_m1/rtl/core.v:993`; no other structural claims.
- Cross-slice: `pc_redirect` owner P18/P17 shared redirect priority; `redirect_target` owner P18/P17 shared redirect target mux; `if_ex_is_16bit` owner P16 fetch size, consumed by P17 MEPC-16; `mem_stall` owner P15 datapath stall, consumed by P17 trap timing.
- Excluded merged leaf: standalone `csr.v` register behavior belongs to P11 and is not re-covered here.
- Tokens: no active Codex goal token counter was available from `get_goal`; token budget/usage was therefore not machine-recorded.

## Lockstep

See `directed_lockstep_report.md`; Spike commit mismatch is treated as FAIL.
