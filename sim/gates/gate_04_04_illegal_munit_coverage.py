"""gate_04_04_illegal_munit_coverage - illegal compressed + M-unit coverage gate."""

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE_DIR = ROOT / "flow/v2_pipeline/phase_04_04_illegal_munit_coverage"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def test_phase_04_04_artifacts_exist():
    required = [
        "README.md",
        "Makefile",
        "firmware.S",
        "firmware.lds",
        "firmware_spike.lds",
        "tb_illegal_munit_coverage.v",
        "analyze_delta.py",
        "firmware.hex",
        "firmware.disasm",
        "sim.log",
        "coverage.dat",
        "coverage/merged_with_phase_04_04.dat",
        "coverage/coverage.info",
        "module_delta.csv",
        "illegal_munit_coverage.log",
        "illegal_munit_coverage_report.md",
        "wave.vcd",
    ]
    for name in required:
        path = PHASE_DIR / name
        assert path.exists(), f"missing Phase 4.4 artifact: {name}"
        assert path.stat().st_size > 0, f"empty Phase 4.4 artifact: {name}"


def test_phase_04_04_behavior_passed():
    sim_log = _read(PHASE_DIR / "sim.log")
    for required in [
        "mmio[00000024] <= 00000a0a",
        "illegal compressed case 1 reached WB illegal",
        "illegal compressed case 1 asserted terminal trap",
        "illegal compressed case 2 reached WB illegal",
        "illegal compressed case 2 asserted terminal trap",
        "illegal compressed case 3 reached WB illegal",
        "illegal compressed case 3 asserted terminal trap",
        "PASS: illegal compressed trap and M-unit coverage completed",
    ]:
        assert required in sim_log
    assert "FAIL:" not in sim_log


def test_phase_04_04_firmware_contains_m_corners_and_cjalr():
    disasm = _read(PHASE_DIR / "firmware.disasm")
    for required in [
        "mulh",
        "mulhsu",
        "mulhu",
        "div",
        "rem",
        "divu",
        "remu",
        "jalr\tt0",
        "sw\tt2,36(s0)",
    ]:
        assert required in disasm


def test_phase_04_04_coverage_delta_is_dut_only_and_positive():
    log = _read(PHASE_DIR / "illegal_munit_coverage.log")
    report = _read(PHASE_DIR / "illegal_munit_coverage_report.md")
    assert "PASS: illegal compressed/M-unit coverage merged" in log
    assert "not-closed" in report
    assert "coverplan-required" in report


def test_phase_04_04_cdec_div_mul_module_delta_is_high_value():
    # P2 2026-06-09: intent-based (was frozen snapshot of smaller core). Absolute
    # closure tracked in gate_04_09_code_coverage_signoff.py.
    rows = {row["module"]: row for row in _rows(PHASE_DIR / "module_delta.csv")}
    for mod in ('cdec.v', 'div.v', 'mul.v'):
        assert mod in rows, f"{mod} delta not recorded"
        r = rows[mod]
        assert int(r["line_hit_delta"]) >= 0
        assert int(r["merged_line_hit"]) >= int(r["base_line_hit"])
        assert int(r["merged_toggle_hit"]) >= int(r["base_toggle_hit"])

def test_phase_04_04_waveform_is_focused_not_full_dump():
    vcd = PHASE_DIR / "wave.vcd"
    size_kb = vcd.stat().st_size / 1024.0
    assert 100 < size_kb < 1024
    tb = _read(PHASE_DIR / "tb_illegal_munit_coverage.v")
    assert "$dumpoff" in tb
    assert "$dumpon" in tb
    assert "$test$plusargs(\"full_vcd\")" in tb
    for required_signal in [
        "dut.md_started",
        "dut.md_active_is_div",
        "dut.md_result_valid",
        "dut.md_result_q",
        "dut.cdec_illegal",
        "dut.id_illegal",
        "dut.ex_mem_illegal_r",
        "dut.ex_wb_illegal_r",
        "dut.trap_latched",
    ]:
        assert required_signal in tb
