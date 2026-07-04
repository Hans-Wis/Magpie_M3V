"""gate_02_00_trap_interrupt - lab08e CSR/trap/IRQ structural gate.

Phase 2.0 productizes the M-mode CSR, MRET, and external-interrupt control
slice for the active lab08e pipeline. It includes structural + lint checks and
a directed Verilator simulation for IRQ entry on a 16-bit instruction. It does
not claim complete CSR coverage, Spike equivalence, or line/toggle coverage.
"""

import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RTL_DIR = ROOT / "IP/cpu_m1/rtl"
PHASE_DIR = ROOT / "flow/v2_pipeline/phase_02_00_trap_interrupt"

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


def _read_head(path: Path, size: int = 4096) -> str:
    with path.open("rb") as fh:
        return fh.read(size).decode("utf-8", errors="replace")


def test_phase_02_00_evidence_directory_exists():
    assert PHASE_DIR.is_dir()
    assert (PHASE_DIR / "README.md").is_file()


def test_defines_cover_m_mode_csr_trap_and_mret_contract():
    text = _read(RTL_DIR / "def.vh")
    for required in [
        "`define CSR_MSTATUS  12'h300",
        "`define CSR_MIE      12'h304",
        "`define CSR_MTVEC    12'h305",
        "`define CSR_MSCRATCH 12'h340",
        "`define CSR_MEPC     12'h341",
        "`define CSR_MCAUSE   12'h342",
        "`define CSR_MIP      12'h344",
        "`define CSR_CYCLE    12'hC00",
        "`define CSR_CYCLEH   12'hC80",
        "`define CSR_INSTRET  12'hC02",
        "`define CSR_INSTRETH 12'hC82",
        "`define CSR_OP_W     2'b01",
        "`define CSR_OP_S     2'b10",
        "`define CSR_OP_C     2'b11",
        "`define MCAUSE_EXT_IRQ 32'h8000_000B",
        "`define MCAUSE_TIMER_IRQ 32'h8000_0007",
        "`define MCAUSE_MSW_IRQ   32'h8000_0003",
        "`define MSTATUS_MIE_BIT  3",
        "`define MSTATUS_MPIE_BIT 7",
        "`define MIE_MEIE_BIT 11",
        "`define MIE_MTIE_BIT 7",
        "`define MIE_MSIE_BIT 3",
        "`define MIP_MEIP_BIT 11",
        "`define MIP_MTIP_BIT 7",
        "`define MIP_MSIP_BIT 3",
        "`define INSTR_MRET   32'h3020_0073",
    ]:
        assert required in text


def test_idu_decodes_csr_ops_and_mret_as_legal_system_instructions():
    text = _read(RTL_DIR / "idu.v")
    for required in [
        "assign is_csr  = is_system && (funct3 != 3'b000);",
        "assign is_mret = (instr == `INSTR_MRET);",
        "assign csr_op       = funct3[1:0];",
        "assign csr_uses_imm = funct3[2];",
        "assign csr_addr     = instr[31:20];",
        "assign csr_zimm     = {27'b0, instr[19:15]};",
        "is_csr         : wb_sel = `WB_SEL_CSR;",
        "| is_jalr | is_csr | is_mret | is_vset | is_vexec | is_fexec_w;",
        "assign illegal = !known_opcode | bmu_slot_illegal;",
    ]:
        assert required in text


def test_csr_file_registers_read_mux_write_ops_and_direct_mtvec_mode():
    text = _read(RTL_DIR / "csr.v")
    for required in [
        "reg        mie_meie;",
        "reg        mstatus_mie;",
        "reg        mstatus_mpie;",
        "reg [31:2] mtvec_base;",
        "reg [31:0] mscratch;",
        "reg [31:0] mepc_reg;",
        "reg [31:0] mcause_reg;",
        "reg        ext_pending;",
        "reg        mie_mtie;",
        "reg        mie_msie;",
        "reg [63:0] cycle_cnt;",
        "reg [63:0] instret_cnt;",
            "localparam [1:0] mstatus_mpp = 2'b11;",  # ADR-0015: M-only MPP read-only WARL=M
            "reg [31:0] mtval_reg;",
            # ADR-0036 3A: mstatus grew SD + VS (EN_RVV-visible fields; zero when EN_RVV=0)
            "wire [31:0] mstatus_val = {mstatus_sd, 16'b0, mstatus_fs_visible, mstatus_mpp,",  # ADR-0050: +FS,
        "wire [31:0] mie_val     = {20'b0, mie_meie, 3'b0, mie_mtie, 3'b0, mie_msie, 3'b0};",
        "wire [31:0] mip_val     = {20'b0, (ext_pending | meip), 3'b0, mtip, 3'b0, msip, 3'b0};",
        "wire [31:0] mtvec_val   = {mtvec_base, 2'b00};",
        "`CSR_MSTATUS : csr_rdata = mstatus_val;",
        "`CSR_MIE     : csr_rdata = mie_val;",
        "`CSR_MTVEC   : csr_rdata = mtvec_val;",
        "`CSR_MEPC    : csr_rdata = mepc_reg;",
            "`CSR_MCAUSE  : csr_rdata = mcause_reg;",
            "`CSR_MTVAL   : csr_rdata = mtval_val;",
        "`CSR_MIP     : csr_rdata = mip_val;",
        "default      : csr_rdata = 32'h0;",
        "`CSR_OP_W : new_val = csr_wdata;",
        "`CSR_OP_S : new_val = csr_old_val | csr_wdata;",
        "`CSR_OP_C : new_val = csr_old_val & ~csr_wdata;",
        "`CSR_MTVEC   : mtvec_base  <= new_val[31:2];",
        "mie_mtie <= new_val[`MIE_MTIE_BIT];",
        "mie_msie <= new_val[`MIE_MSIE_BIT];",
    ]:
        assert required in text


def test_csr_file_trap_entry_exit_pending_and_counter_behavior():
    text = _read(RTL_DIR / "csr.v")
    for required in [
        "cycle_cnt <= cycle_cnt + 1'b1;",
        "if (instr_retired)",
        "instret_cnt <= instret_cnt + 1'b1;",
        "if (trap_enter) begin",
        "mepc_reg     <= trap_pc;",
        "mcause_reg   <= trap_cause;",
        "mstatus_mpie <= mstatus_mie;",
        "mstatus_mie  <= 1'b0;",
        "end else if (trap_exit) begin",
        "mstatus_mie  <= mstatus_mpie;",
        "mstatus_mpie <= 1'b1;",
        "ext_pending <=\n                trap_enter         ? 1'b0 :\n                irq_external_pulse ? 1'b1 :\n                                     ext_pending;",
        "assign mtvec_o     = mtvec_val;",
        "assign mepc_o      = mepc_reg;",
        "wire irq_mei = (ext_pending | meip) & mie_meie;",
        "wire irq_msi = msip        & mie_msie;",
        "wire irq_mti = mtip        & mie_mtie;",
        "assign irq_pending = (irq_mei | irq_msi | irq_mti) & mstatus_mie;",
        "assign irq_cause   = irq_mei ? `MCAUSE_EXT_IRQ   :",
        "irq_msi ? `MCAUSE_MSW_IRQ   :",
        "`MCAUSE_TIMER_IRQ;",
    ]:
        assert required in text


def test_core_integrates_csr_at_pipeline_commit_boundary():
    text = _read(RTL_DIR / "core.v")
    for required in [
        "wire [31:0] id_csr_wdata = id_csr_uses_imm ? id_csr_zimm : rs1_val;",
        "wire        id_csr_we_logic = id_is_csr &&",
        "((id_csr_op == `CSR_OP_W) || (id_csr_wdata != 32'h0));",
        ".csr_raddr          (id_csr_addr)",
        ".csr_we             (wb_csr_we)",
        ".csr_waddr          (ex_wb_csr_addr_r)",
        ".csr_op             (ex_wb_csr_op_r)",
        ".csr_wdata          (ex_wb_csr_wdata_r)",
        ".csr_old_val        (ex_wb_csr_rdata_r)",
        ".instr_retired      (wb_instr_retired)",
        ".trap_enter         (wb_trap_enter)",
        ".trap_pc            (wb_trap_pc_for_mepc)",
        ".trap_exit          (wb_trap_exit)",
        ".irq_external_pulse (irq_external_pulse)",
        "ex_mem_csr_rdata_r       <= id_csr_rdata;",
        "ex_mem_csr_we_r          <= id_csr_we_logic;",
        "ex_wb_csr_rdata_r       <= ex_mem_csr_rdata_r;",
        "ex_wb_csr_we_r          <= ex_mem_csr_we_r;",
        "assign wb_csr_we      = ex_wb_csr_we_r && ex_wb_valid_r && !wb_take_irq &&",
        "!wb_take_trigger && !ex_wb_illegal_r && !mem_stall;",
        "`WB_SEL_CSR  : wb_data_mux = ex_wb_csr_rdata_r;",
    ]:
        assert required in text


def test_core_irq_mret_redirect_priority_and_side_effect_suppression():
    text = _read(RTL_DIR / "core.v")
    for required in [
        "assign wb_take_irq = ex_wb_valid_r && irq_pending && !ex_wb_illegal_r &&",
        "!wb_take_data_trap && !wb_trigger_pending && !mem_stall;",
        "wire wb_redirect = wb_take_irq || wb_take_data_trap || wb_take_sync_trap || wb_take_trigger ||",
        "wire ex_mem_advance_to_wb = ex_mem_valid_r && !wb_redirect;",
        "assign rfu_we      = ex_wb_valid_r && ex_wb_rd_we_r && !ex_wb_illegal_r &&",
        "!wb_take_irq && !wb_take_data_trap && !wb_take_trigger && !mem_stall;",
        "end else if (wb_take_irq || wb_take_data_trap || wb_take_sync_trap) begin",
        "redirect_target = mtvec_o;",
        "end else if (ex_wb_valid_r && ex_wb_is_mret_r) begin",
        "redirect_target = mepc_o;",
        "assign wb_trap_enter        = (wb_take_irq || wb_take_data_trap || wb_take_sync_trap) && !mem_stall;",
        "assign wb_trap_exit          = ex_wb_valid_r && ex_wb_is_mret_r && !mem_stall;",
        "assign wb_instr_retired = ex_wb_valid_r && !wb_take_irq && !wb_take_data_trap &&",
        "!wb_take_sync_trap && !wb_take_trigger && !mem_stall;",
    ]:
        assert required in text


def test_core_saves_interrupt_mepc_with_16_bit_aware_next_pc():
    text = _read(RTL_DIR / "core.v")
    for required in [
        "reg        if_ex_is_16bit;  // instruction size flag for correct mepc / link-addr",
        "if_ex_is_16bit        <= is_16bit_w;",
        "wire [31:0] if_ex_pc_plus_4   = if_ex_pc + (if_ex_is_16bit ? 32'd2 : 32'd4);",
        "ex_mem_pc_plus_4_r       <= if_ex_pc_plus_4;",
        "ex_wb_pc_plus_4_r       <= ex_mem_pc_plus_4_r;",
        "wire [31:0] wb_sync_exception_pc = ex_wb_pc_r;",
        "assign wb_trap_pc_for_mepc = (wb_take_sync_trap || wb_take_data_trap) ? wb_sync_exception_pc :",
        "ex_wb_is_jal_r          ? ex_wb_pc_plus_imm_r :",
        "ex_wb_is_jalr_r         ? (ex_wb_alu_result_r & ~32'd1) :",
        "ex_wb_pc_plus_4_r;",
    ]:
        assert required in text


def test_core_illegal_system_instructions_latch_trap_without_irq_entry():
    text = _read(RTL_DIR / "core.v")
    for required in [
        # ADR-0036 3A: illegal now includes the EN_RVV VS/vector-CSR terms (== id_illegal when EN_RVV=0)
        "ex_mem_illegal_r         <= id_illegal_eff;",
        "ex_wb_illegal_r         <= ex_mem_illegal_r;",
        "assign wb_take_irq = ex_wb_valid_r && irq_pending && !ex_wb_illegal_r &&",
        "!wb_take_data_trap && !wb_trigger_pending && !mem_stall;",
        "else if (wb_take_sync_trap && !mem_stall) trap_latched <= 1'b1;",
        "assign trap = trap_latched;",
    ]:
        assert required in text


def test_phase_02_00_verilator_lint_only():
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


def test_phase_02_00_directed_sim_artifacts_are_present_and_passing():
    required_paths = [
        PHASE_DIR / "Makefile",
        PHASE_DIR / "tb_trap_irq.v",
        PHASE_DIR / "firmware.S",
        PHASE_DIR / "firmware.lds",
        PHASE_DIR / "firmware.hex",
        PHASE_DIR / "firmware.disasm",
        PHASE_DIR / "sim.log",
        PHASE_DIR / "wave.vcd",
        PHASE_DIR / "vcd_manifest.md",
    ]
    for path in required_paths:
        assert path.exists(), f"missing phase 2.0 artifact: {path}"
        assert path.stat().st_size > 0, f"empty phase 2.0 artifact: {path}"

    log = _read(PHASE_DIR / "sim.log")
    for required in [
        "inject IRQ on 16-bit target pc=00000080 instr=00140413",
        "irq entry trap_pc=00000082 mtvec=00000100",
        "handler stored mepc=00000082",
        "handler stored mcause=8000000b",
        "mret resume marker=0000600d",
        "PASS: directed IRQ on 16-bit instruction saved mepc=00000082 mcause=8000000b and mret resumed",
    ]:
        assert required in log


def test_phase_02_00_firmware_places_16bit_irq_target_and_handler_at_fixed_addresses():
    disasm = _read(PHASE_DIR / "firmware.disasm")
    for required in [
        "00000080 <irq_target>:",
        "  80:\t0405                \taddi\ts0,s0,1",
        "00000082 <after_irq>:",
        "  82:\t4489                \tli\ts1,2",
        "00000100 <mtvec_handler>:",
        "csrr\tt1,mepc",
        "csrr\tt1,mcause",
        "30200073          \tmret",
    ]:
        assert required in disasm


def test_phase_02_00_vcd_manifest_records_review_intent_and_escape_hatch():
    manifest = _read(PHASE_DIR / "vcd_manifest.md")
    for required in [
        "Review Questions",
        "PC=0x80",
        "mepc=0x82",
        "mcause=0x8000000b",
        "Required Signals",
        "Dump Windows",
        "Trace Settings",
        "TRACE_DEPTH=2",
        "TRACE_DEPTH=5 RUN_ARGS=+full_vcd",
        "Known Blind Spots",
    ]:
        assert required in manifest


def test_phase_02_00_vcd_header_exposes_directed_irq_debug_signals():
    vcd_head = _read_head(PHASE_DIR / "wave.vcd")
    for required in [
        "$scope module tb_trap_irq",
        "irq_external_pulse",
        "injected_irq",
        "saw_irq_entry",
        "stored_mepc",
        "stored_mcause",
        "dbg_pc",
        "dbg_instr",
        "d_mem_addr",
        "d_mem_wdata",
    ]:
        assert required in vcd_head


def test_phase_02_00_vcd_size_is_short_directed_review_not_full_hierarchy():
    wave_vcd = PHASE_DIR / "wave.vcd"
    size_mb = wave_vcd.stat().st_size / (1024 * 1024)
    assert size_mb < 20, f"default Phase 2.0 VCD too large: {size_mb:.1f} MB"
    assert size_mb > 0.01, f"default Phase 2.0 VCD unexpectedly tiny: {size_mb:.3f} MB"
