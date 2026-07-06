#!/usr/bin/env python3
"""build_model_dw — MobileNet-block offline half (ADR-0061): int8 depthwise-separable.

[1,6,6,8] -> DepthwiseConv2D 3x3 VALID stride1 (per-channel, ReLU) -> [1,4,4,8]
          -> PointwiseConv2D 1x1 cout=8 (per-channel, ReLU)        -> [1,4,4,8].

The depthwise conv is NOT a shared-K GEMM (out channel c uses only in channel c).
KEY MAPPING (zero RTL / zero runtime change): lower it as a STANDARD conv with
BLOCK-DIAGONAL (channel-masked) weights — w[c][k] = dwkernel[c][tap] iff channel(k)==c
else 0, over the full im2col K = kh*kw*cin. Then
    out[pixel][c] = sum_k rows[pixel][k] * w[c][k] = sum over channel c's taps only
= the exact depthwise int32 accumulator (the zeroed off-channel taps contribute 0
bit-exactly in int8*int8->int32). Per-channel requant via RESCALE_PC. ~1/8 array
utilization; the mat_engine + npu_dma + tflm_runtime conv path are provably sufficient.

The pointwise 1x1 conv IS a plain GEMM (K = cin) -> existing conv lowering as-is.

Run:  LD_LIBRARY_PATH=$CONDA_PREFIX/lib python3 build_model_dw.py
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
    dw = tf.keras.layers.DepthwiseConv2D(3, padding="valid", activation="relu",
                                         name="dw")
    pw = tf.keras.layers.Conv2D(8, 1, padding="valid", activation="relu", name="pw")
    out = pw(dw(inp))
    m = tf.keras.Model(inp, out)
    dw.set_weights([rng.normal(0, 0.5, (3, 3, 8, 1)).astype(np.float32),
                    rng.normal(0, 0.2, 8).astype(np.float32)])
    pw.set_weights([rng.normal(0, 0.4, (1, 1, 8, 8)).astype(np.float32),
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


def _dw_block_diagonal(w, kh, kw, cin):
    """w: DEPTHWISE weight tensor [1,kh,kw,cin] -> block-diagonal conv rows
    [cout=cin][kh*kw*cin] in the runtime's im2col k-order (ky,kx,ci)."""
    wf = np.zeros((cin, kh * kw * cin), dtype=np.int64)
    for c in range(cin):
        for ky in range(kh):
            for kx in range(kw):
                k = (ky * kw + kx) * cin + c
                wf[c, k] = int(w[0, ky, kx, c])
    return wf


def main():
    ART.mkdir(exist_ok=True)
    tfl = convert_int8(build_keras())
    (ART / "dwsep.tflite").write_bytes(tfl)

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
    dw_out_idx = None
    for op in it._get_ops_details():
        name = op["op_name"]
        if name not in ("DEPTHWISE_CONV_2D", "CONV_2D"):
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
        if name == "DEPTHWISE_CONV_2D":
            _, kh, kw, cin = w.shape          # [1,kh,kw,cin], depth_mult=1
            wf = _dw_block_diagonal(w, kh, kw, cin)
            # per-channel scales run along cin -> cout=cin
            scales = ws if len(ws) == cin else ws * cin
            layers.append(dict(
                kind="conv", tag="depthwise", kh=kh, kw=kw, cin=cin, cout=cin,
                stride=1, in_h=6, in_w=6, relu=True,
                weights=wf.astype(int).tolist(), bias=b.astype(int).tolist(),
                input_zp=iz[0], input_scale=is_[0], output_scale=os_[0],
                output_zp=oz[0], weight_scales=list(scales), out_tensor=out_idx))
            dw_out_idx = out_idx
        else:                                 # CONV_2D 1x1 (pointwise)
            cout, kh, kw, cin = w.shape
            assert kh == 1 and kw == 1, "expected pointwise 1x1"
            wf = w.reshape(cout, kh * kw * cin)
            layers.append(dict(
                kind="conv", tag="pointwise", kh=kh, kw=kw, cin=cin, cout=cout,
                stride=1, in_h=4, in_w=4, relu=True,
                weights=wf.astype(int).tolist(), bias=b.astype(int).tolist(),
                input_zp=iz[0], input_scale=is_[0], output_scale=os_[0],
                output_zp=oz[0],
                weight_scales=(ws if len(ws) == cout else ws * cout),
                out_tensor=out_idx))
    assert len(layers) == 2 and layers[0]["tag"] == "depthwise"
    assert len(set(layers[0]["weight_scales"])) > 1, "dw scales degenerate"

    rng = np.random.default_rng(SEED + 2)
    x = rng.integers(-128, 128, (1, 6, 6, 8), dtype=np.int8)
    it.set_tensor(it.get_input_details()[0]["index"], x)
    it.invoke()
    dw_out = it.get_tensor(dw_out_idx)                  # [1,4,4,8]
    final = it.get_tensor(it.get_output_details()[0]["index"])

    (ART / "model_dw.json").write_text(json.dumps(
        dict(source="dwsep.tflite", seed=SEED, layers=layers)))
    (ART / "golden_dw.json").write_text(json.dumps(dict(
        input=x.astype(int).tolist(),
        dw=dw_out.astype(int).tolist(),
        final=final.astype(int).tolist())))
    print("dw scales distinct:", len(set(layers[0]["weight_scales"])))
    print("golden final[0][0]:", final.astype(int).tolist()[0][0])


if __name__ == "__main__":
    main()
