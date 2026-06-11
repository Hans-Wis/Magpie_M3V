#!/usr/bin/env python3
"""phase_a2_zb — A1 issue-decoupled MUL directed lockstep (ADR-0026 A1).

Deterministic, trap-free program -> FULL per-commit Spike lockstep over the whole trace.
Covers the hazard corners of the load-like MUL design (b2b issue, mul-use dist 1/2, mul->mul
RAW, sign matrix, load interplay, wrong-path squash, div/mul arbitration). Authority = Spike."""

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
EBREAK_INSTRS = {0x0010_0073, 0x0000_9002}


def main() -> int:
    run_spike(work_dir=ROOT, elf=ROOT / "firmware_spike.elf", log=ROOT / "spike.log",
              isa="rv32imc_zba_zbb_zbs_zicond_zicsr_zifencei",   # A2 ISA (misa.B parity)
              instructions=400)
    dut = parse_dut_commits(ROOT / "dut_commit.trace")
    spike = parse_spike_commits(ROOT / "spike.log", limit=len(dut), pc_base=SPIKE_BASE,
                                stop_instrs=EBREAK_INSTRS)
    write_commit_csv(ROOT / "spike_commit.trace", spike)
    ok, message = compare_commits(dut[: len(spike)], spike, label="a2_zb full lockstep")
    ok = ok and len(spike) >= 55          # the whole directed program must really run
    (ROOT / "a2_zb_report.md").write_text(
        "# Phase A1 MUL Directed Lockstep Report\n\n"
        f"Status: {'pass' if ok else 'fail'}\n\n"
        f"Result: {message} ({len(spike)} commits)\n\n"
        "Corners: b2b mul, mul-use dist1/dist2, mul->mul RAW, MULH/MULHSU/MULHU sign matrix, "
        "mul/load interplay, wrong-path mul squash, div<->mul arbitration. FULL per-commit "
        "Spike lockstep (trap-free by construction; trap-x-mul covered by the riscv-dv farm).\n",
        encoding="utf-8",
    )
    print(("PASS: " if ok else "FAIL: ") + f"{message} ({len(spike)} commits)")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
