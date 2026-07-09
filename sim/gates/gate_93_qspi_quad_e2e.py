"""gate_93_qspi_quad_e2e — ADR-0071 D1: quad mode end-to-end on the SoC.

Host boots from imem (quad COLD BOOT IS NOT CLAIMED — reset is single-lane,
ADR honesty bound), enables MODE.QUAD via the CSR, then:

  D-side XIP reads bit-exact vs the image golden (single baseline first),
  a sequential quad warm streak, EXECUTION FROM FLASH — the firmware calls an
  XIP-resident routine at 0x4000_0800 and asserts its return magic (instruction
  fetch over quad 1-4-4), then restores single-lane and re-verifies.

Gate-level counters: qcold>0 AND qwarm>0 from SOC_QSPI_STATS (quad frames
really opened and continuous-read really engaged).
"""

import re
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
from gate_92_qspi_prog import IMG, VERILATOR, build_tb, run_fw  # noqa: E402


@pytest.mark.skipif(not shutil.which("verilator") and not VERILATOR.exists(),
                    reason="no verilator — not-run")
def test_quad_e2e(tmp_path):
    binary = build_tb(tmp_path)
    r = run_fw(binary, "host_qspi_quad", "host_qspi_quad.hex")
    out = r.stdout
    assert "SOC_QSPI_PASS" in out, out[-3000:]
    m = re.search(r"SOC_QSPI_STATS cold=\d+ warm=\d+ qcold=(\d+) qwarm=(\d+)", out)
    assert m, out[-1500:]
    assert int(m.group(1)) > 0 and int(m.group(2)) > 0, \
        f"quad counters not engaged (qcold={m.group(1)} qwarm={m.group(2)}):\n{out[-1500:]}"
    assert r.returncode == 0, out[-1500:]
