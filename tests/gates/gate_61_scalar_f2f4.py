"""gate_61_scalar_f2f4 — ADR-0050 F2-F4: full RV32IMF arithmetic (row-1 close).

fadd/fsub/fmul (F2), fmadd/fmsub/fnmadd/fnmsub (F3), fdiv/fsqrt (F4) in fexu
as faithful Berkeley softfloat-3 transcriptions (Spike's own float authority):
roundPackToF32 with tininess-after-rounding, addMags/subMags, mul via
shortShiftRightJam64, mulAdd 64-bit aligned-sum single-rounding path, div via
full-width quotient + remainder-jam sticky, sqrt via restoring integer sqrt.
All combinational at sim level (the multi-cycle F4 plan is deferred to the
Phase 7 timing pass — recorded as an ADR-0050 deviation).

Evidence: f2 directed corners (Grok list — every static+dynamic rm, NaN
propagation, inf∓inf, 0×inf, overflow/underflow ladders per rm, fused-vs-split
FMA incl. massive exponent deltas and 0×inf+qNaN, div DZ/NV/subnormal-quotient,
sqrt exact/NX/NV) + multi-seed random corpora — every f-write bit-exact and
every fflags probe exact vs Spike --isa=rv32imf_zve32x...
"""

import re
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_22_vector_csr_lockstep"

needs_verilator = pytest.mark.skipif(
    not shutil.which("verilator"), reason="no verilator — not-run")


def _run(target, min_commits, extra=()):
    r = subprocess.run(["make", "-C", str(PHASE), target, *extra],
                       capture_output=True, text=True)
    assert r.returncode == 0, f"{target} failed:\n{r.stdout[-3000:]}"
    m = re.search(r"PASS: vcsr-lockstep matched (\d+) commits", r.stdout)
    assert m and int(m.group(1)) >= min_commits, r.stdout[-1500:]


@needs_verilator
def test_f2f4_directed_corners():
    _run("f2", 290)


def test_f2_covers_equal_exponent_cancellation():
    # green-wash guard: random floats almost never share an exponent, so the
    # Sterbenz-exact renormalizing subMags path (the pack-carry bug Codex
    # caught) must be pinned by explicit directed stimulus
    s = (PHASE / "firmware_f2.S").read_text()
    assert "0x3FC00000" in s and "0x3FA00000" in s, "missing 1.5-1.25 cancellation"


@needs_verilator
def test_frand_multi_seed():
    # arithmetic-heavy random corpora (specials-dense generator) across seeds;
    # ~1000+ commits each, all f-writes + fflags probes bit-exact vs Spike
    for seed in ("20260705", "7", "12345"):
        _run("frand", 900, extra=(f"FSEED={seed}", "FBLOCKS=40"))


def test_f2_stimulus_is_directed_not_generated():
    # green-wash guard: the corner file must exercise div/sqrt/fma explicitly
    s = (PHASE / "firmware_f2.S").read_text()
    for op in ("fdiv.s", "fsqrt.s", "fmadd.s", "fnmsub.s", "frflags"):
        assert op in s, f"missing {op} in directed corners"
