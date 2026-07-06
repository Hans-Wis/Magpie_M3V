"""gate_p01_coverage_infra - P01: coverage infrastructure gate (hardened per Codex+Gemini P01 review).

Proves the per-stage acceptance infrastructure is SOUND before any P02+ gate builds on it. Uses
SYNTHETIC coverage data with KNOWN hit/miss points to assert exact RAW/ADJUSTED counts, and proves the
green-wash guards (blanket-waiver ban, un-approved-waiver ignore, RAW>=ADJUSTED invariant, source-line
metric via .info not .dat blocks). No RTL work.
"""
import importlib.util
import json
import textwrap
from pathlib import Path

import pytest


ROOT = Path(__file__).resolve().parents[1]
COV = ROOT / "IP/cpu_m1/dv/cov"

# The reporter self-tests run on SYNTHETIC data (always available). The one test that runs on
# REAL VCS coverage needs phase_04_0*_coverage/coverage.dat — licensed-EDA artifacts absent in a
# fresh checkout. Skip (not-run) rather than fail; M3V code coverage = Verilator in dv/gates.
_needs_real_cov = pytest.mark.skipif(
    not list(ROOT.glob("flow/v2_pipeline/phase_04_0*_coverage/coverage.dat")),
    reason="real VCS coverage.dat absent — licensed-EDA (EXTERNAL_DEPS.md §2/§3); "
    "synthetic-data infra tests still run",
)


def _cm():
    spec = importlib.util.spec_from_file_location("cov_metrics", COV / "cov_metrics.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _synthetic_dat(tmp: Path) -> Path:
    """Build a coverage.dat with 4 toggle points in module fake.v: 3 hit, 1 miss (the bit[31] one)."""
    SOH, STX = "\x01", "\x02"

    def pt(obj, hit):
        payload = (f"{SOH}f{STX}/x/fake.v{SOH}l{STX}10{SOH}n{STX}1{SOH}t{STX}toggle"
                   f"{SOH}page{STX}v_toggle/fake{SOH}o{STX}{obj}{SOH}h{STX}tb_x.dut")
        return f"C '{payload}' {1 if hit else 0}"
    lines = [pt("a[0]:0->1", True), pt("a[0]:1->0", True),
             pt("a[1]:0->1", True), pt("cycle_cnt[31]:0->1", False)]
    p = tmp / "coverage.dat"
    p.write_text("\n".join(lines), encoding="latin-1")
    return p


def _synthetic_info(tmp: Path) -> Path:
    p = tmp / "coverage.info"
    p.write_text(textwrap.dedent("""\
        SF:/x/fake.v
        DA:10,5
        DA:11,0
        DA:12,3
        end_of_record
        """), encoding="utf-8")
    return p


def test_p01_infra_files_exist():
    for f in ["cov_metrics.py", "waivers/SCHEMA.md"]:
        assert (COV / f).exists() and (COV / f).stat().st_size > 0, f"missing infra: {f}"


def test_p01_exact_raw_counts(tmp_path):
    cm = _cm()
    rep = cm.dual_number([_synthetic_dat(tmp_path)], info_paths=[_synthetic_info(tmp_path)])
    # toggle: 3 hit / 4 total ; line (source via .info): 2 hit / 3 total
    assert rep["toggle"]["raw"] == (3, 4), rep["toggle"]["raw"]
    assert rep["line"]["raw"] == (2, 3), rep["line"]["raw"]
    assert rep["line_is_blocks"] is False  # source-line metric, not .dat blocks
    # no waivers -> RAW == ADJUSTED exactly
    assert rep["toggle"]["adj"] == (3, 4) and rep["line"]["adj"] == (2, 3)


def test_p01_approved_bitrange_waiver_excludes_only_that_point(tmp_path):
    cm = _cm()
    dat, info = _synthetic_dat(tmp_path), _synthetic_info(tmp_path)
    w = {"waivers": [{"waiver_id": "TW-CYC31", "module": "fake.v", "signal_re": "cycle_cnt",
                      "bit_lo": 31, "bit_hi": 63, "approved": True, "approver": "Claude"}]}
    wp = tmp_path / "w.json"; wp.write_text(json.dumps(w))
    rep = cm.dual_number([dat], waiver_path=str(wp), info_paths=[info])
    # the single missing bit[31] toggle is waived -> adjusted toggle = 3/3 (100%), raw stays 3/4
    assert rep["toggle"]["raw"] == (3, 4)
    assert rep["toggle"]["adj"] == (3, 3)
    assert rep["toggle"]["adj_pct"] == 100.0 and rep["toggle"]["raw_pct"] == 75.0
    # invariant: adjusted hits never exceed raw hits
    assert rep["toggle"]["adj"][0] <= rep["toggle"]["raw"][0]


def test_p01_blanket_waiver_is_rejected(tmp_path):
    """CRITICAL green-wash guard: a catch-all waiver covering a whole module must NOT silently pass."""
    cm = _cm()
    dat, info = _synthetic_dat(tmp_path), _synthetic_info(tmp_path)
    blanket = {"waivers": [{"waiver_id": "BAD", "module": "fake.v", "signal_re": ".*",
                            "approved": True, "approver": "x"}]}
    wp = tmp_path / "bad.json"; wp.write_text(json.dumps(blanket))
    # catch-all + no bit range is INVALID -> ignored (RAW == ADJUSTED), never a free 100%
    rep = cm.dual_number([dat], waiver_path=str(wp), info_paths=[info])
    assert rep["toggle"]["adj"] == rep["toggle"]["raw"], "blanket waiver leaked!"


def test_p01_unapproved_waiver_is_ignored(tmp_path):
    cm = _cm()
    dat, info = _synthetic_dat(tmp_path), _synthetic_info(tmp_path)
    w = {"waivers": [{"waiver_id": "U", "module": "fake.v", "signal_re": "cycle_cnt",
                      "bit_lo": 31, "approved": False}]}
    wp = tmp_path / "u.json"; wp.write_text(json.dumps(w))
    rep = cm.dual_number([dat], waiver_path=str(wp), info_paths=[info])
    assert rep["toggle"]["adj"] == rep["toggle"]["raw"], "un-approved waiver applied!"


def test_p01_over_fraction_waiver_raises(tmp_path):
    """A single waiver excluding > WAIVER_MAX_FRAC of a module's points raises (blanket guard)."""
    cm = _cm()
    dat, info = _synthetic_dat(tmp_path), _synthetic_info(tmp_path)
    # signals list matching ALL 4 points (a[ and cycle) with no bit range -> ~100% of module
    w = {"waivers": [{"waiver_id": "TOOBIG", "module": "fake.v",
                      "signals": ["a[", "cycle_cnt"], "approved": True, "approver": "x"}]}
    wp = tmp_path / "big.json"; wp.write_text(json.dumps(w))
    with pytest.raises(cm.CoverageError):
        cm.dual_number([dat], waiver_path=str(wp), info_paths=[info])


def test_p01_branch_expr_requires_real_vcs_run():
    cm = _cm()
    # branch/expr come from VCS/URG only — parse_urg must REFUSE to invent numbers without a real
    # URG report dir (so a stage cannot be marked done on branch/expr without actually running VCS).
    with pytest.raises(cm.CoverageError):
        cm.parse_urg("/nonexistent")


@_needs_real_cov
def test_p01_reporter_runs_on_real_coverage():
    import glob
    cm = _cm()
    dats = sorted(glob.glob(str(ROOT / "flow/v2_pipeline/phase_04_0*_coverage/coverage.dat")))
    infos = sorted(glob.glob(str(ROOT / "flow/v2_pipeline/phase_04_0*_coverage/coverage/coverage.info")))
    assert dats and infos
    rep = cm.dual_number(dats, info_paths=infos)
    # source-line denominator must be the real ~1432 lines, NOT the ~216 .dat-block undercount
    assert rep["line"]["raw"][1] > 1000, f"line denominator looks like blocks not source: {rep['line']['raw']}"
    assert rep["toggle"]["raw"][1] > 10000
    assert "BRANCH/EXPR/FSM" in cm.format_report(rep, scope="P01-real")
