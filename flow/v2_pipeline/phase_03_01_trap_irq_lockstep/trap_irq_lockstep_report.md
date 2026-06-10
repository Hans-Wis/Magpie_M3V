# Phase 3.1 Trap/IRQ Lockstep Report

Status: pass

Result: prefix lockstep matched 13 commits; trap events matched mepc/mcause/mstatus/mret

Compared prefix fields: `pc`, `instr`, `rd`, `wdata`.

Checked trap fields: `mepc`, `mcause`, handler `mstatus`, `mret` resume.

Scope: directed compressed-instruction IRQ slice; not random DV or coverage closure.
