"""gate_soc_m3v_smoke — ADR-0068 minimal real-host SoC CQ matrix smoke."""

import shutil
import subprocess
import sys
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
    "qspi_master_p0.sv", "qspi_xip.sv", "qspi_master_p2.sv", "qspi_xip_quad.sv", "qspi_axil_front.v",
)]
TB = [ROOT / "design/npu/dv/tb/tb_soc_m3v.v"]
FWDIR = ROOT / "design/npu/sw/host_producer"


def _build_host():
    subprocess.run(["make", "clean"], cwd=FWDIR, check=True, capture_output=True, text=True)
    r = subprocess.run(["make", "all", "size"], cwd=FWDIR, capture_output=True, text=True)
    assert r.returncode == 0, f"host producer build failed:\n{r.stdout}\n{r.stderr}"
    assert (FWDIR / "host_producer.hex").exists(), r.stdout + r.stderr
    return r.stdout + r.stderr


def _run_verilator(tmp_path: Path) -> str:
    mdir = tmp_path / "obj"
    files = CPU_M1_RTL + HOST_RTL + NPU_RTL + SOC_RTL + TB
    b = subprocess.run([
        "verilator", "--binary", "--timing", "-Wno-fatal",
        "--top-module", "tb_soc_m3v", "-Mdir", str(mdir),
        *CPU_M1_ARGS, *[str(p) for p in files],
    ], cwd=ROOT, capture_output=True, text=True)
    binary = mdir / "Vtb_soc_m3v"
    assert binary.exists(), f"verilator build failed:\n{b.stdout}\n{b.stderr}"
    out = subprocess.run([str(binary)], cwd=ROOT, capture_output=True,
                         text=True, timeout=240).stdout
    assert "SOC_M3V_PASS" in out, out
    assert "SOC_M3V: 0 errors" in out, out
    return out


def _dump_bytes(path: Path) -> bytes:
    got = bytearray()
    for w in path.read_text().split():
        v = int(w, 16)
        got += bytes([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF])
    return bytes(got)


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_soc_m3v_real_host_cq_matrix_bit_exact(tmp_path):
    _build_host()
    out = _run_verilator(tmp_path)
    got = _dump_bytes(ROOT / "soc_m3v_result.dump")
    exp = _golden_tile()
    assert got == exp, f"SOC_M3V byte mismatch:\n got={got.hex()}\n exp={exp.hex()}\n{out}"
    print(f"SOC_M3V_BIT_EXACT_PASS bytes={len(exp)}")
