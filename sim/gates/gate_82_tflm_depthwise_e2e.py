"""gate_82_tflm_depthwise_e2e — ADR-0061: a MobileNet depthwise-separable block on the NPU.

dwsep.tflite: [1,6,6,8] -> DepthwiseConv2D 3x3 VALID stride1 (per-channel, ReLU)
              -> [1,4,4,8] -> PointwiseConv2D 1x1 cout=8 (per-channel, ReLU) -> [1,4,4,8].

Depthwise is NOT a shared-K GEMM (out channel c uses only in channel c). It is lowered
as a STANDARD conv with BLOCK-DIAGONAL (channel-masked) weights so the exact depthwise
int32 accumulator falls out of the existing im2col GEMM (zeroed off-channel taps
contribute 0 bit-exactly) — ZERO RTL / ZERO runtime change; the mat_engine + npu_dma +
conv lowering are provably sufficient (~1/8 array utilization). Per-channel requant via
RESCALE_PC. The pointwise 1x1 is a plain GEMM -> existing conv path as-is.

round 1: host im2col (16 pixels = 2 row-groups) of DW block-diagonal conv (K=72, chunked
         64+8) -> RTL -> must equal the BUILTIN_REF DEPTHWISE intermediate bit-exact;
round 2: 1x1 conv over the ACTUAL RTL DW output -> RTL -> final bit-exact.
Provenance: TF regen must reproduce all artifacts byte-exact (skip = not-run).
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


def _load():
    return (json.loads((ART / "model_dw.json").read_text()),
            json.loads((ART / "golden_dw.json").read_text()))


def run_rounds(binary, layer, rows, n_rows, n_out):
    g, t = rt.emit_layer_v2(CASE, layer, rows)
    out = subprocess.run([str(binary)], cwd=ROOT, capture_output=True,
                         text=True, timeout=300).stdout
    assert "NPU_TFLM_MODEL_PASS" in out and "0 errors" in out, out
    return rt.unpack_result_v2(CASE / "result.dump", g, t, n_rows, n_out)


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_depthwise_separable_bit_exact_on_rtl(tmp_path):
    model, golden = _load()
    dw, pw = model["layers"]
    assert dw["tag"] == "depthwise" and pw["tag"] == "pointwise"
    # green-wash guards: genuinely per-channel depthwise, K chunked, 1x1 pointwise
    assert len(set(dw["weight_scales"])) > 1, "dw per-channel degenerated"
    assert len(rt._chunks(dw["kh"] * dw["kw"] * dw["cin"])) >= 2, "K=72 must chunk"
    assert pw["kh"] == 1 and pw["kw"] == 1, "pointwise must be 1x1"

    mdir = tmp_path / "obj"
    b = subprocess.run(["verilator", "--binary", "--timing", "-Wno-fatal",
                        "--top-module", "tb_npu_tflm_model", "-Mdir", str(mdir),
                        *CPU_M1_ARGS, *[str(p) for p in RTL + TB]],
                       capture_output=True, text=True)
    binary = mdir / "Vtb_npu_tflm_model"
    assert binary.exists(), f"build failed:\n{b.stdout}\n{b.stderr}"

    # round 1: depthwise (block-diagonal conv), intermediate bit-exact
    rows = rt.im2col(dw, golden["input"][0])
    assert len(rows) == 16 and len(rows[0]) == 72
    dw_rtl = run_rounds(binary, dw, rows, 16, 8)
    dw_exp = [golden["dw"][0][oy][ox] for oy in range(4) for ox in range(4)]
    assert dw_rtl == dw_exp, "depthwise RTL output != interpreter intermediate"

    # round 2: pointwise 1x1 over the ACTUAL RTL depthwise output, final bit-exact
    pw_in = [[dw_rtl[oy * 4 + ox] for ox in range(4)] for oy in range(4)]  # [4][4][8]
    rows2 = rt.im2col(pw, pw_in)
    assert len(rows2) == 16 and len(rows2[0]) == 8
    pw_rtl = run_rounds(binary, pw, rows2, 16, 8)
    pw_exp = [golden["final"][0][oy][ox] for oy in range(4) for ox in range(4)]
    assert pw_rtl == pw_exp, "pointwise RTL output != interpreter final"


def test_dwsep_artifact_provenance_regen(tmp_path):
    env = dict(os.environ,
               LD_LIBRARY_PATH=os.path.join(os.environ.get("CONDA_PREFIX", ""), "lib"))
    probe = subprocess.run([sys.executable, "-c", "import tensorflow"],
                           env=env, capture_output=True)
    if probe.returncode != 0:
        pytest.skip("tensorflow unavailable — provenance not-run")
    src = ROOT / "sim/models"
    work = tmp_path / "aot"
    shutil.copytree(src, work, ignore=shutil.ignore_patterns("artifacts", "__pycache__"))
    r = subprocess.run([sys.executable, str(work / "build_model_dw.py")],
                       env=env, capture_output=True, text=True, timeout=600)
    assert r.returncode == 0, r.stderr[-2000:]
    for f in ("model_dw.json", "golden_dw.json"):
        assert json.loads((work / "artifacts" / f).read_text()) == \
               json.loads((src / "artifacts" / f).read_text()), f"{f} drifted"
    assert (work / "artifacts/dwsep.tflite").read_bytes() == \
           (src / "artifacts/dwsep.tflite").read_bytes(), ".tflite drifted"
