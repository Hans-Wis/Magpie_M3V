#!/usr/bin/env python3
"""gemma_quant_s2 — Tier C int8 fixed-point golden for the Gemma S2 slice (ADR-0062):
Q/K/V projection + QK-norm + RoPE. Bit-exact authority; the sequencer firmware must
reproduce every checkpoint byte-identical.

  q = h @ Wq  (per-channel GEMM, reshape [seq,nh,hd])   ; k,v analogously (nkv heads)
  q = RMSNorm(q, q_norm)   ; k = RMSNorm(k, k_norm)      # QK-norm over head_dim (reuse S1)
  q = RoPE(q) ; k = RoPE(k)                              # NEW: Q15 cos/sin tables + rotate-half
  v                                                       # v is projected only (no norm/rope)

Fixed-point contract:
- Projections: reuse the proven per-channel gemmlowp GEMM (mat_engine authority).
- QK-norm: reuse S1 rmsnorm_int8 with H=head_dim (per (seq,head) row).
- RoPE (NEW): cos/sin quantized to Q15 int16 tables (round(fp*2^15), documented not fitted).
  neox half-split rotate: rot_i = -x[i+half] (i<half) else x[i-half]. Per element:
      acc = x_i*cos_q15_i + rot_i*sin_q15_i          # int32, Q15 relative to s_x
      out_i = gemmlowp_requant(acc, s_x, s_out*2^15)  # -> int8 (rotation ~norm-preserving)
  The requant multiplier/shift is per-tensor (identical for every row); only the cos/sin
  table pointer varies with sequence position.
INT ONLY in the nonlinear paths (green-wash guard); fp32 is a bounded sanity check only.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parents[1] / "golden"))
import gemma_ref as ref  # noqa: E402
import gemma_quant as gq  # noqa: E402  (gemm_pc, q_pertensor, q_perchannel, requant, qmul)
import gemma_quant_s1 as s1  # noqa: E402  (rmsnorm_int8)
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "golden"))
import rvv_bitmodel as rvv  # noqa: E402  (E1b/RoPE rounding redefinition)


def rope_tables_q15(seq, hd, theta):
    """Documented neox cos/sin [seq,hd] -> Q15 int16 (round(fp*2^15), clipped)."""
    cos, sin = ref.rope_tables(seq, hd, theta)
    cos_q = np.clip(np.round(cos.astype(np.float64) * (1 << 15)), -32768, 32767).astype(np.int64)
    sin_q = np.clip(np.round(sin.astype(np.float64) * (1 << 15)), -32768, 32767).astype(np.int64)
    return cos_q, sin_q


def rope_int8(x_q, s_x, cos_q, sin_q, s_out):
    """x_q [seq,n,hd] int8 @ s_x -> roped int8 @ s_out. Pure int fixed-point.
    Returns (out, dict(mult_q31, shift)) where shift is the firmware rdbpot exponent+31."""
    seq, n, hd = x_q.shape
    half = hd // 2
    m, s = gq.qmul(s_x / (s_out * (1 << 15)))
    out = np.zeros_like(x_q)
    for p in range(seq):
        for h in range(n):
            for i in range(hd):
                rot = -int(x_q[p, h, i + half]) if i < half else int(x_q[p, h, i - half])
                acc = int(x_q[p, h, i]) * int(cos_q[p, i]) + rot * int(sin_q[p, i])
                # RoPE RVV rounding redefinition (nonlinear_rvv_e1b_rope_design §3):
                # srdhm+rdbpot -> vsmul(rnu)+vssra(rnu), Spike-validated primitives
                q = rvv.vssra(rvv.vsmul(acc, m, 0), -s, 0)
                out[p, h, i] = max(-128, min(127, q))
    return out, dict(mult_q31=m & 0xFFFFFFFF, shift=31 - s)


def _proj(h_q, s_h, w_fp, h_f, cfg_out_cols):
    """per-channel GEMM h @ w -> int8 @ s_out (offline scale from fp32 range)."""
    w_q, sw = gq.q_perchannel(w_fp.T)                 # [cols, hid]
    s_out = float(np.max(np.abs(h_f @ w_fp))) / 127.0
    lin = gq.gemm_pc(h_q, w_q, s_h, sw, s_out)        # [seq, cols]
    return lin, s_out, (w_q, sw)


def qk_norm(lin, s_lin, w_norm, eps, s_out, seq, n, hd):
    """QK-norm: RMSNorm over head_dim per (seq,head) row (reuse S1)."""
    rows = lin.reshape(seq * n, hd)
    normed, nrm = s1.rmsnorm_int8(rows, s_lin, w_norm, eps, s_out)
    return normed.reshape(seq, n, hd), nrm


def s2_golden(h_f, W, cfg):
    """Tier C S2. h_f = normed attention input [seq,hidden]. Returns int8 checkpoints."""
    seq, nh, nkv, hd = cfg["seq"], cfg["n_heads"], cfg["n_kv_heads"], cfg["head_dim"]
    eps, theta = cfg["eps"], cfg["rope_theta"]
    h_q, s_h = gq.q_pertensor(h_f)

    q_lin, s_q, _ = _proj(h_q, s_h, W["q_proj"], h_f, nh * hd)
    k_lin, s_k, _ = _proj(h_q, s_h, W["k_proj"], h_f, nkv * hd)
    v_lin, s_v, _ = _proj(h_q, s_h, W["v_proj"], h_f, nkv * hd)

    # QK-norm output scales (offline from fp32 dynamic range)
    q_norm_fp = ref.rmsnorm((h_f @ W["q_proj"]).reshape(seq, nh, hd), W["q_norm"], eps)
    k_norm_fp = ref.rmsnorm((h_f @ W["k_proj"]).reshape(seq, nkv, hd), W["k_norm"], eps)
    s_qn = float(np.max(np.abs(q_norm_fp))) / 127.0
    s_kn = float(np.max(np.abs(k_norm_fp))) / 127.0
    q_n, q_nrm = qk_norm(q_lin, s_q, W["q_norm"], eps, s_qn, seq, nh, hd)
    k_n, k_nrm = qk_norm(k_lin, s_k, W["k_norm"], eps, s_kn, seq, nkv, hd)

    # RoPE output scales (offline)
    cos, sin = ref.rope_tables(seq, hd, theta)
    q_rope_fp = ref.apply_rope(q_norm_fp, cos, sin)
    k_rope_fp = ref.apply_rope(k_norm_fp, cos, sin)
    s_qr = float(np.max(np.abs(q_rope_fp))) / 127.0
    s_kr = float(np.max(np.abs(k_rope_fp))) / 127.0
    cos_q, sin_q = rope_tables_q15(seq, hd, theta)
    q_r, q_rmeta = rope_int8(q_n, s_qn, cos_q, sin_q, s_qr)
    k_r, k_rmeta = rope_int8(k_n, s_kn, cos_q, sin_q, s_kr)

    return dict(
        h_q=h_q, s_h=s_h,
        q_lin=q_lin, k_lin=k_lin, v_lin=v_lin, s_q=s_q, s_k=s_k, s_v=s_v,
        q_n=q_n, k_n=k_n, s_qn=s_qn, s_kn=s_kn, q_nrm=q_nrm, k_nrm=k_nrm,
        q_r=q_r, k_r=k_r, s_qr=s_qr, s_kr=s_kr, q_rmeta=q_rmeta, k_rmeta=k_rmeta,
        cos_q=cos_q, sin_q=sin_q,
        # fp32 references for the bounded sanity check
        q_rope_fp=q_rope_fp, k_rope_fp=k_rope_fp)


if __name__ == "__main__":
    cfg = ref.CFG
    W = ref.make_weights(cfg)
    h = np.random.default_rng(11).normal(0, 1.0, (cfg["seq"], cfg["hidden"])).astype(np.float32)
    g = s2_golden(h, W, cfg)
    for name, fp in (("q_rope", g["q_rope_fp"]), ("k_rope", g["k_rope_fp"])):
        deq = g[name[0] + "_r"].astype(np.float32) * (g["s_qr"] if name[0] == "q" else g["s_kr"])
        rel = np.max(np.abs(deq - fp)) / float(np.max(np.abs(fp)))
        print(f"{name} int8 rel err {rel:.3%}")
    print("q_r[0,0,:6]:", g["q_r"][0, 0, :6].tolist())
    print("k_r[0,0,:6]:", g["k_r"][0, 0, :6].tolist())
