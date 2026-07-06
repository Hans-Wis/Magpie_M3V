"""gate_p16_core_if - P16: core IF / RV32C cross-boundary integration slice (delta methodology).

Authority = Spike per-commit lockstep. P16 owns the core.v <-> ifu boundary (cross-boundary +2/+4 fetch,
residue assemble/fallback, redirect-after-cross) + the PC address-range bits deferred from P15. Tied to
BUG-XBOUND-0001 (cross-boundary fix confirmed green on lockstep). Per-slice core.v branch/expr is
intentionally partial (this slice only exercises the IF region); the whole-core number is the MERGED
result (gate_p19). This gate asserts: lockstep PASS + positive IF delta + VCS coverage was actually run.
"""
import importlib.util
import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
PHASE = ROOT / "flow/v2_pipeline/phase_p16_core_if"
COV = ROOT / "design/cpu_m1/dv/cov"

pytestmark = pytest.mark.skipif(
    not (PHASE / "coverage.dat").exists(), reason="P16 phase not yet run")


def _cm():
    spec = importlib.util.spec_from_file_location("cov_metrics", COV / "cov_metrics.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_p16_spike_lockstep_passes():
    spike = (PHASE / "spike_commit.trace").read_text().strip().splitlines()
    dut = (PHASE / "dut_commit.trace").read_text().strip().splitlines()
    assert spike and dut and spike == dut, "P16 cross-boundary Spike lockstep MISMATCH"


def test_p16_xbound_bug_green():
    # BUG-XBOUND-0001 cross-boundary repro must be green (proven by the lockstep match above)
    rep = (PHASE / "p16_core_if_report.md").read_text()
    assert "lockstep matched" in rep, "P16 cross-boundary lockstep not reported as matched"
    assert (PHASE / "firmware.S").exists(), "P16 cross-boundary fixtures missing"


def test_p16_if_delta_and_vcs_present():
    rep = (PHASE / "p16_core_if_report.md").read_text()
    assert "Delta" in rep, "no IF delta reported"
    assert (PHASE / "vcs/urgReport").is_dir(), "VCS branch/expr not run for P16"
    cm = _cm()
    urg = cm.parse_urg(str(PHASE / "vcs/urgReport"), module="core")
    assert "branch" in urg and "expr" in urg, "VCS did not produce core.v branch/expr"
