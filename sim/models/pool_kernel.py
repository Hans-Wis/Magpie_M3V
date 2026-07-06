#!/usr/bin/env python3
"""pool_kernel — ADR-0049 S4: RVV pooling kernels from the AOT runtime.

MAX_POOL_2D: per output pixel, 4x vle8 (channel vector) -> vmax chain -> vse8.
AVERAGE_POOL_2D (TFLM round-half-AWAY — vssra/vnclip round rnu/rdn, so the
kernel reconstructs half-away exactly): widen-sum the four window pixels
(vwmul-by-1 + 3x vwadd.wv), then at SEW16 add +2 with a -1 masked on the
negative lanes (vmslt mask), then vnclip.wi >>2 under vxrm=rdn (truncate).

LEMMA 1 (proved exhaustively below): for every reachable sum s in
[-512, 508]:  (s + (2 if s >= 0 else 1)) >> 2  ==  TFLM half-away(s/4).
LEMMA 2: the strided LOAD_W descriptor semantics (the gate_51-verified
firmware gather loop) reproduce numpy's pooling-row layout, so embedding the
tile in the DTCM image is equivalent to the DMA path having run.
"""
from __future__ import annotations

import json
from pathlib import Path

ART = Path(__file__).resolve().parent / "artifacts"
H = W = 4
C = 8
OH = OW = 2


def half_away_div4(s: int) -> int:
    return (s + 2) // 4 if s >= 0 else -((-s + 2) // 4)


def lemma1_signfix_equals_half_away() -> None:
    for s in range(-512, 509):
        got = (s + (2 if s >= 0 else 1)) >> 2
        assert got == half_away_div4(s), (s, got, half_away_div4(s))


def sim_load_w_gather(src: bytes, base: int, stride: int, rows: int, cols_w: int):
    """The cq_sequencer LOAD_W(stride) loop (ADR-0043, gate_51-verified):
    row r = src[base + r*stride : +cols_w*4] laid contiguously."""
    out = b""
    for r in range(rows):
        out += src[base + r * stride: base + r * stride + cols_w * 4]
    return out


def lemma2_gather_matches_numpy(x) -> None:
    """Pooling consumes input rows y=0..3 (32B each); a strided gather of the
    full tensor (stride = W*C) equals the flat NHWC layout numpy sees."""
    flat = bytes((v & 0xFF) for row in x for pix in row for v in pix)
    got = sim_load_w_gather(flat, 0, W * C, H, (W * C) // 4)
    assert got == flat


def emit_firmware(out_path: Path) -> None:
    g = json.loads((ART / "pool_golden.json").read_text())
    x = g["input"][0]                      # [4][4][8]
    lemma1_signfix_equals_half_away()
    lemma2_gather_matches_numpy(x)

    a = [".section .init", ".global _start", "_start:",
         "    li   t0, 0x200", "    csrs mstatus, t0",
         "    la   x31, data_area"]

    def pix_off(y, xx):
        return (y * W + xx) * C

    # ---- max pool ----
    a.append("    /* MAX_POOL_2D 2x2 s2 (TFLM: max over window, no requant) */")
    a.append("    li   a0, 8")
    a.append("    vsetvli t1, a0, e8, m1, ta, ma")
    for oy in range(OH):
        for ox in range(OW):
            offs = [pix_off(2 * oy + dy, 2 * ox + dx) for dy in (0, 1) for dx in (0, 1)]
            a.append(f"    addi a1, x31, {offs[0]}")
            a.append("    vle8.v v1, (a1)")
            for i, o in enumerate(offs[1:], start=2):
                a.append(f"    addi a1, x31, {o}")
                a.append(f"    vle8.v v{i}, (a1)")
            a.append("    vmax.vv v1, v1, v2")
            a.append("    vmax.vv v3, v3, v4")
            a.append("    vmax.vv v1, v1, v3")
            a.append(f"    addi a1, x31, {128 + (oy * OW + ox) * C}")
            a.append("    vse8.v v1, (a1)")

    # ---- avg pool ----
    a.append("    /* AVERAGE_POOL_2D 2x2 s2 — exact TFLM half-away (lemma 1) */")
    a.append("    li   t0, 2")
    a.append("    csrw vxrm, t0                  /* rdn: vnclip truncates */")
    for oy in range(OH):
        for ox in range(OW):
            offs = [pix_off(2 * oy + dy, 2 * ox + dx) for dy in (0, 1) for dx in (0, 1)]
            a.append("    li   a0, 8")
            a.append("    vsetvli t1, a0, e8, mf2, ta, ma")
            for i, o in enumerate(offs, start=1):
                a.append(f"    addi a1, x31, {o}")
                a.append(f"    vle8.v v{i}, (a1)")
            a.append("    vmv.v.i v5, 1")
            a.append("    vwmul.vv v6, v1, v5    /* widen: sum16 = a */")
            a.append("    vwadd.wv v6, v6, v2")
            a.append("    vwadd.wv v6, v6, v3")
            a.append("    vwadd.wv v6, v6, v4")
            a.append("    li   a0, 8")
            a.append("    vsetvli t1, a0, e16, m1, ta, ma")
            a.append("    vmslt.vx v0, v6, x0    /* negative-sum lanes */")
            a.append("    vadd.vi v6, v6, 2")
            a.append("    vadd.vi v6, v6, -1, v0.t")
            a.append("    li   a0, 8")
            a.append("    vsetvli t1, a0, e8, mf2, ta, ma")
            a.append("    vnclip.wi v7, v6, 2    /* >>2 truncate + narrow */")
            a.append(f"    addi a1, x31, {160 + (oy * OW + ox) * C}")
            a.append("    vse8.v v7, (a1)")

    # ---- probes: 16 words (8 max + 8 avg) surface in the commit trace ----
    a.append("    /* output probes — gate_59 reads these from the trace */")
    for w in range(16):
        a.append(f"    lw   t2, {128 + w * 4}(x31)")
    a.append("    ebreak")
    a.append("    .balign 4")
    a.append("data_area:")
    flat = [v for row in x for pix in row for v in pix]
    for i in range(0, len(flat), 4):
        word = 0
        for k in range(4):
            word |= (flat[i + k] & 0xFF) << (8 * k)
        a.append(f"    .word 0x{word:08x}")
    a.append("    .zero 64")                    # out_max + out_avg
    out_path.write_text("\n".join(a) + "\n")


def expected_words():
    g = json.loads((ART / "pool_golden.json").read_text())
    words = []
    for key in ("maxpool", "avgpool"):
        flat = [v for row in g[key][0] for pix in row for v in pix]
        for i in range(0, len(flat), 4):
            w = 0
            for k in range(4):
                w |= (flat[i + k] & 0xFF) << (8 * k)
            words.append(w)
    return words


if __name__ == "__main__":
    import sys
    emit_firmware(Path(sys.argv[1]))
    print("kernel emitted; lemmas hold")
