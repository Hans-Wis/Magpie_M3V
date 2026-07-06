#!/usr/bin/env python3
"""Report P16 core IF/RV32C cross-boundary coverage delta."""

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
ROSTER = ROOT / ".run/p15_18/core_uncovered_toggles.txt"
LOCKSTEP_LOG = PHASE_DIR / "directed_lockstep.log"

P16_PREFIXES = {
    "dbg_pc",
    "i_mem_addr",
    "if_ex_pc",
    "if_pc",
    "next_pc_w",
    "redirect_target",
}

P16_DEFERRED_PC_PREFIXES = {
    "ex_mem_pc_r",
    "ex_wb_pc_r",
}

STRUCTURAL = {
    "dbg_pc[0]": "PC bit 0 is 16-bit instruction-alignment constrained; `dbg_pc = if_ex_pc` at design/cpu_m1/rtl/core.v:1079.",
    "i_mem_addr[0]": "All fetch address choices are based on aligned `if_pc` plus 2/4/6 or `next_pc_w`; see design/cpu_m1/rtl/core.v:221.",
    "if_ex_pc[0]": "IF/EX PC is latched from aligned `if_pc`; see design/cpu_m1/rtl/core.v:291.",
    "if_pc[0]": "`ifu` PC is RV32IMC 16-bit aligned and advances by +2/+4; see design/cpu_m1/rtl/ifu.v:45-52.",
    "next_pc_w[0]": "`ifu.next_pc` selects aligned redirect/prediction targets or `pc_reg + pc_inc`; see design/cpu_m1/rtl/ifu.v:45-52.",
    "redirect_target[0]": "JALR redirect recovery masks bit 0 with `& ~32'd1`; see design/cpu_m1/rtl/core.v:1045.",
    "ex_mem_pc_r[0]": "EX/MEM PC is propagated from aligned IF/EX PC; see design/cpu_m1/rtl/core.v:780.",
    "ex_wb_pc_r[0]": "EX/WB PC is propagated from aligned EX/MEM PC; see design/cpu_m1/rtl/core.v:905.",
}

CROSS_SLICE = {
    "bp_predict_target": "P18_BP_RAS",
    "bp_upd_pc": "P18_BP_RAS",
    "ex_bp_upd_pc": "P18_BP_RAS",
    "ex_mem_bp_upd_pc_r": "P18_BP_RAS",
    "if_ex_pred_target": "P18_BP_RAS",
    "ras_push_val": "P18_BP_RAS",
    "ras_top": "P18_BP_RAS",
    "if_ex_pred_ras_target": "P18_BP_RAS",
    "ex_mem_pred_ras_target_r": "P18_BP_RAS",
    "csr_rdata": "P17_CSR_TRAP",
    "id_csr_rdata": "P17_CSR_TRAP",
    "ex_mem_csr_rdata_r": "P17_CSR_TRAP",
    "ex_wb_csr_rdata_r": "P17_CSR_TRAP",
    "mepc_o": "P17_CSR_TRAP",
    "mtvec_o": "P17_CSR_TRAP",
    "wb_sync_exception_pc": "P17_CSR_TRAP",
    "wb_trap_pc_for_mepc": "P17_CSR_TRAP",
}

FIXTURE_HINTS = {
    "dbg_pc": "Run committed code at varied high offsets so debug PC high bits toggle.",
    "i_mem_addr": "Fetch from varied/high offsets, including high-halfword cross-boundary addresses.",
    "if_ex_pc": "Commit instructions from varied/high offsets and PC[1]=0/1 sites.",
    "if_pc": "Execute high/odd-halfword fetch sites through the IFU PC register.",
    "next_pc_w": "Exercise +2/+4 sequential PC, redirect, and high-address target selection.",
    "redirect_target": "Take branches/JAL/JALR to varied high addresses; bit 0 remains structural for JALR mask.",
    "ex_mem_pc_r": "Let high-address IF PCs advance into EX/MEM; this is P15-deferred PC-range closure owned by P16.",
    "ex_wb_pc_r": "Let high-address EX/MEM PCs advance into EX/WB; this is P15-deferred PC-range closure owned by P16.",
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
    rows: list[str] = []
    for line in ROSTER.read_text(encoding="utf-8", errors="replace").splitlines():
        signal = line.strip()
        if not signal:
            continue
        prefix = _prefix(signal)
        if prefix in P16_PREFIXES or prefix in P16_DEFERRED_PC_PREFIXES:
            rows.append(signal)
    return rows


def _closed(signal: str, points: dict[str, int]) -> bool:
    matches = [count for point, count in points.items() if _signal_of(point) == signal]
    return bool(matches) and all(count > 0 for count in matches)


def _classify_remaining(signal: str) -> tuple[str, str]:
    if signal in STRUCTURAL:
        return "STRUCTURAL", STRUCTURAL[signal]
    prefix = _prefix(signal)
    owner = CROSS_SLICE.get(prefix)
    if owner:
        return "cross-slice", owner
    return "REACHABLE", FIXTURE_HINTS.get(prefix, "Add a directed Spike-lockstep fixture for this P16 IF signal.")


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
    text = LOCKSTEP_LOG.read_text(encoding="utf-8", errors="replace")
    match = re.search(r"PASS: (.*matched \d+ commits)", text)
    if match:
        return f"PASS: {match.group(1)}"
    return text.strip().splitlines()[-1] if text.strip() else "empty directed_lockstep.log"


def main() -> int:
    if not BASE_DAT.exists():
        raise SystemExit("missing baseline merged coverage.dat")
    if not THIS_DAT.exists():
        raise SystemExit("missing P16 coverage.dat")

    OUT_COV.mkdir(exist_ok=True)
    merged_dat = OUT_COV / "merged_with_phase_p16.dat"
    merged_info = OUT_COV / "coverage.info"
    _run([VERILATOR_COVERAGE, "-write", merged_dat, BASE_DAT, THIS_DAT])
    _run([VERILATOR_COVERAGE, "-write-info", merged_info, merged_dat])

    base_points = _toggle_points(BASE_DAT)
    p16_points = _toggle_points(THIS_DAT)
    merged_points = _merge_on_base_universe(base_points, p16_points)
    merged_union_points = _merge_union(base_points, p16_points)
    base_hit, base_total, base_pct = _core_counts(base_points)
    p16_hit, p16_total, p16_pct = _core_counts(p16_points)
    merged_hit, merged_total, merged_pct = _core_counts(merged_points)

    roster = _roster_signals()
    covered = [sig for sig in roster if _closed(sig, merged_union_points)]
    newly_covered = [sig for sig in roster if not _closed(sig, base_points) and _closed(sig, merged_union_points)]
    remaining = [sig for sig in roster if not _closed(sig, merged_union_points)]

    by_class: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for signal in remaining:
        cls, note = _classify_remaining(signal)
        by_class[cls].append((signal, note))

    with (PHASE_DIR / "module_delta.csv").open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(
            fh,
            fieldnames=[
                "module",
                "base_toggle_hit",
                "p16_toggle_hit",
                "merged_toggle_hit",
                "toggle_total",
                "base_toggle_percent",
                "p16_toggle_percent",
                "merged_toggle_percent",
                "toggle_hit_delta",
                "p16_roster_total",
                "p16_roster_covered",
                "p16_roster_newly_covered",
            ],
        )
        writer.writeheader()
        writer.writerow(
            {
                "module": "core.v",
                "base_toggle_hit": base_hit,
                "p16_toggle_hit": p16_hit,
                "merged_toggle_hit": merged_hit,
                "toggle_total": merged_total or base_total,
                "base_toggle_percent": f"{base_pct:.2f}",
                "p16_toggle_percent": f"{p16_pct:.2f}",
                "merged_toggle_percent": f"{merged_pct:.2f}",
                "toggle_hit_delta": merged_hit - base_hit,
                "p16_roster_total": len(roster),
                "p16_roster_covered": len(covered),
                "p16_roster_newly_covered": len(newly_covered),
            }
        )

    report = [
        "# P16 Core IF / RV32C Cross-Boundary Report",
        "",
        "Status: P16 slice analyzed; overall gate is not marked green.",
        "",
        f"Spike lockstep: {_lockstep_result()}",
        "",
        "## BUG-XBOUND-0001",
        "",
        "The directed grid includes odd-aligned 32-bit ADDI, compressed tail + 32-bit head, consecutive cross-boundary 32-bit assembly, C.J/C.JAL to high-halfword targets, consecutive C.LW + 32-bit head, and redirect-after-cross-boundary. Spike lockstep is the authority.",
        "",
        "## core.v IF Delta",
        "",
        "| Source | Hit/Total | Toggle % |",
        "| --- | ---: | ---: |",
        f"| BEFORE baseline (`phase_03_06_multi_seed_coverage`) | {base_hit}/{base_total} | {base_pct:.2f}% |",
        f"| P16 directed alone | {p16_hit}/{p16_total} | {p16_pct:.2f}% |",
        f"| AFTER baseline + P16 | {merged_hit}/{merged_total or base_total} | {merged_pct:.2f}% |",
        f"| DELTA closed | +{merged_hit - base_hit} toggles | +{merged_pct - base_pct:.2f} pp |",
        "",
        "## Owned Roster",
        "",
        f"- Covered after merge: {len(covered)}/{len(roster)}",
        f"- Newly covered by P16: {len(newly_covered)}",
        f"- Remaining reachable: {len(by_class.get('REACHABLE', []))}",
        f"- Remaining structural: {len(by_class.get('STRUCTURAL', []))}",
        f"- Remaining cross-slice: {len(by_class.get('cross-slice', []))}",
        "",
        "### Newly Covered",
        "",
        *_format_signal_groups(newly_covered),
        "",
        "### Remaining Structural",
        "",
    ]
    for signal, note in by_class.get("STRUCTURAL", []):
        report.append(f"- `{signal}`: {note}")
    if not by_class.get("STRUCTURAL"):
        report.append("- none")
    report.extend(["", "### Remaining Reachable", ""])
    for signal, note in by_class.get("REACHABLE", []):
        report.append(f"- `{signal}`: {note}")
    if not by_class.get("REACHABLE"):
        report.append("- none")
    report.extend(["", "### Cross-Slice", ""])
    for signal, owner in by_class.get("cross-slice", []):
        report.append(f"- `{signal}`: owner `{owner}`")
    if not by_class.get("cross-slice"):
        report.append("- none")

    (PHASE_DIR / "token_record.txt").write_text(
        "Token budget/usage was not exposed by the local goal API for this turn.\n",
        encoding="utf-8",
    )
    report.extend(
        [
            "",
            "## Tokens",
            "",
            "Token budget/usage was not exposed by the local goal API for this turn; see `token_record.txt`.",
        ]
    )
    (PHASE_DIR / "p16_core_if_report.md").write_text("\n".join(report) + "\n", encoding="utf-8")

    if not newly_covered:
        print("FAIL: P16 directed test produced no new owned core.v IF toggle closure")
        return 1
    print(
        "PASS: P16 IF analyzed; "
        f"{_lockstep_result()}; core.v merged toggle {merged_hit}/{merged_total or base_total} "
        f"({merged_pct:.2f}%, +{merged_hit - base_hit}); "
        f"owned covered {len(covered)}/{len(roster)}; not marking gate green"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
