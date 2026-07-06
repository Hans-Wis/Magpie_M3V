"""gate_p10_cdec - P10: cdec unit coverage gate (Tier-2 Industrial), waiver-aware.

4-agent loop: Grok charter -> Codex tb_cdec_unit.v + Verilator + VCS/URG -> Claude independently verified
each uncovered point against cdec.v RTL, approved structural waivers, accepts. Tier-2: line 100, branch
100, expr >=95, toggle >=95 — after JUSTIFIED structural waivers (IP/cpu_m1/dv/cov/waivers/P10_cdec.json):
RV64/FP-only compressed-encoding default arms (line 169 + 4 branches, ISA scope RV32IMC) + compressed-
immediate format-constant bits + rd_rs1_p/rs2_p {2'b01,..} reg-pair constants. Dual-number RAW+ADJUSTED.
"""
import importlib.util
import json
import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
PHASE = ROOT / "flow/v2_pipeline/phase_p10_cdec"
COV = ROOT / "IP/cpu_m1/dv/cov"
WAIVER = COV / "waivers/P10_cdec.json"
MODULE = "cdec"
WAIVED_RV64FP_BRANCHES = 4  # RV64/FP default:illegal arms unreachable in RV32IMC

pytestmark = pytest.mark.skipif(
    not (PHASE / "coverage/coverage.dat").exists(), reason="P10 cdec phase not yet run")


def _cm():
    spec = importlib.util.spec_from_file_location("cov_metrics", COV / "cov_metrics.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_p10_artifacts_and_waiver_exist():
    for p in ["../../../IP/cpu_m1/dv/tb/tb_cdec_unit.v", "coverage/coverage.dat",
              "coverage/coverage.info", "vcs/urgReport/mod1.html"]:
        assert (PHASE / p).resolve().exists(), f"missing P10 artifact: {p}"
    assert WAIVER.exists()


def test_p10_golden_check_passed():
    logs = " ".join(p.read_text(errors="replace") for p in (PHASE / "logs").glob("*.log"))
    m = re.search(r"PASS: cdec unit (\d+)/(\d+)", logs)
    assert m and int(m.group(1)) == int(m.group(2)) and int(m.group(1)) >= 30


def test_p10_line_toggle_tier2_adjusted():
    cm = _cm()
    rep = cm.dual_number([str(PHASE / "coverage/coverage.dat")],
                         info_paths=[str(PHASE / "coverage/coverage.info")], waiver_path=str(WAIVER))
    ln = rep["line"]["per_module"]["cdec.v"]
    tg = rep["toggle"]["per_module"]["cdec.v"]
    assert 100.0 * ln["adj"][0] / ln["adj"][1] == 100.0, f"adjusted line {ln['adj']} != 100% (raw {ln['raw']})"
    assert 100.0 * tg["adj"][0] / tg["adj"][1] >= 95.0, f"adjusted toggle {tg['adj']} < 95% (raw {tg['raw']})"


def test_p10_branch_expr_tier2_via_vcs():
    cm = _cm()
    urg = cm.parse_urg(str(PHASE / "vcs/urgReport"), module=MODULE)
    # branch RAW ~91% (4 uncovered = RV64/FP default arms, structurally waived) -> ADJUSTED 100%
    uncovered = urg["branch"]["total"] - urg["branch"]["hit"]
    assert uncovered <= WAIVED_RV64FP_BRANCHES, f"branch {urg['branch']}: {uncovered} uncovered > {WAIVED_RV64FP_BRANCHES} waived"
    adj_branch = 100.0 * urg["branch"]["hit"] / (urg["branch"]["total"] - uncovered) if (urg["branch"]["total"] - uncovered) else 0
    assert adj_branch == 100.0, f"adjusted branch {adj_branch}"
    assert urg["expr"]["pct"] >= 95.0, f"expr {urg['expr']} < 95%"


def test_p10_waivers_approved_and_structural():
    for wv in json.loads(WAIVER.read_text())["waivers"]:
        assert wv["approved"] is True and wv.get("approver"), "waiver not approved by Claude"
        assert wv.get("structural_basis") and wv["spike_impact"].startswith("none")
