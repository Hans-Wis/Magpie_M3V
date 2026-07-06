#!/usr/bin/env python3
"""build_model_stride2 — ADR-0065 offline half: int8 CNN with a STRIDE-2 SAME conv.

[1,6,6,8] -> Conv2D 3x3 cout=8 stride=2 padding=SAME (fused ReLU, per-channel) ->
[1,3,3,8] -> Flatten -> Dense(8) -> [1,8].

Deliberate to exercise the F1.4 strided-im2col path with the hard TFLM cases:
- stride=2 SAME on even H/W=6, K=3 -> oh=ceil(6/2)=3, pad_total=1 -> ASYMMETRIC
  split pad_top=0/pad_bottom=1 (Grok pitfall: TF distributes pad unevenly).
- representative data is ASYMMETRIC so input_zp != 0 (padding-with-input_zp only
  bites when zp!=0 — Grok green-wash guard #6).
- conv K = 3*3*8 = 72 (K-chunking 64+8), per-channel weight scales (8 distinct).
The golden is real BUILTIN_REF TFLM inference (stride-2 conv) — bit-exact target.

Run:  LD_LIBRARY_PATH=$CONDA_PREFIX/lib python3 build_model_stride2.py
"""
import json
from pathlib import Path

import numpy as np
import tensorflow as tf

HERE = Path(__file__).resolve().parent
ART = HERE / "artifacts"
SEED = 20260706


def build_keras():
    rng = np.random.default_rng(SEED)
    inp = tf.keras.Input(shape=(6, 6, 8), batch_size=1, dtype=tf.float32)
    cv = tf.keras.layers.Conv2D(8, 3, strides=2, padding="same",
                                activation="relu", name="cv2s")
    fc = tf.keras.layers.Dense(8, name="fc")
    out = fc(tf.keras.layers.Flatten()(cv(inp)))
    m = tf.keras.Model(inp, out)
    cv.set_weights([rng.normal(0, 0.4, (3, 3, 8, 8)).astype(np.float32),
                    rng.normal(0, 0.2, 8).astype(np.float32)])
    fc.set_weights([rng.normal(0, 0.4, (72, 8)).astype(np.float32),
                    rng.normal(0, 0.2, 8).astype(np.float32)])
    return m


def convert_int8(m):
    rng = np.random.default_rng(SEED + 1)

    def rep():
        # ASYMMETRIC range [-1, 5] -> input_zp != 0 (exercises pad-with-input_zp)
        for _ in range(64):
            yield [rng.uniform(-1.0, 5.0, (1, 6, 6, 8)).astype(np.float32)]

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
    (ART / "cnn_s2.tflite").write_bytes(tfl)

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
            cout, kh, kw, cin = w.shape          # tflite CONV_2D w = [cout,kh,kw,cin]
            wf = w.reshape(cout, kh * kw * cin)   # k-order ky,kx,ci (matches im2col)
            layers.append(dict(
                kind="conv", kh=kh, kw=kw, cin=cin, cout=cout,
                stride=2, padding="same",         # F1.4: strided + SAME (ADR-0065)
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
    conv = layers[0]
    # green-wash guards baked into the artifact:
    assert conv["stride"] == 2 and conv["padding"] == "same", "not a stride-2 SAME conv"
    assert conv["input_zp"] != 0, "input_zp==0 — pad-with-zp path not exercised (raise rep asymmetry)"
    assert len(set(conv["weight_scales"])) > 1, "conv scales degenerate (not per-channel)"

    rng = np.random.default_rng(SEED + 2)
    x = rng.integers(-128, 128, (1, 6, 6, 8), dtype=np.int8)
    it.set_tensor(it.get_input_details()[0]["index"], x)
    it.invoke()
    conv_out = it.get_tensor(conv["out_tensor"])              # [1,3,3,8]
    final = it.get_tensor(it.get_output_details()[0]["index"])
    assert list(conv_out.shape) == [1, 3, 3, 8], f"stride-2 SAME shape wrong: {conv_out.shape}"

    (ART / "model_s2.json").write_text(json.dumps(
        dict(source="cnn_s2.tflite", seed=SEED, layers=layers)))
    (ART / "golden_s2.json").write_text(json.dumps(dict(
        input=x.astype(int).tolist(),
        conv=conv_out.astype(int).tolist(),
        final=final.astype(int).tolist())))
    print("input_zp:", conv["input_zp"], "conv shape:", list(conv_out.shape),
          "scales distinct:", len(set(conv["weight_scales"])))
    print("golden final:", final.astype(int).tolist())


if __name__ == "__main__":
    main()
