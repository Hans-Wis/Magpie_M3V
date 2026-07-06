"""gate_gemma3_s1_foundation — ADR-0062 S1: RMSNorm+residual numerical foundation.

Guards the S1 fixed-point contract BEFORE the RTL slice (firmware MAT_RMSNORM +
MAT_EWISE_ADD_REQUANT). Tier-C golden (gemma_quant_s1) is INT-ONLY (no float/np.sqrt in the
quant path — green-wash guard), the polynomial rsqrt is accurate, the int8 output is within a
bounded quant error of the fp32 reference (Tier-A sanity), and the eps corner (all-zero row)
is handled honestly (dropping eps would divide by zero / change the output).
"""
import re
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "design/npu/sw/gemma"))
import gemma_ref as ref  # noqa: E402
import gemma_quant_s1 as s1  # noqa: E402

SRC = ROOT / "design/npu/sw/gemma/gemma_quant_s1.py"


def _ar(rng, shape):
    return rng.normal(0, 1.0, shape).astype(np.float32)


def test_rsqrt_poly_accurate_over_range():
    for arg in (0.01, 0.12, 0.5, 1.0, 2.0, 10.0, 60.0, 1000.0):
        aq = int(round(arg * (1 << 16)))
        y, sh = s1.rsqrt_q31(aq)
        approx = y / (2.0 ** (31 + sh))
        true = 1.0 / np.sqrt(arg)
        assert abs(approx - true) / true < 2e-3, f"rsqrt({arg}) off: {approx} vs {true}"


def test_golden_rsqrt_is_int_only_no_float():
    # green-wash guard #1: rsqrt must be computed by the integer polynomial, NOT float
    # sqrt/pow. (Scale->Q-constant conversion via float() is legitimate offline SSOT setup,
    # like S0's qmul — only the nonlinear rsqrt path must be pure-int.)
    body = SRC.read_text()
    rsq = body[body.index("def rsqrt_q31"):body.index("def q_pertensor")]
    for banned in (r"np\.sqrt", r"math\.sqrt", r"\*\*\s*-?0?\.5", r"\bfloat\(", r"\.astype"):
        assert not re.search(banned, rsq), f"float rsqrt op {banned!r} leaked into rsqrt_q31"
    # and the per-element rmsnorm/residual math must not sneak a float rsqrt either
    full = body[body.index("def rmsnorm_int8"):body.index("def s1_golden")]
    assert "np.sqrt" not in full and "** -0.5" not in full, "float rsqrt in the requant path"


def test_s1_within_quant_bound():
    cfg = ref.CFG
    W = ref.make_weights(cfg)
    rng = np.random.default_rng(7)
    a, r = _ar(rng, (cfg["seq"], cfg["hidden"])), _ar(rng, (cfg["seq"], cfg["hidden"]))
    g = s1.s1_golden(a, r, W["norm_postattn"], cfg)
    an_fp = ref.rmsnorm(a, W["norm_postattn"], cfg["eps"])
    rel_n = np.max(np.abs(g["an_q"].astype(np.float32) * g["s_x"] - an_fp)) / float(np.max(np.abs(an_fp)))
    x_fp = r + an_fp
    rel_x = np.max(np.abs(g["x_q"].astype(np.float32) * g["s_out"] - x_fp)) / float(np.max(np.abs(x_fp)))
    assert rel_n < 0.05 and rel_x < 0.05, f"RMSNorm {rel_n:.3%} / residual {rel_x:.3%} exceed 5%"


def test_s1_golden_deterministic():
    cfg = ref.CFG
    W = ref.make_weights(cfg)
    rng = np.random.default_rng(7)
    a, r = _ar(rng, (cfg["seq"], cfg["hidden"])), _ar(rng, (cfg["seq"], cfg["hidden"]))
    g1 = s1.s1_golden(a, r, W["norm_postattn"], cfg)
    g2 = s1.s1_golden(a, r, W["norm_postattn"], cfg)
    assert np.array_equal(g1["an_q"], g2["an_q"]) and np.array_equal(g1["x_q"], g2["x_q"])


def test_eps_corner_all_zero_row_is_finite_and_eps_matters():
    # green-wash guard: a=0 row -> arg_q = EPS_Q only; must be finite (rsqrt of eps),
    # and EPS_Q must be non-zero (dropping it divides by zero).
    assert s1.EPS_Q > 0, "EPS_Q dropped — all-zero rows would divide by zero"
    a0 = np.zeros((1, 64), np.int64)
    out, _ = s1.rmsnorm_int8(a0, 1.0 / 128, np.zeros(64, np.float32), 1e-6, 0.02)
    assert np.all(out == 0), "zero input must normalize to zero (finite, no inf/NaN)"
    y_eps, sh = s1.rsqrt_q31(s1.EPS_Q)
    assert y_eps > 0 and np.isfinite(y_eps / (2.0 ** (31 + sh))), "rsqrt(eps) must be finite"
