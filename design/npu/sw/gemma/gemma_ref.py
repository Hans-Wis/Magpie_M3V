#!/usr/bin/env python3
"""gemma_ref — fp32 NumPy reference for ONE Gemma-3 decoder layer (ADR-0062).

Gemma-3 (270M structure) decoder layer, exact ops, small representative dims for RTL
sim. This is the fp32 TRUTH; a defined int8 quantization (gemma_quant.py) produces the
bit-exact golden the NPU must match.

Layer (Gemma-3 sandwich norm + QK-norm):
    r = x;  h = RMSNorm_in(x)
    a = SelfAttn(h)              # q/k/v proj, QK-norm, RoPE, GQA, causal+SWA, softmax, AV, o_proj
    a = RMSNorm_postattn(a)
    x = r + a
    r = x;  h = RMSNorm_preffn(x)
    m = MLP(h)                   # GeGLU: down( gelu_tanh(gate(h)) * up(h) )
    m = RMSNorm_postffn(m)
    x = r + m
RMSNorm uses Gemma's (1 + weight) convention. Activation = gelu_pytorch_tanh.
"""
from __future__ import annotations

import numpy as np

# ---- small representative config (Gemma-3 STRUCTURE; dims scaled for sim) ----
CFG = dict(
    hidden=64, n_heads=4, n_kv_heads=1, head_dim=16, intermediate=128,
    seq=4, eps=1e-6, rope_theta=10000.0, sliding_window=0,   # 0 => pure causal
    query_pre_attn_scalar=16,   # scaling = 1/sqrt(query_pre_attn_scalar)
)


def rmsnorm(x, w, eps):
    """Gemma RMSNorm: x * rsqrt(mean(x^2)+eps) * (1 + w). fp32, last-axis."""
    var = np.mean(x.astype(np.float64) ** 2, axis=-1, keepdims=True)
    xn = x / np.sqrt(var + eps)
    return (xn * (1.0 + w)).astype(np.float32)


def gelu_tanh(x):
    """gelu_pytorch_tanh: 0.5 x (1 + tanh(sqrt(2/pi)(x + 0.044715 x^3)))."""
    c = np.sqrt(2.0 / np.pi)
    return (0.5 * x * (1.0 + np.tanh(c * (x + 0.044715 * x ** 3)))).astype(np.float32)


def rope_tables(seq, head_dim, theta):
    """neox-style cos/sin [seq, head_dim] (half-split rotation)."""
    half = head_dim // 2
    inv = 1.0 / (theta ** (np.arange(0, half, dtype=np.float64) / half))
    pos = np.arange(seq, dtype=np.float64)[:, None]
    ang = pos * inv[None, :]                       # [seq, half]
    cos = np.cos(ang); sin = np.sin(ang)
    cos = np.concatenate([cos, cos], axis=-1)      # [seq, head_dim]
    sin = np.concatenate([sin, sin], axis=-1)
    return cos.astype(np.float32), sin.astype(np.float32)


def rotate_half(x):
    half = x.shape[-1] // 2
    return np.concatenate([-x[..., half:], x[..., :half]], axis=-1)


def apply_rope(x, cos, sin):
    # x: [seq, n, head_dim]; cos/sin: [seq, head_dim]
    return x * cos[:, None, :] + rotate_half(x) * sin[:, None, :]


def softmax(x, axis=-1):
    m = np.max(x, axis=axis, keepdims=True)
    e = np.exp((x - m).astype(np.float64))
    return (e / np.sum(e, axis=axis, keepdims=True)).astype(np.float32)


def self_attn(h, W, cfg):
    seq, hid = h.shape
    nh, nkv, hd = cfg["n_heads"], cfg["n_kv_heads"], cfg["head_dim"]
    q = (h @ W["q_proj"]).reshape(seq, nh, hd)
    k = (h @ W["k_proj"]).reshape(seq, nkv, hd)
    v = (h @ W["v_proj"]).reshape(seq, nkv, hd)
    # QK-norm (RMSNorm over head_dim)
    q = rmsnorm(q, W["q_norm"], cfg["eps"])
    k = rmsnorm(k, W["k_norm"], cfg["eps"])
    cos, sin = rope_tables(seq, hd, cfg["rope_theta"])
    q = apply_rope(q, cos, sin)
    k = apply_rope(k, cos, sin)
    # GQA: repeat kv heads to n_heads
    rep = nh // nkv
    k = np.repeat(k, rep, axis=1)
    v = np.repeat(v, rep, axis=1)
    scale = 1.0 / np.sqrt(cfg["query_pre_attn_scalar"])
    out = np.zeros((seq, nh, hd), np.float32)
    causal = np.triu(np.full((seq, seq), -np.inf, np.float32), k=1)
    for hh in range(nh):
        s = (q[:, hh, :] @ k[:, hh, :].T) * scale + causal   # [seq, seq]
        a = softmax(s, axis=-1)
        out[:, hh, :] = a @ v[:, hh, :]
    o = out.reshape(seq, nh * hd)
    return (o @ W["o_proj"]).astype(np.float32)


def mlp(h, W):
    g = gelu_tanh(h @ W["gate_proj"])
    u = h @ W["up_proj"]
    return ((g * u) @ W["down_proj"]).astype(np.float32)


def decoder_layer(x, W, cfg):
    r = x
    a = self_attn(rmsnorm(x, W["norm_in"], cfg["eps"]), W, cfg)
    a = rmsnorm(a, W["norm_postattn"], cfg["eps"])
    x = r + a
    r = x
    m = mlp(rmsnorm(x, W["norm_preffn"], cfg["eps"]), W)
    m = rmsnorm(m, W["norm_postffn"], cfg["eps"])
    return r + m


def make_weights(cfg, seed=20260706):
    rng = np.random.default_rng(seed)
    hid, nh, nkv, hd, inter = (cfg["hidden"], cfg["n_heads"], cfg["n_kv_heads"],
                               cfg["head_dim"], cfg["intermediate"])
    n = lambda *s: rng.normal(0, 0.08, s).astype(np.float32)
    return dict(
        q_proj=n(hid, nh * hd), k_proj=n(hid, nkv * hd), v_proj=n(hid, nkv * hd),
        o_proj=n(nh * hd, hid), q_norm=n(hd), k_norm=n(hd),
        gate_proj=n(hid, inter), up_proj=n(hid, inter), down_proj=n(inter, hid),
        norm_in=n(hid), norm_postattn=n(hid), norm_preffn=n(hid), norm_postffn=n(hid))


if __name__ == "__main__":
    cfg = CFG
    W = make_weights(cfg)
    rng = np.random.default_rng(cfg["seed"] if "seed" in cfg else 1)
    x = np.random.default_rng(42).normal(0, 1.0, (cfg["seq"], cfg["hidden"])).astype(np.float32)
    y = decoder_layer(x, W, cfg)
    print("in", x.shape, "out", y.shape, "finite:", np.isfinite(y).all())
    print("out[0][:6]:", np.round(y[0][:6], 4).tolist())
