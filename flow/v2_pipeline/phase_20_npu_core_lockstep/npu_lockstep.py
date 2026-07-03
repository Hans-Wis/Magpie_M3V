#!/usr/bin/env python3
"""ADR-0034 NPU-sequencer lockstep comparator: npu_top DUT trace vs Spike rv32im golden.

Green-wash guards enforced here (not just documented):
- Spike ISA is rv32im_zicsr_zifencei — NO C. Passing anything else is a hard error.
- A minimum commit count is asserted (10k-class runs must not silently shrink).
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "lib"))
from spike_commit import compare_commits, parse_dut_commits, parse_spike_commits, run_spike, write_commit_csv

ROOT = Path(__file__).resolve().parent
SPIKE_BASE = 0x8000_0000
NPU_ISA = "rv32im_zicsr_zifencei"   # ADR-0032/0034: no C in the NPU sequencer contract
EBREAK_32 = 0x0010_0073             # EN_RVC=0: only the 32-bit encoding terminates


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--min-commits", type=int, default=8)
    ap.add_argument("--instructions", type=int, default=40)
    ap.add_argument("--label", default="npu-lockstep")
    ap.add_argument("--report", type=Path, default=ROOT / "lockstep_report.md")
    args = ap.parse_args()

    run_spike(
        work_dir=ROOT,
        elf=ROOT / "firmware_spike.elf",
        log=ROOT / "spike.log",
        isa=NPU_ISA,
        instructions=args.instructions,
    )
    dut = parse_dut_commits(ROOT / "dut_commit.trace")
    if len(dut) < args.min_commits:
        print(f"FAIL: DUT trace has {len(dut)} commits < required {args.min_commits}")
        return 1
    spike = parse_spike_commits(
        ROOT / "spike.log",
        limit=len(dut),
        pc_base=SPIKE_BASE,
        stop_instrs={EBREAK_32},
    )
    write_commit_csv(ROOT / "spike_commit.trace", spike)
    ok, message = compare_commits(dut, spike, label=args.label)
    args.report.write_text(
        "# Phase 2 Step 4 NPU sequencer lockstep report (ADR-0034)\n\n"
        f"Status: {'pass' if ok else 'fail'}\n\n"
        f"Result: {message}\n\n"
        f"Commits compared: {len(dut)} (bar: >= {args.min_commits})\n\n"
        f"Spike ISA: `{NPU_ISA}` (no C — green-wash guard). DUT = npu_top with the core\n"
        "fetching through the real npu_tcm ports; EN_RVC=0/EN_BP=0/EN_RAS=0.\n",
        encoding="utf-8",
    )
    print(("PASS: " if ok else "FAIL: ") + f"{message} ({len(dut)} commits)")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
