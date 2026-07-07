"""gate_96_stride2_conv_e2e — ADR-0065 (F1.4): a STRIDE-2 SAME int8 conv on the NPU.

cnn_s2.tflite: [1,6,6,8] -> Conv2D 3x3 cout=8 stride=2 padding=SAME (fused ReLU,
per-channel) -> [1,3,3,8] -> Flatten -> Dense(8).

The thesis (Grok-reviewed, 2026-07-06): stride + SAME padding are PURELY an im2col
(software gather) change — the mat_engine / CQ / DMA never see stride, so this is
zero-RTL and circuit-sufficient. This gate proves it end-to-end, bit-exact vs real
BUILTIN_REF TFLM inference, through the SAME mat_engine RTL that gate_50 (stride-1)
uses. Green-wash guards (Grok #1-#9) ensure the test cannot silently reduce to
stride-1 or fake the equivalence.
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


def run_rounds(binary, layer, rows, n_rows, n_out):
    g, t = rt.emit_layer_v2(CASE, layer, rows)
    out = subprocess.run([str(binary)], cwd=ROOT, capture_output=True,
                         text=True, timeout=300).stdout
    assert "NPU_TFLM_MODEL_PASS" in out and "0 errors" in out, out
    return rt.unpack_result_v2(CASE / "result.dump", g, t, n_rows, n_out)


def test_stride2_conv_geometry_and_sampling():
    # Guards #1-#3,#6,#8 — configuration + geometry + strided-sampling locks (no RTL needed).
    model, golden = rt.load_artifacts_s2()
    conv = model["layers"][0]
    assert conv["stride"] == 2 and conv["padding"] == "same", "not a stride-2 SAME conv (#1)"
    assert conv["input_zp"] != 0, "input_zp==0 — pad-with-zp path not exercised (#6)"

    oh, ow, pt, pl = rt.conv_out_geometry(conv)
    assert (oh, ow) == (3, 3), f"stride-2 SAME on 6x6/K3 must be 3x3, got {oh}x{ow} (#2)"
    total_h = max((oh - 1) * conv["stride"] + conv["kh"] - conv["in_h"], 0)
    assert pt != total_h - pt, "SAME pad must be asymmetric (top != bottom) here (#5)"

    rows = rt.im2col(conv, golden["input"][0])
    assert len(rows) == oh * ow == 9, f"row count must be oh*ow=9, got {len(rows)} (#3)"
    # a stride-1 lowering of the same tensor would yield 16 (VALID) or 36 (SAME) rows:
    assert len(rows) not in (16, 36), "row count collapsed to a stride-1 count (#3)"

    # #8 intermediate spot-check: bottom pixel (oy=2) reads iy in {4,5,6}; iy=6 is OOB ->
    # padded with input_zp; iy=4 taps must equal the raw input. Proves strided + input_zp pad.
    x, izp, kw, cin = golden["input"][0], conv["input_zp"], conv["kw"], conv["cin"]
    row = rows[2 * ow + 0]
    assert all(row[(2 * kw + kx) * cin + ci] == izp for kx in range(kw) for ci in range(cin)), \
        "bottom-padding taps are not input_zp (#8)"
    assert all(row[(0 * kw + kx) * cin + ci] == x[4][kx][ci] for kx in range(kw) for ci in range(cin)), \
        "in-bounds taps do not match strided input sample (#8)"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_stride2_conv_bit_exact_on_rtl(tmp_path):
    # Guards #4,#7 — bit-exact vs real TFLM through the REAL mat_engine (no DPI stub).
    model, golden = rt.load_artifacts_s2()
    conv, fc = model["layers"]
    assert conv["stride"] == 2 and conv["padding"] == "same"
    assert len(set(conv["weight_scales"])) > 1, "per-channel degenerated"
    assert len(rt._chunks(conv["kh"] * conv["kw"] * conv["cin"])) >= 2, "K-chunking not exercised"

    mdir = tmp_path / "obj"
    b = subprocess.run(["verilator", "--binary", "--timing", "-Wno-fatal",
                        "--top-module", "tb_npu_tflm_model", "-Mdir", str(mdir),
                        *CPU_M1_ARGS, *[str(p) for p in RTL + TB]],
                       capture_output=True, text=True)
    binary = mdir / "Vtb_npu_tflm_model"
    assert binary.exists(), f"build failed:\n{b.stdout}\n{b.stderr}"

    oh, ow, _, _ = rt.conv_out_geometry(conv)
    rows = rt.im2col(conv, golden["input"][0])
    assert len(rows) == 9 and len(rows[0]) == 72
    out1 = run_rounds(binary, conv, rows, 9, 8)
    exp1 = [golden["conv"][0][oy][ox] for oy in range(oh) for ox in range(ow)]
    assert out1 == exp1, "stride-2 conv RTL output != TFLM interpreter intermediate (#4)"

    # round 2: flatten the ACTUAL RTL conv output -> Dense -> final bit-exact.
    flat = [[v for p in out1 for v in p]]
    out2 = run_rounds(binary, fc, flat, 1, 8)
    assert out2 == golden["final"], "final RTL output != TFLM interpreter (#4)"


def test_stride2_artifact_provenance_regen(tmp_path):
    # #9 provenance: TF regen must reproduce the artifacts byte/JSON-exact.
    env = dict(os.environ,
               LD_LIBRARY_PATH=os.path.join(os.environ.get("CONDA_PREFIX", ""), "lib"))
    probe = subprocess.run([sys.executable, "-c", "import tensorflow"],
                           env=env, capture_output=True)
    if probe.returncode != 0:
        pytest.skip("tensorflow unavailable — provenance not-run")
    src = ROOT / "sim/models"
    work = tmp_path / "aot"
    shutil.copytree(src, work, ignore=shutil.ignore_patterns("artifacts"))
    r = subprocess.run([sys.executable, str(work / "build_model_stride2.py")],
                       env=env, capture_output=True, text=True, timeout=600)
    assert r.returncode == 0, r.stderr[-2000:]
    for f in ("model_s2.json", "golden_s2.json"):
        assert json.loads((work / "artifacts" / f).read_text()) == \
               json.loads((src / "artifacts" / f).read_text()), f"{f} drifted"
    assert (work / "artifacts/cnn_s2.tflite").read_bytes() == \
           (src / "artifacts/cnn_s2.tflite").read_bytes(), ".tflite drifted"
