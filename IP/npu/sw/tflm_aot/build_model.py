#!/usr/bin/env python3
"""build_model — ADR-0041 offline half: Keras -> full-int8 .tflite -> neutral
model.json + authoritative golden vectors (TFLite Interpreter forced onto
REFERENCE kernels == TFLM semantics, all tensors preserved).

TF only runs HERE (offline, like Coral's edgetpu_compiler). The online half
(tflm_runtime.py + gate_49) consumes the checked-in artifacts and never
imports TF. Deterministic: fixed seeds, fixed representative dataset.

Run:  LD_LIBRARY_PATH=$CONDA_PREFIX/lib python3 build_model.py
"""
import json
from pathlib import Path

import numpy as np
import tensorflow as tf

HERE = Path(__file__).resolve().parent
ART = HERE / "artifacts"
SEED = 20260704


def build_keras():
    rng = np.random.default_rng(SEED)
    inp = tf.keras.Input(shape=(16,), batch_size=8, dtype=tf.float32)
    d1 = tf.keras.layers.Dense(24, activation="relu", name="fc1")
    d2 = tf.keras.layers.Dense(8, name="fc2")
    out = d2(d1(inp))
    m = tf.keras.Model(inp, out)
    d1.set_weights([rng.normal(0, 0.5, (16, 24)).astype(np.float32),
                    rng.normal(0, 0.3, 24).astype(np.float32)])
    d2.set_weights([rng.normal(0, 0.5, (24, 8)).astype(np.float32),
                    rng.normal(0, 0.3, 8).astype(np.float32)])
    return m


def convert_int8(m):
    rng = np.random.default_rng(SEED + 1)

    def rep():
        for _ in range(64):
            yield [rng.normal(0, 1.0, (8, 16)).astype(np.float32)]

    c = tf.lite.TFLiteConverter.from_keras_model(m)
    c.optimizations = [tf.lite.Optimize.DEFAULT]
    c.representative_dataset = rep
    c.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    c.inference_input_type = tf.int8
    c.inference_output_type = tf.int8
    # ADR-0041 scope: per-tensor weights (engine RESCALE is per-tile);
    # per-channel support = future work, honest raise otherwise.
    c._experimental_disable_per_channel = True
    return c.convert()


def main():
    ART.mkdir(exist_ok=True)
    tfl = convert_int8(build_keras())
    (ART / "dense2.tflite").write_bytes(tfl)

    it = tf.lite.Interpreter(
        model_content=tfl,
        experimental_op_resolver_type=tf.lite.experimental.OpResolverType.BUILTIN_REF,
        experimental_preserve_all_tensors=True)
    it.allocate_tensors()
    tens = {t["index"]: t for t in it.get_tensor_details()}
    ops = it._get_ops_details()  # offline-only private API; provenance-guarded

    def quant(idx):
        q = tens[idx]["quantization_parameters"]
        scales = [float(s) for s in q["scales"]]
        zps = [int(z) for z in q["zero_points"]]
        return scales, zps

    layers = []
    for op in ops:
        if op["op_name"] != "FULLY_CONNECTED":
            continue
        in_idx, w_idx, b_idx = [int(i) for i in op["inputs"][:3]]
        out_idx = int(op["outputs"][0])
        w = it.get_tensor(w_idx)            # [n_out, k] int8
        b = it.get_tensor(b_idx)            # [n_out] int32
        ws, wz = quant(w_idx)
        is_, iz = quant(in_idx)
        os_, oz = quant(out_idx)
        assert all(z == 0 for z in wz), "int8 FC filters must have zp 0"
        assert len(is_) == 1 and len(os_) == 1, "per-tensor act quant expected"
        # exact per-tensor enforcement — allclose would silently collapse a
        # genuinely per-channel model into one scale (Codex finding #2)
        assert all(x == ws[0] for x in ws), "per-channel weight scales (scope)"
        layers.append(dict(
            name=tens[out_idx]["name"], k=int(w.shape[1]), n=int(w.shape[0]),
            weights=w.astype(int).tolist(), bias=b.astype(int).tolist(),
            input_scale=is_[0], input_zp=iz[0],
            weight_scale=ws[0], output_scale=os_[0], output_zp=oz[0],
            in_tensor=in_idx, out_tensor=out_idx))
    assert len(layers) == 2, f"expected 2 FC layers, got {len(layers)}"
    # fused activation: recover the clamp from the reference run below by
    # recording it explicitly — fc1 has fused RELU, fc2 none (model truth).
    layers[0]["relu"] = True
    layers[1]["relu"] = False

    # authoritative golden: int8 input -> per-layer int8 tensors
    rng = np.random.default_rng(SEED + 2)
    x_i8 = rng.integers(-128, 128, (8, 16), dtype=np.int8)
    in_det = it.get_input_details()[0]
    it.set_tensor(in_det["index"], x_i8)
    it.invoke()
    inter1 = it.get_tensor(layers[0]["out_tensor"]).astype(int).tolist()
    final = it.get_tensor(it.get_output_details()[0]["index"]).astype(int).tolist()

    model = dict(source="dense2.tflite", seed=SEED, batch=8, layers=layers)
    (ART / "model.json").write_text(json.dumps(model))
    (ART / "golden.json").write_text(json.dumps(dict(
        input=x_i8.astype(int).tolist(), layer1=inter1, final=final)))
    print("layers:", [(l["name"], l["k"], l["n"], l["relu"]) for l in layers])
    print("golden final row0:", final[0])


if __name__ == "__main__":
    main()
