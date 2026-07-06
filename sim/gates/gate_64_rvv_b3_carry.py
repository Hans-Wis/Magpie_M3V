"""gate_64_rvv_b3_carry — ADR-0055 Phase-B B3: carry/borrow vadc/vsbc/vmadc/vmsbc.

vadc/vsbc write a vector vd = vs2 +/- (vs1/rs1/imm) +/- carry(v0[i]); v0 is the
carry OPERAND (not a predicate), so the body is force-active (like vmerge), vm=1
is illegal, and vd==0 is illegal (dest would overlap the carry operand v0). vsbc
has no OPIVI form. vmadc/vmsbc write a MASK vd = unsigned carry/borrow-OUT bit:
with vm=0 the carry-in is v0[i] (.v*m forms), with vm=1 there is no carry-in
(.vv/.vx/.vi) and vd==v0 is then legal. vmadc bit = carry-out of (a+b+cin);
vmsbc bit = borrow = (a < b+bin), unsigned wide compare (NOT signed underflow).
The mask path reuses the compare mask-write datapath via the unified mask_dest =
op_cmp||op_madcb predicate (res_cmp/grp_mask_acc/grp_cmp_res), so m2/m4 groups
accumulate with zero new FSM; vadc/vsbc join beats_op for group multi-beat.

Authority: phase_22 `make b3` vs Spike --isa=rv32imf_zve32x_zvl128b — e8/e16/e32
m1 all forms + carry/borrow boundaries (a+b+cin=2^SEW, a<b+bin) + vmadc/vmsbc
both vm=0 (vd!=0) and vm=1 (vd==v0 legal) + an e8/m2 group smoke (splat sources,
self-compare carry mask) + a vd==v0 illegal terminator both sides trap on.
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
def test_b3_directed_lockstep():
    _run("b3", 160)


def test_b3_corpus_covers_carry_borrow_forms():
    fw = (PHASE / "firmware_b3.S").read_text()
    for pat, floor in ((r"vadc\.v[vxi]m", 3),   # vvm/vxm/vim
                       (r"vsbc\.v[vx]m", 2),     # vvm/vxm (no imm)
                       (r"vmadc\.v[vxi]m", 3),   # carry-in forms
                       (r"vmadc\.v[vxi]\b", 3),  # no-carry forms
                       (r"vmsbc\.v[vx]m", 2),    # borrow-in forms
                       (r"vmsbc\.v[vx]\b", 2)):  # no-borrow forms
        n = len(re.findall(pat, fw))
        assert n >= floor, f"B3 corpus lost {pat}: {n} < {floor}"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_prior_vector_targets_still_green():
    for tgt, bar in (("b1", 115), ("b2", 85), ("grid", 140),
                     ("s3", 65), ("vrand", 1200)):
        _run(tgt, bar)
