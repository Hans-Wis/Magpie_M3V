"""gate_npu_dma_width — DMA read/write AXI width scaling.

Sweeps DMA_DATA_W=64/128/256 and checks:
  * ARSIZE on the real wire matches clog2(width bytes)
  * AXI read beat count drops by WPB versus the 32-bit reference length
  * TCM receives the same word image as the 32-bit reference pattern
  * misaligned weight-load descriptors raise ERR_ALIGN without issuing a burst
  * AWSIZE/W beat count and writeback memory image match for wide STORE
  * misaligned writeback descriptors raise ERR_ALIGN without issuing a burst
  * DMA_DATA_W=256 narrow_i uses 32-bit AR/AW size, one WSTRB lane, no ERR_ALIGN
"""

import re
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
RTL = [
    ROOT / "design/npu/rtl/npu_dma.v",
    ROOT / "design/npu/rtl/npu_tcm.v",
]
TB = [
    ROOT / "design/npu/dv/tb/axi_full_mem.v",
    ROOT / "design/npu/dv/tb/axi_full_wmem.v",
    ROOT / "design/npu/dv/tb/tb_npu_dma_width.v",
]


def _run_width(tmp_path: Path, width: int) -> str:
    mdir = tmp_path / f"obj_{width}"
    b = subprocess.run(
        [
            "verilator", "--binary", "--timing", "-Wno-fatal",
            "--top-module", "tb_npu_dma_width", "-Mdir", str(mdir),
            f"-GDMA_DATA_W={width}",
            *[str(p) for p in RTL + TB],
        ],
        capture_output=True,
        text=True,
    )
    binary = mdir / "Vtb_npu_dma_width"
    assert binary.exists(), f"verilator build failed width={width}:\n{b.stdout}\n{b.stderr}"
    out = subprocess.run([str(binary)], cwd=ROOT, capture_output=True, text=True, timeout=120).stdout
    assert f"NPU_DMA_WIDTH_PASS width={width}" in out, out
    return out


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_npu_dma_width_sweep(tmp_path):
    ref_words = 64
    for width in (64, 128, 256):
        out = _run_width(tmp_path, width)
        m = re.search(r"WIDTH_ALIGNED_PASS width=(\d+) arsize=(\d+) rbeats=(\d+) ar_count=(\d+)", out)
        assert m, out
        got_width, arsize, rbeats, ar_count = map(int, m.groups())
        wpb = width // 32
        assert got_width == width
        assert arsize == {64: 3, 128: 4, 256: 5}[width]
        assert rbeats == ref_words // wpb
        assert ar_count == 1
        assert f"WIDTH_ERR_ALIGN_PASS width={width}" in out
        wm = re.search(r"WIDTH_STORE_PASS width=(\d+) awsize=(\d+) wbeats=(\d+) aw_count=(\d+)", out)
        assert wm, out
        got_width, awsize, wbeats, aw_count = map(int, wm.groups())
        assert got_width == width
        assert awsize == {64: 3, 128: 4, 256: 5}[width]
        assert wbeats == ref_words // wpb
        assert aw_count == 1
        assert f"WIDTH_STORE_ERR_ALIGN_PASS width={width}" in out
        if width == 256:
            nm = re.search(
                r"WIDTH_NARROW_PASS width=(\d+) arsize=(\d+) awsize=(\d+) rbeats=(\d+) wbeats=(\d+) wstrb=([0-9a-fA-F]+)",
                out,
            )
            assert nm, out
            n_width, n_arsize, n_awsize, n_rbeats, n_wbeats, n_wstrb = nm.groups()
            assert int(n_width) == 256
            assert int(n_arsize) == 2
            assert int(n_awsize) == 2
            assert int(n_rbeats) == ref_words - 1
            assert int(n_wbeats) == ref_words - 1
            assert int(n_wstrb, 16) == 0x000000F0
            print(
                "NPU_DMA_NARROW width=256 "
                f"arsize={n_arsize} awsize={n_awsize} rbeats={n_rbeats} "
                f"wbeats={n_wbeats} wstrb=0x{int(n_wstrb, 16):08x}"
            )
        print(f"NPU_DMA_WIDTH width={width} arsize={arsize} rbeats={rbeats} awsize={awsize} wbeats={wbeats}")
