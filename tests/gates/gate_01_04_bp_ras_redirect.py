"""gate_01_04_bp_ras_redirect - lab08e BP/RAS/redirect structural gate.

Phase 1.4 productizes branch prediction, return-address prediction, and redirect
recovery contracts for the active lab08e pipeline. This is a structural + lint
gate; directed predictor simulation, VCD review, coverage, and Spike lockstep
remain separate future evidence.
"""

import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
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


def test_core_predicts_returns_and_updates_ras_on_call_link():
    text = _read(RTL_DIR / "core.v")
    for required in [
        "wire if_is_ret_32",
        "(instr_assembled[6:0]  == 7'b1100111)",
        "(instr_assembled[11:7]  == 5'b00000)",
        "(instr_assembled[19:15] == 5'b00001)",
        "wire if_is_ret_16  = is_16bit_w && (cinstr == 16'h8082);",
        "wire        ras_valid      = (ras_top != 32'h0);",
        "wire        ras_predict_ret = if_is_ret && ras_valid && !any_stall && !pc_redirect;",
        "assign ras_pop = ras_predict_ret;",
        "assign ras_push     = if_ex_valid && id_is_jal && (id_rd_idx == 5'd1)",
        "assign ras_push_val = if_ex_pc_plus_4;",
        ".ras_predict_ret    (ras_predict_ret)",
        ".ras_predict_target (ras_top)",
    ]:
        assert required in text


def test_core_bp_update_is_latched_and_excludes_jalr():
    text = _read(RTL_DIR / "core.v")
    for required in [
        "wire ex_actual_taken = if_ex_valid && (branch_taken | id_is_jal | id_is_jalr);",
        "reg [31:0] if_ex_pred_target;",
        "if_ex_pred_target     <= ras_predict_ret ? ras_top : bp_predict_target;",
        "wire [31:0] ex_actual_target = id_is_jalr ? (alu_result & ~32'd1) : if_ex_pc_plus_imm;",
        "wire ex_target_mispredict = if_ex_valid && if_ex_pred_taken && ex_actual_taken",
        "|| ex_target_mispredict",
        "wire        ex_bp_upd_valid  = if_ex_valid && (id_is_branch | id_is_jal)",
        "&& !stall && !pc_redirect;",
        "wire [31:0] ex_bp_upd_pc     = if_ex_pc;",
        "wire        ex_bp_upd_taken  = ex_actual_taken;",
        "wire [31:0] ex_bp_upd_target = if_ex_pc_plus_imm;",
        "ex_mem_bp_upd_valid_r    <= ex_bp_upd_valid;",
        "ex_mem_bp_upd_pc_r       <= ex_bp_upd_pc;",
        "ex_mem_bp_upd_taken_r    <= ex_bp_upd_taken;",
        "ex_mem_bp_upd_target_r   <= ex_bp_upd_target;",
        "assign bp_upd_valid  = ex_mem_bp_upd_valid_r && !mem_stall && !ex_mem_trigger_hit_r;",
        "assign bp_upd_pc     = ex_mem_bp_upd_pc_r;",
        "assign bp_upd_taken  = ex_mem_bp_upd_taken_r;",
        "assign bp_upd_target = ex_mem_bp_upd_target_r;",
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


def test_core_flushes_prefetch_and_pipeline_on_redirect():
    text = _read(RTL_DIR / "core.v")
    for required in [
        "if (!resetn || pc_redirect) begin",
        "cross_assemble <= 1'b0;",
        "residue        <= 16'h0;",
        "assign flush_if_next = pc_redirect;",
        "reg         redirect_warmup;",
        "else if (flush_if_next || warmup || redirect_warmup) begin",
        "Redirect must beat ordinary lu/md/fetch stalls",
        "extra redirect_warmup cycle lets sync i_mem_rdata catch up",
        "if_ex_valid      <= 1'b0;",
        "wire id_advance_to_ex_mem = !any_stall && if_ex_valid && !warmup && !pc_redirect;",
    ]:
        assert required in text


def test_phase_01_04_verilator_lint_only():
    verilator = shutil.which("verilator") or "/home/edauser/miniforge3/envs/magpie_claude/bin/verilator"
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
