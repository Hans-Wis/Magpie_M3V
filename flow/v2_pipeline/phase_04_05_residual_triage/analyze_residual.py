#!/usr/bin/env python3
"""Analyze residual coverage after Phase 4.4."""

from __future__ import annotations

import csv
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
PHASE_DIR = Path(__file__).resolve().parent
COV_DIR = ROOT / "flow/v2_pipeline/phase_04_04_illegal_munit_coverage/coverage"
INFO = COV_DIR / "coverage.info"
MERGED_DAT = COV_DIR / "merged_with_phase_04_04.dat"
RTL_DIR = ROOT / "design/cpu_m1/rtl"


def _module_name(path: str) -> str:
    return Path(path).name


def _is_dut(module: str) -> bool:
    return not module.startswith("tb_")


def _resolve_source(source: str) -> Path:
    raw = Path(source)
    if raw.is_absolute():
        return raw
    return (ROOT / "flow/v2_pipeline/phase_04_04_illegal_munit_coverage" / raw).resolve()


def _source_text(module: str, lineno: int) -> str:
    path = RTL_DIR / module
    if not path.exists():
        return ""
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    if 0 < lineno <= len(lines):
        return lines[lineno - 1].strip()
    return ""


def _classify(module: str, lineno: int, text: str) -> tuple[str, str, str, str, str]:
    if module == "alu.v":
        return (
            "alu_default",
            "reachable-by-illegal-or-unknown-alu-op-only",
            "The ALU default arm is only reached if decode sends an unknown ALU op; in-scope ISA decode should not generate it.",
            "Review as defensive default; waive if decode coverage proves all in-scope ALU ops are enumerated.",
            "waiver-candidate",
        )
    if module == "core.v" and lineno in {713, 893, 895, 896}:
        return (
            "ras_mispredict_recovery",
            "reachable",
            "Current RAS tests cover correct return prediction, not wrong RAS target recovery.",
            "Add directed RAS pollution/overflow/mismatched-return test to force mem_ras_mispredict recovery.",
            "none",
        )
    if module == "csr.v" and lineno in {101, 103}:
        return (
            "csr_high_counters",
            "environment_limited",
            "cycleh/instreth require upper 32-bit counter activity or directed CSR reads; current short simulations only prove low counters.",
            "Add directed CSR read of cycleh/instreth and decide whether long-run counter overflow is required or waived.",
            "none",
        )
    if module == "csr.v" and lineno in {156, 157}:
        return (
            "csr_explicit_write_mepc_mcause",
            "reachable",
            "Directed CSR tests write mscratch/mstatus/mie/mtvec but not explicit software writes to mepc/mcause.",
            "Add directed CSR write/readback for mepc and mcause.",
            "none",
        )
    if module == "csr.v" and lineno == 159:
        return (
            "csr_write_default",
            "reachable-by-unsupported-csr-write-only",
            "Default CSR write arm is a defensive ignore path for unsupported CSR addresses.",
            "Add unsupported CSR write test or waive as defensive default after CSR map review.",
            "waiver-candidate",
        )
    if module == "div.v" and lineno == 129:
        return (
            "div_fsm_default",
            "unreachable-by-legal-reset-fsm",
            "Default FSM state recovery is defensive; legal reset and transitions should keep state in declared set.",
            "Add SVA/FSM assertion or waive as defensive default.",
            "waiver-candidate",
        )
    if module == "idu.v" and lineno == 102:
        return (
            "fence_decode",
            "reachable",
            "Zifencei is in ISA scope but directed tests have not executed FENCE/FENCE.I decode paths enough to mark this line.",
            "Add directed FENCE/FENCE.I decode smoke and Spike comparison if architecturally visible.",
            "none",
        )
    if module == "idu.v" and lineno in {173, 185}:
        return (
            "decode_default_alu_op",
            "reachable-by-unsupported-funct-only",
            "Default ALU op arms are defensive decode fallbacks for unsupported or illegal funct combinations.",
            "Add illegal/unsupported instruction decode test or waive after decode matrix review.",
            "waiver-candidate",
        )
    if module == "idu.v" and lineno in {191, 192}:
        return (
            "branch_unsigned_and_default",
            "reachable",
            "Directed branch tests do not yet cover unsigned branch ALU selection and default branch compare fallback.",
            "Add directed BLTU/BGEU plus unsupported branch funct trap/default decode test.",
            "none",
        )
    if module == "ras.v" and lineno in {64, 65, 67}:
        return (
            "ras_push_edge",
            "reachable",
            "Current RAS directed test covers nested call/return but not empty-stack push edge and overflow/underflow combinations enough for all line points.",
            "Add directed RAS empty/overflow/underflow sequence with observed push/pop pointer behavior.",
            "none",
        )
    return (
        "unclassified",
        "reachable",
        "Residual line remains unclassified after Phase 4.5 script rules.",
        "Inspect RTL and add a directed test or waiver.",
        "none",
    )


def _coverage_dat_fields(payload: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    for item in payload.split("\x01"):
        if not item or "\x02" not in item:
            continue
        key, value = item.split("\x02", 1)
        fields[key] = value
    return fields


def _toggle_counts() -> dict[str, dict[str, int]]:
    points: dict[str, dict[tuple[str, str, str], bool]] = defaultdict(dict)
    for line in MERGED_DAT.read_text(encoding="latin-1", errors="replace").splitlines():
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
        key = (module, fields.get("l", ""), fields.get("o", ""))
        points[module][key] = points[module].get(key, False) or count > 0
    return {
        module: {
            "hit": sum(1 for hit in module_points.values() if hit),
            "total": len(module_points),
        }
        for module, module_points in points.items()
    }


def main() -> int:
    coverage: dict[str, dict[int, int]] = defaultdict(dict)
    sources: dict[str, str] = {}
    current_module = ""
    for line in INFO.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("SF:"):
            source = line.split(":", 1)[1]
            current_module = _module_name(source)
            sources[current_module] = str(_resolve_source(source))
        elif line.startswith("DA:") and current_module:
            lineno_s, count_s = line.split(":", 1)[1].split(",", 1)
            coverage[current_module][int(lineno_s)] = int(count_s)

    toggle = _toggle_counts()
    summary_rows: list[dict[str, str]] = []
    residual_rows: list[dict[str, str]] = []
    for module in sorted(coverage):
        total = len(coverage[module])
        hit = sum(1 for count in coverage[module].values() if count > 0)
        uncovered = total - hit
        scope = "dut" if _is_dut(module) else "testbench"
        t = toggle.get(module, {"hit": 0, "total": 0})
        summary_rows.append(
            {
                "module": module,
                "source": sources.get(module, ""),
                "signoff_scope": scope,
                "hit_lines": str(hit),
                "total_lines": str(total),
                "uncovered_lines": str(uncovered),
                "line_percent": f"{(hit * 100.0 / total) if total else 0.0:.2f}",
                "toggle_hit": str(t["hit"]),
                "toggle_total": str(t["total"]),
                "toggle_percent": f"{(t['hit'] * 100.0 / t['total']) if t['total'] else 0.0:.2f}",
            }
        )
        if not _is_dut(module):
            continue
        for lineno, count in sorted(coverage[module].items()):
            if count > 0:
                continue
            text = _source_text(module, lineno)
            category, reachability, reason, plan, waiver = _classify(module, lineno, text)
            residual_rows.append(
                {
                    "module": module,
                    "line": str(lineno),
                    "category": category,
                    "reachability": reachability,
                    "hit_count": str(count),
                    "reason": reason,
                    "closure_plan": plan,
                    "owner": "DV",
                    "date": "2026-06-07",
                    "waiver": waiver,
                    "source_text": text,
                }
            )

    with (PHASE_DIR / "module_coverage_summary.csv").open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=list(summary_rows[0].keys()))
        writer.writeheader()
        writer.writerows(summary_rows)
    with (PHASE_DIR / "residual_lines.csv").open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=list(residual_rows[0].keys()))
        writer.writeheader()
        writer.writerows(residual_rows)

    dut_hit = sum(int(r["hit_lines"]) for r in summary_rows if r["signoff_scope"] == "dut")
    dut_total = sum(int(r["total_lines"]) for r in summary_rows if r["signoff_scope"] == "dut")
    dut_t_hit = sum(int(r["toggle_hit"]) for r in summary_rows if r["signoff_scope"] == "dut")
    dut_t_total = sum(int(r["toggle_total"]) for r in summary_rows if r["signoff_scope"] == "dut")
    cat_counts = Counter(row["category"] for row in residual_rows)
    waiver_counts = Counter(row["waiver"] for row in residual_rows)

    report = [
        "# Phase 4.5 Residual Coverage Triage",
        "",
        "Status: residual-triage-pass",
        "",
        f"Source coverage: `{COV_DIR.relative_to(ROOT)}`",
        "",
        "## Coverage Status",
        "",
        f"- DUT line coverage: {dut_hit} / {dut_total} = {dut_hit * 100.0 / dut_total:.2f}%",
        f"- DUT uncovered lines: {dut_total - dut_hit}",
        f"- DUT toggle coverage: {dut_t_hit} / {dut_t_total} = {dut_t_hit * 100.0 / dut_t_total:.2f}%",
        "- Functional coverage: not implemented; coverplan-required.",
        "- Coverage closure status: not closed.",
        "",
        "## Residual Category Counts",
        "",
        "| Category | Count |",
        "| --- | ---: |",
    ]
    for category, count in sorted(cat_counts.items()):
        report.append(f"| {category} | {count} |")
    report.extend(
        [
            "",
            "## Waiver Status",
            "",
            "| Waiver | Count |",
            "| --- | ---: |",
        ]
    )
    for waiver, count in sorted(waiver_counts.items()):
        report.append(f"| {waiver} | {count} |")
    report.extend(
        [
            "",
            "No waiver is approved by this phase. `waiver-candidate` means the line is a plausible defensive/default path, but owner approval is still required.",
            "",
            "## Next Closure Actions",
            "",
            "- Add directed RAS mispredict and RAS pointer edge coverage.",
            "- Add directed CSR high-counter and explicit mepc/mcause/default-write coverage or waivers.",
            "- Add directed FENCE/FENCE.I and unsigned branch decode coverage.",
            "- Add SVA/FSM assertion or waiver for defensive default states.",
            "- Build functional coverage bins and close or waive them.",
        ]
    )
    (PHASE_DIR / "residual_triage_report.md").write_text("\n".join(report) + "\n", encoding="utf-8")

    print(
        "PASS: residual triage generated; "
        f"DUT line {dut_hit}/{dut_total} ({dut_hit * 100.0 / dut_total:.2f}%); "
        f"DUT toggle {dut_t_hit}/{dut_t_total} ({dut_t_hit * 100.0 / dut_t_total:.2f}%); "
        f"residual_lines={len(residual_rows)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
