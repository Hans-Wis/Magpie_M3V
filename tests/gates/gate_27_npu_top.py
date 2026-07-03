"""gate_27_npu_top — Phase 1 SEALED NPU subsystem integration.

Verifies npu_top: one AXI4-Lite slave -> {CSR @0x3000_xxxx, TCM @0x3001_xxxx} decode,
DMA (AXI4-full master) streaming shared-mem weights into the TCM, and a level IRQ to the
host on completion. tb_npu_top.v checks (23): CSR ID, TCM host load/readback, IRQ assert on
dma_done + clear via CTRL, DMA-streamed words land in TCM, and the host-loaded TCM region is
not clobbered by the DMA region.

Verilator lint (errors fatal) + iverilog sim asserting NPU_TOP_PASS. Skips if tools absent.
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
RTL = [ROOT / f"IP/npu/rtl/{m}.v" for m in ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm")]
TB = [ROOT / "IP/npu/dv/tb/axi_full_mem.v", ROOT / "IP/npu/dv/tb/tb_npu_top.v"]


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_npu_subsystem_lints_clean_of_errors():
    r = subprocess.run(
        ["verilator", "--lint-only", "-Wall", "-Wno-DECLFILENAME", "-Wno-MULTITOP",
         "-Wno-UNUSEDSIGNAL", *[str(p) for p in RTL]],
        capture_output=True, text=True,
    )
    assert "%Error" not in r.stderr, f"verilator lint errors:\n{r.stderr}"
    assert r.returncode == 0, f"verilator exited {r.returncode}:\n{r.stderr}"


@pytest.mark.skipif(not (shutil.which("iverilog") and shutil.which("vvp")), reason="no iverilog — not-run")
def test_npu_top_integration_scoreboard_passes(tmp_path):
    vvp = tmp_path / "top.vvp"
    subprocess.run(
        ["iverilog", "-g2012", "-o", str(vvp), *[str(p) for p in RTL], *[str(p) for p in TB]],
        check=True, capture_output=True, text=True,
    )
    out = subprocess.run(["vvp", str(vvp)], capture_output=True, text=True, timeout=120).stdout
    assert "NPU_TOP_PASS" in out, f"npu_top integration did not pass:\n{out}"
    assert "0 errors" in out, f"npu_top scoreboard reported mismatches:\n{out}"
