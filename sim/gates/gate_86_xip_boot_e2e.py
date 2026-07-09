"""gate_86_xip_boot_e2e — ADR-0069 Step B: host boots and runs from QSPI flash.

Authority: the SAME host_producer sources are linked twice — imem VMA 0x0
(existing gate_soc_m3v_smoke path) and flash VMA 0x4000_0000 (this gate). In
tb_soc_m3v_xip the host resets at 0x4000_0000 with instruction memory EMPTY
(HOST_INIT_HEX="") — every instruction fetch and rodata load goes over the QSPI
pins through spi_nor_model (green-wash guard: nothing can execute from imem).
The firmware performs the full q_proj CQ offload (load NPU firmware, descriptors,
doorbell, poll, writeback) and the result is asserted three ways:

  1. XIP-boot result bytes == NumPy golden tile (gate_46 authority);
  2. XIP-boot result bytes == imem-boot result bytes (same-source dual link);
  3. TB asserts warm_reads > 0 (continuous-read actually engaged) via the
     SOC_M3V_XIP_QSPI stat line, and no host trap / AXI error.

Deviation from the ADR's original "same ELF" phrasing (recorded): the code is
position-dependent (absolute la/auipc), so dual-boot equality is proven at the
same-SOURCE dual-LINK level, not a single relocated binary.

NOT a performance gate: XIP fetch is tens of clk/word; TB watchdog is ~20x the
imem-boot budget by design (timeout = hang, not slowness).
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_RTL, CPU_M1_DIR  # noqa: E402
from gate_46_cq_matrix_e2e import _golden_tile  # noqa: E402

HOST_RTL = [
    CPU_M1_DIR / "axil_bridge.v",
    ROOT / "design/cpu_m1/soc/plic.v",
    ROOT / "design/cpu_m1/soc/uart.v",
    ROOT / "design/cpu_m1/soc/clint.v",
    ROOT / "design/cpu_m1/soc/dm.v",
    ROOT / "design/cpu_m1/soc/dtm.v",
]
NPU_RTL = [ROOT / f"design/npu/rtl/{m}.v" for m in (
    "npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr",
    "mat_engine", "npu_ml_ctrl", "axi_full_sram", "axil_to_full",
    "axi_full_arbiter_2x1",
)]
SOC_RTL = [ROOT / f"design/soc/{m}.v" for m in (
    "axil_imem", "plic_axil_shim", "periph_axil_shim", "soc_axil_decode",
    "soc_m3v_top", "gpio",
)]
SOC_RTL += [ROOT / f"design/soc/qspi/{m}" for m in (
    "qspi_master_p0.sv", "qspi_xip.sv", "qspi_master_p2.sv", "qspi_xip_quad.sv",
    "qspi_prog.sv", "qspi_axil_front.v", "qspi_csr.v",
)]
TB = [ROOT / "design/npu/dv/tb/spi_nor_model.v",
      ROOT / "design/npu/dv/tb/tb_soc_m3v_xip.v"]
FWDIR = ROOT / "design/npu/sw/host_producer"


def _build_fw():
    subprocess.run(["make", "clean"], cwd=FWDIR, check=True, capture_output=True, text=True)
    r = subprocess.run(["make", "all", "xip"], cwd=FWDIR, capture_output=True, text=True)
    assert r.returncode == 0, f"host producer build failed:\n{r.stdout}\n{r.stderr}"
    assert (FWDIR / "host_producer_xip.flashhex").exists()


def _dump_bytes(path: Path) -> bytes:
    got = bytearray()
    for w in path.read_text().split():
        v = int(w, 16)
        got += bytes([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF])
    return bytes(got)


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_xip_boot_q_proj_bit_exact(tmp_path):
    _build_fw()
    mdir = tmp_path / "obj"
    files = CPU_M1_RTL + HOST_RTL + NPU_RTL + SOC_RTL + TB
    b = subprocess.run([
        "verilator", "--binary", "--timing", "-Wno-fatal",
        "--top-module", "tb_soc_m3v_xip", "-Mdir", str(mdir),
        *CPU_M1_ARGS, *[str(p) for p in files],
    ], cwd=ROOT, capture_output=True, text=True)
    binary = mdir / "Vtb_soc_m3v_xip"
    assert binary.exists(), f"verilator build failed:\n{b.stdout[-3000:]}\n{b.stderr[-2000:]}"

    out = subprocess.run(
        [str(binary), f"+FLASH_HEX={FWDIR / 'host_producer_xip.flashhex'}"],
        cwd=ROOT, capture_output=True, text=True, timeout=3600).stdout
    assert "SOC_M3V_XIP_PASS" in out, out[-4000:]
    assert "SOC_M3V_XIP: 0 errors" in out, out[-2000:]

    # continuous-read must actually engage during straight-line fetch
    import re
    m = re.search(r"SOC_M3V_XIP_QSPI cold=(\d+) warm=(\d+)", out)
    assert m, out[-2000:]
    assert int(m.group(2)) > 0, f"warm_reads==0 — continuous read never engaged:\n{out[-1500:]}"

    got = _dump_bytes(ROOT / "soc_m3v_xip_result.dump")
    exp = _golden_tile()
    assert got == exp, f"XIP result != golden:\n got={got.hex()}\n exp={exp.hex()}"

    # same-source dual-link equality vs the imem-boot dump if present
    imem_dump = ROOT / "soc_m3v_result.dump"
    if imem_dump.exists():
        assert _dump_bytes(imem_dump) == got, "XIP-boot result != imem-boot result"
    print(f"XIP_BOOT_BIT_EXACT_PASS bytes={len(exp)} warm={m.group(2)}")
