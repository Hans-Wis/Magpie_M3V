"""gate_46_cq_matrix_e2e — ADR-0037 4B: the full Coral-shaped matrix offload, golden-exact.

tb_npu_cq_mat drives the REAL flow end to end: host loads int8 a/b blocks into the TCM,
writes a 5-descriptor ring (CFG -> ACC_CLR -> OP(RPT=4, K binding) -> RESCALE (the v4 §06
worked-example params) -> STORE(W2=MAT_OUT, IRQ|LAST)); the sequencer firmware consumes it
and drives the matrix engine; the requantized 8x8 int8 tile lands in shared memory and is
compared here BYTE-EXACTLY against mat_golden.py (the verification authority for matrix —
CLAUDE.md §3 row 3). Also: MAT.OP with W3!=0 halts with ERR_CAUSE=MAT_PARAM (the frozen
W3==0 rule from Grok's critique).
"""

import shutil
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_RTL, verilator_sim  # noqa: E402

RTL = [ROOT / f"IP/npu/rtl/{m}.v" for m in
       ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine")]
RTL += CPU_M1_RTL
TB = [ROOT / "IP/npu/dv/tb/axi_full_rwmem.v", ROOT / "IP/npu/dv/tb/tb_npu_cq_mat.v"]


def _golden_tile() -> bytes:
    sys.path.insert(0, str(ROOT / "IP/npu/golden"))
    import mat_golden

    def s8(v):
        v &= 0xFF
        return v - 256 if v & 0x80 else v

    a = [s8(i * 7 - 100) for i in range(32)]
    b = [s8(i * 5 - 60) for i in range(32)]
    outs = mat_golden.run_op_sequence([
        {"kind": "clr", "mask": 0x1},
        {"kind": "op", "a": a, "b": b, "rpt": 4, "bank": 0},
        {"kind": "rescale", "bank": 0, "mult": 0x54C4699A, "shift": 38,
         "zp": -128, "cmin": -128, "cmax": 127},
    ])
    return outs[0]


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_cq_matrix_offload_matches_golden(tmp_path):
    verilator_sim(tmp_path, "tb_npu_cq_mat", RTL + TB, "NPU_CQ_MAT_PASS",
                  extra_args=CPU_M1_ARGS)
    dump = (ROOT / "mat_result.dump").read_text().split()
    got = bytearray()
    for w in dump:
        v = int(w, 16)
        got += bytes([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF])
    exp = _golden_tile()
    assert bytes(got) == exp, (
        f"matrix tile mismatch:\n got={bytes(got).hex()}\n exp={exp.hex()}")
