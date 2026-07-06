"""gate_38_cq_err — ADR-0035 ERR contract: bad work must halt loudly, never fake-complete.

tb_npu_cq_ring_err S3 (NPU_CQ_ERR_PASS): ERR ladder with per-round recovery —
BAD_OPCODE(1), RSVD_VIOLATION(2), ENGINE_NOT_READY(4) for MAT.OP (the green-wash guard:
the engine exists since ADR-0037 — malformed params must ERR loudly),
DESC_ALIGN(6). Each: CQ_STATUS.err set, ERR_CAUSE latched-once, HEAD frozen, no DONE.
Recovery = repair ring + CQ_CTRL enable-toggle (clears cause) + core restart, then a good
descriptor completes. RING_OVERRUN(3) detection is deferred (ADR-0035 deviation: host-side
discipline, code reserved); DMA_FAULT(5) reuses the gate_28/29-verified engine error path.
"""

import shutil
from pathlib import Path

import pytest

from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_RTL, verilator_sim

ROOT = Path(__file__).resolve().parents[2]
RTL = [ROOT / f"design/npu/rtl/{m}.v" for m in ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine")]
RTL += CPU_M1_RTL


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_cq_err_ladder_halts_and_recovers(tmp_path):
    files = RTL + [ROOT / "design/npu/dv/tb/axi_full_rwmem.v", ROOT / "design/npu/dv/tb/tb_npu_cq_ring_err.v"]
    verilator_sim(tmp_path, "tb_npu_cq_ring_err", files, "NPU_CQ_ERR_PASS", extra_args=CPU_M1_ARGS)
