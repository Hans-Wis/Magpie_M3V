"""gate_03_03_spike_comparator_lib - shared Spike comparator helper gate."""

import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LIB_DIR = ROOT / "flow/v2_pipeline/lib"
sys.path.insert(0, str(LIB_DIR))

from spike_commit import compare_commits, parse_spike_commits, write_commit_csv  # noqa: E402


def test_phase_03_03_shared_spike_commit_helper_exists_and_is_used():
    helper = ROOT / "flow/v2_pipeline/lib/spike_commit.py"
    phase_30 = ROOT / "flow/v2_pipeline/phase_03_00_spike_lockstep/spike_lockstep.py"
    phase_31 = ROOT / "flow/v2_pipeline/phase_03_01_trap_irq_lockstep/trap_irq_lockstep.py"

    helper_text = helper.read_text(encoding="utf-8")
    assert "def parse_spike_commits" in helper_text
    assert "def compare_commits" in helper_text
    assert "def check_expected_events" in helper_text

    for script in [phase_30, phase_31]:
        text = script.read_text(encoding="utf-8")
        assert "from spike_commit import" in text
        assert "parse_spike_commits" in text
        assert "compare_commits" in text


def test_phase_03_03_spike_log_parser_normalizes_pc_and_wdata(tmp_path):
    log = tmp_path / "spike.log"
    log.write_text(
        "\n".join(
            [
                "core   0: 3 0x80000000 (0x00004137) x 2 0x80004000",
                "core   0: 3 0x80000004 (0x4405) x 8 0x00000001",
                "core   0: 3 0x80000008 (0x00009002)",
            ]
        ),
        encoding="utf-8",
    )

    rows = parse_spike_commits(
        log,
        limit=8,
        pc_base=0x8000_0000,
        stop_instrs={0x0000_9002},
    )

    assert rows == [
        {"idx": 0, "pc": 0x0, "instr": 0x0000_4137, "rd": 2, "wdata": 0x4000},
        {"idx": 1, "pc": 0x4, "instr": 0x4405, "rd": 8, "wdata": 0x1},
    ]


def test_phase_03_03_spike_log_parser_keeps_clui_constants_and_normalizes_auipc(tmp_path):
    log = tmp_path / "spike.log"
    log.write_text(
        "\n".join(
            [
                "core   0: 3 0x000010d2 (0x6db5) x27 0x0000d000",
                "core   0: 3 0x000011d6 (0x01fddc97) x25 0x01fde1d6",
            ]
        ),
        encoding="utf-8",
    )

    rows = parse_spike_commits(log, limit=8, pc_base=0x1000)

    assert rows == [
        {"idx": 0, "pc": 0xD2, "instr": 0x6DB5, "rd": 27, "wdata": 0xD000},
        {"idx": 1, "pc": 0x1D6, "instr": 0x01FDDC97, "rd": 25, "wdata": 0x01FDD1D6},
    ]


def test_phase_03_03_compare_reports_first_mismatch():
    dut = [{"idx": 0, "pc": 0, "instr": 0x13, "rd": 1, "wdata": 1}]
    spike = [{"idx": 0, "pc": 0, "instr": 0x13, "rd": 1, "wdata": 2}]

    ok, message = compare_commits(dut, spike, label="unit")
    assert not ok
    assert "unit first mismatch at idx=0: wdata" in message
    assert "dut=00000001" in message
    assert "spike=00000002" in message


def test_phase_03_03_commit_csv_writer_round_trips(tmp_path):
    path = tmp_path / "commit.trace"
    rows = [{"idx": 0, "pc": 0x2A, "instr": 0xA899, "rd": 0, "wdata": 0}]

    write_commit_csv(path, rows)

    assert path.read_text(encoding="utf-8") == (
        "idx,pc,instr,rd,wdata\n"
        "0,0000002a,0000a899,0,00000000\n"
    )
