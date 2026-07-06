#!/usr/bin/env python3
"""Report P17-owned core trap/IRQ coverage evidence without gate-green claims."""

from __future__ import annotations

import csv
import re
from pathlib import Path


PHASE_DIR = Path(__file__).resolve().parent
ROOT = PHASE_DIR.parents[2]
COVERAGE_DAT = PHASE_DIR / "coverage.dat"

OWNED_PATTERNS = [
    "id_mem_align_error",
    "id_mem_misaligned",
    "ex_mem_is_misaligned_r",
    "ex_mem_is_misaligned_store_r",
    "ex_wb_is_misaligned_r",
    "ex_wb_is_misaligned_store_r",
    "wb_take_data_trap",
    "wb_take_sync_trap",
    "wb_take_irq",
    "wb_trap_enter",
    "wb_trap_exit",
    "wb_trap_pc_for_mepc",
    "wb_trap_cause",
    "wb_trap_mtval",
    "ex_wb_is_mret_r",
    "irq_pending",
]

CROSS_SLICE = {
    "pc_redirect": "P18/P17 shared redirect priority",
    "redirect_target": "P18/P17 shared redirect target mux",
    "if_ex_is_16bit": "P16 fetch size, consumed by P17 MEPC-16",
    "mem_stall": "P15 datapath stall, consumed by P17 trap timing",
}

STRUCTURAL_NOTES = {
    "wb_trap_cause": "bits outside supported cause constants are structural at design/cpu_m1/rtl/core.v:993 (cause mux literals 0x0000000b/3/2/4/6/0x8000000b)",
}


def coverage_payload_fields(payload: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    for item in payload.split("\x01"):
        if item and "\x02" in item:
            key, value = item.split("\x02", 1)
            fields[key] = value
    return fields


def covered_core_toggles() -> dict[str, int]:
    rows: dict[str, int] = {}
    if not COVERAGE_DAT.exists():
        return rows
    for line in COVERAGE_DAT.read_text(encoding="latin-1", errors="replace").splitlines():
        if not line.startswith("C '") or "' " not in line:
            continue
        payload, count_s = line[3:].rsplit("' ", 1)
        fields = coverage_payload_fields(payload)
        if fields.get("t") != "toggle" or Path(fields.get("f", "")).name != "core.v":
            continue
        signal = fields.get("o", "")
        try:
            count = int(count_s.strip())
        except ValueError:
            count = 0
        rows[signal] = rows.get(signal, 0) + count
    return rows


def main() -> int:
    toggles = covered_core_toggles()
    owned_rows = []
    missing = []
    for pattern in OWNED_PATTERNS:
        matches = [(sig, count) for sig, count in toggles.items() if pattern in sig]
        hit = sum(1 for _, count in matches if count > 0)
        total = len(matches)
        status = "covered" if total and hit == total else "reachable"
        if pattern in STRUCTURAL_NOTES and hit > 0:
            status = "covered_structural_bits"
        if status == "reachable":
            missing.append(pattern)
        owned_rows.append({
            "signal": pattern,
            "covered_toggles": str(hit),
            "total_toggles": str(total),
            "status": status,
            "note": STRUCTURAL_NOTES.get(pattern, ""),
        })

    with (PHASE_DIR / "module_delta.csv").open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=["signal", "covered_toggles", "total_toggles", "status", "note"])
        writer.writeheader()
        writer.writerows(owned_rows)

    event_count = max(0, sum(1 for _ in (PHASE_DIR / "dut_trap_events.csv").open(encoding="utf-8")) - 1)
    report = [
        "# P17 Core Trap Coverage Delta",
        "",
        "Status: analysis-pass-not-gate-green",
        "",
        f"Directed coverage: `{COVERAGE_DAT.relative_to(ROOT)}`",
        "",
        f"Trap/IRQ/MRET events observed: {event_count}",
        "",
        "## Owned Core Signals",
        "",
        "| Signal | Covered Toggles | Total Toggles | Status |",
        "| --- | ---: | ---: | --- |",
    ]
    report.extend(f"| `{row['signal']}` | {row['covered_toggles']} | {row['total_toggles']} | {row['status']} |" for row in owned_rows)
    report.extend(
        [
            "",
            "## Classification",
            "",
            "- Covered: P17 directed fixture toggled the Verilator points listed above.",
            "- Reachable: any missing owned signal remains reachable and requires more fixture work; no fixture gap is marked structural.",
            "- Structural: `wb_trap_cause` upper/unused cause-code bits are tied by the literal cause mux at `design/cpu_m1/rtl/core.v:993`; no other structural claims.",
            "- Cross-slice: " + "; ".join(f"`{name}` owner {owner}" for name, owner in CROSS_SLICE.items()) + ".",
            "- Excluded merged leaf: standalone `csr.v` register behavior belongs to P11 and is not re-covered here.",
            "- Tokens: no active Codex goal token counter was available from `get_goal`; token budget/usage was therefore not machine-recorded.",
            "",
            "## Lockstep",
            "",
            "See `directed_lockstep_report.md`; Spike commit mismatch is treated as FAIL.",
        ]
    )
    (PHASE_DIR / "p17_core_trap_report.md").write_text("\n".join(report) + "\n", encoding="utf-8")

    print("PASS: P17 trap-delta report written; gate status intentionally not green")
    if missing:
        print("INFO: reachable owned signals still missing full toggle closure: " + ", ".join(missing))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
