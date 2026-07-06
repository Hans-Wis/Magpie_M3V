"""gate_p19_integration_merged - P19: merged core.v integration coverage (P15-P18 union), honest.

Delta methodology closure: the 4 integration slices (P15-P18) each Spike-lockstep-verified, merged for
the core.v integrator number. This gate asserts the MERGED result + that all 4 slice gates exist + the
residual is attributed (docs/reports/integration_closure.md). It does NOT claim core.v 100% — the
compound-expr tail is the separate whole-core riscv-dv-farm milestone (documented, not faked).
"""
import importlib.util
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
MERGED = ROOT / "flow/v2_pipeline/phase_p15_18_merged/merged_urgReport"
COV = ROOT / "design/cpu_m1/dv/cov"
CLOSURE = ROOT / "docs/reports/integration_closure.md"

pytestmark = pytest.mark.skipif(not MERGED.is_dir(), reason="P15-18 merge not yet produced")


def _cm():
    spec = importlib.util.spec_from_file_location("cov_metrics", COV / "cov_metrics.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_p19_all_four_slice_gates_present():
    g = ROOT / "gates"
    for name in ["gate_p15_core_datapath.py", "gate_p16_core_if.py",
                 "gate_p17_core_trap.py", "gate_p18_core_bpras.py"]:
        assert (g / name).exists(), f"missing integration slice gate {name}"


def test_p19_merged_core_branch_and_expr():
    cm = _cm()
    urg = cm.parse_urg(str(MERGED), module="core")
    # merged branch ~96%, expr ~79% — the achieved integration number (RAW, honest; residual attributed)
    assert urg["branch"]["pct"] >= 95.0, f"merged core.v branch regressed: {urg['branch']}"
    assert urg["expr"]["pct"] >= 78.0, f"merged core.v expr regressed: {urg['expr']}"


def test_p19_residual_attributed_not_blanket_waived():
    assert CLOSURE.exists(), "integration closure report missing"
    txt = CLOSURE.read_text()
    # residual must be attributed by owner, and the whole-core farm honestly named as the 100% path
    for key in ["Structural", "Trap paths", "SKU", "whole-core riscv-dv", "Not** claimed"]:
        assert key in txt, f"closure report missing honest attribution: {key!r}"
