#!/usr/bin/env python3
"""ADR-0036 gate_42 — mixed vector/scalar random generator (Stage 3B subset).

Constraints (the honest envelope of what 3B implements):
- configs: legal SEW x LMUL with LMUL in {m1, mf2, mf4} only (m2+ = deferred-illegal)
- ops: vadd.vv/vi/vx, vsub.vv/vx, vmv.v.v/x/i, vmerge.vvm, vmv.x.s
- every vector op sequence ends in a vmv.x.s probe + csrr checkpoints (P0④)
- vector registers are always written before read; v0 only used as vmerge mask
- vstart is never nonzero at a vector op (arithmetic w/ vstart!=0 = illegal, Spike-matched)
- straight-line, ebreak terminator, fits 4KB TCM
"""

from __future__ import annotations

import argparse
import random
from pathlib import Path

CONFIGS = [("e8", "mf4"), ("e8", "mf2"), ("e8", "m1"),
           ("e16", "mf2"), ("e16", "m1"), ("e32", "m1")]
SCALARS = [f"x{i}" for i in range(5, 16)]   # t0..a5 pool for li/probes


def gen(seed: int, blocks: int) -> str:
    rng = random.Random(seed)
    out = [
        ".section .init",
        ".global _start",
        "_start:",
        f"    /* vector-random seed={seed} blocks={blocks} (3B subset) */",
        "    li   t0, 0x200",
        "    csrs mstatus, t0",
    ]
    written: set[int] = set()
    vpool = list(range(1, 24))

    for _ in range(blocks):
        sew, lmul = rng.choice(CONFIGS)
        avl = rng.choice([0, 1, 2, 3, 4, 7, 8, 15, 16, 31, 100])
        ta = rng.choice(["ta", "tu"])
        out.append(f"    li   a0, {avl}")
        out.append(f"    vsetvli t1, a0, {sew}, {lmul}, {ta}, ma")
        out.append("    csrr t2, vl")
        out.append("    csrr t3, vtype")

        # seed 2 fresh registers so sources always have defined content
        for _ in range(2):
            vd = rng.choice(vpool)
            if rng.random() < 0.5:
                out.append(f"    vmv.v.i v{vd}, {rng.randint(-16, 15)}")
            else:
                sr = rng.choice(SCALARS)
                out.append(f"    li   {sr}, {rng.randint(-2048, 2047)}")
                out.append(f"    vmv.v.x v{vd}, {sr}")
            written.add(vd)

        wl = sorted(written)
        for _ in range(rng.randint(3, 6)):
            vd = rng.choice(vpool)
            kind = rng.random()
            if kind < 0.30:
                out.append(f"    vadd.vv v{vd}, v{rng.choice(wl)}, v{rng.choice(wl)}")
            elif kind < 0.45:
                out.append(f"    vsub.vv v{vd}, v{rng.choice(wl)}, v{rng.choice(wl)}")
            elif kind < 0.60:
                out.append(f"    vadd.vi v{vd}, v{rng.choice(wl)}, {rng.randint(-16, 15)}")
            elif kind < 0.72:
                sr = rng.choice(SCALARS)
                out.append(f"    li   {sr}, {rng.randint(-2048, 2047)}")
                out.append(f"    vadd.vx v{vd}, v{rng.choice(wl)}, {sr}")
            elif kind < 0.82:
                out.append(f"    vmv.v.v v{vd}, v{rng.choice(wl)}")
            elif kind < 0.92:
                out.append(f"    vmv.v.i v0, {rng.randint(-16, 15)}")
                vd = rng.choice([v for v in vpool if v != 0])
                out.append(f"    vmerge.vvm v{vd}, v{rng.choice(wl)}, v{rng.choice(wl)}, v0")
            else:
                sr = rng.choice(SCALARS)
                out.append(f"    li   {sr}, {rng.randint(-2048, 2047)}")
                out.append(f"    vsub.vx v{vd}, v{rng.choice(wl)}, {sr}")
            written.add(vd)
            wl = sorted(written)

        # scalar-visible probe + checkpoint (P0④ discipline)
        pr = rng.choice(SCALARS)
        out.append(f"    vmv.x.s {pr}, v{rng.choice(wl)}")
        out.append("    csrr t4, vstart")

    out.extend(["    ebreak", ""])
    return "\n".join(out) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--seed", type=int, default=20260704)
    ap.add_argument("--blocks", type=int, default=52)
    ap.add_argument("--out", type=Path, default=Path("firmware_vrand.S"))
    args = ap.parse_args()
    args.out.write_text(gen(args.seed, args.blocks), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
