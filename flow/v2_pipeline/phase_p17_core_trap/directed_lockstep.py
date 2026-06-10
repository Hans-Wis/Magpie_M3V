#!/usr/bin/env python3
"""Compare P17 core trap directed DUT commit trace against Spike."""

from __future__ import annotations

import csv
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "lib"))
from spike_commit import compare_commits, parse_dut_commits, parse_spike_commits, run_spike, write_commit_csv


ROOT = Path(__file__).resolve().parent
SPIKE_BASE = 0x8000_0000
NM = Path("/home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin/riscv64-unknown-elf-nm")

CAUSES = {
    "p17_ecall": 0x0000_000B,
    "p17_ebreak32": 0x0000_0003,
    "p17_illegal32": 0x0000_0002,
    "p17_c_ebreak_odd": 0x0000_0003,
    "p17_lw_misalign": 0x0000_0004,
    "p17_sw_misalign": 0x0000_0006,
}


def symbols(elf: Path) -> dict[str, int]:
    out = subprocess.check_output([str(NM), "-n", str(elf)], cwd=ROOT, text=True)
    rows: dict[str, int] = {}
    for line in out.splitlines():
        parts = line.split()
        if len(parts) >= 3:
            rows[parts[2]] = int(parts[0], 16)
    return rows


def trap_events(path: Path) -> list[dict[str, int | str]]:
    with path.open(newline="", encoding="utf-8") as fh:
        return [
            {
                "idx": int(row["idx"]),
                "kind": row["kind"],
                "pc": int(row["pc"], 16),
                "cause": int(row["cause"], 16),
                "mtval": int(row["mtval"], 16),
                "mepc": int(row["mepc"], 16),
            }
            for row in csv.DictReader(fh)
        ]


def check_traps(events: list[dict[str, int | str]], syms: dict[str, int]) -> tuple[bool, str]:
    expected_order = [
        "p17_ecall",
        "p17_ebreak32",
        "p17_illegal32",
        "p17_c_ebreak_odd",
        "p17_lw_misalign",
        "p17_sw_misalign",
    ]
    if len(events) < len(expected_order) + 2:
        return False, f"expected at least {len(expected_order) + 2} trap events, got {len(events)}"

    by_pc = {int(event["pc"]): event for event in events}
    for name in expected_order:
        pc = syms[name]
        if pc not in by_pc:
            return False, f"missing trap event for {name} at pc=0x{pc:08x}"
        event = by_pc[pc]
        cause = int(event["cause"])
        mtval = int(event["mtval"])
        mepc = int(event["mepc"])
        if cause != CAUSES[name]:
            return False, f"{name} cause mismatch got=0x{cause:08x} expected=0x{CAUSES[name]:08x}"
        if mepc != pc:
            return False, f"{name} mepc mismatch got=0x{mepc:08x} expected=0x{pc:08x}"
        if name == "p17_c_ebreak_odd" and (pc & 0x2) == 0:
            return False, f"mandatory c.ebreak is not at odd halfword pc=0x{pc:08x}"
        if name == "p17_lw_misalign" and mtval != syms["data_area"] + 1:
            return False, f"lw mtval mismatch got=0x{mtval:08x}"
        if name == "p17_sw_misalign" and mtval != syms["data_area"] + 2:
            return False, f"sw mtval mismatch got=0x{mtval:08x}"

    irq_events = [event for event in events if int(event["cause"]) == 0x8000_000B]
    if len(irq_events) < 2:
        return False, f"expected two external IRQ events, got {len(irq_events)}"
    return True, "trap events matched expected mepc/mcause/mtval values"


def main() -> int:
    syms_dut = symbols(ROOT / "firmware.elf")
    syms_spike = symbols(ROOT / "firmware_spike.elf")
    run_spike(
        work_dir=ROOT,
        elf=ROOT / "firmware_spike.elf",
        log=ROOT / "spike.log",
        pc_base=SPIKE_BASE,
        instructions=320,
    )
    dut = parse_dut_commits(ROOT / "dut_commit.trace")
    spike = parse_spike_commits(
        ROOT / "spike.log",
        limit=len(dut),
        pc_base=SPIKE_BASE,
        stop_pc=syms_spike["p17_ecall"] - SPIKE_BASE,
    )
    write_commit_csv(ROOT / "spike_commit.trace", spike)
    ok, message = compare_commits(dut[: len(spike)], spike, label="P17 core trap prefix lockstep")
    ev_ok, ev_message = check_traps(trap_events(ROOT / "dut_trap_events.csv"), syms_dut)
    ok = ok and ev_ok
    report = [
        "# P17 Core CSR/Trap/IRQ/MRET Directed Lockstep Report",
        "",
        f"Status: {'pass-not-gate-green' if ok else 'fail'}",
        "",
        f"Lockstep: {message}",
        "",
        f"Trap events: {ev_message}",
        "",
        "Compared prefix commit fields: `pc`, `instr`, `rd`, `wdata` up to the first synchronous trap.",
        "",
        "Spike limitation: local Spike 1.1.1-dev logs the M-mode exception and stops before the `mtvec` handler, matching prior J14/J18 evidence. Through-trap commit lockstep is therefore not claimed green.",
        "",
        "External IRQ handler commits are filtered from the DUT trace because the IRQ source is a DUT port, not a Spike-visible architectural stimulus; IRQ correctness is checked through core trap-event evidence.",
    ]
    (ROOT / "directed_lockstep_report.md").write_text("\n".join(report) + "\n", encoding="utf-8")
    print(("PASS: " if ok else "FAIL: ") + message + "; " + ev_message)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
