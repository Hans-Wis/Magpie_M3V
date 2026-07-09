"""gate_88_deploy_smoke — ADR-0069 Step C: the deploy main path, one run.

Grok V4 required a composite: the per-peripheral gates (85/86/87) can all be
green while the composed deployment path is broken. This gate runs ONE firmware
(host_deploy, linked into flash, imem EMPTY) on tb_soc_m3v_xip covering:

  XIP boot @0x4000_0000 -> UART banner 'DPL\\n' (byte-exact scoreboard) ->
  CLINT mtimecmp -> mip.MTIP observed (tie-guard + tick; IRQ depth = gate_87) ->
  full q_proj CQ offload (NPU fw load / descriptors / doorbell / poll) ->
  UART 'OK\\n' -> DONE_PASS, result tile bit-exact vs the gate_46 NumPy golden.

Firmware fail() stages land in shared mem and the TB prints them — a red here
names the failing deploy stage directly.
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
from gate_46_cq_matrix_e2e import _golden_tile  # noqa: E402
from gate_86_xip_boot_e2e import (  # noqa: E402
    CPU_M1_ARGS, CPU_M1_RTL, HOST_RTL, NPU_RTL, SOC_RTL, TB, _dump_bytes)

FWDIR = ROOT / "design/npu/sw/host_deploy"
BANNER = ["UART_TX 44", "UART_TX 50", "UART_TX 4c", "UART_TX 0a",
          "UART_TX 4f", "UART_TX 4b", "UART_TX 0a"]  # D P L \n ... O K \n


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_deploy_smoke_xip_uart_clint_offload(tmp_path):
    subprocess.run(["make", "clean"], cwd=FWDIR, check=True, capture_output=True, text=True)
    r = subprocess.run(["make"], cwd=FWDIR, capture_output=True, text=True)
    assert r.returncode == 0, f"host_deploy build failed:\n{r.stdout}\n{r.stderr}"

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
        [str(binary), f"+FLASH_HEX={FWDIR / 'host_deploy.flashhex'}"],
        cwd=ROOT, capture_output=True, text=True, timeout=3600).stdout
    assert "SOC_M3V_XIP_PASS" in out, out[-4000:]
    assert "SOC_M3V_XIP: 0 errors" in out, out[-2000:]

    pos = -1
    for marker in BANNER:
        nxt = out.find(marker, pos + 1)
        assert nxt > pos, f"UART byte {marker} missing/out-of-order:\n{out[-2500:]}"
        pos = nxt

    got = _dump_bytes(ROOT / "soc_m3v_xip_result.dump")
    assert got == _golden_tile(), "deploy-smoke result != NumPy golden"
    print("DEPLOY_SMOKE_PASS")
