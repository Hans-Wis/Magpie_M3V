"""gate_65_rvv_b4_wholereg — ADR-0055 Phase-B B4: whole-register move vmv<nr>r.v.

vmv1r/2r/4r/8r.v copy nr whole 128-bit registers vd+p <- vs2+p, INDEPENDENT of
vtype (LMUL/SEW/vl): OPIVI f6=100111, vm=1, simm5 (vs1 field) = nr-1, legal
{0,1,3,7} -> nr {1,2,4,8}. Because nr=8 exceeds the 4-part group-staging path,
vmvr runs its own VM_VMVR copy loop (one register/cycle, written in the sole VRF
write block; q_is_grp holds the core, q_vrf_we/q_grp_w=0 so the WB port writes
nothing). Legality (all Spike-probed on this build, overriding Grok's partial-copy
flag): vstart!=0 -> illegal (existing global rule, no carve-out); vill -> illegal;
m8 vtype -> LEGAL (executes, exempt from lmul_m8); bad simm or vd/vs2 not
nr-aligned -> illegal.

Authority: phase_22 `make b4` vs Spike --isa=rv32imf_zve32x_zvl128b — all four nr
verified by vse32+lw per copied register, an over-copy guard (a sentinel in v24
must survive vmv8r), vtype-independence (vmv1r under an m8 vtype), and a misaligned
vmv2r illegal terminator both sides trap on.
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
def test_b4_directed_lockstep():
    _run("b4", 55)


def test_b4_corpus_covers_all_nr():
    fw = (PHASE / "firmware_b4.S").read_text()
    for pat, floor in ((r"vmv1r\.v", 1), (r"vmv2r\.v", 2),   # incl. misaligned terminator
                       (r"vmv4r\.v", 1), (r"vmv8r\.v", 1),
                       (r"e32, m8", 1)):                      # vtype-independence probe
        n = len(re.findall(pat, fw))
        assert n >= floor, f"B4 corpus lost {pat}: {n} < {floor}"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_prior_vector_targets_still_green():
    for tgt, bar in (("b1", 115), ("b2", 85), ("b3", 160),
                     ("s3", 65), ("vmem", 100), ("vrand", 1200)):
        _run(tgt, bar)
