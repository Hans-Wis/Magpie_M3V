#!/usr/bin/env python3
"""phase_03_15 bp_way1 — directed 2-way BTB associativity, FULL per-commit Spike lockstep.

The program is purely deterministic (always-taken aliasing branches in a loop), so unlike the
async-IRQ slices this is full per-commit lockstep across the WHOLE trace (no trap halts Spike's
commit log). Authority = Spike. The --coverage island then shows the u_bp second-way path
(rd_hit1 / predict_from_way1 / valid1 / way1 counter) toggling — the one genuinely-reachable
u_bp gap the random farm never hits (the rest of u_bp's untoggled is address-range-limited high
PC/tag bits + sticky valid, classified as structural waiver in classify_ifu_bp_waiver.py)."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "lib"))
from spike_commit import (
    compare_commits,
    parse_dut_commits,
    parse_spike_commits,
    run_spike,
    write_commit_csv,
)

ROOT = Path(__file__).resolve().parent
SPIKE_BASE = 0x8000_0000
SPIKE_LOG = ROOT / "spike.log"
DUT_TRACE = ROOT / "dut_commit.trace"
SPIKE_TRACE = ROOT / "spike_commit.trace"
EBREAK_INSTRS = {0x0010_0073, 0x0000_9002}   # ebreak / c.ebreak terminate both models


def main() -> int:
    run_spike(work_dir=ROOT, elf=ROOT / "firmware_spike.elf", log=SPIKE_LOG, instructions=400)
    dut = parse_dut_commits(DUT_TRACE)
    spike = parse_spike_commits(SPIKE_LOG, limit=len(dut), pc_base=SPIKE_BASE,
                                stop_instrs=EBREAK_INSTRS)
    write_commit_csv(SPIKE_TRACE, spike)
    ok, message = compare_commits(dut[: len(spike)], spike, label="bp_way1 full lockstep")
    ok = ok and len(spike) >= 40        # the 16-iter loop must actually run
    (ROOT / "bp_way1_report.md").write_text(
        "# Phase 3.15 Branch-Predictor 2-Way (way1) Directed Lockstep Report\n\n"
        f"Status: {'pass' if ok else 'fail'}\n\n"
        f"Result: {message} ({len(spike)} commits)\n\n"
        "Deterministic aliasing-branch loop (brA@0x100 tag2 / brB@0x180 tag3, same BTB set 0) "
        "-> fills both predictor ways. FULL per-commit Spike lockstep (no trap). The --coverage "
        "island toggles the way1 read/predict path (rd_hit1 / predict_from_way1) that the random "
        "farm leaves cold.\n",
        encoding="utf-8",
    )
    print(("PASS: " if ok else "FAIL: ") + f"{message} ({len(spike)} commits)")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
