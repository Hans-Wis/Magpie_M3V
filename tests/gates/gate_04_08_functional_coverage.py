"""gate_04_08_functional_coverage - bound functional covergroup artifact gate."""

import csv
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE_DIR = ROOT / "flow/v2_pipeline/phase_04_08_functional_coverage"
THRESHOLD_PERCENT = 100


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def test_phase_04_08_artifacts_exist():
    required = [
        "functional_coverplan.md",
        "cpu_m1_func_cov_bind.sv",
        "tb_random_func_cov.sv",
        "Makefile",
        "analyze_functional_coverage.py",
        "functional_events.csv",
        "functional_coverage_summary.csv",
        "uncovered_bins.csv",
        "functional_coverage_report.md",
        "provenance.log",
    ]
    for name in required:
        path = PHASE_DIR / name
        assert path.exists(), f"missing Phase 4.8 artifact: {name}"
        assert path.stat().st_size > 0, f"empty Phase 4.8 artifact: {name}"


def test_phase_04_08_covergroups_are_bind_only():
    sv = _read(PHASE_DIR / "cpu_m1_func_cov_bind.sv")
    for group in [
        "cg_opcode_instr_class",
        "cg_alu_m_funct",
        "cg_load_store",
        "cg_branch_jump_bp_ras",
        "cg_hazard_flush",
        "cg_csr_trap",
        "cg_riscvisacov_operands",
        "cg_riscvisacov_value_corners",
        "cg_riscvisacov_immediates",
    ]:
        assert f"covergroup {group}" in sv
    assert "bind core cpu_m1_func_cov_observer" in sv
    assert "module cpu_m1_func_cov_observer" in sv


def test_phase_04_08_report_has_measured_functional_coverage():
    report = _read(PHASE_DIR / "functional_coverage_report.md")
    match = re.search(r"Overall functional coverage: ([0-9]+(?:\.[0-9]+)?)%", report)
    assert match, "missing overall functional coverage"
    overall = float(match.group(1))
    assert overall >= THRESHOLD_PERCENT
    assert "gate threshold:" in report
    assert "Uncovered Bin Triage" in report


def test_phase_04_08_every_uncovered_bin_has_triage():
    rows = _rows(PHASE_DIR / "uncovered_bins.csv")
    for row in rows:
        assert row["covergroup"]
        assert row["bin"]
        assert row["reason"]
        assert row["reachability"]
        assert row["waiver_candidate"] in {"none", "yes", "waive"}


def test_phase_04_08_vcs_urg_provenance_recorded():
    provenance = _read(PHASE_DIR / "provenance.log")
    for required in [
        "host=",
        "vcs_version=",
        "urg_version=",
        "make clean all",
        "-lca -flex_merge code_union",
    ]:
        assert required in provenance
