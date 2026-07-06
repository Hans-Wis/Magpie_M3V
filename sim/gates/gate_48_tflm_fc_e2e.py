"""gate_48_tflm_fc_e2e — ADR-0039 / Phase 6: TFLM int8 FullyConnected, e2e.

One real TFLM op (reference_integer_ops::FullyConnected semantics, per-tensor
int8) lowered by design/npu/golden/tflm_fc.py through the SSOT codec into a
6-descriptor CQ batch, run on the REAL offload loop (ring in shared mem ->
doorbell -> sequencer firmware -> LOAD_W DMA -> LOADACC fold preload -> batch-8
GEMV -> frozen gemmlowp RESCALE -> STORE writeback -> IRQ), compared bit-exact
against an INDEPENDENT per-k int32-wrap reference of the TFLM kernel.

Six corner cases (Grok DV matrix): input_zp {-128,1,13,55,100,-77}, deliberate
int32 wrap through the bias fold, doubling-high multiplier boundary
(mult=0x7FFFFFFF, shift=31), fused-ReLU clamp, bias-only (zero weights — pure
LOADACC path), K in {8,16,32,64} (RPT discipline, full 64-rep array).

Green-wash guards: the reference computes per-k in TFLM order (NOT the fold);
filter_offset != 0 must be REJECTED by the compiler (scope honesty, not a
silent wrong answer); every descriptor round-trips through cq_codec.decode.
"""

import shutil
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "design/npu/golden"))
from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_RTL  # noqa: E402
import tflm_fc  # noqa: E402

RTL = [ROOT / f"design/npu/rtl/{m}.v" for m in
       ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine")]
RTL += CPU_M1_RTL
TB = [ROOT / "design/npu/dv/tb/axi_full_rwmem.v", ROOT / "design/npu/dv/tb/tb_npu_tflm_fc.v"]
CASE_DIR = ROOT / "sim/work/tflm_case"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_tflm_fc_all_corners_bit_exact(tmp_path):
    assert (ROOT / "design/npu/sw/cq_sequencer/firmware.hex").exists()
    mdir = tmp_path / "obj"
    b = subprocess.run(["verilator", "--binary", "--timing", "-Wno-fatal",
                        "--top-module", "tb_npu_tflm_fc", "-Mdir", str(mdir),
                        *CPU_M1_ARGS, *[str(p) for p in RTL + TB]],
                       capture_output=True, text=True)
    assert (mdir / "Vtb_npu_tflm_fc").exists(), f"build failed:\n{b.stdout}\n{b.stderr}"

    cases = tflm_fc.corner_cases()
    assert len(cases) == 6, "corner matrix shrank — green-wash guard"
    for name, case in cases.items():
        tflm_fc.emit_case(CASE_DIR, case)
        out = subprocess.run([str(mdir / "Vtb_npu_tflm_fc")], cwd=ROOT,
                             capture_output=True, text=True, timeout=180).stdout
        assert "NPU_TFLM_FC_PASS" in out, f"case {name} failed:\n{out}"
        assert "0 errors" in out, f"case {name} mismatches:\n{out}"


def test_compiler_rejects_nonzero_filter_offset():
    case = dict(tflm_fc.corner_cases()["base_k32"])
    with pytest.raises(ValueError):
        tflm_fc.compile_fc(**case, filter_zp=3)


def test_descriptors_round_trip_the_ssot_codec():
    sys.path.insert(0, str(ROOT / "design/npu/sw"))
    import cq_codec
    _, ring = tflm_fc.compile_fc(**tflm_fc.corner_cases()["full_k64_maxmult"])
    ops = [cq_codec.decode(ring[i:i + 4]) for i in range(0, len(ring), 4)]
    assert [d["op"] for d in ops] == ["MAT_CFG", "MAT_LOAD_W", "MAT_ACC_CLR",
                                      "MAT_OP", "MAT_RESCALE", "MAT_STORE"]
    clr = ops[2]
    assert clr["bias_tcm_byte"] == 0x700, "W2!=0 => LOADACC semantics (Grok lint)"
    assert ops[3]["rpt"] == 64, "RPT = FC depth (one outer product per rep)"
    assert ops[0]["k"] == 512 and ops[5]["last"] == 1 and ops[5]["irq"] == 1
