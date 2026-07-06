"""gate_03_10_fence_directed_lockstep - directed FENCE/FENCE.I (Zifencei) Spike lockstep.

P1 bar-B-minus: riscv-dv pyflow does NOT generate random fence (instr_category skip in vendored
pygen, riscv_instr.py:159-161), so FENCE/FENCE.I coverage is provided by this directed test and
verified per-commit against Spike. fence.i is a decoded architected NOP on cpu_m1 (no I-cache);
it must retire equivalently to Spike and never decode-trap as illegal.
"""

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_03_10_fence_directed"


def _read(name: str) -> str:
    return (PHASE / name).read_text(encoding="utf-8")


def test_phase_03_10_artifacts_exist():
    for name in ["firmware.S", "firmware.lds", "firmware_spike.lds", "Makefile",
                 "tb_spike_lockstep.v", "spike_lockstep.py", "firmware.disasm",
                 "sim.log", "spike.log", "lockstep.log"]:
        p = PHASE / name
        assert p.exists() and p.stat().st_size > 0, f"missing/empty fence artifact: {name}"


def test_phase_03_10_program_exercises_fence_and_fence_i():
    disasm = _read("firmware.disasm")
    # FENCE (opcode ...000f) and FENCE.I (0000100f) must be in the directed program
    fence_i = len(re.findall(r"\b0000100f\b\s+fence\.i", disasm))
    fence = len(re.findall(r"\bfence\b(?!\.)", disasm))
    assert fence_i >= 1, "no FENCE.I (Zifencei) in directed program"
    assert fence >= 1, "no FENCE in directed program"


def test_phase_03_10_dut_completed_via_ebreak_not_fence_trap():
    # If fence/fence.i decode-trapped as illegal, the DUT would stop early and the commit
    # count would fall short. The program ends on the final ebreak; reaching it with the full
    # commit count proves every fence retired as a NOP (not an illegal trap).
    sim = _read("sim.log")
    assert "FAIL" not in sim
    assert "PASS: DUT commit trace wrote" in sim
    m = re.search(r"commits=(\d+)", sim)
    assert m and int(m.group(1)) >= 20, "DUT stopped before completing the fence program"


def test_phase_03_10_lockstep_matches_spike():
    lockstep = _read("lockstep.log")
    assert lockstep.lstrip().startswith("PASS"), f"fence lockstep not PASS: {lockstep!r}"
    m = re.search(r"matched (\d+) commits", lockstep)
    assert m and int(m.group(1)) >= 10, "fence lockstep matched too few commits"
