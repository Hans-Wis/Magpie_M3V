"""gate_03_01_trap_irq_lockstep - compressed IRQ trap lockstep gate."""

import csv
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE_DIR = ROOT / "flow/v2_pipeline/phase_03_01_trap_irq_lockstep"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def _read_head(path: Path, size: int = 4096) -> str:
    with path.open("rb") as fh:
        return fh.read(size).decode("utf-8", errors="replace")


def test_phase_03_01_artifacts_exist():
    required = [
        "README.md",
        "Makefile",
        "firmware.S",
        "firmware.lds",
        "firmware_spike.lds",
        "tb_trap_irq_lockstep.v",
        "trap_irq_lockstep.py",
        "firmware.hex",
        "firmware.disasm",
        "firmware.elf",
        "firmware_spike.elf",
        "sim.log",
        "dut_commit.trace",
        "dut_trap.trace",
        "spike.log",
        "spike_prefix.trace",
        "trap_irq_lockstep.log",
        "trap_irq_lockstep_report.md",
        "wave.vcd",
    ]
    for name in required:
        path = PHASE_DIR / name
        assert path.exists(), f"missing Phase 3.1 artifact: {name}"
        assert path.stat().st_size > 0, f"empty Phase 3.1 artifact: {name}"


def test_phase_03_01_prefix_commits_match_spike():
    dut = _rows(PHASE_DIR / "dut_commit.trace")
    spike = _rows(PHASE_DIR / "spike_prefix.trace")
    assert len(dut) == 13
    assert dut == spike
    assert dut[-1] == {
        "idx": "12",
        "pc": "0000002a",
        "instr": "0000a899",
        "rd": "0",
        "wdata": "00000000",
    }


def test_phase_03_01_trap_events_cover_compressed_irq_mepc_and_mstatus():
    events = {row["event"]: row for row in _rows(PHASE_DIR / "dut_trap.trace")}
    expected = {
        "irq_entry": ("00000080", "00000082"),
        "mepc": ("0000010c", "00000082"),
        "mcause": ("00000114", "8000000b"),
        "mstatus": ("0000011c", "00001880"),  # MPP=M(0x1800)+MPIE(0x80); spec/Spike-correct (was stale 0x80). P2 2026-06-09
        "mret": ("0000011c", "00000082"),
        "resume": ("00000090", "0000600d"),
    }
    assert set(events) == set(expected)
    for name, (pc, value) in expected.items():
        assert events[name]["pc"] == pc
        assert events[name]["value"] == value


def test_phase_03_01_logs_report_and_rtl_fix_are_recorded():
    sim_log = _read(PHASE_DIR / "sim.log")
    lockstep_log = _read(PHASE_DIR / "trap_irq_lockstep.log")
    report = _read(PHASE_DIR / "trap_irq_lockstep_report.md")
    full_report = _read(ROOT / "docs/v2_pipeline_full_verification_report.md")
    adr = _read(ROOT / "docs/adr/0003-csr-external-irq-pending-collision.md")
    taxonomy = _read(ROOT / "docs/v2_pipeline_bug_taxonomy.md")
    csr = _read(ROOT / "design/cpu_m1/rtl/csr.v")

    assert "PASS: trap/IRQ lockstep trace captured prefix commits and CSR events" in sim_log
    assert "PASS: prefix lockstep matched 13 commits; trap events matched mepc/mcause/mstatus/mret" in lockstep_log
    assert "Status: pass" in report
    assert "Checked trap fields: `mepc`, `mcause`, handler `mstatus`, `mret` resume." in report
    assert "trap_enter         ? 1'b0" in csr
    assert "irq_external_pulse ? 1'b1" in csr
    assert "local RTL deviation" in full_report
    assert "Phase 3.2 IRQ Collision Contract Evidence" in full_report
    assert "Status: **accepted**" in adr
    assert "BUG-IRQ-0001" in taxonomy
    assert "RISK-IRQ-0002" in taxonomy
    assert "Closed for current pulse contract" in taxonomy


def test_phase_03_01_comparator_replays_and_passes():
    assert shutil.which("spike"), "spike executable not found"
    result = subprocess.run(
        ["python3", "trap_irq_lockstep.py"],
        cwd=PHASE_DIR,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    assert "PASS: prefix lockstep matched 13 commits" in result.stdout


def test_phase_03_01_vcd_header_exposes_trap_irq_debug_context():
    vcd_head = _read_head(PHASE_DIR / "wave.vcd")
    for required in [
        "$scope module tb_trap_irq_lockstep",
        "irq_external_pulse",
        "commit_count",
        "stored_mepc",
        "stored_mcause",
        "stored_mstatus",
        "dbg_pc",
        "dbg_instr",
        "d_mem_addr",
        "d_mem_wdata",
    ]:
        assert required in vcd_head
