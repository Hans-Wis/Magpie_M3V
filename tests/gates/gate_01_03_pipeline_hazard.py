"""gate_01_03_pipeline_hazard - lab08e pipeline hazard structural gate.

Phase 1.3 productizes the hazard-control slice for the active lab08e pipeline.
This is a structural + lint gate. It does not claim directed hazard simulation,
assertion closure, coverage closure, or Spike equivalence.
"""

import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RTL_DIR = ROOT / "IP/cpu_m1/rtl"
PHASE_DIR = ROOT / "flow/v2_pipeline/phase_01_03_pipeline_hazard"

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


def test_phase_01_03_evidence_directory_exists():
    assert PHASE_DIR.is_dir()


def test_forwarding_priority_and_load_exclusion_are_encoded():
    text = _read(RTL_DIR / "forward.v")
    for required in [
        "EX/MEM > EX/WB > RFU",
        "wire em_fwd_ok  = em_valid && em_rd_we && !em_is_load && (em_rd_idx != 5'd0);",
        "wire em_fwd_rs1 = em_fwd_ok && (id_rs1_idx == em_rd_idx);",
        "wire em_fwd_rs2 = em_fwd_ok && (id_rs2_idx == em_rd_idx);",
        "wire wb_fwd_ok  = wb_valid && wb_rd_we && (wb_rd_idx != 5'd0);",
        "wire wb_fwd_rs1 = wb_fwd_ok && !em_fwd_rs1 && (id_rs1_idx == wb_rd_idx);",
        "wire wb_fwd_rs2 = wb_fwd_ok && !em_fwd_rs2 && (id_rs2_idx == wb_rd_idx);",
        "assign rs1_val = em_fwd_rs1 ? em_fwd_val :",
        "wb_fwd_rs1 ? wb_data",
        "assign rs2_val = em_fwd_rs2 ? em_fwd_val :",
        "wb_fwd_rs2 ? wb_data",
    ]:
        assert required in text


def test_hazard_detects_load_use_and_muldiv_busy_stalls():
    text = _read(RTL_DIR / "hazard.v")
    for required in [
        "wire load_use_match_em = (id_rs1_idx == em_rd_idx) || (id_rs2_idx == em_rd_idx);",
        "wire load_use_stall = id_valid && em_valid && em_is_load && em_rd_we &&",
        "(em_rd_idx != 5'd0) && load_use_match_em;",
        "wire muldiv_stall = id_valid && id_is_muldiv && md_busy;",
        # ADR-0036 3B: + vex_stall (RVV RAW; tied 0 in host EN_RVV=0 config)
        "assign stall = load_use_stall | muldiv_stall | vex_stall;",
    ]:
        assert required in text


def test_core_combines_fetch_loaduse_muldiv_and_warmup_stalls():
    text = _read(RTL_DIR / "core.v")
    for required in [
        "wire        stall;         // load-use / muldiv stall (existing)",
        "wire        fetch_stall = at_cross_boundary;",
        "wire        any_stall   = stall | fetch_stall | warmup | redirect_warmup | mem_stall;",
        "assign i_mem_en   = (pc_redirect || redirect_warmup || !stall || at_cross_boundary) && !mem_stall;",
        "wire id_advance_to_ex_mem = !any_stall && if_ex_valid && !warmup && !pc_redirect;",
        ".stall        (stall)",
    ]:
        assert required in text


def test_core_holds_or_bubbles_pipeline_registers_on_stall_flush_and_redirect():
    text = _read(RTL_DIR / "core.v")
    for required in [
        "else if (flush_if_next || warmup || redirect_warmup) begin",
        "Redirect must beat ordinary lu/md/fetch stalls",
        "extra redirect_warmup cycle lets sync i_mem_rdata catch up",
        "end else if (any_stall) begin",
        "assign flush_if_next = pc_redirect;",
        "end else if (id_advance_to_ex_mem) begin",
        "end else begin\n            // Stall / wrong-path / warmup: 插 bubble",
        "wire ex_mem_advance_to_wb = ex_mem_valid_r && !wb_redirect;",
        "end else begin\n            // Stall / wrong-path: 插 bubble",
    ]:
        assert required in text


def test_core_suppresses_wrong_path_side_effects_on_redirect_or_irq():
    text = _read(RTL_DIR / "core.v")
    for required in [
        "wire id_mem_active = (id_is_load || id_is_store) && if_ex_valid && !stall &&",
        "!pc_redirect && !warmup;",
        "assign d_mem_valid = ex_mem_valid_r && (ex_mem_is_load_r || ex_mem_is_store_r) &&",
        "!pc_redirect;",
        "ex_mem_is_store_r && ex_mem_valid_r && !pc_redirect ?",
            "assign wb_csr_we      = ex_wb_csr_we_r && ex_wb_valid_r && !wb_take_irq &&",
        "!wb_take_trigger && !ex_wb_illegal_r && !mem_stall;",
        "assign rfu_we      = ex_wb_valid_r && ex_wb_rd_we_r && !ex_wb_illegal_r &&",
        "!wb_take_irq && !wb_take_data_trap && !wb_take_trigger && !mem_stall;",
    ]:
        assert required in text


def test_core_redirect_priority_and_recovery_targets_are_encoded():
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


def test_phase_01_03_verilator_lint_only():
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
