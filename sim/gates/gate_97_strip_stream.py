"""gate_97_strip_stream — ADR-0073: strip-streaming functional authority.

The strip case (K=128 => 2 K-chunks w/ in-strip ACC accumulation (A.2),
N=128 => 2 strips exercising PREFILL -> compute||prefetch -> rendezvous bank
swap) runs on tb_ml_v2_gemm +STRIP_CASE=1 in FOUR timing environments:

  1-cycle SRAM / DDR COL_CYC=3 (G2-cal) / DDR COL_CYC=13 (G1-cal) /
  DDR COL_CYC=3 + pseudo-random per-beat stalls (+STALL_INJECT)

and every run's result.dump must equal THIS GATE'S OWN golden — NumPy matmul
over the raw int8 sidecars + the established mat_golden.rescale per-channel
chain (gate_45 authority; fold=0 in this case). Timing must never change data
(rendezvous/bank-ownership correctness), which is asserted by construction
across the four runs.

Performance is a SEPARATE test (ADR green-wash split): at G2-cal the strip
prefetch chain must deliver >= 4.0 effective B/cyc on the weight stream
(computed from DDR_MODEL_STATS bytes_rd / busy_cycles).
"""

import re
import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np
import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "sim/tools"))
sys.path.insert(0, str(ROOT / "design/npu/golden"))
from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_RTL  # noqa: E402
import ml_strip_case as case  # noqa: E402
import mat_golden  # noqa: E402

RTL = [ROOT / f"design/npu/rtl/{m}.v" for m in (
    "npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr",
    "mat_engine", "npu_ml_ctrl", "npu_strip_buf")]
RTL += CPU_M1_RTL
TB = [ROOT / "design/npu/dv/tb/axi_full_rwmem.v",
      ROOT / "design/npu/dv/tb/tb_ml_v2_gemm.v"]
WORK = ROOT / "sim/work/ml_strip_gemm"
FWDIR = ROOT / "design/npu/sw/ml_job_driver"


def _prepare():
    r = subprocess.run(["python3", str(ROOT / "sim/tools/ml_strip_case.py")],
                       cwd=ROOT, capture_output=True, text=True)
    assert r.returncode == 0, r.stdout + r.stderr
    subprocess.run(["make", "clean"], cwd=FWDIR, capture_output=True, text=True)
    b = subprocess.run(["make", "ml_job_driver_strip.hex",
                        f"W_BASE={case.W_BASE_DEFAULT}",
                        f"STRIP_BYTES={case.STRIP_BYTES}",
                        f"N_STRIPS={case.N_STRIPS}",
                        f"K_CHUNKS={case.K_CHUNKS}", f"K_TAIL={case.K_TAIL}",
                        f"N_TAIL={case.N_TAIL}"],
                       cwd=FWDIR, capture_output=True, text=True)
    assert b.returncode == 0, b.stdout + b.stderr


def _golden() -> bytes:
    """Full 8x128 GEMM golden in the frozen sub-tile block layout:
    block (s,t) = output rows 0..7 x strip-s columns t*8..t*8+7, row-major,
    at byte offset (s*8+t)*64 (matches Phase-A per-tile STORE blocks)."""
    rows = np.load(WORK / "ml_strip_act_rows_int8.npy").astype(np.int64)      # [8,K]
    wf = np.load(WORK / "ml_strip_weights_full_int8.npy").astype(np.int64)    # [128,K]
    scales = case.make_weight_scales(wf.shape[0])
    import tflm_runtime as rt
    acc = rows @ wf.T                                                         # [8,128]
    out = bytearray(8 * 128)
    for s in range(case.N_STRIPS):
        for tt in range(8):
            for r in range(8):
                for cc in range(8):
                    gcol = s * 64 + tt * 8 + cc
                    m, sh = rt.quantize_multiplier(0.023 * float(scales[gcol]) / 0.097)
                    v = mat_golden.rescale(int(acc[r, gcol]), m, 31 - sh,
                                           0, -128, 127) & 0xFF
                    out[(s * 8 + tt) * 64 + r * 8 + cc] = v
    return bytes(out)


def _build(tmp_path, width=None):
    tag = f"obj_w{width}" if width else "obj"
    mdir = tmp_path / tag
    extra = ["-GDMA_DATA_W=%d" % width, "-GMAT_LANES=%d" % (width // 64)] if width else []
    b = subprocess.run(["verilator", "--binary", "--timing", "-Wno-fatal",
                        "--top-module", "tb_ml_v2_gemm", "-Mdir", str(mdir),
                        *extra, *CPU_M1_ARGS, *[str(p) for p in RTL + TB]],
                       cwd=ROOT, capture_output=True, text=True)
    binary = mdir / "Vtb_ml_v2_gemm"
    assert binary.exists(), f"build failed:\n{b.stdout[-3000:]}\n{b.stderr[-2000:]}"
    return binary


def _run(binary, extra):
    r = subprocess.run([str(binary), "+STRIP_CASE=1"] + extra,
                       cwd=ROOT, capture_output=True, text=True, timeout=600)
    assert "STRIP" in r.stdout or "DONE" in r.stdout or r.returncode == 0, r.stdout[-2000:]
    dump = bytearray()
    for wd in (WORK / "result.dump").read_text().split():
        v = int(wd, 16)
        dump += bytes([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF])
    return bytes(dump), r.stdout


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_strip_bit_exact_all_timings(tmp_path):
    _prepare()
    golden = _golden()
    binary = _build(tmp_path)
    for name, extra in [
        ("sram", []),
        ("ddr_g2", ["+DDR_MODEL=1", "+DDR_COL_CYC=3"]),
        ("ddr_g1", ["+DDR_MODEL=1", "+DDR_COL_CYC=13"]),
        ("ddr_g2_stall", ["+DDR_MODEL=1", "+DDR_COL_CYC=3", "+STALL_INJECT=0xBEEF"]),
    ]:
        got, out = _run(binary, extra)
        assert got[:len(golden)] == golden, \
            f"strip result != gate golden under '{name}':\n{out[-1200:]}"
    # width sweep: 128b SKU must produce the same bytes (timing/width-independent)
    b128 = _build(tmp_path, width=128)
    got, out = _run(b128, ["+DDR_MODEL=1", "+DDR_COL_CYC=3"])
    assert got[:len(golden)] == golden, f"128b SKU mismatch:\n{out[-1200:]}"
    print(f"STRIP_BIT_EXACT_PASS bytes={len(golden)} timings=5")


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_strip_bw_perf(tmp_path):
    _prepare()
    # perf target is the 128b native-beat SKU at G2 calibration (ADR-0073 §5);
    # the default 32b SKU caps at 4B/COL_CYC=1.33 B/cyc by construction.
    binary = _build(tmp_path, width=128)
    _, out = _run(binary, ["+DDR_MODEL=1", "+DDR_COL_CYC=3"])
    m = re.search(r"DDR_MODEL_STATS bytes_rd=(\d+) bytes_wr=\d+ busy_cycles=(\d+)", out)
    assert m, out[-1500:]
    bpc = int(m.group(1)) / int(m.group(2))
    print(f"STRIP_BW_G2 {bpc:.2f} B/cyc")
    assert bpc >= 4.0, f"strip stream only {bpc:.2f} B/cyc at G2-cal (target >=4.0)"
