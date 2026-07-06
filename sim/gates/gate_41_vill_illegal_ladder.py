"""gate_41_vill_illegal_ladder — ADR-0036 Stage 3A: vill state machine vs Spike.

Illegal vtype configurations injected via the vsetvl register form (raw vtype in rs2 —
reaches encodings the assembler rejects): fractional-rule violations (e8mf8/e16mf4/e32mf2,
SEW/LMUL > ELEN), reserved vlmul=100, e64 beyond Zve32x ELEN, reserved vtype bits. Each must
set vill (vtype=0x8000_0000, vl=0, checked via csrr checkpoints in the compared stream) and
a following legal vsetvli must recover.

Scope note (recorded): "vector op after vill traps illegal" is Stage 3B scope — in 3A no
vector compute op exists (all non-vset OP-V encodings are honestly illegal), and a trapping
op ends the commit trace; what 3A verifies is the vill STATE machine itself.
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_22_vector_csr_lockstep"

MISSING_TOOL = not (shutil.which("verilator") and shutil.which("spike"))


@pytest.mark.skipif(MISSING_TOOL, reason="verilator/spike absent — not-run")
def test_vill_ladder_lockstep():
    r = subprocess.run(["make", "-C", str(PHASE), "vill"], capture_output=True, text=True)
    assert r.returncode == 0, f"vill ladder lockstep failed:\n{r.stdout[-4000:]}\n{r.stderr[-2000:]}"
    report = (PHASE / "lockstep_report.md").read_text()
    assert "Status: pass" in report
    assert "zve32x_zvl128b" in report
