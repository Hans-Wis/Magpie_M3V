"""gate_77_rvv_e1_vdiv — ADR-0058 Phase-E E1: integer divide / remainder.

vdivu / vdiv / vremu / vrem, OPMVV(.vv)/OPMVX(.vx), f6 100000/100001/100010/100011
(f3-disjoint from vsaddu/vsadd/vssubu/vssub OPIV*, same f6). vd = vs2 op vs1(/rs1).
RISC-V special cases (Spike-probed): unsigned /0 -> all-1s, %0 -> dividend; signed
/0 -> -1, %0 -> dividend; signed overflow MIN/-1 -> quotient MIN, rem 0; signed
division truncates toward zero. Combinational per-element divide (functional lockstep;
real HW would sequence it -- documented timing deviation, same class as fexu F4).
Maskable, joins beats_op for m2/m4 groups.

Authority: phase_22 `make e1` vs Spike --isa=rv32imf_zve32x_zvl128b — all four ops x
.vv/.vx x SEW 8/16/32 over data hitting every special case (a=20,b=3 -> 6 r2; a/0 ->
all-1s / -1; a%0 -> a; MIN/-1 -> MIN,0; -20/3 -> -6 r-2), an e32/m2 group smoke, and a
masked-vdiv-writing-v0 illegal terminator both sides trap on.
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
def test_e1_directed_lockstep():
    _run("e1", 85)


def test_e1_corpus_covers_all_ops_and_specials():
    fw = (PHASE / "firmware_e1.S").read_text()
    for pat, floor in ((r"vdivu\.v[vx]", 2), (r"vdiv\.v[vx]", 2),
                       (r"vremu\.v[vx]", 1), (r"vrem\.v[vx]", 2)):
        n = len(re.findall(pat, fw))
        assert n >= floor, f"E1 corpus lost {pat}: {n} < {floor}"
    # data must contain a zero divisor and the signed MIN dividend
    assert re.search(r"pb8:.*\b0\b", fw) and "0x80" in fw, "E1 needs div0 + MIN special cases"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_prior_vector_green():
    for tgt, bar in (("c1", 100), ("c2", 130), ("d2", 90),
                     ("s2", 100), ("pool", 160), ("vrand", 1200)):
        _run(tgt, bar)
