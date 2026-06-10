#!/usr/bin/env python3
"""Report P18 core BP/RAS recovery coverage delta without claiming gate closure."""

from __future__ import annotations

import csv
import os
import re
import subprocess
from collections import defaultdict
from pathlib import Path


PHASE_DIR = Path(__file__).resolve().parent
ROOT = PHASE_DIR.parents[2]
BASE_DAT = ROOT / "flow/v2_pipeline/phase_p15_core_datapath/coverage/merged_with_phase_p15.dat"
THIS_DAT = PHASE_DIR / "coverage.dat"
OUT_COV = PHASE_DIR / "coverage"
VERILATOR_COVERAGE = Path("/home/edauser/miniforge3/envs/magpie_claude/bin/verilator_coverage")
ROSTER = ROOT / ".run/p15_18/core_uncovered_toggles.txt"
LOCKSTEP_LOG = PHASE_DIR / "directed_lockstep.log"


P18_PREFIXES = {
    "bp_predict_target",
    "bp_upd_pc",
    "ex_bp_upd_pc",
    "ex_mem_bp_upd_pc_r",
    "ex_mem_pred_ras_target_r",
    "ex_target_mispredict",
    "if_ex_pred_ras_target",
    "if_ex_pred_target",
    "mem_ras_actual_target",
    "ras_push_val",
    "ras_top",
    "redirect_target",
}

STRUCTURAL = {
    "mem_ras_actual_target[0]": "STRUCTURAL: core.v line 846 masks JALR/RAS actual target with `& ~32'd1`.",
    "redirect_target[0]": "STRUCTURAL: core.v lines 1045-1048 select only aligned recovery targets; the JALR arm masks with `& ~32'd1`.",
}

CROSS_SLICE_PREFIXES = {
    "if_ex_pred_ras_target": "P14_RAS_LEAF/P18 boundary: low alignment bits originate from RAS-pushed return PCs; P18 observes integration only.",
    "ras_top": "P14_RAS_LEAF/P18 boundary: stack storage and pointer internals are leaf-owned; P18 observes top-value integration only.",
    "ras_push_val": "P16_IF/P18 boundary: return-address low alignment is PC-size/fetch alignment; P18 owns push orchestration, not PC alignment closure.",
    "bp_predict_target": "P13_BP_LEAF/P18 boundary: BTB target storage bits are leaf-owned; P18 owns use in redirect/fetch priority.",
}

FIXTURES = {
    "bp_upd_pc": "REACHABLE: add higher/alternating branch PCs that toggle the remaining update-PC bits.",
    "ex_bp_upd_pc": "REACHABLE: add higher/alternating branch PCs before the EX update latch.",
    "ex_mem_bp_upd_pc_r": "REACHABLE: add higher/alternating branch PCs that reach EX/MEM update registers.",
    "ex_mem_pred_ras_target_r": "REACHABLE: add return targets with the remaining high-bit pattern and a RAS-predicted return.",
    "ex_target_mispredict": "REACHABLE: keep target-alias branches until predicted-taken wrong-target is observed.",
    "if_ex_pred_target": "REACHABLE: add target-alias trained branches whose predicted target reaches IF/EX.",
    "mem_ras_actual_target": "REACHABLE: add a poisoned-return target with the remaining high-bit pattern.",
    "redirect_target": "REACHABLE: add BP and RAS recoveries to targets with the remaining high-bit pattern.",
}

DIRECTED_SCOPE = [
    "taken/not-taken backward branch pairs",
    "4+ taken updates at one branch offset plus repeated not-taken outcomes",
    "two taken branches separated by 64 bytes to share bp.v index bits [6:1]",
    "JAL/RET call-return with RAS push/pop",
    "poisoned RA return to force RAS target mismatch recovery",
    "JAL target training and wrong-path IF clear through redirect",
]


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
        point = fields.get("o", "")
        points[point] = max(points.get(point, 0), count)
    return points


def _signal_of(point: str) -> str:
    return point.split(":", 1)[0]


def _prefix(signal: str) -> str:
    return signal.split("[", 1)[0]


def _core_counts(points: dict[str, int]) -> tuple[int, int, float]:
    total = len(points)
    hit = sum(1 for count in points.values() if count > 0)
    return hit, total, (hit * 100.0 / total) if total else 0.0


def _merge_union(base: dict[str, int], directed: dict[str, int]) -> dict[str, int]:
    merged = dict(base)
    for point, count in directed.items():
        merged[point] = max(merged.get(point, 0), count)
    return merged


def _roster_signals() -> list[str]:
    rows = []
    for line in ROSTER.read_text(encoding="utf-8", errors="replace").splitlines():
        signal = line.strip()
        if signal and _prefix(signal) in P18_PREFIXES:
            rows.append(signal)
    return rows


def _closed(signal: str, points: dict[str, int]) -> bool:
    matches = [count for point, count in points.items() if _signal_of(point) == signal]
    return bool(matches) and all(count > 0 for count in matches)


def _classify(signal: str) -> tuple[str, str]:
    if signal in STRUCTURAL:
        return "STRUCTURAL", STRUCTURAL[signal]
    prefix = _prefix(signal)
    if prefix in CROSS_SLICE_PREFIXES:
        return "cross-slice", CROSS_SLICE_PREFIXES[prefix]
    return "REACHABLE", FIXTURES.get(prefix, "REACHABLE: add a focused P18 BP/RAS recovery fixture for this signal.")


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
    text = LOCKSTEP_LOG.read_text(encoding="utf-8", errors="replace") if LOCKSTEP_LOG.exists() else ""
    match = re.search(r"PASS: (.*matched \d+ commits)", text)
    if match:
        return f"PASS: {match.group(1)}"
    return text.strip().splitlines()[-1] if text.strip() else "missing directed_lockstep.log"


def main() -> int:
    if not BASE_DAT.exists():
        raise SystemExit(f"missing merged baseline {BASE_DAT}")
    if not THIS_DAT.exists():
        raise SystemExit("missing P18 coverage.dat")

    OUT_COV.mkdir(exist_ok=True)
    merged_dat = OUT_COV / "merged_with_phase_p18.dat"
    merged_info = OUT_COV / "coverage.info"
    _run([VERILATOR_COVERAGE, "-write", merged_dat, BASE_DAT, THIS_DAT])
    _run([VERILATOR_COVERAGE, "-write-info", merged_info, merged_dat])

    base_points = _toggle_points(BASE_DAT)
    p18_points = _toggle_points(THIS_DAT)
    merged_points = _merge_union(base_points, p18_points)
    base_hit, base_total, base_pct = _core_counts(base_points)
    p18_hit, p18_total, p18_pct = _core_counts(p18_points)
    merged_hit, merged_total, merged_pct = _core_counts(merged_points)

    roster = _roster_signals()
    now_covered = [sig for sig in roster if not _closed(sig, base_points) and _closed(sig, merged_points)]
    remaining = [sig for sig in roster if not _closed(sig, merged_points)]

    with (PHASE_DIR / "module_delta.csv").open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(
            fh,
            fieldnames=[
                "module",
                "base_toggle_hit",
                "p18_toggle_hit",
                "merged_toggle_hit",
                "toggle_total",
                "base_toggle_percent",
                "p18_toggle_percent",
                "merged_toggle_percent",
                "toggle_hit_delta",
                "p18_roster_total",
                "p18_roster_now_covered",
                "p18_roster_remaining",
            ],
        )
        writer.writeheader()
        writer.writerow(
            {
                "module": "core.v",
                "base_toggle_hit": base_hit,
                "p18_toggle_hit": p18_hit,
                "merged_toggle_hit": merged_hit,
                "toggle_total": merged_total,
                "base_toggle_percent": f"{base_pct:.2f}",
                "p18_toggle_percent": f"{p18_pct:.2f}",
                "merged_toggle_percent": f"{merged_pct:.2f}",
                "toggle_hit_delta": merged_hit - base_hit,
                "p18_roster_total": len(roster),
                "p18_roster_now_covered": len(now_covered),
                "p18_roster_remaining": len(remaining),
            }
        )

    by_class: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for signal in remaining:
        cls, note = _classify(signal)
        by_class[cls].append((signal, note))

    report = [
        "# P18 Core BP/RAS Recovery Integration Report",
        "",
        "Status: report-only, not gate-green",
        "",
        f"Spike lockstep: {_lockstep_result()}",
        "",
        "## core.v Toggle Delta",
        "",
        "| Source | Hit/Total | Toggle % |",
        "| --- | ---: | ---: |",
        f"| BEFORE baseline (`phase_p15_core_datapath` merged) | {base_hit}/{base_total} | {base_pct:.2f}% |",
        f"| P18 directed alone | {p18_hit}/{p18_total} | {p18_pct:.2f}% |",
        f"| AFTER baseline + P18 | {merged_hit}/{merged_total} | {merged_pct:.2f}% |",
        f"| DELTA closed | +{merged_hit - base_hit} toggles | +{merged_pct - base_pct:.2f} pp |",
        "",
        "Only `core.v` P18 roster signals are attributed here. BP/RAS leaf table/stack internals remain P13/P14-owned.",
        "",
        "## Directed Fixtures",
        "",
        *[f"- {item}" for item in DIRECTED_SCOPE],
        "",
        "## P18-Owned Roster Signals Now Covered",
        "",
        *_format_signal_groups(now_covered),
        "",
        "## P18-Owned Roster Signals Still Uncovered",
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
            "## Anti-Green-Wash Notes",
            "",
            "- Spike lockstep mismatch is fail; no mismatch was waived by this analyzer.",
            "- Missing fixture coverage is classified `REACHABLE`, not structural.",
            "- Structural classification is used only for signals with an exact `core.v` alignment/mask citation.",
            "- Cross-slice/leaf entries name the owner and are not claimed as P18 closure.",
            "",
            "## Token Record",
            "",
            "- Codex goal token tracker was not active for this turn (`get_goal` returned no active goal/budget).",
            "- Session transcript is mirrored by `.run/p18_bpras/codex_impl.log`.",
        ]
    )
    (PHASE_DIR / "p18_core_bpras_report.md").write_text("\n".join(report) + "\n", encoding="utf-8")

    print(
        "REPORT: P18 BP/RAS report generated; "
        f"lockstep={_lockstep_result()}; "
        f"core.v toggle {base_hit}/{base_total} ({base_pct:.2f}%) -> "
        f"{merged_hit}/{merged_total} ({merged_pct:.2f}%), "
        f"P18 roster covered +{len(now_covered)}, remaining {len(remaining)}; gate not marked green"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
