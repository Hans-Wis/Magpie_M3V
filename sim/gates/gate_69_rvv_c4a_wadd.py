"""gate_69_rvv_c4a_wadd — ADR-0056 Phase-C C4a: full widening add/sub.

vwaddu/vwadd/vwsubu/vwsub, .vv/.vx (narrow+narrow) and .wv/.wx (wide vs2 + narrow).
OPMVV/OPMVX f6=110xxx (f6[2]=wide-vs2, f6[1]=subtract, f6[0]=signed). dest 2*SEW =
op_a +/- ext(vs1|rs1); narrows sign-extend if signed else zero-extend; .wv/.wx use
the already-2*SEW vs2 as-is. SEW<=16, fractional LMUL only, vm=1. Generalizes the
existing vwadd.wv (op_waddw) into op_waddsub while preserving vwmul.vv and the Phase-0
kernel accumulate (vwadd.wv with vd==vs2). Overlap (require_noover): vd must not
overlap a narrower source — vs1 narrow vector only in OPMVV forms; vs2 narrow for
.vv/.vx, wide (vd==vs2 legal) for .wv/.wx.

Authority: phase_22 `make c4a` vs Spike --isa=rv32imf_zve32x_zvl128b — all 8 add/sub
x .vv/.vx/.wv/.wx x SEW 8/16 (golden-probed vs2=0xFF vs1=1 -> vwaddu 256 / vwadd 0 /
vwsubu 254 / vwsub -2 / vwaddu.wv 257 / vwsub.wv 255), a vd==vs2-wide legal case, and
a vwaddu.vv-vd==vs2 (narrow overlap) illegal terminator both sides trap on.
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
def test_c4a_directed_lockstep():
    _run("c4a", 130)


def test_c4a_corpus_covers_all_forms():
    fw = (PHASE / "firmware_c4a.S").read_text()
    for pat, floor in ((r"vwaddu\.[vw][vx]", 2), (r"vwadd\.[vw][vx]", 2),
                       (r"vwsubu\.[vw][vx]", 2), (r"vwsub\.[vw][vx]", 2),
                       (r"vwadd\.wv\s+v6,\s*v6,\s*v1", 1)):  # vd==vs2 wide overlap (legal)
        n = len(re.findall(pat, fw))
        assert n >= floor, f"C4a corpus lost {pat}: {n} < {floor}"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_prior_widening_and_vector_green():
    for tgt, bar in (("c2", 130), ("c3", 80), ("vwide", 80),
                     ("pool", 160), ("kernel", 40), ("vrand", 1200)):
        _run(tgt, bar)
