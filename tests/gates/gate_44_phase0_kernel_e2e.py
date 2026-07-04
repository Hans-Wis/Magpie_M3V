"""gate_44_phase0_kernel_e2e — ADR-0036 Stage 3D: the Phase 3 EXIT BAR.

The UNMODIFIED Phase 0 kernel (IP/npu/sw/rvv_zve32x_smoke/vdot_i8.c, compiled by clang
with the exact Phase 0 -march=rv32im_zve32x_zvl128b) runs on the EN_RVV sequencer inside
npu_top: vsetvli(e32m1/e8mf4/keep-vl e16mf2) -> vle8.v x2 -> vwmul.vv -> vwadd.wv
(vd==vs2 accumulate) -> vmv.s.x -> vredsum.vs -> vmv.x.s. dot([1..8],[2..9]) = 240.

Pass = 100% commit-stream match vs Spike (43 commits) AND the 240 result observed in
the compared stream three ways (a0 return, register move, scalar lw readback of the
stored result slot = the memory-region check, in-stream).

`make vwide` is the directed half: per-op lockstep for vwmul/vwadd.wv/vmv.s.x/vredsum
incl. negative-operand sign correctness through widening (which caught a real Verilog
signedness bug: an unsigned concat branch in a conditional zero-extended 0x81), 16-bit
lane memory verification via vse16, vd==vs2 accumulation, and vl=0 no-ops.

Green-wash guards: the kernel .c is compiled from the checked-in Phase 0 source with the
checked-in -march (asserted below); random-corpus widening coverage is a recorded
deferral (directed + kernel are the 3D bar).
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_22_vector_csr_lockstep"

MISSING_TOOL = not (shutil.which("verilator") and shutil.which("spike") and shutil.which("clang"))


@pytest.mark.skipif(MISSING_TOOL, reason="verilator/spike/clang absent — not-run")
def test_widening_reduction_directed_lockstep():
    r = subprocess.run(["make", "-C", str(PHASE), "vwide"], capture_output=True, text=True)
    assert r.returncode == 0, f"vwide lockstep failed:\n{r.stdout[-4000:]}\n{r.stderr[-2000:]}"
    assert "Status: pass" in (PHASE / "lockstep_report.md").read_text()


@pytest.mark.skipif(MISSING_TOOL, reason="verilator/spike/clang absent — not-run")
def test_phase0_kernel_end_to_end():
    r = subprocess.run(["make", "-C", str(PHASE), "kernel"], capture_output=True, text=True)
    assert r.returncode == 0, f"kernel lockstep failed:\n{r.stdout[-4000:]}\n{r.stderr[-2000:]}"
    report = (PHASE / "lockstep_report.md").read_text()
    assert "Status: pass" in report and "zve32x_zvl128b" in report
    trace = (PHASE / "dut_commit.trace").read_text()
    assert trace.count("000000f0") >= 3, "result 240 not observed (return + mv + memory readback)"


def test_kernel_is_the_phase0_source_and_march():
    mk = (PHASE / "Makefile").read_text()
    assert "IP/npu/sw/rvv_zve32x_smoke/vdot_i8.c" in mk, "kernel source swapped"
    assert "KERNEL_MARCH = rv32im_zve32x_zvl128b" in mk, "kernel -march drifted from Phase 0"
    assert "-O2" in mk
