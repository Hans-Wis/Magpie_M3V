#!/usr/bin/env python3
"""Compare expanded directed DUT commit trace against Spike."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "lib"))
from spike_commit import compare_commits, parse_dut_commits, parse_spike_commits, run_spike, write_commit_csv


ROOT = Path(__file__).resolve().parent
SPIKE_BASE = 0x8000_0000


def main() -> int:
    run_spike(
        work_dir=ROOT,
        elf=ROOT / "firmware_spike.elf",
        log=ROOT / "spike.log",
        pc_base=SPIKE_BASE,
        instructions=160,
    )
    dut = parse_dut_commits(ROOT / "dut_commit.trace")
    spike = parse_spike_commits(
        ROOT / "spike.log",
        limit=len(dut),
        pc_base=SPIKE_BASE,
        stop_instrs={0x0000_9002},
    )
    write_commit_csv(ROOT / "spike_commit.trace", spike)
    ok, message = compare_commits(dut, spike, label="directed lockstep")
    (ROOT / "directed_lockstep_report.md").write_text(
        "# Phase 3.4 Expanded Directed Lockstep Report\n\n"
        f"Status: {'pass' if ok else 'fail'}\n\n"
        f"Result: {message}\n\n"
        "Compared fields: `pc`, `instr`, `rd`, `wdata`.\n\n"
        "Scope: expanded directed RV32IMC slice; not random DV, riscv-dv, or coverage closure.\n",
        encoding="utf-8",
    )
    print(("PASS: " if ok else "FAIL: ") + message)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
