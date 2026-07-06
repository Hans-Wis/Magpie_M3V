"""gate_03_05_random_lockstep - deterministic random Spike lockstep gate."""

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE_DIR = ROOT / "flow/v2_pipeline/phase_03_05_random_lockstep"
CORE = ROOT / "design/cpu_m1/rtl/core.v"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def _read_head(path: Path, size: int = 8192) -> str:
    with path.open("rb") as fh:
        return fh.read(size).decode("utf-8", errors="replace")


def test_phase_03_05_artifacts_exist():
    required = [
        "README.md",
        "Makefile",
        "gen_random_program.py",
        "random_lockstep.py",
        "firmware.S",
        "firmware.lds",
        "firmware_spike.lds",
        "tb_random_lockstep.v",
        "firmware.hex",
        "firmware.disasm",
        "firmware.elf",
        "firmware_spike.elf",
        "sim.log",
        "dut_commit.trace",
        "spike.log",
        "spike_commit.trace",
        "random_lockstep.log",
        "random_lockstep_report.md",
        "wave.vcd",
    ]
    for name in required:
        path = PHASE_DIR / name
        assert path.exists(), f"missing Phase 3.5 artifact: {name}"
        assert path.stat().st_size > 0, f"empty Phase 3.5 artifact: {name}"


def test_phase_03_05_generator_is_deterministic_and_bounded():
    source = _read(PHASE_DIR / "gen_random_program.py")
    firmware = _read(PHASE_DIR / "firmware.S")
    assert "default=20260607" in source
    assert "default=48" in source
    assert "range(5, 30)" in source
    assert "la   x31, data_area" in firmware
    assert "addi x30, zero, 7" in firmware
    assert "seed=20260607 count=48" in firmware


def test_phase_03_05_dut_and_spike_traces_match_exactly():
    dut = _rows(PHASE_DIR / "dut_commit.trace")
    spike = _rows(PHASE_DIR / "spike_commit.trace")
    assert len(dut) == 81
    assert dut == spike
    assert dut[0] == {
        "idx": "0",
        "pc": "00000000",
        "instr": "00004137",
        "rd": "2",
        "wdata": "00004000",
    }
    assert dut[34] == {
        "idx": "34",
        "pc": "00000080",
        "instr": "03e64833",
        "rd": "16",
        "wdata": "0000007b",
    }
    assert dut[-1] == {
        "idx": "80",
        "pc": "00000138",
        "instr": "5326eb13",
        "rd": "22",
        "wdata": "fffffffa",
    }


def test_phase_03_05_logs_report_and_shared_helper_usage():
    sim_log = _read(PHASE_DIR / "sim.log")
    lockstep_log = _read(PHASE_DIR / "random_lockstep.log")
    report = _read(PHASE_DIR / "random_lockstep_report.md")
    script = _read(PHASE_DIR / "random_lockstep.py")

    assert "PASS: random DUT trace wrote 81 commits before ebreak" in sim_log
    assert "PASS: random lockstep matched 81 commits" in lockstep_log
    assert "Status: pass" in report
    assert "deterministic bounded pseudo-random RV32IMC slice" in report
    assert "from spike_commit import" in script
    assert "parse_spike_commits" in script
    assert "compare_commits" in script


def test_phase_03_05_m_unit_result_latch_deviation_is_present():
    core = _read(CORE)
    for required in [
        "md_active_is_div",
        "md_result_valid",
        "md_result_q",
        "wire        md_done = md_active_is_div ? div_done : mul_done;",
        "wire [31:0] md_result = md_result_q;",
        "md_result_q     <= md_active_is_div ? div_result : mul_result;",
    ]:
        assert required in core


def test_phase_03_05_vcd_header_exposes_random_review_context():
    vcd_head = _read_head(PHASE_DIR / "wave.vcd")
    for required in [
        "$scope module tb_random_lockstep",
        "commit_count",
        "dbg_pc",
        "dbg_instr",
        "dbg_state",
        "d_mem_valid",
        "d_mem_addr",
        "id_is_muldiv",
        "id_md_is_div",
    ]:
        assert required in vcd_head
