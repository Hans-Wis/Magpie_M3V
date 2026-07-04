"""gate_42_vector_alu_lockstep — ADR-0036 Stage 3B: VRF + integer vector ALU subset.

Two lockstep runs on the EN_RVV=1 sequencer (Spike rv32im_zve32x_zvl128b, no C):
- `make valu`: directed — vadd/vsub (vv/vx/vi), vmv.v.*/vmv.x.s, vmerge mask select,
  fractional-LMUL execution, 8/16-bit sign extension through vmv.x.s, vl=0 no-op,
  vstart round-trip, back-to-back RAW through the WB-commit VRF path.
- `make vrand`: mixed vector/scalar random (52+ blocks, ~800+ commits), every block
  vsetvli-reconfigured with csrr checkpoints and a vmv.x.s probe (P0④ discipline).

Spike-matched semantics locked by these runs (found BY the runs, recorded in ADR-0036):
- arithmetic with vstart!=0 traps illegal (Spike's spec-allowed choice),
- tail policy = UNDISTURBED regardless of vta (this Spike build's agnostic choice).
Whole-register memory authority arrives with vector stores in 3C; element-0 probes +
the VRF debug tap (dut_vrf.trace) are the 3B observability envelope.
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_22_vector_csr_lockstep"

MISSING_TOOL = not (shutil.which("verilator") and shutil.which("spike"))


@pytest.mark.skipif(MISSING_TOOL, reason="verilator/spike absent — not-run")
def test_vector_alu_directed_lockstep():
    r = subprocess.run(["make", "-C", str(PHASE), "valu"], capture_output=True, text=True)
    assert r.returncode == 0, f"valu lockstep failed:\n{r.stdout[-4000:]}\n{r.stderr[-2000:]}"
    report = (PHASE / "lockstep_report.md").read_text()
    assert "Status: pass" in report and "zve32x_zvl128b" in report


@pytest.mark.skipif(MISSING_TOOL, reason="verilator/spike absent — not-run")
def test_vector_alu_random_lockstep():
    r = subprocess.run(["make", "-C", str(PHASE), "vrand"], capture_output=True, text=True)
    assert r.returncode == 0, f"vrand lockstep failed:\n{r.stdout[-4000:]}\n{r.stderr[-2000:]}"
    report = (PHASE / "lockstep_report.md").read_text()
    assert "Status: pass" in report
    commits = int(report.split("Commits compared: ")[1].split(" ")[0])
    assert commits >= 800, f"vrand shrank to {commits} commits (<800)"


def test_generator_stays_in_3b_envelope():
    gen = (PHASE / "gen_vector_random.py").read_text()
    # honest-envelope guards: no m2/m4/m8 configs, no C, vstart never nonzero at a vector op
    assert '"m2"' not in gen and '"m4"' not in gen and '"m8"' not in gen
    assert "vstart" in gen  # documented constraint present
    assert "vmv.x.s" in gen and "csrr t2, vl" in gen  # probe + checkpoint discipline
