"""gate_29_npu_writeback — Coral-parity gap #1: result writeback DMA (ADR-0033).

Verifies the NPU writeback path that makes the Coral offload loop possible: TCM result data ->
AXI4 write master -> shared memory, host-programmed via WB_SRC/DST/LEN/GO, wb_done/IRQ only after
the final B handshake.

- tb_npu_writeback: host preloads TCM golden -> WB_GO -> write master -> shared mem; scoreboard
  asserts SHARED[WB_DST+n]==TCM[WB_SRC+n]. Stimulus crosses a 4KB boundary and >256 beats (write
  chunking). Asserts NPU_WB_PASS, wb_done set, no spurious dma_err.
- tb_npu_wb_err: write SLVERR -> STATUS.dma_err latched, wb_done NOT set, no lockup (NPU_WB_ERR_PASS).

Sim = Verilator (VCS = signoff, OUTSIDE-SANDBOX).
"""

import shutil
from pathlib import Path

import pytest

from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_RTL, verilator_sim

ROOT = Path(__file__).resolve().parents[2]
RTL = [ROOT / f"IP/npu/rtl/{m}.v" for m in ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine")]
RTL += CPU_M1_RTL  # ADR-0034: npu_top now instantiates the cpu_m1 sequencer
WMEM = ROOT / "IP/npu/dv/tb/axi_full_wmem.v"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_writeback_scoreboard_passes(tmp_path):
    files = RTL + [WMEM, ROOT / "IP/npu/dv/tb/tb_npu_writeback.v"]
    verilator_sim(tmp_path, "tb_npu_writeback", files, "NPU_WB_PASS", extra_args=CPU_M1_ARGS)


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_writeback_slverr_aborts(tmp_path):
    files = RTL + [WMEM, ROOT / "IP/npu/dv/tb/tb_npu_wb_err.v"]
    verilator_sim(tmp_path, "tb_npu_wb_err", files, "NPU_WB_ERR_PASS", require_zero_errors=False, extra_args=CPU_M1_ARGS)
