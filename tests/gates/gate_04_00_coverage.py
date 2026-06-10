"""gate_04_00_coverage - coverage residual analysis gate.

This gate does not claim coverage closure. It checks that the Phase 3.6
measurement was converted into a complete residual list with reasons and
closure plans for every uncovered line.
"""

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE_DIR = ROOT / "flow/v2_pipeline/phase_04_00_coverage_residual"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def test_phase_04_00_artifacts_exist():
    required = [
        "README.md",
        "analyze_coverage.py",
        "module_coverage_summary.csv",
        "uncovered_lines.csv",
        "coverage_residual_report.md",
    ]
    for name in required:
        path = PHASE_DIR / name
        assert path.exists(), f"missing Phase 4.0 artifact: {name}"
        assert path.stat().st_size > 0, f"empty Phase 4.0 artifact: {name}"


def test_phase_04_00_summary_matches_phase_03_06_measurement():
    report = _read(PHASE_DIR / "coverage_residual_report.md")
    summary = {row["module"]: row for row in _rows(PHASE_DIR / "module_coverage_summary.csv")}

    assert "Status: residual-analysis-pass" in report
    assert "DUT line coverage: 818 / 1054 (77.61%)" in report
    assert "Total line coverage including testbench: 894 / 1130 (79.12%)" in report
    assert "DUT uncovered lines: 236" in report
    assert "DUT toggle coverage: 7500 / 12246 (61.24%)" in report
    assert "Functional coverage target is >=95%; functional cover bins are not implemented yet." in report
    assert "Coverage closure status: not closed" in report
    assert "Line coverage target remains 100%" in report
    assert summary["tb_random_lockstep.v"]["signoff_scope"] == "testbench"
    assert summary["tb_random_lockstep.v"]["line_percent"] == "100.00"
    assert summary["core.v"]["uncovered_lines"] == "73"
    assert summary["csr.v"]["line_percent"] == "47.25"
    assert summary["csr.v"]["toggle_percent"] == "16.15"
    assert summary["forward.v"]["line_percent"] == "100.00"
    assert summary["mul.v"]["line_percent"] == "100.00"


def test_phase_04_00_every_uncovered_line_has_required_triage_fields():
    rows = _rows(PHASE_DIR / "uncovered_lines.csv")
    assert len(rows) == 236
    for row in rows:
        assert row["module"]
        assert row["line"].isdigit()
        assert row["category"]
        assert row["reachability"] in {"reachable", "environment_limited", "not_signoff_rtl"}
        assert row["hit_count"] == "0"
        assert row["reason"]
        assert row["closure_plan"]
        assert row["owner"] == "DV"
        assert row["date"] == "2026-06-07"
        assert row["waiver"] == "none"
        assert row["source_text"] != ""


def test_phase_04_00_category_counts_are_actionable():
    rows = _rows(PHASE_DIR / "uncovered_lines.csv")
    counts: dict[str, int] = {}
    for row in rows:
        counts[row["category"]] = counts.get(row["category"], 0) + 1

    assert counts == {
        "bp_ras_redirect": 59,
        "csr_irq_trap": 58,
        "directed_gap": 57,
        "hazard_forwarding": 3,
        "m_extension_corner": 9,
        "reset_or_interface": 6,
        "rv32c_corner": 44,
    }


def test_phase_04_00_report_names_next_closure_actions():
    report = _read(PHASE_DIR / "coverage_residual_report.md")
    for required in [
        "DUT line | 100% | 77.61% | not-closed",
        "DUT toggle | >=85% | 61.24% | measured-not-closed",
        "Functional | >=95% | not implemented | coverplan-required",
        "Merge Phase 3.7 directed M-unit hazard coverage",
        "Add directed CSR/trap/IRQ coverage tests",
        "Add BP/RAS/redirect directed coverage tests",
        "Add RV32C quadrant/funct3 legal and illegal decode vectors",
        "Add functional coverage bins",
    ]:
        assert required in report
