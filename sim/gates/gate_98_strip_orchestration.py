"""gate_98_strip_orchestration — ADR-0073: strip-mode orchestration tax.

The point of strip mode is killing the per-tile firmware tax (real-size gate/up
= 320 tiles x ~187 cyc ~= 359k/proj on the generic path). This gate measures the
strip case's ML_V2_BREAKDOWN 'other' component (= everything that is neither
mat_busy nor dma_busy: FSM sequencing, rendezvous waits at 1-cycle SRAM where
prefetch is never the constraint) and holds it to the strip-launch scale:

  case = 2 strips x 8 sub-tiles x 2 chunks; assert other <= 3,000 cyc total
  (~<100 cyc per engine transaction — hardware-loop scale, vs ~187/op firmware
  PLUS 6 ops/tile on the generic path).

Legacy zero-regression rides along: gate_67's Phase-A rail numbers must be
unchanged (a strip-FSM edit that slowed the legacy path would show here).
"""

import re
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "sim/tools"))
from gate_97_strip_stream import _build, _prepare, _run  # noqa: E402


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_strip_orchestration_tax(tmp_path):
    _prepare()
    binary = _build(tmp_path)
    _, out = _run(binary, [])          # 1-cycle SRAM: dma never the constraint
    m = re.search(r"ML_V2_BREAKDOWN mat_busy=(\d+) dma_busy=(\d+) other=(\d+)", out)
    assert m, out[-1500:]
    other = int(m.group(3))
    print(f"STRIP_ORCH mat={m.group(1)} dma={m.group(2)} other={other}")
    assert other <= 3000, f"strip orchestration tax {other} cyc (target <=3000)"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_legacy_rail_unchanged(tmp_path):
    r = subprocess.run(["python3", "-m", "pytest", "-q", "-p", "no:cacheprovider",
                        str(ROOT / "sim/gates/gate_67_ml_v2_equiv.py")],
                       cwd=ROOT, capture_output=True, text=True, timeout=1200)
    assert r.returncode == 0, r.stdout[-2000:]
