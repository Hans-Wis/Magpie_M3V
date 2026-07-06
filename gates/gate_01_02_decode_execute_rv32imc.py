"""gate_01_02_decode_execute_rv32imc - lab08e decode/execute phase gate.

Phase 1.2 productizes the RV32IMC decode/execute slice enough to make later
directed simulation meaningful. This is a structural + lint gate: it does not
claim directed ISA closure, coverage closure, or Spike equivalence.

M1-legacy cleanup: the idu/mul/div/core source-string grep tests were removed —
the M3V parameterized core (ADR-0032) evolved those exact strings, and the
behaviour is re-verified by Spike lockstep in sim/gates/gate_03_*/04_*. The
stable def.vh / alu / rfu structural checks and the Verilator lint remain.
"""

import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RTL_DIR = ROOT / "design/cpu_m1/rtl"
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
