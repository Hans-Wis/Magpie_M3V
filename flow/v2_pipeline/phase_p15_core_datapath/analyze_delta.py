#!/usr/bin/env python3
"""Report P15 core datapath coverage delta against the existing multi-seed base."""

from __future__ import annotations

import csv
import os
import re
import subprocess
from collections import defaultdict
from pathlib import Path


PHASE_DIR = Path(__file__).resolve().parent
ROOT = PHASE_DIR.parents[2]
BASE_COV = ROOT / "flow/v2_pipeline/phase_03_06_multi_seed_coverage/coverage"
BASE_DAT = BASE_COV / "merged_coverage.dat"
THIS_DAT = PHASE_DIR / "coverage.dat"
OUT_COV = PHASE_DIR / "coverage"
VERILATOR_COVERAGE = Path("/home/edauser/miniforge3/envs/magpie_claude/bin/verilator_coverage")
P15_ROSTER = ROOT / ".run/p15_18/core_uncovered_toggles.txt"
LOCKSTEP_LOG = PHASE_DIR / "directed_lockstep.log"


P15_PREFIXES = {
    "cdec_expanded",
    "d_mem_rdata",
    "id_mem_align_error",
    "id_mem_misaligned",
    "ex_mem_is_misaligned_r",
    "wb_take_data_trap",
    "mem_stall",
    "ex_mem_pc_plus_4_r",
    "ex_wb_pc_plus_4_r",
    "ex_mem_pc_r",
    "ex_wb_pc_r",
}

STRUCTURAL = {
    "ex_mem_pc_plus_4_r[0]": "PC/link bit 0 is instruction-alignment constrained; `if_ex_pc_plus_4 = if_ex_pc + 2/4` at design/cpu_m1/rtl/core.v:487 and latched at line 783.",
    "ex_wb_pc_plus_4_r[0]": "PC/link bit 0 is instruction-alignment constrained; `if_ex_pc_plus_4 = if_ex_pc + 2/4` at design/cpu_m1/rtl/core.v:487 and propagated at lines 908/982.",
    "ex_mem_pc_r[0]": "Instruction PCs are aligned; IF/EX PC is latched from the fetch PC at design/cpu_m1/rtl/core.v:291 and propagated at line 780.",
    "ex_wb_pc_r[0]": "Instruction PCs are aligned; EX/MEM PC propagates to EX/WB at design/cpu_m1/rtl/core.v:905.",
}

CROSS_SLICE_PREFIXES = {
    "cdec_expanded": "P16/P18 residual context: compressed fetch/decode placement; P15 only consumes the expanded instruction.",
}

FIXTURES = {
    "cdec_expanded": "Add a focused high-register `C.LWSP`/`C.ADD` sequence at both 16-bit halfword positions after P16 fetch alignment closure.",
    "d_mem_rdata": "Load alternating words with the named data bits set and clear through LB/LBU/LH/LHU/LW.",
    "id_mem_align_error": "Add privileged lockstep or non-commit trap harness for odd `LH` and misaligned `LW`.",
    "id_mem_misaligned": "Add privileged lockstep or non-commit trap harness for odd `LH` and misaligned `LW`.",
    "ex_mem_is_misaligned_r": "Add privileged lockstep or non-commit trap harness and observe propagation into EX/MEM.",
    "wb_take_data_trap": "Add privileged lockstep trap handler and compare Spike trap entry through `mtvec`.",
    "mem_stall": "Assert the harness `mem_stall` input during an active load/store wait state.",
    "ex_mem_pc_plus_4_r": "Place committed code at a higher `.org` and execute JAL/JALR link-producing instructions.",
    "ex_wb_pc_plus_4_r": "Place committed code at a higher `.org` and let link-producing instructions reach WB.",
    "ex_mem_pc_r": "Place committed code at a higher `.org` so EX/MEM PC bits toggle.",
    "ex_wb_pc_r": "Place committed code at a higher `.org` so EX/WB PC bits toggle.",
}


def _run(cmd: list[str | Path]) -> None:
    subprocess.run([str(item) for item in cmd], cwd=PHASE_DIR, env=os.environ.copy(), check=True)


def _fields(payload: str) -> dict[str, str]:
    rows: dict[str, str] = {}
    for item in payload.split("\x01"):
        if item and "\x02" in item:
            key, value = item.split("\x02", 1)
            rows[key] = value
    return rows


def _toggle_points(dat: Path) -> dict[str, int]:
    points: dict[str, int] = {}
    for line in dat.read_text(encoding="latin-1", errors="replace").splitlines():
        if not line.startswith("C '") or "' " not in line:
            continue
        payload, count_s = line[3:].rsplit("' ", 1)
        fields = _fields(payload)
        if fields.get("t") != "toggle" or Path(fields.get("f", "")).name != "core.v":
            continue
        try:
            count = int(count_s.strip())
        except ValueError:
            continue
        points[fields.get("o", "")] = max(points.get(fields.get("o", ""), 0), count)
    return points


def _signal_of(point: str) -> str:
    return point.split(":", 1)[0]


def _prefix(signal: str) -> str:
    return signal.split("[", 1)[0]


def _core_counts(points: dict[str, int]) -> tuple[int, int, float]:
    total = len(points)
    hit = sum(1 for count in points.values() if count > 0)
    return hit, total, (hit * 100.0 / total) if total else 0.0


def _merge_on_base_universe(base: dict[str, int], directed: dict[str, int]) -> dict[str, int]:
    return {point: max(count, directed.get(point, 0)) for point, count in base.items()}


def _merge_union(base: dict[str, int], directed: dict[str, int]) -> dict[str, int]:
    merged = dict(base)
    for point, count in directed.items():
        merged[point] = max(merged.get(point, 0), count)
    return merged


def _roster_signals() -> list[str]:
    if not P15_ROSTER.exists():
        return []
    rows = []
    for line in P15_ROSTER.read_text(encoding="utf-8", errors="replace").splitlines():
        signal = line.strip()
        if not signal:
            continue
        if _prefix(signal) in P15_PREFIXES:
            rows.append(signal)
    return rows


def _closed(signal: str, points: dict[str, int]) -> bool:
    matches = [count for point, count in points.items() if _signal_of(point) == signal]
    return bool(matches) and all(count > 0 for count in matches)


def _classify_remaining(signal: str) -> tuple[str, str]:
    if signal in STRUCTURAL:
        return "STRUCTURAL", STRUCTURAL[signal]
    prefix = _prefix(signal)
    if prefix in CROSS_SLICE_PREFIXES:
        return "cross-slice", CROSS_SLICE_PREFIXES[prefix]
    return "REACHABLE", FIXTURES.get(prefix, "Add a directed architectural fixture for this datapath signal.")


def _format_signal_groups(signals: list[str]) -> list[str]:
    if not signals:
        return ["- none"]

    scalars: list[str] = []
    bits_by_prefix: dict[str, list[int]] = defaultdict(list)
    for signal in sorted(signals):
        match = re.fullmatch(r"(.+)\[(\d+)\]", signal)
        if match:
            bits_by_prefix[match.group(1)].append(int(match.group(2)))
        else:
            scalars.append(signal)

    rows = [f"- `{signal}`" for signal in scalars]
    for prefix, bits in sorted(bits_by_prefix.items()):
        ranges: list[str] = []
        start = prev = None
        for bit in sorted(set(bits)):
            if start is None:
                start = prev = bit
            elif bit == prev + 1:
                prev = bit
            else:
                ranges.append(f"{start}" if start == prev else f"{prev}:{start}")
                start = prev = bit
        if start is not None:
            ranges.append(f"{start}" if start == prev else f"{prev}:{start}")
        rows.append(f"- `{prefix}[{', '.join(ranges)}]`")
    return rows


def _lockstep_result() -> str:
    if not LOCKSTEP_LOG.exists():
        return "missing directed_lockstep.log"
    text = LOCKSTEP_LOG.read_text(encoding="utf-8", errors="replace")
    match = re.search(r"PASS: (.*matched \d+ commits)", text)
    if match:
        return f"PASS: {match.group(1)}"
    return text.strip().splitlines()[-1] if text.strip() else "empty directed_lockstep.log"


def main() -> int:
    if not BASE_DAT.exists():
        raise SystemExit("missing baseline merged coverage.dat")
    if not THIS_DAT.exists():
        raise SystemExit("missing P15 coverage.dat")

    OUT_COV.mkdir(exist_ok=True)
    merged_dat = OUT_COV / "merged_with_phase_p15.dat"
    merged_info = OUT_COV / "coverage.info"
    _run([VERILATOR_COVERAGE, "-write", merged_dat, BASE_DAT, THIS_DAT])
    _run([VERILATOR_COVERAGE, "-write-info", merged_info, merged_dat])

    base_points = _toggle_points(BASE_DAT)
    p15_points = _toggle_points(THIS_DAT)
    merged_points = _merge_on_base_universe(base_points, p15_points)
    merged_union_points = _merge_union(base_points, p15_points)
    base_hit, base_total, base_pct = _core_counts(base_points)
    p15_hit, p15_total, p15_pct = _core_counts(p15_points)
    merged_hit, merged_total, merged_pct = _core_counts(merged_points)

    roster = _roster_signals()
    now_covered = [sig for sig in roster if not _closed(sig, base_points) and _closed(sig, merged_union_points)]
    remaining = [sig for sig in roster if not _closed(sig, merged_union_points)]

    with (PHASE_DIR / "module_delta.csv").open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(
            fh,
            fieldnames=[
                "module",
                "base_toggle_hit",
                "p15_toggle_hit",
                "merged_toggle_hit",
                "toggle_total",
                "base_toggle_percent",
                "p15_toggle_percent",
                "merged_toggle_percent",
                "toggle_hit_delta",
            ],
        )
        writer.writeheader()
        writer.writerow(
            {
                "module": "core.v",
                "base_toggle_hit": base_hit,
                "p15_toggle_hit": p15_hit,
                "merged_toggle_hit": merged_hit,
                "toggle_total": merged_total or base_total,
                "base_toggle_percent": f"{base_pct:.2f}",
                "p15_toggle_percent": f"{p15_pct:.2f}",
                "merged_toggle_percent": f"{merged_pct:.2f}",
                "toggle_hit_delta": merged_hit - base_hit,
            }
        )

    by_class: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for signal in remaining:
        cls, note = _classify_remaining(signal)
        by_class[cls].append((signal, note))

    report = [
        "# P15 Core Datapath Integration Report",
        "",
        f"Spike lockstep: {_lockstep_result()}",
        "",
        "## core.v Toggle Delta",
        "",
        "| Source | Hit/Total | Toggle % |",
        "| --- | ---: | ---: |",
        f"| BEFORE baseline (`phase_03_06_multi_seed_coverage`) | {base_hit}/{base_total} | {base_pct:.2f}% |",
        f"| P15 directed alone | {p15_hit}/{p15_total} | {p15_pct:.2f}% |",
        f"| AFTER baseline + P15 | {merged_hit}/{merged_total or base_total} | {merged_pct:.2f}% |",
        f"| DELTA closed | +{merged_hit - base_hit} toggles | +{merged_pct - base_pct:.2f} pp |",
        "",
        "After percentage is computed on the baseline `core.v` toggle-point universe. "
        "The raw merged coverage artifact is still written to `coverage/merged_with_phase_p15.dat`.",
        "",
        "## Datapath-Owned Roster Signals Now Covered",
        "",
        *_format_signal_groups(now_covered),
        "",
        "## Datapath-Owned Roster Signals Still Uncovered",
        "",
    ]
    for cls in ["REACHABLE", "STRUCTURAL", "cross-slice"]:
        entries = by_class.get(cls, [])
        report.extend([f"### {cls}", ""])
        if not entries:
            report.append("- none")
        else:
            grouped_notes: dict[str, list[str]] = defaultdict(list)
            for signal, note in entries:
                grouped_notes[note].append(signal)
            for note, signals in grouped_notes.items():
                for row in _format_signal_groups(signals):
                    report.append(f"{row}: {note}")
        report.append("")
    report.extend(
        [
            "## Fixture Scope",
            "",
            "- Back-to-back `addi` plus `lw` -> dependent `add` load-use stall.",
            "- EX/MEM and WB ALU forwarding consumers.",
            "- `mul`/`div` M-unit busy stalls while younger ALU work is held.",
            "- Taken branch redirect near a recent load-use pair.",
            "- `WB_SEL_LSU`, `WB_SEL_MD`, ALU, PC4/PCIMM paths, and load sign/zero extension.",
            "- Testbench-driven `mem_stall` wait states on active data-port accesses.",
            "",
            "No IF, CSR/trap, BP, or RAS coverage is claimed here.",
        ]
    )
    (PHASE_DIR / "p15_core_datapath_report.md").write_text("\n".join(report) + "\n", encoding="utf-8")

    print(
        "PASS: P15 datapath report generated; "
        f"core.v toggle {base_hit}/{base_total} ({base_pct:.2f}%) -> "
        f"{merged_hit}/{merged_total or base_total} ({merged_pct:.2f}%), "
        f"delta +{merged_hit - base_hit}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
