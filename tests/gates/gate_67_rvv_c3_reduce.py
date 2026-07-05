"""gate_67_rvv_c3_reduce — ADR-0056 Phase-C C3: non-sum reductions.

vred{sum,and,or,xor,minu,min,maxu,max}.vs — vd[0] = vs1[0] OP reduce(vs2[0..vl-1]).
Generalizes the original vredsum into op_red (OPMVV f6=000xxx; f6[2:0] selects the
combine). Unmasked (vm=1) and m1-only, matching the original vredsum scope (masked /
group reductions stay deferred-illegal — the DUT is intentionally more restrictive
there, so those cases are NOT exercised against Spike). min/max sign-extend seed +
elements to 32b for a signed compare; minu/maxu and sum/and/or/xor zero-extend; only
red_acc[SEW-1:0] commits. vstart!=0 -> illegal (global rule, Spike-confirmed).

Authority: phase_22 `make c3` vs Spike --isa=rv32imf_zve32x_zvl128b — all eight
reductions x SEW 8/16/32 over signed/unsigned boundary data (so minu!=min and
maxu!=max), seed via vmv.s.x, and a vredsum-at-vstart!=0 illegal terminator both
sides trap on.
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
def test_c3_directed_lockstep():
    _run("c3", 80)


def test_c3_corpus_covers_all_reductions():
    fw = (PHASE / "firmware_c3.S").read_text()
    for pat, floor in ((r"vredsum\.vs", 3), (r"vredand\.vs", 3), (r"vredor\.vs", 3),
                       (r"vredxor\.vs", 3), (r"vredminu\.vs", 3), (r"vredmin\.vs", 3),
                       (r"vredmaxu\.vs", 3), (r"vredmax\.vs", 3)):
        n = len(re.findall(pat, fw))
        assert n >= floor, f"C3 corpus lost {pat}: {n} < {floor}"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_prior_vector_targets_still_green():
    for tgt, bar in (("c1", 100), ("b3", 160), ("s3", 65),
                     ("pool", 160), ("vrand", 1200)):
        _run(tgt, bar)
