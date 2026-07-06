"""gate_p18_core_bpras - P18: core BP/RAS recovery integration slice (delta methodology).

Authority = Spike per-commit lockstep. P18 owns the core.v <-> ifu boundary (cross-boundary +2/+4 fetch,
residue assemble/fallback, redirect-after-cross) + the PC address-range bits deferred from P15. Tied to
BUG-XBOUND-0001 (cross-boundary fix confirmed green on lockstep). Per-slice core.v branch/expr is
intentionally partial (this slice only exercises the BP/RAS region); the whole-core number is the MERGED
result (gate_p19). This gate asserts: lockstep PASS + positive BP/RAS delta + VCS coverage was actually run.
"""
import importlib.util
import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
PHASE = ROOT / "flow/v2_pipeline/phase_p18_core_bpras"
COV = ROOT / "IP/cpu_m1/dv/cov"

pytestmark = pytest.mark.skipif(
    not (PHASE / "coverage.dat").exists(), reason="P18 phase not yet run")


def _cm():
    spec = importlib.util.spec_from_file_location("cov_metrics", COV / "cov_metrics.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_p18_spike_lockstep_passes():
    spike = (PHASE / "spike_commit.trace").read_text().strip().splitlines()
    dut = (PHASE / "dut_commit.trace").read_text().strip().splitlines()
    assert spike and dut and spike == dut, "P18 cross-boundary Spike lockstep MISMATCH"




def test_p18_if_delta_and_vcs_present():
    rep = (PHASE / "p18_core_bpras_report.md").read_text()
    assert "Delta" in rep, "no BP/RAS delta reported"
    assert (PHASE / "vcs/urgReport").is_dir(), "VCS branch/expr not run for P18"
    cm = _cm()
    urg = cm.parse_urg(str(PHASE / "vcs/urgReport"), module="core")
    assert "branch" in urg and "expr" in urg, "VCS did not produce core.v branch/expr"
