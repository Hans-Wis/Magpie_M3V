"""gate_25_npu_dma — Phase 1 data-plane (AXI4-full + DMA).

Verifies the weight/activation bandwidth path of the two-core M3V SoC:
  host --AXI4-Lite--> npu_axil_regs (DMA descriptor CSRs) --> npu_dma
  npu_dma --AXI4-full INCR read bursts--> shared weight memory --> NPU local buffer

The integration tb (`tb_npu_dma.v`) programs the DMA over the AXI4-Lite fabric exactly as
host firmware would (SRC/DST/LEN then GO), polls STATUS.dma_done, and checks every copied
word. Stimulus deliberately forces **multi-burst chunking (>256 beats)** AND a **4 KB-boundary
crossing** so the AXI-legal burst splitting is exercised, not just a single short burst.

Verilator lint (errors fatal) + iverilog sim asserting NPU_DMA_PASS. Skips if tools absent.
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
RTL = [ROOT / "IP/npu/rtl/axil_1to2.v", ROOT / "IP/npu/rtl/npu_axil_regs.v", ROOT / "IP/npu/rtl/npu_dma.v"]
TB = [ROOT / "IP/npu/dv/tb/axi_full_mem.v", ROOT / "IP/npu/dv/tb/tb_npu_dma.v"]


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_dataplane_rtl_lints_clean_of_errors():
    r = subprocess.run(
        ["verilator", "--lint-only", "-Wall", "-Wno-DECLFILENAME", "-Wno-MULTITOP",
         "-Wno-UNUSEDSIGNAL", *[str(p) for p in RTL]],
        capture_output=True, text=True,
    )
    assert "%Error" not in r.stderr, f"verilator lint errors:\n{r.stderr}"
    assert r.returncode == 0, f"verilator exited {r.returncode}:\n{r.stderr}"


@pytest.mark.skipif(not (shutil.which("iverilog") and shutil.which("vvp")), reason="no iverilog — not-run")
def test_dma_burst_copy_scoreboard_passes(tmp_path):
    vvp = tmp_path / "dma.vvp"
    subprocess.run(
        ["iverilog", "-g2012", "-o", str(vvp), *[str(p) for p in RTL], *[str(p) for p in TB]],
        check=True, capture_output=True, text=True,
    )
    out = subprocess.run(["vvp", str(vvp)], capture_output=True, text=True, timeout=120).stdout
    assert "NPU_DMA_PASS" in out, f"DMA scoreboard did not pass:\n{out}"
    assert "0 errors" in out, f"DMA scoreboard reported mismatches:\n{out}"
