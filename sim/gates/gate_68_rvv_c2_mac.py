"""gate_68_rvv_c2_mac — ADR-0056 Phase-C C2: integer multiply-accumulate.

vmacc (vd+=vs1*vs2), vnmsac (vd-=vs1*vs2), vmadd (vd=vs1*vd+vs2), vnmsub
(vd=vs2-vs1*vd). OPMVV(.vv)/OPMVX(.vx, scalar replaces vs1), f6 101101/101111/
101001/101011 — f3-disjoint from vsra/vnsra/vssra/vnclip. Low SEW bits only
(sign-agnostic). vd is the accumulator: vd_old is read as an operand and vd-overlap
with vs1/vs2 is spec-legal (no generic overlap illegality). Dedicated per-SEW loops
(prod_ab=vs1*vs2, prod_db=vs1*vd), joins beats_op for m2/m4 groups.

Authority: phase_22 `make c2` vs Spike --isa=rv32imf_zve32x_zvl128b — all four MAC
ops x vv/vx x SEW 8/16/32 (golden-probed vd=10,vs1=3,vs2=5 -> 25/-5/35/-25),
explicit vd==vs1 and vd==vs2 overlap cases (must not trap), an e32/m2 group smoke,
and a masked-vmacc-writing-v0 illegal terminator both sides trap on.
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
def test_c2_directed_lockstep():
    _run("c2", 130)


def test_c2_corpus_covers_all_mac_and_overlap():
    fw = (PHASE / "firmware_c2.S").read_text()
    for pat, floor in ((r"vmacc\.v[vx]", 3), (r"vnmsac\.v[vx]", 2),
                       (r"vmadd\.v[vx]", 3), (r"vnmsub\.v[vx]", 2),
                       (r"vmacc\.vv v2, v6, v2", 1),   # vd==vs2 overlap
                       (r"vmadd\.vv v6, v6, v2", 1)):  # vd==vs1 overlap
        n = len(re.findall(pat, fw))
        assert n >= floor, f"C2 corpus lost {pat}: {n} < {floor}"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_prior_vector_targets_still_green():
    for tgt, bar in (("c1", 100), ("c3", 80), ("b3", 160),
                     ("s3", 65), ("pool", 160), ("vrand", 1200)):
        _run(tgt, bar)
