#!/usr/bin/env python3
"""Generate the gate_67 mat_engine-v2 Phase A GEMM blob and golden bytes."""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "sim/models"))
sys.path.insert(0, str(ROOT / "design/npu/golden"))

import gemma_runtime as gr  # noqa: E402
import mat_golden  # noqa: E402
import tflm_runtime as rt  # noqa: E402

K = 64
ROWS = 8
SHARED_ACT_B = 0x1C00   # B1: resident-activation shared src (matches npu_ml_ctrl ACT_SRC)


def s8(v: int) -> int:
    v &= 0xFF
    return v - 256 if v & 0x80 else v


def make_rows() -> list[list[int]]:
    return [[s8(r * 29 + k * 7 - 83) for k in range(K)] for r in range(ROWS)]


def make_weights(n: int) -> np.ndarray:
    return np.array([[s8(c * 19 + k * 11 - 71) for k in range(K)] for c in range(n)],
                    dtype=np.int64)


def make_layer(n: int):
    w_q = make_weights(n)
    sw = np.array([0.011 + 0.00037 * ((c * 5) % 17) for c in range(n)], dtype=np.float64)
    return gr.gemm_layer(w_q, sw, s_in=0.023, s_out=0.097, k=K, n=n)


def tile_golden_from_blob(blob: bytes) -> bytes:
    fold = [int.from_bytes(blob[i * 4:i * 4 + 4], "little", signed=True)
            for i in range(8)]
    mults = [int.from_bytes(blob[rt.PARAM_OFF + i * 4:rt.PARAM_OFF + i * 4 + 4],
                            "little", signed=True)
             for i in range(8)]
    shifts = [blob[rt.PARAM_OFF + 32 + i] for i in range(8)]
    a = [s8(blob[rt.A_OFF + i]) for i in range(K * 8)]
    b_off = rt.A_OFF + K * 8
    b = [s8(blob[b_off + i]) for i in range(K * 8)]

    acc = [[fold[c] for c in range(8)] for _ in range(8)]
    for kk in range(K):
        avec = a[kk * 8:kk * 8 + 8]
        bvec = b[kk * 8:kk * 8 + 8]
        mat_golden.outer_accumulate(acc, avec, bvec)

    out = bytearray()
    for r in range(8):
        for c in range(8):
            out.append(mat_golden.rescale(acc[r][c], mults[c], shifts[c],
                                          0, -128, 127) & 0xFF)
    return bytes(out)


def write_hex(path: Path, segments: list[tuple[int, bytes]]) -> None:
    lines: list[str] = []
    for src, blob in segments:
        lines.append(f"@{src >> 2:08x}")
        for i in range(0, len(blob), 4):
            lines.append(f"{int.from_bytes(blob[i:i + 4], 'little'):08x}")
    path.write_text("\n".join(lines) + "\n")


def write_words(path: Path, data: bytes) -> None:
    lines = []
    for i in range(0, len(data), 4):
        lines.append(f"{int.from_bytes(data[i:i + 4], 'little'):08x}")
    path.write_text("\n".join(lines) + "\n")


TIGHT_HDR = 0x60   # B1.1: [fold(0x20)|param(0x20..0x48)|pad] before weights (matches OP_B_T=0x760)


def _b1_stationary(segments, tight: bool = False):
    """B1 activation-stationary repack: pull the activation (identical for every tile
    in a q_proj group) out to a single resident blob at SHARED_ACT; per-tile blob
    becomes [header | weights]. B1.1 (tight) drops the A_OFF header padding: per-tile
    blob = [fold|param|pad->0x60 | weights] (152w). Golden is unchanged (same GEMM,
    same bytes — only the DMA layout differs)."""
    kw = K * 8                      # 512 activation/weight bytes per tile
    act = segments[0][1][rt.A_OFF:rt.A_OFF + kw]
    out = [(SHARED_ACT_B, act)]     # resident activation, loaded once
    hdr = TIGHT_HDR if tight else rt.A_OFF
    words = 152 if tight else 272
    for job, (_src, blob) in enumerate(segments):
        assert blob[rt.A_OFF:rt.A_OFF + kw] == act, "activation differs per tile (not stationary)"
        b1 = blob[0:hdr] + blob[rt.A_OFF + kw:rt.A_OFF + 2 * kw]   # [fold|param(|pad)|weights]
        assert len(b1) == words * 4
        out.append((rt.SHARED_BLOB_B + job * rt.JOB_STRIDE_B, b1))
    return out


def generate(outdir: Path, n: int, stationary: bool = False,
             tight: bool = False) -> tuple[int, int]:
    assert n in (16, 64), "gate_67 bring-up/final shapes are N=16 or N=64"
    outdir.mkdir(parents=True, exist_ok=True)
    rows = make_rows()
    layer = make_layer(n)
    segments, _ring, n_groups, n_tiles = rt.lower_layer_v2(layer, rows)
    assert n_groups == 1
    assert len(segments) == n_tiles
    assert n_tiles == n // 8

    for job, (src, blob) in enumerate(segments):
        assert src == rt.SHARED_BLOB_B + job * rt.JOB_STRIDE_B
        assert len(blob) == 400 * 4

    # golden is from the ORIGINAL full blobs (activation-stationary changes DMA, not math)
    golden = b"".join(tile_golden_from_blob(blob) for _src, blob in segments)
    shared = _b1_stationary(segments, tight=tight) if stationary else segments
    write_hex(outdir / "ml_v2_shared.hex", shared)
    write_words(outdir / "ml_v2_golden.hex", golden)
    (outdir / "ml_v2_golden.bin").write_bytes(golden)
    (outdir / "ml_v2_meta.hex").write_text(f"{n_tiles:08x}\n{n_tiles * 16:08x}\n")
    (outdir / "ml_v2_rows.txt").write_text(
        "\n".join(" ".join(f"{v:4d}" for v in row) for row in rows) + "\n")
    return n_groups, n_tiles


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--outdir", type=Path, default=ROOT / "sim/work/ml_v2_gemm")
    ap.add_argument("--n", type=int, default=64)
    args = ap.parse_args()
    ng, nt = generate(args.outdir, args.n)
    print(f"ML_V2_GEMM_CASE out={args.outdir} n_groups={ng} n_tiles={nt}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
