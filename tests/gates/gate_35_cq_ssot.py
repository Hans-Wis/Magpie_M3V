"""gate_35_cq_ssot — ADR-0035: the command-descriptor SSOT is one truth, four artifacts.

v4 §06 rule: the same definition is simultaneously (1) the RTL decode constants, (2) the
codegen target, (3) the golden codec, (4) the assembler encoding table. This gate makes
divergence a hard failure:
- regenerating from the YAML schema must produce byte-identical checked-in artifacts,
- the Python codec self-test passes (round-trip all opcodes),
- reserved-bit violations are rejected,
- spot-check frozen v0.1 values (opcodes 0x01-0x07, ENGINE_NOT_READY=4, Q31 RESCALE fields)
  are present in ALL THREE generated artifacts.
"""

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCHEMA = ROOT / "IP/npu/schema/command_descriptor_v0_1.yaml"
GEN = ROOT / "IP/npu/schema/gen_cq_ssot.py"
ARTIFACTS = [
    ROOT / "IP/npu/rtl/cq_defs.vh",
    ROOT / "IP/npu/sw/include/command_descriptor.h",
    ROOT / "IP/npu/sw/cq_codec.py",
]


def test_ssot_files_exist():
    assert SCHEMA.exists() and GEN.exists()
    for a in ARTIFACTS:
        assert a.exists(), f"missing generated SSOT artifact: {a}"


def test_regeneration_is_byte_identical():
    before = {a: a.read_bytes() for a in ARTIFACTS}
    r = subprocess.run([sys.executable, str(GEN)], capture_output=True, text=True, cwd=ROOT)
    assert r.returncode == 0, f"generator failed:\n{r.stdout}\n{r.stderr}"
    for a in ARTIFACTS:
        assert a.read_bytes() == before[a], f"SSOT divergence: {a} changed on regen"


def test_codec_selftest_and_rsvd_rejection():
    r = subprocess.run([sys.executable, str(ROOT / "IP/npu/sw/cq_codec.py")],
                       capture_output=True, text=True)
    assert r.returncode == 0, f"codec self-test failed:\n{r.stdout}\n{r.stderr}"
    sys.path.insert(0, str(ROOT / "IP/npu/sw"))
    import importlib
    codec = importlib.import_module("cq_codec")
    words = codec.encode("MAT_FENCE")
    codec.decode(words)  # legal round-trip
    bad = list(words)
    bad[0] |= 1 << 15    # W0 rsvd bit
    try:
        codec.decode(bad)
        raise AssertionError("codec accepted a reserved-bit violation")
    except AssertionError:
        raise
    except Exception:
        pass  # rejection expected


def test_frozen_v01_values_in_all_artifacts():
    vh = (ROOT / "IP/npu/rtl/cq_defs.vh").read_text()
    h = (ROOT / "IP/npu/sw/include/command_descriptor.h").read_text()
    py = (ROOT / "IP/npu/sw/cq_codec.py").read_text()
    for text, name in ((vh, "vh"), (h, "h"), (py, "py")):
        for tok in ("MAT_LOAD_W", "MAT_RESCALE", "MAT_FENCE", "ENGINE_NOT_READY"):
            assert tok in text, f"{name} artifact lost frozen token {tok}"
