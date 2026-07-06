"""gate_a3_dtcm - ADR-0026 Phase A3 (as amended 2026-06-12): dual-bank D-TCM macro.

A3 scope (amended, Grok-concurred): dtcm.v IP-delivered dual-bank TCM — 32-bit core-port
semantics IDENTICAL to the flat 1-cycle model; 64-bit wide READ port = the documented Phase-B
interface (vector LSU / GEMV weed feed), directed-exercised (a stub without exercise is dead
logic). Core RTL untouched by A3. The ORIGINAL "loadstream >=3.5 B/c" KPI was amended in the ADR
(scalar issue physics, not memory — see the amendment note).

Asserts:
  1. unit KPI: wide port sustains 8 B/c (64/64 grants) + byte-lanes + arbitration + coherence
  2. dtcm-in-the-loop directed lockstep PASS (full per-commit, A2 program, background wide
     reader >=50 coherent grants concurrent with the running core)
  3. zero scalar regression BY CONSTRUCTION: core RTL has no working-tree diff (A3 = macro only)
  4. honest taxonomy: wrapper-equivalence is NOT claimed — REPAIR-0001 records the inherited
     tb_mem_wrapper bit-rot (broken at compile since pre-freeze; row = not-run until repaired)
"""

import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
A3 = ROOT / "flow/v2_pipeline/phase_a3_dtcm"


def test_a3_unit_kpi_wide_8_bytes_per_cycle():
    log = (A3 / "unit_run.log").read_text()
    assert "= 8 B/c" in log, "wide-port 8 B/c KPI line missing"
    assert any(l.startswith("PASS") for l in log.splitlines()), "unit not PASS"
    assert "64/64 grants" in log


def test_a3_dtcm_in_the_loop_lockstep():
    log = (A3 / "a3_dtcm.log").read_text()
    assert log.lstrip().startswith("PASS"), f"in-the-loop lockstep not PASS: {log!r}"
    m = re.search(r"matched (\d+) commits", log)
    assert m and int(m.group(1)) >= 55
    sim = (A3 / "sim.log").read_text()
    mg = re.search(r"wide reader (\d+) coherent grants", sim)
    assert mg and int(mg.group(1)) >= 50, "background wide reader under-exercised"


def test_a3_core_rtl_untouched():
    """A3 = SoC-side macro only; the core/wrapper contract RTL must have no uncommitted diff
    beyond dtcm.v itself (zero scalar regression by construction)."""
    out = subprocess.run(["git", "diff", "--name-only", "--", "design/cpu_m1/rtl/"],
                         capture_output=True, text=True, cwd=ROOT).stdout.strip().splitlines()
    touched = [f for f in out if not f.endswith("dtcm.v")]
    assert not touched, f"A3 must not touch core RTL: {touched}"
    assert (ROOT / "design/cpu_m1/rtl/dtcm.v").exists()


def test_a3_repair_disposition_honest():
    rep = (ROOT / "flow/v2_pipeline/phase_02_01_mem_wrapper/REPAIR_NEEDED.md").read_text()
    assert "not-run" in rep and "REPAIR-0001" in rep, "wrapper-eq must be honestly dispositioned"
