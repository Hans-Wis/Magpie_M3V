# Phase 3.14 msip Software-Interrupt Directed Lockstep Report

Status: pass

Result: prefix lockstep matched 12 commits; msip handler events matched mepc/mcause=0x80000003/mstatus/mret

Compared prefix fields: `pc`, `instr`, `rd`, `wdata` (per-commit vs Spike).

Checked trap fields: `mepc`, `mcause` (0x80000003 = M software), handler `mstatus`, `mret`.

Scope: directed msip (CLINT software-int) slice — the deterministic, lockstep-able interrupt path for blocker #4b. Truly-async meip/mtip remain directed-only.
