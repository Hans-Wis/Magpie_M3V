"""gate_03_00_spike_lockstep - minimal Spike per-commit lockstep gate.

This gate checks the first bounded vertical slice against Spike. It is a
directed RV32IMC program, not random DV or coverage closure.
"""

import csv
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE_DIR = ROOT / "flow/v2_pipeline/phase_03_00_spike_lockstep"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _read_head(path: Path, size: int = 4096) -> str:
    with path.open("rb") as fh:
        return fh.read(size).decode("utf-8", errors="replace")


def _trace_rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def test_phase_03_00_evidence_directory_and_required_files_exist():
    required = [
        "README.md",
        "Makefile",
        "firmware.S",
        "firmware.lds",
        "firmware_spike.lds",
        "tb_spike_lockstep.v",
        "spike_lockstep.py",
        "firmware.hex",
        "firmware.disasm",
        "firmware.elf",
        "firmware_spike.elf",
        "sim.log",
        "dut_commit.trace",
        "spike.log",
        "spike_commit.trace",
        "lockstep.log",
        "lockstep_report.md",
        "wave.vcd",
    ]
    for name in required:
        path = PHASE_DIR / name
        assert path.exists(), f"missing Phase 3.0 artifact: {name}"
        assert path.stat().st_size > 0, f"empty Phase 3.0 artifact: {name}"


def test_phase_03_00_directed_program_covers_minimal_vertical_slice():
    disasm = _read(PHASE_DIR / "firmware.disasm")
    for required in [
        "4405                \tli\ts0,1",
        "0409                \taddi\ts0,s0,2",
        "add",
        "sw",
        "lw",
        "beq",
        "mul",
        "addi",
        "ebreak",
    ]:
        assert required in disasm


def test_phase_03_00_dut_and_spike_traces_match_exactly():
    dut = _trace_rows(PHASE_DIR / "dut_commit.trace")
    spike = _trace_rows(PHASE_DIR / "spike_commit.trace")
    assert len(dut) == 14
    assert dut == spike
    assert dut[0] == {
        "idx": "0",
        "pc": "00000000",
        "instr": "00004137",
        "rd": "2",
        "wdata": "00004000",
    }
    assert dut[-1] == {
        "idx": "13",
        "pc": "0000002e",
        "instr": "ffda8b13",
        "rd": "22",
        "wdata": "00000007",
    }


def test_phase_03_00_logs_and_report_record_lockstep_pass_without_overclaiming():
    sim_log = _read(PHASE_DIR / "sim.log")
    lockstep_log = _read(PHASE_DIR / "lockstep.log")
    report = _read(PHASE_DIR / "lockstep_report.md")
    readme = _read(PHASE_DIR / "README.md")

    assert "PASS: DUT commit trace wrote 14 commits before ebreak" in sim_log
    assert "PASS: lockstep matched 14 commits" in lockstep_log
    assert "Status: pass" in report
    assert "Compared fields: `pc`, `instr`, `rd`, `wdata`." in report
    assert "not random DV or coverage closure" in report
    assert "No interrupts or CSR comparison in this first lockstep slice." in readme


def test_phase_03_00_spike_comparator_replays_and_passes():
    assert shutil.which("spike"), "spike executable not found"
    result = subprocess.run(
        ["python3", "spike_lockstep.py"],
        cwd=PHASE_DIR,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    assert "PASS: lockstep matched 14 commits" in result.stdout


def test_phase_03_00_vcd_header_exposes_commit_debug_context():
    vcd_head = _read_head(PHASE_DIR / "wave.vcd")
    for required in [
        "$scope module tb_spike_lockstep",
        "commit_count",
        "dbg_pc",
        "dbg_instr",
        "dbg_state",
        "i_mem_addr",
        "d_mem_addr",
        "d_mem_wdata",
    ]:
        assert required in vcd_head
