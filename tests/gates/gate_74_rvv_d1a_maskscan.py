"""gate_74_rvv_d1a_maskscan — ADR-0057 Phase-D D1a: mask-scan simple set.

vid.v (vd[i]=i, vector dest), vcpop.m (scalar rd = popcount of active vs2 mask bits),
vfirst.m (scalar rd = first active set index, else -1). OPMVV; vs1 field selects op
(VWXUNARY0 f6=010000: vcpop vs1=10000, vfirst vs1=10001; VMUNARY0 f6=010100: vid
vs1=10001). Maskable (active = vm||v0[i]), m1-only (m2/m4 grp_only_illegal), vstart!=0
illegal (Spike-probed: vcpop TRAPS at vstart!=0 — Grok's "exempt" flag was empirically
wrong). vcpop/vfirst write a scalar GPR (idu.v rd_we extended to opv_scalar_rd =
vmv.x.s|vcpop|vfirst); vid.v writes the VRF; masked vid writing v0 is illegal.

Authority: phase_22 `make d1a` vs Spike --isa=rv32imf_zve32x_zvl128b — vid.v x SEW
8/16/32; vcpop/vfirst unmasked, masked (v0 predicate), and empty-mask (vcpop 0 /
vfirst -1); golden mask {2,3,6} -> vcpop 3 / vfirst 2 / vid [0..7]; masked v0={3,6,7}
-> vcpop 2 / vfirst 3; a vid-at-vstart!=0 illegal terminator both sides trap on.
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
def test_d1a_directed_lockstep():
    _run("d1a", 35)


def test_d1a_corpus_covers_ops():
    fw = (PHASE / "firmware_d1a.S").read_text()
    assert len(re.findall(r"vid\.v", fw)) >= 3, "D1a needs vid.v across SEW"
    assert len(re.findall(r"vcpop\.m", fw)) >= 3, "D1a needs masked+unmasked+empty vcpop"
    assert len(re.findall(r"vfirst\.m", fw)) >= 3, "D1a needs masked+unmasked+empty vfirst"
    assert "v0.t" in fw, "D1a must exercise a masked mask-scan"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_prior_vector_green():
    for tgt, bar in (("c1", 100), ("c5", 90), ("s1", 80),
                     ("kernel", 40), ("pool", 160), ("vrand", 1200)):
        _run(tgt, bar)
