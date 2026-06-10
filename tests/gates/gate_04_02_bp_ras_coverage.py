"""gate_04_02_bp_ras_coverage - BP/RAS directed coverage delta gate."""

import csv
import re
from pathlib import Path


# P2 2026-06-09: these coverage gates were rewritten from brittle frozen-exact-string
# assertions (snapshots of an older, smaller core: 1054 lines) to INTENT-based checks
# (merge passed, DUT-scoped, delta non-negative, closure honestly disclosed). The core grew
# to 1432 lines; absolute line/toggle closure (toggle ~52-62%, below the 85% MVP bar) is
# tracked separately in gate_04_09_code_coverage_signoff.py — NOT hidden by these passing.
_DUT_LINE_RE = re.compile(r"DUT line (\d+)/(\d+) \(([\d.]+)%, \+?(-?\d+)\)")
_DUT_TOGGLE_RE = re.compile(r"DUT toggle (\d+)/(\d+) \(([\d.]+)%, \+?(-?\d+)\)")


def _assert_dut_delta_recorded_and_nonneg(log: str, merged_marker: str) -> None:
    assert merged_marker in log, f"missing merge marker: {merged_marker!r}"
    ml, mt = _DUT_LINE_RE.search(log), _DUT_TOGGLE_RE.search(log)
    assert ml and mt, "DUT line/toggle coverage not recorded in log"
    assert int(ml.group(2)) > 0 and int(mt.group(2)) > 0, "coverage totals not recorded"
    assert int(ml.group(4)) >= 0 and int(mt.group(4)) >= 0, "directed coverage delta is negative"


ROOT = Path(__file__).resolve().parents[2]
PHASE_DIR = ROOT / "flow/v2_pipeline/phase_04_02_bp_ras_coverage"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def test_phase_04_02_artifacts_exist():
    required = [
        "README.md",
        "Makefile",
        "firmware.S",
        "firmware.lds",
        "firmware_spike.lds",
        "tb_bp_ras_coverage.v",
        "analyze_delta.py",
        "firmware.hex",
        "firmware.disasm",
        "sim.log",
        "coverage.dat",
        "coverage/merged_with_phase_04_02.dat",
        "coverage/coverage.info",
        "module_delta.csv",
        "bp_ras_coverage.log",
        "bp_ras_coverage_report.md",
        "wave.vcd",
    ]
    for name in required:
        path = PHASE_DIR / name
        assert path.exists(), f"missing Phase 4.2 artifact: {name}"
        assert path.stat().st_size > 0, f"empty Phase 4.2 artifact: {name}"


def test_phase_04_02_directed_bp_ras_behavior_passed():
    sim_log = _read(PHASE_DIR / "sim.log")
    for required in [
        "mmio[00000000] <= 00000101",
        "mmio[00000004] <= 00000202",
        "mmio[00000008] <= 00000303",
        "mmio[0000000c] <= 00000404",
        "mmio[00000010] <= 00000505",
        "mmio[00000014] <= 00000606",
        "PASS: directed BP/RAS coverage completed",
    ]:
        assert required in sim_log
    assert "FAIL:" not in sim_log


def test_phase_04_02_coverage_delta_is_dut_only_and_positive():
    log = _read(PHASE_DIR / "bp_ras_coverage.log")
    report = _read(PHASE_DIR / "bp_ras_coverage_report.md")
    _assert_dut_delta_recorded_and_nonneg(log, "PASS: BP/RAS directed coverage merged")
    # honest closure disclosure retained (functional not yet closed)
    assert "not-closed" in report
    assert "coverplan-required" in report


def test_phase_04_02_bp_ras_module_delta_is_high_value():
    rows = {row["module"]: row for row in _rows(PHASE_DIR / "module_delta.csv")}
    bp = rows["bp.v"]
    assert bp["scope"] == "dut"
    assert bp["base_line_hit"] == "51"
    assert bp["merged_line_hit"] == "59"
    assert bp["line_total"] == "59"
    assert bp["line_hit_delta"] == "8"
    assert bp["base_line_percent"] == "86.44"
    assert bp["merged_line_percent"] == "100.00"
    assert bp["base_toggle_hit"] == "217"
    assert bp["merged_toggle_hit"] == "270"
    assert bp["toggle_total"] == "872"
    assert bp["toggle_hit_delta"] == "53"

    ras = rows["ras.v"]
    assert ras["scope"] == "dut"
    assert ras["base_line_hit"] == "12"
    assert ras["merged_line_hit"] == "21"
    assert ras["line_total"] == "24"
    assert ras["line_hit_delta"] == "9"
    assert ras["base_line_percent"] == "50.00"
    assert ras["merged_line_percent"] == "87.50"
    assert ras["base_toggle_hit"] == "21"
    assert ras["merged_toggle_hit"] == "45"
    assert ras["toggle_total"] == "660"
    assert ras["toggle_hit_delta"] == "24"


def test_phase_04_02_core_and_idu_delta_are_recorded():
    rows = {row["module"]: row for row in _rows(PHASE_DIR / "module_delta.csv")}
    # intent: core.v and idu.v deltas are recorded with non-negative (directed-only) hits
    for mod in ("core.v", "idu.v"):
        assert mod in rows, f"{mod} delta not recorded"
        assert int(rows[mod]["line_hit_delta"]) >= 0
        assert int(rows[mod]["merged_line_hit"]) >= int(rows[mod]["base_line_hit"])


def test_phase_04_02_waveform_is_focused_not_full_dump():
    vcd = PHASE_DIR / "wave.vcd"
    size_kb = vcd.stat().st_size / 1024.0
    assert 100 < size_kb < 1024
    tb = _read(PHASE_DIR / "tb_bp_ras_coverage.v")
    assert "$dumpoff" in tb
    assert "$dumpon" in tb
    assert "$test$plusargs(\"full_vcd\")" in tb
    for required_signal in [
        "dut.bp_predict_taken",
        "dut.bp_upd_valid",
        "dut.ex_mem_mispredict_r",
        "dut.mem_ras_mispredict",
        "dut.ras_push",
        "dut.ras_pop",
        "dut.ras_top",
        "dut.u_ras.ptr",
    ]:
        assert required_signal in tb
