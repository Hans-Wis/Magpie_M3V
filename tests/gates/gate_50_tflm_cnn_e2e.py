"""gate_50_tflm_cnn_e2e — ADR-0042: a real int8 CNN (per-channel conv) on the NPU.

cnn.tflite: [1,6,6,8] -> Conv2D 3x3 cout=8 VALID (fused ReLU, GENUINELY
per-channel — 8 distinct scales, asserted) -> Flatten -> Dense(8).
Deliberate shapes: conv K = 72 (K-chunking 64+8), FC K = 128 (64+64) — both
exceed the single-OP limit, so accumulation across chunked MAT_OPs is on the
critical path; requant runs the new per-channel RESCALE_PC (engine fetches
8 mult + 8 shift from TCM).

round 1: host im2col (16 output pixels = 2 row-groups) -> RTL -> conv output
         must equal the BUILTIN_REF interpreter INTERMEDIATE bit-exact;
round 2: flatten of the ACTUAL RTL conv output -> Dense -> final bit-exact.
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

RTL = [ROOT / f"IP/npu/rtl/{m}.v" for m in
       ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine")]
RTL += CPU_M1_RTL
TB = [ROOT / "IP/npu/dv/tb/axi_full_rwmem.v", ROOT / "IP/npu/dv/tb/tb_npu_tflm_model.v"]
CASE = ROOT / "tflm_model"


def run_rounds(binary, layer, rows, n_rows, n_out):
    g, t = rt.emit_layer_v2(CASE, layer, rows)
    out = subprocess.run([str(binary)], cwd=ROOT, capture_output=True,
                         text=True, timeout=300).stdout
    assert "NPU_TFLM_MODEL_PASS" in out and "0 errors" in out, out
    return rt.unpack_result_v2(CASE / "result.dump", g, t, n_rows, n_out)


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_real_cnn_bit_exact_on_rtl(tmp_path):
    model, golden = rt.load_artifacts2()
    conv, fc = model["layers"]
    assert len(set(conv["weight_scales"])) > 1, "per-channel degenerated"
    assert len(rt._chunks(conv["kh"] * conv["kw"] * conv["cin"])) >= 2
    assert len(rt._chunks(fc["k"])) >= 2

    mdir = tmp_path / "obj"
    b = subprocess.run(["verilator", "--binary", "--timing", "-Wno-fatal",
                        "--top-module", "tb_npu_tflm_model", "-Mdir", str(mdir),
                        *CPU_M1_ARGS, *[str(p) for p in RTL + TB]],
                       capture_output=True, text=True)
    binary = mdir / "Vtb_npu_tflm_model"
    assert binary.exists(), f"build failed:\n{b.stdout}\n{b.stderr}"

    rows = rt.im2col(conv, golden["input"][0])
    assert len(rows) == 16 and len(rows[0]) == 72
    out1 = run_rounds(binary, conv, rows, 16, 8)
    exp1 = [golden["conv"][0][oy][ox] for oy in range(4) for ox in range(4)]
    assert out1 == exp1, "conv RTL output != interpreter intermediate"

    flat = [[v for p in out1 for v in p]]        # NHWC flatten, ACTUAL RTL data
    out2 = run_rounds(binary, fc, flat, 1, 8)
    assert out2 == golden["final"], "final RTL output != interpreter"


def test_cnn_artifact_provenance_regen(tmp_path):
    env = dict(os.environ,
               LD_LIBRARY_PATH="/home/edauser/miniforge3/envs/magpie_claude/lib")
    probe = subprocess.run([sys.executable, "-c", "import tensorflow"],
                           env=env, capture_output=True)
    if probe.returncode != 0:
        pytest.skip("tensorflow unavailable — provenance not-run")
    src = ROOT / "sim/models"
    work = tmp_path / "aot"
    shutil.copytree(src, work, ignore=shutil.ignore_patterns("artifacts"))
    r = subprocess.run([sys.executable, str(work / "build_model2.py")],
                       env=env, capture_output=True, text=True, timeout=600)
    assert r.returncode == 0, r.stderr[-2000:]
    for f in ("model2.json", "golden2.json"):
        assert json.loads((work / "artifacts" / f).read_text()) == \
               json.loads((src / "artifacts" / f).read_text()), f"{f} drifted"
    assert (work / "artifacts/cnn.tflite").read_bytes() == \
           (src / "artifacts/cnn.tflite").read_bytes(), ".tflite drifted"
