## candidate_2_mepc_precise
REAL bug. Pre-fix directed observe: illegal32 aligned exp 0x80 obs 0x7c; illegal32 odd-half/cross exp 0x8e obs 0x8a; compressed illegal exp 0x98 obs 0x94; ebreak exp 0xa0 obs 0x9c; misaligned lw exp 0xa8 obs 0xa4. Fixed `core.v`: sync/data trap `mepc` now uses `ex_wb_pc_r`, not `ex_wb_pc_r - 4`. ADR: `docs/adr/0011-mepc-precision-and-warl-mask.md`.

## candidate_1_mepc_lsb_mask
REAL bug. Pre-fix `csrw mepc,0x83; csrr mepc` observed 0x83, expected 0x82. Fixed `csr.v`: software `mepc` writes mask bit0 only (`{new_val[31:1],1'b0}`), preserving bit1 for IALIGN=16. Post-fix observed 0x82.

## ex_wb_pc_r semantics
`ex_wb_pc_r` holds the original instruction PC: `if_ex_pc -> ex_mem_pc_r -> ex_wb_pc_r`. It is not PC+4/next PC. Post-fix directed evidence: 0x80/0x8e/0x98/0xa0/0xa8 all matched expected fault PCs.

## revalidate
Directed gate added: `tests/gates/gate_02_03_mepc_directed.py` / `flow/v2_pipeline/phase_02_03_mepc_directed`. Key gates PASS: gate_02_00, gate_02_02, gate_02_03, gate_03_08, gate_02_01, gate_04_08 = 34 passed. Full gate-file suite: `pytest -q tests/gates/*.py` = 183 passed. Bare `pytest -q` collects no tests in this repo.

## regressions
No functional regressions found. Updated old misalign bench termination to accept final terminal ebreak after its three expected misalign traps under precise `mepc`.

## tokens
Not metered by local CLI; report-faithful evidence above.
