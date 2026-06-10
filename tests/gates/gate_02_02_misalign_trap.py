"""gate_02_02_misalign_trap - directed misaligned load/store trap gate."""

from __future__ import annotations

import csv
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_02_02_misalign"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def _rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def test_phase_02_02_rebuild_run_and_spike_compare():
    res = subprocess.run(["make", "-C", str(PHASE), "clean", "all"], capture_output=True, text=True)
    out = res.stdout + res.stderr
    assert res.returncode == 0, out[-4000:]
    assert "PASS: misalign trap observed 3 precise traps" in out
    assert "PASS: Spike trap-on-misaligned observed lw:mcause=4" in out


def test_phase_02_02_artifacts_and_firmware_intent():
    for name in [
        "Makefile",
        "firmware.S",
        "firmware.lds",
        "firmware_spike.lds",
        "tb_misalign_trap.v",
        "spike_misalign.py",
        "firmware.hex",
        "firmware.disasm",
        "sim.log",
        "spike_lw.log",
        "spike_lh.log",
        "spike_sh.log",
        "misalign_events.csv",
        "misalign_trap.log",
    ]:
        path = PHASE / name
        assert path.is_file(), f"missing artifact: {name}"
        assert path.stat().st_size > 0, f"empty artifact: {name}"

    source = _read(PHASE / "firmware.S")
    for needle in ["lb   x12, 0(x10)", "sb   x13, 0(x10)", "lw   x15, 1(x10)", "lh   x16, 1(x10)", "sh   x17, 1(x10)"]:
        assert needle in source


def test_phase_02_02_observed_mcause_mtval_and_no_bad_dbus():
    rows = _rows(PHASE / "misalign_events.csv")
    assert len(rows) == 3
    expected = [
        ("load", "00000004"),
        ("load", "00000004"),
        ("store", "00000006"),
    ]
    mtvals = {row["mtval"] for row in rows}
    assert len(mtvals) == 1
    assert next(iter(mtvals)) != "00000000"
    for row, (kind, mcause) in zip(rows, expected):
        assert row["kind"].strip() == kind
        assert row["mcause"] == mcause
        assert int(row["mtval"], 16) & 0x3 == 1

    sim_log = _read(PHASE / "sim.log")
    assert "MARK aligned_byte_no_trap" in sim_log
    assert "FAIL: misaligned DBUS request" not in sim_log
    assert "no misaligned DBUS request" in sim_log


def test_phase_02_02_spike_was_trap_on_misaligned():
    checker = _read(PHASE / "spike_misalign.py")
    assert '"--misaligned"' not in checker.split("cmd = [", 1)[1].split("]", 1)[0]
    assert "trap_load_address_misaligned" in _read(PHASE / "spike_lw.log")
    assert "trap_load_address_misaligned" in _read(PHASE / "spike_lh.log")
    assert "trap_store_address_misaligned" in _read(PHASE / "spike_sh.log")
