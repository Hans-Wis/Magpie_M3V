"""gate_84_mat_lanes_sku — LANES SKU proof for matrix engine and npu_top integration.

Sweeps the authoritative gate_45 mat_engine golden TB at LANES=1/2/4 using the
same vectors and golden. Also runs the gate_46 CQ-matrix e2e path at
MAT_LANES=1 to prove the non-default SKU is wired through npu_top.
"""

import shutil
import subprocess
from pathlib import Path

import pytest

from gate_20_axi_fabric import CPU_M1_ARGS, verilator_sim  # noqa: E402
from gate_46_cq_matrix_e2e import RTL as CQ_RTL, TB as CQ_TB, _golden_tile  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_23_mat_engine"


def _run_make(args):
    return subprocess.run(["make", "-C", str(PHASE), *args],
                          capture_output=True, text=True, timeout=240)


def _assert_mat_engine_log(lanes):
    log = (PHASE / "sim.log").read_text()
    for token in (
        "MAT_ENGINE_PASS",
        "part1: 90 rescale corners",
        "part2: 24 sequences",
        "part3: 8 per-channel tiles",
        ", 0 errors",
    ):
        assert token in log, f"LANES={lanes}: missing {token!r} in sim.log"


def _read_dump_tile():
    dump = (ROOT / "mat_result.dump").read_text().split()
    got = bytearray()
    for w in dump:
        v = int(w, 16)
        got += bytes([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF])
    return bytes(got)


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_mat_engine_bit_exact_all_lanes():
    for lanes in (1, 2, 4):
        c = _run_make(["clean"])
        assert c.returncode == 0, f"LANES={lanes}: clean failed:\n{c.stdout}\n{c.stderr}"
        r = _run_make([f"LANES={lanes}", "all"])
        assert r.returncode == 0, (
            f"LANES={lanes}: unit TB failed:\n{r.stdout[-4000:]}\n{r.stderr[-2000:]}")
        _assert_mat_engine_log(lanes)


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_cq_matrix_e2e_mat_lanes_1_matches_golden(tmp_path):
    verilator_sim(tmp_path, "tb_npu_cq_mat", CQ_RTL + CQ_TB, "NPU_CQ_MAT_PASS",
                  extra_args=[*CPU_M1_ARGS, "-GMAT_LANES=1"])
    got = _read_dump_tile()
    exp = _golden_tile()
    assert got == exp, f"MAT_LANES=1 matrix tile mismatch:\n got={got.hex()}\n exp={exp.hex()}"
