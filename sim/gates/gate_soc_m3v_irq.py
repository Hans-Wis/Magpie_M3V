"""gate_soc_m3v_irq — IRQ-driven real-host SoC CQ matrix smoke."""

import os
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_DIR, CPU_M1_RTL  # noqa: E402
from gate_46_cq_matrix_e2e import _golden_tile  # noqa: E402

NPU_RTL = [ROOT / f"design/npu/rtl/{m}.v" for m in (
    "npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr",
    "mat_engine", "npu_ml_ctrl", "axi_full_sram", "axil_to_full",
    "axi_full_arbiter_2x1",
)]
HOST_RTL = [
    CPU_M1_DIR / "axil_bridge.v",
    ROOT / "design/cpu_m1/soc/plic.v",
    ROOT / "design/cpu_m1/soc/uart.v",
    ROOT / "design/cpu_m1/soc/clint.v",
    ROOT / "design/cpu_m1/soc/dm.v",
    ROOT / "design/cpu_m1/soc/dtm.v",
]
SOC_RTL = [ROOT / f"design/soc/{m}.v" for m in (
    "axil_imem", "plic_axil_shim", "periph_axil_shim", "soc_axil_decode", "soc_m3v_top", "gpio",
)]
SOC_RTL += [ROOT / f"design/soc/qspi/{m}" for m in (
    "qspi_master_p0.sv", "qspi_xip.sv", "qspi_master_p2.sv", "qspi_xip_quad.sv",
    "qspi_prog.sv", "qspi_axil_front.v", "qspi_csr.v",
)]
TB = [ROOT / "design/npu/dv/tb/tb_soc_m3v_irq.v"]
FWDIR = ROOT / "design/npu/sw/host_producer_irq"
NM = Path("/home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin/riscv64-unknown-elf-nm")
TOOLCHAIN_LIBS = (
    "/home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib:"
    "/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib:"
    "/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib"
)


def _build_host() -> int:
    subprocess.run(["make", "clean"], cwd=FWDIR, check=True, capture_output=True, text=True)
    r = subprocess.run(["make", "all", "size"], cwd=FWDIR, capture_output=True, text=True)
    assert r.returncode == 0, f"IRQ host producer build failed:\n{r.stdout}\n{r.stderr}"
    assert (FWDIR / "host_producer_irq.hex").exists(), r.stdout + r.stderr
    env = os.environ.copy()
    env["LD_LIBRARY_PATH"] = TOOLCHAIN_LIBS
    nm = subprocess.run([str(NM), str(FWDIR / "host_producer_irq.elf")],
                        capture_output=True, text=True, env=env)
    assert nm.returncode == 0, f"nm failed:\n{nm.stdout}\n{nm.stderr}"
    for line in nm.stdout.splitlines():
        fields = line.split()
        if len(fields) == 3 and fields[2] == "trap_entry":
            return int(fields[0], 16)
    raise AssertionError(f"trap_entry symbol not found:\n{nm.stdout}")


def _run_verilator(tmp_path: Path, trap_pc: int) -> str:
    mdir = tmp_path / "obj"
    files = CPU_M1_RTL + HOST_RTL + NPU_RTL + SOC_RTL + TB
    b = subprocess.run([
        "verilator", "--binary", "--timing", "-Wno-fatal",
        "--top-module", "tb_soc_m3v_irq", f"-GTRAP_PC={trap_pc}",
        "-Mdir", str(mdir),
        *CPU_M1_ARGS, *[str(p) for p in files],
    ], cwd=ROOT, capture_output=True, text=True)
    binary = mdir / "Vtb_soc_m3v_irq"
    assert binary.exists(), f"verilator build failed:\n{b.stdout}\n{b.stderr}"
    out = subprocess.run([str(binary)], cwd=ROOT, capture_output=True,
                         text=True, timeout=300).stdout
    assert "SOC_M3V_IRQ_PASS" in out, out
    assert "SOC_M3V_IRQ: 0 errors" in out, out
    assert "SOC_M3V_IRQ_SEEN" in out, out
    return out


def _dump_bytes(path: Path) -> bytes:
    got = bytearray()
    for w in path.read_text().split():
        v = int(w, 16)
        got += bytes([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF])
    return bytes(got)


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_soc_m3v_irq_real_host_cq_matrix_bit_exact(tmp_path):
    trap_pc = _build_host()
    out = _run_verilator(tmp_path, trap_pc)
    got = _dump_bytes(ROOT / "soc_m3v_irq_result.dump")
    exp = _golden_tile()
    assert got == exp, f"SOC_M3V_IRQ byte mismatch:\n got={got.hex()}\n exp={exp.hex()}\n{out}"
    print(f"SOC_M3V_IRQ_BIT_EXACT_PASS bytes={len(exp)} trap_pc=0x{trap_pc:08x}")
