"""gate_33_npu_core_arbitration — ADR-0034 risk R3: DMA-vs-core TCM write arbitration.

tb_npu_core_arb overlaps a 256-beat DMA burst into TCM words 512..767 with a running
300-iteration core load/store loop at word 64. Pass requires REAL overlap (core retired
instructions while the DMA engine was busy — checked on internal signals, not inferred),
both completions, no dma_err, the full DMA region equal to the source pattern (any lost
write beat fails), the core's final result correct, and the program region untouched.
Sim = Verilator (VCS signoff OUTSIDE-SANDBOX).
"""

import shutil
from pathlib import Path

import pytest

from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_RTL, verilator_sim

ROOT = Path(__file__).resolve().parents[2]
RTL = [ROOT / f"design/npu/rtl/{m}.v" for m in ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine", "npu_ml_ctrl", "npu_strip_buf")]
RTL += CPU_M1_RTL
TB = [ROOT / "design/npu/dv/tb/axi_full_mem.v", ROOT / "design/npu/dv/tb/tb_npu_core_arb.v"]


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_dma_vs_core_arbitration_overlap(tmp_path):
    verilator_sim(tmp_path, "tb_npu_core_arb", RTL + TB, "NPU_CORE_ARB_PASS", extra_args=CPU_M1_ARGS)
