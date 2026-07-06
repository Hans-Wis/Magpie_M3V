"""gate_02_01_mem_wrapper - valid/ready memory wrapper + pipeline freeze (ADR-0005).

Phase 2.1 turns the fixed-latency `core` into a CPU IP with a Harvard,
single-outstanding, ready-gated valid/ready bus (`cpu_m1_top`) plus a global
`mem_stall` that *freezes* the pipeline (hold-in-place + suppress every commit
side-effect) for the wait duration. Misalignment traps inside the core (no
misaligned bus request is issued).

Authority: `tb_equiv` shows cpu_m1_top produces a commit stream identical to the
bare `core` over the full program for I/D wait modes {0,1,3,random} in every
combination (10/10). The bare core is already Spike-validated (phase_03_06), so
this is transitive per-commit Spike equivalence. Not a sign-off; coverage/lint
/PPA stay open.
"""

import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RTL = ROOT / "design/cpu_m1/rtl"
PHASE = ROOT / "flow/v2_pipeline/phase_02_01_mem_wrapper"
RTL_FILES = ["rfu.v", "alu.v", "idu.v", "ifu.v", "lsu.v", "csr.v", "trigger.v", "mul.v",
             "div.v", "forward.v", "hazard.v", "bp.v", "ras.v", "cdec.v",
             "core.v", "cpu_m1_top.v"]


def _read(p: Path) -> str:
    return p.read_text(encoding="utf-8")


def test_adr_and_spec_present():
    assert (ROOT / "docs/adr/0005-mem-valid-ready-wrapper.md").is_file()
    assert "valid/ready" in _read(ROOT / "design/cpu_m1/docs/spec.md")


def test_core_has_mem_stall_input_and_freeze_gating():
    text = _read(RTL / "core.v")
    # input + OR into the stall network
    assert "input             mem_stall," in text
    assert "any_stall   = stall | fetch_stall | warmup | redirect_warmup | mem_stall;" in text
    # hold-in-place (not bubble) for the two downstream pipeline registers
    assert "end else if (mem_stall) begin" in text
    # commit side-effects suppressed during a memory wait
    for needle in [
        "assign rfu_we      = ex_wb_valid_r && ex_wb_rd_we_r && !ex_wb_illegal_r &&",
        "!wb_take_irq && !wb_take_data_trap && !wb_take_trigger && !mem_stall;",
        "assign wb_instr_retired = ex_wb_valid_r && !wb_take_irq && !wb_take_data_trap &&",
        "!wb_take_sync_trap && !wb_take_trigger && !mem_stall;",
        "assign wb_csr_we      = ex_wb_csr_we_r && ex_wb_valid_r && !wb_take_irq &&",
        "!wb_take_trigger && !ex_wb_illegal_r && !mem_stall;",
            "assign wb_trap_enter        = (wb_take_irq || wb_take_data_trap || wb_take_sync_trap) && !mem_stall;",
        "assign bp_upd_valid  = ex_mem_bp_upd_valid_r && !mem_stall && !ex_mem_trigger_hit_r;",
        "&& !stall && !pc_redirect && !mem_stall;",  # ras_push
        "if (mem_stall) begin\n            // ADR-0005 freeze: no PC redirect",
    ]:
        assert needle in text, f"missing freeze gating: {needle!r}"


def test_core_misalign_trap_is_present_and_gates_bus_request():
    text = _read(RTL / "core.v")
    assert "wire wb_take_data_trap = ex_wb_valid_r && ex_wb_is_misaligned_r;" in text
    # a misaligned access never drives a bus request
    assert "!pc_redirect && !debug_mode && !ex_mem_is_misaligned_r &&" in text


def test_wrapper_valid_ready_contract_and_boot_prime():
    text = _read(RTL / "cpu_m1_top.v")
    for needle in ["ibus_req", "ibus_ready", "dbus_req", "dbus_ready", "dbus_wstrb",
                   "wire mem_stall = ((i_busy | d_busy) | ~primed) & resetn;",
                   "wire i_fire = core_i_mem_en & ~i_busy & ~mem_stall;",
                   "i_boot ? RESET_PC"]:
        assert needle in text, f"missing wrapper contract: {needle!r}"


def test_verilator_lint_clean():
    vl = shutil.which("verilator") or "verilator"
    assert Path(vl).exists(), f"verilator not found: {vl}"
    cmd = [vl, "--lint-only", "-Wall", "-Wno-DECLFILENAME", "-Wno-TIMESCALEMOD",
           "-Wno-UNUSEDSIGNAL", "-Wno-PROCASSINIT", f"-I{RTL}",
           *[str(RTL / n) for n in RTL_FILES], "--top-module", "cpu_m1_top"]
    subprocess.run(cmd, check=True)


def test_equivalence_all_wait_modes_pass():
    """cpu_m1_top == bare core over the program for all I/D wait configs."""
    res = subprocess.run(["bash", str(PHASE / "run_equiv.sh")],
                         capture_output=True, text=True)
    out = res.stdout + res.stderr
    assert "SUMMARY 10/10 wait configs pass" in out, out[-2000:]
    assert res.returncode == 0, out[-2000:]
