#!/usr/bin/env python3
"""tflm_runtime — ADR-0041 online half: lower one FC layer of model.json to a
CQ batch + TCM blob and package the shared-memory image for the RTL run.

No TensorFlow here: this is the deployment-side runtime (Coral's libedgetpu
role) — it loads the AOT artifacts, lowers per-op through the SSOT codec,
rings the doorbell (in DV: via tb_npu_tflm_model), and unpacks results.

Lowering (generalizes ADR-0039 compile_fc):
- column tiles of 8 outputs; per tile: ACC_CLR(W2=fold_t) -> OP(a, b_t, RPT=K)
  -> RESCALE -> STORE(dst_t). The a blob is shared by all tiles.
- requant params via TFLM QuantizeMultiplier (frexp -> Q31 + shift); only
  right shifts are representable (engine shift = 31 - s in [31,62]) — a
  left-shift multiplier raises (scope honesty).
- fused ReLU: act_min = max(-128, output_zp), act_max = 127 (TFLM
  CalculateActivationRangeQuantized).
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "IP/npu/sw"))
sys.path.insert(0, str(ROOT / "IP/npu/golden"))

import cq_codec  # noqa: E402  (SSOT — generated)
from tflm_fc import wrap32  # noqa: E402

TCM_BLOB_B = 0x600
A_OFF = 0x240                # a-vectors (past the 0x800 MAT_OUT hole gap map)
MAT_OUT_B = 0x800
SHARED_BLOB_B = 0x2000
SHARED_DST_B = 0x1800
ART = Path(__file__).resolve().parent / "artifacts"


def quantize_multiplier(real: float):
    """TFLM QuantizeMultiplier (quantization_util.cc): real = q31/2^31 * 2^shift.
    TfLiteRound = half away from zero (NOT python banker's round); shift < -31
    flushes to (0, 0) exactly like TFLite (Codex ADR-0041 finding #1)."""
    if real == 0.0:
        return 0, 0
    q, shift = math.frexp(real)
    q31 = math.floor(q * (1 << 31) + 0.5)   # q in [0.5, 1): half away == half up
    if q31 == (1 << 31):
        q31 //= 2
        shift += 1
    if shift < -31:
        return 0, 0
    if shift > 0:
        raise ValueError("left-shift multiplier unsupported (scope, ADR-0041)")
    return q31, shift


def act_range(layer):
    zp = layer["output_zp"]
    return (max(-128, zp), 127) if layer["relu"] else (-128, 127)


def lower_layer(layer, inputs):
    """inputs: [8][K] int8 lists. Returns (blob, ring_words, n_tiles)."""
    k, n = layer["k"], layer["n"]
    assert len(inputs) == 8 and len(inputs[0]) == k
    assert n % 8 == 0 and k % 8 == 0 and 8 <= k <= 64, "scope (ADR-0041)"
    n_tiles = n // 8
    w, bias = layer["weights"], layer["bias"]
    input_offset = -layer["input_zp"]
    mult, shift = quantize_multiplier(
        layer["input_scale"] * layer["weight_scale"] / layer["output_scale"])
    eng_shift = 31 - shift
    amin, amax = act_range(layer)

    b_base = A_OFF + 8 * k
    blob = bytearray(b_base + n_tiles * 8 * k)
    for t in range(n_tiles):
        for c in range(8):
            f = wrap32(bias[t * 8 + c] +
                       input_offset * sum(w[t * 8 + c])) & 0xFFFFFFFF
            blob[t * 0x20 + 4 * c: t * 0x20 + 4 * c + 4] = f.to_bytes(4, "little")
        for kk in range(k):
            for c in range(8):
                blob[b_base + t * 8 * k + 8 * kk + c] = w[t * 8 + c][kk] & 0xFF
    for kk in range(k):
        for r in range(8):
            blob[A_OFF + 8 * kk + r] = inputs[r][kk] & 0xFF

    words = (len(blob) + 3) // 4
    rows = (words + 15) // 16
    blob.extend(b"\0" * (rows * 16 * 4 - len(blob)))

    ring = []
    ring += cq_codec.encode("MAT_CFG", m=8, n=8, k=8 * k)
    ring += cq_codec.encode("MAT_LOAD_W", src_addr=0x80000000 | SHARED_BLOB_B,
                            rows=rows, cols=16)
    for t in range(n_tiles):
        last = (t == n_tiles - 1)
        ring += cq_codec.encode("MAT_ACC_CLR", acc_mask=1,
                                bias_tcm_byte=TCM_BLOB_B + t * 0x20)
        ring += cq_codec.encode("MAT_OP", a_addr=TCM_BLOB_B + A_OFF,
                                b_addr=TCM_BLOB_B + b_base + t * 8 * k,
                                rpt=k, acc=0)
        ring += cq_codec.encode("MAT_RESCALE", multiplier_q31=mult,
                                out_zp=layer["output_zp"], shift=eng_shift,
                                clamp_min=amin, clamp_max=amax, acc=0)
        ring += cq_codec.encode("MAT_STORE",
                                dst_addr=0x80000000 | (SHARED_DST_B + t * 0x40),
                                stride=MAT_OUT_B, rows=4, cols=4,
                                irq=1 if last else 0, last=1 if last else 0)
    return bytes(blob), ring, n_tiles


def emit_layer(outdir: Path, layer, inputs):
    blob, ring, n_tiles = lower_layer(layer, inputs)
    assert len(ring) // 4 <= 16, "ring capacity"
    outdir.mkdir(parents=True, exist_ok=True)
    lines = ["@00000100"] + ["%08x" % x for x in ring]
    lines.append("@00000800")
    for i in range(0, len(blob), 4):
        lines.append("%08x" % int.from_bytes(blob[i:i + 4], "little"))
    (outdir / "tflm_shared.hex").write_text("\n".join(lines) + "\n")
    (outdir / "tflm_meta.hex").write_text(
        "%08x\n%08x\n" % (len(ring) // 4, n_tiles * 16))
    return n_tiles


def unpack_result(dump_path: Path, n_tiles: int, n: int):
    """result.dump words -> [8][n] int8 (tile t words t*16..t*16+15)."""
    words = [int(x, 16) for x in dump_path.read_text().split()]
    assert len(words) == n_tiles * 16
    out = [[0] * n for _ in range(8)]
    for t in range(n_tiles):
        raw = b"".join(w.to_bytes(4, "little") for w in words[t * 16:(t + 1) * 16])
        for r in range(8):
            for c in range(8):
                if t * 8 + c < n:
                    v = raw[r * 8 + c]
                    out[r][t * 8 + c] = v - 256 if v > 127 else v
    return out


def load_artifacts():
    model = json.loads((ART / "model.json").read_text())
    golden = json.loads((ART / "golden.json").read_text())
    return model, golden
