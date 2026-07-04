"""gate_28_axi_adversarial — Phase 1.5 bus-protocol hardening.

Adversarial AXI stimulus that the happy-path BFMs never generate, each targeting a Codex-found
bug and asserting the FIX (see docs/reviews/2026-07-03_multiagent_review.md):
  - W-before-AW must complete (no misroute/deadlock)   [axil_1to2 / npu_top]
  - WSTRB byte-write merges (does not clobber the word) [npu_axil_regs / npu_tcm]
  - out-of-window NPU address -> SLVERR (no CSR alias)  [npu_top DECERR]
  - TCM out-of-range offset -> SLVERR (no wrap)         [npu_tcm]
  - DMA LEN=0 -> done, no rogue 256-beat burst          [npu_dma]
  - DMA read SLVERR -> STATUS.dma_err (not silent OK)   [npu_dma]

Sim = **Verilator** (`--binary --timing`); VCS = signoff (OUTSIDE-SANDBOX).
"""

import shutil
from pathlib import Path

import pytest

from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_RTL, verilator_sim

ROOT = Path(__file__).resolve().parents[2]
NPU_RTL = [ROOT / f"IP/npu/rtl/{m}.v" for m in ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine")]
NPU_RTL += CPU_M1_RTL  # ADR-0034: npu_top now instantiates the cpu_m1 sequencer
MEM = ROOT / "IP/npu/dv/tb/axi_full_mem.v"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_adversarial_axi_lite_and_dma_ctrl(tmp_path):
    files = NPU_RTL + [MEM, ROOT / "IP/npu/dv/tb/tb_axi_adversarial.v"]
    verilator_sim(tmp_path, "tb_axi_adversarial", files, "ADVERSARIAL_PASS", extra_args=CPU_M1_ARGS)


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_dma_flags_read_slverr(tmp_path):
    files = [ROOT / "IP/npu/rtl/npu_dma.v", MEM, ROOT / "IP/npu/dv/tb/tb_dma_err.v"]
    verilator_sim(tmp_path, "tb_dma_err", files, "DMA_ERR_PASS", require_zero_errors=False)
