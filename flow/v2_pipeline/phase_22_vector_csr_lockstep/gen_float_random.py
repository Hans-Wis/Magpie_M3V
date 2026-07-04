#!/usr/bin/env python3
"""ADR-0050 F2-F4 random generator: random bit patterns through the full F
datapath vs Spike (softfloat). Every op followed by fmv.x.w + frflags
checkpoints; rm churn via csrw frm; deliberate special-value density (NaN/
inf/subnormal/zero) alongside uniform bits."""
import argparse
import random
from pathlib import Path

SPECIALS = [0x00000000, 0x80000000, 0x3F800000, 0xBF800000, 0x7F800000,
            0xFF800000, 0x7FC00000, 0x7FA00001, 0x00000001, 0x807FFFFF,
            0x00800000, 0x7F7FFFFF, 0xFF7FFFFF, 0x3F000000, 0x34000000,
            0x00400000, 0x80000001, 0x7F000000]


def fbits(rng):
    r = rng.random()
    if r < 0.35:
        return rng.choice(SPECIALS)
    if r < 0.55:  # near-overflow / near-underflow exponents
        e = rng.choice([0, 1, 2, 0xFD, 0xFE, 0x7F, 0x80])
        return (rng.getrandbits(1) << 31) | (e << 23) | rng.getrandbits(23)
    return rng.getrandbits(32)


def gen(seed, blocks):
    rng = random.Random(seed)
    out = [".section .init", ".global _start", "_start:",
           "    li   t0, 0x2200", "    csrs mstatus, t0",
           f"    /* float-random seed={seed} blocks={blocks} */"]
    fpool = list(range(1, 30))
    written = set()
    for _ in range(blocks):
        out.append(f"    li   t0, {rng.randint(0, 4)}")
        out.append("    csrw frm, t0")
        # seed 3 fresh f-regs
        for _ in range(3):
            fd = rng.choice(fpool)
            out.append(f"    li   t1, {fbits(rng)}")
            out.append(f"    fmv.w.x f{fd}, t1")
            written.add(fd)
        wl = sorted(written)
        for _ in range(rng.randint(4, 7)):
            fd = rng.choice(fpool)
            k = rng.random()
            a, b, c = rng.choice(wl), rng.choice(wl), rng.choice(wl)
            if k < 0.22:
                out.append(f"    fadd.s f{fd}, f{a}, f{b}")
            elif k < 0.40:
                out.append(f"    fsub.s f{fd}, f{a}, f{b}")
            elif k < 0.58:
                out.append(f"    fmul.s f{fd}, f{a}, f{b}")
            elif k < 0.74:
                op = rng.choice(["fmadd.s", "fmsub.s", "fnmadd.s", "fnmsub.s"])
                out.append(f"    {op} f{fd}, f{a}, f{b}, f{c}")
            elif k < 0.87:
                out.append(f"    fdiv.s f{fd}, f{a}, f{b}")
            else:
                out.append(f"    fsqrt.s f{fd}, f{a}")
            written.add(fd)
            wl = sorted(written)
            out.append(f"    fmv.x.w t2, f{fd}")
            out.append("    csrr t3, fflags")
        out.append("    csrw fflags, x0")
    out.append("    ebreak")
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--seed", type=int, default=20260705)
    ap.add_argument("--blocks", type=int, default=40)
    ap.add_argument("--out", type=Path, default=Path("firmware_frand.S"))
    a = ap.parse_args()
    a.out.write_text(gen(a.seed, a.blocks))
