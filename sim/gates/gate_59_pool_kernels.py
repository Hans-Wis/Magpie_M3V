"""gate_59_pool_kernels — ADR-0049 S4: POOL runtime kernels, the Phase-A close.

MAX_POOL_2D and AVERAGE_POOL_2D int8 (2x2 stride-2 VALID on [1,4,4,8]) run as
RVV kernels on the NPU core, built ONLY from the Phase-A primitives:
max = vle8/vmax/vse8; avg = widen-sum (vwmul-by-1 + vwadd.wv), a sign-fix
(+2, and -1 masked on negative lanes via vmslt) and vnclip>>2 under vxrm=rdn
— which reproduces TFLM's round-half-AWAY exactly (LEMMA 1, proved
exhaustively over every reachable sum at kernel-generation time; a plain
vssra/vnclip rounding mode cannot).

Authority chain: TFLite BUILTIN_REF interpreter (offline, real .tflite
pooling ops) -> checked-in golden; the kernel run is Spike-lockstep verified
end to end AND its output probes (lw commits in the trace) must equal the
golden words. LEMMA 2 ties the embedded DTCM tile to the gate_51-verified
strided-DMA gather semantics (the DMA path is equivalent to the image the
kernel consumes). Scope: full windows only (VALID; edge-partial counts are
out of the 2x2s2 shape), recorded.
"""

import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_22_vector_csr_lockstep"
sys.path.insert(0, str(ROOT / "sim/models"))
import pool_kernel  # noqa: E402


def test_lemmas_hold():
    pool_kernel.lemma1_signfix_equals_half_away()
    g = json.loads((pool_kernel.ART / "pool_golden.json").read_text())
    pool_kernel.lemma2_gather_matches_numpy(g["input"][0])


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_pool_kernels_lockstep_and_tflm_exact():
    pool_kernel.emit_firmware(PHASE / "firmware_pool.S")
    r = subprocess.run(["make", "-C", str(PHASE), "pool"],
                       capture_output=True, text=True)
    assert r.returncode == 0, r.stdout[-3000:]
    m = re.search(r"PASS: vcsr-lockstep matched (\d+) commits", r.stdout)
    assert m and int(m.group(1)) >= 150, r.stdout[-1500:]

    exp = pool_kernel.expected_words()
    lws = []
    for line in (PHASE / "dut_commit.trace").read_text().splitlines():
        f = line.split(",")
        if len(f) == 5 and f[0].isdigit():
            insn = int(f[2], 16)
            if (insn & 0x7F) == 0x03 and ((insn >> 12) & 0x7) == 2:  # lw
                lws.append(int(f[4], 16))
    assert len(lws) >= 16, "probe lw commits missing from the trace"
    assert lws[-16:] == exp, "RTL pool outputs != TFLM reference golden"


def test_pool_artifact_provenance_regen(tmp_path):
    env = dict(os.environ,
               LD_LIBRARY_PATH=os.path.join(os.environ.get("CONDA_PREFIX", ""), "lib"))
    probe = subprocess.run([sys.executable, "-c", "import tensorflow"],
                           env=env, capture_output=True)
    if probe.returncode != 0:
        pytest.skip("tensorflow unavailable — provenance not-run")
    src = ROOT / "sim/models"
    work = tmp_path / "aot"
    shutil.copytree(src, work, ignore=shutil.ignore_patterns("artifacts"))
    r = subprocess.run([sys.executable, str(work / "build_pool.py")],
                       env=env, capture_output=True, text=True, timeout=600)
    assert r.returncode == 0, r.stderr[-2000:]
    assert json.loads((work / "artifacts/pool_golden.json").read_text()) == \
           json.loads((src / "artifacts/pool_golden.json").read_text())
