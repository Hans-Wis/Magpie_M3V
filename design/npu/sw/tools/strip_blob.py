"""ADR-0073 strip GEMM blob helpers.

Weight layout is strip-major, then K-chunk-major, then 8-column sub-tile:
offset(c,t)=c*4096+t*512 within each strip, with bytes packed [k][8].

Parameter blocks match sim/tools/ml_strip_case.py:param_block exactly: 8 little-endian
int32 multipliers, 8 uint8 engine shifts, then zero padding to a 64B stride.
"""
from __future__ import annotations

import numpy as np


STRIP_COLS = 64
SUBTILE_COLS = 8
SUBTILES_PER_STRIP = STRIP_COLS // SUBTILE_COLS
K_CHUNK = 64
CHUNK_BYTES = 4096
SUBTILE_BYTES = 512
PARAM_BLOCK_STRIDE = 64


def _as_int8_matrix(w_nk: np.ndarray) -> np.ndarray:
    arr = np.asarray(w_nk, dtype=np.int8)
    if arr.ndim != 2:
        raise ValueError("w_nk must be a 2-D int8 array with shape [N,K]")
    return arr


def make_strip_blob(w_nk: np.ndarray) -> bytes:
    """Pack int8 weights shaped [N,K] into the frozen strip layout.

    N is zero-padded to strips of 64 output channels. K is zero-padded to
    chunks of 64 input channels. The returned bytes contain every strip tightly
    concatenated, so one strip has ``ceil(K/64) * 4096`` bytes.
    """
    w = _as_int8_matrix(w_nk)
    n, k = w.shape
    n_strips = (n + STRIP_COLS - 1) // STRIP_COLS
    k_chunks = (k + K_CHUNK - 1) // K_CHUNK
    blob = bytearray(n_strips * k_chunks * CHUNK_BYTES)

    for s in range(n_strips):
        strip_base = s * k_chunks * CHUNK_BYTES
        for c in range(k_chunks):
            chunk_base = strip_base + c * CHUNK_BYTES
            for t in range(SUBTILES_PER_STRIP):
                tile_base = chunk_base + t * SUBTILE_BYTES
                for kk in range(K_CHUNK):
                    src_k = c * K_CHUNK + kk
                    for lane in range(SUBTILE_COLS):
                        src_n = s * STRIP_COLS + t * SUBTILE_COLS + lane
                        if src_n < n and src_k < k:
                            blob[tile_base + kk * SUBTILE_COLS + lane] = int(w[src_n, src_k]) & 0xFF
    return bytes(blob)


def make_param_blocks(mults, shifts, n: int) -> bytes:
    """Pack per-channel RESCALE_PC params into 64B-stride 8-channel blocks."""
    mult_arr = np.asarray(mults, dtype=np.int64).reshape(-1)
    shift_arr = np.asarray(shifts, dtype=np.uint8).reshape(-1)
    if n < 0:
        raise ValueError("n must be non-negative")
    if mult_arr.size < n or shift_arr.size < n:
        raise ValueError("mults and shifts must contain at least n entries")

    blocks = bytearray()
    for base in range(0, n, SUBTILE_COLS):
        blk = bytearray()
        sh = bytearray()
        for i in range(SUBTILE_COLS):
            idx = base + i
            m = int(mult_arr[idx]) if idx < n else 0
            s = int(shift_arr[idx]) if idx < n else 0
            blk += (m & 0xFFFFFFFF).to_bytes(4, "little")
            sh.append(s & 0xFF)
        block = bytes(blk) + bytes(sh)
        blocks += block + bytes(PARAM_BLOCK_STRIDE - len(block))
    return bytes(blocks)
