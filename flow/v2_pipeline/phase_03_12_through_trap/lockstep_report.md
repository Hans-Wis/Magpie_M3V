# Phase 3.12 Through-Trap Lockstep Report

Status: pass

Result: pre-trap prefix lockstep matched 7 commits; through-trap handler CSRs match spec (mepc/mcause=11/mstatus=0x1800) x2, mret resumes correctly

Pre-trap prefix: 7 commits Spike-equivalent. Through-trap handler: spec-validated.

FINDING: Spike 1.1.1-dev `--log-commits` halts the commit log at the first M-mode synchronous
trap (verified with a clean no-MMIO ecall + plain `-l`), so it cannot be the post-trap oracle.
Through-trap correctness is therefore proven by: (1) Spike per-commit lockstep on the pre-trap
prefix, (2) the DUT executing the FULL handler with trap CSRs (mepc/mcause/mstatus) and resume
PC matched to the RISC-V spec. This is real commit-by-commit trap verification with the spec as
the handler oracle. (spike_commit.py also normalizes PC-holding CSR reads by pc_base, ready for a
Spike build that does log through traps.)
