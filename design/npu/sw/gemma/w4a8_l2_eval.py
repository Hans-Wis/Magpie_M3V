#!/usr/bin/env python3
"""w4a8_l2_eval — W4A8 real-weight L2 evaluation (ADR-0072 RTL 前置 #1).

Full gemma-3-270m forward in pure NumPy (no torch): safetensors bf16 -> fp32,
18 layers, GQA 4:1, dual-rope (sliding 10k / full 1M), sliding window 512,
sandwich norms, QK-norm, GeGLU, tied lm_head. Evaluates the PRODUCTION composed
scheme — W4 per-group -> re-quantize onto the existing per-tensor int8 grid
(w8_equiv), i.e. what the npu_dma W4_DEQUANT path will emit — NOT a pure-fp
dequant (that would flatter the numbers).

Schemes: bf16 baseline / int8 per-tensor (today's proxy) / W4A8 g=64 / g=32
(composed). Metrics on an embedded ~1k-token corpus: PPL, mean logit KL
(base->quant), top-1 agreement. L2 is a quality report, NOT a lockstep gate
(ADR-0072 honesty split). Scale ratio modeled exact-float here; the fixed-point
(M_g, SH) rounding belongs to the L1 golden.

Usage: python3 w4a8_l2_eval.py [--model-dir ~/models/gemma-3-270m] [--max-tokens 1024]
"""
from __future__ import annotations

import argparse
import json
import struct
from pathlib import Path

import numpy as np
import sentencepiece as spm

CORPUS = """
The design of a small neural processing unit begins with an honest accounting of
where the cycles go. In a decoder-only transformer running one token at a time,
every layer must read its entire weight matrix from memory, and no amount of
arithmetic cleverness can hide a channel that is too narrow. The engineers
measured first and argued later. What the measurements said was simple: the
multiply array sat idle while the memory system dripped bytes through a straw.
So the plan changed. Instead of a faster core, they built a wider path, taught
the direct memory engine to fetch long, orderly bursts, and cut the weights in
half by storing four bits where eight had been. Each group of sixty-four values
shared a scale, chosen so that the small numbers survived and the large ones did
not clip. The reference model lived in a few hundred lines of NumPy, slow and
transparent, and every hardware change had to match it bit for bit before anyone
was allowed to celebrate. When the first end-to-end token emerged, matching the
golden output exactly, the room was quiet for a moment. Then someone asked about
the next bottleneck, because there is always a next bottleneck, and the meeting
moved on. Later that season the team revisited the attention path. With longer
sequences the score matrix grew, and the softmax that had once been a rounding
error began to show up in the profiles. They replaced a division with a
reciprocal multiply, vectorized the exponent lookup, and kept a small cache of
recent keys on chip so the memory system could keep streaming weights
undisturbed. None of these changes was glamorous. Each one was measured,
reviewed, and gated before it landed. The report at the end of the quarter drew
one lesson in bold: performance work is bookkeeping first, architecture second,
and heroics never.
""" * 2


def load_safetensors_np(path: Path):
    with open(path, "rb") as f:
        n = struct.unpack("<Q", f.read(8))[0]
        header = json.loads(f.read(n))
        base = 8 + n
        data = np.memmap(path, dtype=np.uint8, mode="r")
    out = {}
    for name, meta in header.items():
        if name == "__metadata__":
            continue
        s, e = meta["data_offsets"]
        raw = np.asarray(data[base + s:base + e])
        if meta["dtype"] == "BF16":
            u16 = raw.view(np.uint16).astype(np.uint32) << 16
            arr = u16.view(np.float32)
        elif meta["dtype"] == "F32":
            arr = raw.view(np.float32)
        else:
            raise ValueError(f"{name}: unsupported dtype {meta['dtype']}")
        out[name] = np.array(arr.reshape(meta["shape"]), dtype=np.float32)
    return out


def rmsnorm(x, w, eps=1e-6):
    var = np.mean(x.astype(np.float64) ** 2, axis=-1, keepdims=True)
    return ((x / np.sqrt(var + eps)) * (1.0 + w)).astype(np.float32)


def gelu_tanh(x):
    c = np.sqrt(2.0 / np.pi)
    return 0.5 * x * (1.0 + np.tanh(c * (x + 0.044715 * x ** 3)))


def rope_apply(x, pos, theta):
    # x: [S, H, D]; neox half-rotation
    S, H, D = x.shape
    half = D // 2
    inv = 1.0 / (theta ** (np.arange(0, half, dtype=np.float64) * 2 / D))
    ang = np.outer(pos, inv)                        # [S, half]
    cos = np.cos(ang)[:, None, :]
    sin = np.sin(ang)[:, None, :]
    x1, x2 = x[..., :half], x[..., half:]
    return np.concatenate([x1 * cos - x2 * sin, x1 * sin + x2 * cos],
                          axis=-1).astype(np.float32)


def softmax(x):
    m = np.max(x, axis=-1, keepdims=True)
    e = np.exp(x - m)
    return e / np.sum(e, axis=-1, keepdims=True)


class Gemma3:
    def __init__(self, model_dir: Path):
        cfg = json.loads((model_dir / "config.json").read_text())
        self.cfg = cfg
        self.W = load_safetensors_np(model_dir / "model.safetensors")
        self.layer_types = cfg["layer_types"]

    def forward_logits(self, ids, wsub=None):
        """wsub: optional {tensor_name: ndarray} substitution for GEMM weights."""
        cfg, W = self.cfg, self.W
        get = (lambda k: wsub[k] if wsub and k in wsub else W[k])
        hid, nh, nkv = cfg["hidden_size"], cfg["num_attention_heads"], cfg["num_key_value_heads"]
        hd = cfg["head_dim"]
        S = len(ids)
        pos = np.arange(S)
        emb = W["model.embed_tokens.weight"]
        x = emb[ids] * np.sqrt(float(hid), dtype=np.float64).astype(np.float32)
        causal = np.tril(np.ones((S, S), dtype=bool))
        sw = cfg["sliding_window"]
        swmask = causal & (pos[None, :] > (pos[:, None] - sw))
        qscale = cfg["query_pre_attn_scalar"] ** -0.5
        for li in range(cfg["num_hidden_layers"]):
            p = f"model.layers.{li}."
            sliding = self.layer_types[li] == "sliding_attention"
            theta = cfg["rope_local_base_freq"] if sliding else cfg["rope_theta"]
            mask = swmask if sliding else causal
            r = x
            h = rmsnorm(x, W[p + "input_layernorm.weight"])
            q = (h @ get(p + "self_attn.q_proj.weight").T).reshape(S, nh, hd)
            k = (h @ get(p + "self_attn.k_proj.weight").T).reshape(S, nkv, hd)
            v = (h @ get(p + "self_attn.v_proj.weight").T).reshape(S, nkv, hd)
            q = rmsnorm(q, W[p + "self_attn.q_norm.weight"])
            k = rmsnorm(k, W[p + "self_attn.k_norm.weight"])
            q = rope_apply(q, pos, theta)
            k = rope_apply(k, pos, theta)
            k = np.repeat(k, nh // nkv, axis=1)
            v = np.repeat(v, nh // nkv, axis=1)
            att = np.einsum("shd,thd->hst", q, k) * qscale
            att = np.where(mask[None], att, -1e30)
            att = softmax(att)
            o = np.einsum("hst,thd->shd", att, v).reshape(S, nh * hd)
            a = o @ get(p + "self_attn.o_proj.weight").T
            a = rmsnorm(a, W[p + "post_attention_layernorm.weight"])
            x = r + a
            r = x
            h = rmsnorm(x, W[p + "pre_feedforward_layernorm.weight"])
            g = gelu_tanh(h @ get(p + "mlp.gate_proj.weight").T)
            u = h @ get(p + "mlp.up_proj.weight").T
            m = (g * u) @ get(p + "mlp.down_proj.weight").T
            m = rmsnorm(m, W[p + "post_feedforward_layernorm.weight"])
            x = r + m
        x = rmsnorm(x, W["model.norm.weight"])
        return x @ emb.T                                            # tied lm_head


GEMM_KEYS = ("self_attn.q_proj.weight", "self_attn.k_proj.weight",
             "self_attn.v_proj.weight", "self_attn.o_proj.weight",
             "mlp.gate_proj.weight", "mlp.up_proj.weight", "mlp.down_proj.weight")


def q_int8_pt(w):
    s = np.max(np.abs(w)) / 127.0
    return (np.clip(np.round(w / s), -127, 127) * s).astype(np.float32)


def q_w4_composed(w, g):
    """PRODUCTION path: symmetric W4 per-(out-row, K-group) -> re-quantize onto
    the per-tensor int8 grid (what npu_dma W4_DEQUANT emits)."""
    s_t = np.max(np.abs(w)) / 127.0
    o, k = w.shape                       # HF layout [out, in]; K = in axis
    pad = (-k) % g
    wp = np.pad(w, ((0, 0), (0, pad)))
    wg = wp.reshape(o, -1, g)
    s_g = np.max(np.abs(wg), axis=2, keepdims=True) / 7.0
    s_g = np.where(s_g == 0, 1e-12, s_g)
    w4 = np.clip(np.round(wg / s_g), -7, 7)
    w8 = np.clip(np.round(w4 * (s_g / s_t)), -127, 127)     # int8 grid re-quant
    return (w8.reshape(o, -1)[:, :k] * s_t).astype(np.float32)


def build_sub(model, fn):
    sub = {}
    for li in range(model.cfg["num_hidden_layers"]):
        for kk in GEMM_KEYS:
            name = f"model.layers.{li}.{kk}"
            sub[name] = fn(model.W[name])
    return sub


def metrics(base_logits, q_logits, ids):
    tgt = np.asarray(ids[1:])
    def nll(lg):
        lp = lg[:-1] - np.log(np.sum(np.exp(lg[:-1] - np.max(lg[:-1], axis=-1,
                              keepdims=True)), axis=-1, keepdims=True)) - \
             np.max(lg[:-1], axis=-1, keepdims=True)
        return -np.mean(lp[np.arange(len(tgt)), tgt])
    p = softmax(base_logits.astype(np.float64))
    qs = softmax(q_logits.astype(np.float64))
    kl = float(np.mean(np.sum(p * (np.log(p + 1e-12) - np.log(qs + 1e-12)), axis=-1)))
    top1 = float(np.mean(np.argmax(base_logits, -1) == np.argmax(q_logits, -1)))
    return float(np.exp(nll(q_logits))), kl, top1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model-dir", default=str(Path.home() / "models/gemma-3-270m"))
    ap.add_argument("--max-tokens", type=int, default=1024)
    args = ap.parse_args()
    md = Path(args.model_dir)

    sp = spm.SentencePieceProcessor(model_file=str(md / "tokenizer.model"))
    ids = [2] + sp.encode(CORPUS.strip())[: args.max_tokens - 1]   # BOS=2
    print(f"tokens={len(ids)}")

    model = Gemma3(md)
    print("weights loaded:", len(model.W))

    base = model.forward_logits(ids)
    ppl_base, _, _ = metrics(base, base, ids)
    print(f"L2 bf16_base        ppl={ppl_base:9.4f} kl=0.000000 top1=1.0000")

    for name, fn in [("int8_per_tensor", q_int8_pt),
                     ("w4a8_g64", lambda w: q_w4_composed(w, 64)),
                     ("w4a8_g32", lambda w: q_w4_composed(w, 32))]:
        lg = model.forward_logits(ids, build_sub(model, fn))
        ppl, kl, top1 = metrics(base, lg, ids)
        print(f"L2 {name:<16} ppl={ppl:9.4f} kl={kl:.6f} top1={top1:.4f}")
    print("W4A8_L2_EVAL_DONE")


if __name__ == "__main__":
    main()
