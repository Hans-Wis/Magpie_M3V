"""gate_70_rvv_c4b_wmul — ADR-0056 Phase-C C4b: widening multiply.

vwmul (signed*signed), vwmulu (unsigned*unsigned), vwmulsu (signed vs2 * unsigned
vs1/rs1) -> full 2*SEW product. OPMVV/OPMVX f6=111011/111000/111010. Extends the
Phase-0 vwmul.vv to OPMVX and adds the u/su variants; shares the g_w8/g_w16 widening
loops with C4a add/sub (r = op_wmulany?prod:ws_res). SEW<=16, fractional LMUL, vm=1.
Overlap: vs2 is narrow so vd==vs2 illegal; vd==vs1 illegal for OPMVV forms.

Authority: phase_22 `make c4b` vs Spike --isa=rv32imf_zve32x_zvl128b — vwmul/vwmulu/
vwmulsu x .vv/.vx x SEW 8/16 over sign boundary data (golden-probed vs2=-128 vs1=255
-> vwmul 128 / vwmulu 32640 / vwmulsu -32640), and a vwmulu.vv-vd==vs2 narrow-overlap
illegal terminator both sides trap on. Regression keeps the vwmul.vv Phase-0 kernel
path (kernel/pool/vwide) green.
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
def test_c4b_directed_lockstep():
    _run("c4b", 90)


def test_c4b_corpus_covers_all_variants():
    fw = (PHASE / "firmware_c4b.S").read_text()
    for pat, floor in ((r"vwmul\.v[vx]", 2), (r"vwmulu\.v[vx]", 2),
                       (r"vwmulsu\.v[vx]", 2)):
        n = len(re.findall(pat, fw))
        assert n >= floor, f"C4b corpus lost {pat}: {n} < {floor}"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_prior_widening_and_vector_green():
    for tgt, bar in (("c4a", 130), ("c2", 130), ("vwide", 80),
                     ("pool", 160), ("kernel", 40), ("vrand", 1200)):
        _run(tgt, bar)
