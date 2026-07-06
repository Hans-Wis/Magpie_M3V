#!/usr/bin/env python3
"""gemma_quant_layer — Tier C int8 fixed-point golden for the FULL Gemma-3 decoder layer
(ADR-0062 S4/S5). Composes S0..S3 with consistent scale-chaining. Bit-exact authority; the
NPU RTL (mat_engine GEMMs + sequencer-core nonlinear ops) must reproduce every checkpoint.

Decoder layer (Gemma-3 sandwich norm), int8 end-to-end:
  # attention sub-block (S4 output = x_mid)
  r1 = x ; hin = RMSNorm_in(x)
  q,k,v = proj(hin) ; qn,kn = QK-norm ; qr,kr = RoPE
  attn = softmax(qr kr^T)·v  (S3, GQA) ; a_o = o_proj(attn)
  a_n = RMSNorm_postattn(a_o) ; x_mid = r1 + a_n
  # MLP sub-block (S5 output = x_out)
  r2 = x_mid ; hff = RMSNorm_preffn(x_mid)
  m = down( gelu(gate(hff)) * up(hff) )  (S0 GeGLU)
  m_n = RMSNorm_postffn(m) ; x_out = r2 + m_n

Scales are chosen offline from the fp32 forward pass (Tier A) and every int8 op consumes the
previous op's int8 output at the previous op's output scale. fp32 is a bounded sanity check.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parents[1] / "golden"))
import gemma_ref as ref  # noqa: E402
import gemma_quant as gq  # noqa: E402
import gemma_quant_s1 as s1  # noqa: E402
import gemma_quant_s2 as s2  # noqa: E402
import gemma_quant_s3 as s3  # noqa: E402


def _s(x):
    return float(np.max(np.abs(x))) / 127.0 or 1.0


def _proj(x_q, s_x, w_fp, x_fp):
    w_q, sw = gq.q_perchannel(w_fp.T)
    s_out = _s(x_fp @ w_fp)
    lin = np.clip(gq.gemm_pc(x_q, w_q, s_x, sw, s_out), -128, 127).astype(np.int64)
    return lin, s_out


def _rmsnorm(a_q, s_a, w, eps, a_fp_normed):
    s_out = _s(a_fp_normed)
    out, nrm = s1.rmsnorm_int8(a_q, s_a, w, eps, s_out)
    return out, s_out, nrm


def layer_int8(x_f, W, cfg):
    seq, nh, nkv, hd = cfg["seq"], cfg["n_heads"], cfg["n_kv_heads"], cfg["head_dim"]
    hid, inter, eps, theta = cfg["hidden"], cfg["intermediate"], cfg["eps"], cfg["rope_theta"]
    ck = {}                                     # checkpoints (int8) + scales + firmware SSOT

    # ---- fp32 forward (scale source, Tier A) ----
    hin_fp = ref.rmsnorm(x_f, W["norm_in"], eps)
    q_fp = (hin_fp @ W["q_proj"]).reshape(seq, nh, hd)
    k_fp = (hin_fp @ W["k_proj"]).reshape(seq, nkv, hd)
    v_fp = (hin_fp @ W["v_proj"]).reshape(seq, nkv, hd)
    qn_fp = ref.rmsnorm(q_fp, W["q_norm"], eps)
    kn_fp = ref.rmsnorm(k_fp, W["k_norm"], eps)
    cos, sin = ref.rope_tables(seq, hd, theta)
    qr_fp = ref.apply_rope(qn_fp, cos, sin)
    kr_fp = ref.apply_rope(kn_fp, cos, sin)
    a_fp = ref.self_attn(hin_fp, W, cfg)        # includes o_proj
    an_fp = ref.rmsnorm(a_fp, W["norm_postattn"], eps)
    xmid_fp = x_f + an_fp
    hff_fp = ref.rmsnorm(xmid_fp, W["norm_preffn"], eps)
    m_fp = ref.mlp(hff_fp, W)
    mn_fp = ref.rmsnorm(m_fp, W["norm_postffn"], eps)
    xout_fp = xmid_fp + mn_fp

    # ---- int8 forward (chained) ----
    x_q, s_x = gq.q_pertensor(x_f)
    ck.update(x_q=x_q, s_x=s_x)

    hin_q, s_hin, nrm_in = _rmsnorm(x_q, s_x, W["norm_in"], eps, hin_fp)
    ck.update(hin_q=hin_q, s_hin=s_hin, nrm_in=nrm_in)

    q_lin, s_q = _proj(hin_q, s_hin, W["q_proj"], hin_fp)
    k_lin, s_k = _proj(hin_q, s_hin, W["k_proj"], hin_fp)
    v_lin, s_v = _proj(hin_q, s_hin, W["v_proj"], hin_fp)

    s_qn = _s(qn_fp)
    s_kn = _s(kn_fp)
    qn_q, q_nrm = s1.rmsnorm_int8(q_lin.reshape(seq * nh, hd), s_q, W["q_norm"], eps, s_qn)
    kn_q, k_nrm = s1.rmsnorm_int8(k_lin.reshape(seq * nkv, hd), s_k, W["k_norm"], eps, s_kn)

    cos_q, sin_q = s2.rope_tables_q15(seq, hd, theta)
    s_qr, s_kr = _s(qr_fp), _s(kr_fp)
    qr_q, q_rmeta = s2.rope_int8(qn_q.reshape(seq, nh, hd), s_qn, cos_q, sin_q, s_qr)
    kr_q, k_rmeta = s2.rope_int8(kn_q.reshape(seq, nkv, hd), s_kn, cos_q, sin_q, s_kr)
    ck.update(q_nrm=q_nrm, k_nrm=k_nrm, q_rmeta=q_rmeta, k_rmeta=k_rmeta,
              cos_q=cos_q, sin_q=sin_q, s_q=s_q, s_k=s_k, s_v=s_v, s_qn=s_qn, s_kn=s_kn,
              s_qr=s_qr, s_kr=s_kr, qr_q=qr_q, kr_q=kr_q, v_lin=v_lin)

    v_r = v_lin.reshape(seq, nkv, hd)
    g3 = s3.s3_golden(qr_q, s_qr, kr_q, s_kr, v_r, s_v, cfg, qr_fp, kr_fp, v_fp)
    attn_q, s_attn = g3["attn"], g3["s_av"]
    ck.update(g3=g3, attn_q=attn_q, s_attn=s_attn)

    ao_q, s_ao = _proj(attn_q, s_attn, W["o_proj"], g3["attn_fp"])   # o_proj input = pre-o_proj attn
    an_q, s_an, nrm_pa = _rmsnorm(ao_q, s_ao, W["norm_postattn"], eps, an_fp)
    s_xmid = _s(xmid_fp)
    xmid_q, res1 = s1.residual_add_int8(x_q, s_x, an_q, s_an, s_xmid)
    ck.update(ao_q=ao_q, s_ao=s_ao, an_q=an_q, s_an=s_an, nrm_pa=nrm_pa,
              xmid_q=xmid_q, s_xmid=s_xmid, res1=res1)      # xmid_q = S4 output

    # ---- MLP sub-block (S5) ----
    hff_q, s_hff, nrm_pf = _rmsnorm(xmid_q, s_xmid, W["norm_preffn"], eps, hff_fp)
    gate_lin, s_gate = _proj(hff_q, s_hff, W["gate_proj"], hff_fp)
    up_lin, s_up = _proj(hff_q, s_hff, W["up_proj"], hff_fp)
    gate_fp = ref.gelu_tanh(hff_fp @ W["gate_proj"])
    s_gelu = _s(gate_fp)
    lut = gq.gelu_lut(s_gate, s_gelu)
    gelu_q = np.array([[lut[int(v) + 128] for v in row] for row in gate_lin], np.int64)
    prod_fp = gate_fp * (hff_fp @ W["up_proj"])
    s_prod = _s(prod_fp)
    m_qmul, m_shift = gq.qmul(s_gelu * s_up / s_prod)
    prod_q = np.array([[gq.requant(int(gelu_q[i, j]) * int(up_lin[i, j]), s_gelu * s_up, s_prod)
                        for j in range(inter)] for i in range(seq)], np.int64)
    m_lin, s_m = _proj(prod_q, s_prod, W["down_proj"], prod_fp)
    mn_q, s_mn, nrm_pff = _rmsnorm(m_lin, s_m, W["norm_postffn"], eps, mn_fp)
    s_xout = _s(xout_fp)
    xout_q, res2 = s1.residual_add_int8(xmid_q, s_xmid, mn_q, s_mn, s_xout)
    ck.update(hff_q=hff_q, s_hff=s_hff, nrm_pf=nrm_pf, gate_lin=gate_lin, s_gate=s_gate,
              up_lin=up_lin, s_up=s_up, gelu_q=gelu_q, s_gelu=s_gelu, lut=lut,
              prod_q=prod_q, s_prod=s_prod, m_ewise=(m_qmul, m_shift), m_lin=m_lin, s_m=s_m,
              mn_q=mn_q, s_mn=s_mn, nrm_pff=nrm_pff, xout_q=xout_q, s_xout=s_xout, res2=res2)

    ck.update(xmid_fp=xmid_fp, xout_fp=xout_fp)
    return ck


if __name__ == "__main__":
    cfg = ref.CFG
    W = ref.make_weights(cfg)
    x = np.random.default_rng(23).normal(0, 1.0, (cfg["seq"], cfg["hidden"])).astype(np.float32)
    ck = layer_int8(x, W, cfg)
    for name in ("xmid", "xout"):
        deq = ck[f"{name}_q"].astype(np.float32) * ck[f"s_{name}"]
        rel = np.max(np.abs(deq - ck[f"{name}_fp"])) / float(np.max(np.abs(ck[f"{name}_fp"])))
        print(f"{name} (S4/S5) int8 rel err {rel:.3%}")
    # cross-check against the pure fp32 decoder layer
    y = ref.decoder_layer(x, W, cfg)
    print("xout matches decoder_layer fp32:", np.allclose(y, ck["xout_fp"], atol=1e-5))
    print("xout_q[0][:6]:", ck["xout_q"][0][:6].tolist())
