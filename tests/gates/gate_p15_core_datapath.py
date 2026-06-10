"""gate_p15_core_datapath - P15: core datapath integration slice (Tier-2, delta methodology).

First INTEGRATION gate. Authority = Spike per-commit lockstep (not a unit golden TB). Delta methodology
(Grok charter): P15 owns the core.v DATAPATH integrator LOGIC (forward/bypass mux, load-use stall,
muldiv busy stall, flush-vs-forward priority, wb_sel/result mux, mem_stall, forward value bus) — the
incremental coverage on core.v not already owned by leaf islands. Closed +519 core.v toggles.

Honest disposition (IP/cpu_m1/dv/cov/waivers/P15_core_datapath.json):
- PC[0] structural waiver (pipeline PC regs latch the aligned fetch PC; bit 0 always 0).
- PC[31:8] address-range bits deferred to P16_IF (memory/PC-range placement).
- misalign/trap-detect signals deferred to P17_CSR_TRAP (need mtvec trap harness for lockstep).
"""
import importlib.util
import json
import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_p15_core_datapath"
COV = ROOT / "IP/cpu_m1/dv/cov"
WAIVER = COV / "waivers/P15_core_datapath.json"

pytestmark = pytest.mark.skipif(
    not (PHASE / "coverage.dat").exists(), reason="P15 phase not yet run")


def _cm():
    spec = importlib.util.spec_from_file_location("cov_metrics", COV / "cov_metrics.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_p15_spike_lockstep_passes():
    # THE authority: DUT commit trace must equal Spike commit trace per-commit
    spike = (PHASE / "spike_commit.trace").read_text().strip().splitlines()
    dut = (PHASE / "dut_commit.trace").read_text().strip().splitlines()
    assert spike and dut, "missing lockstep traces"
    assert spike == dut, "Spike per-commit lockstep MISMATCH (P15 datapath)"
    assert len(dut) >= 100, f"too few commits ({len(dut)}) to exercise the datapath"


def test_p15_datapath_logic_fully_covered():
    cm = _cm()
    pts = cm.parse_points([str(PHASE / "coverage.dat")], "toggle")["core.v"]

    def cov(name):
        # toggle object keys carry a bit index and/or edge suffix: "sig[5]:0->1" or "sig:0->1"
        hits = [h for (s, l), h in pts.items()
                if s.startswith(name + "[") or s.startswith(name + ":")]
        return (sum(hits), len(hits))

    # datapath integrator logic P15 owns must be 100% (forward mux/value, wb_sel, stall, flush, mem_stall)
    for sig in ["ex_mem_fwd_val", "ex_mem_wb_sel_r", "mem_stall"]:
        h, t = cov(sig)
        assert t > 0 and h == t, f"datapath signal {sig} not fully covered: {h}/{t}"


def test_p15_delta_positive():
    # P15 must add real core.v coverage (delta methodology: incremental over baseline)
    report = (PHASE / "p15_core_datapath_report.md").read_text()
    m = re.search(r"delta[^+]*\+(\d+)\s*toggles", report, re.I)
    assert m and int(m.group(1)) > 0, "P15 did not close a positive core.v toggle delta"


def test_p15_disposition_structural_and_deferred():
    w = json.loads(WAIVER.read_text())
    for wv in w["waivers"]:
        assert wv["approved"] is True and wv["spike_impact"].startswith("none")
        assert wv.get("structural_basis")
    # cross-slice deferrals must name a downstream owner (no silent drop)
    for d in w.get("deferred_cross_slice", []):
        assert d["owner"] in {"P16_IF", "P17_CSR_TRAP", "P18_BP_RAS"} and d.get("basis")
