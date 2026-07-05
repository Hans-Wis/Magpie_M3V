"""gate_71_rvv_c4c_wmacc — ADR-0056 Phase-C C4c: widening multiply-accumulate.

vwmaccu (u*u), vwmacc (s*s), vwmaccsu (signed vs1 * unsigned vs2), vwmaccus
(unsigned rs1 * signed vs2, .vx only) -> vd (2*SEW) += product. f6=111100/111101/
111111/111110. The su/us sign roles are on vs1/vs2 and SWAPPED vs vwmulsu (a
notorious RVV quirk) — Spike-probed vs2=-128 vs1=255 vd=0 -> maccu 32640 / macc 128 /
maccsu -128 / maccus -32640. vd is the wide accumulator (read as the 2*SEW lane).
Shares the g_w8/g_w16 widening loops (r = op_wmaccany?macc_res : op_wmulany?prod :
ws_res). SEW<=16, fractional LMUL, vm=1. Overlap: vd==vs1/vs2 illegal (narrow src).

Authority: phase_22 `make c4c` vs Spike --isa=rv32imf_zve32x_zvl128b — all 4 MAC
variants x .vv/.vx (vwmaccus .vx only) x SEW 8/16 with a reseeded accumulator, and a
vwmaccu.vv-vd==vs2 narrow-overlap illegal terminator both sides trap on.
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
def test_c4c_directed_lockstep():
    _run("c4c", 120)


def test_c4c_corpus_covers_all_variants():
    fw = (PHASE / "firmware_c4c.S").read_text()
    for pat, floor in ((r"vwmaccu\.v[vx]", 2), (r"vwmacc\.v[vx]", 2),
                       (r"vwmaccsu\.v[vx]", 2), (r"vwmaccus\.vx", 2)):
        n = len(re.findall(pat, fw))
        assert n >= floor, f"C4c corpus lost {pat}: {n} < {floor}"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_prior_widening_and_vector_green():
    for tgt, bar in (("c4a", 130), ("c4b", 90), ("c2", 130),
                     ("vwide", 80), ("kernel", 40), ("vrand", 1200)):
        _run(tgt, bar)
