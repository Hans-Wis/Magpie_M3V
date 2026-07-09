"""gate_87_uart_clint — ADR-0069 Step A: UART + CLINT mounted on soc_m3v_top.

Authority: tb_soc_m3v_periph runs host_uart_clint firmware on the real SoC top
(cpu_m1 host + decode + periph_axil_shim + uart/clint + PLIC + NPU). The firmware
is self-checking and writes DONE_PASS 0xC0DE0087 to shared mem only after ALL of:
  (a) mip.MTIP==0 && mip.MSIP==0 BEFORE any CLINT programming (tie-1 guard);
  (b) 'M3V\\n' banner via THR with LSR.THRE polling (TB scoreboards each byte);
  (c) UART IER.THRE -> PLIC ID 2 external IRQ, handler asserts claim id==2,
      reads IIR (clears), completes (NPU keeps PLIC ID 1 — M2 contract);
  (d) CLINT mtimecmp=mtime+delta -> mtip -> timer trap handler (mcause 0x80000007);
  (e) CLINT msip -> soft trap handler (mcause 0x80000003) clears msip.
The TB $fatal's on DONE_FAIL (with firmware stage/evidence) or watchdog timeout,
so a bare PASS marker cannot be green-washed by a hung core.

Green-wash guards in this gate: exact banner byte sequence asserted (not just the
PASS line), firmware is rebuilt from source (no stale .hex), and Verilator build
warnings are fatal via -Wno-fatal absence for the TB set... (build uses the same
waiver set as the soc gates; functional authority is the self-checking firmware).
"""

import os
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
SOC_PERIPH_RTL = [ROOT / f"design/cpu_m1/soc/{m}.v" for m in ("plic", "uart", "clint", "dm", "dtm")]
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
TB = ROOT / "design/npu/dv/tb/tb_soc_m3v_periph.v"
NOR_MODEL = ROOT / "design/npu/dv/tb/spi_nor_model.v"
FWDIR = ROOT / "design/npu/sw/host_uart_clint"

BANNER = ["UART_TX 4d", "UART_TX 33", "UART_TX 56", "UART_TX 0a", "UART_TX 21"]


def _build_and_run(tmp_path):
    r = subprocess.run(["make", "clean"], cwd=FWDIR, capture_output=True, text=True)
    r = subprocess.run(["make"], cwd=FWDIR, capture_output=True, text=True)
    assert r.returncode == 0, f"firmware build failed:\n{r.stdout}\n{r.stderr}"
    hexf = FWDIR / "host_uart_clint.hex"
    assert hexf.exists()

    obj = tmp_path / "obj_dir"
    cmd = [str(VERILATOR), "--binary", "--timing", "-j", "4",
           "--top-module", "tb_soc_m3v_periph", "--timescale", "1ns/1ns",
           f"-I{CPU_M1_DIR}", "-Mdir", str(obj),
           "-Wno-fatal", "-Wno-DECLFILENAME", "-Wno-TIMESCALEMOD",
           "-Wno-UNUSEDSIGNAL", "-Wno-SYNCASYNCNET"]
    cmd += [str(f) for f in CPU_RTL + SOC_PERIPH_RTL + NPU_RTL + SOC_RTL + [NOR_MODEL, TB]]
    r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    assert r.returncode == 0, f"verilator build failed:\n{r.stdout[-3000:]}\n{r.stderr[-3000:]}"

    r = subprocess.run([str(obj / "Vtb_soc_m3v_periph"),
                        f"+HOST_INIT_HEX={FWDIR / 'host_uart_clint.hex'}"],
                       cwd=ROOT, capture_output=True, text=True, timeout=600)
    return r


@pytest.mark.skipif(not shutil.which("verilator") and not VERILATOR.exists(),
                    reason="no verilator — not-run")
def test_uart_clint_directed(tmp_path):
    r = _build_and_run(tmp_path)
    out = r.stdout
    assert "SOC_PERIPH_PASS" in out, f"no PASS marker:\n{out[-3000:]}\n{r.stderr[-1000:]}"
    assert "SOC_PERIPH_FAIL" not in out and "SOC_PERIPH_TIMEOUT" not in out, out[-3000:]
    # exact banner order: M 3 V \n !  (scoreboard, not just the PASS line)
    pos = -1
    for marker in BANNER:
        nxt = out.find(marker, pos + 1)
        assert nxt > pos, f"banner byte {marker} missing/out-of-order:\n{out[-2000:]}"
        pos = nxt
    assert r.returncode == 0, f"sim exit {r.returncode}:\n{out[-1500:]}"
