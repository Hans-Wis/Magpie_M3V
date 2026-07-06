"""gate_p12_ras - P12: ras unit coverage gate (Tier-2 Industrial) — hardest stateful, FSM + waivers.

4-agent loop: Grok charter + Gemini toggle enumeration -> Codex tb_csr_unit.v + Verilator + VCS/URG
(-cm fsm) -> Claude independently verifies waiver basis vs ras.v RTL, approves, accepts. Tier-2: line
100, branch 100, expr >=95, toggle >=95, FSM state+arc 100 — after JUSTIFIED structural waivers
(design/cpu_m1/dv/cov/waivers/P12_ras.json): counter cycle/instret[27:63], mstatus/mie/mip WPRI-reserved,
mtvec MODE, mepc[0] IALIGN, mstatus_mpp M-mode-forced. Dual-number RAW + ADJUSTED.
"""
import importlib.util
import json
import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
PHASE = ROOT / "flow/v2_pipeline/phase_p12_ras"
COV = ROOT / "design/cpu_m1/dv/cov"
WAIVER = COV / "waivers/P12_ras.json"
MODULE = "ras"

pytestmark = pytest.mark.skipif(
    not (PHASE / "coverage/coverage.dat").exists(), reason="P12 csr phase not yet run")


def _cm():
    spec = importlib.util.spec_from_file_location("cov_metrics", COV / "cov_metrics.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_p12_artifacts_exist():
    for p in ["../../../design/cpu_m1/dv/tb/tb_csr_unit.v", "coverage/coverage.dat",
              "coverage/coverage.info", "vcs/urgReport/mod1.html"]:
        assert (PHASE / p).resolve().exists(), f"missing P12 artifact: {p}"


def test_p12_golden_check_passed():
    logs = " ".join(p.read_text(errors="replace") for p in (PHASE / "logs").glob("*.log"))
    m = re.search(r"PASS: ras unit (\d+)/(\d+)", logs)
    assert m and int(m.group(1)) == int(m.group(2)) and int(m.group(1)) >= 30


def test_p12_line_toggle_tier2_adjusted():
    cm = _cm()
    rep = cm.dual_number([str(PHASE / "coverage/coverage.dat")],
                         info_paths=[str(PHASE / "coverage/coverage.info")],
                         waiver_path=str(WAIVER) if WAIVER.exists() else None)
    ln = rep["line"]["per_module"]["ras.v"]
    tg = rep["toggle"]["per_module"]["ras.v"]
    assert 100.0 * ln["adj"][0] / ln["adj"][1] == 100.0, f"adjusted line {ln['adj']} != 100% (raw {ln['raw']})"
    assert 100.0 * tg["adj"][0] / tg["adj"][1] >= 95.0, f"adjusted toggle {tg['adj']} < 95% (raw {tg['raw']})"


def test_p12_branch_expr_fsm_tier2_via_vcs():
    cm = _cm()
    urg = cm.parse_urg(str(PHASE / "vcs/urgReport"), module=MODULE)
    if "branch" in urg:
        assert urg["branch"]["pct"] == 100.0, f"branch {urg['branch']} < 100%"
    if "expr" in urg:
        assert urg["expr"]["pct"] >= 95.0, f"expr {urg['expr']} < 95%"
    if "fsm_state" in urg:
        assert urg["fsm_state"]["pct"] == 100.0, f"FSM state {urg['fsm_state']} != 100%"
    if "fsm_arc" in urg:
        assert urg["fsm_arc"]["pct"] == 100.0, f"FSM arc {urg['fsm_arc']} != 100%"


def test_p12_waivers_approved_and_structural():
    if not WAIVER.exists():
        return
    for wv in json.loads(WAIVER.read_text())["waivers"]:
        assert wv["approved"] is True and wv.get("approver"), "waiver not approved by Claude"
        assert wv.get("structural_basis") and wv["spike_impact"].startswith("none")
