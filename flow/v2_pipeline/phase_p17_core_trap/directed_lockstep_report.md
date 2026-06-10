# P17 Core CSR/Trap/IRQ/MRET Directed Lockstep Report

Status: pass-not-gate-green

Lockstep: P17 core trap prefix lockstep matched 11 commits

Trap events: trap events matched expected mepc/mcause/mtval values

Compared prefix commit fields: `pc`, `instr`, `rd`, `wdata` up to the first synchronous trap.

Spike limitation: local Spike 1.1.1-dev logs the M-mode exception and stops before the `mtvec` handler, matching prior J14/J18 evidence. Through-trap commit lockstep is therefore not claimed green.

External IRQ handler commits are filtered from the DUT trace because the IRQ source is a DUT port, not a Spike-visible architectural stimulus; IRQ correctness is checked through core trap-event evidence.
