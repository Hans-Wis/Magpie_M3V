"""gate_62_rvv_b1_intcore — ADR-0055 Phase-B B1: integer-core completeness.

Adds the basic Zve32x integer ALU ops the TFLM subset lacked: bitwise
(vand/vor/vxor), shift (vsll/vsrl/vsra), and reverse-subtract (vrsub) — all
across vv/vx/vi forms, SEW e8/e16/e32, LMUL m1 + m2 (the beat path). These join
the existing per-SEW datapath mux and beats_op set, reusing the verified m2/m4
group machinery.

Authority: phase_22 lockstep `make b1` vs Spike --isa=zve32x_zvl128b (directed:
every form x SEW, shift amounts including >= SEW truncation to log2(SEW) bits,
vsra sign edges, vrsub with scalar/immediate; results read back via vse+lw per
element and vmv.x.s at m2). The vsra bug this caught: an unsigned ternary
context turns `>>>` into a LOGICAL shift — fixed with a self-determined signed
intermediate wire (a recurring Verilog gotcha). Build uses -mno-relax so `la`/
data-table addresses encode PC-relative-identically in the DUT (base 0x0) and
Spike (base 0x8000_0000) images.
"""

import re
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_22_vector_csr_lockstep"


def _run(target, min_commits):
    r = subprocess.run(["make", "-C", str(PHASE), target],
                       capture_output=True, text=True)
    assert r.returncode == 0, f"{target} failed:\n{r.stdout[-3000:]}"
    m = re.search(r"PASS: vcsr-lockstep matched (\d+) commits", r.stdout)
    assert m and int(m.group(1)) >= min_commits, r.stdout[-1500:]


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_b1_directed_lockstep():
    _run("b1", 110)


def test_b1_corpus_covers_all_ops():
    # green-wash guard: the directed firmware must exercise every B1 op across
    # forms, so the pool can't silently shrink
    fw = (PHASE / "firmware_b1.S").read_text()
    for pat, floor in ((r"vand\.", 3), (r"vor\.", 2), (r"vxor\.", 3),
                       (r"vsll\.", 3), (r"vsrl\.", 2), (r"vsra\.", 3),
                       (r"vrsub\.", 3)):
        n = len(re.findall(pat, fw))
        assert n >= floor, f"B1 corpus lost {pat}: {n} < {floor}"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_prior_vector_targets_still_green():
    for tgt, bar in (("grid", 140), ("s1", 80), ("s3", 70), ("vrand", 1200)):
        _run(tgt, bar)
