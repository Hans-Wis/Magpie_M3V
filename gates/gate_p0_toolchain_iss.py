"""gate_p0_toolchain_iss — Phase 0 "the toolchain applies" gate.

Proves the M3V NPU software contract is real BEFORE any RTL exists:
the OPEN RVV Zve32x toolchain (upstream clang) compiles an int8 vector kernel and the
Spike ISS (VLEN=128 via Zvl128b) executes it correctly — no Google closed compiler needed.

Pipeline: clang (integrated-as, RVV) -> GNU ld (bare-metal HTIF) -> spike --isa rv32im_zve32x_zvl128b.
Golden: int8 dot([1..8],[2..9]) = 240, returned as the HTIF exit code.

Skips (not fails) if clang / riscv64-linux-gnu-gcc / spike are absent, so the gate is honest
about environment capability (§9 taxonomy: not-run != fail).
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
SW = ROOT / "design/npu/sw/rvv_zve32x_smoke"
MARCH = "rv32im_zve32x_zvl128b"
EXPECTED = 240

REQUIRED = ["clang", "riscv64-linux-gnu-gcc", "spike"]


def _have_tools():
    return all(shutil.which(t) for t in REQUIRED)


@pytest.mark.skipif(not _have_tools(), reason=f"missing one of {REQUIRED} — Phase 0 not-run")
def test_open_rvv_toolchain_runs_on_spike_iss(tmp_path):
    def clang(src, out, extra=()):
        subprocess.run(
            ["clang", "--target=riscv32", f"-march={MARCH}", "-mabi=ilp32", *extra,
             "-c", str(SW / src), "-o", str(tmp_path / out)],
            check=True,
        )

    clang("vdot_i8.c", "vdot_i8.o", ["-O2"])
    clang("npu_main.c", "npu_main.o", ["-O2"])
    clang("crt0.S", "crt0.o")

    subprocess.run(
        ["riscv64-linux-gnu-gcc", "-nostdlib", "-nostartfiles",
         f"-march={MARCH}", "-mabi=ilp32", "-Wl,-T," + str(SW / "link.ld"),
         str(tmp_path / "crt0.o"), str(tmp_path / "npu_main.o"), str(tmp_path / "vdot_i8.o"),
         "-o", str(tmp_path / "p0.elf")],
        check=True,
    )

    rc = subprocess.run(
        ["spike", f"--isa={MARCH}", str(tmp_path / "p0.elf")],
        timeout=60,
    ).returncode
    assert rc == EXPECTED, f"Spike ISS returned {rc}, expected int8 dot = {EXPECTED}"


def test_kernel_actually_emits_rvv_instructions():
    """The kernel must lower to real RVV ops (guards against a scalar fallback silently passing)."""
    if not shutil.which("clang"):
        pytest.skip("no clang — not-run")
    s = subprocess.run(
        ["clang", "--target=riscv32", f"-march={MARCH}", "-mabi=ilp32", "-O2",
         "-S", str(SW / "vdot_i8.c"), "-o", "-"],
        check=True, capture_output=True, text=True,
    ).stdout
    for mnem in ("vsetvli", "vle8.v", "vwmul.vv", "vwadd.wv", "vredsum.vs"):
        assert mnem in s, f"expected RVV instruction {mnem!r} not emitted"
