"""gate_02_03_mepc_directed - directed mepc precision and WARL mask gate."""

from pathlib import Path
import subprocess


ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_02_03_mepc_directed"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def test_phase_02_03_rebuild_run_and_observe_precise_mepc():
    res = subprocess.run(["make", "-C", str(PHASE), "clean", "all"], capture_output=True, text=True)
    out = res.stdout + res.stderr
    assert res.returncode == 0, out[-4000:]
    assert "PASS: directed mepc CSR mask and synchronous trap precision completed" in out


def test_phase_02_03_artifacts_and_firmware_intent():
    for name in [
        "Makefile",
        "README.md",
        "firmware.S",
        "firmware.lds",
        "tb_mepc_directed.v",
        "firmware.hex",
        "firmware.disasm",
        "sim.log",
        "mepc_directed.log",
        "wave.vcd",
    ]:
        path = PHASE / name
        assert path.is_file(), f"missing artifact: {name}"
        assert path.stat().st_size > 0, f"empty artifact: {name}"

    source = _read(PHASE / "firmware.S")
    for needle in [
        "csrw mepc, x5",
        "csrr x6, mepc",
        ".word 0xffffffff",
        ".2byte 0x0000",
        "ebreak",
        "lw   x9, 1(x5)",
        "csrr x14, mepc",
    ]:
        assert needle in source


def test_phase_02_03_observed_expected_values():
    log = _read(PHASE / "sim.log")
    assert "CSR mepc write/read observed=00000082 expected=00000082" in log
    for idx, pc in enumerate(["00000080", "0000008e", "00000098", "000000a0", "000000a8"]):
        assert f"RESULT idx={idx} observed_mepc={pc} expected_mepc={pc} handler_mepc={pc}" in log
    for cause in ["mcause=00000002", "mcause=00000003", "mcause=00000004"]:
        assert cause in log
