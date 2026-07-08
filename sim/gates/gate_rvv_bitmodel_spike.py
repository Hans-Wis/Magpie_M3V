"""gate_rvv_bitmodel_spike — RVV bit-model is Spike-backed, not RTL-fitted.

Compiles a tiny Zve32x program, runs it on Spike, and compares scalar loads of vsmul/vssra
results against design/npu/sw/golden/rvv_bitmodel.py over corners, exact-half ties, and random
data.  This is the contract source used by the Gemma RMSNorm RVV golden.
"""
from __future__ import annotations

import os
import random
import re
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "design/npu/sw/golden"))
sys.path.insert(0, str(ROOT / "flow/v2_pipeline/lib"))

import rvv_bitmodel as rvv  # noqa: E402
from spike_commit import COMMIT_RE, run_spike  # noqa: E402

TOOLCHAIN = ROOT / ".." / ".." / ".."
GCC = Path("/home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin/riscv64-unknown-elf-gcc")
LDS = ROOT / "flow/v2_pipeline/phase_20_npu_core_lockstep/firmware_spike.lds"
ISA = "rv32imf_zve32x_zvl128b_zicsr_zifencei"
LD_LIBRARY_PATH = (
    "/home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib:"
    "/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib:"
    "/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib"
)


def _u32(x: int) -> int:
    return int(x) & 0xFFFF_FFFF


def _s32(x: int) -> int:
    x &= 0xFFFF_FFFF
    return x - 0x1_0000_0000 if x & 0x8000_0000 else x


def _emit_words(label: str, values: list[int]) -> str:
    words = ", ".join(f"0x{_u32(v):08x}" for v in values)
    return f"{label}: .word {words}\n"


def _spike_x31_values(log: Path) -> list[int]:
    vals: list[int] = []
    for line in log.read_text().splitlines():
        m = COMMIT_RE.search(line)
        if m and m.group("rd") and int(m.group("rd")) == 31:
            vals.append(_s32(int(m.group("wdata"), 16)))
    return vals


@pytest.mark.skipif(not shutil.which("spike") or not GCC.exists(), reason="Spike/toolchain missing")
def test_rvv_bitmodel_matches_spike_zve32x(tmp_path):
    rng = random.Random(20260708)
    vsmul_pairs = [
        (1 << 30, 2),
        (-(1 << 30) - 1, 2),
        (0x80000000, 0x80000000),
        (0x7FFFFFFF, 0x7FFFFFFF),
        (0x40000000, 3),
        (0x40000000, -3),
        (-7, 0x40000000),
    ]
    for _ in range(17):
        vsmul_pairs.append((rng.randrange(-(1 << 31), 1 << 31),
                            rng.randrange(-(1 << 31), 1 << 31)))

    vssra_cases = [
        (3, 1),            # exact-half tie, positive
        (-3, 1),           # exact-half tie, negative
        (0x7FFFFFFF, 31),
        (0x80000000, 31),
        (13, 3),
        (-128, 3),
    ]
    for _ in range(18):
        vssra_cases.append((rng.randrange(-(1 << 31), 1 << 31), rng.randrange(0, 32)))

    expected: list[int] = []
    asm = [
        ".section .init\n.global _start\n_start:\n",
        "    li t0, 0x200\n    csrs mstatus, t0\n",
        "    lla x20, out\n",
    ]

    for vxrm in range(4):
        for idx in range(0, len(vsmul_pairs), 4):
            chunk = vsmul_pairs[idx:idx + 4]
            a = [p[0] for p in chunk]
            b = [p[1] for p in chunk]
            for av, bv in chunk:
                expected.append(rvv.vsmul(av, bv, vxrm))
            asm += [
                f"    li t0, {vxrm}\n    csrw vxrm, t0\n",
                f"    lla x21, vsmul_a_{vxrm}_{idx}\n    lla x22, vsmul_b_{vxrm}_{idx}\n",
                f"    li a0, {len(chunk)}\n",
                "    vsetvli t1, a0, e32, m1, ta, ma\n",
                "    vle32.v v2, (x21)\n    vle32.v v3, (x22)\n",
                "    vsmul.vv v4, v2, v3\n    vse32.v v4, (x20)\n",
            ]
            for lane in range(len(chunk)):
                asm.append(f"    lw x31, {lane * 4}(x20)\n")

    for vxrm in range(4):
        for idx, (x, sh) in enumerate(vssra_cases):
            expected.append(rvv.vssra(x, sh, vxrm))
            asm += [
                f"    li t0, {vxrm}\n    csrw vxrm, t0\n",
                f"    lla x21, vssra_x_{vxrm}_{idx}\n",
                "    li a0, 1\n    vsetvli t1, a0, e32, m1, ta, ma\n",
                "    vle32.v v2, (x21)\n",
                f"    li t2, {sh}\n    vssra.vx v4, v2, t2\n",
                "    vse32.v v4, (x20)\n    lw x31, 0(x20)\n",
            ]

    asm += ["    ebreak\n\n.section .data\n.align 6\nout: .space 32\n"]
    for vxrm in range(4):
        for idx in range(0, len(vsmul_pairs), 4):
            chunk = vsmul_pairs[idx:idx + 4]
            asm.append(_emit_words(f"vsmul_a_{vxrm}_{idx}", [p[0] for p in chunk]))
            asm.append(_emit_words(f"vsmul_b_{vxrm}_{idx}", [p[1] for p in chunk]))
    for vxrm in range(4):
        for idx, (x, _sh) in enumerate(vssra_cases):
            asm.append(_emit_words(f"vssra_x_{vxrm}_{idx}", [x]))

    src = tmp_path / "rvv_bitmodel_spike.S"
    elf = tmp_path / "rvv_bitmodel_spike.elf"
    log = tmp_path / "spike.log"
    src.write_text("".join(asm))
    env = dict(os.environ)
    env["LD_LIBRARY_PATH"] = LD_LIBRARY_PATH
    subprocess.run([
        str(GCC), "-Os", f"-march={ISA}", "-mabi=ilp32", "-mno-relax",
        "-nostartfiles", "-nostdlib", "-ffreestanding",
        f"-Wl,-Bstatic,-T,{LDS},--strip-debug",
        "-o", str(elf), str(src),
    ], check=True, env=env)

    run_spike(work_dir=tmp_path, elf=elf, log=log, isa=ISA, instructions=5000)
    got = _spike_x31_values(log)
    assert got == expected


def test_bitmodel_covers_requested_corner_values():
    assert rvv.vsmul(1 << 30, 2, 0) == 1
    assert rvv.vsmul(-(1 << 30) - 1, 2, 0) == -1
    assert rvv.vssra(3, 1, 1) == 2       # rne exact half to even
    assert rvv.vssra(1, 1, 3) == 1       # rod inexact result is odd
    assert re.search(r"def vsmul", (ROOT / "design/npu/sw/golden/rvv_bitmodel.py").read_text())
