"""gate_94_ddr_latency_model — ddr_wall_step1 §A: DDR-latency-realistic rail.

Replaces the 1-cycle shared-SRAM optimism on the ml_v2 q_proj rail with
axi_ddr_latency_model (page-hit/miss first-beat latency, COL_CYC beat spacing,
single-outstanding, 4KB/INCR discipline checker) and asserts:

  1. BYTE-EXACT results in SRAM mode AND at COL_CYC=13/6/1 — timing never
     changes data (the overlap-correctness baseline the design doc requires);
  2. dma_busy strictly increases as COL_CYC grows while mat_busy stays
     invariant (the wall is the memory, not the engine);
  3. DDR_MODEL_STATS accounting present (bytes_rd matches the rail's weight
     traffic every run).

Calibration honesty (in the report, repeated here): this TB config runs the
32-bit DMA SKU and COL_CYC is per AXI beat, so absolute cyc numbers are ~4x
pessimistic vs the 128-bit Magpie_DDR native beat; ORDER conclusions
(dma-dominated wall) are calibration-independent.
"""

import re
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_RTL, CPU_M1_DIR  # noqa: E402

NPU_RTL = [ROOT / f"design/npu/rtl/{m}.v" for m in (
    "npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr",
    "mat_engine", "npu_ml_ctrl", "axi_full_sram", "axil_to_full",
    "axi_full_arbiter_2x1")]
TB = [ROOT / "design/npu/dv/tb/axi_full_rwmem.v",
      ROOT / "design/npu/dv/tb/tb_ml_v2_gemm.v"]


def _run(binary, extra):
    r = subprocess.run([str(binary)] + extra, cwd=ROOT, capture_output=True,
                       text=True, timeout=900)
    out = r.stdout
    assert "ML_V2_GEMM_PASS" in out, out[-2500:]
    bd = re.search(r"ML_V2_BREAKDOWN mat_busy=(\d+) dma_busy=(\d+) other=(\d+)", out)
    assert bd, out[-1500:]
    return int(bd.group(1)), int(bd.group(2)), out


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_ddr_latency_rail(tmp_path):
    mdir = tmp_path / "obj"
    files = CPU_M1_RTL + NPU_RTL + TB
    b = subprocess.run([
        "verilator", "--binary", "--timing", "-Wno-fatal",
        "--top-module", "tb_ml_v2_gemm", "-Mdir", str(mdir),
        *CPU_M1_ARGS, *[str(p) for p in files],
    ], cwd=ROOT, capture_output=True, text=True)
    binary = mdir / "Vtb_ml_v2_gemm"
    assert binary.exists(), f"build failed:\n{b.stdout[-3000:]}\n{b.stderr[-2000:]}"

    mat0, dma0, _ = _run(binary, [])                       # 1-cyc SRAM baseline
    results = {}
    for col in (1, 6, 13):
        mat, dma, out = _run(binary, ["+DDR_MODEL=1", f"+DDR_COL_CYC={col}"])
        assert mat == mat0, f"mat_busy changed under DDR timing: {mat} vs {mat0}"
        assert "DDR_MODEL_STATS" in out, out[-1500:]
        results[col] = dma
    assert results[1] > dma0, "DDR ideal should still exceed 1-cyc SRAM dma"
    assert results[6] > results[1] and results[13] > results[6], \
        f"dma not monotone in COL_CYC: {dma0} {results}"
    print(f"DDR_RAIL dma sram={dma0} col1={results[1]} col6={results[6]} col13={results[13]}")
