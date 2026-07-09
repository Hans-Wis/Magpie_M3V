"""gate_91_qspi_quad_readback — ADR-0071 D1: quad 1-4-4 XIP unit authority.

Same acceptance role as gate_85 but for the quad path (qspi_xip_quad +
qspi_master_p2 arrive from M6 with ZERO source-repo DV). tb_qspi_xip_readback
runs the single-lane battery first (gate_85's contract, unchanged), then the
quad phase per the ADR-0071 §5 FROZEN timing table (goldens derive from the
table + image, not from RTL waveforms):

  quad cold read / warm continuous streak (quad_warm_reads>0) / I-D interleave
  re-seek / D-write SLVERR / beyond-image 0xFFFFFFFF / idle I-priority /
  single->quad->single MODE flips at idle / mid-stream MODE flip -> next read
  re-opens COLD / io_oe overlap assertion every SCLK edge (TB $fatal).

This gate asserts the quad markers + stat line; gate_85 keeps owning the
single-lane markers so a quad-side red doesn't mask a single-lane one.
"""

import re
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
from gate_85_qspi_xip_readback import FILES, IMG, VERILATOR  # noqa: E402


@pytest.mark.skipif(not shutil.which("verilator") and not VERILATOR.exists(),
                    reason="no verilator — not-run")
def test_qspi_quad_readback(tmp_path):
    assert IMG.exists()
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
    m = re.search(r"QSPI_QUAD_READBACK_PASS cold=\d+ warm=\d+ quad_cold=(\d+) quad_warm=(\d+)", out)
    assert m, f"quad PASS stat line missing:\n{out[-3000:]}\n{r.stderr[-1000:]}"
    assert int(m.group(1)) > 0 and int(m.group(2)) > 0, \
        f"quad cold/warm counters not both engaged:\n{out[-1500:]}"
    assert r.returncode == 0, out[-1500:]
