## root_cause
At `pc=0x0e`, temporary probe captured `instr_assembled=8f930000` before fallback, expected `00cf8f93`.
Signals: `cross_assemble=0 residue=0f97/8067 cur_half_lo=0000 cur_half_hi=8f93 at_cross_boundary=1 upcoming_cross=0 i_mem_rdata=8f930000`.
Wrong logic: lab08e cleared `cross_assemble` while consuming a high-half 32-bit instruction and did not save `cur_half_hi` as residue for the next high-half 32-bit in a consecutive run.

## fix
Changed `IP/cpu_m1/rtl/core.v`: added `consecutive_cross`, drives `i_mem_addr=if_pc+6`, keeps `cross_assemble=1`, and updates `residue=cur_half_hi` while consuming current high-half 32-bit.
Preserved `mem_stall` freeze by gating `consecutive_cross` with `!mem_stall`; fallback `at_cross_boundary` remains unchanged.
Changed `IP/cpu_m1/rtl/idu.v`: included legal `is_jalr` in `known_opcode`; seed exposed this immediately after xbound fix at `pc=0x12`.
ADR: `docs/adr/0007-crossboundary-consecutive-32bit.md`.
Evidence: `docs/reports/bug_xbound_0001/j9_evidence.md`.

## revalidate
riscv-dv seed `2026060801`: original xbound failure fixed; commits 0-5 now match Spike (`addi@0x0e` and `jalr@0x12` retire). Run continues to 981 DUT commits, then later mismatch at idx 59 (`pc=0x0d2`, `c.lui`, DUT `0000d000` vs Spike `0000c000`).
`python3 -m pytest tests/gates/gate_*.py -q`: PASS, `179 passed`.
`gate_03_08_lockstep_revalidate`: PASS, `1 passed`; 81 DUT commits equal 81 Spike commits.
`gate_02_01_mem_wrapper`: PASS, `6 passed`.
`gate_04_08_functional_coverage`: PASS, `5 passed`; report remains `100.00% (72/72 bins)`.

## regressions
None found in requested gates.

## issues
Seed `2026060801` now exposes a later independent-looking `c.lui` immediate mismatch at idx 59; not the original xbound illegal-trap failure.
Git status from repo top shows unrelated dirty files under `platform/` and `doc/`; untouched.

## tokens
Not available from runtime instrumentation.
