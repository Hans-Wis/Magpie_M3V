#!/usr/bin/env python3
"""w4a8_ptq_sim — W4A8 Phase-0 Go/No-Go simulation (Grok path, zero RTL).

Symmetric per-group W4 PTQ on the 7 streamed GEMM weight matrices of a
Gemma-3-structure decoder layer (gemma_ref fp32 truth), vs per-tensor int8
(current-scheme proxy) and per-tensor W4 (why-grouping baseline). Metrics:
per-matrix weight SNR, single-layer output SNR/cos/max, 18-layer chained drift.

HONESTY: weights are the repo's synthetic Gaussians (gemma_ref.make_weights) at
REAL dims (H=640, inter=2048). Gaussians under-represent real-model outliers —
a Go from this sim is PROVISIONAL pending a real-weight (HF) re-run; a No-Go
here is decisive (synthetic is the easy case). Full-model PPL is out of scope
(no real weights / eval stack in repo).
"""
from __future__ import annotations

import numpy as np

import gemma_ref as G

REAL_CFG = dict(
    hidden=640, n_heads=4, n_kv_heads=1, head_dim=160, intermediate=2048,
    seq=16, eps=1e-6, rope_theta=10000.0, sliding_window=0,
    query_pre_attn_scalar=160,
)
GEMMS = ("q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj")
N_LAYERS = 18


def q_int8_per_tensor(w):
    s = np.max(np.abs(w)) / 127.0
    return (np.clip(np.round(w / s), -127, 127) * s).astype(np.float32)


def q_w4_per_tensor(w):
    s = np.max(np.abs(w)) / 7.0
    return (np.clip(np.round(w / s), -7, 7) * s).astype(np.float32)


def q_w4_per_group(w, g):
    """Symmetric per-group along the input (axis-0 / K) dimension."""
    k, n = w.shape
    pad = (-k) % g
    wp = np.pad(w, ((0, pad), (0, 0)))
    wg = wp.reshape(-1, g, n)                        # groups × g × n
    s = np.max(np.abs(wg), axis=1, keepdims=True) / 7.0
    s = np.where(s == 0, 1e-12, s)
    dq = np.clip(np.round(wg / s), -7, 7) * s
    return dq.reshape(-1, n)[:k].astype(np.float32)


def snr_db(ref, x):
    err = (ref.astype(np.float64) - x.astype(np.float64))
    p_sig = np.mean(ref.astype(np.float64) ** 2)
    p_err = np.mean(err ** 2)
    return float("inf") if p_err == 0 else 10.0 * np.log10(p_sig / p_err)


def quantize_weights(W, scheme):
    Wq = dict(W)
    for k in GEMMS:
        Wq[k] = scheme(W[k])
    return Wq


def layer_metrics(cfg, W, Wq, x):
    y_ref = G.decoder_layer(x, W, cfg)
    y_q = G.decoder_layer(x, Wq, cfg)
    cos = float(np.dot(y_ref.ravel(), y_q.ravel()) /
                (np.linalg.norm(y_ref) * np.linalg.norm(y_q)))
    rel = float(np.max(np.abs(y_ref - y_q)) / (np.max(np.abs(y_ref)) + 1e-12))
    return snr_db(y_ref, y_q), cos, rel


def chained_drift(cfg, scheme, x0):
    x_ref = x0.copy()
    x_q = x0.copy()
    for layer in range(N_LAYERS):
        W = G.make_weights(cfg, seed=20260710 + layer)
        Wq = quantize_weights(W, scheme)
        x_ref = G.decoder_layer(x_ref, W, cfg)
        x_q = G.decoder_layer(x_q, Wq, cfg)
    cos = float(np.dot(x_ref.ravel(), x_q.ravel()) /
                (np.linalg.norm(x_ref) * np.linalg.norm(x_q)))
    return snr_db(x_ref, x_q), cos


def bytes_per_layer(cfg, wbits, g=None):
    n_w = sum(int(np.prod([cfg["hidden"], cfg["n_heads"] * cfg["head_dim"]][:2]))
              for _ in ())  # placeholder, computed below explicitly
    hid, nh, nkv, hd, inter = (cfg["hidden"], cfg["n_heads"], cfg["n_kv_heads"],
                               cfg["head_dim"], cfg["intermediate"])
    shapes = [(hid, nh * hd), (hid, nkv * hd), (hid, nkv * hd), (nh * hd, hid),
              (hid, inter), (hid, inter), (inter, hid)]
    n = sum(a * b for a, b in shapes)
    total = n * wbits / 8.0
    if g:
        total += sum(-(-a // g) * b for a, b in shapes) * 2.0   # s16 per group
    return total


def main():
    cfg = REAL_CFG
    rng = np.random.default_rng(42)
    x = rng.normal(0, 1.0, (cfg["seq"], cfg["hidden"])).astype(np.float32)
    W = G.make_weights(cfg, seed=20260710)

    schemes = [
        ("int8_per_tensor", q_int8_per_tensor),
        ("w4_per_tensor", q_w4_per_tensor),
        ("w4_g128", lambda w: q_w4_per_group(w, 128)),
        ("w4_g64", lambda w: q_w4_per_group(w, 64)),
        ("w4_g32", lambda w: q_w4_per_group(w, 32)),
    ]

    print("== per-matrix weight SNR (dB) ==")
    hdr = "matrix".ljust(11) + "".join(n.rjust(17) for n, _ in schemes)
    print(hdr)
    for m in GEMMS:
        row = m.ljust(11)
        for _, fn in schemes:
            row += f"{snr_db(W[m], fn(W[m])):17.2f}"
        print(row)

    print("\n== single decoder layer (real dims H=640/inter=2048, seq=16) ==")
    print("scheme".ljust(17) + "out_SNR_dB".rjust(12) + "cosine".rjust(12) + "max_rel".rjust(12))
    for name, fn in schemes:
        s, c, r = layer_metrics(cfg, W, quantize_weights(W, fn), x)
        print(f"{name:<17}{s:12.2f}{c:12.6f}{r:12.4f}")

    print(f"\n== {N_LAYERS}-layer chained drift (independent weights/layer) ==")
    print("scheme".ljust(17) + "final_SNR_dB".rjust(14) + "cosine".rjust(12))
    for name, fn in schemes:
        s, c = chained_drift(cfg, fn, x)
        print(f"{name:<17}{s:14.2f}{c:12.6f}")

    print("\n== bytes/layer + decode tok/s upper bounds (18L, 460MHz; measured B/cyc) ==")
    b8 = bytes_per_layer(cfg, 8)
    rows = [("W8 (int8)", b8),
            ("W4 g=128", bytes_per_layer(cfg, 4, 128)),
            ("W4 g=64", bytes_per_layer(cfg, 4, 64)),
            ("W4 g=32", bytes_per_layer(cfg, 4, 32))]
    bpcs = [("G1-now", 1.6), ("G2", 2.86), ("stream", 4.63), ("pin-ish", 5.4)]
    print("config".ljust(12) + "MB/layer".rjust(10) + "".join(n.rjust(10) for n, _ in bpcs))
    for name, b in rows:
        row = name.ljust(12) + f"{b/1e6:10.3f}"
        for _, bpc in bpcs:
            toks = 460e6 / (N_LAYERS * b / bpc)
            row += f"{toks:10.1f}"
        print(row)
    print("\nW4A8_PTQ_SIM_DONE")


if __name__ == "__main__":
    main()
