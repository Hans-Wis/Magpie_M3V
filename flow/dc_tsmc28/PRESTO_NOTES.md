# DC/Presto compatibility notes — full npu_top synthesis (M3-signoff)

**Status (2026-07-08):** full `npu_top` DC flow is set up (`synth_npu_top.tcl` + `npu_tcm_bb.v`
TCM black-box stub) but **blocked** by a pervasive Verilator-vs-Presto incompatibility in the
core RTL. Deferred (User decision); per-block PPAs cover the current picture. Core RTL kept pristine.

## What works
- `synth_npu_dma.tcl` — npu_dma std-cell PPA sweep (M3c, done). npu_dma.v was reordered for Presto.
- `synth_mat_lanes.tcl` — mat_engine LANES PPA (ADR-0067, done).
- `flow/v2_pipeline/phase_05_01_synth_ppa` — cpu_m1_top HOST config (no vexu) 699MHz/26,298µm² (Jul 3).
- The simpler npu modules (npu_axil_regs, npu_dma, npu_ml_ctrl, mat_engine, axil_decerr) Presto-compile clean.

## The blocker: Verilator-style forward references
DC's Presto front-end requires declaration-before-use for nets/regs used in continuous assigns;
Verilator's 2-pass elaboration tolerates the reverse order. The core RTL (verified under Verilator)
uses forward references pervasively. Count from the failed `npu_top` elaborate (Presto stops early,
so these are lower bounds):

| File | forward-ref `symbol not defined` count | examples |
|---|---|---|
| `idu.v` | 2 | `is_fmem_ld`, `is_fmem_st` (ADR-0050 F, added after the Jul-3 cpu_m1_top synth) |
| `core.v` | 19 | (core datapath temporaries) |
| `vexu.v` | 16 | `vsew`, `beats_op`, `is_vmem`, `vm_state`, `part_res`, `seg8`, ... |

Total ≥ 37 across the 3 most complex, most-verified modules (vexu = RVV Phase B-F). Note the
cpu_m1_top HOST synth (phase_05_01) predates the F/RVV additions that introduced these, and it did
NOT include vexu.

## To complete npu_top DC (future Presto-compat pass)
1. Reorder the ~37+ forward references (declare wires/regs before their first continuous-assign use).
   PURE reorder, no logic change — the fix pattern is exactly what was done for `npu_dma.v` (M3c) and
   `idu.v` (attempted, reverted here to keep the core pristine until a verified pass).
2. Re-verify the core: host lockstep (ADR-0032 commit-trace equivalence) + the full RVV Phase B-F
   gate set (`gate_62..81`) + scalar gates — a reorder must be behavior-identical.
3. Then `CLK_PERIOD=2.0 dc_shell -f synth_npu_top.tcl` (flagship MAT_LANES=4/DMA_DATA_W=256/ML_V2_EN=1).
   The TCM (`npu_tcm`/`npu_itcm`) is black-boxed via `npu_tcm_bb.v` (SRAM macro; mem not synthesized as
   flops). Total NPU = reported logic + TCM macro (memory compiler) + vexu/core (in the same synth once
   Presto-clean).

## No easy partial
Black-boxing `vexu` alone does not help — `core.v` (19) still fails Presto — so the core.v + idu.v
reorders are the minimum for ANY npu_top synth. Hence the full pass is gated on the reorder+re-verify.
