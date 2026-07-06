"""gate_03_15_bp_way1_lockstep - branch-predictor 2-way (way1) directed lockstep (blocker #1, u_bp).

The random riscv-dv farm leaves the BTB's SECOND way's READ/PREDICT path cold (rd_hit1 /
predict_from_way1 = 0/2): random branches rarely alias to the same BTB set with a distinct tag
and re-execute taken. phase_03_15_bp_way1 forces it deterministically — two always-taken
branches brA@0x100 (set 0, tag 0x2) and brB@0x180 (set 0, tag 0x3) in a 16-iteration loop fill
both ways; re-fetching brB then READS way1 and predicts from it. Being fully deterministic it is
FULL per-commit Spike lockstep (no trap), authority = Spike.

This is the one genuinely-reachable u_bp gap; the rest of u_bp's untoggled bits are address-range-
limited high PC/tag bits + sticky valid (no invalidate) + the saturating-counter monotonic edge,
classified as structural waiver (classify_ifu_bp_waiver.py, coverage_report §2.12). Per-island
coverage (distinct TB hierarchy -> cross-TB unmergeable, same caveat as gate_03_14).
"""

import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_03_15_bp_way1"


def _read(name: str) -> str:
    return (PHASE / name).read_text(encoding="utf-8")


def test_phase_03_15_artifacts_exist():
    for name in ["firmware.S", "firmware.lds", "firmware_spike.lds", "Makefile",
                 "tb_bp_way1.v", "bp_way1.py", "firmware.hex", "sim.log",
                 "spike.log", "bp_way1.log"]:
        p = PHASE / name
        assert p.exists() and p.stat().st_size > 0, f"missing/empty artifact: {name}"


def test_phase_03_15_program_has_aliasing_branches():
    disasm = _read("firmware.disasm")
    # brA @ 0x100 and brB @ 0x180 — same BTB set 0 (PC[5:1]=0), different tags.
    assert re.search(r"^\s*100:\s", disasm, re.M), "brA must be pinned at 0x100"
    assert re.search(r"^\s*180:\s", disasm, re.M), "brB must be pinned at 0x180"


def test_phase_03_15_full_lockstep_pass():
    log = _read("bp_way1.log")
    assert log.lstrip().startswith("PASS"), f"bp_way1 lockstep not PASS: {log!r}"
    assert "full lockstep matched" in log


def test_phase_03_15_way1_read_predict_toggles():
    """The island must toggle the way1 READ + PREDICT path that the random farm leaves cold."""
    cov = PHASE / "coverage.dat"
    if not (cov.exists() and cov.stat().st_size > 0):
        pytest.skip("coverage.dat not built (run `make` in phase_03_15_bp_way1)")
    hits = {}
    for line in cov.read_text(errors="replace").splitlines():
        m = re.match(r"^C '(.*)' (\d+)\s*$", line)
        if not m:
            continue
        key, cnt = m.group(1), int(m.group(2))
        fld = dict((x[0], x.split("\002", 1)[1]) for x in key.split("\001") if "\002" in x)
        if fld.get("t") != "toggle" or fld.get("h", "").split(".")[-1] != "u_bp":
            continue
        base = re.sub(r"\[.*", "", fld.get("o", "?")).split(":")[0]
        if cnt > 0:
            hits[base] = hits.get(base, 0) + 1
    for sig in ("rd_hit1", "predict_from_way1", "wr_hit1"):
        assert hits.get(sig, 0) > 0, f"way1 signal {sig} did not toggle"
