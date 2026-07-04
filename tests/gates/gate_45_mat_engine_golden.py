"""gate_45_mat_engine_golden — ADR-0037 4A: the matrix engine is bit-exact vs the golden.

Regenerates the vectors from IP/npu/golden/mat_golden.py (whose --selftest pins the
gemmlowp bit-truths: SRDHM negative-halves-toward-zero, double rounding, INT32_MIN
saturation) and runs the unit TB: 90 rescale corners + 24 random CLR→OP(rpt)→RESCALE
sequences with all 64 output bytes compared + param-error probes (bank>=4, shift<31,
rpt=0). Case counts are asserted so a parse failure can never silently shrink coverage
(that exact failure mode happened during bring-up).
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_23_mat_engine"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_mat_engine_bit_exact_vs_golden():
    r = subprocess.run(["make", "-C", str(PHASE), "all"], capture_output=True, text=True)
    assert r.returncode == 0, f"unit TB failed:\n{r.stdout[-4000:]}\n{r.stderr[-2000:]}"
    log = (PHASE / "sim.log").read_text()
    assert "MAT_ENGINE_PASS" in log
    assert "part1: 90 rescale corners" in log, "corner count shrank (parse guard tripped?)"
    assert "part2: 24 sequences" in log
    assert ", 0 errors" in log


def test_golden_selftest_pins_gemmlowp_truths():
    r = subprocess.run(["python3", str(ROOT / "IP/npu/golden/mat_golden.py"), "--selftest"],
                       capture_output=True, text=True)
    assert r.returncode == 0 and "golden selftest PASS" in r.stdout
