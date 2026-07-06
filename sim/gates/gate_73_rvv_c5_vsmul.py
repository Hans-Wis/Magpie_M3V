"""gate_73_rvv_c5_vsmul — ADR-0056 Phase-C C5: signed saturating rounding fractional
multiply (vsmul).

vsmul.vv/.vx: vd = sat(round((vs2*vs1) >> (SEW-1))) with vxrm rounding (rnu/rne/rdn/
rod). OPIVV/OPIVX f6=100111 — f3-disjoint from vmulh (OPMV*) and vmv<nr>r (OPIVI),
same f6. The only overflow is (-2^(SEW-1))^2 -> +2^(SEW-1), which saturates to +max
and sets vxsat. SEW 8/16/32 (SEW8 Spike-probed legal). Maskable body op, joins
beats_op. The arithmetic shift is kept in a self-determined signed wire (a logical-
shift bug otherwise falsely saturates negative products — the recurring >>>-in-
unsigned-context gotcha, caught by lockstep here).

Authority: phase_22 `make c5` vs Spike --isa=rv32imf_zve32x_zvl128b — vsmul x .vv/.vx
x SEW 8/16/32 across all four vxrm modes over fractional/saturating data (golden-probed
64*64>>7=32, -128*-128->127+vxsat, 64*3>>7 rounds 1->2), vxsat observed via csrr, an
e32/m2 group smoke (observed via m1 stores), and a masked-vsmul-writing-v0 illegal
terminator both sides trap on.
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
def test_c5_directed_lockstep():
    _run("c5", 90)


def test_c5_corpus_covers_forms_and_vxrm():
    fw = (PHASE / "firmware_c5.S").read_text()
    assert len(re.findall(r"vsmul\.v[vx]", fw)) >= 6, "C5 corpus lost vsmul forms"
    for m in range(4):
        assert f"csrw vxrm, {m}" in fw, f"C5 corpus missing vxrm mode {m}"
    assert "csrr t5, vxsat" in fw or "csrr t3, vxsat" in fw, "C5 must observe vxsat"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_prior_phase_c_and_vector_green():
    for tgt, bar in (("c1", 100), ("c2", 130), ("c4a", 130), ("c4c", 120),
                     ("s2", 100), ("vrand", 1200)):
        _run(tgt, bar)
