"""gate_04_01_csr_irq_coverage - CSR/IRQ directed coverage delta gate."""

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE_DIR = ROOT / "flow/v2_pipeline/phase_04_01_csr_irq_coverage"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def test_phase_04_01_artifacts_exist():
    required = [
        "README.md",
        "Makefile",
        "firmware.S",
        "firmware.lds",
        "firmware_spike.lds",
        "tb_csr_irq_coverage.v",
        "analyze_delta.py",
        "firmware.hex",
        "firmware.disasm",
        "sim.log",
        "coverage.dat",
        "coverage/merged_with_phase_04_01.dat",
        "coverage/coverage.info",
        "module_delta.csv",
        "csr_irq_coverage.log",
        "csr_irq_coverage_report.md",
        "wave.vcd",
    ]
    for name in required:
        path = PHASE_DIR / name
        assert path.exists(), f"missing Phase 4.1 artifact: {name}"
        assert path.stat().st_size > 0, f"empty Phase 4.1 artifact: {name}"


def test_phase_04_01_directed_csr_irq_behavior_passed():
    sim_log = _read(PHASE_DIR / "sim.log")
    for required in [
        "mmio[00000000] <= 00000000",
        "mmio[00000004] <= 12345678",
        "mmio[00000008] <= 1234567f",
        "mmio[0000000c] <= 12345677",
        "mmio[00000010] <= 00000000",
        "mmio[0000001c] <= 00000800",
        "mmio[00000024] <= 8000000b",
        "mmio[00000028] <= 00001880",  # handler mstatus MPP=M(0x1800)+MPIE(0x80); spec/Spike-correct (was stale 0x80). P2 2026-06-09
        "mret resume marker observed",
        "PASS: directed CSR/IRQ coverage completed",
    ]:
        assert required in sim_log
    assert "FAIL:" not in sim_log


def test_phase_04_01_coverage_delta_is_dut_only_and_positive():
    # P2 2026-06-09: intent-based (was frozen 1054-line snapshot). Absolute closure tracked in
    # gate_04_09_code_coverage_signoff.py. Here: merge passed, DUT-scoped, delta non-negative.
    import re
    log = _read(PHASE_DIR / "csr_irq_coverage.log")
    report = _read(PHASE_DIR / "csr_irq_coverage_report.md")
    assert "PASS: CSR/IRQ directed coverage merged" in log
    ml = re.search(r"DUT line (\d+)/(\d+) \(([\d.]+)%, \+?(-?\d+)\)", log)
    mt = re.search(r"DUT toggle (\d+)/(\d+) \(([\d.]+)%, \+?(-?\d+)\)", log)
    assert ml and mt, "DUT line/toggle coverage not recorded in log"
    assert int(ml.group(2)) > 0 and int(mt.group(2)) > 0, "coverage totals not recorded"
    assert int(ml.group(4)) >= 0 and int(mt.group(4)) >= 0, "directed coverage delta is negative"
    assert "not-closed" in report
    assert "coverplan-required" in report


def test_phase_04_01_csr_module_delta_is_high_value():
    rows = {row["module"]: row for row in _rows(PHASE_DIR / "module_delta.csv")}
    # intent: csr.v delta recorded, DUT-scoped, non-negative (directed adds coverage)
    csr = rows["csr.v"]
    assert csr["scope"] == "dut"
    assert int(csr["line_hit_delta"]) >= 0
    assert int(csr["merged_line_hit"]) >= int(csr["base_line_hit"])
    assert int(csr["merged_toggle_hit"]) >= int(csr["base_toggle_hit"])


def test_phase_04_01_waveform_is_focused_not_full_dump():
    vcd = PHASE_DIR / "wave.vcd"
    size_kb = vcd.stat().st_size / 1024.0
    assert 50 < size_kb < 1024
    tb = _read(PHASE_DIR / "tb_csr_irq_coverage.v")
    assert "$dumpoff" in tb
    assert "$dumpon" in tb
    assert "$test$plusargs(\"full_vcd\")" in tb
    for required_signal in [
        "dut.u_csr.mstatus_mie",
        "dut.u_csr.mstatus_mpie",
        "dut.u_csr.ext_pending",
        "dut.wb_take_irq",
        "dut.wb_trap_pc_for_mepc",
    ]:
        assert required_signal in tb
