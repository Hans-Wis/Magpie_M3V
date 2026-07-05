"""gate_80_rvv_f_m8 — ADR-0059 Phase-F: LMUL=m8 (8-register group).

Extends the VM_GRP multi-beat register-group path from max 4 parts (m4) to 8 parts
(m8) for same-width beats_op ops (add/sub/bitwise/shift/min-max/compares/mul/mac/sat/
vsmul/carry/vdiv). vlmax e8=128 / e16=64 / e32=32 (Spike-probed). vd/vs aligned mod-8.
Widening/reductions/mask-scan/gather/slides stay m8-illegal (cfg_illegal). Compares
under m8 emit a single mask register accumulated across parts (grp_mask_acc) with a
vl_ones[7:0] shift so vl==128 fills all 128 mask bits. The atomic group commit writes
grp_stage[1..7] at writeback (w_parts up to 8).

Authority: phase_22 `make f` vs Spike --isa=rv32imf_zve32x_zvl128b — m8 vadd.vv/.vx
e8/e16 + vmsltu/vmseq -> mask + vl=0/vl=1 + masked mu + unaligned-vd@m8 illegal
terminator (traps in BOTH DUT and Spike). The m1/m2/m4 group + fractional + segment
regression stays green (unchanged paths).
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
def test_f_directed_lockstep():
    _run("f", 40)


def test_f_corpus_covers_m8_forms():
    fw = (PHASE / "firmware_f.S").read_text()
    assert "e8, m8" in fw, "F must cover m8 at e8 (vlmax=128)"
    assert "e16, m8" in fw, "F must cover m8 at e16 (vlmax=64)"
    for pat in (r"vadd\.vv v24, v8, v16", r"vadd\.vx", r"vmsltu\.vx",
                r"vmseq\.vv", r"v0\.t", r"vadd\.vv v9, v8, v16"):
        assert re.search(pat, fw), f"F corpus lost {pat}"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_prior_group_and_vector_green():
    for tgt, bar in (("e1", 85), ("e2", 120), ("d2", 90), ("b3", 160),
                     ("c5", 90), ("pool", 160), ("vrand", 1200)):
        _run(tgt, bar)
