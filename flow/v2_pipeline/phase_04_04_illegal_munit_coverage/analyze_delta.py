#!/usr/bin/env python3
"""Merge Phase 4.4 illegal-compressed/M-unit coverage with Phase 4.3."""

from __future__ import annotations

import csv
import os
import subprocess
from collections import defaultdict
from pathlib import Path


PHASE_DIR = Path(__file__).resolve().parent
ROOT = PHASE_DIR.parents[2]
BASE_COV = ROOT / "flow/v2_pipeline/phase_04_03_rv32c_cross_coverage/coverage"
BASE_INFO = BASE_COV / "coverage.info"
BASE_DAT = BASE_COV / "merged_with_phase_04_03.dat"
THIS_DAT = PHASE_DIR / "coverage.dat"
OUT_COV = PHASE_DIR / "coverage"
VERILATOR_COVERAGE = Path("/home/edauser/miniforge3/envs/magpie_claude/bin/verilator_coverage")


def _module_name(source_path: str) -> str:
    return Path(source_path).name


def _is_dut(module: str) -> bool:
    return not module.startswith("tb_")


def _run(cmd: list[str | Path]) -> None:
    subprocess.run([str(item) for item in cmd], cwd=PHASE_DIR, env=os.environ.copy(), check=True)


def _line_by_module(info: Path) -> dict[str, dict[str, int]]:
    rows: dict[str, dict[str, int]] = defaultdict(lambda: {"hit": 0, "total": 0})
    current_module = ""
    for line in info.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("SF:"):
            current_module = _module_name(line.split(":", 1)[1])
        elif line.startswith("DA:") and current_module:
            rows[current_module]["total"] += 1
            _, payload = line.split(":", 1)
            _, count_s = payload.split(",", 1)
            if int(count_s) > 0:
                rows[current_module]["hit"] += 1
    return rows


def _coverage_dat_fields(payload: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    for item in payload.split("\x01"):
        if not item or "\x02" not in item:
            continue
        key, value = item.split("\x02", 1)
        fields[key] = value
    return fields


def _toggle_points(dat: Path) -> dict[str, dict[tuple[str, str, str], bool]]:
    rows: dict[str, dict[tuple[str, str, str], bool]] = defaultdict(dict)
    for line in dat.read_text(encoding="latin-1", errors="replace").splitlines():
        if not line.startswith("C '") or "' " not in line:
            continue
        payload, count_s = line[3:].rsplit("' ", 1)
        fields = _coverage_dat_fields(payload)
        if fields.get("t") != "toggle":
            continue
        module = _module_name(fields.get("f", ""))
        key = (module, fields.get("l", ""), fields.get("o", ""))
        try:
            count = int(count_s.strip())
        except ValueError:
            continue
        rows[module][key] = rows[module].get(key, False) or count > 0
    return rows


def _toggle_counts(points: dict[str, dict[tuple[str, str, str], bool]]) -> dict[str, dict[str, int]]:
    return {
        module: {"hit": sum(1 for hit in module_points.values() if hit), "total": len(module_points)}
        for module, module_points in points.items()
    }


def _merge_toggle_points(*sources: dict[str, dict[tuple[str, str, str], bool]]) -> dict[str, dict[tuple[str, str, str], bool]]:
    merged: dict[str, dict[tuple[str, str, str], bool]] = defaultdict(dict)
    for source in sources:
        for module, points in source.items():
            for key, hit in points.items():
                merged[module][key] = merged[module].get(key, False) or hit
    return merged


def _sum_dut(rows: dict[str, dict[str, int]]) -> tuple[int, int, float]:
    hit = sum(vals["hit"] for mod, vals in rows.items() if _is_dut(mod))
    total = sum(vals["total"] for mod, vals in rows.items() if _is_dut(mod))
    return hit, total, (hit * 100.0 / total) if total else 0.0


def _pct(hit: int, total: int) -> float:
    return (hit * 100.0 / total) if total else 0.0


def main() -> int:
    if not BASE_INFO.exists() or not BASE_DAT.exists():
        raise SystemExit("missing Phase 4.3 base coverage artifacts")
    if not THIS_DAT.exists():
        raise SystemExit("missing Phase 4.4 coverage.dat")

    OUT_COV.mkdir(exist_ok=True)
    merged_dat = OUT_COV / "merged_with_phase_04_04.dat"
    merged_info = OUT_COV / "coverage.info"
    _run([VERILATOR_COVERAGE, "-write", merged_dat, BASE_DAT, THIS_DAT])
    _run([VERILATOR_COVERAGE, "-write-info", merged_info, merged_dat])

    base_line = _line_by_module(BASE_INFO)
    merged_line = _line_by_module(merged_info)
    base_toggle_points = _toggle_points(BASE_DAT)
    this_toggle_points = _toggle_points(THIS_DAT)
    merged_toggle_points = _merge_toggle_points(base_toggle_points, this_toggle_points)
    base_toggle = _toggle_counts(base_toggle_points)
    merged_toggle = _toggle_counts(merged_toggle_points)

    modules = sorted(set(base_line) | set(merged_line) | set(base_toggle) | set(merged_toggle))
    delta_rows: list[dict[str, str]] = []
    for module in modules:
        bl = base_line.get(module, {"hit": 0, "total": 0})
        ml = merged_line.get(module, {"hit": 0, "total": 0})
        bt = base_toggle.get(module, {"hit": 0, "total": 0})
        mt = merged_toggle.get(module, {"hit": 0, "total": 0})
        delta_rows.append(
            {
                "module": module,
                "scope": "dut" if _is_dut(module) else "testbench",
                "base_line_hit": str(bl["hit"]),
                "merged_line_hit": str(ml["hit"]),
                "line_total": str(ml["total"] or bl["total"]),
                "line_hit_delta": str(ml["hit"] - bl["hit"]),
                "base_line_percent": f"{_pct(bl['hit'], bl['total']):.2f}",
                "merged_line_percent": f"{_pct(ml['hit'], ml['total']):.2f}",
                "base_toggle_hit": str(bt["hit"]),
                "merged_toggle_hit": str(mt["hit"]),
                "toggle_total": str(mt["total"] or bt["total"]),
                "toggle_hit_delta": str(mt["hit"] - bt["hit"]),
                "base_toggle_percent": f"{_pct(bt['hit'], bt['total']):.2f}",
                "merged_toggle_percent": f"{_pct(mt['hit'], mt['total']):.2f}",
            }
        )

    with (PHASE_DIR / "module_delta.csv").open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=list(delta_rows[0].keys()))
        writer.writeheader()
        writer.writerows(delta_rows)

    base_l_hit, base_l_total, base_l_pct = _sum_dut(base_line)
    merged_l_hit, merged_l_total, merged_l_pct = _sum_dut(merged_line)
    base_t_hit, base_t_total, base_t_pct = _sum_dut(base_toggle)
    merged_t_hit, merged_t_total, merged_t_pct = _sum_dut(merged_toggle)
    line_delta = merged_l_hit - base_l_hit
    toggle_delta = merged_t_hit - base_t_hit
    by_module = {row["module"]: row for row in delta_rows}

    report = [
        "# Phase 4.4 Illegal Compressed Trap + M-Unit Coverage Delta",
        "",
        "Status: coverage-delta-pass",
        "",
        f"Base coverage: `{BASE_COV.relative_to(ROOT)}`",
        "",
        f"Directed coverage: `{THIS_DAT.relative_to(ROOT)}`",
        "",
        f"Merged coverage: `{merged_info.relative_to(ROOT)}`",
        "",
        "## DUT Coverage Delta",
        "",
        "| Metric | Base | Merged | Delta | Target | Status |",
        "| --- | ---: | ---: | ---: | ---: | --- |",
        f"| Line | {base_l_hit}/{base_l_total} ({base_l_pct:.2f}%) | "
        f"{merged_l_hit}/{merged_l_total} ({merged_l_pct:.2f}%) | +{line_delta} lines | 100% | not-closed |",
        f"| Toggle | {base_t_hit}/{base_t_total} ({base_t_pct:.2f}%) | "
        f"{merged_t_hit}/{merged_t_total} ({merged_t_pct:.2f}%) | +{toggle_delta} toggles | >=85% | not-closed |",
        "| Functional | not implemented | not implemented | 0 bins | >=95% | coverplan-required |",
        "",
        "## Illegal/M-Unit Module Delta",
        "",
        "| Module | Line Base | Line Merged | Line Delta | Toggle Base | Toggle Merged | Toggle Delta |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for module in ["cdec.v", "core.v", "div.v", "mul.v"]:
        row = by_module[module]
        report.append(
            f"| {module} | {row['base_line_hit']}/{row['line_total']} ({row['base_line_percent']}%) | "
            f"{row['merged_line_hit']}/{row['line_total']} ({row['merged_line_percent']}%) | "
            f"+{row['line_hit_delta']} | {row['base_toggle_hit']}/{row['toggle_total']} "
            f"({row['base_toggle_percent']}%) | {row['merged_toggle_hit']}/{row['toggle_total']} "
            f"({row['merged_toggle_percent']}%) | +{row['toggle_hit_delta']} |"
        )
    report.extend(
        [
            "",
            "## Directed Behavior Checked",
            "",
            "- M-unit signed/unsigned multiply variants and divide/remainder corner behavior.",
            "- Divide-by-zero and signed overflow results are checked in firmware before the marker store.",
            "- Legal `C.JALR` decode path is executed before the M-unit completion marker.",
            "- Illegal compressed reserved/RV32-invalid/default encodings propagate to the terminal trap path.",
            "",
            "## Remaining Closure",
            "",
            "Coverage is still not closed. Continue with residual line/toggle triage, functional cover bins, "
            "and final waiver review for structurally unreachable or out-of-scope behavior.",
        ]
    )
    (PHASE_DIR / "illegal_munit_coverage_report.md").write_text("\n".join(report) + "\n", encoding="utf-8")

    cdec_delta = int(by_module["cdec.v"]["line_hit_delta"]) + int(by_module["cdec.v"]["toggle_hit_delta"])
    div_delta = int(by_module["div.v"]["line_hit_delta"]) + int(by_module["div.v"]["toggle_hit_delta"])
    if line_delta <= 0 and toggle_delta <= 0:
        print("FAIL: directed illegal/M-unit test produced no DUT coverage delta")
        return 1
    if cdec_delta <= 0 and div_delta <= 0:
        print("FAIL: directed illegal/M-unit test produced no cdec/div module delta")
        return 1
    print(
        "PASS: illegal compressed/M-unit coverage merged; "
        f"DUT line {merged_l_hit}/{merged_l_total} ({merged_l_pct:.2f}%, +{line_delta}); "
        f"DUT toggle {merged_t_hit}/{merged_t_total} ({merged_t_pct:.2f}%, +{toggle_delta})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
