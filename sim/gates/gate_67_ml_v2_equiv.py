"""gate_67_ml_v2_equiv — mat_engine v2 Phase A hardware tile sequencer equivalence."""

import re
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "sim/tools"))
from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_RTL  # noqa: E402
import ml_v2_gemm_case  # noqa: E402

RTL = [ROOT / f"design/npu/rtl/{m}.v" for m in
       ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine", "npu_ml_ctrl")]
RTL += CPU_M1_RTL
TB = [ROOT / "design/npu/dv/tb/axi_full_rwmem.v", ROOT / "design/npu/dv/tb/tb_ml_v2_gemm.v"]
CASE = ROOT / "sim/work/ml_v2_gemm"
FWDIR = ROOT / "design/npu/sw/ml_job_driver"


def _build_firmware(n_tiles: int, ml_cfg: int = 0) -> str:
    subprocess.run(["make", "clean"], cwd=FWDIR, check=True, capture_output=True, text=True)
    r = subprocess.run(["make", f"N_TILES={n_tiles}", f"ML_CFG={ml_cfg}", "all", "size"],
                       cwd=FWDIR, capture_output=True, text=True)
    assert r.returncode == 0, f"ml_job_driver build failed:\n{r.stdout}\n{r.stderr}"
    return r.stdout + r.stderr


def _run_verilator(tmp_path: Path) -> str:
    mdir = tmp_path / "obj"
    b = subprocess.run(["verilator", "--binary", "--timing", "-Wno-fatal",
                        "--top-module", "tb_ml_v2_gemm", "-Mdir", str(mdir),
                        *CPU_M1_ARGS, *[str(p) for p in RTL + TB]],
                       capture_output=True, text=True)
    binary = mdir / "Vtb_ml_v2_gemm"
    assert binary.exists(), f"verilator build failed:\n{b.stdout}\n{b.stderr}"
    out = subprocess.run([str(binary)], cwd=ROOT, capture_output=True,
                         text=True, timeout=240).stdout
    assert "ML_V2_GEMM_PASS" in out, out
    assert "0 errors" in out, out
    return out


def _dump_bytes(path: Path) -> bytes:
    got = bytearray()
    for w in path.read_text().split():
        v = int(w, 16)
        got += bytes([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF])
    return bytes(got)


def _first_mismatch(got: bytes, exp: bytes) -> str:
    for i, (g, e) in enumerate(zip(got, exp)):
        if g != e:
            tile = i // 64
            off = i % 64
            row = off // 8
            col = off % 8
            base = tile * 64
            return (
                f"tile={tile} row={row} col={col} byte={i} got=0x{g:02x} exp=0x{e:02x}\n"
                f"got_tile={got[base:base + 64].hex()}\n"
                f"exp_tile={exp[base:base + 64].hex()}"
            )
    return f"length mismatch got={len(got)} exp={len(exp)}"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_ml_v2_gemm_matches_firmware_golden(tmp_path):
    _ng, n_tiles = ml_v2_gemm_case.generate(CASE, n=64)
    build_log = _build_firmware(n_tiles)
    assert (FWDIR / "ml_job_driver.hex").exists(), build_log

    out = _run_verilator(tmp_path)
    got = _dump_bytes(CASE / "result.dump")
    exp = (CASE / "ml_v2_golden.bin").read_bytes()
    assert got == exp, "ML_V2 byte mismatch:\n" + _first_mismatch(got, exp)

    m = re.search(r"ML_V2_CYCLES=(\d+)", out)
    assert m, out
    print(f"ML_V2_CYCLES={m.group(1)}")
    bd = re.search(r"ML_V2_BREAKDOWN mat_busy=(\d+) dma_busy=(\d+) other=(\d+)", out)
    if bd:
        print(f"ML_V2_BREAKDOWN mat={bd.group(1)} dma={bd.group(2)} other={bd.group(3)}")
    print(f"ML_V2_BIT_EXACT_PASS n_tiles={n_tiles} bytes={len(exp)}")


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_ml_v2_gemm_b1_activation_stationary(tmp_path):
    """ADR-0067 Phase B B1: same q_proj GEMM with activation loaded ONCE (stationary).
    Bit-exact vs the same golden; DMA must drop (~896 fewer redundant activation words)."""
    _ng, n_tiles = ml_v2_gemm_case.generate(CASE, n=64, stationary=True)
    build_log = _build_firmware(n_tiles, ml_cfg=2)   # ML_JOB_CFG[1] = stationary
    assert (FWDIR / "ml_job_driver.hex").exists(), build_log

    out = _run_verilator(tmp_path)
    got = _dump_bytes(CASE / "result.dump")
    exp = (CASE / "ml_v2_golden.bin").read_bytes()
    assert got == exp, "B1 byte mismatch:\n" + _first_mismatch(got, exp)

    cyc = int(re.search(r"ML_V2_CYCLES=(\d+)", out).group(1))
    bd = re.search(r"ML_V2_BREAKDOWN mat_busy=(\d+) dma_busy=(\d+) other=(\d+)", out)
    dma = int(bd.group(2))
    # activation-stationary must actually cut DMA (Phase A dma was ~3,408); guard the
    # win so a "load anyway" regression can't pass silently.
    assert dma < 3000, f"B1 dma={dma} did not drop vs Phase A ~3,408 (activation not stationary?)"
    print(f"ML_V2_B1_CYCLES={cyc} mat={bd.group(1)} dma={dma} other={bd.group(3)}")
    print(f"ML_V2_B1_BIT_EXACT_PASS n_tiles={n_tiles} bytes={len(exp)}")
