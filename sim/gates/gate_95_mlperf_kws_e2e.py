"""gate_95_mlperf_kws_e2e — ADR-0064 F1.3: MLPerf Tiny KWS (DS-CNN) on the NPU.

kws.tflite: a depthwise-separable CNN (MLPerf KWS structure) at stride-1 VALID
representative dims:
  [6,6,8] -Conv2D 3x3(8,relu)-> [4,4,8] -DepthwiseConv2D 3x3(relu)-> [2,2,8]
          -Conv2D 1x1(8,relu)-> [2,2,8] -Flatten-> [32] -Dense(8)-> [8]
Proves the DS-CNN mechanism = a multi-layer HETEROGENEOUS chain (regular conv ->
depthwise-separable block -> FC head) composing e2e bit-exact. Each layer's ACTUAL RTL
output feeds the next; every intermediate + final == BUILTIN_REF interpreter bit-exact.
Depthwise = block-diagonal conv (ADR-0061). Production stride-2 first conv + global
avg-pool are the F1.4 backlog (im2col stride-2 gap); mechanism is stride-independent.
"""
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "sim/models"))
from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_RTL  # noqa: E402
import tflm_runtime as rt  # noqa: E402

RTL = [ROOT / f"design/npu/rtl/{m}.v" for m in
       ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine", "npu_ml_ctrl")]
RTL += CPU_M1_RTL
TB = [ROOT / "design/npu/dv/tb/axi_full_rwmem.v", ROOT / "design/npu/dv/tb/tb_npu_tflm_model.v"]
CASE = ROOT / "sim/work/tflm_model"
ART = ROOT / "sim/models/artifacts"


def run_layer(binary, layer, rows, n_out):
    g, t = rt.emit_layer_v2(CASE, layer, rows)
    out = subprocess.run([str(binary)], cwd=ROOT, capture_output=True,
                         text=True, timeout=300).stdout
    assert "NPU_TFLM_MODEL_PASS" in out and "0 errors" in out, out
    return rt.unpack_result_v2(CASE / "result.dump", g, t, len(rows), n_out)


def _hwc(pixels, h, w):     # [h*w][C] -> [h][w][C]
    return [[pixels[oy * w + ox] for ox in range(w)] for oy in range(h)]


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_kws_dscnn_bit_exact(tmp_path):
    model = json.loads((ART / "model_kws.json").read_text())
    golden = json.loads((ART / "golden_kws.json").read_text())
    cv, dw, pw, fc = model["layers"]
    assert [l["tag"] for l in model["layers"]] == ["conv", "depthwise", "pointwise", "fc"]

    mdir = tmp_path / "obj"
    b = subprocess.run(["verilator", "--binary", "--timing", "-Wno-fatal",
                        "--top-module", "tb_npu_tflm_model", "-Mdir", str(mdir),
                        *CPU_M1_ARGS, *[str(p) for p in RTL + TB]],
                       capture_output=True, text=True)
    binary = mdir / "Vtb_npu_tflm_model"
    assert binary.exists(), f"build failed:\n{b.stdout}\n{b.stderr}"

    # 1. regular conv 3x3: [6,6,8] -> [4,4,8]
    cv_out = run_layer(binary, cv, rt.im2col(cv, golden["input"][0]), 8)
    assert cv_out == [golden["inter"][0][0][oy][ox] for oy in range(4) for ox in range(4)], "conv"
    # 2. depthwise (block-diagonal) 3x3: [4,4,8] -> [2,2,8]
    dw_out = run_layer(binary, dw, rt.im2col(dw, _hwc(cv_out, 4, 4)), 8)
    assert dw_out == [golden["inter"][1][0][oy][ox] for oy in range(2) for ox in range(2)], "depthwise"
    # 3. pointwise 1x1: [2,2,8] -> [2,2,8]
    pw_out = run_layer(binary, pw, rt.im2col(pw, _hwc(dw_out, 2, 2)), 8)
    assert pw_out == [golden["inter"][2][0][oy][ox] for oy in range(2) for ox in range(2)], "pointwise"
    # 4. flatten + FC: [2,2,8]=32 -> [8]
    flat = [v for p in pw_out for v in p]      # NHWC flatten of the ACTUAL RTL pw output
    fc_out = run_layer(binary, fc, [flat], 8)
    assert fc_out[0] == golden["final"][0], "FC head / final logits"


def test_kws_artifact_provenance_regen(tmp_path):
    env = dict(os.environ, LD_LIBRARY_PATH=os.path.join(os.environ.get("CONDA_PREFIX", ""), "lib"))
    if subprocess.run([sys.executable, "-c", "import tensorflow"],
                      env=env, capture_output=True).returncode != 0:
        pytest.skip("tensorflow unavailable — provenance not-run")
    src = ROOT / "sim/models"
    work = tmp_path / "aot"
    shutil.copytree(src, work, ignore=shutil.ignore_patterns("artifacts", "__pycache__"))
    r = subprocess.run([sys.executable, str(work / "build_model_kws.py")],
                       env=env, capture_output=True, text=True, timeout=600)
    assert r.returncode == 0, r.stderr[-2000:]
    for f in ("model_kws.json", "golden_kws.json"):
        assert json.loads((work / "artifacts" / f).read_text()) == \
               json.loads((src / "artifacts" / f).read_text()), f"{f} drifted"
