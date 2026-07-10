#!/usr/bin/env python3
"""Generate the ADR-0073 strip-streaming smoke case.

The D2 strip FSM streams only the B operand from DDR into npu_strip_buf. The
fold vectors, per-channel requant params, and activation rows are still consumed
from the frozen Phase-A TCM addresses in npu_ml_ctrl, so this emits both the DDR
image and a TCM preload sidecar for the Verilator TB.

ADR-0073 D4 strip-local layout addendum (frozen): chunk-major then 8-col
sub-tile. offset(c,t)=c*4096+t*512, where each 512B block is 64 k-rows x
8 cols, k-major [k][8], identical to the Phase-A engine B tile. Sub-tile t
covers strip columns t*8..t*8+7. Strip-mode per-channel params live at
STRIP_PARAM_PTR=0x1200 as consecutive 64B blocks (40B + 24B pad, 32B-aligned) indexed by global sub-tile
(strip*8+t); strip fold blocks live at 0x1600+i*32 and are zero in this case.
STORE writes one Phase-A 8x8 output block per sub-tile at
DST+(strip*8+t)*64 bytes, so the full 8x128 result is 1024 contiguous bytes in
row-tile-major Phase-A block layout.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "sim/models"))

import tflm_runtime as rt  # noqa: E402

ROWS = 8
K = 128
K_CHUNKS = 2
K_TAIL = 64
N_STRIPS = 2
N_TAIL = 64
STRIP_N = N_STRIPS * N_TAIL
STRIP_COLS = 64
SUBTILE_COLS = 8
SUBTILES_PER_STRIP = STRIP_COLS // SUBTILE_COLS
W_BASE_DEFAULT = 0x4000
STRIP_BYTES = K * STRIP_COLS

FOLD_PTR = 0x1600
PARAM_PTR = 0x720
STRIP_PARAM_PTR = 0x1200
OP_A_ADDR = 0x940
STRIP_A_STEP = 0x200
SHARED_ACT_B = 0x1C00


def s8(v: int) -> int:
    v &= 0xFF
    return v - 256 if v & 0x80 else v


def make_rows() -> np.ndarray:
    return np.array([[s8(r * 29 + k * 7 - 83) for k in range(K)]
                     for r in range(ROWS)], dtype=np.int8)


def make_weights(n: int) -> np.ndarray:
    return np.array([[s8(c * 19 + k * 11 - 71) for k in range(K)]
                     for c in range(n)], dtype=np.int8)


def make_weight_scales(n: int) -> np.ndarray:
    return np.array([0.011 + 0.00037 * ((c * 5) % 17) for c in range(n)],
                    dtype=np.float64)


def write_hex(path: Path, segments: list[tuple[int, bytes]]) -> None:
    lines: list[str] = []
    for src, blob in segments:
        lines.append(f"@{src >> 2:08x}")
        for i in range(0, len(blob), 4):
            lines.append(f"{int.from_bytes(blob[i:i + 4], 'little'):08x}")
    path.write_text("\n".join(lines) + "\n")


def param_block(scales: np.ndarray, cols: list[int]) -> bytes:
    blk = bytearray()
    shifts = bytearray()
    for c in cols:
        m, s = rt.quantize_multiplier(0.023 * float(scales[c]) / 0.097)
        eng_shift = 31 - s
        assert 31 <= eng_shift <= 62
        blk += (m & 0xFFFFFFFF).to_bytes(4, "little")
        shifts.append(eng_shift)
    return bytes(blk) + bytes(shifts)


def activation_blob(rows: np.ndarray) -> bytes:
    act = bytearray(K * ROWS)
    for kk in range(K):
        for r in range(ROWS):
            act[kk * ROWS + r] = int(rows[r, kk]) & 0xFF
    return bytes(act)


def make_strip_blob(weights_full: np.ndarray, strip: int) -> bytes:
    blob = bytearray(STRIP_BYTES)
    col0 = strip * STRIP_COLS
    for chunk in range(K_CHUNKS):
        k0 = chunk * 64
        chunk_base = chunk * 4096
        for tile in range(SUBTILES_PER_STRIP):
            tile_base = chunk_base + tile * 512
            tile_col0 = col0 + tile * SUBTILE_COLS
            for kk in range(64):
                for c in range(SUBTILE_COLS):
                    blob[tile_base + kk * SUBTILE_COLS + c] = \
                        int(weights_full[tile_col0 + c, k0 + kk]) & 0xFF
    return bytes(blob)


def make_tcm_blob(rows: np.ndarray, scales: np.ndarray) -> list[tuple[int, bytes]]:
    fold = bytes(32)
    params = bytearray()
    for strip in range(N_STRIPS):
        for tile in range(SUBTILES_PER_STRIP):
            col0 = strip * STRIP_COLS + tile * SUBTILE_COLS
            blk = param_block(scales, list(range(col0, col0 + SUBTILE_COLS)))
            params += blk + bytes(64 - len(blk))   # pad to 64B: engine 32B alignment
    act = activation_blob(rows)
    return [
        (FOLD_PTR, fold),
        (STRIP_PARAM_PTR, bytes(params)),
        (OP_A_ADDR, bytes(act[:64 * ROWS])),
        (OP_A_ADDR + STRIP_A_STEP, bytes(act[64 * ROWS:])),
    ]


def generate(outdir: Path, w_base: int = W_BASE_DEFAULT) -> dict[str, int]:
    assert (w_base & 0xFFF) == 0, "W_BASE must be 4KB aligned"
    outdir.mkdir(parents=True, exist_ok=True)

    rows = make_rows()
    weights_full = make_weights(N_STRIPS * STRIP_COLS)
    scales = make_weight_scales(N_STRIPS * STRIP_COLS)
    params = b"".join(
        param_block(scales, list(range(s * STRIP_COLS + t * SUBTILE_COLS,
                                     s * STRIP_COLS + (t + 1) * SUBTILE_COLS)))
        for s in range(N_STRIPS)
        for t in range(SUBTILES_PER_STRIP)
    )

    shared = [(SHARED_ACT_B, activation_blob(rows))]
    for s in range(N_STRIPS):
        shared.append((w_base + s * STRIP_BYTES, make_strip_blob(weights_full, s)))
    write_hex(outdir / "ml_strip_shared.hex", shared)
    write_hex(outdir / "ml_strip_tcm.hex", make_tcm_blob(rows, scales))

    np.save(outdir / "ml_strip_act_rows_int8.npy", rows)
    np.save(outdir / "ml_strip_weights_full_int8.npy", weights_full)
    np.save(outdir / "ml_strip_weights_int8.npy", weights_full)
    np.save(outdir / "ml_strip_requant_blob.npy", np.frombuffer(params, dtype=np.uint8))
    (outdir / "ml_strip_act_rows.hex").write_text(
        "\n".join("".join(f"{int(v) & 0xFF:02x}" for v in row) for row in rows) + "\n")
    (outdir / "ml_strip_weights_int8.hex").write_text(
        "\n".join("".join(f"{int(v) & 0xFF:02x}" for v in row) for row in weights_full) + "\n")
    (outdir / "ml_strip_requant_blob.hex").write_text(params.hex() + "\n")

    result_words = ROWS * STRIP_N // 4
    meta = {
        "w_base": w_base,
        "strip_bytes": STRIP_BYTES,
        "n_strips": N_STRIPS,
        "k_chunks": K_CHUNKS,
        "k_tail": K_TAIL,
        "n_tail": N_TAIL,
        "result_words": result_words,
        "subtiles_per_strip": SUBTILES_PER_STRIP,
    }
    (outdir / "ml_strip_meta.hex").write_text(
        "".join(f"{v:08x}\n" for v in meta.values()))
    return meta


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--outdir", type=Path, default=ROOT / "sim/work/ml_strip_gemm")
    ap.add_argument("--w-base", type=lambda x: int(x, 0), default=W_BASE_DEFAULT)
    args = ap.parse_args()
    meta = generate(args.outdir, args.w_base)
    print(
        "ML_STRIP_CASE "
        f"out={args.outdir} W_BASE=0x{meta['w_base']:08x} "
        f"STRIP_BYTES={meta['strip_bytes']} N_STRIPS={meta['n_strips']} "
        f"K_CHUNKS={meta['k_chunks']} K_TAIL={meta['k_tail']} "
        f"N_TAIL={meta['n_tail']} RESULT_WORDS={meta['result_words']} "
        f"LAYOUT=offset(c,t)=c*4096+t*512 PARAM_PTR=0x{STRIP_PARAM_PTR:04x} "
        f"STORE=DST+(s*8+t)*64"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
