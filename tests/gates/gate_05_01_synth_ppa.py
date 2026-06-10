"""gate_05_01_synth_ppa - advisory DC PPA trial artifact gate."""

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE_DIR = ROOT / "flow/v2_pipeline/phase_05_01_synth_ppa"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def _summary_value(text: str, key: str) -> str:
    match = re.search(rf"^{re.escape(key)}=(.*)$", text, re.MULTILINE)
    assert match, f"missing synth summary key: {key}"
    return match.group(1).strip()


def test_phase_05_01_artifacts_exist():
    required = [
        "files.f",
        "run_dc.tcl",
        "library_search_evidence.txt",
        "dc_shell.log",
        "dc_stdout.log",
        "provenance.log",
        "ppa_summary.txt",
    ]
    for name in required:
        path = PHASE_DIR / name
        assert path.exists(), f"missing Phase 5.1 synth artifact: {name}"
        assert path.stat().st_size > 0, f"empty Phase 5.1 synth artifact: {name}"


def test_phase_05_01_filelist_top_and_library():
    filelist = _read(PHASE_DIR / "files.f")
    tcl = _read(PHASE_DIR / "run_dc.tcl")
    evidence = _read(PHASE_DIR / "library_search_evidence.txt")
    assert "+incdir+../../../IP/cpu_m1/rtl" in filelist
    assert "../../../IP/cpu_m1/rtl/cpu_m1_top.v" in filelist
    assert "set top_name cpu_m1_top" in tcl
    assert "compile_ultra" in tcl
    assert "tcbn28hpcplusbwp40p140tt0p9v25c.db" in tcl
    assert "search_2_selected=/home/edauser/project/SOC/Magpie_X3/APR/ref/db/tcbn28hpcplusbwp40p140tt0p9v25c.db" in evidence


def test_phase_05_01_trial_ppa_or_waiver_recorded():
    summary = _read(PHASE_DIR / "ppa_summary.txt")
    status = _summary_value(summary, "status")
    assert status in {"trial_pass", "waived_unavailable"}
    assert _summary_value(summary, "top") == "cpu_m1_top"
    assert _summary_value(summary, "trial_estimate") == "true"
    if status == "trial_pass":
        assert float(_summary_value(summary, "area_um2")) > 0.0
        assert float(_summary_value(summary, "target_period_ns")) > 0.0
        assert re.match(r"^-?\d+(\.\d+)?$", _summary_value(summary, "wns_ns"))
        assert re.match(r"^-?\d+(\.\d+)?$", _summary_value(summary, "tns_ns"))
        assert float(_summary_value(summary, "total_power_mw")) >= 0.0
        for report in ["reports/area.rpt", "reports/timing.rpt", "reports/power.rpt", "reports/qor.rpt"]:
            path = PHASE_DIR / report
            assert path.exists(), f"missing DC report: {report}"
            assert path.stat().st_size > 0, f"empty DC report: {report}"
    else:
        assert "waiver_reason=" in summary


def test_phase_05_01_provenance_records_dc_license():
    provenance = _read(PHASE_DIR / "provenance.log")
    for required in [
        "dc_shell_version=X-2025.06-SP2",
        "license_outcome=",
        "dc_shell -f run_dc.tcl",
        "target_library=/home/edauser/project/SOC/Magpie_X3/APR/ref/db/tcbn28hpcplusbwp40p140tt0p9v25c.db",
    ]:
        assert required in provenance
