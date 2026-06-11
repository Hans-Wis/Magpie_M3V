#!/usr/bin/env python3
"""Compare the DUT commit trace against Spike for the stall x cross-boundary stress.

Directed proof for the BUG-XBOUND-0001 "Open lead": stall/redirect landing on a
consecutive cross-boundary 32-bit RVC run. Per-commit equivalence to Spike (pc /
instr / rd / wdata) confirms the resumed {cur_half_lo, residue} assembles correctly
and the wrong-path instruction never commits.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "lib"))
from spike_commit import compare_commits, parse_dut_commits, parse_spike_commits, run_spike, write_commit_csv


ROOT = Path(__file__).resolve().parent
SPIKE_LOG = ROOT / "spike.log"
SPIKE_TRACE = ROOT / "spike_commit.trace"
DUT_TRACE = ROOT / "dut_commit.trace"
REPORT = ROOT / "lockstep_report.md"
SPIKE_BASE = 0x8000_0000


def main() -> int:
    run_spike(work_dir=ROOT, elf=ROOT / "firmware_spike.elf", log=SPIKE_LOG, instructions=120)
    dut = parse_dut_commits(DUT_TRACE)
    spike = parse_spike_commits(
        SPIKE_LOG,
        limit=len(dut),
        pc_base=SPIKE_BASE,
        stop_instrs={0x0000_9002},  # c.ebreak: stop before the halt instruction (symmetric with DUT)
    )
    write_commit_csv(SPIKE_TRACE, spike)
    ok, message = compare_commits(dut, spike, label="stall_xboundary lockstep")
    REPORT.write_text(
        "# Phase 3.11 Stall x Cross-Boundary Spike Lockstep Report\n\n"
        f"Status: {'pass' if ok else 'fail'}\n\n"
        f"Result: {message}\n\n"
        "Compared fields: `pc`, `instr`, `rd`, `wdata`.\n\n"
        "Scope: directed stress for load-use/muldiv stall + branch redirect landing on a\n"
        "consecutive cross-boundary 32-bit RVC run (BUG-XBOUND-0001 open lead). Not random DV.\n",
        encoding="utf-8",
    )
    print(("PASS: " if ok else "FAIL: ") + message)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
