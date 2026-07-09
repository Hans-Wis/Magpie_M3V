"""gate_89_debug_jtag_soc — ADR-0070 P1: dm/dtm mounted on soc_m3v_top (SMOKE).

Scope per ADR-0070 (honestly bounded): halt/resume + one abstract GPR read over
real JTAG bit-bang on the SoC top. Abstract WRITE / CSR / memory access /
ndmreset closure are NOT covered here (core-level debug authority lives in
phase_06_*). Markers asserted from tb_soc_m3v_p1:

  JTAG_IDLE_QUIET_OK  halt_req never asserts while the TAP is idle (tie guard —
                      the TB $fatal's on any idle-window halt_req pulse)
  JTAG_IDCODE_OK      IDCODE == 0x10A98AD3 over the pins
  JTAG_HALT_OK        dmactive -> haltreq -> dmstatus.halted, firmware
                      heartbeat provably FROZEN for 500 clk
  JTAG_SP_OK          abstract read x2 == 0x80010000 (crt0 golden)
  JTAG_RESUME_OK      resumereq -> heartbeat increments again

Shares one TB run with gate_90 semantics but is built/run independently so a
red names the failing phase without cross-contamination.
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
from gate_20_axi_fabric import CPU_M1_DIR  # noqa: E402

VERILATOR = Path("/home/edauser/miniforge3/envs/magpie_claude/bin/verilator")

CPU_RTL = [CPU_M1_DIR / f"{m}.v" for m in (
    "rfu", "alu", "bmu", "idu", "ifu", "lsu", "csr", "trigger", "pmp", "mul",
    "div", "forward", "hazard", "bp", "ras", "cdec", "vexu", "fexu", "core",
    "cpu_m1_top", "axil_bridge")]
SOC_PERIPH_RTL = [ROOT / f"design/cpu_m1/soc/{m}.v" for m in (
    "plic", "uart", "clint", "dm", "dtm")]
NPU_RTL = [ROOT / f"design/npu/rtl/{m}.v" for m in (
    "npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr",
    "mat_engine", "npu_ml_ctrl", "axi_full_sram", "axil_to_full",
    "axi_full_arbiter_2x1")]
SOC_RTL = [ROOT / f"design/soc/{m}.v" for m in (
    "axil_imem", "plic_axil_shim", "periph_axil_shim", "soc_axil_decode",
    "soc_m3v_top", "gpio")]
SOC_RTL += [ROOT / f"design/soc/qspi/{m}" for m in (
    "qspi_master_p0.sv", "qspi_xip.sv", "qspi_master_p2.sv", "qspi_xip_quad.sv",
    "qspi_axil_front.v")]
TB = [ROOT / "design/npu/dv/tb/spi_nor_model.v",
      ROOT / "design/npu/dv/tb/tb_soc_m3v_p1.v"]
FWDIR = ROOT / "design/npu/sw/host_p1"

MARKERS = ["JTAG_IDLE_QUIET_OK", "JTAG_IDCODE_OK", "JTAG_HALT_OK",
           "JTAG_SP_OK", "JTAG_RESUME_OK", "SOC_P1_PASS"]


def build_and_run(tmp_path):
    subprocess.run(["make", "clean"], cwd=FWDIR, capture_output=True, text=True)
    r = subprocess.run(["make"], cwd=FWDIR, capture_output=True, text=True)
    assert r.returncode == 0, f"host_p1 build failed:\n{r.stdout}\n{r.stderr}"

    obj = tmp_path / "obj_dir"
    cmd = [str(VERILATOR), "--binary", "--timing", "-j", "4",
           "--top-module", "tb_soc_m3v_p1", "--timescale", "1ns/1ns",
           f"-I{CPU_M1_DIR}", "-Mdir", str(obj),
           "-Wno-fatal", "-Wno-DECLFILENAME", "-Wno-TIMESCALEMOD",
           "-Wno-UNUSEDSIGNAL", "-Wno-SYNCASYNCNET"]
    cmd += [str(f) for f in CPU_RTL + SOC_PERIPH_RTL + NPU_RTL + SOC_RTL + TB]
    r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    assert r.returncode == 0, f"verilator build failed:\n{r.stdout[-3000:]}\n{r.stderr[-2000:]}"

    r = subprocess.run([str(obj / "Vtb_soc_m3v_p1")],
                       cwd=ROOT, capture_output=True, text=True, timeout=900)
    return r


@pytest.mark.skipif(not shutil.which("verilator") and not VERILATOR.exists(),
                    reason="no verilator — not-run")
def test_debug_jtag_soc_smoke(tmp_path):
    r = build_and_run(tmp_path)
    out = r.stdout
    for m in MARKERS:
        assert m in out, f"{m} missing:\n{out[-3000:]}\n{r.stderr[-800:]}"
    assert "P1_FAIL" not in out, out[-3000:]
    assert r.returncode == 0, out[-1500:]
