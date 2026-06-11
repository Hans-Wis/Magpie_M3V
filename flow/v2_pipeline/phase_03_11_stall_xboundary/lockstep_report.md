# Phase 3.11 Stall x Cross-Boundary Spike Lockstep Report

Status: pass

Result: stall_xboundary lockstep matched 39 commits

Compared fields: `pc`, `instr`, `rd`, `wdata`.

Scope: directed stress for load-use/muldiv stall + branch redirect landing on a
consecutive cross-boundary 32-bit RVC run (BUG-XBOUND-0001 open lead). Not random DV.
