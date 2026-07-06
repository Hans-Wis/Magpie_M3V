#!/usr/bin/env python3
"""gemma_quant_s3 — Tier C int8 fixed-point golden for the Gemma S3 slice (ADR-0062):
QK^T + causal mask + softmax + AV, batched over heads (GQA nkv=1 => k/v shared).

Row index r = h*seq + p  (head h, query position p):
  scores[r,j] = requant( q[p,h] . k[j] , s_q*s_k*scale , s_score )   # int8, scale=1/sqrt(qpre)
  prob[r,:]   = softmax_int8( scores[r,:], valid=p+1 )               # causal: attend j<=p
  av[r,d]     = requant( sum_k prob[r,k]*v[k,d] , s_prob*s_v , s_av ) # int8
  attn[p, h*hd+d] = av[h*seq+p, d]                                    # reassemble [seq, nh*hd]

QK^T and AV reuse the proven per-channel GEMM (gemm_pc == mat_engine); the key-dim is padded
to a multiple of 8 in the RTL emit (zeros contribute nothing). softmax is the one new op:
  mx = max_{j<valid} s[j] ; e[j] = EXP_LUT[mx - s[j]] ; sm = sum e[j]
  prob[j<valid] = (e[j]*PROB_SCALE + sm//2)//sm ; prob[j>=valid] = 0
EXP_LUT[d] = round(exp(-d*s_score)*EXP_SCALE) (documented, not fitted). INT ONLY.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import gemma_ref as ref  # noqa: E402
import gemma_quant as gq  # noqa: E402  (gemm_pc, requant)

EXP_SCALE = 65535
PROB_SCALE = 127


def exp_lut(s_score):
    """256-entry uint16 LUT: EXP_LUT[d] = round(exp(-d*s_score)*EXP_SCALE), d in [0,255]."""
    lut = np.zeros(256, np.int64)
    for d in range(256):
        lut[d] = min(EXP_SCALE, int(round(np.exp(-d * s_score) * EXP_SCALE)))
    return lut


def softmax_int8_row(s_row, valid, lut):
    """One attention row: int8 logits + causal valid-length -> int8 prob (sum ~PROB_SCALE)."""
    n = len(s_row)
    mx = max(int(s_row[j]) for j in range(valid))
    sm = sum(int(lut[mx - int(s_row[j])]) for j in range(valid))
    p = [0] * n
    for j in range(valid):
        e = int(lut[mx - int(s_row[j])])
        p[j] = (e * PROB_SCALE + sm // 2) // sm
    return p


def s3_golden(q_r, s_qr, k_r, s_kr, v_q, s_v, cfg,
              q_rope_fp, k_rope_fp, v_fp):
    """q_r [seq,nh,hd], k_r/v_q [seq,nkv,hd] int8. Returns batched int8 checkpoints."""
    seq, nh, nkv, hd = cfg["seq"], cfg["n_heads"], cfg["n_kv_heads"], cfg["head_dim"]
    scale = 1.0 / np.sqrt(cfg["query_pre_attn_scalar"])
    rep = nh // nkv
    k_h = k_r[:, 0, :]                      # [seq,hd] (nkv=1)
    v_h = v_q[:, 0, :]                      # [seq,hd]

    # offline s_score from the fp32 logit dynamic range (unmasked)
    logit_max = 0.0
    for h in range(nh):
        lg = (q_rope_fp[:, h, :] @ k_rope_fp[:, h // rep, :].T) * scale
        logit_max = max(logit_max, float(np.max(np.abs(lg))))
    s_score = logit_max / 127.0

    # QK^T: rows r=h*seq+p ; per-tensor requant (uniform weight scales)
    rows_q = np.array([q_r[p, h, :] for h in range(nh) for p in range(seq)], np.int64)
    scores = gq.gemm_pc(rows_q, k_h, s_qr, [s_kr] * seq, s_score / scale)  # [nh*seq, seq]
    scores = np.clip(scores, -128, 127).astype(np.int64)

    # softmax (causal valid = p+1)
    lut = exp_lut(s_score)
    s_prob = 1.0 / PROB_SCALE
    prob = np.zeros((nh * seq, seq), np.int64)
    for h in range(nh):
        for p in range(seq):
            prob[h * seq + p] = softmax_int8_row(scores[h * seq + p], p + 1, lut)

    # AV: out[r,d] = sum_k prob[r,k]*v[k,d]  (v.T as weights)
    v_t = v_h.T                             # [hd, seq]
    # s_av offline from fp32 attention out
    causal = np.triu(np.full((seq, seq), -np.inf, np.float32), k=1)
    attn_fp = np.zeros((seq, nh * hd), np.float32)
    for h in range(nh):
        sfp = (q_rope_fp[:, h, :] @ k_rope_fp[:, h // rep, :].T) * scale + causal
        afp = ref.softmax(sfp, axis=-1)
        attn_fp[:, h * hd:(h + 1) * hd] = afp @ v_fp[:, h // rep, :]
    s_av = float(np.max(np.abs(attn_fp))) / 127.0
    av = gq.gemm_pc(prob, v_t, s_prob, [s_v] * hd, s_av)          # [nh*seq, hd]
    av = np.clip(av, -128, 127).astype(np.int64)

    attn = np.zeros((seq, nh * hd), np.int64)
    for h in range(nh):
        for p in range(seq):
            attn[p, h * hd:(h + 1) * hd] = av[h * seq + p]

    return dict(scores=scores, prob=prob, av=av, attn=attn,
                s_score=s_score, s_prob=s_prob, s_av=s_av, lut=lut,
                rows_q=rows_q, k_h=k_h, v_t=v_t, attn_fp=attn_fp)


if __name__ == "__main__":
    import gemma_quant_s2 as s2
    cfg = ref.CFG
    W = ref.make_weights(cfg)
    h = np.random.default_rng(11).normal(0, 1.0, (cfg["seq"], cfg["hidden"])).astype(np.float32)
    g2 = s2.s2_golden(h, W, cfg)
    # v (unroped) int8 reshaped [seq,nkv,hd]
    v_q = g2["v_lin"].reshape(cfg["seq"], cfg["n_kv_heads"], cfg["head_dim"])
    v_fp = (h @ W["v_proj"]).reshape(cfg["seq"], cfg["n_kv_heads"], cfg["head_dim"])
    g = s3_golden(g2["q_r"], g2["s_qr"], g2["k_r"], g2["s_kr"], v_q, g2["s_v"], cfg,
                  g2["q_rope_fp"], g2["k_rope_fp"], v_fp)
    deq = g["attn"].astype(np.float32) * g["s_av"]
    rel = np.max(np.abs(deq - g["attn_fp"])) / float(np.max(np.abs(g["attn_fp"])))
    print(f"S3 attention int8 rel err {rel:.3%}")
    print("scores[0][:4]:", g["scores"][0][:4].tolist())
    print("prob[3][:4]:", g["prob"][3][:4].tolist(), "(row p=3: full causal)")
    print("attn[0][:6]:", g["attn"][0][:6].tolist())
