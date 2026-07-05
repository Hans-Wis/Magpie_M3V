"""gate_78_rvv_e2_segment — ADR-0058 Phase-E E2 (stub): segment load/store.

vlseg<nf>e<eew>.v / vsseg<nf>e<eew>.v, User-approved MINIMAL scope: nf=2..8, EEW=SEW,
LMUL=1, unmasked, vstart=0, unit-stride. element-major/field-minor interleave:
memory beat k=(element k/nf, field k%nf) at rs1 + k*eew_bytes; load fields go to
vd..vd+nf-1, store fields come from vs3..vs3+nf-1. Implemented as a vmem-FSM extension:
seg_off byte-offset accumulator + seg_fld field counter + vm_idx element counter; loads
capture into per-field seg_buf[] then drain to nf registers via VM_SEGWR (one reg/cycle
in the sole vrf-write block, q_vrf_we forced 0 like vmvr); stores source (vs3+f)[i]
beat-by-beat. Out-of-stub-scope (LMUL>1 / EEW!=SEW / masked) is intentionally illegal
(DUT stricter than Spike -- documented scope-cut, not lockstep-tested).

Authority: phase_22 `make e2` vs Spike --isa=rv32imf_zve32x_zvl128b — vlseg2/3/4
deinterleave + vsseg2 interleave x SEW 8/16/32 (golden-probed vlseg2 -> v4=a[], v5=b[]).
The vmem unit-stride regression stays green (the non-segment FSM path is unchanged).
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
def test_e2_directed_lockstep():
    _run("e2", 55)


def test_e2_corpus_covers_seg_forms():
    fw = (PHASE / "firmware_e2.S").read_text()
    for pat, floor in ((r"vlseg2e8\.v", 1), (r"vlseg3e8\.v", 1), (r"vlseg4e8\.v", 1),
                       (r"vsseg2e8\.v", 1), (r"vlseg2e16\.v", 1), (r"vlseg2e32\.v", 1)):
        assert re.search(pat, fw), f"E2 corpus lost {pat}"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_prior_mem_and_vector_green():
    for tgt, bar in (("e1", 85), ("vmem", 100), ("d2", 90),
                     ("s3", 65), ("pool", 160), ("vrand", 1200)):
        _run(tgt, bar)
