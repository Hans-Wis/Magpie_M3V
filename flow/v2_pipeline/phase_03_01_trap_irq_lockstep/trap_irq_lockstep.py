#!/usr/bin/env python3
"""Compare pre-IRQ DUT commits against Spike and check trap/CSR events."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "lib"))
from spike_commit import (
    check_expected_events,
    compare_commits,
    parse_dut_commits,
    parse_spike_commits,
    parse_trap_events,
    run_spike,
    write_commit_csv,
)


ROOT = Path(__file__).resolve().parent
SPIKE_BASE = 0x8000_0000
IRQ_TARGET_PC = 0x80
EXPECTED_EVENTS = {
    "irq_entry": (0x80, 0x82),
    "mepc": (None, 0x82),
    "mcause": (None, 0x8000_000B),
    # Handler mstatus = MPP=2'b11 (0x1800, M-mode) + MPIE=1 (0x80); spec Priv §3.1.6.
    # firmware presets mstatus=0x1808 (Spike: c768_mstatus 0x1808) then trap entry => 0x1880.
    # Updated from stale 0x80 (pre-MPP golden) to spec/Spike-correct 0x1880. P2 2026-06-09.
    "mstatus": (None, 0x1880),
    "mret": (None, 0x82),
    "resume": (None, 0x600D),
}

def compare() -> tuple[bool, str]:
    dut = parse_dut_commits(ROOT / "dut_commit.trace")
    spike = parse_spike_commits(
        ROOT / "spike.log",
        limit=len(dut),
        pc_base=SPIKE_BASE,
        stop_pc=IRQ_TARGET_PC,
    )
    write_commit_csv(ROOT / "spike_prefix.trace", spike)
    ok, message = compare_commits(dut, spike, label="prefix lockstep")
    if not ok:
        return False, message
    events = parse_trap_events(ROOT / "dut_trap.trace")
    ok, message = check_expected_events(events, EXPECTED_EVENTS)
    if not ok:
        return False, message
    return True, f"prefix lockstep matched {len(dut)} commits; trap events matched mepc/mcause/mstatus/mret"


def main() -> int:
    run_spike(
        work_dir=ROOT,
        elf=ROOT / "firmware_spike.elf",
        log=ROOT / "spike.log",
        pc_base=SPIKE_BASE,
        instructions=80,
    )
    ok, message = compare()
    (ROOT / "trap_irq_lockstep_report.md").write_text(
        "# Phase 3.1 Trap/IRQ Lockstep Report\n\n"
        f"Status: {'pass' if ok else 'fail'}\n\n"
        f"Result: {message}\n\n"
        "Compared prefix fields: `pc`, `instr`, `rd`, `wdata`.\n\n"
        "Checked trap fields: `mepc`, `mcause`, handler `mstatus`, `mret` resume.\n\n"
        "Scope: directed compressed-instruction IRQ slice; not random DV or coverage closure.\n",
        encoding="utf-8",
    )
    print(("PASS: " if ok else "FAIL: ") + message)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
