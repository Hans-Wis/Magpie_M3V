#!/usr/bin/env python3
"""gemma_quant — Tier C int8 fixed-point golden for the Gemma-3 GeGLU MLP (ADR-0062, S0).

GeGLU MLP:  down( gelu_tanh(gate(x)) ⊙ up(x) ).
Quant scheme (bit-exact authority; GEMM = gemmlowp already-proven vs mat_engine):
  x int8 (per-tensor) ; W_gate/up/down int8 per-channel (symmetric, zp=0).
  gate = requant_pc( GEMM(x, Wg) )  -> int8
  gelu = GELU_LUT[gate]             -> int8   (256-entry int8->int8, derived from fp32
                                               gelu_tanh; bit-exact table lookup)
  up   = requant_pc( GEMM(x, Wu) )  -> int8
  prod = requant( gelu * up )       -> int8   (per-tensor scale_gelu*scale_up)
  out  = requant_pc( GEMM(prod, Wd))-> int8
Tier A (fp32 gemma_ref.mlp) is a bounded-error sanity check ONLY, not the golden.
GELU LUT is derived from the DOCUMENTED gelu_tanh (no fitting) -> Tier A faithful.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parents[1] / "sw/tflm_aot"))
sys.path.insert(0, str(HERE.parents[1] / "golden"))
import gemma_ref as ref  # noqa: E402
# Requant primitives come from the PROVEN mat_engine authority (mat_golden == mat_engine.v),
# NOT a local copy — a local srdhm using Python >> rounds negatives toward -inf and diverged
# from the RTL's truncate-toward-zero (Codex F1.5 review: 85/256 out bytes). Single source.
from mat_golden import srdhm, rdbpot  # noqa: E402


# ---- gemmlowp fixed-point requant (srdhm/rdbpot imported from mat_golden above) ----
def qmul(real):
    """TFLM QuantizeMultiplier -> (q31, shift<=0). Enforces the same contract as
    tflm_runtime.quantize_multiplier: shift < -31 flushes to (0,0); a left-shift
    (shift > 0) multiplier is unsupported (scope honesty), matching the engine."""
    import math
    if real == 0.0:
        return 0, 0
    q, s = math.frexp(real)
    q31 = math.floor(q * (1 << 31) + 0.5)
    if q31 == (1 << 31):
        q31 //= 2; s += 1
    if s < -31:
        return 0, 0
    if s > 0:
        raise ValueError("left-shift multiplier unsupported (scope, matches mat_engine)")
    return q31, s


def requant(acc, scale_in, scale_out, zp_out=0, amin=-128, amax=127):
    m, s = qmul(scale_in / scale_out)
    q = rdbpot(srdhm(int(acc), m), -s) + zp_out
    return max(amin, min(amax, q))


def requant_rvv(acc, scale_in, scale_out, zp_out=0, amin=-128, amax=127):
    """E1b rounding redefinition (Gemma-private, RMSNorm precedent): the scalar
    srdhm+rdbpot pair becomes the Zve32x vsmul(rnu)+vssra(rnu) chain the RVV'd
    sequencer handler executes. Primitives are the Spike-validated ones in
    golden/rvv_bitmodel.py — same (M,S) = (q31, -shift), no re-derivation."""
    import sys as _sys
    from pathlib import Path as _P
    _sys.path.insert(0, str(_P(__file__).resolve().parents[1] / "golden"))
    import rvv_bitmodel as _rvv
    m, s = qmul(scale_in / scale_out)
    q = _rvv.vssra(_rvv.vsmul(int(acc), m, 0), -s, 0) + zp_out
    return max(amin, min(amax, q))


# ---- symmetric int8 quantizers ----
def q_pertensor(x):
    s = float(np.max(np.abs(x))) / 127.0 or 1.0
    q = np.clip(np.round(x / s), -127, 127).astype(np.int64)
    return q, s


def q_perchannel(w):  # w: [cout, k], scale per cout row
    s = np.maximum(np.max(np.abs(w), axis=1) / 127.0, 1e-12)
    q = np.clip(np.round(w / s[:, None]), -127, 127).astype(np.int64)
    return q, s


def gemm_pc(x_q, w_q, sx, sw, sout, relu=False):
    """out[s][j] = requant_pc( sum_k x_q[s][k]*w_q[j][k] ). x_q [S][K], w_q [N][K]."""
    S, K = x_q.shape
    N = w_q.shape[0]
    amin = 0 if relu else -128         # note: our fold path uses zp; here zp=0 symmetric
    out = np.zeros((S, N), np.int64)
    for si in range(S):
        for j in range(N):
            acc = int(np.dot(x_q[si], w_q[j]))
            out[si, j] = requant(acc, sx * sw[j], sout, 0, amin, 127)
    return out


def gelu_lut(scale_in, scale_out):
    """256-entry int8->int8 LUT: q_out = requant(gelu_tanh(dequant(q_in))). Documented,
    not fitted -> Tier A faithful. Index by (int8 value + 128)."""
    lut = np.zeros(256, np.int64)
    for v in range(-128, 128):
        g = float(ref.gelu_tanh(np.array([v * scale_in], np.float32))[0])
        lut[v + 128] = max(-128, min(127, int(np.round(g / scale_out))))
    return lut


def geglu_int8(x_f, W, cfg):
    """Tier C int8 GeGLU. Returns dict of int8 checkpoints + scales."""
    hid, inter = cfg["hidden"], cfg["intermediate"]
    x_q, sx = q_pertensor(x_f)
    wg_q, swg = q_perchannel(W["gate_proj"].T)   # [inter][hidden]
    wu_q, swu = q_perchannel(W["up_proj"].T)
    wd_q, swd = q_perchannel(W["down_proj"].T)    # [hidden][inter]

    # scale choices: keep outputs ~1/127 of observed fp32 range (documented, per-tensor)
    s_gate = float(np.max(np.abs(x_f @ W["gate_proj"]))) / 127.0
    s_up = float(np.max(np.abs(x_f @ W["up_proj"]))) / 127.0
    gate_ref = ref.gelu_tanh(x_f @ W["gate_proj"])
    s_gelu = float(np.max(np.abs(gate_ref))) / 127.0
    prod_ref = gate_ref * (x_f @ W["up_proj"])
    s_prod = float(np.max(np.abs(prod_ref))) / 127.0
    s_out = float(np.max(np.abs(ref.mlp(x_f, W)))) / 127.0

    gate_q = gemm_pc(x_q, wg_q, sx, swg, s_gate)
    up_q = gemm_pc(x_q, wu_q, sx, swu, s_up)
    lut = gelu_lut(s_gate, s_gelu)
    gelu_q = np.array([[lut[int(v) + 128] for v in row] for row in gate_q], np.int64)
    prod_q = np.array([[requant(int(gelu_q[s, j]) * int(up_q[s, j]),
                                s_gelu * s_up, s_prod) for j in range(inter)]
                       for s in range(x_q.shape[0])], np.int64)
    out_q = gemm_pc(prod_q, wd_q, s_prod, swd, s_out)
    return dict(x_q=x_q, sx=sx, gate_q=gate_q, up_q=up_q, gelu_q=gelu_q,
                prod_q=prod_q, out_q=out_q, s_out=s_out, lut=lut,
                scales=dict(gate=s_gate, up=s_up, gelu=s_gelu, prod=s_prod, out=s_out))


if __name__ == "__main__":
    cfg = ref.CFG
    W = ref.make_weights(cfg)
    x = np.random.default_rng(42).normal(0, 1.0, (cfg["seq"], cfg["hidden"])).astype(np.float32)
    r = geglu_int8(x, W, cfg)
    # Tier A bounded-error sanity (NOT the bit-exact golden)
    out_fp32 = ref.mlp(x, W)
    out_deq = r["out_q"].astype(np.float32) * r["s_out"]
    err = np.max(np.abs(out_deq - out_fp32))
    rng = float(np.max(np.abs(out_fp32)))
    print(f"S0 GeGLU int8: out {r['out_q'].shape}  max_abs_err={err:.4f} "
          f"range={rng:.4f}  rel={err/rng:.3%}")
    print("gate_q[0][:6]:", r["gate_q"][0][:6].tolist())
    print("gelu_q[0][:6]:", r["gelu_q"][0][:6].tolist())
    print("out_q[0][:6]:", r["out_q"][0][:6].tolist())
