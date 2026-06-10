#!/usr/bin/env python3
"""Run Spike with misaligned accesses trapping and check expected exceptions."""

from __future__ import annotations

import re
import os
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent
SPIKE_BASE = 0x8000_0000
TOOLCHAIN_DIR = Path("/home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin")
GCC = TOOLCHAIN_DIR / "riscv64-unknown-elf-gcc"
TOOLCHAIN_LIBS = (
    "/home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib:"
    "/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib:"
    "/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib"
)


TRAP_RE = re.compile(
    r"exception trap_(?P<name>load|store)_address_misaligned, epc 0x(?P<epc>[0-9a-f]+)\n"
    r"core\s+0:\s+tval 0x(?P<tval>[0-9a-f]+)"
)

CASES = [
    ("lw", "load", 4, "lw   x15, 1(x10)"),
    ("lh", "load", 4, "lh   x16, 1(x10)"),
    ("sh", "store", 6, "addi x17, zero, 0x123\n    sh   x17, 1(x10)"),
]


def write_case_asm(path: Path, body: str) -> None:
    path.write_text(
        ".section .init\n"
        ".global _start\n"
        "_start:\n"
        "    .option push\n"
        "    .option norvc\n"
        "    la   x10, data_area\n"
        f"    {body}\n"
        "    ebreak\n"
        "    .option pop\n"
        "    .balign 4\n"
        "data_area:\n"
        "    .word 0x44332211\n"
        "    .word 0x88776655\n",
        encoding="utf-8",
    )


def build_case(asm: Path, elf: Path) -> None:
    env = os.environ.copy()
    env["LD_LIBRARY_PATH"] = TOOLCHAIN_LIBS
    subprocess.run(
        [
            str(GCC),
            "-Os",
            "-march=rv32imc_zicsr_zifencei",
            "-mabi=ilp32",
            "-nostartfiles",
            "-nostdlib",
            "-ffreestanding",
            "-Wl,-Bstatic,-T,firmware_spike.lds,--strip-debug",
            "-o",
            str(elf),
            str(asm),
        ],
        cwd=ROOT,
        env=env,
        check=True,
    )


def run_case(name: str, elf: Path, log: Path) -> tuple[str, int]:
    cmd = [
        "spike",
        "--isa=rv32imc_zicsr_zifencei",
        "--priv=m",
        f"--pc=0x{SPIKE_BASE:08x}",
        "-m0x80000000:0x10000",
        "--log-commits",
        "-l",
        f"--log={log}",
        "--instructions=40",
        str(elf),
    ]
    result = subprocess.run(cmd, cwd=ROOT, text=True, capture_output=True)
    combined = (log.read_text(encoding="utf-8", errors="replace") if log.exists() else "")
    combined += "\n" + result.stdout + "\n" + result.stderr
    match = TRAP_RE.search(combined)
    if not match:
        raise RuntimeError(f"{name}: Spike did not report a misaligned exception")
    return match.group("name"), int(match.group("tval"), 16)


def main() -> int:
    observed: list[str] = []
    try:
        for mnemonic, expected_kind, expected_mcause, body in CASES:
            asm = ROOT / f"spike_case_{mnemonic}.S"
            elf = ROOT / f"spike_case_{mnemonic}.elf"
            log = ROOT / f"spike_{mnemonic}.log"
            write_case_asm(asm, body)
            build_case(asm, elf)
            kind, tval = run_case(mnemonic, elf, log)
            if kind != expected_kind:
                print(f"FAIL: Spike {mnemonic} kind={kind} expected={expected_kind}")
                return 1
            if (tval & 0x3) != 1:
                print(f"FAIL: Spike {mnemonic} tval=0x{tval:08x} not addr%%4==1")
                return 1
            observed.append(f"{mnemonic}:mcause={expected_mcause}:mtval=0x{tval:08x}")
    except Exception as exc:
        print(f"FAIL: {exc}")
        return 1

    print("PASS: Spike trap-on-misaligned observed " + "; ".join(observed))
    return 0


if __name__ == "__main__":
    sys.exit(main())
