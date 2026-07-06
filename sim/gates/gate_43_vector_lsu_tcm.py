"""gate_43_vector_lsu_tcm — ADR-0036 Stage 3C: unit-stride vector loads/stores.

`make vmem` directed lockstep (110 commits, 100% match vs Spike rv32im_zve32x_zvl128b):
vle8/vle16/vle32 + vse16/vse32, EEW!=SEW (vle8 under e32 = EMUL mf4), partial-vl stores
with sentinel words proving only vl elements touch memory, whole-register stores proving
the undisturbed policy IN MEMORY, vl=0 load/store no-ops, and a vstart!=0 RESUMABLE load
(elements below vstart undisturbed; Spike executes it — the arithmetic-only scope of the
vstart-illegal rule is thereby lockstep-proven, Grok's 3C blocker flag).

Memory authority = the commit stream itself (P0④ post-run half realized in-stream):
every vector-store target is scalar-lw'ed back and compared bit-exact; every vector load
reads scalar-sw-initialized memory. The mixed random corpus (gate_42 vrand) also carries
one legal-EEW memory op per block against a scalar-initialized pool.

Design note (recorded): the vector-memory FSM starts only with EX/MEM+EX/WB drained, so
mid-op flush/IRQ is impossible by construction (wb_take_irq needs a valid WB instruction)
and store beats are never wrong-path. Vector beats use the same core_d TCM port and
arbitration (dma > core > host) already proven under overlap by gate_33; a dedicated
vector-vs-DMA overlap test is deferred to the 3D/system stage (honest note).
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_22_vector_csr_lockstep"

MISSING_TOOL = not (shutil.which("verilator") and shutil.which("spike"))


@pytest.mark.skipif(MISSING_TOOL, reason="verilator/spike absent — not-run")
def test_vector_lsu_directed_lockstep():
    r = subprocess.run(["make", "-C", str(PHASE), "vmem"], capture_output=True, text=True)
    assert r.returncode == 0, f"vmem lockstep failed:\n{r.stdout[-4000:]}\n{r.stderr[-2000:]}"
    report = (PHASE / "lockstep_report.md").read_text()
    assert "Status: pass" in report and "zve32x_zvl128b" in report
    commits = int(report.split("Commits compared: ")[1].split(" ")[0])
    assert commits >= 70, f"vmem shrank to {commits} commits"


def test_vmem_firmware_covers_the_contract():
    fw = (PHASE / "firmware_vmem.S").read_text()
    for tok in ("vle8.v", "vle16.v", "vle32.v", "vse16.v", "vse32.v",
                "csrw vstart", "vsetivli t1, 0"):
        assert tok in fw, f"vmem firmware lost coverage token: {tok}"
