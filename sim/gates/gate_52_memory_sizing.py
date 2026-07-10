"""gate_52_memory_sizing — ADR-0044: Coral row-4 memory parity.

ITCM 8KB (fetch + host 0x3002 window) / DTCM 32KB (0x3001) Harvard split with
the SAME firmware image mirrored into both (Spike-flat-compatible; recorded
limit: self-modifying code); DTCM structural model = 8-way word-interleaved
banks with a 2R+1W per-bank per-cycle budget enforced by a sim checker.

tb_npu_memsize: capacity boundaries (last word OK / past-end SLVERR / 0x3003
decode error), Harvard isolation (same offset holds independent values; D
writes never touch the fetch image), and the bank checker BOTH ways — a
host-driven engine OP shows zero violations (dual 256b windows = exactly the
2R budget) AND a forced host-polling overlap makes the counter fire (the
checker is alive, not decoration — Grok green-wash guard).

Plus: RTL params must actually say 8192x32 / 2048x32 (no silent shrink), and
the whole existing NPU gate chain re-ran green on the 32KB/banked memories.
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
TB = [ROOT / "design/npu/dv/tb/axi_full_rwmem.v", ROOT / "design/npu/dv/tb/tb_npu_memsize.v"]


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_sizing_isolation_and_bank_budget(tmp_path):
    verilator_sim(tmp_path, "tb_npu_memsize", RTL + TB, "NPU_MEMSIZE_PASS",
                  extra_args=CPU_M1_ARGS)


def test_rtl_declares_coral_row4_sizes():
    top = (ROOT / "design/npu/rtl/npu_top.v").read_text()
    assert re.search(r"TCM_WORDS\s*=\s*8192", top), "DTCM must be 32KB"
    assert re.search(r"ITCM_WORDS\s*=\s*2048", top), "ITCM must be 8KB"
    tcm = (ROOT / "design/npu/rtl/npu_tcm.v").read_text()
    assert "bank_violations" in tcm and "npu_itcm" in tcm
