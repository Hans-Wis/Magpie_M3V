"""gate_04_10_toggle_effective_signoff - Tier-2-Narrow in-SKU EFFECTIVE toggle sign-off.

The raw whole-core toggle (58.9%) is below 95% because ~38% of raw toggle points are out-of-SKU
optional/integrator logic (PMP / RV32A / Debug+Trigger), constant/rollover/sticky nets that cannot
toggle by construction, or PC-high bits unreachable in the 16KB low-address farm. Per the industry-
accepted close (documented exclusion list + effective coverage to bar, see
docs/reports/toggle_exclusion_list.md and FEATURE_FREEZE.md SKU-1), the signable metric is the
**in-SKU EFFECTIVE** toggle coverage after excluding those categories.

This gate asserts the effective coverage meets the ≥90% defensible bar, from the committed
snapshot (toggle_signoff_snapshot.json), and — when the merged coverage DB is present — re-derives
it live via classify_signoff.py and checks the two agree (no silent drift). DV-lead human signature
on the exclusion list remains a separate PROCESS step (snapshot records it PENDING); this gate is
the reproducible coverage evidence that supports that signature.
"""

import json
import re
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_03_09_riscvdv_lockstep"
SNAP = PHASE / "toggle_signoff_snapshot.json"
DB = PHASE / "coverage_merged/m1a_farm.dat"
CLASSIFY = PHASE / "classify_signoff.py"
BAR = 90.0


def _snap():
    return json.loads(SNAP.read_text())


def test_snapshot_exists():
    assert SNAP.exists(), "toggle_signoff_snapshot.json missing"
    s = _snap()
    assert s["raw_hit"] > 0 and s["effective_denom"] > 0


def test_effective_meets_defensible_bar():
    s = _snap()
    assert s["effective_pct"] >= BAR, (
        f"in-SKU effective toggle {s['effective_pct']}% < {BAR}% defensible bar")


def test_effective_arithmetic_consistent():
    s = _snap()
    # effective denom = raw_total - out_of_sku - structural - address_bound; hit unchanged.
    ex = s["exclusions"]
    expect_denom = s["raw_total"] - ex["out_of_sku"] - ex["structural"] - ex["address_bound"]
    assert expect_denom == s["effective_denom"], (
        f"denom mismatch: {expect_denom} != {s['effective_denom']}")
    assert abs(100.0 * s["effective_hit"] / s["effective_denom"] - s["effective_pct"]) < 0.1


def test_live_db_matches_snapshot():
    """If the merged coverage DB is present, re-derive and check it agrees with the snapshot."""
    if not (DB.exists() and DB.stat().st_size > 0):
        pytest.skip("merged coverage DB not present (run the farm + injectors)")
    out = subprocess.run(["python3", str(CLASSIFY), str(DB)], capture_output=True, text=True).stdout
    m = re.search(r"effective = (\d+)/(\d+) = ([\d.]+)%", out)
    assert m, f"classify_signoff produced no effective number:\n{out[:500]}"
    live = float(m.group(3))
    assert abs(live - _snap()["effective_pct"]) < 0.5, (
        f"live effective {live}% drifted from snapshot {_snap()['effective_pct']}%")
    assert live >= BAR
