"""gate_92_qspi_prog — ADR-0071 D2: flash program/erase via QSPI CSR (SoC e2e).

Lifts the P0 honesty bound "no field self-update": host firmware drives the
whole path over real CSRs and the XIP window against spi_nor_model's frozen
semantics (ADR §4/§5). Firmware stages ($fail names the step):

  1 pre-image golden        2 SE busy observed      3 sector 0xFF + outside intact
  4 done sticky seen on the busy==0 STATUS read, cleared by that read
  5 WBUF+PP 16B readback    6 AND-write (re-PP no erase -> only 1->0)
  7 serialization: XIP read issued during SE stalls and completes bit-exact
  8 start-while-busy ignored (CE during SE -> image intact)
  9 MODE write during busy defers to idle (quad readback after, single restore)

TB adds the counter check firmware can't see: SOC_QSPI_COLDMARK delta>0 — the
first XIP read after PROG re-opened a COLD frame (continuous stream was closed
for the PROG grant, ADR §5 CS-ordering).
"""

import re
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
from gate_89_debug_jtag_soc import (  # noqa: E402
    CPU_RTL, NPU_RTL, SOC_PERIPH_RTL, VERILATOR)
from gate_20_axi_fabric import CPU_M1_DIR  # noqa: E402

SOC_RTL = [ROOT / f"design/soc/{m}.v" for m in (
    "axil_imem", "plic_axil_shim", "periph_axil_shim", "soc_axil_decode",
    "soc_m3v_top", "gpio")]
SOC_RTL += [ROOT / f"design/soc/qspi/{m}" for m in (
    "qspi_master_p0.sv", "qspi_xip.sv", "qspi_master_p2.sv", "qspi_xip_quad.sv",
    "qspi_prog.sv", "qspi_axil_front.v", "qspi_csr.v")]
TB = [ROOT / "design/npu/dv/tb/spi_nor_model.v",
      ROOT / "design/npu/dv/tb/tb_soc_m3v_qspi.v"]
IMG = ROOT / "design/npu/dv/tb/xip_img_p2.hex"


def build_tb(tmp_path):
    obj = tmp_path / "obj_dir"
    cmd = [str(VERILATOR), "--binary", "--timing", "-j", "4",
           "--top-module", "tb_soc_m3v_qspi", "--timescale", "1ns/1ns",
           f"-I{CPU_M1_DIR}", "-Mdir", str(obj),
           "-Wno-fatal", "-Wno-DECLFILENAME", "-Wno-TIMESCALEMOD",
           "-Wno-UNUSEDSIGNAL", "-Wno-SYNCASYNCNET"]
    cmd += [str(f) for f in CPU_RTL + SOC_PERIPH_RTL + NPU_RTL + SOC_RTL + TB]
    r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    assert r.returncode == 0, f"verilator build failed:\n{r.stdout[-3000:]}\n{r.stderr[-2000:]}"
    return obj / "Vtb_soc_m3v_qspi"


def run_fw(binary, fwdir_name, hexname):
    fwdir = ROOT / f"design/npu/sw/{fwdir_name}"
    subprocess.run(["make", "clean"], cwd=fwdir, capture_output=True, text=True)
    r = subprocess.run(["make"], cwd=fwdir, capture_output=True, text=True)
    assert r.returncode == 0, f"{fwdir_name} build failed:\n{r.stdout}\n{r.stderr}"
    r = subprocess.run([str(binary),
                        f"+HOST_INIT_HEX={fwdir / hexname}",
                        f"+FLASH_HEX={IMG}"],
                       cwd=ROOT, capture_output=True, text=True, timeout=900)
    return r


@pytest.mark.skipif(not shutil.which("verilator") and not VERILATOR.exists(),
                    reason="no verilator — not-run")
def test_prog_erase_e2e(tmp_path):
    binary = build_tb(tmp_path)
    r = run_fw(binary, "host_qspi_prog", "host_qspi_prog.hex")
    out = r.stdout
    assert "SOC_QSPI_PASS" in out, out[-3000:]
    m = re.search(r"SOC_QSPI_COLDMARK delta=(\d+)", out)
    assert m and int(m.group(1)) > 0, \
        f"post-PROG first XIP read did not re-open cold:\n{out[-1500:]}"
    assert r.returncode == 0, out[-1500:]
