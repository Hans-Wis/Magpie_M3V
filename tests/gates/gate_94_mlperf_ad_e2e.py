"""gate_94_mlperf_ad_e2e — ADR-0064 F1.1: MLPerf Tiny AD (FC autoencoder) on the NPU.

ad.tflite: a deep symmetric fully-connected autoencoder (MLPerf Tiny AD structure) at
representative dims 32-24-16-8-16-24-32 (encoder -> bottleneck 8 -> decoder, fused ReLU
on hidden, int8). Every FC layer is lowered through the existing CQ/mat_engine FC path
(lower_layer_v2) and chained: each layer's RTL output feeds the next layer's input, and
each intermediate + the final reconstruction must equal the BUILTIN_REF interpreter
bit-exact. Proves a deep FC chain through a bottleneck on the RTL — the AD workload.

Full 640-wide MLPerf AD needs a multi-ring driver (single ring = 32 descriptors); the
mechanism (FC chain) is dim-independent. Anomaly score (reconstruction MSE) is host-side.
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

RTL = [ROOT / f"IP/npu/rtl/{m}.v" for m in
       ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine")]
RTL += CPU_M1_RTL
TB = [ROOT / "IP/npu/dv/tb/axi_full_rwmem.v", ROOT / "IP/npu/dv/tb/tb_npu_tflm_model.v"]
CASE = ROOT / "sim/work/tflm_model"
ART = ROOT / "sim/models/artifacts"


def run_layer(binary, layer, rows):
    g, t = rt.emit_layer_v2(CASE, layer, rows)
    out = subprocess.run([str(binary)], cwd=ROOT, capture_output=True,
                         text=True, timeout=300).stdout
    assert "NPU_TFLM_MODEL_PASS" in out and "0 errors" in out, out
    return rt.unpack_result_v2(CASE / "result.dump", g, t, len(rows), layer["n"])


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_mlperf_ad_autoencoder_bit_exact(tmp_path):
    model = json.loads((ART / "model_ad.json").read_text())
    golden = json.loads((ART / "golden_ad.json").read_text())
    layers = model["layers"]
    assert len(layers) == 6 and layers[2]["n"] == 8, "expected 6 FC layers, bottleneck n=8"

    mdir = tmp_path / "obj"
    b = subprocess.run(["verilator", "--binary", "--timing", "-Wno-fatal",
                        "--top-module", "tb_npu_tflm_model", "-Mdir", str(mdir),
                        *CPU_M1_ARGS, *[str(p) for p in RTL + TB]],
                       capture_output=True, text=True)
    binary = mdir / "Vtb_npu_tflm_model"
    assert binary.exists(), f"build failed:\n{b.stdout}\n{b.stderr}"

    # chain the FC layers: each RTL output feeds the next; compare every layer bit-exact
    vec = golden["input"][0]                      # [32] int8
    for i, layer in enumerate(layers):
        out = run_layer(binary, layer, [vec])     # 1 sample -> [1][n]
        exp = golden["inter"][i][0]
        assert out[0] == exp, f"AD layer {i} (n={layer['n']}) RTL != interpreter\n{out[0]}\n{exp}"
        vec = out[0]                              # ACTUAL RTL output chains forward
    assert vec == golden["final"][0], "AD final reconstruction != interpreter"


def test_ad_artifact_provenance_regen(tmp_path):
    env = dict(os.environ, LD_LIBRARY_PATH="/home/edauser/miniforge3/envs/magpie_claude/lib")
    if subprocess.run([sys.executable, "-c", "import tensorflow"],
                      env=env, capture_output=True).returncode != 0:
        pytest.skip("tensorflow unavailable — provenance not-run")
    src = ROOT / "sim/models"
    work = tmp_path / "aot"
    shutil.copytree(src, work, ignore=shutil.ignore_patterns("artifacts", "__pycache__"))
    r = subprocess.run([sys.executable, str(work / "build_model_ad.py")],
                       env=env, capture_output=True, text=True, timeout=600)
    assert r.returncode == 0, r.stderr[-2000:]
    for f in ("model_ad.json", "golden_ad.json"):
        assert json.loads((work / "artifacts" / f).read_text()) == \
               json.loads((src / "artifacts" / f).read_text()), f"{f} drifted"
