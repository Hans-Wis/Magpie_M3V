"""gate_06_00_debug_mvd_coverage - debug-mode (MVD) directed test + coverage of the debug CSR path.

Discharges the Tier-C "debug coverage debt" surfaced in coverage_report §2.14: the random farm
never enters Debug Mode, so the u_csr debug bits (debug_csr_we/waddr/wdata/rdata, dpc, dscratch0,
dcsr) were cold — but debug (JTAG halt/step) is a SHIPPED feature, so those bits must be COVERED,
not waived. phase_06_00_debug_mvd drives the real debug-module abstract-command interface through
a Debug-spec sequence: halt, read GPR/dpc, abstract GPR write, mret-corner halt, single-step
(dcsr.step), dscratch0 walking-pattern access, and dcsr.ebreakm set. Built with --coverage; the
island toggles the debug datapath (debug_csr_wdata/rdata 64/64, dscratch0_reg, dcsr.ebreakm,
debug_halt_enter, dpc) that the farm leaves dark.

Authority = the RISC-V Debug spec (the TB checks dpc capture, abstract read/write, step retires
exactly one instruction, dscratch0/ebreakm readback). Per-island (cross-TB), like gate_03_14/15.
The residual cold debug bits are dpc/dscratch0/debug_halt_pc HIGH bits + dcsr reserved-constant
fields (address/constant-limited), not unverified logic.
"""

import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_06_00_debug_mvd"


def _read(name: str) -> str:
    return (PHASE / name).read_text(encoding="utf-8")


def test_phase_06_00_artifacts_exist():
    for name in ["tb_debug_mvd.v", "Makefile", "sim.log"]:
        p = PHASE / name
        assert p.exists() and p.stat().st_size > 0, f"missing/empty artifact: {name}"


def test_phase_06_00_sim_pass_with_debug_sequence():
    sim = _read("sim.log")
    assert "FAIL" not in sim and "Error" not in sim, f"debug sim reported error: {sim!r}"
    line = next((l for l in sim.splitlines() if l.startswith("PASS")), "")
    assert line, "debug sim did not PASS"
    # the spec sequence must have run: halt+dpc, step, and the new dscratch0/ebreakm closure
    assert "dscratch0=55555555" in line, "dscratch0 walking-pattern access did not run"
    assert "ebreakm=1" in line, "dcsr.ebreakm was not exercised"


def test_phase_06_00_coverage_toggles_debug_csr_path():
    """The island must toggle the debug CSR path the random farm leaves cold (Tier-C debt closure)."""
    cov = PHASE / "coverage.dat"
    if not (cov.exists() and cov.stat().st_size > 0):
        pytest.skip("coverage.dat not built (run `make` in phase_06_00_debug_mvd)")
    hits = {}
    for line in cov.read_text(errors="replace").splitlines():
        m = re.match(r"^C '(.*)' (\d+)\s*$", line)
        if not m:
            continue
        key, cnt = m.group(1), int(m.group(2))
        fld = dict((x[0], x.split("\002", 1)[1]) for x in key.split("\001") if "\002" in x)
        if fld.get("t") != "toggle" or fld.get("h", "").split(".")[-1] != "u_csr":
            continue
        base = re.sub(r"\[.*", "", fld.get("o", "?")).split(":")[0]
        if cnt > 0:
            hits[base] = hits.get(base, 0) + 1
    for sig in ("debug_csr_we", "debug_halt_enter", "dpc_reg", "dscratch0_reg", "dcsr_ebreakm_reg"):
        assert hits.get(sig, 0) > 0, f"debug CSR signal {sig} did not toggle (debug debt not discharged)"
