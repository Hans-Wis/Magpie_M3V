"""gate_01_04_bp_ras_redirect - lab08e BP/RAS/redirect structural gate.

Phase 1.4 productizes branch prediction, return-address prediction, and redirect
recovery contracts for the active lab08e pipeline. This is a structural + lint
gate; directed predictor simulation, VCD review, coverage, and Spike lockstep
remain separate future evidence.

M1-legacy cleanup: the three core.v source-string grep tests (RAS predict/push,
BP-update latch, prefetch flush) were removed — the M3V parameterized core
(ADR-0032) evolved those strings; the behaviour is re-verified by Spike lockstep
in sim/gates/gate_03_*. The bp.v / ras.v structural checks and the lint remain.
"""

import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RTL_DIR = ROOT / "IP/cpu_m1/rtl"
PHASE_DIR = ROOT / "flow/v2_pipeline/phase_01_04_bp_ras_redirect"

RTL_FILES = [
    "rfu.v",
    "alu.v",
    "idu.v",
    "ifu.v",
    "lsu.v",
    "csr.v",
    "trigger.v",
    "mul.v",
    "div.v",
    "forward.v",
    "hazard.v",
    "bp.v",
    "ras.v",
    "cdec.v",
    "core.v",
]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_phase_01_04_evidence_directory_exists():
    assert PHASE_DIR.is_dir()


def test_bp_structure_is_two_way_set_associative_with_saturating_counters():
    text = _read(RTL_DIR / "bp.v")
    for required in [
        "localparam IDX_BITS = 5;",
        "localparam IDX_LSB  = 1;",
        "localparam TAG_LSB  = IDX_LSB + IDX_BITS;",
        "reg                 valid0",
        "reg [TAG_BITS-1:0]  tag0",
        "reg [31:0]          target0",
        "reg [1:0]           counter0",
        "reg                 valid1",
        "reg [TAG_BITS-1:0]  tag1",
        "reg [31:0]          target1",
        "reg [1:0]           counter1",
        "reg                 lru",
        "assign bp_predict_taken  = predict_from_way0 | predict_from_way1;",
        "assign bp_predict_target = rd_hit1 ? target1[rd_idx] : target0[rd_idx];",
        "wire [1:0] cnt_inc = (cur_cnt == 2'b11) ? 2'b11 : cur_cnt + 2'd1;",
        "wire [1:0] cnt_dec = (cur_cnt == 2'b00) ? 2'b00 : cur_cnt - 2'd1;",
        "wire [1:0] cnt_next",
        "wire lru_next = ~wr_way;",
    ]:
        assert required in text


def test_ras_structure_supports_top_push_pop_and_same_cycle_replace():
    text = _read(RTL_DIR / "ras.v")
    for required in [
        "localparam DEPTH = 8;",
        "reg [31:0]         stack [0:DEPTH-1];",
        "reg [PTR_BITS-1:0] ptr;",
        "assign ras_top = (ptr == 0) ? 32'h0 : stack[top_idx];",
        "if (push && pop) begin",
        "stack[top_idx] <= push_val;",
        "end else if (push) begin",
        "stack[ptr] <= push_val;",
        "ptr <= ptr + 3'd1;",
        "end else if (pop) begin",
        "if (ptr != 0) ptr <= ptr - 3'd1;",
    ]:
        assert required in text


def test_core_redirect_priority_covers_irq_mret_ras_and_bp_recovery():
    text = _read(RTL_DIR / "core.v")
    for required in [
            "end else if (wb_take_irq || wb_take_data_trap || wb_take_sync_trap) begin",
        "redirect_target = mtvec_o;",
        "end else if (ex_wb_valid_r && ex_wb_is_mret_r) begin",
        "redirect_target = mepc_o;",
        "end else if (mem_ras_mispredict) begin",
        "redirect_target = mem_ras_actual_target;",
        "end else if (ex_mem_valid_r && ex_mem_mispredict_r && !ex_mem_trigger_hit_r) begin",
        "ex_mem_is_jalr_r          ? (ex_mem_alu_result_r & ~32'd1)",
        "ex_mem_is_branch_taken_r  ? ex_mem_pc_plus_imm_r",
        "ex_mem_is_jal_r           ? ex_mem_pc_plus_imm_r",
        "ex_mem_pc_plus_4_r",
    ]:
        assert required in text


def test_phase_01_04_verilator_lint_only():
    verilator = shutil.which("verilator") or "verilator"
    assert Path(verilator).exists(), f"verilator not found: {verilator}"
    cmd = [
        verilator,
        "--lint-only",
        "-Wall",
        "-Wno-DECLFILENAME",
        "-Wno-TIMESCALEMOD",
        "-Wno-UNUSEDSIGNAL",
        f"-I{RTL_DIR}",
        *[str(RTL_DIR / name) for name in RTL_FILES],
        "--top-module",
        "core",
    ]
    subprocess.run(cmd, cwd=ROOT, check=True)
