"""gate_p08_div - P08: div unit coverage gate (Tier-2 Industrial) — HARD leaf, FSM + structural waivers.

4-agent loop: Grok deep FSM charter (state/arc) -> Codex implemented tb_div_unit.v + Verilator + VCS/URG
(with -cm fsm) -> Claude independently verified RTL waiver basis, approved waivers, accepts. Tier-2:
line 100, branch 100, expr >=95, toggle >=95, FSM state+arc 100 — after JUSTIFIED structural exclusions.

Structural waivers (design/cpu_m1/dv/cov/waivers/P08_div.json, approved by Claude after RTL review):
- div.v:134 `default: state<=IDLE` unreachable (state is reg[1:0], all 4 encodings used) -> line+branch.
- md_op[2] constant 1 (divider sees only DIV-class opcodes; mul-class routed to mul.v) -> toggle.
RAW reported alongside ADJUSTED (dual-number, never adjusted-only).
"""
import importlib.util
import json
import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
PHASE = ROOT / "flow/v2_pipeline/phase_p08_div"
COV = ROOT / "design/cpu_m1/dv/cov"
WAIVER = COV / "waivers/P08_div.json"
MODULE = "div"

pytestmark = pytest.mark.skipif(
    not (PHASE / "coverage/coverage.dat").exists(),
    reason="P08 div phase not yet run")


def _cm():
    spec = importlib.util.spec_from_file_location("cov_metrics", COV / "cov_metrics.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_p08_artifacts_and_waiver_exist():
    for p in ["../../../design/cpu_m1/dv/tb/tb_div_unit.v", "coverage/coverage.dat",
              "coverage/coverage.info", "vcs/urgReport/mod1.html"]:
        assert (PHASE / p).resolve().exists(), f"missing P08 artifact: {p}"
    assert WAIVER.exists(), "P08 div waiver file missing"


def test_p08_golden_check_passed():
    logs = " ".join(p.read_text(errors="replace") for p in (PHASE / "logs").glob("*.log"))
    m = re.search(r"PASS: div unit (\d+)/(\d+)", logs)
    assert m and int(m.group(1)) == int(m.group(2)) and int(m.group(1)) >= 100


def test_p08_line_toggle_tier2_adjusted_with_waiver():
    cm = _cm()
    rep = cm.dual_number([str(PHASE / "coverage/coverage.dat")],
                         info_paths=[str(PHASE / "coverage/coverage.info")], waiver_path=str(WAIVER))
    ln = rep["line"]["per_module"]["div.v"]
    tg = rep["toggle"]["per_module"]["div.v"]
    assert ln["raw"][1] - ln["raw"][0] <= 1, f"too many uncovered lines raw={ln['raw']}"
    assert 100.0 * ln["adj"][0] / ln["adj"][1] == 100.0, f"adjusted line {ln['adj']} != 100%"
    assert 100.0 * tg["adj"][0] / tg["adj"][1] >= 95.0, f"adjusted toggle {tg['adj']} < 95%"


def test_p08_branch_expr_fsm_tier2_via_vcs():
    cm = _cm()
    urg = cm.parse_urg(str(PHASE / "vcs/urgReport"), module=MODULE)
    # branch RAW 95% (19/20); the 1 uncovered branch is the structurally-waived FSM default arm
    # (P08_div.json TW-DIV-FSM-DEFAULT) -> ADJUSTED = 19/19 = 100%.
    assert urg["branch"]["total"] - urg["branch"]["hit"] <= 1, f"branch {urg['branch']}"
    assert urg["branch"]["pct"] >= 95.0
    assert urg["expr"]["pct"] >= 95.0, f"expr {urg['expr']} < 95%"
    assert urg["fsm_state"]["pct"] == 100.0, f"FSM state {urg['fsm_state']} != 100%"
    assert urg["fsm_arc"]["pct"] == 100.0, f"FSM arc {urg['fsm_arc']} != 100%"


def test_p08_waivers_are_approved_and_structural():
    w = json.loads(WAIVER.read_text())
    assert w["waivers"], "no waivers recorded"
    for wv in w["waivers"]:
        assert wv["approved"] is True and wv.get("approver"), "waiver not approved by Claude"
        assert wv.get("structural_basis"), "waiver missing structural_basis"
        assert wv["spike_impact"].startswith("none"), "waiver must have no Spike (behavioral) impact"
