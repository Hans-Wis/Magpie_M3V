"""gate_01_02_decode_execute_rv32imc - lab08e decode/execute phase gate.

Phase 1.2 productizes the RV32IMC decode/execute slice enough to make later
directed simulation meaningful. This is a structural + lint gate: it does not
claim directed ISA closure, coverage closure, or Spike equivalence.
"""

import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RTL_DIR = ROOT / "IP/cpu_m1/rtl"
PHASE_DIR = ROOT / "flow/v2_pipeline/phase_01_02_decode_execute_rv32imc"

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


def test_phase_01_02_evidence_directory_exists():
    assert PHASE_DIR.is_dir()


def test_defines_cover_rv32imc_decode_execute_constants():
    text = _read(RTL_DIR / "def.vh")
    for required in [
        "`define OPC_LUI",
        "`define OPC_AUIPC",
        "`define OPC_JAL",
        "`define OPC_JALR",
        "`define OPC_BRANCH",
        "`define OPC_LOAD",
        "`define OPC_STORE",
        "`define OPC_OP_IMM",
        "`define OPC_OP",
        "`define OPC_SYSTEM",
        "`define OPC_FENCE",
        "`define F3_ADD_SUB",
        "`define F3_SLL",
        "`define F3_SLT",
        "`define F3_SLTU",
        "`define F3_XOR",
        "`define F3_SRL_SRA",
        "`define F3_OR",
        "`define F3_AND",
        "`define F7_MULDIV",
        "`define MD_MUL",
        "`define MD_MULH",
        "`define MD_MULHSU",
        "`define MD_MULHU",
        "`define MD_DIV",
        "`define MD_DIVU",
        "`define MD_REM",
        "`define MD_REMU",
        "`define WB_SEL_MD",
    ]:
        assert required in text


def test_idu_decodes_rv32i_immediates_alu_branch_mem_csr_and_m_extension():
    text = _read(RTL_DIR / "idu.v")
    for required in [
        "wire [31:0] imm_i",
        "wire [31:0] imm_s",
        "wire [31:0] imm_b",
        "wire [31:0] imm_u",
        "wire [31:0] imm_j",
        "is_lui, is_auipc",
        "is_jal",
        "is_jalr, is_load, is_op_imm",
        "is_store",
        "is_branch",
        "assign is_muldiv = is_op && (funct7 == `F7_MULDIV);",
        "assign md_op     = funct3;",
        "assign md_is_div = funct3[2];",
        "`F3_ADD_SUB : alu_op = is_sub_or_sra ? `ALU_SUB : `ALU_ADD;",
        "`F3_SLT     : alu_op = `ALU_SLT;",
        "`F3_SLTU    : alu_op = `ALU_SLTU;",
        "`F3_XOR     : alu_op = `ALU_XOR;",
        "`F3_OR      : alu_op = `ALU_OR;",
        "`F3_AND     : alu_op = `ALU_AND;",
        "`F3_SLL     : alu_op = `ALU_SLL;",
        "`F3_SRL_SRA : alu_op = is_sub_or_sra ? `ALU_SRA : `ALU_SRL;",
        "is_csr         : wb_sel = `WB_SEL_CSR;",
        "is_muldiv      : wb_sel = `WB_SEL_MD;",
        "assign illegal = !known_opcode;",
    ]:
        assert required in text


def test_alu_implements_all_rv32i_execute_ops_and_fast_branch_comparators():
    text = _read(RTL_DIR / "alu.v")
    for required in [
        "assign cmp_eq   = eq;",
        "assign cmp_lt_s = lt_s;",
        "assign cmp_lt_u = lt_u;",
        "`ALU_ADD    : result = sum;",
        "`ALU_SUB    : result = diff;",
        "`ALU_AND    : result = op_a & op_b;",
        "`ALU_OR     : result = op_a | op_b;",
        "`ALU_XOR    : result = op_a ^ op_b;",
        "`ALU_SLL    : result = sll_o;",
        "`ALU_SRL    : result = srl_o;",
        "`ALU_SRA    : result = sra_o;",
        "`ALU_SLT    : result = {31'b0, lt_s};",
        "`ALU_SLTU   : result = {31'b0, lt_u};",
        "`ALU_SEQ    : result = {31'b0, eq};",
        "`ALU_COPY_B : result = op_b;",
    ]:
        assert required in text


def test_rfu_preserves_x0_invariant_and_two_read_one_write_contract():
    text = _read(RTL_DIR / "rfu.v")
    for required in [
        "reg [31:0] regs [0:31];",
        "assign rs1_data = (rs1_idx == 5'd0) ? 32'h0 : regs[rs1_idx];",
        "assign rs2_data = (rs2_idx == 5'd0) ? 32'h0 : regs[rs2_idx];",
        "if (we && rd_idx != 5'd0)",
        "regs[rd_idx] <= rd_data;",
    ]:
        assert required in text


def test_mul_div_units_cover_rv32m_signed_unsigned_and_spec_corners():
    mul = _read(RTL_DIR / "mul.v")
    for required in [
        "wire opa_unsigned = (md_op == `MD_MULHU);",
        "wire opb_unsigned = (md_op == `MD_MULHU) || (md_op == `MD_MULHSU);",
        "wire signed [32:0] opa_ext",
        "wire signed [32:0] opb_ext",
        "high_out <= (md_op != `MD_MUL);",
        "reg                done_pending;",
        "wire signed [65:0] product_w = opa_r * opb_r;",
        "result       <= high_out ? product_w[63:32] : product_w[31:0];",
        "done_pending <= 1'b1;",
    ]:
        assert required in mul

    div = _read(RTL_DIR / "div.v")
    for required in [
        "localparam IDLE",
        "localparam WORK",
        "localparam FIXUP",
        "localparam DONE",
        "div_by_zero <= (op_b == 32'h0);",
        "overflow    <= ((md_op == `MD_DIV) || (md_op == `MD_REM))",
        "result <= ret_rem ? orig_a : `DIV_BY_ZERO_QUOT;",
        "result <= ret_rem ? 32'h0 : `DIV_OVERFLOW_QUOT;",
        "result <= sign_rem ? -remainder : remainder;",
        "result <= sign_quot ? -quotient : quotient;",
        "state <= DONE;",
        "DONE: begin",
    ]:
        assert required in div


def test_core_integrates_decode_execute_writeback_and_muldiv_stall_paths():
    text = _read(RTL_DIR / "core.v")
    for required in [
        "idu u_idu",
        "rfu u_rfu",
        "alu u_alu",
        "mul u_mul",
        "div u_div",
        "forward u_forward",
        "hazard u_hazard",
        "reg         md_active_is_div;",
        "reg         md_result_valid;",
        "reg  [31:0] md_result_q;",
        "wire md_start = if_ex_valid && id_is_muldiv && !md_started && !md_result_valid &&",
        "!pc_redirect && !warmup && !redirect_warmup;",
        "wire        md_busy = if_ex_valid && id_is_muldiv && !md_result_valid;",
        "wire [31:0] md_result = md_result_q;",
        "md_result_q     <= md_active_is_div ? div_result : mul_result;",
        ".id_is_muldiv (id_is_muldiv)",
        ".md_busy      (md_busy)",
        "ex_mem_md_result_r       <= md_result;",
        "ex_wb_md_result_r       <= ex_mem_md_result_r;",
        "`WB_SEL_MD   : wb_data_mux = ex_wb_md_result_r;",
        "assign rfu_we      = ex_wb_valid_r && ex_wb_rd_we_r && !ex_wb_illegal_r &&",
        "!wb_take_irq && !wb_take_data_trap && !wb_take_trigger && !mem_stall;",
    ]:
        assert required in text


def test_phase_01_02_verilator_lint_only():
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
