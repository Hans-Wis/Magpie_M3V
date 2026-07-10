"""gate_gemma3_s1_rtl — ADR-0062 S1 (F1.6): Gemma post-attn RMSNorm + residual bit-exact
on the NPU RTL.

  a_normed = RMSNorm(a)*(1+w)   ->  x = r + a_normed     (representative dims seq=4, hidden=64)

Both nonlinear ops run on the NPU sequencer core via the new CQ ops MAT_RMSNORM /
MAT_EWISE_ADD_REQUANT — NOT the host (nonlinear-in-RTL green-wash guard). rsqrt is the pure
integer degree-3 polynomial (no scalar-F): the coefficients ride in a TCM param blob sourced
from the Tier-C golden (gemma_quant_s1), so firmware carries ZERO rsqrt constants (non-circular
SSOT). The residual step is chained through the ACTUAL RTL RMSNorm output, and every checkpoint
is asserted byte-identical to the golden.
"""
import re
import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np
import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "sim/models"))
sys.path.insert(0, str(ROOT / "design/npu/sw/gemma"))
from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_RTL  # noqa: E402
import gemma_ref as ref  # noqa: E402
import gemma_quant_s1 as s1  # noqa: E402
import gemma_runtime as gr  # noqa: E402

RTL = [ROOT / f"design/npu/rtl/{m}.v" for m in
       ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine", "npu_ml_ctrl", "npu_strip_buf")]
RTL += CPU_M1_RTL
TB = [ROOT / "design/npu/dv/tb/axi_full_rwmem.v", ROOT / "design/npu/dv/tb/tb_npu_tflm_model.v"]
CASE = ROOT / "sim/work/tflm_model"
FIRMWARE = ROOT / "design/npu/sw/cq_sequencer/firmware.hex"


def _golden(seed=7):
    cfg = ref.CFG
    W = ref.make_weights(cfg)
    rng = np.random.default_rng(seed)
    a = rng.normal(0, 1.0, (cfg["seq"], cfg["hidden"])).astype(np.float32)
    r = rng.normal(0, 1.0, (cfg["seq"], cfg["hidden"])).astype(np.float32)
    g = s1.s1_golden(a, r, W["norm_postattn"], cfg)
    return cfg, g


def _run(binary):
    out = subprocess.run([str(binary)], cwd=ROOT, capture_output=True,
                         text=True, timeout=300).stdout
    assert "NPU_TFLM_MODEL_PASS" in out and "0 errors" in out, out


def test_s1_ssot_and_nonlinear_in_rtl():
    # green-wash guards that need no RTL build: the opcodes exist, the rsqrt coefficients
    # in the golden blob are the frozen SSOT (eps kept), and the firmware carries no scalar-F.
    import cq_codec as c
    assert "MAT_RMSNORM" in c.OPCODES and "MAT_EWISE_ADD_REQUANT" in c.OPCODES
    assert s1.EPS_Q > 0, "eps dropped -> all-zero rows divide by zero"
    assert len(s1.RSQRT_C) == 4 and s1.INV_SQRT2_Q16 == 46341
    disasm = ROOT / "design/npu/sw/cq_sequencer/firmware.disasm"
    if disasm.exists():
        text = disasm.read_text()
        for banned in (r"\bfsqrt", r"\bfdiv", r"\bfmul\.", r"\bfadd\.", r"\bfcvt"):
            assert not re.search(banned, text), f"scalar-F {banned!r} leaked into rsqrt firmware"
        for required in (r"\bvwmul\.vv\b", r"\bvsmul\.vx\b", r"\bvssra\.vx\b",
                         r"\bvle8\.v\b", r"\bvle16\.v\b", r"\bvse8\.v\b",
                         r"\bvncvt\.x\.x\.w\b"):
            assert re.search(required, text), f"RMSNorm RVV disasm missing {required!r}"
        m = re.search(r"vsmul\.vx(?P<loop>[\s\S]{0,700}?vse8\.v)", text)
        assert m, "RMSNorm scale loop not found in disasm"
        for banned in ("__ashrdi3", "__muldi3", "__divdi3"):
            assert banned not in m.group("loop"), f"{banned} leaked into RMSNorm scale loop"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_s1_rmsnorm_residual_bit_exact_on_rtl(tmp_path):
    assert FIRMWARE.exists(), "firmware.hex missing — run make in design/npu/sw/cq_sequencer"
    cfg, g = _golden()
    seq, H = cfg["seq"], cfg["hidden"]

    mdir = tmp_path / "obj"
    b = subprocess.run(["verilator", "--binary", "--timing", "-Wno-fatal",
                        "--top-module", "tb_npu_tflm_model", "-Mdir", str(mdir),
                        *CPU_M1_ARGS, *[str(p) for p in RTL + TB]],
                       capture_output=True, text=True)
    binary = mdir / "Vtb_npu_tflm_model"
    assert binary.exists(), f"build failed:\n{b.stdout}\n{b.stderr}"

    # --- step 1: a_normed = RMSNorm(a)*(1+w) on the sequencer (MAT_RMSNORM) ---
    rw, nt = gr.emit_rmsnorm(CASE, g["a_q"].tolist(), g, seq, H)
    _run(binary)
    an = gr.unpack_contiguous(CASE / "result.dump", seq, H)
    assert an == g["an_q"].tolist(), "RMSNorm RTL != golden"

    # --- step 2: x = r + a_normed on the sequencer, chained from the RTL a_normed ---
    gr.emit_add_requant(CASE, g["r_q"].tolist(), an, g, seq, H)
    _run(binary)
    x = gr.unpack_contiguous(CASE / "result.dump", seq, H)
    assert x == g["x_q"].tolist(), "residual add RTL != golden (full S1)"
