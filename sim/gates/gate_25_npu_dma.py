"""gate_25_npu_dma — Phase 1 data-plane (AXI4-full + DMA).

npu_dma AXI4-full INCR read-burst master streams shared-mem weights into the NPU local buffer,
host-programmed over the AXI4-Lite fabric. Stimulus forces multi-burst chunking (>256 beats) AND a
4 KB-boundary crossing. Sim engine = **Verilator** (VCS = signoff, OUTSIDE-SANDBOX).
"""

import shutil
from pathlib import Path

import pytest

from gate_20_axi_fabric import verilator_lint, verilator_sim

ROOT = Path(__file__).resolve().parents[2]
RTL = [ROOT / f"IP/npu/rtl/{m}.v" for m in ("axil_1to2", "npu_axil_regs", "npu_dma")]
TB = [ROOT / "IP/npu/dv/tb/axi_full_mem.v", ROOT / "IP/npu/dv/tb/tb_npu_dma.v"]


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_dataplane_rtl_lints_clean_of_errors():
    verilator_lint(RTL)


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_dma_burst_copy_scoreboard_passes(tmp_path):
    verilator_sim(tmp_path, "tb_npu_dma", RTL + TB, "NPU_DMA_PASS")
