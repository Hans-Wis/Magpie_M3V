"""gate_30_npu_core_integration — Phase 2 Step 4 (ADR-0034): the NPU core is alive in its socket.

tb_npu_core_smoke drives npu_top exactly like the host: program loaded into TCM over the REAL
AXI4-Lite path (not backdoor), CTRL.start releases the core, DONE mailbox store sets
STATUS.npu_done + level IRQ, host reads the core-computed result back out of the TCM
(anti-green-wash: proves the core actually fetched from TCM and executed). Also: no fetch
before start (core_resetn observed low), STATUS.busy seen while running, irq_clear works,
start=0 clears done, and a re-run with a modified program produces the new result (42 -> 55).
Sim = Verilator (VCS signoff OUTSIDE-SANDBOX).
"""

import shutil
from pathlib import Path

import pytest

from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_RTL, verilator_lint, verilator_sim

ROOT = Path(__file__).resolve().parents[2]
RTL = [ROOT / f"design/npu/rtl/{m}.v" for m in ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine", "npu_ml_ctrl", "npu_strip_buf")]
RTL += CPU_M1_RTL
TB = [ROOT / "design/npu/dv/tb/tb_npu_core_smoke.v"]


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_npu_core_integration_lints_clean():
    verilator_lint(RTL, extra_args=CPU_M1_ARGS)


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_npu_core_boot_done_irq_rerun(tmp_path):
    verilator_sim(tmp_path, "tb_npu_core_smoke", RTL + TB, "NPU_CORE_SMOKE_PASS", extra_args=CPU_M1_ARGS)
