"""gate_01_01_fetch_rv32c_prefetch - lab08e fetch/RV32C/pre-fetch phase gate.

Phase 1.1 starts productizing the lab08e IF path. It checks the active RTL has
the RV32C fetch/decode and pre-fetch residue mechanisms needed before broader
directed simulation and Spike lockstep are meaningful.
"""

import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RTL_DIR = ROOT / "IP/cpu_m1/rtl"
PHASE_DIR = ROOT / "flow/v2_pipeline/phase_01_01_fetch_rv32c_prefetch"

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


def test_ifu_supports_rv32c_pc_increment_and_priority():
    text = _read(RTL_DIR / "ifu.v")
    assert "input             is_16bit" in text
    assert "wire [31:0] pc_inc = is_16bit ? 32'd2 : 32'd4;" in text
    for required in [
        "pc_redirect          ? redirect_target",
        "pc_stall             ? pc_reg",
        "ras_predict_ret      ? ras_predict_target",
        "bp_predict_taken     ? bp_predict_target",
        "pc_reg + pc_inc",
    ]:
        assert required in text


def test_core_has_prefetch_residue_and_cross_boundary_paths():
    text = _read(RTL_DIR / "core.v")
    for required in [
        "reg [15:0]  residue",
        "reg         cross_assemble",
        "wire        at_cross_boundary",
        "wire        upcoming_cross",
        "wire        fetch_stall = at_cross_boundary",
        "cross_assemble  ? {cur_half_lo, residue}",
        "upcoming_cross    ? (if_pc + 32'd4)",
        "at_cross_boundary ? (if_pc + 32'd2)",
        "cross_assemble <= 1'b1;",
        "residue        <= cur_half_hi;",
    ]:
        assert required in text


def test_cdec_covers_required_rv32c_quadrants_and_illegal_cases():
    text = _read(RTL_DIR / "cdec.v")
    for required in [
        "module cdec",
        "2'b00: case (funct3)",
        "2'b01: case (funct3)",
        "2'b10: case (funct3)",
        "C.ADDI4SPN",
        "C.LW",
        "C.SW",
        "C.JAL",
        "C.J",
        "C.BEQZ",
        "C.BNEZ",
        "C.LWSP",
        "C.SWSP",
        "C.EBREAK",
        "illegal = 1'b1",
    ]:
        assert required in text


def test_fetch_phase_filelist_contains_cdec_ras_and_core():
    filelist = _read(RTL_DIR / "filelist.f")
    for name in ["ifu.v", "cdec.v", "ras.v", "bp.v", "core.v"]:
        assert f"IP/cpu_m1/rtl/{name}" in filelist


def test_fetch_rv32c_prefetch_verilator_lint_only():
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


def test_phase_01_01_smoke_sim_artifacts_are_present_and_passing():
    sim_log = PHASE_DIR / "sim.log"
    wave_vcd = PHASE_DIR / "wave.vcd"
    firmware_hex = PHASE_DIR / "firmware.hex"
    firmware_disasm = PHASE_DIR / "firmware.disasm"

    for path in [sim_log, wave_vcd, firmware_hex, firmware_disasm]:
        assert path.exists(), f"missing phase 1.1 artifact: {path}"
        assert path.stat().st_size > 0, f"empty phase 1.1 artifact: {path}"

    log = _read(sim_log)
    assert "Magpie_M1 Phase 1.1 -- lab08e 4-stage pipeline + BP/RAS + RV32IMC" in log
    assert ">>> IRQ reset" in log
    assert "PASS:" in log
    assert "LED transitions" in log


def test_phase_01_01_vcd_manifest_records_review_intent_and_escape_hatch():
    manifest = _read(PHASE_DIR / "vcd_manifest.md")
    for required in [
        "Review Questions",
        "Required Signals",
        "Dump Windows",
        "Default Trace Settings",
        "TRACE_DEPTH=2",
        "REVIEW_TRACE=1",
        "Full Debug Escape Hatch",
        "TRACE_DEPTH=5 REVIEW_TRACE=0 RUN_ARGS=+full_vcd",
        "Known Blind Spots",
    ]:
        assert required in manifest

    makefile = _read(PHASE_DIR / "Makefile")
    for required in [
        "TRACE_DEPTH ?= 2",
        "REVIEW_TRACE ?= 1",
        "RUN_ARGS ?=",
        "-DREVIEW_TRACE",
        "$(RUN_ARGS)",
    ]:
        assert required in makefile


def test_phase_01_01_firmware_contains_compressed_boot_sequence():
    disasm = _read(PHASE_DIR / "firmware.disasm")
    for required in [
        "0001",
        "\tnop",
        "4281",
        "\tli",
        "jal",
        "mret",
    ]:
        assert required in disasm


def test_phase_01_01_vcd_header_exposes_key_debug_signals():
    vcd_head = _read_head(PHASE_DIR / "wave.vcd")
    for required in [
        "$scope module tb_core",
        "$scope module dut",
        "led [3:0]",
        "dbg_pc",
        "dbg_instr",
        "dbg_state",
    ]:
        assert required in vcd_head


def test_phase_01_01_vcd_size_is_review_focused_not_full_hierarchy():
    wave_vcd = PHASE_DIR / "wave.vcd"
    size_mb = wave_vcd.stat().st_size / (1024 * 1024)
    assert size_mb < 50, f"default review VCD too large: {size_mb:.1f} MB"
    assert size_mb > 0.1, f"default review VCD unexpectedly tiny: {size_mb:.3f} MB"
