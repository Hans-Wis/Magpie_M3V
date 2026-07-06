#!/usr/bin/env python3
"""build_model2 — ADR-0042 offline half: tiny int8 CNN with PER-CHANNEL conv.

[1,6,6,8] -> Conv2D 3x3 cout=8 VALID stride1 (fused ReLU, per-channel) ->
[1,4,4,8] -> Flatten -> Dense(8) -> [1,8].
Deliberate shapes: conv K = 3*3*8 = 72 (K-chunking 64+8), FC K = 128 (64+64),
conv weights per-channel quantized (the TFLite default we previously disabled).

Run:  LD_LIBRARY_PATH=$CONDA_PREFIX/lib python3 build_model2.py
"""
import json
from pathlib import Path

import numpy as np
import tensorflow as tf

HERE = Path(__file__).resolve().parent
ART = HERE / "artifacts"
SEED = 20260705


def build_keras():
    rng = np.random.default_rng(SEED)
    inp = tf.keras.Input(shape=(6, 6, 8), batch_size=1, dtype=tf.float32)
    cv = tf.keras.layers.Conv2D(8, 3, padding="valid", activation="relu", name="cv1")
    fc = tf.keras.layers.Dense(8, name="fc")
    out = fc(tf.keras.layers.Flatten()(cv(inp)))
    m = tf.keras.Model(inp, out)
    cv.set_weights([rng.normal(0, 0.4, (3, 3, 8, 8)).astype(np.float32),
                    rng.normal(0, 0.2, 8).astype(np.float32)])
    fc.set_weights([rng.normal(0, 0.4, (128, 8)).astype(np.float32),
                    rng.normal(0, 0.2, 8).astype(np.float32)])
    return m


def convert_int8(m):
    rng = np.random.default_rng(SEED + 1)

    def rep():
        for _ in range(64):
            yield [rng.normal(0, 1.0, (1, 6, 6, 8)).astype(np.float32)]

    c = tf.lite.TFLiteConverter.from_keras_model(m)
    c.optimizations = [tf.lite.Optimize.DEFAULT]
    c.representative_dataset = rep
    c.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    c.inference_input_type = tf.int8
    c.inference_output_type = tf.int8
    return c.convert()          # per-channel stays ON (TFLite default)


def main():
    ART.mkdir(exist_ok=True)
    tfl = convert_int8(build_keras())
    (ART / "cnn.tflite").write_bytes(tfl)

    it = tf.lite.Interpreter(
        model_content=tfl,
        experimental_op_resolver_type=tf.lite.experimental.OpResolverType.BUILTIN_REF,
        experimental_preserve_all_tensors=True)
    it.allocate_tensors()
    tens = {t["index"]: t for t in it.get_tensor_details()}

    def quant(idx):
        q = tens[idx]["quantization_parameters"]
        return [float(s) for s in q["scales"]], [int(z) for z in q["zero_points"]]

    layers = []
    for op in it._get_ops_details():
        if op["op_name"] not in ("CONV_2D", "FULLY_CONNECTED"):
            continue
        in_idx, w_idx, b_idx = [int(i) for i in op["inputs"][:3]]
        out_idx = int(op["outputs"][0])
        w = it.get_tensor(w_idx)
        b = it.get_tensor(b_idx)
        ws, wz = quant(w_idx)
        is_, iz = quant(in_idx)
        os_, oz = quant(out_idx)
        assert all(z == 0 for z in wz)
        assert len(is_) == 1 and len(os_) == 1
        if op["op_name"] == "CONV_2D":
            # w: [cout, kh, kw, cin] -> flat [cout][kh*kw*cin] (im2col k-order)
            cout, kh, kw, cin = w.shape
            wf = w.reshape(cout, kh * kw * cin)
            layers.append(dict(
                kind="conv", kh=kh, kw=kw, cin=cin, cout=cout, stride=1,
                in_h=6, in_w=6, relu=True,
                weights=wf.astype(int).tolist(), bias=b.astype(int).tolist(),
                input_zp=iz[0], input_scale=is_[0], output_scale=os_[0],
                output_zp=oz[0],
                weight_scales=(ws if len(ws) == cout else ws * cout),
                out_tensor=out_idx))
        else:
            layers.append(dict(
                kind="fc", k=int(w.shape[1]), n=int(w.shape[0]), relu=False,
                weights=w.astype(int).tolist(), bias=b.astype(int).tolist(),
                input_zp=iz[0], input_scale=is_[0], output_scale=os_[0],
                output_zp=oz[0],
                weight_scales=(ws if len(ws) == w.shape[0] else ws * w.shape[0]),
                out_tensor=out_idx))
    assert len(layers) == 2 and layers[0]["kind"] == "conv"
    # green-wash guard: conv must be GENUINELY per-channel
    assert len(set(layers[0]["weight_scales"])) > 1, "conv scales degenerate"

    rng = np.random.default_rng(SEED + 2)
    x = rng.integers(-128, 128, (1, 6, 6, 8), dtype=np.int8)
    it.set_tensor(it.get_input_details()[0]["index"], x)
    it.invoke()
    conv_out = it.get_tensor(layers[0]["out_tensor"])   # [1,4,4,8]
    final = it.get_tensor(it.get_output_details()[0]["index"])

    (ART / "model2.json").write_text(json.dumps(
        dict(source="cnn.tflite", seed=SEED, layers=layers)))
    (ART / "golden2.json").write_text(json.dumps(dict(
        input=x.astype(int).tolist(),
        conv=conv_out.astype(int).tolist(),
        final=final.astype(int).tolist())))
    print("conv scales distinct:", len(set(layers[0]["weight_scales"])))
    print("golden final:", final.astype(int).tolist())


if __name__ == "__main__":
    main()
