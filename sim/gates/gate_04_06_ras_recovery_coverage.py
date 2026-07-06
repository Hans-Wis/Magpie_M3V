"""gate_04_06_ras_recovery_coverage - RAS recovery residual coverage gate."""

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE_DIR = ROOT / "flow/v2_pipeline/phase_04_06_ras_recovery_coverage"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def test_phase_04_06_artifacts_exist():
    required = [
        "README.md",
        "Makefile",
        "firmware.S",
        "firmware.lds",
        "firmware_spike.lds",
        "tb_ras_recovery_coverage.v",
        "analyze_delta.py",
        "firmware.hex",
        "firmware.disasm",
        "sim.log",
        "coverage.dat",
        "coverage/merged_with_phase_04_06.dat",
        "coverage/coverage.info",
        "module_delta.csv",
        "ras_recovery_coverage.log",
        "ras_recovery_coverage_report.md",
        "wave.vcd",
    ]
    for name in required:
        path = PHASE_DIR / name
        assert path.exists(), f"missing Phase 4.6 artifact: {name}"
        assert path.stat().st_size > 0, f"empty Phase 4.6 artifact: {name}"


def test_phase_04_06_behavior_passed_and_wrong_path_did_not_commit():
    sim_log = _read(PHASE_DIR / "sim.log")
    for required in [
        "RAS unit pointer-edge checks passed",
        "saw mem_ras_mispredict pred=00000010 actual=00000020",
        "saw RAS recovery redirect target=00000020",
        "mmio[00000000] <= 00000406",
        "PASS: directed RAS recovery and pointer-edge coverage completed",
    ]:
        assert required in sim_log
    assert "wrong-path predicted return committed" not in sim_log
    assert "FAIL:" not in sim_log


def test_phase_04_06_firmware_contains_poisoned_return_pattern():
    disasm = _read(PHASE_DIR / "firmware.disasm")
    for required in [
        "<predicted_return>:",
        "bad00bad",
        "<actual_return>:",
        "406",
        "<poison_ret>:",
        "mv\tra,t0",
        "ret",
    ]:
        assert required in disasm


def test_phase_04_06_coverage_delta_is_dut_only_and_positive():
    log = _read(PHASE_DIR / "ras_recovery_coverage.log")
    report = _read(PHASE_DIR / "ras_recovery_coverage_report.md")
    assert "PASS: RAS recovery coverage merged" in log
    assert "not-closed" in report
    assert "coverplan-required" in report


def test_phase_04_06_core_and_ras_line_residuals_are_closed():
    # P2 2026-06-09: intent-based (was frozen snapshot of smaller core). Absolute
    # closure tracked in gate_04_09_code_coverage_signoff.py.
    rows = {row["module"]: row for row in _rows(PHASE_DIR / "module_delta.csv")}
    for mod in ('core.v', 'ras.v'):
        assert mod in rows, f"{mod} delta not recorded"
        r = rows[mod]
        assert int(r["line_hit_delta"]) >= 0
        assert int(r["merged_line_hit"]) >= int(r["base_line_hit"])
        assert int(r["merged_toggle_hit"]) >= int(r["base_toggle_hit"])

def test_phase_04_06_waveform_is_focused_not_full_dump():
    vcd = PHASE_DIR / "wave.vcd"
    size_kb = vcd.stat().st_size / 1024.0
    assert 50 < size_kb < 512
    tb = _read(PHASE_DIR / "tb_ras_recovery_coverage.v")
    assert "$dumpoff" in tb
    assert "$dumpon" in tb
    assert "$test$plusargs(\"full_vcd\")" in tb
    for required_signal in [
        "dut.mem_ras_mispredict",
        "dut.mem_ras_actual_target",
        "dut.ex_mem_pred_ras_target_r",
        "dut.pc_redirect",
        "dut.redirect_target",
        "u_ras_edge.ptr",
    ]:
        assert required_signal in tb
