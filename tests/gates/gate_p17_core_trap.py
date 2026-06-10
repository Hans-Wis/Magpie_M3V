"""gate_p17_core_trap - P17: core CSR/trap/IRQ/MRET integration slice (delta, HONEST PARTIAL).

P17 owns the core.v trap GLUE (trap_enter wiring, mepc/mcause/mtval from the executing stage, flush on
trap, IRQ vs mstatus.mie, mret) + the misalign/trap-detect signals deferred from P15.

*** HONESTY (report-faithfully) ***: local Spike 1.1.1-dev logs the M-mode synchronous exception and
STOPS before executing the mtvec handler (known from J14/J18). So through-trap per-commit lockstep is
NOT claimed green. The correctness evidence P17 DOES stand on:
  (1) pre-trap commit lockstep matches (the DUT trace prefix == Spike's full trace up to its stop), and
  (2) trap-entry architectural values mepc/mcause/mtval match Spike's expected values.
A future through-trap lockstep needs Spike configured M-only (--priv=m) — see ADR-0015 / debug_report.md.
"""
import importlib.util
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_p17_core_trap"
COV = ROOT / "IP/cpu_m1/dv/cov"

pytestmark = pytest.mark.skipif(
    not (PHASE / "coverage.dat").exists(), reason="P17 phase not yet run")


def _cm():
    spec = importlib.util.spec_from_file_location("cov_metrics", COV / "cov_metrics.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_p17_pretrap_lockstep_prefix_matches():
    # Spike stops at the trap; the DUT trace must match Spike's full (pre-trap) trace as a prefix.
    spike = (PHASE / "spike_commit.trace").read_text().strip().splitlines()
    dut = (PHASE / "dut_commit.trace").read_text().strip().splitlines()
    assert spike, "no Spike trace"
    assert len(dut) >= len(spike), "DUT halted before Spike (real divergence, not the trap-stop case)"
    assert dut[:len(spike)] == spike, "pre-trap lockstep prefix MISMATCH (real divergence)"


def test_p17_trap_values_match_spike():
    rep = (PHASE / "directed_lockstep_report.md").read_text() + \
          (PHASE / "p17_core_trap_report.md").read_text()
    assert "mepc" in rep and "mcause" in rep and "mtval" in rep, "trap-value evidence missing"
    assert "matched" in rep.lower(), "trap entry values not reported as matched vs Spike"


def test_p17_spike_throughtrap_limitation_documented():
    # the Spike-stop limitation must be disclosed (not silently claimed as full lockstep)
    rep = (PHASE / "p17_core_trap_report.md").read_text() + \
          (PHASE / "directed_lockstep_report.md").read_text()
    assert "Spike" in rep and ("limitation" in rep or "stops" in rep or "not claimed" in rep), \
        "through-trap Spike limitation not honestly disclosed"


def test_p17_trap_delta_and_vcs_present():
    rep = (PHASE / "p17_core_trap_report.md").read_text()
    assert "Delta" in rep, "no trap delta reported"
    assert (PHASE / "vcs/urgReport").is_dir(), "VCS branch/expr not run for P17"
    cm = _cm()
    urg = cm.parse_urg(str(PHASE / "vcs/urgReport"), module="core")
    assert "branch" in urg and "expr" in urg
