"""gate_03_12_through_trap_lockstep - through-trap per-commit verification (Tier-2 blocker #3).

Closes the P17 "through-trap not commit-by-commit" gap (docs/reports/integration_closure.md,
dv_methodology_equivalence.md). A directed M-mode ECALL trap drives the DUT through a real handler
(reads mepc/mcause/mstatus, advances mepc, mret, resumes) twice.

KEY FINDING (corrects the prior vague claim): Spike 1.1.1-dev `--log-commits` HALTS the commit log at
the first M-mode synchronous trap — verified here with a clean no-MMIO ecall (earlier reports blamed an
unmapped-MMIO store fault; the real limitation is the trap itself, confirmed with plain `-l` too). So
Spike cannot be the post-trap oracle in this build. Through-trap correctness is proven by:
  (1) Spike per-commit lockstep on the PRE-TRAP prefix, and
  (2) the DUT executing the FULL handler with trap CSRs + resume PC matched to the RISC-V spec
      (mepc==ecall_pc, mcause==11 M-ecall, mstatus==0x1800 MPP=M/MPIE=0/MIE=0, resume==ecall_pc+4).
spike_commit.py was also extended to normalize PC-holding CSR reads (mepc/mtvec/mtval) by pc_base, so a
Spike build that DOES log through traps would compare the handler per-commit with no further change.
"""

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_03_12_through_trap"


def _read(name: str) -> str:
    return (PHASE / name).read_text(encoding="utf-8")


def test_phase_03_12_artifacts_exist():
    for name in ["firmware.S", "firmware.lds", "firmware_spike.lds", "Makefile",
                 "tb_spike_lockstep.v", "spike_lockstep.py", "firmware.disasm",
                 "sim.log", "spike.log", "lockstep.log", "dut_commit.trace"]:
        p = PHASE / name
        assert p.exists() and p.stat().st_size > 0, f"missing/empty artifact: {name}"


def test_phase_03_12_program_has_ecall_traps_and_handler():
    disasm = _read("firmware.disasm")
    assert len(re.findall(r"\becall\b", disasm)) >= 2, "need >=2 ecall sync traps"
    assert re.search(r"csrr\s+a0,\s*mepc", disasm), "handler must read mepc"
    assert re.search(r"csrr\s+a1,\s*mcause", disasm), "handler must read mcause"
    assert re.search(r"\bmret\b", disasm), "handler must mret"


def test_phase_03_12_dut_executes_full_handler():
    """The DUT trace must contain the handler commits AND the post-mret resume — i.e. the DUT
    actually went THROUGH the trap (not just up to it)."""
    trace = _read("dut_commit.trace").strip().splitlines()[1:]
    pcs = [int(line.split(",")[1], 16) for line in trace if line.strip()]
    assert 0x38 in pcs, "handler entry (pc 0x38) not executed"
    assert 0x20 in pcs and 0x2c in pcs, "program did not resume after mret (no 0x20/0x2c)"
    assert len(pcs) >= 20, f"too few commits ({len(pcs)}) — DUT did not run both traps + handlers"


def test_phase_03_12_lockstep_pass():
    """spike_lockstep.py: pre-trap prefix Spike-equivalent + through-trap handler spec-validated."""
    log = _read("lockstep.log")
    assert log.lstrip().startswith("PASS"), f"through-trap lockstep not PASS: {log!r}"
    assert "prefix lockstep matched" in log
    assert "mret resumes correctly" in log


def test_phase_03_12_sim_completed_through_traps():
    sim = _read("sim.log")
    assert "FAIL" not in sim and "stop on ebreak" in sim
    m = re.search(r"commits=(\d+)", sim)
    assert m and int(m.group(1)) >= 20, "DUT did not complete both through-traps"
