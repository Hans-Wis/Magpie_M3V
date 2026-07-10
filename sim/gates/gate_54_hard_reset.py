"""gate_54_hard_reset — ADR-0047: hard vs soft reset, the row-6 remainder.

CTRL[3] = hard reset: the AXI write completes, the soft-abort drain machinery
runs (core halted, GO locked, DMA to a burst boundary), then — once engines
are quiet and no host transaction is in flight (new acceptances frozen so a
polling host cannot starve it) — a 2-cycle internal domain reset returns
EVERY register to power-on: fault evidence, ring config, HEAD/TAIL, DMA/MAT
config, IRQ, CTRL itself. ITCM/DTCM contents persist (SRAM semantics —
intentional divergence from an IMEM-clearing Coral hard reset, recorded).

The killer check is the DISTINCTION: the same fault, soft-then-read keeps
ERR_CAUSE (ADR-0038), hard-then-read reads zero. Plus: clean AXI drain when
fired mid-4096-beat DMA, double-hard idempotence, and a cold restart that
runs a full CQ matrix batch with no spurious IRQ.
"""

import shutil
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_RTL, verilator_sim  # noqa: E402

RTL = [ROOT / f"design/npu/rtl/{m}.v" for m in
       ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine", "npu_ml_ctrl", "npu_strip_buf")]
RTL += CPU_M1_RTL
TB = [ROOT / "design/npu/dv/tb/axi_full_rwmem.v", ROOT / "design/npu/dv/tb/tb_npu_hard_reset.v"]


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_hard_vs_soft_reset_distinction(tmp_path):
    for hexf in ("trap_test.hex", "firmware.hex"):
        assert (ROOT / "design/npu/sw/cq_sequencer" / hexf).exists()
    verilator_sim(tmp_path, "tb_npu_hard_reset", RTL + TB, "NPU_HARDRST_PASS",
                  extra_args=CPU_M1_ARGS)
