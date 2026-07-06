"""gate_31_npu_core_directed_lockstep — Phase 2 Step 4 (ADR-0034) directed lockstep.

DUT = npu_top with the parameterized cpu_m1 sequencer (EN_RVC=0/EN_BP=0/EN_RAS=0) fetching
through the REAL npu_tcm ports. Golden = Spike --isa=rv32im_zicsr_zifencei (no C).
Directed program exercises the ADR-0032 strip risks at system level: mul/div busy,
branch taken/not-taken with EX-resolve-only redirect, jal/jalr without RAS, load-use.
Pass bar: 100% commit-trace match, >=500 commits. Sim = Verilator (VCS signoff OUTSIDE-SANDBOX).
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_20_npu_core_lockstep"

MISSING_TOOL = not (shutil.which("verilator") and shutil.which("spike"))


@pytest.mark.skipif(MISSING_TOOL, reason="verilator/spike absent — not-run")
def test_npu_directed_lockstep_passes():
    subprocess.run(["make", "-C", str(PHASE), "clean"], check=True, capture_output=True)
    r = subprocess.run(["make", "-C", str(PHASE), "directed"], capture_output=True, text=True)
    assert r.returncode == 0, f"directed lockstep failed:\n{r.stdout[-4000:]}\n{r.stderr[-2000:]}"
    log = (PHASE / "lockstep.log").read_text()
    assert log.startswith("PASS"), f"lockstep log not PASS: {log}"


@pytest.mark.skipif(MISSING_TOOL, reason="verilator/spike absent — not-run")
def test_directed_commit_bar_and_isa_guard():
    report = (PHASE / "lockstep_report.md").read_text()
    assert "Status: pass" in report
    # green-wash guards: commit bar respected and the ISA really has no C
    commits = int(report.split("Commits compared: ")[1].split(" ")[0])
    assert commits >= 500, f"directed run shrank to {commits} commits (<500)"
    assert "rv32im_zicsr_zifencei" in report and "rv32imc" not in report
