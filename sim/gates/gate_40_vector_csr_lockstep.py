"""gate_40_vector_csr_lockstep — ADR-0036 Stage 3A / P0④: the vector-CSR lockstep contract.

Directed vset{i}vl{i} grid on the EN_RVV=1 sequencer inside npu_top: legal SEW×LMUL configs
(incl. the kernel-critical fractional mf4/mf2), AVL boundaries (0/1/vlmax−1/vlmax/AVL>vlmax),
vsetivli immediates, tail/mask encoding bits, the keep-vl x0 matrix, and the vsetvl
register-vtype form — each followed by csrr checkpoints of vl/vtype/vstart (plus
vlenb/vxsat/vcsr round-trips) so the vector-CSR state enters the compared scalar commit
stream. Golden = Spike --isa=rv32im_zve32x_zvl128b_zicsr_zifencei (no C, no F).
Pass = 100% commit match. This is the P0④ per-commit half; the post-run memory half
arrives with vector stores in Stage 3C (ADR-0036).
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_22_vector_csr_lockstep"

MISSING_TOOL = not (shutil.which("verilator") and shutil.which("spike"))


@pytest.mark.skipif(MISSING_TOOL, reason="verilator/spike absent — not-run")
def test_vector_csr_grid_lockstep():
    subprocess.run(["make", "-C", str(PHASE), "clean"], check=True, capture_output=True)
    r = subprocess.run(["make", "-C", str(PHASE), "grid"], capture_output=True, text=True)
    assert r.returncode == 0, f"vcsr grid lockstep failed:\n{r.stdout[-4000:]}\n{r.stderr[-2000:]}"
    report = (PHASE / "lockstep_report.md").read_text()
    assert "Status: pass" in report
    assert "zve32x_zvl128b" in report and "rv32imc" not in report  # ISA green-wash guard
