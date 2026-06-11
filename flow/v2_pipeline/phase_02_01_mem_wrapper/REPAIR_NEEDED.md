# REPAIR-0001 — tb_mem_wrapper bit-rot (found 2026-06-12 during A3)

This TB was BROKEN AT COMPILE at the M1A fork point (debug-port-era pin names swapped between the
two instances: `cpu_m1_top uut` had `.debug_mode_o`, `core ref_core` had `.debug_mode` — i.e. it has
not actually been runnable since the ADR-0021 debug ports landed pre-freeze; gate_02_01 passed by
reading the COMMITTED log from an older RTL generation). Partial repair done in this commit:
- pin names corrected per module (top=.debug_mode, core=.debug_mode_o)
- separate dbg_dummy2_* sinks for ref_core (MULTIDRIVEN fix)

REMAINING DECAY (needs real archaeology, separate work item): after the compile fixes the baseline
loop terminates at cycle 2 with 0 commits (`ref_terminal = ex_wb_valid_r && ex_wb_illegal_r` fires
during warmup; TRACE_A shows if_pc=2/4/8). The warmup/terminal logic predates several core
generations. Until repaired, the wrapper-equivalence row is **not-run** (honest taxonomy §9) — NOT
claimed green. The wrapper CONTRACT itself is unaffected by A1–A3: `git diff m1a-fork-base..HEAD --
IP/cpu_m1/rtl/cpu_m1_top.v IP/cpu_m1/rtl/lsu.v` is EMPTY (proof: A3's dtcm is an SoC-side macro;
the equivalence property proven at the M1 freeze still describes this RTL).
