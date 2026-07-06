"""gate_81_rvv_vcompress — ADR-0060 Phase-E tail: vcompress.vm.

vcompress.vm vd,vs2,vs1 packs active elements of vs2 (mask = bit i of the explicit
vs1 operand, NOT v0; encoding vm=1) into contiguous low vd lanes:
    j=0; for i in [0,vl): if vs1_bit[i]: vd[j++]=vs2[i]
positions [j,vl) and [vl,vlmax) undisturbed. OPMVV f6=010111. m1-only (LMUL>1
auto-illegal via grp_only_illegal); vstart=0 (global); overlap vd==vs2/vs1 illegal.
Combinational running-index scatter (variable-base part-select), unrolled per SEW.

Authority: phase_22 `make ecmp` vs Spike --isa=rv32imf_zve32x_zvl128b — e8 mask 0x4D
-> [10,12,13,16], all-active identity, empty-mask tail-undisturbed (pre-color 0x99),
e16 mask 0x35, e32 mask 0x0A, partial-vl=5 tail-undisturbed, and a vd==vs2 overlap
illegal terminator trapping in both DUT and Spike. The permute/mask-scan regression
stays green.
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
def test_vcompress_directed_lockstep():
    _run("ecmp", 30)


def test_vcompress_corpus_covers_forms():
    fw = (PHASE / "firmware_ecmp.S").read_text()
    for pat in (r"vcompress\.vm v4, v2, v1", r"e16, m1", r"e32, m1",
                r"0x99", r"vcompress\.vm v2, v2, v1"):
        assert re.search(pat, fw), f"vcompress corpus lost {pat}"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_prior_permute_and_vector_green():
    for tgt, bar in (("e3", 65), ("d2", 90), ("f", 150), ("b3", 160),
                     ("pool", 160), ("vrand", 1200)):
        _run(tgt, bar)
