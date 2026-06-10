"""gate_03_07_muldiv_hazard - directed M-unit hazard regression gate."""

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE_DIR = ROOT / "flow/v2_pipeline/phase_03_07_muldiv_hazard"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def _read_head(path: Path, size: int = 12288) -> str:
    with path.open("rb") as fh:
        return fh.read(size).decode("utf-8", errors="replace")


def test_phase_03_07_artifacts_exist():
    required = [
        "README.md",
        "Makefile",
        "firmware.S",
        "firmware.lds",
        "firmware_spike.lds",
        "tb_muldiv_hazard.v",
        "muldiv_hazard.py",
        "firmware.hex",
        "firmware.disasm",
        "firmware.elf",
        "firmware_spike.elf",
        "sim.log",
        "dut_commit.trace",
        "spike.log",
        "spike_commit.trace",
        "muldiv_hazard.log",
        "muldiv_hazard_report.md",
        "wave.vcd",
    ]
    for name in required:
        path = PHASE_DIR / name
        assert path.exists(), f"missing Phase 3.7 artifact: {name}"
        assert path.stat().st_size > 0, f"empty Phase 3.7 artifact: {name}"
    assert not (PHASE_DIR / "directed_lockstep.log").exists()
    assert not (PHASE_DIR / "directed_lockstep_report.md").exists()


def test_phase_03_07_program_targets_m_unit_hazards_and_corners():
    asm = _read(PHASE_DIR / "firmware.S")
    disasm = _read(PHASE_DIR / "firmware.disasm")
    for required in [
        "Back-to-back M ops",
        "M result as store data",
        "M result as address component",
        "Divide-by-zero and overflow",
        "div  s6, s1, zero",
        "rem  s8, s1, zero",
        "div  s9, s5, s4",
        "rem  s10, s5, s4",
        "divu s11, t0, s2",
        "remu t0, t0, s2",
    ]:
        assert required in asm
    for mnemonic in ["mul", "div", "rem", "divu", "remu", "sw", "lw", "bne", "ebreak"]:
        assert mnemonic in disasm


def test_phase_03_07_dut_and_spike_traces_match_exactly():
    dut = _rows(PHASE_DIR / "dut_commit.trace")
    spike = _rows(PHASE_DIR / "spike_commit.trace")
    assert len(dut) == 45
    assert dut == spike
    assert dut[9] == {
        "idx": "9",
        "pc": "0000001e",
        "instr": "032482b3",
        "rd": "5",
        "wdata": "000000b9",
    }
    assert dut[10] == {
        "idx": "10",
        "pc": "00000022",
        "instr": "0322c333",
        "rd": "6",
        "wdata": "00000025",
    }
    assert dut[35] == {
        "idx": "35",
        "pc": "00000080",
        "instr": "034accb3",
        "rd": "25",
        "wdata": "80000000",
    }
    assert dut[-1] == {
        "idx": "44",
        "pc": "000000a2",
        "instr": "0000137d",
        "rd": "6",
        "wdata": "00000025",
    }


def test_phase_03_07_logs_report_and_dut_aware_normalization():
    sim_log = _read(PHASE_DIR / "sim.log")
    lockstep_log = _read(PHASE_DIR / "muldiv_hazard.log")
    report = _read(PHASE_DIR / "muldiv_hazard_report.md")
    script = _read(PHASE_DIR / "muldiv_hazard.py")

    assert "PASS: muldiv hazard DUT trace wrote 45 commits before ebreak" in sim_log
    assert "PASS: muldiv hazard lockstep matched 45 commits" in lockstep_log
    assert "Status: pass" in report
    assert "directed mul/div stall, result-latch, forwarding, load-use" in report
    assert "normalize_wdata_base=False" in script
    assert "drow[\"wdata\"] == raw - SPIKE_BASE" in script


def test_phase_03_07_vcd_header_exposes_m_unit_review_context():
    vcd_head = _read_head(PHASE_DIR / "wave.vcd")
    for required in [
        "$scope module tb_muldiv_hazard",
        "commit_count",
        "dbg_pc",
        "dbg_instr",
        "md_started",
        "md_active_is_div",
        "md_result_valid",
        "md_result_q",
        "md_done",
        "md_busy",
        "ex_mem_md_result_r",
        "ex_wb_md_result_r",
    ]:
        assert required in vcd_head
