"""gate_p02_alu - P02: alu unit coverage gate (Tier-2 Industrial).

First leaf unit gate of the incremental coverage campaign (coverage_gate_plan.md). 4-agent loop:
Grok charter (.run/p02_alu/grok_charter.log) -> Codex implemented tb_alu_unit.v + ran Verilator + VCS/URG
-> Claude (this gate) independently verifies via cov_metrics + parse_urg and accepts.

Tier-2 acceptance (after justified exclusions): line 100, branch 100, expr/cond >=95, toggle >=95,
FSM N/A (alu is combinational). Line 67 (case default) is COVERED by the invalid-op directed vector
(Grok ruling: coverable, NOT a waiver). No waivers for alu.
"""
import importlib.util

import pytest
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PHASE = ROOT / "flow/v2_pipeline/phase_p02_alu"
COV = ROOT / "IP/cpu_m1/dv/cov"
MODULE = "alu"

_needs_vcs_cov = pytest.mark.skipif(
    not (PHASE / "coverage" / "coverage.dat").exists(),
    reason="VCS/URG unit-coverage artifacts absent — licensed-EDA signoff "
    "(EXTERNAL_DEPS.md §2/§3); M3V code coverage = Verilator in dv/gates gate_91.")


def _cm():
    spec = importlib.util.spec_from_file_location("cov_metrics", COV / "cov_metrics.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


@_needs_vcs_cov
def test_p02_artifacts_exist():
    for p in ["../../../IP/cpu_m1/dv/tb/tb_alu_unit.v", "coverage/coverage.dat",
              "coverage/coverage.info", "vcs/urgReport/mod0.html"]:
        f = (PHASE / p).resolve()
        assert f.exists() and f.stat().st_size > 0, f"missing P02 artifact: {p}"


def test_p02_golden_check_passed():
    logs = " ".join(p.read_text(errors="replace") for p in (PHASE / "logs").glob("*.log"))
    m = re.search(r"PASS: alu unit (\d+)/(\d+) vectors", logs)
    assert m, "alu unit golden check did not PASS"
    assert int(m.group(1)) == int(m.group(2)) and int(m.group(1)) >= 100, "golden vectors short"


@_needs_vcs_cov
def test_p02_line_and_toggle_meet_tier2():
    cm = _cm()
    rep = cm.dual_number([str(PHASE / "coverage/coverage.dat")],
                         info_paths=[str(PHASE / "coverage/coverage.info")])
    al_line = rep["line"]["per_module"][f"{MODULE}.v"]
    al_tog = rep["toggle"]["per_module"][f"{MODULE}.v"]
    line_pct = 100.0 * al_line["adj"][0] / al_line["adj"][1]
    tog_pct = 100.0 * al_tog["adj"][0] / al_tog["adj"][1]
    assert line_pct == 100.0, f"line {line_pct:.1f}% < 100% Tier-2 (no waivers for alu)"
    assert tog_pct >= 95.0, f"toggle {tog_pct:.1f}% < 95% Tier-2"


@_needs_vcs_cov
def test_p02_branch_and_expr_meet_tier2_via_vcs():
    cm = _cm()
    urg = cm.parse_urg(str(PHASE / "vcs/urgReport"), module=MODULE)
    assert urg["branch"]["pct"] == 100.0, f"branch {urg['branch']} < 100% Tier-2"
    assert urg["expr"]["pct"] >= 95.0, f"expr {urg['expr']} < 95% Tier-2"


@_needs_vcs_cov
def test_p02_line67_default_is_covered_not_waived():
    # the case default (line 67) must be hit by the invalid-op vector, not waived
    info = (PHASE / "coverage/coverage.info").read_text(errors="replace")
    in_alu = False
    for ln in info.splitlines():
        if ln.startswith("SF:"):
            in_alu = ln.endswith("alu.v")
        elif in_alu and ln.startswith("DA:67,"):
            assert int(ln.split(",")[1]) > 0, "line 67 (default) not covered"
            return
    # if line 67 not present at all, fail (must be instrumented + hit)
    assert False, "line 67 not found in alu.v coverage"
