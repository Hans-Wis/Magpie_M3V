"""gate_63_rvv_b2_narrow_ext — ADR-0055 Phase-B B2: narrowing shift + extension.

B2a narrowing shift (vnsrl/vnsra, .wv/.wx/.wi): wide 2*SEW source >> shamt -> SEW
dest low bits, reusing the vnclip wide datapath minus round/clip. Only SEW8 (src
e16) and SEW16 (src e32) — SEW32 narrowing needs a 64-bit source, absent in
Zve32x. shamt masked to log2(2*SEW) bits; vnsra arithmetic via a self-determined
signed wire, its sign edges observable at shamt >= log2(2*SEW)/... where the fill
reaches the low SEW bits. B2b extension (vzext/vsext.vf2/vf4, OPMVV f6=010010,
gated on f3 so disjoint from OPIVV vsbc): SEW/2 or SEW/4 low-lane source -> SEW
zero/sign extended; vf2 needs SEW>=16, vf4 needs SEW32, vf8 illegal (no e64).

Both are body ops carrying the masked-vd==v0 illegality (proactively added after
the B1 3-way review caught that gap). Authority: phase_22 `make b2` vs Spike
--isa=zve32x_zvl128b (fractional-LMUL narrowing configs, EEW-override wide loads,
sign/zero extension of negative sources, masked-vd0 illegal terminator).
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
def test_b2_directed_lockstep():
    _run("b2", 85)


def test_b2_corpus_covers_narrow_and_ext():
    fw = (PHASE / "firmware_b2.S").read_text()
    for pat, floor in ((r"vnsrl\.", 3), (r"vnsra\.", 3),
                       (r"vzext\.vf2", 1), (r"vsext\.vf2", 2),
                       (r"vzext\.vf4", 1), (r"vsext\.vf4", 1)):
        n = len(re.findall(pat, fw))
        assert n >= floor, f"B2 corpus lost {pat}: {n} < {floor}"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_prior_vector_targets_still_green():
    for tgt, bar in (("b1", 115), ("grid", 140), ("s2", 100), ("vrand", 1200)):
        _run(tgt, bar)
