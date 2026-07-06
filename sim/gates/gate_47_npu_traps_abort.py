"""gate_47_npu_traps_abort — ADR-0038 / P0⑤: the control plane closes.

tb_npu_p05, four scenarios in sequence on the real npu_top:
S1 core trap -> host: a deterministic illegal instruction (trap_test firmware, pc=0x14);
   the terminal handler reports ERR_PC=0x14 / ERR_CAUSE=0x80000002 (CORE_TRAP|mcause)
   through the latch-once mirror pair; the cq_err rising edge raises the host ERR IRQ
   (Kelvin io_fault shape: fault visible in status, core spins).
S2 soft_reset (CTRL[2]): the core halts immediately (start cleared), STATUS[8] drops at
   quiesce, and the FAULT EVIDENCE PERSISTS for post-mortem until the CQ_CTRL
   enable-toggle ack (Grok critique adoption — reset must not destroy evidence).
S3 abort mid-4096-beat DMA: the engine stops at a burst boundary — zero AR handshakes
   after quiesce (AXI protocol clean), busy/done clear, ERR_CAUSE=ABORTED(8), ERR IRQ.
S4 recovery: ack, reload the CQ firmware, and a full matrix batch
   (CFG/ACC_CLR/OP/RESCALE/STORE|LAST) runs to DONE with no error.
GO pulses are abort-locked in the registers; FULL IRQ stays unimplemented (the
producer-side FULL check is the ABI since ADR-0035 — recorded).
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_RTL, verilator_sim  # noqa: E402

RTL = [ROOT / f"IP/npu/rtl/{m}.v" for m in
       ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine")]
RTL += CPU_M1_RTL
TB = [ROOT / "IP/npu/dv/tb/axi_full_rwmem.v", ROOT / "IP/npu/dv/tb/tb_npu_p05.v"]


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_traps_abort_recovery(tmp_path):
    for hexf in ("trap_test.hex", "firmware.hex"):
        assert (ROOT / "IP/npu/sw/cq_sequencer" / hexf).exists(), f"{hexf} missing"
    verilator_sim(tmp_path, "tb_npu_p05", RTL + TB, "NPU_P05_PASS", extra_args=CPU_M1_ARGS)


def test_ssot_carries_the_fault_namespace():
    import json
    d = json.loads((ROOT / "IP/npu/schema/command_descriptor_v0_1.yaml").read_text())
    names = {e["name"]: e["value"] for e in d["err_causes"]}
    assert names.get("ABORTED") == 8 and names.get("MAT_PARAM") == 7
    assert names.get("CORE_TRAP_FLAG") == 0x80000000
    regs = {r["name"]: r["offset"] for r in d["csr"]["registers"]}
    assert regs.get("ERR_PC") == 128
