#!/usr/bin/env python3
"""Generate deterministic bounded RV32IMC assembly for Phase 3.5."""

from __future__ import annotations

import argparse
import random
from pathlib import Path


ALU_R = ["add", "sub", "xor", "or", "and", "sll", "srl", "sra", "slt", "sltu"]
ALU_I = ["addi", "xori", "ori", "andi", "slti", "sltiu"]
SH_I = ["slli", "srli", "srai"]
M_OPS = ["mul", "mulh", "mulhu", "div", "divu", "rem", "remu"]
LOADS = [("lw", 4), ("lh", 2), ("lhu", 2), ("lb", 1), ("lbu", 1)]
STORES = [("sw", 4), ("sh", 2), ("sb", 1)]


def reg(rng: random.Random, *, avoid: set[int] | None = None) -> int:
    avoid = avoid or set()
    choices = [idx for idx in range(5, 30) if idx not in avoid]
    return rng.choice(choices)


def signed_imm(rng: random.Random, bits: int = 12) -> int:
    lo = -(1 << (bits - 1))
    hi = (1 << (bits - 1)) - 1
    return rng.randint(lo, hi)


def gen(seed: int, count: int) -> str:
    rng = random.Random(seed)
    out: list[str] = [
        ".section .init",
        ".global _start",
        "_start:",
        f"    /* deterministic pseudo-random seed={seed} count={count} */",
        "    lui  sp, %hi(16*1024)",
        "    addi sp, sp, %lo(16*1024)",
        "    la   x31, data_area",
        "    addi x30, zero, 7       /* non-zero divisor */",
    ]

    for idx in range(5, 30):
        imm = rng.randint(1, 0x7FF)
        out.append(f"    addi x{idx}, zero, {imm}")

    out.extend(
        [
            ".option push",
            ".option rvc",
            "    c.li   s0, 1",
            "    c.addi s0, 2",
            "    c.mv   s1, s0",
            ".option pop",
        ]
    )

    for _ in range(count):
        kind = rng.random()
        if kind < 0.32:
            if rng.random() < 0.55:
                op = rng.choice(ALU_I)
                out.append(f"    {op} x{reg(rng)}, x{reg(rng)}, {signed_imm(rng)}")
            else:
                op = rng.choice(SH_I)
                out.append(f"    {op} x{reg(rng)}, x{reg(rng)}, {rng.randint(0, 31)}")
        elif kind < 0.56:
            op = rng.choice(ALU_R)
            out.append(f"    {op} x{reg(rng)}, x{reg(rng)}, x{reg(rng)}")
        elif kind < 0.72:
            op = rng.choice(M_OPS)
            rs2 = 30 if op in {"div", "divu", "rem", "remu"} else reg(rng)
            out.append(f"    {op} x{reg(rng)}, x{reg(rng)}, x{rs2}")
        elif kind < 0.86:
            op, width = rng.choice(LOADS)
            offset = rng.randint(0, 15) * width
            out.append(f"    {op} x{reg(rng)}, {offset}(x31)")
        else:
            op, width = rng.choice(STORES)
            offset = rng.randint(0, 15) * width
            out.append(f"    {op} x{reg(rng)}, {offset}(x31)")

    out.extend(
        [
            "done:",
            "    ebreak",
            "",
            "    .balign 4",
            "data_area:",
        ]
    )
    for _ in range(20):
        out.append(f"    .word 0x{rng.getrandbits(32):08x}")
    return "\n".join(out) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=20260607)
    parser.add_argument("--count", type=int, default=48)
    parser.add_argument("--out", type=Path, default=Path("firmware.S"))
    args = parser.parse_args()
    args.out.write_text(gen(args.seed, args.count), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
