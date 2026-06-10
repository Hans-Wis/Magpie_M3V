## misalign_regression
Root cause: J14 sync-trap work did not flush EX/MEM on data-trap WB redirect, and synchronous exception `mepc` used the pipeline next-PC bookkeeping instead of the faulting PC. Fix: `core.v` includes `wb_take_data_trap` in `wb_redirect`, saves sync/data exception PC via `wb_sync_exception_pc`, and keeps IRQ on the next-PC path. Directed firmware also vectors through an explicit trap slot so the handler entry is unambiguous. `gate_02_02`: PASS, 4/4.

## stale_assertions_reconciled
Updated gates `01_03`, `01_04`, `02_00`, `02_01`, `03_09` after verifying new RTL. Old `wb_csr_we` no-sync-trap needle -> new `!ex_wb_illegal_r` suppression: correct because illegal/sync traps must not commit CSR writes. Old IRQ-only redirect strings -> `wb_take_irq || wb_take_data_trap || wb_take_sync_trap`: correct because all trap entries redirect to `mtvec`. Old mstatus layout -> MPP+MTVAL layout: correct per M-only `mstatus.MPP=2'b11` and precise trap `mtval`. Old raw CSR latch -> `id_csr_rdata`: correct for EX/MEM CSR RAW forwarding. Old noCSR riscv-dv scope -> CSR-enabled scope (`--no_csr_instr=0`, `--bare_program_mode=0`): correct for J14 supported-CSR sweep.

## sync_trap_status
CSR-instruction lockstep rerun on current RTL: seeds `2026061401..2026061405`, all OK, 6,261 matched commits, no divergences; summary remains `INCOMPLETE` only because target was intentionally `999999`. Full sync-trap stream remains honestly scoped: ADR-0010/J14 evidence says local Spike 1.1.1-dev stops after M-mode `ecall`/`ebreak` exception logging before handler commits. Async interrupts and full sync-trap continuation remain documented gaps; not faked.

## csr_bug_fixes_verified
`mstatus.MPP`: verified correct in `csr.v` via `mstatus_mpp`, reset/trap/mret M-only `2'b11`, and CSR read layout `{19'b0, mstatus_mpp, ...}`. `mscratch` forwarding: verified correct via core EX/MEM CSR forwarding into `id_csr_rdata` plus same-cycle CSR-file forwarding; CSR rerun matched non-timing CSR rows.

## final_pytest
`python3 -m pytest tests/gates/gate_*.py -q`: PASS, 180 passed, 0 failed. Explicit gates: `gate_03_08`/`gate_02_01`/`gate_04_08`: PASS, 12 passed. Coverage artifact: 100.00% (72/72 bins). Misalign log: mcause 4/4/6, mtval `00000071`, no misaligned DBUS. Prior arith 100k artifact: J11 PASS 114,216 commits. Prior RV32IMC-noCSR artifact: J13 PASS 5/5 seeds, 6,882 commits.

## regressions_remaining
None in gates or rerun CSR-instruction lockstep. Full sync-trap-stream and async interrupt lockstep remain documented unsupported-scope gaps, not regressions hidden by tests.

## tokens
Not metered by local tooling.
