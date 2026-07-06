"""gate_10_host_integrity — cpu_m1 host integrity (Phase 2 governance).

SUPERSEDED byte-identical freeze: per ADR-0032 (User directive 2026-07-03), cpu_m1 is now
MODIFIABLE in M3V, but every change must be FULLY VERIFIED. The behavioral guarantee therefore
moved from "source byte-identical to the freeze tag" to "host config produces byte-identical
Spike commit traces" — enforced by the lockstep re-run + gate_02_host_equivalence (trace-diff vs
the `m3v-pre-phase2-cpu` tag), not by this file.

This gate now only checks the host RTL is present and that its modification is governed by an ADR
(so a change can never land without the parameterization/verification contract in place).
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_host_rtl_present():
    core = ROOT / "design/cpu_m1/rtl/core.v"
    assert core.is_file(), "cpu_m1 host core.v missing — design/cpu_m1/rtl must be intact"


def test_cpu_m1_modification_is_adr_governed():
    adr = ROOT / "docs/adr/0032-cpu-param-phase2.md"
    assert adr.is_file(), "cpu_m1 is modifiable only under ADR-0032 (parameterization + full verification)"
    txt = adr.read_text(encoding="utf-8")
    assert "host trace-diff" in txt.lower() or "byte-identical commit traces" in txt.lower(), \
        "ADR-0032 must define the host-equivalence (commit-trace) acceptance bar"
