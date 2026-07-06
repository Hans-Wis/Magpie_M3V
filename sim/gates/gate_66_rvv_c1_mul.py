"""gate_66_rvv_c1_mul — ADR-0055 Phase-C C1: same-width integer multiply.

vmul (low SEW), vmulh (signed*signed high SEW), vmulhu (unsigned*unsigned high),
vmulhsu (signed vs2 * unsigned vs1/rs1, high). OPMVV(.vv)/OPMVX(.vx), f6
100101/100111/100100/100110 — f3-disjoint from vsll (OPIVX) and vmv<nr>r (OPIVI).
Dedicated per-SEW loops form the full 2*SEW product (self-determined signed/
unsigned wires to dodge the signed-in-ternary zero-extend trap) then slice low or
high SEW bits. Same-shape body op: joins beats_op for m2/m4 register groups.

Authority: phase_22 `make c1` vs Spike --isa=rv32imf_zve32x_zvl128b — all four
variants x vv/vx x SEW 8/16/32 over a sign boundary matrix (-2^(SEW-1), -1, max+,
mixed; golden-probed -2^31*2 -> mul 0 / mulh,mulhsu -1 / mulhu 1), an e32/m2 group
smoke, and a masked-vmul-writing-v0 illegal terminator both sides trap on.
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
def test_c1_directed_lockstep():
    _run("c1", 100)


def test_c1_corpus_covers_all_variants():
    fw = (PHASE / "firmware_c1.S").read_text()
    for pat, floor in ((r"vmul\.v[vx]", 4), (r"vmulh\.v[vx]", 2),
                       (r"vmulhu\.v[vx]", 2), (r"vmulhsu\.v[vx]", 2),
                       (r"e32, m2", 1)):       # group smoke
        n = len(re.findall(pat, fw))
        assert n >= floor, f"C1 corpus lost {pat}: {n} < {floor}"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_prior_vector_targets_still_green():
    for tgt, bar in (("b3", 160), ("b4", 55), ("s3", 65),
                     ("vmem", 100), ("vrand", 1200)):
        _run(tgt, bar)
