#!/usr/bin/env python3
"""ADR-0035 gate_39 comparator: CQ consume slice, npu_top DUT vs Spike rv32im golden.

The Spike image carries the MMIO/DMA shadow seeds (firmware_cq.S -DSPIKE_SEED), so every
load in the commit stream is deterministic. ISA guard: rv32im_zicsr_zifencei, no C.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "lib"))
from spike_commit import compare_commits, parse_dut_commits, parse_spike_commits, run_spike, write_commit_csv

ROOT = Path(__file__).resolve().parent
SPIKE_BASE = 0x8000_0000
NPU_ISA = "rv32im_zicsr_zifencei"
EBREAK_32 = 0x0010_0073


def main() -> int:
    run_spike(work_dir=ROOT, elf=ROOT / "firmware_spike.elf", log=ROOT / "spike.log",
              isa=NPU_ISA, instructions=1000)
    dut = parse_dut_commits(ROOT / "dut_commit.trace")
    if len(dut) < 8:
        print(f"FAIL: DUT trace has only {len(dut)} commits")
        return 1
    spike = parse_spike_commits(ROOT / "spike.log", limit=len(dut), pc_base=SPIKE_BASE,
                                stop_instrs={EBREAK_32}, normalize_window=0x4_0000)
    write_commit_csv(ROOT / "spike_commit.trace", spike)
    ok, message = compare_commits(dut, spike, label="cq-lockstep")
    (ROOT / "lockstep_report.md").write_text(
        "# ADR-0035 gate_39 CQ-consume lockstep report\n\n"
        f"Status: {'pass' if ok else 'fail'}\n\nResult: {message}\n\n"
        f"Commits compared: {len(dut)}\n\n"
        f"Spike ISA: `{NPU_ISA}` (no C). MMIO shadow = Spike-image seeding "
        "(descriptor, weights, STATUS=0x19, HEAD/TAIL) — see firmware_cq.S.\n",
        encoding="utf-8",
    )
    print(("PASS: " if ok else "FAIL: ") + f"{message} ({len(dut)} commits)")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
