"""gate_03_04_directed_lockstep - expanded directed Spike lockstep gate."""

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE_DIR = ROOT / "flow/v2_pipeline/phase_03_04_directed_lockstep"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def _read_head(path: Path, size: int = 4096) -> str:
    with path.open("rb") as fh:
        return fh.read(size).decode("utf-8", errors="replace")


def test_phase_03_04_artifacts_exist():
    required = [
        "README.md",
        "Makefile",
        "firmware.S",
        "firmware.lds",
        "firmware_spike.lds",
        "tb_directed_lockstep.v",
        "directed_lockstep.py",
        "firmware.hex",
        "firmware.disasm",
        "firmware.elf",
        "firmware_spike.elf",
        "sim.log",
        "dut_commit.trace",
        "spike.log",
        "spike_commit.trace",
        "directed_lockstep.log",
        "directed_lockstep_report.md",
        "wave.vcd",
    ]
    for name in required:
        path = PHASE_DIR / name
        assert path.exists(), f"missing Phase 3.4 artifact: {name}"
        assert path.stat().st_size > 0, f"empty Phase 3.4 artifact: {name}"


def test_phase_03_04_directed_program_expands_instruction_mix():
    disasm = _read(PHASE_DIR / "firmware.disasm")
    for required in [
        "add",
        "sub",
        "xor",
        "or",
        "and",
        "slli",
        "srli",
        "srai",
        "sw",
        "lw",
        "sh",
        "lh",
        "sb",
        "lb",
        "bne",
        "beq",
        "mul",
        "div",
        "rem",
        "jal",
        "ret",
        "ebreak",
    ]:
        assert required in disasm


def test_phase_03_04_dut_and_spike_traces_match_exactly():
    dut = _rows(PHASE_DIR / "dut_commit.trace")
    spike = _rows(PHASE_DIR / "spike_commit.trace")
    assert len(dut) == 40
    assert dut == spike
    assert dut[0] == {
        "idx": "0",
        "pc": "00000000",
        "instr": "00004137",
        "rd": "2",
        "wdata": "00004000",
    }
    assert dut[-1] == {
        "idx": "39",
        "pc": "00000080",
        "instr": "01fb9763",
        "rd": "0",
        "wdata": "00000000",
    }


def test_phase_03_04_jalr_x0_writeback_is_normalized():
    rows = _rows(PHASE_DIR / "dut_commit.trace")
    ret = rows[37]
    assert ret == {
        "idx": "37",
        "pc": "0000008a",
        "instr": "00008067",
        "rd": "0",
        "wdata": "00000000",
    }
    tb = _read(PHASE_DIR / "tb_directed_lockstep.v")
    assert "dut.rfu_wr_idx != 5'd0" in tb


def test_phase_03_04_logs_report_and_shared_helper_usage():
    sim_log = _read(PHASE_DIR / "sim.log")
    lockstep_log = _read(PHASE_DIR / "directed_lockstep.log")
    report = _read(PHASE_DIR / "directed_lockstep_report.md")
    script = _read(PHASE_DIR / "directed_lockstep.py")

    assert "PASS: expanded directed DUT trace wrote 40 commits before ebreak" in sim_log
    assert "PASS: directed lockstep matched 40 commits" in lockstep_log
    assert "Status: pass" in report
    assert "expanded directed RV32IMC slice" in report
    assert "from spike_commit import" in script
    assert "parse_spike_commits" in script
    assert "compare_commits" in script


def test_phase_03_04_vcd_header_exposes_commit_debug_context():
    vcd_head = _read_head(PHASE_DIR / "wave.vcd")
    for required in [
        "$scope module tb_directed_lockstep",
        "commit_count",
        "dbg_pc",
        "dbg_instr",
        "dbg_state",
        "i_mem_addr",
        "d_mem_addr",
        "d_mem_wdata",
    ]:
        assert required in vcd_head
