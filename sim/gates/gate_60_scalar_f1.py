"""gate_60_scalar_f1 — ADR-0050 F1: scalar F foundation (RV32IMF row-1 opener).

fexu (F regfile + combinational F1 ops at EX, WB commit under the scalar kill
rules) + the fcsr contract built as a mirror of the proven vector-CSR
machinery: fflags sticky-accrual at WB with age-ordered ID-read overlays,
eff-frm through MEM+WB csr windows, mstatus.FS dirty (SD folded), same-addr
and cross-alias forwarding in both csr.v (WB window) and core.v (MEM window).
flw/fsw ride the existing scalar LSU (idu now classifies f3=010 FP-mem as a
real word load/store; rd_we suppressed for flw); a conservative F-reg RAW
stall mirrors the vector rule. F-reg writes surface in the commit trace as
rd = 64+f rows and are compared BIT-EXACT against Spike --isa=rv32imf...
(the RVFI trace port gained rvfi_f_valid/f_rd/f_wdata).

F1 coverage (directed, 135 commits, all Spike-matched): flw/fsw roundtrips,
sign-injection incl. NaN payloads, feq(sNaN-only NV) vs flt/fle(any-NaN NV),
fmin/fmax IEEE-2019 rules (+-0 ordering, single-sNaN, both-NaN canonical),
the full fclass grid, fcvt.w[u].s across every rounding mode with
NaN/inf/overflow saturation + NV/NX, fcvt.s.w[u] exact/inexact, dynamic rm
resolving the forwarded frm, fcsr aliasing, FS dirty in mstatus.
F2 (fadd/fsub/fmul), F3 (FMA), F4 (fdiv/fsqrt) are deferred-illegal.
"""

import re
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_22_vector_csr_lockstep"


def _run(target, min_commits):
    r = subprocess.run(["make", "-C", str(PHASE), target],
                       capture_output=True, text=True)
    assert r.returncode == 0, f"{target} failed:\n{r.stdout[-3000:]}"
    m = re.search(r"PASS: vcsr-lockstep matched (\d+) commits", r.stdout)
    assert m and int(m.group(1)) >= min_commits, r.stdout[-1500:]


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_f1_directed_lockstep():
    _run("f1", 130)


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_vector_targets_survive_the_f_isa():
    # the ISA string gained F (mstatus.FS exists on both sides) — the whole
    # vector chain must stay bit-identical
    for tgt, bar in (("grid", 140), ("vill", 40), ("vrand", 1200), ("pool", 150)):
        _run(tgt, bar)


def test_isa_string_carries_f():
    s = (PHASE / "vcsr_lockstep.py").read_text()
    assert "rv32imf_zve32x" in s, "green-wash guard: the ISA string itself"
