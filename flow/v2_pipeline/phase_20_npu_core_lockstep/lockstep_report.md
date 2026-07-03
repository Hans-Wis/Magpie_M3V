# Phase 2 Step 4 NPU sequencer lockstep report (ADR-0034)

Status: pass

Result: npu-lockstep matched 10809 commits

Commits compared: 10809 (bar: >= 10000)

Spike ISA: `rv32im_zicsr_zifencei` (no C — green-wash guard). DUT = npu_top with the core
fetching through the real npu_tcm ports; EN_RVC=0/EN_BP=0/EN_RAS=0.
