"""gate_57_rvv_s2_sat — ADR-0049 S2: saturating / averaging / scaling ops.

vexu grows vsadd[u]/vssub[u] (vxsat), vaadd[u]/vasub[u] (vxrm rounding),
vssrl/vssra (scaling shifts), vnclip[u] (narrowing clip, fractional-LMUL
rule mirrors widening). vxsat commits at WB with the vector-write kill rules;
vxrm reaches EX as an EFFECTIVE value (MEM+WB csr-write windows — the 3A
alias-group lesson applied to a new consumer); pending saturation overlays
ID-stage reads of vxsat/vcsr in age order.

Authority: phase_22 lockstep — s2 directed (102 commits: INT8 boundaries,
csrr-vxsat straight after the sat op, csrw-vxrm straight before vaadd, all
four rounding modes on odd sums, masked-off must NOT set vxsat, vnclip clip
edges under mf2, vl=0 no-effect, vcsr clear path) and the random corpus with
vxrm churn + sticky/clear probes. Bring-up caught: vaadd took bits [8:2]
(shift by 2) and OPMVV operand-b fell through to the scalar path.
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
def test_s2_directed_corners():
    _run("s2", 100)


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_s2_random_corpus_with_vxrm_churn():
    _run("vrand", 1300)
    fw = (PHASE / "firmware_vrand.S").read_text()
    for pat, floor in ((r"vsadd|vssub", 20), (r"vaadd|vasub", 8),
                      (r"vssrl|vssra", 10), (r"csrw vxrm", 30),
                      (r"csrr t4, vxsat", 30)):
        n = len(re.findall(pat, fw))
        assert n >= floor, f"corpus lost {pat}: {n} < {floor}"
