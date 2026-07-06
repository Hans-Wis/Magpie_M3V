"""gate_36_cq_ring — ADR-0035: CQ transport integration + ring protocol.

- tb_npu_cq_smoke (Codex-authored, Claude-reviewed): full offload batch over the ring —
  host writes descriptors to shared memory, doorbell (TAIL), sequencer firmware fetches via
  DMA, executes LOAD_W/FENCE/STORE(IRQ)/CFG(LAST); weight data lands in TCM, results land
  back in shared memory, IRQ + DONE + HEAD advance verified; plus an ENGINE_NOT_READY halt.
- tb_npu_cq_ring_err S1/S2 (NPU_CQ_RING_PASS): batch consumption, ring WRAP across the
  4-slot boundary, FULL/EMPTY advisory flags from HEAD/TAIL.
Sim = Verilator (VCS signoff OUTSIDE-SANDBOX).
"""

import shutil
from pathlib import Path

import pytest

from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_RTL, verilator_lint, verilator_sim

ROOT = Path(__file__).resolve().parents[2]
RTL = [ROOT / f"design/npu/rtl/{m}.v" for m in ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine")]
RTL += CPU_M1_RTL
RWMEM = ROOT / "design/npu/dv/tb/axi_full_rwmem.v"
FIRMWARE = ROOT / "design/npu/sw/cq_sequencer/firmware.hex"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_cq_rtl_lints_clean():
    verilator_lint(RTL, extra_args=CPU_M1_ARGS)


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_cq_offload_batch_smoke(tmp_path):
    assert FIRMWARE.exists(), "sequencer firmware.hex missing (make -C design/npu/sw/cq_sequencer)"
    files = RTL + [RWMEM, ROOT / "design/npu/dv/tb/tb_npu_cq_smoke.v"]
    verilator_sim(tmp_path, "tb_npu_cq_smoke", files, "NPU_CQ_SMOKE_PASS", extra_args=CPU_M1_ARGS)


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_cq_ring_wrap_full_empty(tmp_path):
    files = RTL + [RWMEM, ROOT / "design/npu/dv/tb/tb_npu_cq_ring_err.v"]
    verilator_sim(tmp_path, "tb_npu_cq_ring_err", files, "NPU_CQ_RING_PASS", extra_args=CPU_M1_ARGS)
