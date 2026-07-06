#!/usr/bin/env python3
"""build_model_ad — MLPerf Tiny AD (anomaly detection) offline half (ADR-0064 F1.1).

MLPerf Tiny AD reference = a deep symmetric FULLY-CONNECTED autoencoder (ToyADMOS): the
production model is 640-128-128-128-128-8-128-128-128-128-640 (ReLU hidden, int8). We use
the SAME STRUCTURE (encoder -> bottleneck -> decoder, symmetric, ReLU, int8) at
representative dims 32-24-16-8-16-24-32 that fit the current single-ring CQ runtime (the
640-wide layer = hundreds of descriptors >> 32-entry ring; full-scale needs a multi-ring
driver, backlog). The mechanism proven = a deep FC chain through a bottleneck, which is
config-independent. Anomaly score (reconstruction MSE) is a host scalar op, not the NPU's.

Run:  LD_LIBRARY_PATH=$CONDA_PREFIX/lib python3 build_model_ad.py
"""
import json
from pathlib import Path

import numpy as np
import tensorflow as tf

HERE = Path(__file__).resolve().parent
ART = HERE / "artifacts"
SEED = 20260706
DIMS = [32, 24, 16, 8, 16, 24, 32]     # in -> ... -> bottleneck 8 -> ... -> out


def build_keras():
    rng = np.random.default_rng(SEED)
    inp = tf.keras.Input(shape=(DIMS[0],), batch_size=1, dtype=tf.float32)
    x = inp
    layers = []
    for i, n in enumerate(DIMS[1:]):
        last = (i == len(DIMS) - 2)
        d = tf.keras.layers.Dense(n, activation=(None if last else "relu"),
                                  name=f"fc{i+1}")
        x = d(x)
        layers.append(d)
    m = tf.keras.Model(inp, x)
    for d, (kin, kout) in zip(layers, zip(DIMS[:-1], DIMS[1:])):
        d.set_weights([rng.normal(0, 0.4, (kin, kout)).astype(np.float32),
                       rng.normal(0, 0.2, kout).astype(np.float32)])
    return m


def convert_int8(m):
    rng = np.random.default_rng(SEED + 1)

    def rep():
        for _ in range(64):
            yield [rng.normal(0, 1.0, (1, DIMS[0])).astype(np.float32)]

    c = tf.lite.TFLiteConverter.from_keras_model(m)
    c.optimizations = [tf.lite.Optimize.DEFAULT]
    c.representative_dataset = rep
    c.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    c.inference_input_type = tf.int8
    c.inference_output_type = tf.int8
    return c.convert()


def main():
    ART.mkdir(exist_ok=True)
    tfl = convert_int8(build_keras())
    (ART / "ad.tflite").write_bytes(tfl)

    it = tf.lite.Interpreter(
        model_content=tfl,
        experimental_op_resolver_type=tf.lite.experimental.OpResolverType.BUILTIN_REF,
        experimental_preserve_all_tensors=True)
    it.allocate_tensors()
    tens = {t["index"]: t for t in it.get_tensor_details()}

    def quant(idx):
        q = tens[idx]["quantization_parameters"]
        return [float(s) for s in q["scales"]], [int(z) for z in q["zero_points"]]

    layers, out_idxs = [], []
    n_fc = 0
    for op in it._get_ops_details():
        if op["op_name"] != "FULLY_CONNECTED":
            continue
        in_idx, w_idx, b_idx = [int(i) for i in op["inputs"][:3]]
        out_idx = int(op["outputs"][0])
        w = it.get_tensor(w_idx)
        b = it.get_tensor(b_idx)
        ws, wz = quant(w_idx)
        is_, iz = quant(in_idx)
        os_, oz = quant(out_idx)
        assert all(z == 0 for z in wz) and len(is_) == 1 and len(os_) == 1
        n_fc += 1
        relu = (n_fc != len(DIMS) - 1)          # every hidden fc is fused-ReLU; output is not
        layers.append(dict(
            kind="fc", k=int(w.shape[1]), n=int(w.shape[0]), relu=relu,
            weights=w.astype(int).tolist(), bias=b.astype(int).tolist(),
            input_zp=iz[0], input_scale=is_[0], output_scale=os_[0], output_zp=oz[0],
            weight_scales=(ws if len(ws) == w.shape[0] else ws * w.shape[0]),
            out_tensor=out_idx))
        out_idxs.append(out_idx)
    assert len(layers) == len(DIMS) - 1, f"expected {len(DIMS)-1} FC layers, got {len(layers)}"

    rng = np.random.default_rng(SEED + 2)
    x = rng.integers(-128, 128, (1, DIMS[0]), dtype=np.int8)
    it.set_tensor(it.get_input_details()[0]["index"], x)
    it.invoke()
    inter = [it.get_tensor(i).astype(int).tolist() for i in out_idxs]
    final = it.get_tensor(it.get_output_details()[0]["index"]).astype(int).tolist()

    (ART / "model_ad.json").write_text(json.dumps(dict(source="ad.tflite", dims=DIMS,
                                                       seed=SEED, layers=layers)))
    (ART / "golden_ad.json").write_text(json.dumps(dict(
        input=x.astype(int).tolist(), inter=inter, final=final)))
    print(f"AD autoencoder: {len(layers)} FC layers, dims {DIMS}")
    print("final (reconstruction):", final[0][:8], "...")


if __name__ == "__main__":
    main()
