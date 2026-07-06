#!/usr/bin/env python3
"""ADR-0037 — bit-accurate golden model for the M3V matrix engine (v4 §06 v0.1).

THE single source of numerical truth (CLAUDE.md §3: matrix parity = NumPy golden):
- outer_product_accumulate: acc[r][c] += sext8(a[r]) * sext8(b[c]), int32 wrap
  (RPT serialized reps; a/b advance 8 bytes per rep — frozen stripmine).
- rescale (MAT.RESCALE): EXACT TFLite/gemmlowp two-step semantics (frozen by
  ADR-0037 after Grok+Gemini review both rejected the collapsed single-step):
  SaturatingRoundingDoublingHighMul(acc, mult_q31) then RoundingDivideByPOT
  (exp = shift-31, round half away from zero), then +zp, clamp int8.
  shift in [31,62] (right-shift-only v0.1; the v4 example shift=38 -> exp=7).
  Known TFLM double-rounding is part of the contract (e.g. an exact 0.25 can
  round to 1 through the two steps).

Also usable as a generator: `python3 mat_golden.py --emit <dir> --seed N` writes
stimulus + expected hex files for the RTL unit TB (gate_45).
"""

from __future__ import annotations

import argparse
import random
from pathlib import Path

I32_MIN, I32_MAX = -(1 << 31), (1 << 31) - 1


def _wrap32(x: int) -> int:
    x &= 0xFFFF_FFFF
    return x - (1 << 32) if x & 0x8000_0000 else x


def outer_accumulate(acc: list[list[int]], a: list[int], b: list[int]) -> None:
    """One outer product into an 8x8 int32 accumulator (wrapping, like the RTL)."""
    for r in range(8):
        for c in range(8):
            acc[r][c] = _wrap32(acc[r][c] + a[r] * b[c])


def srdhm(a: int, b: int) -> int:
    """gemmlowp SaturatingRoundingDoublingHighMul, bit-exact (int32 x int32)."""
    if a == I32_MIN and b == I32_MIN:
        return I32_MAX
    ab = a * b
    nudge = (1 << 30) if ab >= 0 else (1 - (1 << 30))
    s = ab + nudge
    # C++ int64 division truncates toward zero
    return s // (1 << 31) if s >= 0 else -((-s) // (1 << 31))


def rdbpot(x: int, exp: int) -> int:
    """gemmlowp RoundingDivideByPOT: round half away from zero."""
    if exp == 0:
        return x
    mask = (1 << exp) - 1
    remainder = x & mask                          # two's-complement low bits
    threshold = (mask >> 1) + (1 if x < 0 else 0)
    return (x >> exp) + (1 if remainder > threshold else 0)


def rescale(acc32: int, mult_q31: int, shift: int, zp: int, cmin: int, cmax: int) -> int:
    """Bit-exact MAT.RESCALE = TFLite two-step (SRDHM + RDBPOT) + zp + clamp."""
    assert 31 <= shift <= 62
    out = rdbpot(srdhm(acc32, mult_q31), shift - 31) + zp
    return max(cmin, min(cmax, out))


def run_op_sequence(ops, banks: int = 4):
    """ops: list of dicts driving a software model of the engine.
    kinds: clr {mask}, op {a: bytes, b: bytes, rpt, bank}, rescale {bank, mult,
    shift, zp, cmin, cmax} -> returns list of 64-byte outputs per rescale."""
    accs = [[[0] * 8 for _ in range(8)] for _ in range(banks)]
    outs = []
    for o in ops:
        if o["kind"] == "clr":
            for k in range(banks):
                if (o["mask"] >> k) & 1:
                    accs[k] = [[0] * 8 for _ in range(8)]
        elif o["kind"] == "op":
            for rep in range(o["rpt"]):
                a = o["a"][rep * 8:rep * 8 + 8]
                b = o["b"][rep * 8:rep * 8 + 8]
                outer_accumulate(accs[o["bank"]], a, b)
        elif o["kind"] == "rescale":
            acc = accs[o["bank"]]
            out = bytearray()
            for r in range(8):
                for c in range(8):
                    v = rescale(acc[r][c], o["mult"], o["shift"], o["zp"],
                                o["cmin"], o["cmax"])
                    out.append(v & 0xFF)
            outs.append(bytes(out))
    return outs


def _s8(v: int) -> int:
    v &= 0xFF
    return v - 256 if v & 0x80 else v


def emit_vectors(outdir: Path, seed: int) -> None:
    rng = random.Random(seed)
    cases = []
    # directed rescale corners on a known acc value set
    corner_accs = [0, 1, -1, 127, -128, 255, -255, 240, 16129, -16384,
                   I32_MAX, I32_MIN, I32_MIN + 1, 0x4000_0000 - 1, -0x4000_0000]
    cases.append({
        "kind": "corner_rescale",
        "accs": corner_accs,
        "params": [
            (0x54C4_699A, 38, -128, -128, 127),      # the v4 §06 worked example
            (0x7FFF_FFFF, 31, 0, -128, 127),
            (0x4000_0000, 31, 0, -128, 127),
            (0x4000_0000, 62, 127, -128, 127),
            (0x2AAA_AAAB, 33, -1, -100, 100),
            (0x8000_0000 - (1 << 32), 31, 0, -128, 127),
        ],
    })
    lines_in, lines_exp = [], []
    for accv in corner_accs:
        for (m, sh, zp, cmin, cmax) in cases[0]["params"]:
            o = rescale(accv, m, sh, zp, cmin, cmax)
            lines_in.append(f"{accv & 0xFFFFFFFF:08x} {m & 0xFFFFFFFF:08x} {sh:02x} {zp & 0xFF:02x} "
                            f"{cmin & 0xFF:02x} {cmax & 0xFF:02x}")
            lines_exp.append(f"{o & 0xFF:02x}")
    (outdir / "rescale_cases.txt").write_text("\n".join(lines_in) + "\n")
    (outdir / "rescale_expected.txt").write_text("\n".join(lines_exp) + "\n")

    # random end-to-end op sequences (per case: a/b bytes, rpt, one rescale)
    seq_in, seq_exp = [], []
    for _ in range(24):
        rpt = rng.choice([1, 2, 4, 8])
        a = [rng.randint(-128, 127) for _ in range(8 * rpt)]
        b = [rng.randint(-128, 127) for _ in range(8 * rpt)]
        mult = rng.randint(1 << 30, I32_MAX)     # TFLM-normalized multiplier range
        shift = rng.randint(31, 46)
        zp = rng.randint(-128, 127)
        outs = run_op_sequence([
            {"kind": "clr", "mask": 0xF},
            {"kind": "op", "a": a, "b": b, "rpt": rpt, "bank": 0},
            {"kind": "rescale", "bank": 0, "mult": mult, "shift": shift,
             "zp": zp, "cmin": -128, "cmax": 127},
        ])
        seq_in.append(" ".join([f"{rpt:02x}", f"{mult:08x}", f"{shift:02x}",
                                f"{zp & 0xFF:02x}"] +
                               [f"{x & 0xFF:02x}" for x in a] +
                               [f"{x & 0xFF:02x}" for x in b]))
        seq_exp.append("".join(f"{x:02x}" for x in outs[0]))
    (outdir / "seq_cases.txt").write_text("\n".join(seq_in) + "\n")
    (outdir / "seq_expected.txt").write_text("\n".join(seq_exp) + "\n")

    # per-channel rescale (ADR-0042): 8 cases, each with a full acc tile and
    # per-COLUMN (mult, shift) sets + per-tensor zp/clamp; 64 bytes compared
    pc_in, pc_exp = [], []
    for _ in range(8):
        accs = [rng.randint(-(1 << 20), 1 << 20) for _ in range(64)]
        mults = [rng.randint(1 << 30, I32_MAX) for _ in range(8)]
        shifts = [rng.randint(31, 46) for _ in range(8)]
        zp = rng.randint(-128, 127)
        out = bytearray()
        for r in range(8):
            for c in range(8):
                out.append(rescale(accs[r * 8 + c], mults[c], shifts[c],
                                   zp, -128, 127) & 0xFF)
        pc_in.append(" ".join([f"{zp & 0xFF:02x}"] +
                              [f"{m:08x}" for m in mults] +
                              [f"{s:02x}" for s in shifts] +
                              [f"{a & 0xFFFFFFFF:08x}" for a in accs]))
        pc_exp.append("".join(f"{x:02x}" for x in out))
    (outdir / "pc_cases.txt").write_text("\n".join(pc_in) + "\n")
    (outdir / "pc_expected.txt").write_text("\n".join(pc_exp) + "\n")
    print(f"emitted {len(lines_in)} rescale corners + {len(seq_in)} sequences "
          f"+ {len(pc_in)} per-channel tiles -> {outdir}")


def selftest() -> None:
    # v4 §06 worked example: mult=0x54C4699A (~0.6621*2^31), shift=38, zp=-128
    print("v4 example:", rescale(16129, 0x54C4699A, 38, -128, -128, 127))
    # TFLM two-step signatures (incl. the double-rounding contract)
    assert srdhm(I32_MIN, I32_MIN) == I32_MAX              # saturation edge
    assert rescale(3, 1 << 30, 32, 0, -128, 127) == 1      # 0.75 -> 1
    assert rescale(-3, 1 << 30, 32, 0, -128, 127) == -1    # -0.75 -> -1
    # gemmlowp bit-truths (measured, not folklore): SRDHM negative halves land
    # TOWARD zero (nudge 1-2^30 + trunc division); the double-rounding lifts an
    # exact +0.25 to 1. These asymmetries ARE the TFLM contract.
    assert rescale(1, 1 << 30, 32, 0, -128, 127) == 1      # +0.25 -> 1 (double round)
    assert rescale(-1, 1 << 30, 32, 0, -128, 127) == 0     # -0.25 -> 0
    assert rescale(2, 1 << 30, 32, 0, -128, 127) == 1      # +0.5 -> 1
    assert rescale(-2, 1 << 30, 32, 0, -128, 127) == -1    # -0.5 -> -1 (via -1 srdhm, rdbpot exp... measured)
    print("golden selftest PASS")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--emit", type=Path)
    ap.add_argument("--seed", type=int, default=20260704)
    ap.add_argument("--selftest", action="store_true")
    args = ap.parse_args()
    if args.selftest:
        selftest()
        return 0
    if args.emit:
        args.emit.mkdir(parents=True, exist_ok=True)
        emit_vectors(args.emit, args.seed)
        return 0
    ap.print_help()
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
