#!/usr/bin/env python3
"""Compare a minimal DUT commit trace against Spike commit log."""

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
    run_spike(work_dir=ROOT, elf=ROOT / "firmware_spike.elf", log=SPIKE_LOG,
              isa="rv32imc_zba_zbb_zbs_zicsr_zifencei", instructions=80)

    def _mask_x0(rows):
        # x0 is architecturally never written; wdata for rd==0 is don't-care. This old
        # TB records the writeback bus even for x0-dest jumps (c.jr/ret/jr), unlike the
        # RVFI-based NPU trace. Canonicalize so the compare is on real writes only.
        for r in rows:
            if int(r["rd"]) == 0:
                r["wdata"] = 0
        return rows

    dut = _mask_x0(parse_dut_commits(DUT_TRACE))
    spike = _mask_x0(parse_spike_commits(
        SPIKE_LOG,
        limit=len(dut),
        pc_base=SPIKE_BASE,
        stop_instrs={0x0000_9002},
    ))
    write_commit_csv(SPIKE_TRACE, spike)
    ok, message = compare_commits(dut, spike, label="lockstep")
    REPORT.write_text(
        "# Phase 3.0 Spike Lockstep Report\n\n"
        f"Status: {'pass' if ok else 'fail'}\n\n"
        f"Result: {message}\n\n"
        "Compared fields: `pc`, `instr`, `rd`, `wdata`.\n\n"
        "Scope: minimal directed RV32IMC vertical slice. This is not random DV or coverage closure.\n",
        encoding="utf-8",
    )
    print(("PASS: " if ok else "FAIL: ") + message)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
