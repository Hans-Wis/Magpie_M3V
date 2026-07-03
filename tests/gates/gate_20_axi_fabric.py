"""gate_20_axi_fabric — Phase 1 AXI4-Lite fabric brick.

Verifies the first net-new bus slice of the two-core M3V SoC:
  host AXI4-Lite master  ->  axil_1to2 router  ->  { NPU CSR slave @0x3xxx , passthrough mem }

Checks (transaction scoreboard, `tb_axil_fabric.v`):
  - NPU presence (ID reg), CSR round-trips (SCRATCH/CONFIG), CTRL->npu_start, STATUS RO
  - address routing: 0x3xxx -> NPU, else -> passthrough; no cross-talk

Two stages: Verilator lint (errors fatal; style warnings allowed) + iverilog simulation
asserting AXIL_FABRIC_PASS. Skips (not-run) if verilator/iverilog absent (§9 honesty).
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
RTL = [ROOT / "IP/npu/rtl/axil_1to2.v", ROOT / "IP/npu/rtl/npu_axil_regs.v"]
TB = [ROOT / "IP/npu/dv/tb/axil_mem16.v", ROOT / "IP/npu/dv/tb/tb_axil_fabric.v"]


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_fabric_rtl_lints_clean_of_errors():
    r = subprocess.run(
        ["verilator", "--lint-only", "-Wall", "-Wno-DECLFILENAME", "-Wno-MULTITOP",
         "-Wno-UNUSEDSIGNAL", *[str(p) for p in RTL]],
        capture_output=True, text=True,
    )
    # warnings are allowed; only hard errors (%Error) fail the gate
    assert "%Error" not in r.stderr, f"verilator lint errors:\n{r.stderr}"
    assert r.returncode == 0, f"verilator exited {r.returncode}:\n{r.stderr}"


@pytest.mark.skipif(not (shutil.which("iverilog") and shutil.which("vvp")), reason="no iverilog — not-run")
def test_fabric_scoreboard_passes(tmp_path):
    vvp = tmp_path / "fabric.vvp"
    subprocess.run(
        ["iverilog", "-g2012", "-o", str(vvp), *[str(p) for p in RTL], *[str(p) for p in TB]],
        check=True, capture_output=True, text=True,
    )
    out = subprocess.run(["vvp", str(vvp)], capture_output=True, text=True, timeout=60).stdout
    assert "AXIL_FABRIC_PASS" in out, f"scoreboard did not pass:\n{out}"
    assert "0 errors" in out, f"scoreboard reported mismatches:\n{out}"
