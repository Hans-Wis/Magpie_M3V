#!/usr/bin/env python3
"""w4a8_l2_ablation — attribute the W4 loss and probe cheap recoveries.

A: composed int8-grid vs pure-fp dequant (how much the second rounding costs)
B: asymmetric per-group W4 (zero-point) vs symmetric
C: per-matrix-class sensitivity (quantize ONE class to W4 g=64, rest bf16)
   -> mixed-precision candidate set
All pure NumPy on the real gemma-3-270m weights; L2 metrics vs bf16 base.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
import w4a8_l2_eval as E


def q_w4_pure(w, g):
    """Pure symmetric per-group dequant (no int8-grid recomposition)."""
    o, k = w.shape
    pad = (-k) % g
    wp = np.pad(w, ((0, 0), (0, pad)))
    wg = wp.reshape(o, -1, g)
    s_g = np.max(np.abs(wg), axis=2, keepdims=True) / 7.0
    s_g = np.where(s_g == 0, 1e-12, s_g)
    dq = np.clip(np.round(wg / s_g), -7, 7) * s_g
    return dq.reshape(o, -1)[:, :k].astype(np.float32)


def q_w4_asym(w, g):
    """Asymmetric per-group (uint4 + zero-point), pure dequant."""
    o, k = w.shape
    pad = (-k) % g
    wp = np.pad(w, ((0, 0), (0, pad)))
    wg = wp.reshape(o, -1, g)
    mn = np.min(wg, axis=2, keepdims=True)
    mx = np.max(wg, axis=2, keepdims=True)
    s = np.where(mx - mn == 0, 1e-12, (mx - mn) / 15.0)
    q = np.clip(np.round((wg - mn) / s), 0, 15)
    dq = q * s + mn
    return dq.reshape(o, -1)[:, :k].astype(np.float32)


def main():
    md = Path.home() / "models/gemma-3-270m"
    import sentencepiece as spm
    sp = spm.SentencePieceProcessor(model_file=str(md / "tokenizer.model"))
    ids = [2] + sp.encode(E.CORPUS.strip())[:767]
    model = E.Gemma3(md)
    base = model.forward_logits(ids)

    def run(tag, sub):
        lg = model.forward_logits(ids, sub)
        ppl, kl, top1 = E.metrics(base, lg, ids)
        print(f"L2 {tag:<26} ppl={ppl:9.4f} kl={kl:.6f} top1={top1:.4f}")

    print("== A: composition cost (g=64) ==")
    run("w4_g64_pure", E.build_sub(model, lambda w: q_w4_pure(w, 64)))
    run("w4_g64_composed", E.build_sub(model, lambda w: E.q_w4_composed(w, 64)))

    print("== B: asymmetric (pure dequant) ==")
    run("w4_g64_asym", E.build_sub(model, lambda w: q_w4_asym(w, 64)))
    run("w4_g32_asym", E.build_sub(model, lambda w: q_w4_asym(w, 32)))

    print("== C: per-class sensitivity (one class W4 g=64 composed, rest bf16) ==")
    for kk in E.GEMM_KEYS:
        sub = {}
        for li in range(model.cfg["num_hidden_layers"]):
            name = f"model.layers.{li}.{kk}"
            sub[name] = E.q_w4_composed(model.W[name], 64)
        run(f"only_{kk.split('.')[-2]}", sub)

    print("W4A8_L2_ABLATION_DONE")


if __name__ == "__main__":
    main()
