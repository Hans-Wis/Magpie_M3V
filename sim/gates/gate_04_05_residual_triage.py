"""gate_04_05_residual_triage - post-Phase-4.4 coverage residual triage gate."""

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE_DIR = ROOT / "flow/v2_pipeline/phase_04_05_residual_triage"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def test_phase_04_05_artifacts_exist():
    required = [
        "README.md",
        "analyze_residual.py",
        "module_coverage_summary.csv",
        "residual_lines.csv",
        "residual_triage_report.md",
    ]
    for name in required:
        path = PHASE_DIR / name
        assert path.exists(), f"missing Phase 4.5 artifact: {name}"
        assert path.stat().st_size > 0, f"empty Phase 4.5 artifact: {name}"


def test_phase_04_05_report_records_not_closed_coverage_status():
    report = _read(PHASE_DIR / "residual_triage_report.md")
    for required in [
        "Status: residual-triage-pass",
        "DUT line coverage: 1035 / 1054 = 98.20%",
        "DUT uncovered lines: 19",
        "DUT toggle coverage: 8235 / 12246 = 67.25%",
        "Functional coverage: not implemented; coverplan-required.",
        "Coverage closure status: not closed.",
        "No waiver is approved by this phase.",
    ]:
        assert required in report


def test_phase_04_05_every_residual_line_has_reason_plan_and_waiver_status():
    rows = _rows(PHASE_DIR / "residual_lines.csv")
    assert len(rows) == 19
    for row in rows:
        assert row["module"]
        assert row["line"].isdigit()
        assert row["category"]
        assert row["reachability"]
        assert row["hit_count"] == "0"
        assert row["reason"]
        assert row["closure_plan"]
        assert row["owner"] == "DV"
        assert row["date"] == "2026-06-07"
        assert row["waiver"] in {"none", "waiver-candidate"}
        assert row["source_text"]


def test_phase_04_05_residual_categories_are_expected():
    rows = _rows(PHASE_DIR / "residual_lines.csv")
    counts: dict[str, int] = {}
    waiver_counts: dict[str, int] = {}
    for row in rows:
        counts[row["category"]] = counts.get(row["category"], 0) + 1
        waiver_counts[row["waiver"]] = waiver_counts.get(row["waiver"], 0) + 1

    assert counts == {
        "alu_default": 1,
        "branch_unsigned_and_default": 2,
        "csr_explicit_write_mepc_mcause": 2,
        "csr_high_counters": 2,
        "csr_write_default": 1,
        "decode_default_alu_op": 2,
        "div_fsm_default": 1,
        "fence_decode": 1,
        "ras_mispredict_recovery": 4,
        "ras_push_edge": 3,
    }
    assert waiver_counts == {"none": 14, "waiver-candidate": 5}


def test_phase_04_05_module_summary_matches_phase_04_04_headline():
    rows = {row["module"]: row for row in _rows(PHASE_DIR / "module_coverage_summary.csv")}
    assert rows["cdec.v"]["hit_lines"] == "106"
    assert rows["cdec.v"]["total_lines"] == "106"
    assert rows["core.v"]["uncovered_lines"] == "4"
    assert rows["csr.v"]["uncovered_lines"] == "5"
    assert rows["div.v"]["uncovered_lines"] == "1"
    assert rows["idu.v"]["uncovered_lines"] == "5"
    assert rows["ras.v"]["uncovered_lines"] == "3"

    dut_hit = sum(int(row["hit_lines"]) for row in rows.values() if row["signoff_scope"] == "dut")
    dut_total = sum(int(row["total_lines"]) for row in rows.values() if row["signoff_scope"] == "dut")
    dut_toggle_hit = sum(int(row["toggle_hit"]) for row in rows.values() if row["signoff_scope"] == "dut")
    dut_toggle_total = sum(int(row["toggle_total"]) for row in rows.values() if row["signoff_scope"] == "dut")
    assert (dut_hit, dut_total) == (1035, 1054)
    assert (dut_toggle_hit, dut_toggle_total) == (8235, 12246)


def test_phase_04_05_next_actions_are_specific():
    report = _read(PHASE_DIR / "residual_triage_report.md")
    for required in [
        "Add directed RAS mispredict and RAS pointer edge coverage.",
        "Add directed CSR high-counter and explicit mepc/mcause/default-write coverage or waivers.",
        "Add directed FENCE/FENCE.I and unsigned branch decode coverage.",
        "Add SVA/FSM assertion or waiver for defensive default states.",
        "Build functional coverage bins and close or waive them.",
    ]:
        assert required in report
