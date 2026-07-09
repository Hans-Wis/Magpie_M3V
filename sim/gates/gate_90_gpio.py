"""gate_90_gpio — ADR-0070 P1: GPIO block on soc_m3v_top.

Markers asserted from tb_soc_m3v_p1 (contract per ADR-0070 §2, Grok #6/#11/#12):

  GPIO_RESET_OK   right after reset deassert: gpio_oe==0 AND gpio_out==0
                  (frozen reset values — no garbage drive before software)
  GPIO_OE_OUT_OK  firmware DIR=0x00FF OUT=0x5A -> pads assert BOTH oe and out
                  (oe checked explicitly, not just out)
  GPIO_IN_OK      TB drives gpio_in=0xA5C3, waits >2FF sync, firmware reads IN
                  and the readback flag is 0x0000A5C3 (upper 16 bits zero —
                  WARL-ignore verified)

Runs the same TB as gate_89 (one firmware exercises both phases) but asserts
only the GPIO contract, so a debug-side break doesn't mask a GPIO red.
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
from gate_89_debug_jtag_soc import VERILATOR, build_and_run  # noqa: E402

MARKERS = ["GPIO_RESET_OK", "GPIO_OE_OUT_OK", "GPIO_IN_OK"]


@pytest.mark.skipif(not shutil.which("verilator") and not VERILATOR.exists(),
                    reason="no verilator — not-run")
def test_gpio_directed(tmp_path):
    r = build_and_run(tmp_path)
    out = r.stdout
    for m in MARKERS:
        assert m in out, f"{m} missing:\n{out[-3000:]}\n{r.stderr[-800:]}"
    assert "P1_FAIL" not in out, out[-3000:]
    assert r.returncode == 0, out[-1500:]
