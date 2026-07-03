#!/usr/bin/env python3
"""ADR-0036 gate_40/41 comparator: vector-CSR state via the P0④ checkpoint discipline.

Every vset{i}vl{i} rd write and every csrr vl/vtype/vstart/vxsat/vcsr/vlenb checkpoint is an
ordinary scalar commit — compared bit-exact against Spike --isa=rv32im_zve32x_zvl128b
(no C, no F: the green-wash guard is the ISA string itself).
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "lib"))
from spike_commit import compare_commits, parse_dut_commits, parse_spike_commits, run_spike, write_commit_csv

ROOT = Path(__file__).resolve().parent
SPIKE_BASE = 0x8000_0000
VCSR_ISA = "rv32im_zve32x_zvl128b_zicsr_zifencei"
EBREAK_32 = 0x0010_0073


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--min-commits", type=int, default=40)
    args = ap.parse_args()

    run_spike(work_dir=ROOT, elf=ROOT / "firmware_spike.elf", log=ROOT / "spike.log",
              isa=VCSR_ISA, instructions=2000)
    dut = parse_dut_commits(ROOT / "dut_commit.trace")
    if len(dut) < args.min_commits:
        print(f"FAIL: DUT trace has {len(dut)} commits < required {args.min_commits}")
        return 1
    spike = parse_spike_commits(ROOT / "spike.log", limit=len(dut), pc_base=SPIKE_BASE,
                                stop_instrs={EBREAK_32})
    write_commit_csv(ROOT / "spike_commit.trace", spike)
    ok, message = compare_commits(dut, spike, label="vcsr-lockstep")
    (ROOT / "lockstep_report.md").write_text(
        "# ADR-0036 3A vector-CSR lockstep report (P0④)\n\n"
        f"Status: {'pass' if ok else 'fail'}\n\nResult: {message}\n\n"
        f"Commits compared: {len(dut)} (bar: >= {args.min_commits})\n\n"
        f"Spike ISA: `{VCSR_ISA}`. Checkpoint discipline: csrr vl/vtype/vstart after every\n"
        "config change; vsetvli rd values in-stream (ADR-0036 P0④ contract).\n",
        encoding="utf-8",
    )
    print(("PASS: " if ok else "FAIL: ") + f"{message} ({len(dut)} commits)")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
