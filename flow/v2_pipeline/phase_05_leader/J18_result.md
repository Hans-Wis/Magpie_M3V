## root_cause
Confirmed: `run_riscvdv_lockstep.py` previously rewrote riscv-dv `test_done: ecall` into `j write_tohost`, so ECALL was test-exit, not a real M-mode sync trap.
Evidence: original riscv-dv asm has `test_done: li gp,1; ecall; write_tohost: sw gp,tohost,t5`; adapted firmware changed only that ECALL to the tohost jump.
Also found generated `ecall_handler` jumps to test-exit for ECALL, so the handler path also had to be adapted.
After handler fix, Spike still truncated at first M-mode ECALL; built `/home/edauser/build/riscv-isa-sim` to rev `3e7bf30da0f35037c90e11d919154ca7ecc28d65`, but it behaved the same, so newer Spike did not close J18.

## trap_handler
Harness keeps riscv-dv mtvec setup and same ELF/memory map for DUT and Spike.
Adapted asm makes only final `test_done` use distinct tohost sentinel; in-stream ECALL/EBREAK/illegal/misaligned load/store are intended real traps.
Injected J18 sync-trap smoke at `main`: ECALL, EBREAK, illegal `.word 0`, misaligned LW, misaligned SW.
Patched handler resumes ECALL/BREAKPOINT/LOAD_ADDRESS_MISALIGNED/STORE_ADDRESS_MISALIGNED/ILLEGAL by reading MEPC, advancing 2/4 bytes from instruction length, restoring context, then MRET.

## sync_trap_lockstep
Not clean. Seed `2026061801` DUT trap trace covers trap entry, handler stream, MRET, and resume for ECALL/EBREAK/illegal/misaligned load/store.
DUT logged boundary state including fault PC, MEPC, MCAUSE, MTVAL, MSTATUS; timing CSRs remain excluded.
Spike commit log stops at `pc=0x000010f8 instr=0x00000073 ECALL` with `exception trap_machine_ecall`; it never logs mtvec handler or MRET, so per-commit trap-boundary comparison is not closed.

## divergences
`2026061801`: `pc=0x000010f8 instr=0x00000073 ECALL`; classified harness/ISS invocation blocker, not proven real-DUT bug.
DUT enters trap with `mcause=0x0b`, `mepc=0x000010f8`, `mtval=0`, `mstatus=0x1880`, then MRET resumes at `0x000010fc`; Spike stream ends before handler.
No RTL fix and no ADR were made because no clean-room DUT defect was isolated.

## revalidate
PASS: `gate_02_00_trap_interrupt.py gate_02_02_misalign_trap.py gate_02_03_mepc_directed.py` => 22 passed.
PASS: `gate_02_01_mem_wrapper.py gate_03_08_lockstep_revalidate.py gate_04_08_functional_coverage.py` plus the above directed gates => 34 passed.
PASS artifact gate: `gate_03_09_riscvdv_lockstep.py` => 3 passed, with summary honestly `DIVERGENCE-FOUND` for J18 sync-trap stream.
Not rerun green this turn: full pytest >=183 and prior full-mix 100k.

## regressions
J18 remains open: sync-trap DUT path is exercised, but Spike-side trap continuation/commit logging is blocked.
No test relaxation was applied; async interrupts remain off.

## tokens
Not metered.
