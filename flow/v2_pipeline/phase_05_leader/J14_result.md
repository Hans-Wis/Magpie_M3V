## summary
CSR instr enabled for M1-supported CSR sweep: YES. Five seeds `2026061401..1405` clean for CSR/no-random-sync-trap lockstep: 1,922 matched commits. Summary status is `INCOMPLETE` only because target_commits was set to 999999 to force all five seeds.

## timing_csr_handling
Excluded only CSR-read `wdata` compare for timing CSRs `{cycle=0xc00, cycleh=0xc80, instret=0xc02, instreth=0xc82}` plus Spike machine-counter aliases `{0xb00,0xb80,0xb02,0xb82}` and `time/timeh` if present. PC/instr/rd still compare. Raw proof: all five seeds mismatch only `cycle`/`instret` data; non-timing CSR rows (`mstatus/mie/mtvec/mscratch/mepc/mcause/mtval/mip`) compare exactly.

## divergences
REAL-DUT pc=0x1102 `csrr mstatus`: DUT `0x80`, Spike `0x1880`; root cause MPP bits absent. Fix: add `mstatus_mpp` and M-only MPP behavior in `csr.v`; ADR `docs/adr/0010-csr-sync-trap-lockstep.md`.
REAL-DUT pc=0x110a `csrr mscratch` after `csrrw`: DUT old `0`, Spike `0x1880`; root cause CSR RAW hazard. Fix: CSR EX/MEM and WB read forwarding; ADR-0010.
HARNESS pc=0x112a `csrr cycle`: Spike trapped until launched with `zicntr`; fixed Spike ISA to `rv32imc_zicsr_zifencei_zicntr`.
HARNESS sync traps: this Spike 1.1.1-dev stops after M-mode `ecall`/`ebreak` exception logs, before handler commits, so sync-trap continuation is not clean yet. DUT RTL now implements precise sync trap entry, but lockstep sync-trap seeds remain open.

## revalidate
`python3 -m pytest tests/gates/gate_*.py -q`: FAIL, 162 passed / 18 failed.
`gate_03_08_lockstep_revalidate`: PASS, 1 passed.
`gate_02_01_mem_wrapper`: FAIL, 5 passed / 1 text-pattern failure due new sync-trap gating expression.
`gate_04_08_functional_coverage`: PASS, 5 passed.
Prior RV32IMC-noCSR path not relaunched after CSR edits; prior J13 artifact remains clean.

## regressions
Behavioral regression observed in full pytest: `gate_02_02_misalign_trap` rebuild now fails after one trap (`aligned byte marker occurred after trap_count=1`). Needs follow-up before signoff.

## open
J14 not fully closed: sync-trap lockstep continuation with Spike, gate_02_02 regression, and full pytest failures remain in scope.

## tokens
not metered by local tools.
