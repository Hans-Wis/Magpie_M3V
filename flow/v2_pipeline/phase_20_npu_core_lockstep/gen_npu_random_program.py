#!/usr/bin/env python3
"""Deterministic bounded RV32IM (no C) generator for the M3V NPU sequencer lockstep.

Adapted from phase_03_05 gen_random_program.py with the ADR-0034 NPU constraints:
- NO compressed instructions (EN_RVC=0; Spike --isa carries no C) — green-wash guard.
- Loop-wrapped random body so >=10k commits fit in the 4KB TCM: x29 = iteration counter.
- Reserved regs: x29 loop counter, x30 divisor, x31 data pointer; dests draw from x5..x28.
- sp parked inside the 4KB TCM (unused by the body, kept sane).
- The DONE mailbox (0x0001_0000) is deliberately never touched: ebreak is the sole
  lockstep terminator (ADR-0034).
"""

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
    # x5..x28 only: x29/x30/x31 are reserved (loop counter / divisor / data base)
    choices = [idx for idx in range(5, 29) if idx not in avoid]
    return rng.choice(choices)


def signed_imm(rng: random.Random, bits: int = 12) -> int:
    lo = -(1 << (bits - 1))
    hi = (1 << (bits - 1)) - 1
    return rng.randint(lo, hi)


def gen(seed: int, count: int, iters: int) -> str:
    rng = random.Random(seed)
    out: list[str] = [
        ".section .init",
        ".global _start",
        "_start:",
        f"    /* deterministic pseudo-random seed={seed} count={count} iters={iters} */",
        "    lui  sp, 1              /* sp = 0x1000 = TCM top (unused by body) */",
        "    la   x31, data_area",
        "    addi x30, zero, 7       /* non-zero divisor */",
        f"    addi x29, zero, {iters} /* loop counter (reserved) */",
    ]

    for idx in range(5, 29):
        imm = rng.randint(1, 0x7FF)
        out.append(f"    addi x{idx}, zero, {imm}")

    out.append("loop_top:")

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
            "    addi x29, x29, -1",
            "    bne  x29, zero, loop_top   /* EX-resolve redirect every iteration (BP off) */",
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
    parser.add_argument("--seed", type=int, default=20260703)
    parser.add_argument("--count", type=int, default=96)
    parser.add_argument("--iters", type=int, default=110)
    parser.add_argument("--out", type=Path, default=Path("firmware.S"))
    args = parser.parse_args()
    args.out.write_text(gen(args.seed, args.count, args.iters), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
