#!/usr/bin/env python3
"""gemma_runtime — ADR-0062 S0: deployment-side lowering of the Gemma GeGLU MLP to
the NPU (F1.5 RTL e2e). GEMMs reuse the proven mat_engine FC path (tflm_runtime);
the nonlinear ops (gelu LUT, elementwise mul-requant) run on the NPU sequencer via
the new CQ opcodes MAT_ACT_LUT / MAT_EWISE_MUL (nonlinear-in-RTL, not the host).

S0 = down( gelu(gate(x)) ⊙ up(x) ), orchestrated as 5 host-chained steps (like the CNN
gate_50 flatten): each GEMM and each nonlinear op runs on the NPU; the host only moves +
relayouts the int8 results between steps (never computes gelu/prod). Every step is checked
bit-exact against the Tier-C golden (gemma_quant).
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "sim/models"))
sys.path.insert(0, str(ROOT / "design/npu/sw"))
sys.path.insert(0, str(ROOT / "design/npu/sw/gemma"))
sys.path.insert(0, str(ROOT / "design/npu/golden"))

import struct                      # noqa: E402
import cq_codec                    # noqa: E402  (SSOT)
import tflm_runtime as rt          # noqa: E402  (GEMM lowering + hex writer + unpack)
import gemma_ref as gref           # noqa: E402
import gemma_quant as gq           # noqa: E402
import gemma_quant_s1 as gq1       # noqa: E402  (S1 Tier-C golden + rsqrt SSOT)

# TCM byte layout for the nonlinear steps (all < 0xF00 scratch; firmware bound-checks this).
TCM_IN = 0x700          # MAT_LOAD_W target (activation inputs land here, contiguous)
SHARED_IN = 0x2000      # rt.SHARED_BLOB_B — where we stage the input bytes in shared
SHARED_OUT = 0x1800     # rt.SHARED_DST_B — MAT_STORE target; the TB dumps this window


def s0_tensors(seed: int = 42):
    """Quantized S0 model + Tier-C golden checkpoints (single source = gemma_quant)."""
    cfg = gref.CFG
    W = gref.make_weights(cfg)
    x = np.random.default_rng(seed).normal(0, 1.0, (cfg["seq"], cfg["hidden"])).astype(np.float32)
    g = gq.geglu_int8(x, W, cfg)
    wg_q, swg = gq.q_perchannel(W["gate_proj"].T)   # [inter][hidden]
    wu_q, swu = gq.q_perchannel(W["up_proj"].T)
    wd_q, swd = gq.q_perchannel(W["down_proj"].T)   # [hidden][inter]
    return dict(cfg=cfg, g=g,
                wg=(wg_q, swg), wu=(wu_q, swu), wd=(wd_q, swd))


def gemm_layer(w_q, sw, s_in, s_out, k, n):
    """An FC-layer dict for a symmetric (zp=0, no-bias) GeGLU projection GEMM.
    fold = bias + input_offset*sum(w) = 0 -> plain ACC_CLR; per-channel requant
    qmul(s_in*sw[c]/s_out) is exactly gemma_quant.gemm_pc's requant."""
    return dict(kind="fc", k=int(k), n=int(n), relu=False,
                weights=[[int(v) for v in row] for row in w_q],
                bias=[0] * int(n),
                input_zp=0, input_scale=float(s_in),
                output_scale=float(s_out), output_zp=0,
                weight_scales=[float(s) for s in sw])


def _write_case(case: Path, ring, segments, result_words, ring_entries=32):
    """Write tflm_shared.hex / tflm_meta.hex for a hand-built CQ program (nonlinear step),
    matching rt.emit_layer_v2's format so tb_npu_tflm_model runs it unchanged."""
    assert len(ring) // 4 < ring_entries, "ring capacity"
    case.mkdir(parents=True, exist_ok=True)
    lines = ["@00000100"] + ["%08x" % x for x in ring]
    for src, blob in segments:
        lines.append("@%08x" % (src >> 2))
        for i in range(0, len(blob), 4):
            lines.append("%08x" % int.from_bytes(blob[i:i + 4].ljust(4, b"\0"), "little"))
    (case / "tflm_shared.hex").write_text("\n".join(lines) + "\n")
    (case / "tflm_meta.hex").write_text("%08x\n%08x\n%08x\n" %
                                        (len(ring) // 4, result_words, ring_entries))


def _pack_rows(mat):
    """[seq][n] int8 -> contiguous bytes (row-major)."""
    b = bytearray()
    for row in mat:
        for v in row:
            b.append(int(v) & 0xFF)
    return bytes(b)


def _load_w(blob):
    """MAT_LOAD_W of a byte blob into TCM_IN. blob is padded to a multiple of 32 bytes so
    rows*cols(=8) exactly covers it (no stray words loaded past the data)."""
    padded = blob + b"\0" * ((-len(blob)) % 32)
    words = len(padded) // 4
    rows = words // 8
    return list(cq_codec.encode("MAT_LOAD_W", src_addr=0x80000000 | SHARED_IN,
                                rows=rows, cols=8)), padded


def _store(src_tcm, out_bytes):
    swords = (out_bytes + 3) // 4
    srows = (swords + 7) // 8
    return cq_codec.encode("MAT_STORE", dst_addr=0x80000000 | SHARED_OUT,
                           src_tcm_byte=src_tcm, rows=srows, cols=8, irq=1, last=1), srows * 8


def emit_act_lut(case: Path, gate, lut, seq, inter):
    """gelu = MAT_ACT_LUT[gate] on the NPU. shared_in = [gate | lut]; per-row LUT; store gelu."""
    gate_b = _pack_rows(gate)
    lut_b = bytes(int(v) & 0xFF for v in lut)      # 256-entry int8 table as bytes
    ring, blob = _load_w(gate_b + lut_b)
    gate_tcm, lut_tcm = TCM_IN, TCM_IN + len(gate_b)
    gelu_tcm = lut_tcm + len(lut_b)
    for r in range(seq):
        ring += cq_codec.encode("MAT_ACT_LUT", src=gate_tcm + r * inter,
                                dst=gelu_tcm + r * inter, lut=lut_tcm, rpt=inter)
    store, rwords = _store(gelu_tcm, seq * inter)
    ring += store
    _write_case(case, ring, [(SHARED_IN, blob)], rwords)
    return rwords, seq * inter


def emit_ewise_mul(case: Path, gelu, up, mult_q31, shift, seq, inter):
    """prod = MAT_EWISE_MUL(gelu, up) on the NPU. shared_in = [gelu | up]; per-row mul-requant."""
    gelu_b = _pack_rows(gelu)
    up_b = _pack_rows(up)
    ring, blob = _load_w(gelu_b + up_b)
    gelu_tcm, up_tcm = TCM_IN, TCM_IN + len(gelu_b)
    prod_tcm = up_tcm + len(up_b)
    for r in range(seq):
        ring += cq_codec.encode("MAT_EWISE_MUL", multiplier_q31=mult_q31 & 0xFFFFFFFF,
                                src_a=gelu_tcm + r * inter, src_b=up_tcm + r * inter,
                                dst=prod_tcm + r * inter, shift=shift, rpt=inter)
    store, rwords = _store(prod_tcm, seq * inter)
    ring += store
    _write_case(case, ring, [(SHARED_IN, blob)], rwords)
    return rwords, seq * inter


def _align32(x):
    return (x + 31) & ~31


def _rmsnorm_blob(nrm, coeffs, eps_q, inv_sqrt2):
    hdr = struct.pack("<IIIiiiiI", nrm["SA2_Q"] & 0xFFFFFFFF, nrm["OUT_NUM"] & 0xFFFFFFFF,
                      eps_q, coeffs[0], coeffs[1], coeffs[2], coeffs[3], inv_sqrt2)
    wq = b"".join(struct.pack("<h", int(w)) for w in nrm["w_q16"])   # H int16 Q2.14
    return hdr + wq                                                  # 32 + 2H bytes


def emit_rmsnorm_rows(case: Path, rows_q, nrm, coeffs, eps_q, inv_sqrt2, nrows, H):
    """MAT_RMSNORM over `nrows` rows of length H. rows_q is [nrows][H] int8. Reused by S1
    (H=hidden) and S2 QK-norm (H=head_dim). Coeffs/constants ride a TCM param blob from the
    golden (zero firmware constants, non-circular SSOT). Returns (result_words, nrows*H)."""
    blob = _rmsnorm_blob(nrm, coeffs, eps_q, inv_sqrt2)
    a_b = _pack_rows(rows_q)
    a_pad = a_b + b"\0" * ((-len(a_b)) % 32)
    combined = a_pad + blob
    ring, loaded = _load_w(combined)
    a_base = TCM_IN
    blob_base = a_base + len(a_pad)
    out_base = _align32(blob_base + len(blob))
    for r in range(nrows):
        ring += cq_codec.encode("MAT_RMSNORM", src=a_base + r * H, dst=out_base + r * H,
                                param=blob_base, rpt=H)
    store, rwords = _store(out_base, nrows * H)
    ring += store
    _write_case(case, ring, [(SHARED_IN, loaded)], rwords)
    return rwords, nrows * H


def emit_rmsnorm(case: Path, a_q, g, seq, H):
    """ADR-0062 S1: RMSNorm*(1+w) row-per-descriptor. Thin wrapper over emit_rmsnorm_rows."""
    return emit_rmsnorm_rows(case, a_q, g["nrm"], g["coeffs"], g["eps_q"],
                             gq1.INV_SQRT2_Q16, seq, H)


def emit_rope(case: Path, x_q, cos_q, sin_q, rmeta, seq, n, hd):
    """ADR-0062 S2: neox RoPE on [seq,n,hd] int8 via MAT_ROPE (one head-vector per
    descriptor). cos_q/sin_q are [seq,hd] Q15 int16; the per-position table pointer varies,
    the requant mult/shift are per-tensor. Returns (result_words, seq*n*hd)."""
    x_b = bytearray()
    for p in range(seq):
        for h in range(n):
            for i in range(hd):
                x_b.append(int(x_q[p][h][i]) & 0xFF)
    x_pad = bytes(x_b) + b"\0" * ((-len(x_b)) % 32)
    tbl_b = bytearray()
    for p in range(seq):
        for i in range(hd):
            tbl_b += struct.pack("<h", int(cos_q[p][i]))
        for i in range(hd):
            tbl_b += struct.pack("<h", int(sin_q[p][i]))
    tbl_pad = bytes(tbl_b) + b"\0" * ((-len(tbl_b)) % 32)
    param = struct.pack("<ii", rmeta["mult_q31"] if rmeta["mult_q31"] < (1 << 31)
                        else rmeta["mult_q31"] - (1 << 32), rmeta["shift"])
    combined = x_pad + tbl_pad + param
    ring, loaded = _load_w(combined)
    x_base = TCM_IN
    tbl_base = x_base + len(x_pad)
    param_base = tbl_base + len(tbl_pad)
    out_base = _align32(param_base + len(param))
    for p in range(seq):
        for h in range(n):
            off = (p * n + h) * hd
            ring += cq_codec.encode("MAT_ROPE", src=x_base + off, dst=out_base + off,
                                    table=tbl_base + p * (4 * hd), param=param_base, rpt=hd)
    store, rwords = _store(out_base, seq * n * hd)
    ring += store
    _write_case(case, ring, [(SHARED_IN, loaded)], rwords)
    return rwords, seq * n * hd


def emit_add_requant(case: Path, r_q, an_q, g, seq, H, shift=16):
    """ADR-0062 S1: residual add r + a_normed on the NPU sequencer (MAT_EWISE_ADD_REQUANT).
    One descriptor per row; R_NUM/X_NUM from the golden (independent input scales)."""
    res = g["res"]
    hdr = struct.pack("<iiI", res["R_NUM"], res["X_NUM"], shift)     # 12 bytes
    r_b = _pack_rows(r_q)
    an_b = _pack_rows(an_q)
    r_pad = r_b + b"\0" * ((-len(r_b)) % 32)
    an_pad = an_b + b"\0" * ((-len(an_b)) % 32)
    combined = r_pad + an_pad + hdr
    ring, loaded = _load_w(combined)
    r_base = TCM_IN
    an_base = r_base + len(r_pad)
    blob_base = an_base + len(an_pad)
    out_base = _align32(blob_base + len(hdr))
    for r in range(seq):
        ring += cq_codec.encode("MAT_EWISE_ADD_REQUANT", src_a=r_base + r * H,
                                src_b=an_base + r * H, dst=out_base + r * H,
                                param=blob_base, rpt=H)
    store, rwords = _store(out_base, seq * H)
    ring += store
    _write_case(case, ring, [(SHARED_IN, loaded)], rwords)
    return rwords, seq * H


def unpack_contiguous(dump_path: Path, seq, n):
    """result.dump words -> [seq][n] int8 (contiguous row-major)."""
    words = [int(x, 16) for x in dump_path.read_text().split()]
    raw = b"".join(w.to_bytes(4, "little") for w in words)
    out = []
    for r in range(seq):
        row = [(raw[r * n + c] - 256 if raw[r * n + c] > 127 else raw[r * n + c])
               for c in range(n)]
        out.append(row)
    return out
