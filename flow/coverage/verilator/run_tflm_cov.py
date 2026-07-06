#!/usr/bin/env python3
"""run_tflm_cov — ADR-0063 V5: drive the tflm coverage DUT over the offload layers
(dwsep DW+PW, cnn conv+FC) to exercise mat_engine / npu_dma / npu_axil_regs / CQ.
Run after building obj_tflm/Vcov_tflm. Collects one coverage.dat per layer into dats/."""
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "IP/npu/sw/tflm_aot"))
sys.path.insert(0, str(ROOT / "IP/npu/sw"))
import tflm_runtime as rt  # noqa: E402

CASE = ROOT / "tflm_model"
COVBIN = ROOT / "flow/coverage/verilator/obj_tflm/Vcov_tflm"
DATS = ROOT / "flow/coverage/verilator/dats"
ART = ROOT / "IP/npu/sw/tflm_aot/artifacts"


def run_layer(tag, layer, rows):
    rt.emit_layer_v2(CASE, layer, rows)
    (ROOT / "coverage.dat").unlink(missing_ok=True)
    subprocess.run([str(COVBIN)], cwd=ROOT, capture_output=True, timeout=300)
    d = ROOT / "coverage.dat"
    if d.exists():
        d.replace(DATS / f"tflm_{tag}.dat")
        print(f"  tflm_{tag}: collected")


def main():
    DATS.mkdir(exist_ok=True)
    mdw = json.loads((ART / "model_dw.json").read_text())
    gdw = json.loads((ART / "golden_dw.json").read_text())
    dw, pw = mdw["layers"]
    run_layer("dw", dw, rt.im2col(dw, gdw["input"][0]))
    dwo = [gdw["dw"][0][oy][ox] for oy in range(4) for ox in range(4)]
    run_layer("pw", pw, rt.im2col(pw, [[dwo[oy * 4 + ox] for ox in range(4)] for oy in range(4)]))
    m2 = json.loads((ART / "model2.json").read_text())
    g2 = json.loads((ART / "golden2.json").read_text())
    conv, fc = m2["layers"]
    run_layer("cnn_conv", conv, rt.im2col(conv, g2["input"][0]))
    co = [g2["conv"][0][oy][ox] for oy in range(4) for ox in range(4)]
    run_layer("cnn_fc", fc, [[v for p in co for v in p]])


if __name__ == "__main__":
    main()
