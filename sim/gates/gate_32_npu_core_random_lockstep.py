"""gate_32_npu_core_random_lockstep — Phase 2 Step 4 (ADR-0034) random lockstep signoff.

>=8 seeds x >=10,000 commits/seed of loop-wrapped rv32im (NO C) random programs on the
npu_top DUT (core fetches from the real npu_tcm), each seed 100% commit-match vs Spike
--isa=rv32im_zicsr_zifencei. The DONE mailbox is never used as EOF (ebreak only) — the
generator reserves x29/x30/x31 and never emits mailbox addresses (ADR-0034 guard).
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_20_npu_core_lockstep"

SEEDS = [20260703, 1, 2, 3, 5, 8, 13, 21]
MIN_COMMITS = 10_000

MISSING_TOOL = not (shutil.which("verilator") and shutil.which("spike"))


@pytest.mark.skipif(MISSING_TOOL, reason="verilator/spike absent — not-run")
@pytest.mark.parametrize("seed", SEEDS)
def test_npu_random_lockstep_seed(seed):
    r = subprocess.run(
        ["make", "-C", str(PHASE), "random", f"SEED={seed}"],
        capture_output=True, text=True,
    )
    assert r.returncode == 0, f"seed {seed} lockstep failed:\n{r.stdout[-4000:]}\n{r.stderr[-2000:]}"
    report = (PHASE / "lockstep_report.md").read_text()
    assert "Status: pass" in report, f"seed {seed}: {report}"
    commits = int(report.split("Commits compared: ")[1].split(" ")[0])
    assert commits >= MIN_COMMITS, f"seed {seed} shrank to {commits} commits (<{MIN_COMMITS})"


@pytest.mark.skipif(MISSING_TOOL, reason="verilator/spike absent — not-run")
def test_generator_never_touches_mailbox():
    # static guard: reserved regs + no mailbox constant in the generator
    gen = (PHASE / "gen_npu_random_program.py").read_text()
    assert "range(5, 29)" in gen, "x29/x30/x31 reservation removed from generator"
    assert '"    ebreak",' in gen, "ebreak terminator removed from generator"
    # data pointer is la x31,data_area (in-TCM); no absolute-address stores exist,
    # so the only way to reach the mailbox would be an explicit lui — forbid it.
    assert "lui  x31" not in gen and "lui x31" not in gen
