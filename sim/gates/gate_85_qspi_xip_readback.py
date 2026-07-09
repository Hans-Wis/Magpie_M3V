"""gate_85_qspi_xip_readback — ADR-0069 Step B: QSPI XIP front-end unit authority.

M6's qspi_xip/qspi_master_p0 arrive with ZERO functional DV in their source repo
(unproven IP per ADR-0069) — this gate is their acceptance authority, exercising
the §4.1a frozen semantics against our own spi_nor_model (mode-0, 0x03,
continuous-read, auto-increment while CS low, 0xFF erased):

  cold first read / warm sequential streaming (warm_reads>0 asserted) /
  I-D interleave with forced re-seeks (the arbiter+continuous-read main risk) /
  D-side write -> SLVERR and flash untouched / beyond-image reads = 0xFFFFFFFF /
  idle simultaneous I+D arbitration -> I first.

All data checks are bit-exact vs the same hex image the model loads.
tb_qspi_xip_readback self-checks ($fatal on any mismatch) and prints
QSPI_READBACK_PASS only at the end — this gate asserts that marker plus a clean
exit, and greps that every named check actually ran (no silent scope shrink).
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
VERILATOR = Path("/home/edauser/miniforge3/envs/magpie_claude/bin/verilator")

FILES = [
    ROOT / "design/soc/qspi/qspi_master_p0.sv",
    ROOT / "design/soc/qspi/qspi_xip.sv",
    ROOT / "design/soc/qspi/qspi_master_p2.sv",
    ROOT / "design/soc/qspi/qspi_xip_quad.sv",
    ROOT / "design/soc/qspi/qspi_axil_front.v",
    ROOT / "design/npu/dv/tb/spi_nor_model.v",
    ROOT / "design/npu/dv/tb/tb_qspi_xip_readback.v",
]
IMG = ROOT / "design/npu/dv/tb/xip_img_smoke.hex"


@pytest.mark.skipif(not shutil.which("verilator") and not VERILATOR.exists(),
                    reason="no verilator — not-run")
def test_qspi_xip_readback(tmp_path):
    assert IMG.exists(), "xip_img_smoke.hex missing — flash image is part of the gate"
    obj = tmp_path / "obj_dir"
    cmd = [str(VERILATOR), "--binary", "--timing", "-j", "4",
           "--top-module", "tb_qspi_xip_readback", "--timescale", "1ns/1ns",
           "-Mdir", str(obj),
           "-Wno-fatal", "-Wno-DECLFILENAME", "-Wno-TIMESCALEMOD",
           "-Wno-UNUSEDSIGNAL", "-Wno-SYNCASYNCNET"]
    cmd += [str(f) for f in FILES]
    r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    assert r.returncode == 0, f"verilator build failed:\n{r.stdout[-3000:]}\n{r.stderr[-2000:]}"

    r = subprocess.run([str(obj / "Vtb_qspi_xip_readback"), f"+FLASH_HEX={IMG}"],
                       cwd=ROOT, capture_output=True, text=True, timeout=600)
    out = r.stdout
    assert "QSPI_READBACK_PASS" in out, f"no PASS marker:\n{out[-3000:]}\n{r.stderr[-1000:]}"
    assert r.returncode == 0, out[-1500:]
