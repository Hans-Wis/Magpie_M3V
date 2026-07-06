"""gate_58_rvv_s3_lmul — ADR-0049 S3: LMUL m2/m4 register groups.

Groups execute as internal multi-beat in vexu (drained-start, one part per
cycle into staging) with ONE architectural commit: part 0 rides the pipeline
as the authoritative value, parts 1..N-1 are written atomically from staging
at WB under the same kill rules — no uop cracking, per-commit Spike lockstep
unchanged (the ADR-ruled design). Compares read groups but write ONE mask
register (no group write). Widening/narrowing/reductions keep their own
LMUL rules; vector memory stays EMUL<=1 (the legality now computes EMUL with
integer LMUL — bring-up caught e16/m2+vse16 EMUL=2 slipping through and, one
layer deeper, STORE-FP opcodes aliasing the f6 arith decodes into the new
group path: every other use site had an is_vmem priority mux).

Authority: phase_22 lockstep — s3 directed (72 commits: part-boundary vl
{16,17,32}, masked groups spanning parts, saturation raised only in a later
part, group compares, SEW sweep, odd-vd@m2 illegal terminator) + the random
corpus now drawing m2/m4 configs with group-aligned register pools.
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
def test_s3_directed_group_corners():
    _run("s3", 70)


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_s3_random_corpus_with_groups():
    _run("vrand", 1200)
    fw = (PHASE / "firmware_vrand.S").read_text()
    n = len(re.findall(r"vsetvli.*, m[24],", fw))
    assert n >= 10, f"m2/m4 configs shrank from the corpus: {n}"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_unaligned_opmvv_vv_source_is_illegal():
    _run("s3i", 6)          # Codex finding: vaaddu.vv with unaligned vs1 @m2


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_phase0_kernel_still_exact():
    _run("kernel", 40)
