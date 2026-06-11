#!/usr/bin/env python3
"""phase_03_14 — msip (M software interrupt) directed lockstep.

Closes Tier-2 blocker #4b's lockstep-able path. Compares the pre-IRQ DUT commit prefix
against Spike per-commit (Spike has no msip driven, so the prefix is identical up to the
interrupt point), then validates the DUT interrupt-handler CSRs against the RISC-V Priv
spec — mcause must be 0x8000_0003 (interrupt, code 3 = M software). Same rigor as the
through-trap slice (gate_03_12): prefix-lockstep + spec-validated handler."""

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
    "mcause": (None, 0x8000_0003),    # M software interrupt (msip), ADR-0019
    "mstatus": (None, 0x1880),        # MPP=11 (0x1800) + MPIE=1 (0x80), Priv §3.1.6
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
    return True, (f"prefix lockstep matched {len(dut)} commits; msip handler events matched "
                  f"mepc/mcause=0x80000003/mstatus/mret")


def main() -> int:
    run_spike(
        work_dir=ROOT,
        elf=ROOT / "firmware_spike.elf",
        log=ROOT / "spike.log",
        pc_base=SPIKE_BASE,
        instructions=80,
    )
    ok, message = compare()
    (ROOT / "msip_directed_report.md").write_text(
        "# Phase 3.14 msip Software-Interrupt Directed Lockstep Report\n\n"
        f"Status: {'pass' if ok else 'fail'}\n\n"
        f"Result: {message}\n\n"
        "Compared prefix fields: `pc`, `instr`, `rd`, `wdata` (per-commit vs Spike).\n\n"
        "Checked trap fields: `mepc`, `mcause` (0x80000003 = M software), handler `mstatus`, `mret`.\n\n"
        "Scope: directed msip (CLINT software-int) slice — the deterministic, lockstep-able "
        "interrupt path for blocker #4b. Truly-async meip/mtip remain directed-only.\n",
        encoding="utf-8",
    )
    print(("PASS: " if ok else "FAIL: ") + message)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
