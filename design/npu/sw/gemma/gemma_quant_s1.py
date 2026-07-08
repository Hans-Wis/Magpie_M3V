#!/usr/bin/env python3
"""gemma_quant_s1 — Tier C int8 fixed-point golden for the Gemma S1 slice (ADR-0062):
post-attention RMSNorm + residual. Bit-exact authority; the rv32im sequencer firmware
(MAT_RMSNORM + MAT_EWISE_ADD_REQUANT) must reproduce every checkpoint byte-identical.

  a_normed = RMSNorm(a) = a * rsqrt(mean(a^2)+eps) * (1 + w)     # per row over hidden
  x        = r + a_normed                                        # residual

Fixed-point contract (Grok S1 review, 2026-07-06_gemma_s1_rmsnorm_rsqrt_grok.md):
- rsqrt = degree-3 polynomial on the normalized mantissa (NO scalar-F, NO float). arg is
  UQ*.16; output UQ0.31 with an exponent correction (1/sqrt(2) for odd exponents).
- arg_q = mean_sq*SA2_Q + EPS_Q folds s_a^2 and eps (eps kept: EPS_Q=round(eps*2^16)=66).
- (1+w) is int16 Q2.14; final requant is RVV-native:
  prod=src*w_q16; q=vsmul(prod,M,rnu); q=vssra(q,S,rnu); sat8(q).
- residual: acc = r*R_NUM + a_normed*X_NUM; sat8((acc+2^(SHIFT-1))>>SHIFT).
INT ONLY: no np.sqrt / **-0.5 / float in the quant path (green-wash guard).
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "golden"))
import gemma_ref as ref  # noqa: E402
import rvv_bitmodel as rvv  # noqa: E402

# rsqrt cubic on the mantissa m=1+f, f in [0,1) (UQ0.16). Coeffs Q0.31; Horner in the
# f-integer domain. Fit once, frozen here (SSOT); the .h/.rodata for firmware share these.
RSQRT_C = [  # c0 + c1*t + c2*t^2 + c3*t^3, t = f/2^16 in [0,1)
    round(0.999133573 * (1 << 31)),
    round(-0.480801012 * (1 << 31)),
    round(0.271844597 * (1 << 31)),
    round(-0.083683222 * (1 << 31)),
]
EPS_Q = 66            # round(1e-6 * 2^16)
INV_SQRT2_Q16 = 46341  # round(2^16 / sqrt(2))


def _clz64(x: int) -> int:
    return 64 - x.bit_length()


def rsqrt_q31(arg_q: int) -> tuple[int, int]:
    """arg_real = arg_q / 2^16 (arg_q > 0). Returns (y_adj, sh) with
    rsqrt(arg_real) == y_adj / 2^(31 + sh)  (sh may be negative for arg_real < 1). Pure int;
    e even -> shift e/2, e odd -> INV_SQRT2 factor + shift (e-1)/2 (arithmetic identity
    2^(-e/2) = 2^(-(e-1)/2)/sqrt2)."""
    assert arg_q > 0
    p = arg_q.bit_length() - 1             # MSB index -> m = arg_q / 2^p in [1,2)
    norm = (arg_q >> (p - 47)) if p >= 47 else (arg_q << (47 - p))   # MSB at bit 47
    f = (norm >> (47 - 16)) & 0xFFFF        # UQ0.16 fraction of the mantissa
    acc = RSQRT_C[3]                         # Horner in the f domain, Q0.31
    for ci in (RSQRT_C[2], RSQRT_C[1], RSQRT_C[0]):
        acc = (((acc * f) + (1 << 15)) >> 16) + ci
    y_adj = acc                             # rsqrt(m) in UQ0.31, m in [1,2)
    e = p - 16                              # arg_real = m * 2^e
    if e & 1:                               # odd (works for negative e too: -3&1==1 in python)
        y_adj = ((y_adj * INV_SQRT2_Q16) + (1 << 15)) >> 16
        sh = (e - 1) >> 1                    # floor((e-1)/2); python >> floors -> correct for e<0
    else:
        sh = e >> 1
    return y_adj, sh


def q_pertensor(x):
    s = float(np.max(np.abs(x))) / 127.0 or 1.0
    q = np.clip(np.round(x / s), -127, 127).astype(np.int64)
    return q, s


def rmsnorm_rvv_ms(y_adj: int, out_num: int, sh: int) -> tuple[int, int, int, int]:
    """Normalize P=y_adj*OUT_NUM into RVV vsmul multiplier M and vssra shift S."""
    P = int(y_adj) * int(out_num)
    assert P > 0
    for k in range(0, 64):
        M = (P + (1 << (k - 1))) >> k if k > 0 else P
        S = 30 + int(sh) - k
        if M <= rvv.INT32_MAX and 0 <= S <= 31:
            return int(M), int(S), int(k), int(P)
    raise AssertionError(f"RMSNorm RVV M/S normalization failed: P={P} sh={sh}")


def rmsnorm_int8(a_q, s_a, w, eps, s_x):
    """a_q [seq][H] int8 -> a_normed int8 @ s_x. Pure int fixed-point per Grok's contract."""
    seq, H = a_q.shape
    SA2_Q = int(round(s_a * s_a * (1 << 16)))
    w_q16 = np.array([int(round((1.0 + wi) * (1 << 14))) for wi in w], np.int64)  # Q2.14
    OUT_NUM = int(round((s_a / s_x) * (1 << 16)))
    out = np.zeros((seq, H), np.int64)
    dbg = []
    for r in range(seq):
        sum_sq = int(np.sum(a_q[r].astype(np.int64) ** 2))
        mean_sq = sum_sq // H
        arg_q = mean_sq * SA2_Q + EPS_Q
        y_adj, sh = rsqrt_q31(arg_q)
        M, S, k, P = rmsnorm_rvv_ms(y_adj, OUT_NUM, sh)
        for i in range(H):
            prod = int(a_q[r, i]) * int(w_q16[i])          # exact src*(1+w) Q2.14
            q = rvv.vsmul(prod, M, 0)
            q = rvv.vssra(q, S, 0)
            out[r, i] = rvv.sat8(q)
        dbg.append(dict(sum_sq=sum_sq, mean_sq=mean_sq, arg_q=arg_q, y_adj=y_adj, sh=sh,
                        M=M, S=S, k=k, P=P))
    return out, dict(SA2_Q=SA2_Q, OUT_NUM=OUT_NUM, w_q16=w_q16.tolist(), rows=dbg)


def residual_add_int8(r_q, s_r, an_q, s_x, s_out):
    seq, H = r_q.shape
    R_NUM = int(round((s_r / s_out) * (1 << 16)))
    X_NUM = int(round((s_x / s_out) * (1 << 16)))
    out = np.zeros((seq, H), np.int64)
    for i in range(seq):
        for j in range(H):
            acc = int(r_q[i, j]) * R_NUM + int(an_q[i, j]) * X_NUM
            v = (acc + (1 << 15)) >> 16
            out[i, j] = max(-128, min(127, v))
    return out, dict(R_NUM=R_NUM, X_NUM=X_NUM)


def s1_golden(a_f, r_f, w, cfg):
    """Tier C S1: RMSNorm(a) + residual(r). Returns int8 checkpoints + scales + SSOT."""
    eps = cfg["eps"]
    a_q, s_a = q_pertensor(a_f)
    r_q, s_r = q_pertensor(r_f)
    # output scales chosen offline (documented) from the fp32 dynamic ranges
    an_ref = ref.rmsnorm(a_f, w, eps)
    s_x = float(np.max(np.abs(an_ref))) / 127.0
    x_ref = r_f + an_ref
    s_out = float(np.max(np.abs(x_ref))) / 127.0
    an_q, nrm = rmsnorm_int8(a_q, s_a, w, eps, s_x)
    x_q, res = residual_add_int8(r_q, s_r, an_q, s_x, s_out)
    return dict(a_q=a_q, r_q=r_q, an_q=an_q, x_q=x_q, s_a=s_a, s_r=s_r, s_x=s_x, s_out=s_out,
                nrm=nrm, res=res, coeffs=RSQRT_C, eps_q=EPS_Q)


if __name__ == "__main__":
    cfg = ref.CFG
    W = ref.make_weights(cfg)
    rng = np.random.default_rng(7)
    a = rng.normal(0, 1.0, (cfg["seq"], cfg["hidden"])).astype(np.float32)
    r = rng.normal(0, 1.0, (cfg["seq"], cfg["hidden"])).astype(np.float32)
    g = s1_golden(a, r, W["norm_postattn"], cfg)
    # Tier A bounded-error sanity (NOT bit-exact authority)
    an_fp = ref.rmsnorm(a, W["norm_postattn"], cfg["eps"])
    an_deq = g["an_q"].astype(np.float32) * g["s_x"]
    rel_n = np.max(np.abs(an_deq - an_fp)) / float(np.max(np.abs(an_fp)))
    x_fp = r + an_fp
    x_deq = g["x_q"].astype(np.float32) * g["s_out"]
    rel_x = np.max(np.abs(x_deq - x_fp)) / float(np.max(np.abs(x_fp)))
    print(f"RMSNorm int8 rel err {rel_n:.3%} ; residual int8 rel err {rel_x:.3%}")
    print("an_q[0][:6]:", g["an_q"][0][:6].tolist())
    print("x_q[0][:6]: ", g["x_q"][0][:6].tolist())
