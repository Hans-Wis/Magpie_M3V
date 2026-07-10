"""gate_95_realsize_compute — ddr_wall_step1 §B: H=640-class kernel microbench.

Runs flow/v2_pipeline/phase_24_realsize_perf (NPU-config core, 1-cycle
bench memory == TCM timing class; kernels are verbatim copies of the shipped
cq_sequencer handlers — provenance in perf_h640.c header) and asserts every
expected PERF line is present with a plausible cycle count. The numbers feed
docs/reports/2026-07-10_ddr_wall_realsize_baseline.md; this gate keeps the
measurement reproducible, it does NOT enforce specific values (perf gate,
not a golden gate — honest split per the design doc).
"""

import re
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_24_realsize_perf"

EXPECT = [
    ("rmsnorm_rvv", 640), ("rmsnorm_rvv", 160),
    ("ewise_mul_scalar", 2048), ("ewise_mul_scalar", 640),
    ("ewise_add_rvv", 640), ("rope_scalar", 160),
    ("softmax_scalar", 4), ("softmax_scalar", 64), ("softmax_scalar", 256),
]


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_realsize_microbench():
    subprocess.run(["make", "clean"], cwd=PHASE, capture_output=True, text=True)
    r = subprocess.run(["make"], cwd=PHASE, capture_output=True, text=True, timeout=1800)
    assert r.returncode == 0, f"microbench failed:\n{r.stdout[-3000:]}\n{r.stderr[-2000:]}"
    out = r.stdout
    assert "REALSIZE PERF DONE" in out, out[-2000:]
    got = {(m.group(1), int(m.group(2))): int(m.group(3))
           for m in re.finditer(r"PERF (\S+) size=(\d+) cyc=(\d+)", out)}
    for key in EXPECT:
        assert key in got, f"missing PERF line {key}: have {sorted(got)}"
        assert 0 < got[key] < 10_000_000, f"implausible cycles {key}={got[key]}"
    print("REALSIZE " + " ".join(f"{k[0]}@{k[1]}={v}" for k, v in sorted(got.items())))
