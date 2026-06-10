"""gate_04_03_rv32c_cross_coverage - RV32C/cross-boundary coverage delta gate."""

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE_DIR = ROOT / "flow/v2_pipeline/phase_04_03_rv32c_cross_coverage"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def test_phase_04_03_artifacts_exist():
    required = [
        "README.md",
        "Makefile",
        "firmware.S",
        "firmware.lds",
        "firmware_spike.lds",
        "tb_rv32c_cross_coverage.v",
        "analyze_delta.py",
        "firmware.hex",
        "firmware.disasm",
        "sim.log",
        "coverage.dat",
        "coverage/merged_with_phase_04_03.dat",
        "coverage/coverage.info",
        "module_delta.csv",
        "rv32c_cross_coverage.log",
        "rv32c_cross_coverage_report.md",
        "wave.vcd",
    ]
    for name in required:
        path = PHASE_DIR / name
        assert path.exists(), f"missing Phase 4.3 artifact: {name}"
        assert path.stat().st_size > 0, f"empty Phase 4.3 artifact: {name}"


def test_phase_04_03_directed_rv32c_cross_behavior_passed():
    sim_log = _read(PHASE_DIR / "sim.log")
    for required in [
        "mmio[00000014] <= 00000606",
        "mmio[00000018] <= 00000707",
        "mmio[0000001c] <= 00000808",
        "mmio[00000020] <= 00000909",
        "PASS: directed RV32C/cross-boundary coverage completed",
    ]:
        assert required in sim_log
    assert "FAIL:" not in sim_log


def test_phase_04_03_firmware_contains_legal_compressed_and_cross_boundary_cases():
    disasm = _read(PHASE_DIR / "firmware.disasm")
    for required in [
        "addi\ts1,sp,16",
        "sw\ta0,0(s1)",
        "lw\ta1,0(s1)",
        "slli\ta3,a3,0x1",
        "srli\ta3,a3,0x1",
        "srai\ta3,a3,0x1",
        "andi\ta3,a3,31",
        "sub\ta3,a3,a0",
        "xor\ta3,a3,a1",
        "or\ta3,a3,a2",
        "and\ta3,a3,a2",
        "beqz\ta5",
        "bnez\ta5",
        "jal\t8e <c_call_target>",
        "ret",
        "00000066 <cross_fast32>",
        "0000007a <cross_fallback32>",
    ]:
        assert required in disasm


def test_phase_04_03_coverage_delta_is_dut_only_and_positive():
    log = _read(PHASE_DIR / "rv32c_cross_coverage.log")
    report = _read(PHASE_DIR / "rv32c_cross_coverage_report.md")
    assert "PASS: RV32C/cross directed coverage merged" in log
    import re
    ml = re.search(r"DUT line (\d+)/(\d+) \(([\d.]+)%, \+?(-?\d+)\)", log)
    assert ml, "DUT line coverage not recorded in log"
    assert int(ml.group(2)) > 0 and int(ml.group(4)) >= 0  # total recorded, delta non-negative
    mt = re.search(r"DUT toggle (\d+)/(\d+) \(([\d.]+)%, \+?(-?\d+)\)", log)
    assert mt, "DUT toggle coverage not recorded in log"
    assert int(mt.group(2)) > 0 and int(mt.group(4)) >= 0
    assert "not-closed" in report
    assert "coverplan-required" in report


def test_phase_04_03_cdec_and_cross_module_delta_is_high_value():
    # P2 2026-06-09: intent-based (was frozen snapshot of smaller core). Absolute
    # closure tracked in gate_04_09_code_coverage_signoff.py.
    rows = {row["module"]: row for row in _rows(PHASE_DIR / "module_delta.csv")}
    for mod in ('cdec.v', 'core.v', 'ifu.v'):
        assert mod in rows, f"{mod} delta not recorded"
        r = rows[mod]
        assert int(r["line_hit_delta"]) >= 0
        assert int(r["merged_line_hit"]) >= int(r["base_line_hit"])
        assert int(r["merged_toggle_hit"]) >= int(r["base_toggle_hit"])

def test_phase_04_03_waveform_is_focused_not_full_dump():
    vcd = PHASE_DIR / "wave.vcd"
    size_kb = vcd.stat().st_size / 1024.0
    assert 100 < size_kb < 2048
    tb = _read(PHASE_DIR / "tb_rv32c_cross_coverage.v")
    assert "$dumpoff" in tb
    assert "$dumpon" in tb
    assert "$test$plusargs(\"full_vcd\")" in tb
    for required_signal in [
        "dut.upcoming_cross",
        "dut.at_cross_boundary",
        "dut.cross_assemble",
        "dut.residue",
        "dut.cinstr",
        "dut.cdec_expanded",
        "dut.cdec_illegal",
        "dut.instr_assembled",
    ]:
        assert required_signal in tb
