"""gate_10_host_noregress — freeze guard for the M3V host core.

M3V's `IP/cpu_m1/` is the FROZEN M1A scalar host (tag m1a-rtl-freeze-v1.0). ADR-0031 requires it to
stay byte-identical: all net-new work lands under `IP/npu/`. This gate mechanically enforces the
freeze so any accidental edit to the host RTL (or a mis-scoped NPU change touching it) trips CI.

Check: `git diff m1a-rtl-freeze-v1.0 -- IP/cpu_m1/rtl` must be empty, and the host RTL must exist.
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
FREEZE_TAG = "m1a-rtl-freeze-v1.0"


def _git(*args):
    return subprocess.run(["git", "-C", str(ROOT), *args], capture_output=True, text=True)


@pytest.mark.skipif(not shutil.which("git"), reason="no git — not-run")
def test_frozen_host_rtl_byte_identical_to_freeze_tag():
    tag = _git("rev-parse", "--verify", f"{FREEZE_TAG}^{{commit}}")
    assert tag.returncode == 0, f"freeze tag {FREEZE_TAG} not found in M3V repo"
    diff = _git("diff", "--stat", FREEZE_TAG, "--", "IP/cpu_m1/rtl")
    assert diff.returncode == 0, f"git diff failed:\n{diff.stderr}"
    assert diff.stdout.strip() == "", (
        "FROZEN host RTL under IP/cpu_m1/rtl/ diverged from the freeze tag:\n" + diff.stdout
    )


def test_host_rtl_present():
    core = ROOT / "IP/cpu_m1/rtl/core.v"
    assert core.is_file(), "frozen host core.v missing — IP/cpu_m1/rtl must be intact"
