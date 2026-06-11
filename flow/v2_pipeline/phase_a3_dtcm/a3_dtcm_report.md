# Phase A1 MUL Directed Lockstep Report

Status: pass

Result: a3_dtcm full lockstep matched 57 commits (57 commits)

Corners: b2b mul, mul-use dist1/dist2, mul->mul RAW, MULH/MULHSU/MULHU sign matrix, mul/load interplay, wrong-path mul squash, div<->mul arbitration. FULL per-commit Spike lockstep (trap-free by construction; trap-x-mul covered by the riscv-dv farm).
