"""gate_03_13_fence_in_stream_lockstep - fence/fence.i IN-STREAM riscv-dv lockstep (Tier-2 blocker #4a).

The riscv-dv pyflow does not emit fence in the random stream, so the 105k farm EXCLUDED fence
(covered only directed, gate_03_10). This closes that exclusion AT SCALE: fence/fence.i are injected
into random riscv-dv programs and the same farm DUT+Spike per-commit lockstep is run. fence.i is an
architected NOP on cpu_m1 (no I-cache) and a NOP in Spike's trace, so a correct DUT retires it
identically; any mis-handling (e.g. decode-trap as illegal) would diverge.

Reproduce: `python3 flow/v2_pipeline/phase_03_09_riscvdv_lockstep/inject_fence_lockstep.py`
(writes fence_in_stream_summary.json). This gate validates that summary.

NOTE: the async-IRQ half of blocker #4 is tracked separately — Spike 1.1.1-dev has no deterministic
external-IRQ injection (only `-d`), so truly-async meip lockstep is Spike-limited; the lockstep-able
interrupt is software-interrupt (msip, program-self-triggered). See task #4 / coverage docs.
"""

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SUMMARY = ROOT / "flow/v2_pipeline/phase_03_09_riscvdv_lockstep/fence_in_stream_summary.json"


def _summary() -> dict:
    assert SUMMARY.exists() and SUMMARY.stat().st_size > 0, f"missing {SUMMARY}"
    return json.loads(SUMMARY.read_text(encoding="utf-8"))


def test_fence_in_stream_summary_pass():
    s = _summary()
    assert s["status"] == "PASS", f"fence-in-stream not PASS: {s.get('status')}"
    assert s["divergences"] == 0, f"fence-in-stream divergences: {s['divergences']}"


def test_fence_in_stream_has_seeds_and_commits():
    s = _summary()
    assert s["seeds"] >= 3, f"too few seeds: {s['seeds']}"
    assert s["total_matched_commits"] >= 5000, f"too few matched commits: {s['total_matched_commits']}"


def test_fence_actually_present_in_every_program():
    """Each program's compiled disasm must contain >=1 fence.i — otherwise the test is vacuous."""
    s = _summary()
    for row in s["per_seed"]:
        assert row["ok"], f"seed {row['seed']} diverged: {row['message']}"
        assert row["disasm_fence_i"] >= 1, f"seed {row['seed']} has no fence.i in compiled program"
