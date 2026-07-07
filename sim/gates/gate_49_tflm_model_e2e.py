"""gate_49_tflm_model_e2e — ADR-0041: a REAL .tflite model runs on the NPU.

The checked-in AOT artifacts (dense2.tflite -> model.json + golden.json, built
offline by build_model.py with the TFLite REFERENCE interpreter as authority)
are lowered layer-by-layer by tflm_runtime.py (SSOT codec only, no TF) and run
on the full RTL offload loop:

  round 1: fc1 (16->24, fused ReLU, 3 column tiles, 14 descriptors) — the RTL
           output must equal the interpreter's INTERMEDIATE tensor bit-exact
           (guard: never compare only the final value);
  round 2: fc2 (24->8) fed with fc1's ACTUAL RTL OUTPUT (host repack — true
           multi-op chaining through shared memory) — final output must equal
           the interpreter's model output bit-exact.

Provenance: with TF available, rebuilding the artifacts must reproduce the
checked-in golden (skip -> honest not-run when TF is absent). Scope guards:
left-shift requant multiplier raises; ring capacity asserted.
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


def run_layer(binary, layer, inputs):
    n_tiles = rt.emit_layer(CASE, layer, inputs)
    out = subprocess.run([str(binary)], cwd=ROOT, capture_output=True,
                         text=True, timeout=300).stdout
    assert "NPU_TFLM_MODEL_PASS" in out and "0 errors" in out, out
    return rt.unpack_result(CASE / "result.dump", n_tiles, layer["n"])


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_real_tflite_model_bit_exact_on_rtl(tmp_path):
    model, golden = rt.load_artifacts()
    mdir = tmp_path / "obj"
    b = subprocess.run(["verilator", "--binary", "--timing", "-Wno-fatal",
                        "--top-module", "tb_npu_tflm_model", "-Mdir", str(mdir),
                        *CPU_M1_ARGS, *[str(p) for p in RTL + TB]],
                       capture_output=True, text=True)
    binary = mdir / "Vtb_npu_tflm_model"
    assert binary.exists(), f"build failed:\n{b.stdout}\n{b.stderr}"

    l1, l2 = model["layers"]
    out1 = run_layer(binary, l1, golden["input"])
    assert out1 == golden["layer1"], "fc1 RTL output != interpreter intermediate"

    out2 = run_layer(binary, l2, out1)   # chained from ACTUAL RTL output
    assert out2 == golden["final"], "fc2 RTL output != interpreter final"


def test_runtime_scope_guards():
    with pytest.raises(ValueError):
        rt.quantize_multiplier(2.0)          # left shift — must not silently pass
    q31, s = rt.quantize_multiplier(0.25)
    assert q31 == 1 << 30 and s == -1
    assert rt.quantize_multiplier(1e-12) == (0, 0)   # TFLite flush-to-zero


def test_artifact_provenance_regen(tmp_path):
    env = dict(os.environ,
               LD_LIBRARY_PATH=os.path.join(os.environ.get("CONDA_PREFIX", ""), "lib"))
    probe = subprocess.run([sys.executable, "-c", "import tensorflow"],
                           env=env, capture_output=True)
    if probe.returncode != 0:
        pytest.skip("tensorflow unavailable — provenance not-run")
    src = ROOT / "sim/models"
    work = tmp_path / "aot"
    shutil.copytree(src, work, ignore=shutil.ignore_patterns("artifacts"))
    r = subprocess.run([sys.executable, str(work / "build_model.py")],
                       env=env, capture_output=True, text=True, timeout=600)
    assert r.returncode == 0, r.stderr[-2000:]
    for f in ("model.json", "golden.json"):
        assert json.loads((work / "artifacts" / f).read_text()) == \
               json.loads((src / "artifacts" / f).read_text()), f"{f} drifted"
    assert (work / "artifacts/dense2.tflite").read_bytes() == \
           (src / "artifacts/dense2.tflite").read_bytes(), ".tflite drifted"
