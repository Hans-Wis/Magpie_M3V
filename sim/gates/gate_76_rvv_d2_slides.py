"""gate_76_rvv_d2_slides — ADR-0057 Phase-D D2: vector slides.

vslideup / vslidedown (.vx/.vi, off = rs1 unsigned / uimm zero-ext) and vslide1up /
vslide1down (.vx, off=1, inject rs1[SEW-1:0] at the boundary). f6=001110 (up) /
001111 (down); OPIVX/OPIVI = slide, OPMVX = slide1. Barrel-shift datapath: vs2_up =
vs2 << (off*SEW), vs2_dn = vs2 >> (off*SEW) (zero-fill top); per element blend with
vd_old for undisturbed lanes; slidedown zero-fills when i+off>=vlmax; slide1 injects
the scalar at element 0 (up) / vl-1 (down). m1-only. Legality (all Spike-probed,
overriding Grok on both points): vstart!=0 -> illegal for both (NOT honored) via the
global rule; slideup-family (vslideup + vslide1up) vd==vs2 -> illegal (require_noover),
slidedown vd==vs2 legal; masked slide writing v0 illegal.

Authority: phase_22 `make d2` vs Spike --isa=rv32imf_zve32x_zvl128b — all slide forms
x SEW 8/16/32 (golden src[10..17]: slideup2=[.,.,10..15], slidedown2=[12..17,0,0],
slide1up(0x55) inject@0, slide1down inject@vl-1); masked slide; off>=vl edges (slideup
all undisturbed / slidedown all zero); a vslideup-vd==vs2 overlap illegal terminator
both sides trap on.
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
def test_d2_directed_lockstep():
    _run("d2", 90)


def test_d2_corpus_covers_all_slide_forms():
    fw = (PHASE / "firmware_d2.S").read_text()
    for pat, floor in ((r"vslideup\.v[xi]", 3), (r"vslidedown\.v[xi]", 3),
                       (r"vslide1up\.vx", 2), (r"vslide1down\.vx", 2)):
        n = len(re.findall(pat, fw))
        assert n >= floor, f"D2 corpus lost {pat}: {n} < {floor}"
    assert "v0.t" in fw, "D2 must exercise a masked slide"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_prior_vector_green():
    for tgt, bar in (("d1a", 35), ("d1b", 55), ("c5", 90),
                     ("s1", 80), ("pool", 160), ("vrand", 1200)):
        _run(tgt, bar)
