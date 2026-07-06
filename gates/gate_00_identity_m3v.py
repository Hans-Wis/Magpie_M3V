"""gate_00_identity_m3v - M3V identity hard-separation smoke gate.

Magpie_M3V is a full-history fork of Magpie_M1A (tag m1a-rtl-freeze-v1.0). It is the
*self-built HYBRID NPU* successor: the frozen M1A scalar core (design/cpu_m1/) stays as the host,
and all net-new ML acceleration (tightly-coupled int8/int4 GEMV TCU + TCM/DMA) lands under
design/npu/. This is a SIBLING of Magpie_M1V (which took the CoralNPU IMPORT route, ADR-0030) —
their evidence is hard-isolated.

Per the evidence-separation rule (CLAUDE.md §9 / docs/M1A_DESIGN_FREEZE.md): M1A's / M1's
Tier-2 evidence is NEVER claimable by M3V — every gate/lockstep/coverage result must be
re-earned on this line under the new identity (the inherited M1A scalar+TCM RTL is re-verified
only as a no-regression guard, not re-claimed).

This gate pins the separation mechanically:
  1. ip.json design_id == cpu_m3v (+ provenance_fork records the M1A freeze tag/SHA)
  2. flow/state contains NO magpie_m1.* / magpie_m1a.* / magpie_m1v.* ancestor/sibling evidence
     (only magpie_m3v.* may exist)
so a copy-paste regression of identity (the failure mode Grok flagged at fork time) trips CI
immediately.
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_ip_json_identity_is_cpu_m3v():
    j = json.loads((ROOT / "design/cpu_m1/ip.json").read_text())
    assert j["design_id"] == "cpu_m3v", f"design_id must be cpu_m3v, got {j['design_id']!r}"
    assert j["name"] == "cpu_m3v"
    pf = j.get("provenance_fork")
    assert pf and pf.get("fork_tag") == "m1a-rtl-freeze-v1.0", "provenance_fork must record the M1A freeze tag"
    assert pf.get("parent", "").startswith("Magpie_M1A"), "parent must be Magpie_M1A"


def test_no_ancestor_or_sibling_state_evidence_in_m3v():
    state = ROOT / "flow/state"
    leaked = (
        sorted(p.name for p in state.glob("magpie_m1.*"))
        + sorted(p.name for p in state.glob("magpie_m1a.*"))
        + sorted(p.name for p in state.glob("magpie_m1v.*"))
    )
    assert not leaked, f"ancestor/sibling (M1/M1A/M1V) evidence leaked into M3V flow/state: {leaked}"


def test_m3v_states_use_m3v_design_id():
    state = ROOT / "flow/state"
    for p in state.glob("*.state.json"):
        j = json.loads(p.read_text())
        design = j.get("design") or j.get("design_id") or ""
        assert "m3v" in str(design), f"{p.name}: state design id {design!r} is not an m3v identity"
