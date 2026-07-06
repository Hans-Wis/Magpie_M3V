"""gate_03_08_lockstep_revalidate - rebuild and rerun Phase 3.5 lockstep."""

from __future__ import annotations

import csv
import os
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_03_05_random_lockstep"
RTL = ROOT / "design/cpu_m1/rtl"

VFLAGS = (
    "--binary -j 4 --trace --trace-depth 2 --trace-structs "
    "--top-module tb_random_lockstep --timescale 1ns/1ns "
    f"-I{RTL} -Wall -Wno-PROCASSINIT -Wno-DECLFILENAME "
    "-Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET -Wno-PINMISSING"
)


def _rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def test_phase_03_08_rebuilds_current_rtl_and_reruns_lockstep():
    core = RTL / "core.v"
    before = (PHASE / "dut_commit.trace").stat().st_mtime_ns if (PHASE / "dut_commit.trace").exists() else 0
    env = os.environ.copy()
    res = subprocess.run(
        ["make", "-C", str(PHASE), "clean", "all", f"VFLAGS={VFLAGS}"],
        capture_output=True,
        text=True,
        env=env,
    )
    out = res.stdout + res.stderr
    assert res.returncode == 0, out[-5000:]
    assert "--top-module tb_random_lockstep" in out
    assert "-Wno-PINMISSING" in out
    assert "../../../design/cpu_m1/rtl/core.v" in out
    assert (PHASE / "dut_commit.trace").stat().st_mtime_ns > before
    assert "PASS: random lockstep matched" in out

    dut = _rows(PHASE / "dut_commit.trace")
    spike = _rows(PHASE / "spike_commit.trace")
    assert len(dut) >= 80
    assert dut == spike
