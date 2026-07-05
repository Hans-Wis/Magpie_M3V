"""gate_75_rvv_d1b_maskprefix — ADR-0057 Phase-D D1b: mask-scan set + prefix.

vmsbf.m / vmsof.m / vmsif.m (mask dest) + viota.m (vector dest). VMUNARY0 f6=010100;
vs1 selects op (vmsbf=00001, vmsof=00010, vmsif=00011, viota=10000). F = first ACTIVE
set bit in vs2 (active = vm||v0[i]) over [0,vl): vmsbf i<F, vmsof i==F, vmsif i<=F;
viota vd[i] = # active set bits in [0,i). Maskable (inactive undisturbed), m1-only
(m2/m4 grp_only_illegal), vstart!=0 illegal. vms* are mask-dest (like compares, vd==v0
legal — Spike-probed); viota is vector-dest (masked-vd0 illegal). One always@* scan
(run/preset over mbits) feeds both the vms mask bits (via the compare mask_dest res_cmp
path) and the viota prefix counts.

Authority: phase_22 `make d1b` vs Spike --isa=rv32imf_zve32x_zvl128b — golden mask
{2,3,6} -> vmsbf 0x03 / vmsif 0x07 / vmsof 0x04 / viota [0,0,0,1,2,2,2,3]; masked
v0={3,6,7} (active-set {3,6}); empty mask (all 0); viota at SEW 8/16/32; a viota-at-
vstart!=0 illegal terminator both sides trap on.
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
def test_d1b_directed_lockstep():
    _run("d1b", 55)


def test_d1b_corpus_covers_ops():
    fw = (PHASE / "firmware_d1b.S").read_text()
    for pat, floor in ((r"vmsbf\.m", 2), (r"vmsif\.m", 2),
                       (r"vmsof\.m", 1), (r"viota\.m", 3)):
        n = len(re.findall(pat, fw))
        assert n >= floor, f"D1b corpus lost {pat}: {n} < {floor}"
    assert "v0.t" in fw, "D1b must exercise masked mask-scan"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_prior_vector_green():
    for tgt, bar in (("d1a", 35), ("b3", 160), ("s1", 80),
                     ("c3", 80), ("pool", 160), ("vrand", 1200)):
        _run(tgt, bar)
