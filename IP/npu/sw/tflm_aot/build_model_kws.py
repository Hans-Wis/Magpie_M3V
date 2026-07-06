#!/usr/bin/env python3
"""build_model_kws — MLPerf Tiny KWS (DS-CNN) offline half (ADR-0064 F1.3).

MLPerf Tiny KWS reference = DS-CNN: a regular Conv2D (stride-2) + N depthwise-separable
blocks (DepthwiseConv 3x3 + Pointwise 1x1) + global-avg-pool + Dense. We prove the
DS-CNN MECHANISM = a multi-layer heterogeneous chain (regular conv -> depthwise-separable
block -> FC head) composing e2e bit-exact, at stride-1 VALID representative dims. The
production stride-2 first conv is the same im2col gap as VWW/ResNet (F1.4 backlog); global
avg-pool is a Phase-A RVV op not yet chained (host flatten->FC head here). Depthwise is
the block-diagonal conv trick (ADR-0061).

  [6,6,8] -Conv2D 3x3 (8,relu)-> [4,4,8] -DepthwiseConv2D 3x3 (relu)-> [2,2,8]
          -Conv2D 1x1 (8,relu)-> [2,2,8] -Flatten-> [32] -Dense(8)-> [8]

Run:  LD_LIBRARY_PATH=$CONDA_PREFIX/lib python3 build_model_kws.py
"""
import json
from pathlib import Path

import numpy as np
import tensorflow as tf

from build_model_dw import _dw_block_diagonal   # reuse the depthwise block-diagonal repack

HERE = Path(__file__).resolve().parent
ART = HERE / "artifacts"
SEED = 20260706


def build_keras():
    rng = np.random.default_rng(SEED)
    inp = tf.keras.Input(shape=(6, 6, 8), batch_size=1, dtype=tf.float32)
    cv = tf.keras.layers.Conv2D(8, 3, padding="valid", activation="relu", name="cv")
    dw = tf.keras.layers.DepthwiseConv2D(3, padding="valid", activation="relu", name="dw")
    pw = tf.keras.layers.Conv2D(8, 1, padding="valid", activation="relu", name="pw")
    fc = tf.keras.layers.Dense(8, name="fc")
    out = fc(tf.keras.layers.Flatten()(pw(dw(cv(inp)))))
    m = tf.keras.Model(inp, out)
    cv.set_weights([rng.normal(0, 0.4, (3, 3, 8, 8)).astype(np.float32),
                    rng.normal(0, 0.2, 8).astype(np.float32)])
    dw.set_weights([rng.normal(0, 0.5, (3, 3, 8, 1)).astype(np.float32),
                    rng.normal(0, 0.2, 8).astype(np.float32)])
    pw.set_weights([rng.normal(0, 0.4, (1, 1, 8, 8)).astype(np.float32),
                    rng.normal(0, 0.2, 8).astype(np.float32)])
    fc.set_weights([rng.normal(0, 0.4, (32, 8)).astype(np.float32),
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
    return c.convert()


def _common(w_idx, in_idx, out_idx, quant):
    ws, wz = quant(w_idx)
    is_, iz = quant(in_idx)
    os_, oz = quant(out_idx)
    assert all(z == 0 for z in wz) and len(is_) == 1 and len(os_) == 1
    return ws, is_[0], iz[0], os_[0], oz[0]


def main():
    ART.mkdir(exist_ok=True)
    tfl = convert_int8(build_keras())
    (ART / "kws.tflite").write_bytes(tfl)

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
    in_hw = [6, 4, 2, None]     # conv input H/W per op (fc has none)
    hw_i = 0
    for op in it._get_ops_details():
        name = op["op_name"]
        if name not in ("CONV_2D", "DEPTHWISE_CONV_2D", "FULLY_CONNECTED"):
            continue
        in_idx, w_idx, b_idx = [int(i) for i in op["inputs"][:3]]
        out_idx = int(op["outputs"][0])
        w = it.get_tensor(w_idx)
        b = it.get_tensor(b_idx)
        ws, is_, iz, os_, oz = _common(w_idx, in_idx, out_idx, quant)
        common = dict(input_zp=iz, input_scale=is_, output_scale=os_, output_zp=oz,
                      bias=b.astype(int).tolist(), out_tensor=out_idx, relu=True)
        if name == "DEPTHWISE_CONV_2D":
            _, kh, kw, cin = w.shape
            wf = _dw_block_diagonal(w, kh, kw, cin)
            layers.append(dict(kind="conv", tag="depthwise", kh=kh, kw=kw, cin=cin,
                               cout=cin, stride=1, in_h=in_hw[hw_i], in_w=in_hw[hw_i],
                               weights=wf.astype(int).tolist(),
                               weight_scales=list(ws if len(ws) == cin else ws * cin),
                               **common))
            hw_i += 1
        elif name == "CONV_2D":
            cout, kh, kw, cin = w.shape
            wf = w.reshape(cout, kh * kw * cin)
            layers.append(dict(kind="conv", tag=("pointwise" if kh == 1 else "conv"),
                               kh=kh, kw=kw, cin=cin, cout=cout, stride=1,
                               in_h=in_hw[hw_i], in_w=in_hw[hw_i],
                               weights=wf.astype(int).tolist(),
                               weight_scales=(list(ws) if len(ws) == cout else list(ws) * cout),
                               **common))
            hw_i += 1
        else:                                  # FULLY_CONNECTED
            common["relu"] = False
            layers.append(dict(kind="fc", tag="fc", k=int(w.shape[1]), n=int(w.shape[0]),
                               weights=w.astype(int).tolist(),
                               weight_scales=(list(ws) if len(ws) == w.shape[0] else list(ws) * w.shape[0]),
                               **common))
        out_idxs.append(out_idx)
    tags = [l["tag"] for l in layers]
    assert tags == ["conv", "depthwise", "pointwise", "fc"], f"unexpected op order {tags}"

    rng = np.random.default_rng(SEED + 2)
    x = rng.integers(-128, 128, (1, 6, 6, 8), dtype=np.int8)
    it.set_tensor(it.get_input_details()[0]["index"], x)
    it.invoke()
    inter = [it.get_tensor(i).astype(int).tolist() for i in out_idxs]
    final = it.get_tensor(it.get_output_details()[0]["index"]).astype(int).tolist()

    (ART / "model_kws.json").write_text(json.dumps(dict(source="kws.tflite", seed=SEED,
                                                        layers=layers)))
    (ART / "golden_kws.json").write_text(json.dumps(dict(
        input=x.astype(int).tolist(), inter=inter, final=final)))
    print("KWS DS-CNN:", tags, "final:", final[0])


if __name__ == "__main__":
    main()
