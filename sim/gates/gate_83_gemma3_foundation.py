"""gate_83_gemma3_foundation — ADR-0062: Gemma-3 decoder-layer verification foundation.

Guards the numerical foundation BEFORE the RTL slices (S0..S5):
- fp32 reference decoder layer (gemma_ref) runs, finite, correct shapes;
- Tier C int8 GeGLU golden (gemma_quant) is deterministic and within a bounded quant
  error of the fp32 reference (Tier A sanity — NOT the bit-exact authority);
- the GELU LUT is derived from the documented gelu_tanh (256 int8->int8 entries),
  not fitted (green-wash guard: golden must not use np.tanh as the RTL path).

This is Tier A/C self-consistency; the bit-exact RTL checkpoints land with S0 (gate_*
gemma3_s0_geglu). No RTL here — pure golden integrity.
"""
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "IP/npu/sw/gemma"))
import gemma_ref as ref  # noqa: E402
import gemma_quant as q  # noqa: E402


def _x(cfg):
    return np.random.default_rng(42).normal(
        0, 1.0, (cfg["seq"], cfg["hidden"])).astype(np.float32)


def test_fp32_reference_layer_runs():
    cfg = ref.CFG
    W = ref.make_weights(cfg)
    y = ref.decoder_layer(_x(cfg), W, cfg)
    assert y.shape == (cfg["seq"], cfg["hidden"])
    assert np.isfinite(y).all()


def test_geglu_int8_within_quant_bound():
    cfg = ref.CFG
    W = ref.make_weights(cfg)
    x = _x(cfg)
    r = q.geglu_int8(x, W, cfg)
    out_deq = r["out_q"].astype(np.float32) * r["s_out"]
    out_fp32 = ref.mlp(x, W)
    rel = np.max(np.abs(out_deq - out_fp32)) / float(np.max(np.abs(out_fp32)))
    assert rel < 0.05, f"GeGLU int8 rel error {rel:.3%} exceeds 5% quant bound"


def test_geglu_golden_deterministic():
    cfg = ref.CFG
    W = ref.make_weights(cfg)
    x = _x(cfg)
    a = q.geglu_int8(x, W, cfg)["out_q"]
    b = q.geglu_int8(x, W, cfg)["out_q"]
    assert np.array_equal(a, b), "Tier C golden must be deterministic (bit-exact authority)"


def test_gelu_lut_is_documented_not_fitted():
    # LUT[v] must equal requant(gelu_tanh(dequant(v))) for a sample of entries —
    # i.e. derived from the documented activation, not tuned to pass.
    si, so = 0.02, 0.015
    lut = q.gelu_lut(si, so)
    assert len(lut) == 256
    for v in (-128, -40, 0, 37, 127):
        g = float(ref.gelu_tanh(np.array([v * si], np.float32))[0])
        assert lut[v + 128] == max(-128, min(127, int(np.round(g / so))))
    # gelu_tanh dips near x=-0.75 then rises; large-positive saturates to identity-ish.
    # sanity: strictly increasing on the positive half, and the min is on the negative half.
    pos = [lut[v + 128] for v in range(0, 128)]
    assert all(pos[i + 1] >= pos[i] for i in range(len(pos) - 1)), "gelu increasing for x>=0"
    assert int(np.argmin(lut)) < 128, "gelu minimum must be on the negative half"
