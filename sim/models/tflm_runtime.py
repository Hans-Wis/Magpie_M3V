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

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "design/npu/sw"))
sys.path.insert(0, str(ROOT / "design/npu/golden"))

import cq_codec  # noqa: E402  (SSOT — generated)
from tflm_fc import wrap32  # noqa: E402

TCM_BLOB_B = 0x700
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
        "%08x\n%08x\n%08x\n" % (len(ring) // 4, n_tiles * 16, 16))
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


# ---------------------------------------------------------------------------
# ADR-0042: generalized lowering — CONV_2D (host im2col), K>64 chunking,
# PER-CHANNEL requant (MAT_RESCALE RPT=1 -> engine RESCALE_PC).
# ---------------------------------------------------------------------------
PARAM_OFF = 0x20            # per-tile param block inside the job blob header
JOB_STRIDE_B = 0x800        # shared-mem spacing between job blobs


def _chunks(k):
    out = []
    while k > 0:
        c = min(64, k)
        out.append(c)
        k -= c
    return out


def conv_out_geometry(layer):
    """TFLM Conv2D output geometry + SAME pad offsets (ADR-0065, dilation 1).
    SAME: oh = ceil(H/S); pad_total = max((oh-1)*S + K - H, 0); pad_before = total//2
    (the remainder lands at bottom/right — TFLM's asymmetric split). Returns
    (oh, ow, pad_top, pad_left)."""
    kh, kw, s = layer["kh"], layer["kw"], layer["stride"]
    h, w = layer["in_h"], layer["in_w"]
    pad = layer.get("padding", "valid")
    if pad == "same":
        oh, ow = -(-h // s), -(-w // s)                      # ceil
        pth = max((oh - 1) * s + kh - h, 0)
        ptw = max((ow - 1) * s + kw - w, 0)
        return oh, ow, pth // 2, ptw // 2
    assert pad == "valid", f"unsupported padding {pad!r} (scope valid|same, ADR-0065)"
    return (h - kh) // s + 1, (w - kw) // s + 1, 0, 0


def im2col(layer, x):
    """x: [H][W][Cin] int8 -> rows[oh*ow][K]. Supports stride>=1 and VALID/SAME
    padding (dilation 1, ADR-0065). SAME pads with the INPUT ZERO-POINT so padded
    taps contribute 0 through the input_offset fold (TFLM asymmetric-int8 semantic).
    K order is (ky,kx,ci) to match the [cout,kh,kw,cin]->[cout,K] weight flatten."""
    kh, kw, cin = layer["kh"], layer["kw"], layer["cin"]
    h, w, s = layer["in_h"], layer["in_w"], layer["stride"]
    izp = layer["input_zp"]
    oh, ow, pt, pl = conv_out_geometry(layer)
    rows = []
    for oy in range(oh):
        for ox in range(ow):
            row = []
            for ky in range(kh):
                for kx in range(kw):
                    iy, ix = oy * s + ky - pt, ox * s + kx - pl
                    inside = 0 <= iy < h and 0 <= ix < w
                    for ci in range(cin):
                        row.append(x[iy][ix][ci] if inside else izp)
            rows.append(row)
    return rows


def lower_layer_v2(layer, rows):
    """rows: [n_rows][K] int8 (any n_rows; padded to groups of 8).
    Returns (segments [(shared_byte, bytes)], ring words, n_groups, n_tiles)."""
    if layer["kind"] == "conv":
        n_out, k = layer["cout"], layer["kh"] * layer["kw"] * layer["cin"]
    else:
        n_out, k = layer["n"], layer["k"]
    assert n_out % 8 == 0 and k % 8 == 0, "pad upstream (scope)"
    n_tiles = n_out // 8
    n_groups = (len(rows) + 7) // 8
    rows = [list(r) for r in rows] +            [[0] * k for _ in range(n_groups * 8 - len(rows))]
    w = layer["weights"]
    input_offset = -layer["input_zp"]
    amin, amax = act_range(layer)
    chunks = _chunks(k)

    segments, ring = [], []
    job = 0
    for g in range(n_groups):
        for tile in range(n_tiles):
            fold = bytearray()
            for c in range(8):
                f = wrap32(layer["bias"][tile * 8 + c] +
                           input_offset * sum(w[tile * 8 + c])) & 0xFFFFFFFF
                fold += f.to_bytes(4, "little")
            header = bytes(fold).ljust(PARAM_OFF, b"\0") +                 _param_block_tile(layer, tile)
            k_off = 0
            for ci, ch in enumerate(chunks):
                blob = bytearray(header.ljust(A_OFF, b"\0"))
                for kk in range(ch):
                    for r in range(8):
                        blob.append(rows[g * 8 + r][k_off + kk] & 0xFF)
                for kk in range(ch):
                    for c in range(8):
                        blob.append(w[tile * 8 + c][k_off + kk] & 0xFF)
                words = (len(blob) + 3) // 4
                lw_rows = (words + 15) // 16
                blob.extend(b"\0" * (lw_rows * 16 * 4 - len(blob)))
                src = SHARED_BLOB_B + (job * len(chunks) + ci) * JOB_STRIDE_B
                segments.append((src, bytes(blob)))
                ring += cq_codec.encode("MAT_LOAD_W",
                                        src_addr=0x80000000 | src,
                                        rows=lw_rows, cols=16)
                if ci == 0:
                    ring += cq_codec.encode("MAT_ACC_CLR", acc_mask=1,
                                            bias_tcm_byte=TCM_BLOB_B)
                ring += cq_codec.encode("MAT_CFG", m=8, n=8, k=8 * ch)
                ring += cq_codec.encode("MAT_OP", a_addr=TCM_BLOB_B + A_OFF,
                                        b_addr=TCM_BLOB_B + A_OFF + 8 * ch,
                                        rpt=ch, acc=0)
                k_off += ch
            last = (g == n_groups - 1) and (tile == n_tiles - 1)
            ring += cq_codec.encode("MAT_RESCALE",
                                    param_ptr=TCM_BLOB_B + PARAM_OFF,
                                    out_zp=layer["output_zp"],
                                    clamp_min=amin, clamp_max=amax, acc=0)
            ring += cq_codec.encode("MAT_STORE",
                                    dst_addr=0x80000000 | (SHARED_DST_B + job * 0x40),
                                    stride=MAT_OUT_B, rows=4, cols=4,
                                    irq=1 if last else 0, last=1 if last else 0)
            job += 1
    return segments, ring, n_groups, n_tiles


def _param_block_tile(layer, tile):
    blk = bytearray()
    shifts = bytearray()
    for c in range(8):
        ws = layer["weight_scales"][tile * 8 + c]
        m, s = quantize_multiplier(
            layer["input_scale"] * ws / layer["output_scale"])
        eng = 31 - s
        assert 31 <= eng <= 62
        blk += (m & 0xFFFFFFFF).to_bytes(4, "little")
        shifts.append(eng)
    return bytes(blk) + bytes(shifts)


def emit_layer_v2(outdir: Path, layer, rows, ring_entries=32):
    segments, ring, n_groups, n_tiles = lower_layer_v2(layer, rows)
    assert len(ring) // 4 < ring_entries, "ring capacity"
    outdir.mkdir(parents=True, exist_ok=True)
    lines = ["@00000100"] + ["%08x" % x for x in ring]
    for src, blob in segments:
        lines.append("@%08x" % (src >> 2))
        for i in range(0, len(blob), 4):
            lines.append("%08x" % int.from_bytes(blob[i:i + 4], "little"))
    (outdir / "tflm_shared.hex").write_text("\n".join(lines) + "\n")
    (outdir / "tflm_meta.hex").write_text(
        "%08x\n%08x\n%08x\n" % (len(ring) // 4, n_groups * n_tiles * 16,
                                   ring_entries))
    return n_groups, n_tiles


def unpack_result_v2(dump_path: Path, n_groups: int, n_tiles: int, n_rows: int, n_out: int):
    words = [int(x, 16) for x in dump_path.read_text().split()]
    assert len(words) == n_groups * n_tiles * 16
    out = [[0] * n_out for _ in range(n_rows)]
    job = 0
    for g in range(n_groups):
        for tile in range(n_tiles):
            raw = b"".join(w.to_bytes(4, "little")
                           for w in words[job * 16:(job + 1) * 16])
            for r in range(8):
                p = g * 8 + r
                if p < n_rows:
                    for c in range(8):
                        if tile * 8 + c < n_out:
                            v = raw[r * 8 + c]
                            out[p][tile * 8 + c] = v - 256 if v > 127 else v
            job += 1
    return out


def load_artifacts2():
    model = json.loads((ART / "model2.json").read_text())
    golden = json.loads((ART / "golden2.json").read_text())
    return model, golden


def load_artifacts_s2():
    """ADR-0065 stride-2 SAME conv model + TFLM golden."""
    model = json.loads((ART / "model_s2.json").read_text())
    golden = json.loads((ART / "golden_s2.json").read_text())
    return model, golden
