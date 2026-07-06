"""gate_03_11_stall_xboundary_lockstep - directed stall/redirect x cross-boundary Spike lockstep.

Closes the BUG-XBOUND-0001 "Open lead" (docs/reports/bug_xbound_0001/findings.md): a
load-use/muldiv STALL or a branch REDIRECT landing ON a consecutive cross-boundary 32-bit
RVC run holds cross_assemble/residue while i_mem_addr reverts to the held PC, so the resumed
{cur_half_lo, residue} could use a stale cur_half_lo. The riscv-dv arith+RVC farm physically
cannot reach this corner (no loads -> no load-use stall during a run), so it is proven here by
a directed program with VCD + per-commit Spike equivalence.

The program (firmware.S) builds a consecutive cross-boundary run (one c.nop -> every following
32-bit instr starts at a high half, %4==2) and places inside it: a load-use stall, two muldiv
(mul/div) use stalls, a taken forward branch (redirect onto a cross instr, with a wrong-path
instruction that must NOT commit), and a taken backward branch (2nd pass re-enters the run via
the redirect-fallback path rather than the prefetch path). Equivalence to Spike (pc/instr/rd/
wdata) for every retired commit proves the resumed assembly is correct.

Authority = Spike per-commit lockstep, not "looks right". Layer-1 honesty.
"""

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_03_11_stall_xboundary"


def _read(name: str) -> str:
    return (PHASE / name).read_text(encoding="utf-8")


def test_phase_03_11_artifacts_exist():
    for name in ["firmware.S", "firmware.lds", "firmware_spike.lds", "Makefile",
                 "tb_spike_lockstep.v", "spike_lockstep.py", "firmware.disasm",
                 "sim.log", "spike.log", "lockstep.log"]:
        p = PHASE / name
        assert p.exists() and p.stat().st_size > 0, f"missing/empty artifact: {name}"


def test_phase_03_11_program_builds_consecutive_cross_boundary_run():
    """At least a dozen 32-bit instructions must start at an odd half-word (addr %4==2),
    i.e. cross a word boundary, which is what makes the run 'consecutive cross-boundary'."""
    disasm = _read("firmware.disasm")
    cross = re.findall(r"^\s+[0-9a-f]*[26ae]:\s+[0-9a-f]{8}\s", disasm, re.MULTILINE)
    assert len(cross) >= 12, f"too few cross-boundary 32-bit instrs ({len(cross)}); run not built"


def test_phase_03_11_program_exercises_stall_and_redirect_classes():
    """The directed program must contain the stall/redirect classes the open lead is about:
    a load, a mul, a div, and (forward+backward) taken branches inside the cross run."""
    disasm = _read("firmware.disasm")
    assert re.search(r"[26ae]:\s+[0-9a-f]{8}\s+lw\b", disasm), "no cross-boundary load (load-use stall)"
    assert re.search(r"[26ae]:\s+[0-9a-f]{8}\s+mul\b", disasm), "no cross-boundary mul (muldiv stall)"
    assert re.search(r"[26ae]:\s+[0-9a-f]{8}\s+div\b", disasm), "no cross-boundary div (muldiv stall)"
    assert len(re.findall(r"[26ae]:\s+[0-9a-f]{8}\s+bne\b", disasm)) >= 2, "need forward+backward redirect"


def test_phase_03_11_wrongpath_instruction_not_committed():
    """The instruction skipped by the taken forward branch (addi a6,a5,99 @0x3e) is wrong-path:
    it must never appear in the DUT commit trace. (Catches wrong-path-commit regressions.)"""
    disasm = _read("firmware.disasm")
    m = re.search(r"^\s+([0-9a-f]+):\s+([0-9a-f]{8})\s+addi\s+a6", disasm, re.MULTILINE)
    assert m, "wrong-path addi a6 not found in program"
    wrongpath_pc = int(m.group(1), 16)
    trace = _read("dut_commit.trace")
    committed_pcs = {int(line.split(",")[1], 16) for line in trace.splitlines()[1:] if line.strip()}
    assert wrongpath_pc not in committed_pcs, f"wrong-path instr @0x{wrongpath_pc:x} wrongly committed"


def test_phase_03_11_dut_completed_via_ebreak():
    sim = _read("sim.log")
    assert "FAIL" not in sim
    assert "PASS: DUT commit trace wrote" in sim
    m = re.search(r"commits=(\d+)", sim)
    assert m and int(m.group(1)) >= 30, "DUT stopped before completing the stress program"


def test_phase_03_11_lockstep_matches_spike():
    lockstep = _read("lockstep.log")
    assert lockstep.lstrip().startswith("PASS"), f"stall_xboundary lockstep not PASS: {lockstep!r}"
    m = re.search(r"matched (\d+) commits", lockstep)
    assert m and int(m.group(1)) >= 30, "lockstep matched too few commits"
