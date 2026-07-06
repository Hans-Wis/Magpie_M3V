"""gate_10_pipeline_v2_reference - v2 Ch2 pipeline target integration gate.

This gate does not qualify the v2 pipeline as Magpie_M1 sign-off RTL. It checks
that the Ch2 lab08e practical-IP target is present, recorded in metadata, and
lint-parsable as a standalone reference core. Ch2 lab08b remains a reduced
RV32IM checkpoint.
"""

import json
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LAB08B_RTL_DIR = ROOT / "IP/cpu_m1/rtl/variants/ch2_lab08b"
LAB08E_RTL_DIR = ROOT / "IP/cpu_m1/rtl"


RTL_FILES = [
    "rfu.v",
    "alu.v",
    "idu.v",
    "ifu.v",
    "lsu.v",
    "csr.v",
    "mul.v",
    "div.v",
    "forward.v",
    "hazard.v",
    "bp.v",
    "core.v",
]

LAB08E_EXTRA_RTL_FILES = [
    "trigger.v",
    "ras.v",
    "cdec.v",
]


def _read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_adr_0002_records_pipeline_reference_scope():
    text = _read("docs/adr/0002-pipeline-v2-ch2-integration.md")
    assert "Status: **accepted**" in text
    assert "Supersedes: ADR-0001" in text
    assert "~/project/lab/CPU/Ch2/lab08e" in text
    assert "4-stage + BP + RAS + RV32C + pre-fetch" in text
    assert "~/project/lab/CPU/Ch2/lab08b" in text
    assert "not yet" in text
    assert "qualified" in text


def test_v2_reference_files_are_present():
    for name in RTL_FILES:
        assert (LAB08B_RTL_DIR / name).is_file(), name
        assert (LAB08E_RTL_DIR / name).is_file(), name
    for name in LAB08E_EXTRA_RTL_FILES:
        assert (LAB08E_RTL_DIR / name).is_file(), name

    filelist = _read("IP/cpu_m1/rtl/filelist.f")
    for name in RTL_FILES:
        assert f"IP/cpu_m1/rtl/{name}" in filelist
    for name in LAB08E_EXTRA_RTL_FILES:
        assert f"IP/cpu_m1/rtl/{name}" in filelist


def test_ip_json_records_v2_reference_variant():
    data = json.loads(_read("IP/cpu_m1/ip.json"))
    checkpoint = data["variants"]["v2_pipeline_ch2_lab08b"]
    assert checkpoint["status"] == "roadmap-reference-integration"
    variant = data["variants"]["v2_pipeline_ch2_lab08e"]
    assert variant["status"] == "active-signoff-baseline"
    assert variant["qualification_status"] == "not-yet-qualified"
    assert variant["local_rtl"] == "IP/cpu_m1/rtl"
    assert "forwarding" in variant["features"]
    assert "flush-redirect" in variant["features"]
    assert "RAS" in variant["features"]
    assert "RV32C" in variant["features"]
    assert "pre-fetch-residue-buffer" in variant["features"]
    assert variant["reported_ch2_fpga"]["clock_mhz"] == 85
    assert variant["verification_report"] == "docs/v2_pipeline_full_verification_report.md"


def test_v2_full_verification_report_requires_magpie_evidence():
    text = _read("docs/v2_pipeline_full_verification_report.md")
    lower = text.lower()
    assert "not-yet-qualified" in text
    assert "copied rtl" in lower
    assert "lint-only gate" in lower
    assert "not sufficient qualification evidence" in lower
    for required in [
        "Wrapper",
        "Directed RV32C",
        "Pre-fetch",
        "BP/RAS",
        "Hazards",
        "Flush",
        "Spike lockstep",
        "Google RISC-V DV",
        "Coverage",
        "FPGA PPA",
    ]:
        assert required in text
    assert "Line coverage target is 100%" in text
    assert "flow/v2_pipeline" in text


def test_v2_reference_verilator_lint_only():
    verilator = shutil.which("verilator") or "verilator"
    assert Path(verilator).exists(), f"verilator not found: {verilator}"
    cmd = [
        verilator,
        "--lint-only",
        "-Wall",
        "-Wno-DECLFILENAME",
        "-Wno-TIMESCALEMOD",
        "-Wno-UNUSEDSIGNAL",
        f"-I{LAB08E_RTL_DIR}",
        *[str(LAB08E_RTL_DIR / name) for name in RTL_FILES],
        *[str(LAB08E_RTL_DIR / name) for name in LAB08E_EXTRA_RTL_FILES],
        "--top-module",
        "core",
    ]
    subprocess.run(cmd, cwd=ROOT, check=True)
