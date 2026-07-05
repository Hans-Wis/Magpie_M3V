#!/usr/bin/env python3
"""tflm_fc — ADR-0039 / Phase 6: TFLM int8 FullyConnected on the M3V NPU.

Two independent halves, bit-equality between them is the gate_48 contract:

GOLDEN  `fc_reference()` is a faithful reimplementation of TFLM
        reference_integer_ops::FullyConnected (per-tensor int8): for each
        (batch r, output c), acc starts at 0 and accumulates
        (input[r][k] + input_offset) * filter[c][k] for k = 0..K-1 IN ORDER
        with int32 wrap, then acc += bias[c], then the frozen gemmlowp
        two-step requant (mat_golden.rescale == engine RESCALE == TFLM
        MultiplyByQuantizedMultiplier), + output_zp, clamp to the fused
        activation range. input_offset = -input_zero_point (TFLM sign).

COMPILER `compile_fc()` lowers the same op to the NPU: batch-8 GEMV on the
        8x8 outer-product engine (rep k: a_k[r] = input[r][k],
        b_k[c] = filter[c][k]) with the affine fold
        fold32[c] = wrap32(bias[c] + input_offset * sum_k filter[c][k])
        PRELOADED into every accumulator row (MAT.ACC_CLR W2 = fold ptr ->
        engine CMD_LOADACC). Exact mod 2^32: wrapping add is associative/
        commutative and multiplication distributes (two's-complement ring),
        so the fold grouping cannot diverge from TFLM's per-k order.
        Descriptors are emitted ONLY through the SSOT codec (cq_codec).

Scope (explicit gate assumptions): per-tensor quant, filter_offset == 0
(TFLite int8 filters mandate zero_point 0 — compile_fc raises otherwise),
batch = 8, K in {8..64} multiple of 8, outputs <= 8, single tile.
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "IP/npu/sw"))
sys.path.insert(0, str(Path(__file__).resolve().parent))

import cq_codec  # noqa: E402  (SSOT — generated)
from mat_golden import rescale  # noqa: E402  (frozen engine requant)

# TCM layout (bytes) — one contiguous MAT.LOAD_W blob lands at 0x600
TCM_BLOB_B = 0x700          # fixed LOAD_W destination (firmware TCM_WEIGHT_B, ADR-0043)
FOLD_OFF = 0x000            # 8x int32 fold words
A_OFF = 0x240               # a-vectors (skips the 0x800 MAT_OUT hole)
MAT_OUT_B = 0x800           # engine RESCALE output region (reset default)
SHARED_BLOB_B = 0x2000      # blob source in shared memory
SHARED_DST_B = 0x1800       # STORE writeback destination in shared memory
RING_B = 0x400              # ring base in shared memory


def wrap32(x: int) -> int:
    x &= 0xFFFFFFFF
    return x - 0x100000000 if x & 0x80000000 else x


def fc_reference(inputs, filters, bias, input_zp, mult_q31, shift, out_zp,
                 act_min, act_max):
    """TFLM reference kernel semantics, per-k int32 wrap. -> out[r][c] int8."""
    batch, k_dim = len(inputs), len(inputs[0])
    input_offset = -input_zp
    out = []
    for r in range(batch):
        row = []
        for c in range(len(filters)):
            acc = 0
            for k in range(k_dim):
                acc = wrap32(acc + (inputs[r][k] + input_offset) * filters[c][k])
            acc = wrap32(acc + bias[c])
            row.append(rescale(acc, mult_q31, shift, out_zp, act_min, act_max))
        out.append(row)
    return out


def compile_fc(inputs, filters, bias, input_zp, mult_q31, shift, out_zp,
               act_min, act_max, filter_zp=0):
    """Lower one FC op to (tcm_blob bytes, ring descriptor words)."""
    if filter_zp != 0:
        raise ValueError("TFLite int8 filters require zero_point == 0 "
                         "(per-tensor scope, ADR-0039)")
    batch, k_dim = len(inputs), len(inputs[0])
    n_out = len(filters)
    if batch != 8 or n_out != 8 or k_dim % 8 or not 8 <= k_dim <= 64:
        raise ValueError("scope: batch=8, outputs=8, K in {8..64} mult of 8 "
                         "(fewer outputs: pad filters/bias to 8 upstream)")
    if not -128 <= input_zp <= 127:
        raise ValueError("input_zp out of int8 range")

    input_offset = -input_zp
    blob = bytearray(A_OFF + 2 * 8 * k_dim)
    for c in range(8):
        f = wrap32(bias[c] + input_offset * sum(filters[c])) if c < n_out else 0
        blob[FOLD_OFF + 4 * c:FOLD_OFF + 4 * c + 4] = (f & 0xFFFFFFFF).to_bytes(4, "little")
    for k in range(k_dim):                       # a_k[r] = input[r][k]
        for r in range(8):
            blob[A_OFF + 8 * k + r] = inputs[r][k] & 0xFF
    b_off = A_OFF + 8 * k_dim                    # b_k[c] = filter[c][k]
    for k in range(k_dim):
        for c in range(n_out):
            blob[b_off + 8 * k + c] = filters[c][k] & 0xFF

    words = (len(blob) + 3) // 4
    cols = 16
    rows = (words + cols - 1) // cols
    blob.extend(b"\0" * (rows * cols * 4 - len(blob)))

    ring = []
    # engine contract (ADR-0037): one rep = ONE outer product consuming 8 a-bytes
    # + 8 b-bytes; CFG.K counts a-BYTES (= 8 * FC depth), RPT = FC depth k_dim.
    ring += cq_codec.encode("MAT_CFG", m=8, n=8, k=8 * k_dim)
    ring += cq_codec.encode("MAT_LOAD_W", src_addr=0x80000000 | SHARED_BLOB_B,
                            rows=rows, cols=cols)
    ring += cq_codec.encode("MAT_ACC_CLR", acc_mask=1,
                            bias_tcm_byte=TCM_BLOB_B + FOLD_OFF)
    ring += cq_codec.encode("MAT_OP", a_addr=TCM_BLOB_B + A_OFF,
                            b_addr=TCM_BLOB_B + b_off, rpt=k_dim, acc=0)
    ring += cq_codec.encode("MAT_RESCALE", multiplier_q31=mult_q31,
                            out_zp=out_zp, shift=shift,
                            clamp_min=act_min, clamp_max=act_max, acc=0)
    ring += cq_codec.encode("MAT_STORE", dst_addr=0x80000000 | SHARED_DST_B,
                            stride=MAT_OUT_B, rows=4, cols=4, irq=1, last=1)
    return bytes(blob), ring


def expected_words(out):
    """Engine tile order: byte el = r*8+c, packed LE into 16 words."""
    raw = bytearray(64)
    for r in range(8):
        for c in range(8):
            raw[r * 8 + c] = (out[r][c] if c < len(out[r]) else 0) & 0xFF
    return [int.from_bytes(raw[4 * i:4 * i + 4], "little") for i in range(16)]


def emit_case(outdir: Path, case: dict) -> None:
    """Write tflm_shared.hex (ring @0x100 + blob @0x800, word-addressed) and
    tflm_expected.hex (16 words) for tb_npu_tflm_fc."""
    blob, ring = compile_fc(**case)
    out = fc_reference(case["inputs"], case["filters"], case["bias"],
                       case["input_zp"], case["mult_q31"], case["shift"],
                       case["out_zp"], case["act_min"], case["act_max"])
    # cross-check: fold-lowered params reproduce the reference bit-exactly
    # is enforced by the RTL run; here assert the codec round-trips.
    for i in range(0, len(ring), 4):
        cq_codec.decode(ring[i:i + 4])
    outdir.mkdir(parents=True, exist_ok=True)
    lines = ["@00000100"] + ["%08x" % w for w in ring]
    lines.append("@00000800")
    for i in range(0, len(blob), 4):
        lines.append("%08x" % int.from_bytes(blob[i:i + 4], "little"))
    (outdir / "tflm_shared.hex").write_text("\n".join(lines) + "\n")
    (outdir / "tflm_expected.hex").write_text(
        "\n".join("%08x" % w for w in expected_words(out)) + "\n")


def _lcg(seed):
    while True:
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        yield seed


def _mat(gen, rows, cols, lo=-128, hi=127):
    return [[lo + next(gen) % (hi - lo + 1) for _ in range(cols)] for _ in range(rows)]


def corner_cases():
    """Grok-critique DV matrix: zp extremes, deliberate int32 wrap, doubling-high
    multiplier boundary, fused-ReLU clamp, bias-only (pure LOADACC), K sweep."""
    g = _lcg(0xC0FFEE)
    cases = {}
    cases["base_k32"] = dict(
        inputs=_mat(g, 8, 32), filters=_mat(g, 8, 32),
        bias=[wrap32(next(g) - 0x3FFFFFFF) for _ in range(8)],
        input_zp=13, mult_q31=0x54C4699A, shift=38, out_zp=-10,
        act_min=-128, act_max=127)
    cases["zp_extreme_k8"] = dict(
        inputs=_mat(g, 8, 8), filters=_mat(g, 8, 8),
        bias=[next(g) % 2000 - 1000 for _ in range(8)],
        input_zp=-128, mult_q31=0x40000000, shift=31, out_zp=127,
        act_min=-128, act_max=127)
    cases["relu_k32"] = dict(
        inputs=_mat(g, 8, 32), filters=_mat(g, 8, 32),
        bias=[next(g) % 40000 - 20000 for _ in range(8)],
        input_zp=100, mult_q31=0x54C4699A, shift=36, out_zp=0,
        act_min=0, act_max=127)
    cases["wrap_bias_k16"] = dict(
        inputs=_mat(g, 8, 16), filters=_mat(g, 8, 16),
        bias=[0x7FFFFF00 + (next(g) % 0x200) for _ in range(8)],  # wraps
        input_zp=-77, mult_q31=0x22222222, shift=40, out_zp=5,
        act_min=-128, act_max=127)
    cases["full_k64_maxmult"] = dict(
        inputs=_mat(g, 8, 64), filters=_mat(g, 8, 64),
        bias=[next(g) % 100000 - 50000 for _ in range(8)],
        input_zp=1, mult_q31=0x7FFFFFFF, shift=31, out_zp=-1,
        act_min=-128, act_max=127)
    cases["bias_only_zero_w"] = dict(
        inputs=_mat(g, 8, 8), filters=[[0] * 8 for _ in range(8)],
        bias=[-(1 << 30), -1, 0, 1, 12345, -12345, (1 << 30), 77],
        input_zp=55, mult_q31=0x40000000, shift=33, out_zp=3,
        act_min=-100, act_max=100)
    return cases


if __name__ == "__main__":
    emit_case(Path(sys.argv[1]), corner_cases()[sys.argv[2]])
