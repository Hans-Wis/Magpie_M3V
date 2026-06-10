"""gate_p03_lsu - P03: lsu unit coverage gate (Tier-2 Industrial).

Leaf unit gate (template = gate_p02_alu). 4-agent loop: Grok charter (.run/p03_08/grok_charters.log
P03 section; funct3-default coverable by illegal-funct3 vector, not a waiver) -> Codex implemented
tb_lsu_unit.v + Verilator + VCS/URG -> Claude verifies via cov_metrics + parse_urg and accepts.

Tier-2: line 100, branch 100, expr/cond >=95, toggle >=95, FSM N/A (combinational). No waivers expected.
"""
import importlib.util
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_p03_lsu"
COV = ROOT / "IP/cpu_m1/dv/cov"
MODULE = "lsu"


def _cm():
    spec = importlib.util.spec_from_file_location("cov_metrics", COV / "cov_metrics.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_p03_artifacts_exist():
    for p in ["../../../IP/cpu_m1/dv/tb/tb_lsu_unit.v", "coverage/coverage.dat",
              "coverage/coverage.info", "vcs/urgReport/mod0.html"]:
        f = (PHASE / p).resolve()
        assert f.exists() and f.stat().st_size > 0, f"missing P03 artifact: {p}"


def test_p03_golden_check_passed():
    logs = " ".join(p.read_text(errors="replace") for p in (PHASE / "logs").glob("*.log"))
    m = re.search(r"PASS: lsu unit (\d+)/(\d+) vectors", logs)
    assert m and int(m.group(1)) == int(m.group(2)) and int(m.group(1)) >= 30, "lsu golden short/failed"


def test_p03_line_and_toggle_meet_tier2():
    cm = _cm()
    rep = cm.dual_number([str(PHASE / "coverage/coverage.dat")],
                         info_paths=[str(PHASE / "coverage/coverage.info")])
    ln = rep["line"]["per_module"][f"{MODULE}.v"]
    tg = rep["toggle"]["per_module"][f"{MODULE}.v"]
    line_pct = 100.0 * ln["adj"][0] / ln["adj"][1]
    tog_pct = 100.0 * tg["adj"][0] / tg["adj"][1]
    assert line_pct == 100.0, f"line {line_pct:.1f}% < 100% Tier-2 (funct3 default must be covered)"
    assert tog_pct >= 95.0, f"toggle {tog_pct:.1f}% < 95% Tier-2"


def test_p03_branch_and_expr_meet_tier2_via_vcs():
    cm = _cm()
    urg = cm.parse_urg(str(PHASE / "vcs/urgReport"), module=MODULE)
    assert urg["branch"]["pct"] == 100.0, f"branch {urg['branch']} < 100% Tier-2"
    assert urg["expr"]["pct"] >= 95.0, f"expr {urg['expr']} < 95% Tier-2"
