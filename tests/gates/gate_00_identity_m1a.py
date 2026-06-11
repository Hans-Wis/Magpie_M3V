"""gate_00_identity_m1a - M1A identity hard-separation smoke gate.

Magpie_M1A is a full-history fork of Magpie_M1 (tag m1-rtl-freeze-v1.0). Per the evidence-separation
rule (M1 CLAUDE.md §9 / docs/M1_DESIGN_FREEZE.md): M1's Tier-2 evidence is NEVER claimable by M1A —
every gate/lockstep/coverage result must be re-earned on this line under the new identity.

This gate pins the separation mechanically:
  1. ip.json design_id == cpu_m1a (+ provenance_fork records the parent tag/SHA)
  2. flow/state contains NO magpie_m1.* evidence (only magpie_m1a.* may exist)
so a copy-paste regression of identity (the failure mode Grok flagged at fork time) trips CI
immediately.
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def test_ip_json_identity_is_cpu_m1a():
    j = json.loads((ROOT / "IP/cpu_m1/ip.json").read_text())
    assert j["design_id"] == "cpu_m1a", f"design_id must be cpu_m1a, got {j['design_id']!r}"
    assert j["name"] == "cpu_m1a"
    pf = j.get("provenance_fork")
    assert pf and pf.get("fork_tag") == "m1-rtl-freeze-v1.0", "provenance_fork must record the M1 freeze tag"


def test_no_m1_state_evidence_in_m1a():
    state = ROOT / "flow/state"
    leaked = sorted(p.name for p in state.glob("magpie_m1.*"))
    assert not leaked, f"M1 evidence leaked into M1A flow/state: {leaked}"


def test_m1a_states_use_m1a_design_id():
    state = ROOT / "flow/state"
    for p in state.glob("*.state.json"):
        j = json.loads(p.read_text())
        design = j.get("design") or j.get("design_id") or ""
        assert "m1a" in str(design), f"{p.name}: state design id {design!r} is not an m1a identity"
