"""gate_37_cq_exec_equiv — ADR-0035: the CQ path executes THE SAME transfer as the
gate_29-verified direct-CSR path.

tb_npu_cq_equiv runs one 16-word weight load + 16-word result writeback twice — once via
CQ descriptors (LOAD_W/FENCE/STORE), once via direct host CSR programming — and requires:
byte-identical destination region, identical AXI write-channel activity (AW bursts, W
beats, WLAST count) and identical weight-source read activity. The CQ transport may add
descriptor fetches but must not change the executed transfer (anti-green-wash: proves the
firmware's W1..W3 -> CSR mapping, not just 'data eventually arrived').
"""

import shutil
from pathlib import Path

import pytest

from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_RTL, verilator_sim

ROOT = Path(__file__).resolve().parents[2]
RTL = [ROOT / f"design/npu/rtl/{m}.v" for m in ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine")]
RTL += CPU_M1_RTL


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_cq_vs_direct_csr_equivalence(tmp_path):
    files = RTL + [ROOT / "design/npu/dv/tb/axi_full_rwmem.v", ROOT / "design/npu/dv/tb/tb_npu_cq_equiv.v"]
    verilator_sim(tmp_path, "tb_npu_cq_equiv", files, "NPU_CQ_EQUIV_PASS", extra_args=CPU_M1_ARGS)
