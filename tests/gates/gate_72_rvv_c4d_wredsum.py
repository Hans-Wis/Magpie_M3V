"""gate_72_rvv_c4d_wredsum — ADR-0056 Phase-C C4d: widening sum reduction.

vwredsum.vs (sext), vwredsumu.vs (zext) -> vd[0] (2*SEW) = ext(vs1[0]) + sum of
ext(vs2[0..vl-1]). OPIVV (NOT OPMVV) f6=110000/110001 — disjoint from the OPMVV
vwaddu/vwadd (C4a) by f3. vs1[0] is already 2*SEW (seeded at the wide vtype). A
dedicated 32-bit accumulator sign/zero-extends vs2 elements per op and commits
wred_acc[2*SEW-1:0]. m1/fractional-LMUL (group reductions stay grp_only_illegal),
SEW<=16 (SEW32 -> wred_illegal), vm=1 (masked deferred). vstart!=0 -> illegal (global).

Authority: phase_22 `make c4d` vs Spike --isa=rv32imf_zve32x_zvl128b — vwredsum/
vwredsumu x SEW 8/16 over signed/unsigned boundary data (so vwredsum != vwredsumu;
golden-probed seed=3 vs2={5,-1,127,-128} -> vwredsum 6 / vwredsumu 518), and a
vwredsum-at-vstart!=0 illegal terminator both sides trap on.
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
def test_c4d_directed_lockstep():
    _run("c4d", 30)


def test_c4d_corpus_covers_both_and_signedness():
    fw = (PHASE / "firmware_c4d.S").read_text()
    for pat, floor in ((r"vwredsum\.vs", 2), (r"vwredsumu\.vs", 2)):
        n = len(re.findall(pat, fw))
        assert n >= floor, f"C4d corpus lost {pat}: {n} < {floor}"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_prior_widening_and_vector_green():
    for tgt, bar in (("c4a", 130), ("c4b", 90), ("c4c", 120),
                     ("c3", 80), ("vwide", 80), ("vrand", 1200)):
        _run(tgt, bar)
