"""gate_04_07_csr_idu_residual_coverage - CSR/IDU residual coverage gate."""

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE_DIR = ROOT / "flow/v2_pipeline/phase_04_07_csr_idu_residual_coverage"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def test_phase_04_07_artifacts_exist():
    required = [
        "README.md",
        "Makefile",
        "tb_csr_idu_residual_coverage.v",
        "analyze_delta.py",
        "sim.log",
        "coverage.dat",
        "coverage/merged_with_phase_04_07.dat",
        "coverage/coverage.info",
        "module_delta.csv",
        "csr_idu_residual_coverage.log",
        "csr_idu_residual_coverage_report.md",
        "wave.vcd",
    ]
    for name in required:
        path = PHASE_DIR / name
        assert path.exists(), f"missing Phase 4.7 artifact: {name}"
        assert path.stat().st_size > 0, f"empty Phase 4.7 artifact: {name}"


def test_phase_04_07_behavior_passed_and_checked_residuals():
    sim_log = _read(PHASE_DIR / "sim.log")
    for required in [
        "csr read cycleh addr=c80 data=00000000",
        "csr read instreth addr=c82 data=00000000",
        "csr read mepc explicit write addr=341 data=00001234",
        "csr read mcause explicit write addr=342 data=00000002",
        "csr read unsupported csr default write addr=7c1 data=00000000",
        "decode fence instr=0000000f",
        "decode fence.i instr=0000100f",
        "decode bltu instr=00206463",
        "decode bgeu instr=00207563",
        "decode reserved branch funct3 default instr=00203263",
        "PASS: CSR/IDU residual coverage completed",
    ]:
        assert required in sim_log
    assert "decode reserved branch funct3 default instr=00203263 alu=10 branch=1 invert=0 br_type=1 illegal=1" in sim_log
    assert "FAIL:" not in sim_log


def test_phase_04_07_coverage_delta_is_dut_only_and_positive():
    log = _read(PHASE_DIR / "csr_idu_residual_coverage.log")
    report = _read(PHASE_DIR / "csr_idu_residual_coverage_report.md")
    assert "PASS: CSR/IDU residual coverage merged" in log
    assert "not-closed" in report
    assert "coverplan-required" in report


def test_phase_04_07_csr_and_idu_line_residuals_are_closed():
    # P2 2026-06-09: intent-based (was frozen snapshot of smaller core). Absolute
    # closure tracked in gate_04_09_code_coverage_signoff.py.
    rows = {row["module"]: row for row in _rows(PHASE_DIR / "module_delta.csv")}
    for mod in ('csr.v', 'idu.v'):
        assert mod in rows, f"{mod} delta not recorded"
        r = rows[mod]
        assert int(r["line_hit_delta"]) >= 0
        assert int(r["merged_line_hit"]) >= int(r["base_line_hit"])
        assert int(r["merged_toggle_hit"]) >= int(r["base_toggle_hit"])

def test_phase_04_07_waveform_is_focused_not_full_dump():
    vcd = PHASE_DIR / "wave.vcd"
    size_kb = vcd.stat().st_size / 1024.0
    assert 5 < size_kb < 256
    tb = _read(PHASE_DIR / "tb_csr_idu_residual_coverage.v")
    assert "$dumpoff" in tb
    assert "$dumpon" in tb
    assert "$test$plusargs(\"full_vcd\")" in tb
    for required_signal in [
        "u_csr.mepc_reg",
        "u_csr.mcause_reg",
        "u_csr.cycle_cnt",
        "u_csr.instret_cnt",
        "alu_op",
        "is_branch",
        "branch_invert",
        "br_type",
    ]:
        assert required_signal in tb
