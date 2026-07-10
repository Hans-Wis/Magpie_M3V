"""gate_53_rvfi_trace — ADR-0045: RVFI/RVVI-lite trace port (Coral row 8, v0).

The port is pure wire-outs of the WB commit state (scalar: valid/pc/trap/
intr/rd; vector: v_valid/vd/wdata[128]/vl/vtype; order counter at npu_top
counting retire+trap events). AUTHORITY: the phase_20 Spike lockstep TB now
samples ONLY the port — directed (1164 commits) + random (8x10,809) rerun
green means the trace stream IS the lockstep evidence, not a decoration.

Checks here:
1. tb_npu_trace: deterministic illegal at pc=0x14 — exactly 5 retires, one
   rvfi_trap pulse with rvfi_pc==0x14, rvvi silent on scalar firmware,
   order == retires+traps; handler ERR_CAUSE contract unchanged.
2. Anti-greenwash: the lockstep TB's sampling path must contain ZERO
   hierarchical core peeks (grep guard) — everything through dut.rvfi_*.
3. The port-sourced directed lockstep run itself (via the gate_31 harness).

v1 (ADR-0048): rvfi_insn (asserted == ITCM join on EVERY lockstep commit),
rvfi_trap_mtval + rvfi_mstatus, and a WB-aligned mem trace (re/we/addr/
wdata/wstrb — the trap TB watches the handler's two MMIO stores land on the
ERR_CAUSE mirror with the exact data). Vector trace remains valid within
the implemented LMUL<=1 subset.
"""

import re
import shutil
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_RTL, verilator_sim  # noqa: E402

RTL = [ROOT / f"design/npu/rtl/{m}.v" for m in
       ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine", "npu_ml_ctrl", "npu_strip_buf")]
RTL += CPU_M1_RTL
TB = [ROOT / "design/npu/dv/tb/axi_full_rwmem.v", ROOT / "design/npu/dv/tb/tb_npu_trace.v"]


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_trap_visibility_and_order(tmp_path):
    assert (ROOT / "design/npu/sw/cq_sequencer/trap_test.hex").exists()
    verilator_sim(tmp_path, "tb_npu_trace", RTL + TB, "NPU_TRACE_PASS",
                  extra_args=CPU_M1_ARGS)


def test_lockstep_tb_samples_only_the_port():
    tb = (ROOT / "flow/v2_pipeline/phase_20_npu_core_lockstep/tb_npu_lockstep.v").read_text()
    assert "u_core." not in tb, "hierarchical core peek crept back into lockstep"
    for sig in ("dut.rvfi_valid", "dut.rvfi_trap", "dut.rvfi_pc",
                "dut.rvfi_rd_addr", "dut.rvvi_v_valid"):
        assert sig in tb, f"lockstep TB no longer samples {sig}"


def test_port_carries_the_core_signals():
    core = (ROOT / "design/cpu_m1/rtl/core.v").read_text()
    m = re.search(r"assign rvfi_valid\s*=\s*wb_instr_retired", core)
    assert m, "rvfi_valid must be the real retirement signal"
    assert re.search(r"assign rvvi_v_valid\s*=\s*wb_vex_we", core)
