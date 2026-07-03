"""gate_27_npu_top — Phase 1 SEALED NPU subsystem integration.

npu_top: one AXI4-Lite slave -> {CSR @0x3000, TCM @0x3001, DECERR} decode; DMA (AXI4-full)
streams weights into TCM; level IRQ on completion. tb_npu_top checks CSR/TCM decode, TCM host
load/readback, DMA→TCM stream, IRQ assert+clear, no host/DMA clobber. Sim = **Verilator**.
"""

import shutil
from pathlib import Path

import pytest

from gate_20_axi_fabric import verilator_lint, verilator_sim

ROOT = Path(__file__).resolve().parents[2]
RTL = [ROOT / f"IP/npu/rtl/{m}.v" for m in ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr")]
TB = [ROOT / "IP/npu/dv/tb/axi_full_mem.v", ROOT / "IP/npu/dv/tb/tb_npu_top.v"]


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_npu_subsystem_lints_clean_of_errors():
    verilator_lint(RTL)


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_npu_top_integration_scoreboard_passes(tmp_path):
    verilator_sim(tmp_path, "tb_npu_top", RTL + TB, "NPU_TOP_PASS")
