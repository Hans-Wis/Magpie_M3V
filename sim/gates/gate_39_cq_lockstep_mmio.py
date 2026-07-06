"""gate_39_cq_lockstep_mmio — ADR-0035: the CQ consume flow under per-commit Spike lockstep.

DUT = npu_top + shared-memory model: host rings the doorbell (TAIL=1), the sequencer slice
reads TAIL/HEAD over the core-local CSR mirror, DMA-fetches the descriptor from the ring,
decodes MAT.LOAD_W (SSOT encoding), executes it through the DMA engine, verifies the landed
weights, advances HEAD, and signals LAST via the DONE mailbox — every commit compared vs
Spike rv32im (no C).

MMIO honesty technique (ADR-0035): no Spike device plugin exists in this env, so the shadow
device is realized by SEEDING the Spike image (-DSPIKE_SEED) with the exact MMIO/DMA-produced
values the DUT deterministically reads (descriptor words, weight blob, STATUS=busy|dma_done|
irq_pending, HEAD/TAIL), and by using bounded pure-ALU delays + single reads instead of poll
loops. If the RTL's real STATUS/data ever drifts from the contract, the commit diff fails
loudly. Random lockstep scope is unchanged (TCM-only corpus, gate_32).
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_21_cq_lockstep"

MISSING_TOOL = not (shutil.which("verilator") and shutil.which("spike"))


@pytest.mark.skipif(MISSING_TOOL, reason="verilator/spike absent — not-run")
def test_cq_consume_lockstep():
    subprocess.run(["make", "-C", str(PHASE), "clean"], check=True, capture_output=True)
    r = subprocess.run(["make", "-C", str(PHASE), "all"], capture_output=True, text=True)
    assert r.returncode == 0, f"cq lockstep failed:\n{r.stdout[-4000:]}\n{r.stderr[-2000:]}"
    log = (PHASE / "lockstep.log").read_text()
    assert log.startswith("PASS"), log
    report = (PHASE / "lockstep_report.md").read_text()
    assert "Status: pass" in report
    assert "rv32im_zicsr_zifencei" in report and "rv32imc" not in report
