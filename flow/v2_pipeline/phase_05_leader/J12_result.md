## summary
J12 enabled load/store + branch/jump and data pages for bounded riscv-dv; CSR/fence remain disabled. Generation is scoped to RV32IC for this wave so M/mul-div stays as-is. Clean bounded run: seeds 2026061206, 2026061207, 2026061208 all PASS, 1534 matched commits total. Summary JSON status is INCOMPLETE only because target_commits stayed 100000 and this run intentionally did not launch full 100k.

## divergences_found
HARNESS: initial data-page enable exposed DUT/Spike memory-map mismatch. DUT executes at PC 0 while ELF/Spike use 0x1000; data symbols were 0x1000-based. Fix: `tb_riscvdv_lockstep.v` subtracts ELF_BASE=0x1000 for D-memory indexing, and `firmware.lds` includes riscv-dv `.region*` data sections in the loaded image.
REAL-DUT: seeds 2026061201/1202/1203/1205 first diverged after taken branches; evidence included PC 0xec branch matching then DUT latching target PC 0xf8 with stale instr 0x0006e033 instead of memory instr 0x0021f763. Fix: `core.v` BTB target verification, redirect-over-stall priority, and one-cycle `redirect_warmup`. ADR: `docs/adr/0008-btb-target-mispredict-recovery.md`.
REAL-DUT residual outside J12 scope: RV32IMC exploratory run then exposed M-unit/result association mismatches (e.g. seed 2026061201 PC 0x1478 `rem s10,s8,gp`: raw Spike x26=0, DUT x26=0x472816d0). Not fixed here; J12 generation moved to RV32IC per "M/mul-div may stay as-is".

## memmap
Spike runs `-m0x1000:0x40000 --pc=0x1000`; comparator normalizes Spike PCs by 0x1000. DUT loads the same linked binary image into one 256KiB RAM at offset 0; I-fetch uses DUT PC, D-memory subtracts ELF_BASE for 0x1000-based `.data/.region*/.user_stack` addresses so loads see the same initialized data page and stores hit the same backing image.

## revalidate
`python3 -m pytest tests/gates/gate_*.py -q`: 180 passed in 7.99s.
`gate_03_08`: 1 passed in 3.92s; `gate_02_01`: 6 passed in 0.40s; `gate_04_08`: 5 passed in 0.01s; `gate_03_09`: 3 passed in 0.01s.
Prior J11 arith 114216-commit artifact was not rerun after J12 edits; `gate_03_09` still checks the artifact/report path.

## regressions
No regression in pytest/gates. Known residual: M-unit random interaction found in exploratory RV32IMC J12 remains a separate wave; full 100k J12 was not launched.

## tokens
Not available from local runtime/API telemetry.
