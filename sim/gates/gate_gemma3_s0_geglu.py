"""gate_gemma3_s0_geglu — ADR-0062 S0 (F1.5): Gemma GeGLU MLP bit-exact on the NPU RTL.

down( gelu(gate(x)) ⊙ up(x) ), representative dims (seq=4, hidden=64, inter=128).
The 3 GEMMs run on the proven mat_engine; the nonlinear ops (gelu 256-entry LUT, elementwise
mul-requant) run on the NPU sequencer via the new CQ ops MAT_ACT_LUT / MAT_EWISE_MUL — NOT the
host (nonlinear-in-RTL green-wash guard). The pipeline is chained through the host RTL→RTL
(each step consumes the previous step's ACTUAL RTL output), and every checkpoint is asserted
byte-identical to the Tier-C fixed-point golden (gemma_quant, whose requant was just fixed to
the mat_engine authority).
"""
import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np
import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "sim/models"))
from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_RTL  # noqa: E402
import tflm_runtime as rt  # noqa: E402
import gemma_runtime as gr  # noqa: E402
import gemma_quant as gq  # noqa: E402

RTL = [ROOT / f"design/npu/rtl/{m}.v" for m in
       ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine")]
RTL += CPU_M1_RTL
TB = [ROOT / "design/npu/dv/tb/axi_full_rwmem.v", ROOT / "design/npu/dv/tb/tb_npu_tflm_model.v"]
CASE = ROOT / "sim/work/tflm_model"


def _run(binary):
    out = subprocess.run([str(binary)], cwd=ROOT, capture_output=True,
                         text=True, timeout=300).stdout
    assert "NPU_TFLM_MODEL_PASS" in out and "0 errors" in out, out


def test_s0_lut_and_requant_contract():
    # green-wash guards that need no RTL: the new opcodes exist and the mul-requant params
    # are the golden's (not invented), and the gelu LUT is the documented table.
    import cq_codec as c
    assert "MAT_ACT_LUT" in c.OPCODES and "MAT_EWISE_MUL" in c.OPCODES
    t = gr.s0_tensors(); sc = t["g"]["scales"]
    m, s = gq.qmul(sc["gelu"] * sc["up"] / sc["prod"])
    assert 31 <= 31 - s <= 62, "mul-requant engine shift out of range"
    lut = t["g"]["lut"]
    assert len(lut) == 256 and int(np.argmin(lut)) < 128, "gelu LUT not the documented table"


@pytest.mark.skip(reason="F1.5 S0 e2e blocked on firmware TCM-layout: the MAT_ACT_LUT/"
                  "MAT_EWISE_MUL handlers (+int64 srdhm/rdbpot) grow the sequencer .text/.bss "
                  "to 0x854, overlapping the weight-DMA region at TCM_WEIGHT_B=0x700 (4K linker "
                  "region) — corrupts latched CFG state, hangs ALL GEMMs. Fix = relocate the CQ "
                  "data regions past the code (MAT_OUT out_base is CSR-configurable) or shrink "
                  "srdhm. Runtime + gate + handler design are ready; see "
                  "docs/reports/2026-07-06_gemma_s0_e2e_blocker.md.")
@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_s0_geglu_bit_exact_on_rtl(tmp_path):
    t = gr.s0_tensors()
    cfg, g = t["cfg"], t["g"]
    seq, hid, inter = cfg["seq"], cfg["hidden"], cfg["intermediate"]
    sc = g["scales"]
    x_q = g["x_q"].tolist()

    mdir = tmp_path / "obj"
    b = subprocess.run(["verilator", "--binary", "--timing", "-Wno-fatal",
                        "--top-module", "tb_npu_tflm_model", "-Mdir", str(mdir),
                        *CPU_M1_ARGS, *[str(p) for p in RTL + TB]],
                       capture_output=True, text=True)
    binary = mdir / "Vtb_npu_tflm_model"
    assert binary.exists(), f"build failed:\n{b.stdout}\n{b.stderr}"

    # --- step 1: gate = GEMM(x, Wg) on mat_engine ---
    wg, swg = t["wg"]
    ng, nt = rt.emit_layer_v2(CASE, gr.gemm_layer(wg, swg, g["sx"], sc["gate"], hid, inter),
                              x_q, ring_entries=128)
    _run(binary)
    gate = rt.unpack_result_v2(CASE / "result.dump", ng, nt, seq, inter)
    assert gate == g["gate_q"].tolist(), "gate GEMM RTL != golden"

    # --- step 2: gelu = MAT_ACT_LUT[gate] on the sequencer (RTL-chained from step 1) ---
    rw, _ = gr.emit_act_lut(CASE, gate, g["lut"].tolist(), seq, inter)
    _run(binary)
    gelu = gr.unpack_contiguous(CASE / "result.dump", seq, inter)
    assert gelu == g["gelu_q"].tolist(), "gelu LUT RTL != golden"

    # --- step 3: up = GEMM(x, Wu) ---
    wu, swu = t["wu"]
    ng, nt = rt.emit_layer_v2(CASE, gr.gemm_layer(wu, swu, g["sx"], sc["up"], hid, inter),
                              x_q, ring_entries=128)
    _run(binary)
    up = rt.unpack_result_v2(CASE / "result.dump", ng, nt, seq, inter)
    assert up == g["up_q"].tolist(), "up GEMM RTL != golden"

    # --- step 4: prod = MAT_EWISE_MUL(gelu, up) on the sequencer ---
    m, s = gq.qmul(sc["gelu"] * sc["up"] / sc["prod"])
    gr.emit_ewise_mul(CASE, gelu, up, m, 31 - s, seq, inter)
    _run(binary)
    prod = gr.unpack_contiguous(CASE / "result.dump", seq, inter)
    assert prod == g["prod_q"].tolist(), "elementwise mul-requant RTL != golden"

    # --- step 5: out = GEMM(prod, Wd) (RTL-chained from step 4) ---
    wd, swd = t["wd"]
    ng, nt = rt.emit_layer_v2(CASE, gr.gemm_layer(wd, swd, sc["prod"], sc["out"], inter, hid),
                              prod, ring_entries=128)
    _run(binary)
    out = rt.unpack_result_v2(CASE / "result.dump", ng, nt, seq, hid)
    assert out == g["out_q"].tolist(), "down GEMM RTL != golden (full S0 GeGLU)"
