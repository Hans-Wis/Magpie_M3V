"""gate_96_w4a8_ptq_sim — W4A8 Phase-0 simulation reproducibility.

Runs design/npu/sw/gemma/w4a8_ptq_sim.py (pure NumPy, zero RTL) and asserts the
run completes with all three sections and sane orderings:
  - grouping monotonicity: w4 per-tensor < g128 < g64 < g32 weight-SNR;
  - int8 layer SNR > every w4 variant (sanity of the harness);
  - tok/s table present with W4 g=64 above W8 at every B/cyc point.
Numbers feed docs/reports/2026-07-10_w4a8_phase0.md; this is a perf/analysis
gate, not a golden gate.
"""

import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SIM = ROOT / "design/npu/sw/gemma/w4a8_ptq_sim.py"


def test_w4a8_phase0_sim():
    r = subprocess.run(["python3", str(SIM)], cwd=SIM.parent,
                       capture_output=True, text=True, timeout=1200)
    assert r.returncode == 0, r.stdout[-2000:] + r.stderr[-2000:]
    out = r.stdout
    assert "W4A8_PTQ_SIM_DONE" in out

    def snr(name):
        m = re.search(rf"^{name}\s+(-?[\d.]+)", out, re.M)
        assert m, f"{name} row missing"
        return float(m.group(1))

    s_pt, s128, s64, s32 = (snr("w4_per_tensor"), snr("w4_g128"),
                            snr("w4_g64"), snr("w4_g32"))
    assert s_pt < s128 < s64 < s32, (s_pt, s128, s64, s32)
    assert snr("int8_per_tensor") > s32

    rows = {m.group(1): [float(x) for x in m.group(2).split()]
            for m in re.finditer(r"^(W[48] \S+|W8 \(int8\))\s+([\d. ]+)$", out, re.M)}
    assert "W8 (int8)" in rows and "W4 g=64" in rows, sorted(rows)
    w8, w4 = rows["W8 (int8)"], rows["W4 g=64"]
    assert all(a < b for a, b in zip(w8[1:], w4[1:])), (w8, w4)
    print("W4A8_PHASE0_SIM_OK")
