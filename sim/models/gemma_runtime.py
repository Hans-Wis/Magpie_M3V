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

import cq_codec                    # noqa: E402  (SSOT)
import tflm_runtime as rt          # noqa: E402  (GEMM lowering + hex writer + unpack)
import gemma_ref as gref           # noqa: E402
import gemma_quant as gq           # noqa: E402

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
