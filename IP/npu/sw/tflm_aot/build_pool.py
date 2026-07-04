#!/usr/bin/env python3
"""build_pool — ADR-0049 S4 offline half: real TFLM pooling authority.

Two 1-op int8 .tflite models on [1,4,4,8] (VALID 2x2 stride-2 -> [1,2,2,8]):
MAX_POOL_2D and AVERAGE_POOL_2D, run on the BUILTIN_REF interpreter to give
the bit-exact pooling golden (incl. the avg-pool round-half-away semantics
the RVV kernel must reproduce).

Run:  LD_LIBRARY_PATH=$CONDA_PREFIX/lib python3 build_pool.py
"""
import json
from pathlib import Path

import numpy as np
import tensorflow as tf

ART = Path(__file__).resolve().parent / "artifacts"
SEED = 20260706


def one_op_model(layer):
    inp = tf.keras.Input(shape=(4, 4, 8), batch_size=1, dtype=tf.float32)
    m = tf.keras.Model(inp, layer(inp))
    rng = np.random.default_rng(SEED + 1)

    def rep():
        for _ in range(32):
            yield [rng.normal(0, 1.0, (1, 4, 4, 8)).astype(np.float32)]

    c = tf.lite.TFLiteConverter.from_keras_model(m)
    c.optimizations = [tf.lite.Optimize.DEFAULT]
    c.representative_dataset = rep
    c.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    c.inference_input_type = tf.int8
    c.inference_output_type = tf.int8
    return c.convert()


def golden(tfl, x):
    it = tf.lite.Interpreter(
        model_content=tfl,
        experimental_op_resolver_type=tf.lite.experimental.OpResolverType.BUILTIN_REF)
    it.allocate_tensors()
    it.set_tensor(it.get_input_details()[0]["index"], x)
    it.invoke()
    return it.get_tensor(it.get_output_details()[0]["index"])


def main():
    ART.mkdir(exist_ok=True)
    rng = np.random.default_rng(SEED + 2)
    x = rng.integers(-128, 128, (1, 4, 4, 8), dtype=np.int8)

    mp = one_op_model(tf.keras.layers.MaxPooling2D(2, 2, padding="valid"))
    ap = one_op_model(tf.keras.layers.AveragePooling2D(2, 2, padding="valid"))
    (ART / "maxpool.tflite").write_bytes(mp)
    (ART / "avgpool.tflite").write_bytes(ap)
    (ART / "pool_golden.json").write_text(json.dumps(dict(
        input=x.astype(int).tolist(),
        maxpool=golden(mp, x).astype(int).tolist(),
        avgpool=golden(ap, x).astype(int).tolist())))
    print("max row0:", golden(mp, x)[0, 0, 0].tolist())
    print("avg row0:", golden(ap, x)[0, 0, 0].tolist())


if __name__ == "__main__":
    main()
