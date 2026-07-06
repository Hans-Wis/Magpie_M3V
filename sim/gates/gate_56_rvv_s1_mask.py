"""gate_56_rvv_s1_mask — ADR-0049 S1: mask execution, mask-dest ops, min/max.

New vexu subset (Spike-arbitrated, per-commit lockstep + P0-4 checkpoints):
masked arithmetic (vm=0, masked-off = undisturbed), the 8 mask logicals
(vmand/vmnand/vmandn/vmxor/vmor/vmnor/vmorn/vmxnor), integer compares to a
mask destination (vmseq/vmsne/vmslt[u]/vmsle[u]/vmsgt[u] with per-form
legality), and vmin[u]/vmax[u] (the max-pool primitive).

Authority: phase_22 lockstep — `make s1` (directed corners: vl in {0,1,VLMAX},
all-0/all-1 masks, signed edges, mask-dest tail at vl=1) and `make vrand`
(random corpus now interleaves compare -> logical -> masked-arith -> min/max
against Spike; op presence in the generated corpus is ASSERTED so the pool
can never silently shrink). Prior targets (grid/vill/valu/vmem) re-green.
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
def test_s1_directed_corners():
    _run("s1", 80)


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_s1_random_corpus():
    _run("vrand", 1000)
    fw = (PHASE / "firmware_vrand.S").read_text()
    for pat, floor in ((r"vmseq|vmsne|vmslt|vmsle|vmsgt", 30),
                      (r"vmand|vmor|vmxor|vmnand|vmnor|vmxnor|vmandn|vmorn", 10),
                      (r"vmax|vmin", 30),
                      (r"v0\.t", 20)):
        n = len(re.findall(pat, fw))
        assert n >= floor, f"corpus lost {pat}: {n} < {floor} (green-wash guard)"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_prior_vector_targets_still_green():
    for tgt, bar in (("valu", 60), ("vmem", 100), ("grid", 140), ("vill", 40)):
        _run(tgt, bar)
