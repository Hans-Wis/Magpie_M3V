"""gate_79_rvv_e3_vrgather — ADR-0058 Phase-E E3: vrgather.

vrgather.vv/.vx/.vi — vd[i] = (index >= vlmax) ? 0 : vs2[index]; index = vs1[i] (SEW,
.vv) / rs1 (.vx) / uimm (.vi). OPIVV/OPIVX/OPIVI f6=001100. m1-only combinational
crossbar (16:1/8:1/4:1 lane select via idx low bits, out-of-range via vlmax_el).
Legality (Spike-probed): require_noover -> vd==vs2 illegal and (.vv) vd==vs1 illegal;
vstart!=0 illegal (global rule); masked-vd0 illegal. vrgatherei16 (f6=001110 OPIVV)
is deferred (16-bit index would need an EMUL>1 index register group).

Authority: phase_22 `make e3` vs Spike --isa=rv32imf_zve32x_zvl128b — .vv/.vx/.vi x SEW
8/16/32 with out-of-range indices (-> 0), broadcast (.vx/.vi), a masked gather, and a
vrgather.vv-vd==vs2 overlap illegal terminator both sides trap on. Golden src[10..17]
idx[3,0,7,2,9,1,5,4] -> [13,10,17,12,0,11,15,14].
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
def test_e3_directed_lockstep():
    _run("e3", 60)


def test_e3_corpus_covers_forms():
    fw = (PHASE / "firmware_e3.S").read_text()
    for pat, floor in ((r"vrgather\.vv", 3), (r"vrgather\.vx", 3), (r"vrgather\.vi", 2)):
        n = len(re.findall(pat, fw))
        assert n >= floor, f"E3 corpus lost {pat}: {n} < {floor}"
    assert "v0.t" in fw and re.search(r"li +a1, *20", fw), "E3 needs masked + OOR cases"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_prior_vector_green():
    for tgt, bar in (("e1", 85), ("e2", 55), ("d2", 90),
                     ("c1", 100), ("pool", 160), ("vrand", 1200)):
        _run(tgt, bar)
