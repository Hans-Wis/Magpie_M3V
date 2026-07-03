"""gate_34_npu_core_strip_coverage — ADR-0032/0034 strip-coverage bar for the NPU config.

Runs the phase_20 lockstep (directed + one 10k-commit random seed) under Verilator
--coverage-line on the npu_top instance and enforces:
- bp.v/ras.v/cdec.v contribute ZERO coverage points (the EN_*=0 strip is RTL-elaboration
  level, not a TB disable — green-wash guard),
- every reachable EN_RVC/EN_BP/EN_RAS guard line is covered (none uncovered),
- ifu.v (the EN_RVC-parameterized module that stays live) >=95% line coverage,
- residual uncovered core.v lines are written to coverage_report.md for triage
  (debug/trap/unreachable-in-stripped-config classes — same discipline as phase_04_00).
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_20_npu_core_lockstep"

MISSING_TOOL = not (shutil.which("verilator") and shutil.which("spike"))


@pytest.mark.skipif(MISSING_TOOL, reason="verilator/spike absent — not-run")
def test_npu_strip_coverage_bar():
    r = subprocess.run(["make", "-C", str(PHASE), "coverage"], capture_output=True, text=True)
    assert r.returncode == 0, f"coverage run failed:\n{r.stdout[-4000:]}\n{r.stderr[-2000:]}"
    log = (PHASE / "coverage.log").read_text()
    assert log.startswith("PASS"), f"strip-coverage analyzer: {log}"
    report = (PHASE / "coverage_report.md").read_text()
    assert "Status: pass" in report
    assert "generate-off at elaboration" in report
