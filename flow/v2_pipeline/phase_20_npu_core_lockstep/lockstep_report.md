# Phase 2 Step 4 NPU sequencer lockstep report (ADR-0034)

Status: pass

Result: npu-lockstep matched 1164 commits

Commits compared: 1164 (bar: >= 500)

Spike ISA: `rv32im_zicsr_zifencei` (no C — green-wash guard). DUT = npu_top with the core
fetching through the real npu_tcm ports; EN_RVC=0/EN_BP=0/EN_RAS=0.
