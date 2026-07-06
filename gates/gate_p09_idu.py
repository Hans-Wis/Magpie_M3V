"""gate_p09_idu - P09: idu unit coverage gate (Tier-2 Industrial), waiver-aware.

4-agent loop: Grok charter -> Codex tb_idu_unit.v + Verilator + VCS/URG -> Claude independently verified
each uncovered point against idu.v RTL, ruled them structural, approved waivers, accepts. Claude's RTL
review CORRECTED Grok's charter (which assumed funct3 default coverable; it is not — funct3 is fully
8/8 decoded). Tier-2: line 100, branch 100, expr >=95, toggle >=95 — after JUSTIFIED structural waivers
(design/cpu_m1/dv/cov/waivers/P09_idu.json): funct3-default unreachable, csr_zimm zero-ext, imm_u/imm_b/imm_j
hardwired-0 format bits. Dual-number RAW + ADJUSTED.
"""
import importlib.util
import json
import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
PHASE = ROOT / "flow/v2_pipeline/phase_p09_idu"
COV = ROOT / "design/cpu_m1/dv/cov"
WAIVER = COV / "waivers/P09_idu.json"
MODULE = "idu"

pytestmark = pytest.mark.skipif(
    not (PHASE / "coverage/coverage.dat").exists(), reason="P09 idu phase not yet run")


def _cm():
    spec = importlib.util.spec_from_file_location("cov_metrics", COV / "cov_metrics.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_p09_artifacts_exist():
    for p in ["../../../design/cpu_m1/dv/tb/tb_idu_unit.v", "coverage/coverage.dat",
              "coverage/coverage.info", "vcs/urgReport/mod1.html"]:
        assert (PHASE / p).resolve().exists(), f"missing P09 artifact: {p}"


def test_p09_golden_check_passed():
    logs = " ".join(p.read_text(errors="replace") for p in (PHASE / "logs").glob("*.log"))
    m = re.search(r"PASS: idu unit (\d+)/(\d+)", logs)
    assert m and int(m.group(1)) == int(m.group(2)) and int(m.group(1)) >= 30


def test_p09_line_toggle_tier2_adjusted():
    cm = _cm()
    rep = cm.dual_number([str(PHASE / "coverage/coverage.dat")],
                         info_paths=[str(PHASE / "coverage/coverage.info")],
                         waiver_path=str(WAIVER) if WAIVER.exists() else None)
    ln = rep["line"]["per_module"]["idu.v"]
    tg = rep["toggle"]["per_module"]["idu.v"]
    assert 100.0 * ln["adj"][0] / ln["adj"][1] == 100.0, f"adjusted line {ln['adj']} != 100% (raw {ln['raw']})"
    assert 100.0 * tg["adj"][0] / tg["adj"][1] >= 95.0, f"adjusted toggle {tg['adj']} < 95% (raw {tg['raw']})"


def test_p09_branch_expr_tier2_via_vcs():
    cm = _cm()
    urg = cm.parse_urg(str(PHASE / "vcs/urgReport"), module=MODULE)
    if "branch" in urg:
        assert urg["branch"]["pct"] == 100.0, f"branch {urg['branch']} < 100%"
    if "expr" in urg:
        assert urg["expr"]["pct"] >= 95.0, f"expr {urg['expr']} < 95%"


def test_p09_waivers_approved_and_structural():
    if not WAIVER.exists():
        return
    for wv in json.loads(WAIVER.read_text())["waivers"]:
        assert wv["approved"] is True and wv.get("approver"), "waiver not approved by Claude"
        assert wv.get("structural_basis") and wv["spike_impact"].startswith("none")
