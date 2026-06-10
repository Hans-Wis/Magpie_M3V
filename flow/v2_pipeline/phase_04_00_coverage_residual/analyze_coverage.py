#!/usr/bin/env python3
"""Generate Phase 4.0 coverage residual analysis from Verilator lcov output."""

from __future__ import annotations

import csv
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
PHASE_DIR = Path(__file__).resolve().parent
COV_DIR = ROOT / "flow/v2_pipeline/phase_03_06_multi_seed_coverage/coverage"
INFO = COV_DIR / "coverage.info"
MERGED_COVERAGE = COV_DIR / "merged_coverage.dat"
ANNOTATED = COV_DIR / "annotated"
RTL_DIR = ROOT / "IP/cpu_m1/rtl"


def _module_name(source_path: str) -> str:
    return Path(source_path).name


def _is_dut_module(module: str) -> bool:
    return not module.startswith("tb_")


def _annotated_source(module: str) -> dict[int, str]:
    rtl_path = RTL_DIR / module
    if rtl_path.exists():
        return {
            idx: line.rstrip()
            for idx, line in enumerate(
                rtl_path.read_text(encoding="utf-8", errors="replace").splitlines(),
                start=1,
            )
        }
    path = ANNOTATED / module
    if not path.exists():
        return {}
    rows: dict[int, str] = {}
    for idx, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), start=1):
        if len(line) > 13 and (line.startswith("%") or line.startswith(" ") or line.startswith("~")):
            rows[idx] = line[13:].rstrip()
        else:
            rows[idx] = line.rstrip()
    return rows


def _classify(module: str, line_text: str) -> tuple[str, str, str, str]:
    text = line_text.strip()
    if module == "csr.v" or "irq" in text or "trap" in text or "mret" in text or "CSR_" in text:
        return (
            "csr_irq_trap",
            "reachable",
            "Not exercised by the non-privileged random seed ladder; needs directed CSR/trap/IRQ tests.",
            "Add CSR read/write, mret, trap-entry/exit, and IRQ timing directed tests; rerun coverage.",
        )
    if module in {"bp.v", "ras.v"} or "bp_" in text or "ras_" in text:
        return (
            "bp_ras_redirect",
            "reachable",
            "Not exercised by the current random grammar because it has no looped predictor training or return stack sequence.",
            "Add directed BP/RAS train/mispredict/return tests and include them in coverage merge.",
        )
    if module == "cdec.v" or "cinstr" in text or "illegal" in text:
        return (
            "rv32c_corner",
            "reachable",
            "Current random grammar uses only a small legal compressed subset; many legal/illegal compressed encodings are unhit.",
            "Add directed RV32C decode tests for each quadrant/funct3 and illegal/reserved encodings.",
        )
    if module in {"div.v", "mul.v"} or "div_by_zero" in text or "overflow" in text or "remainder" in text:
        return (
            "m_extension_corner",
            "reachable",
            "Phase 3.6 random seeds do not hit all signed, unsigned, overflow, and remainder control paths.",
            "Merge Phase 3.7 M-unit hazard test into coverage and add missing M corner vectors.",
        )
    if module in {"hazard.v", "forward.v"} or "stall" in text or "fwd" in text:
        return (
            "hazard_forwarding",
            "reachable",
            "Random seeds do not guarantee every forwarding/stall priority combination.",
            "Add directed load-use, EX/MEM vs WB forwarding priority, and wrong-path suppression tests.",
        )
    if "resetn" in text or text.startswith("input") or text.startswith("output"):
        return (
            "reset_or_interface",
            "environment_limited",
            "Coverage point is tied to reset/interface observation in this harness.",
            "Review whether later wrapper/full-system harness should hit it; waive only with owner approval.",
        )
    if module == "tb_random_lockstep.v":
        return (
            "testbench",
            "not_signoff_rtl",
            "Testbench coverage is not CPU RTL closure evidence.",
            "Exclude testbench from sign-off coverage accounting or track separately.",
        )
    return (
        "directed_gap",
        "reachable",
        "Line was not hit by current seed ladder.",
        "Add directed or random stimulus that targets this line; rerun coverage.",
    )


def parse_info() -> tuple[dict[str, dict[int, int]], dict[str, str]]:
    coverage: dict[str, dict[int, int]] = defaultdict(dict)
    source_paths: dict[str, str] = {}
    current_module = ""
    current_source = ""
    for line in INFO.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("SF:"):
            current_source = line.split(":", 1)[1]
            current_module = _module_name(current_source)
            source_paths[current_module] = current_source
        elif line.startswith("DA:") and current_module:
            payload = line.split(":", 1)[1]
            lineno_s, count_s = payload.split(",", 1)
            coverage[current_module][int(lineno_s)] = int(count_s)
    return coverage, source_paths


def _coverage_dat_fields(payload: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    for item in payload.split("\x01"):
        if not item or "\x02" not in item:
            continue
        key, value = item.split("\x02", 1)
        fields[key] = value
    return fields


def parse_toggle_coverage() -> tuple[dict[str, dict[str, int]], dict[str, int]]:
    module_counts: dict[str, dict[str, int]] = defaultdict(lambda: {"hit": 0, "total": 0})
    total_counts = {"hit": 0, "total": 0}
    if not MERGED_COVERAGE.exists():
        return module_counts, total_counts

    for line in MERGED_COVERAGE.read_text(encoding="latin-1", errors="replace").splitlines():
        if not line.startswith("C '") or "' " not in line:
            continue
        payload, count_s = line[3:].rsplit("' ", 1)
        fields = _coverage_dat_fields(payload)
        if fields.get("t") != "toggle":
            continue
        module = _module_name(fields.get("f", ""))
        try:
            count = int(count_s.strip())
        except ValueError:
            continue
        hit = 1 if count > 0 else 0
        module_counts[module]["total"] += 1
        module_counts[module]["hit"] += hit
        total_counts["total"] += 1
        total_counts["hit"] += hit
    return module_counts, total_counts


def main() -> int:
    coverage, source_paths = parse_info()
    toggle_by_module, toggle_total = parse_toggle_coverage()
    summary_rows: list[dict[str, str]] = []
    uncovered_rows: list[dict[str, str]] = []

    for module in sorted(coverage):
        annotated = _annotated_source(module)
        total = len(coverage[module])
        hit = sum(1 for count in coverage[module].values() if count > 0)
        uncovered = total - hit
        percent = (hit * 100.0 / total) if total else 0.0
        is_dut = _is_dut_module(module)
        toggle = toggle_by_module.get(module, {"hit": 0, "total": 0})
        toggle_percent = (toggle["hit"] * 100.0 / toggle["total"]) if toggle["total"] else 0.0
        summary_rows.append(
            {
                "module": module,
                "source": source_paths.get(module, ""),
                "signoff_scope": "dut" if is_dut else "testbench",
                "hit_lines": str(hit),
                "total_lines": str(total),
                "uncovered_lines": str(uncovered),
                "line_percent": f"{percent:.2f}",
                "toggle_hit": str(toggle["hit"]),
                "toggle_total": str(toggle["total"]),
                "toggle_percent": f"{toggle_percent:.2f}",
            }
        )
        for lineno, count in sorted(coverage[module].items()):
            if count > 0:
                continue
            line_text = annotated.get(lineno, "")
            category, reachability, reason, closure_plan = _classify(module, line_text)
            uncovered_rows.append(
                {
                    "module": module,
                    "line": str(lineno),
                    "category": category,
                    "reachability": reachability,
                    "hit_count": str(count),
                    "reason": reason,
                    "closure_plan": closure_plan,
                    "owner": "DV",
                    "date": "2026-06-07",
                    "waiver": "none",
                    "source_text": line_text.strip(),
                }
            )

    with (PHASE_DIR / "module_coverage_summary.csv").open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(
            fh,
            fieldnames=[
                "module",
                "source",
                "signoff_scope",
                "hit_lines",
                "total_lines",
                "uncovered_lines",
                "line_percent",
                "toggle_hit",
                "toggle_total",
                "toggle_percent",
            ],
        )
        writer.writeheader()
        writer.writerows(summary_rows)

    with (PHASE_DIR / "uncovered_lines.csv").open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(
            fh,
            fieldnames=[
                "module",
                "line",
                "category",
                "reachability",
                "hit_count",
                "reason",
                "closure_plan",
                "owner",
                "date",
                "waiver",
                "source_text",
            ],
        )
        writer.writeheader()
        writer.writerows(uncovered_rows)

    total_lines = sum(int(row["total_lines"]) for row in summary_rows)
    hit_lines = sum(int(row["hit_lines"]) for row in summary_rows)
    uncovered = total_lines - hit_lines
    percent = hit_lines * 100.0 / total_lines
    dut_rows = [row for row in summary_rows if row["signoff_scope"] == "dut"]
    dut_total_lines = sum(int(row["total_lines"]) for row in dut_rows)
    dut_hit_lines = sum(int(row["hit_lines"]) for row in dut_rows)
    dut_uncovered = dut_total_lines - dut_hit_lines
    dut_percent = dut_hit_lines * 100.0 / dut_total_lines
    dut_toggle_total = sum(int(row["toggle_total"]) for row in dut_rows)
    dut_toggle_hit = sum(int(row["toggle_hit"]) for row in dut_rows)
    dut_toggle_percent = dut_toggle_hit * 100.0 / dut_toggle_total if dut_toggle_total else 0.0
    total_toggle_percent = (
        toggle_total["hit"] * 100.0 / toggle_total["total"] if toggle_total["total"] else 0.0
    )
    category_counts: dict[str, int] = defaultdict(int)
    reachability_counts: dict[str, int] = defaultdict(int)
    for row in uncovered_rows:
        category_counts[row["category"]] += 1
        reachability_counts[row["reachability"]] += 1

    report_lines = [
        "# Phase 4.0 Coverage Residual Analysis",
        "",
        "Status: residual-analysis-pass",
        "",
        f"Input coverage: `{INFO.relative_to(ROOT)}`",
        "",
        f"DUT line coverage: {dut_hit_lines} / {dut_total_lines} ({dut_percent:.2f}%)",
        "",
        f"Total line coverage including testbench: {hit_lines} / {total_lines} ({percent:.2f}%)",
        "",
        f"DUT uncovered lines: {dut_uncovered}",
        "",
        f"Total uncovered lines including testbench: {uncovered}",
        "",
        f"DUT toggle coverage: {dut_toggle_hit} / {dut_toggle_total} ({dut_toggle_percent:.2f}%)",
        "",
        f"Total toggle coverage including testbench: {toggle_total['hit']} / {toggle_total['total']} ({total_toggle_percent:.2f}%)",
        "",
        "Coverage closure status: not closed. Line coverage target remains 100%.",
        "",
        "Toggle coverage target is >=85%; current value is measured but not closed.",
        "",
        "Functional coverage target is >=95%; functional cover bins are not implemented yet.",
        "",
        "The sign-off headline excludes testbench coverage. Testbench coverage is tracked only as supporting data.",
        "",
        "## Coverage Target Status",
        "",
        "| Metric | Target | Current | Status |",
        "| --- | ---: | ---: | --- |",
        f"| DUT line | 100% | {dut_percent:.2f}% | not-closed |",
        f"| DUT toggle | >=85% | {dut_toggle_percent:.2f}% | measured-not-closed |",
        "| Functional | >=95% | not implemented | coverplan-required |",
        "",
        "## Category Counts",
        "",
        "| Category | Count |",
        "| --- | ---: |",
    ]
    for category, count in sorted(category_counts.items()):
        report_lines.append(f"| {category} | {count} |")
    report_lines.extend(
        [
            "",
            "## Reachability Counts",
            "",
            "| Reachability | Count |",
            "| --- | ---: |",
        ]
    )
    for reachability, count in sorted(reachability_counts.items()):
        report_lines.append(f"| {reachability} | {count} |")
    report_lines.extend(
        [
            "",
            "## Module Summary",
            "",
            "| Module | Scope | Line Hit / Total | Line % | Toggle Hit / Total | Toggle % | Uncovered |",
            "| --- | --- | ---: | ---: | ---: | ---: | ---: |",
        ]
    )
    for row in sorted(summary_rows, key=lambda r: (-int(r["uncovered_lines"]), r["module"])):
        report_lines.append(
            f"| {row['module']} | {row['signoff_scope']} | {row['hit_lines']} / {row['total_lines']} | "
            f"{row['line_percent']}% | {row['toggle_hit']} / {row['toggle_total']} | "
            f"{row['toggle_percent']}% | {row['uncovered_lines']} |"
        )
    report_lines.extend(
        [
            "",
            "## Residual List",
            "",
            "Every uncovered line is listed in `uncovered_lines.csv` with reason, "
            "reachability, closure plan, owner/date, and waiver status.",
            "",
            "## Next Closure Actions",
            "",
            "- Merge Phase 3.7 directed M-unit hazard coverage into the coverage database.",
            "- Add directed CSR/trap/IRQ coverage tests using Phase 2.0/3.1 programs.",
            "- Add BP/RAS/redirect directed coverage tests.",
            "- Add RV32C quadrant/funct3 legal and illegal decode vectors.",
            "- Add functional coverage bins for ISA class, trap cause, redirect type, forwarding source, and M-unit corner bins.",
        ]
    )
    (PHASE_DIR / "coverage_residual_report.md").write_text("\n".join(report_lines) + "\n", encoding="utf-8")
    print(
        "PASS: coverage residual analysis listed "
        f"{dut_uncovered} DUT uncovered lines; DUT line coverage {dut_percent:.2f}%; "
        f"DUT toggle coverage {dut_toggle_percent:.2f}%"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
