#!/usr/bin/env python3
"""ADR-0036/0049 — mixed vector/scalar random generator (3B+3C+S1 subset).

Constraints (the honest envelope of what 3B implements):
- configs: legal SEW x LMUL with LMUL in {m1, mf2, mf4} only (m2+ = deferred-illegal)
- ops: vadd.vv/vi/vx, vsub.vv/vx, vmv.v.v/x/i, vmerge.vvm, vmv.x.s
- every vector op sequence ends in a vmv.x.s probe + csrr checkpoints (P0④)
- vector registers are always written before read; v0 only used as vmerge mask
- vstart is never nonzero at a vector op (arithmetic w/ vstart!=0 = illegal, Spike-matched)
- straight-line, ebreak terminator, fits 4KB TCM
- 3C: unit-stride vle8/16/32 + vse8/16/32 against a scalar-initialized pool at
  data_area; EEW picked legal for the live SEW/LMUL (EMUL<=1), base aligned to
  EEW; every store is followed by a scalar lw probe of a touched word
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
        f"    /* vector-random seed={seed} blocks={blocks} (3B+3C subset) */",
        "    li   t0, 0x200",
        "    csrs mstatus, t0",
        "    la   x31, data_area",
    ]
    # scalar-init the 64-byte pool so vector loads always read defined memory
    for w in range(16):
        out.append(f"    li   t0, {rng.getrandbits(31)}")
        out.append(f"    sw   t0, {w*4}(x31)")
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
            elif kind < 0.94:
                sr = rng.choice(SCALARS)
                out.append(f"    li   {sr}, {rng.randint(-2048, 2047)}")
                out.append(f"    vsub.vx v{vd}, v{rng.choice(wl)}, {sr}")
            else:
                out.append(f"    vmv.v.v v{vd}, v{rng.choice(wl)}")
            written.add(vd)
            wl = sorted(written)

        # ---- S1 (ADR-0049): mask pipeline — compare -> logical -> masked arith
        # + min/max; corners: vl in {0,1,VLMAX}, alternating/all-0/all-1 masks,
        # signed edges (Grok DV list)
        if wl:
            cmp_op = rng.choice(["vmseq.vv", "vmsne.vv", "vmslt.vv", "vmsltu.vv",
                                 "vmsle.vv", "vmsleu.vv"])
            out.append(f"    {cmp_op} v0, v{rng.choice(wl)}, v{rng.choice(wl)}")
            if rng.random() < 0.5:
                cmp2 = rng.choice(["vmsgt.vx", "vmsgtu.vx", "vmseq.vi", "vmsne.vi"])
                vtmp = rng.choice([v for v in vpool if v != 0])
                if cmp2.endswith(".vx"):
                    sr = rng.choice(SCALARS)
                    edge = rng.choice([-1, 0, 127, -128, rng.randint(-2048, 2047)])
                    out.append(f"    li   {sr}, {edge}")
                    out.append(f"    {cmp2[:-3]}.vx v{vtmp}, v{rng.choice(wl)}, {sr}")
                else:
                    out.append(f"    {cmp2[:-3]}.vi v{vtmp}, v{rng.choice(wl)}, {rng.randint(-16, 15)}")
                mlog = rng.choice(["vmand.mm", "vmor.mm", "vmxor.mm", "vmnand.mm",
                                   "vmnor.mm", "vmxnor.mm", "vmandn.mm", "vmorn.mm"])
                out.append(f"    {mlog} v0, v0, v{vtmp}")
                written.add(vtmp)
            # masked arithmetic under the freshly built v0
            vd2 = rng.choice([v for v in vpool if v != 0])
            marith = rng.choice([
                f"vadd.vv v{vd2}, v{rng.choice(wl)}, v{rng.choice(wl)}, v0.t",
                f"vsub.vv v{vd2}, v{rng.choice(wl)}, v{rng.choice(wl)}, v0.t",
                f"vadd.vi v{vd2}, v{rng.choice(wl)}, {rng.randint(-16, 15)}, v0.t",
                f"vmax.vv v{vd2}, v{rng.choice(wl)}, v{rng.choice(wl)}, v0.t",
                f"vmin.vv v{vd2}, v{rng.choice(wl)}, v{rng.choice(wl)}, v0.t",
            ])
            out.append(f"    {marith}")
            written.add(vd2)
            # unmasked min/max (max pool shape)
            vd3 = rng.choice(vpool)
            mm = rng.choice(["vmax.vv", "vmaxu.vv", "vmin.vv", "vminu.vv",
                             "vmax.vx", "vminu.vx"])
            if mm.endswith(".vx"):
                sr = rng.choice(SCALARS)
                out.append(f"    li   {sr}, {rng.choice([-1, 0, 1, 127, -128])}")
                out.append(f"    {mm[:-3]}.vx v{vd3}, v{rng.choice(wl)}, {sr}")
            else:
                out.append(f"    {mm[:-3]}.vv v{vd3}, v{rng.choice(wl)}, v{rng.choice(wl)}")
            written.add(vd3)
            wl = sorted(written)
            out.append(f"    vmv.x.s {rng.choice(SCALARS)}, v0")   # mask reg probe

        # 3C: one unit-stride memory op per block (legal EEW for live config)
        sewb = {"e8": 1, "e16": 2, "e32": 4}[sew]
        lm_den = {"m1": 1, "mf2": 2, "mf4": 4, "mf8": 8}.get(lmul, 1)
        vlmax_el = (16 // sewb) // lm_den
        legal_eews = [b for b in (1, 2, 4) if vlmax_el * b <= 16]
        if legal_eews and wl:
            eewb = rng.choice(legal_eews)
            off = rng.randrange(0, 64 - vlmax_el * eewb + 1, eewb) if vlmax_el * eewb < 64 else 0
            suf = {1: "8", 2: "16", 4: "32"}[eewb]
            out.append(f"    addi a1, x31, {off}")
            if rng.random() < 0.5:
                vd = rng.choice(vpool)
                out.append(f"    vle{suf}.v v{vd}, (a1)")
                written.add(vd)
                wl = sorted(written)
                out.append(f"    vmv.x.s {rng.choice(SCALARS)}, v{vd}")
            else:
                out.append(f"    vse{suf}.v v{rng.choice(wl)}, (a1)")
                out.append(f"    lw   {rng.choice(SCALARS)}, {off & ~3}(x31)")

        # scalar-visible probe + checkpoint (P0④ discipline)
        pr = rng.choice(SCALARS)
        out.append(f"    vmv.x.s {pr}, v{rng.choice(wl)}")
        out.append("    csrr t4, vstart")

    out.extend(["    ebreak", "", "    .balign 4", "data_area:", "    .zero 64", ""])
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
