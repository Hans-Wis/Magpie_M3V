"""gate_03_09_riscvdv_lockstep - riscv-dv Spike lockstep scope."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE = ROOT / "flow/v2_pipeline/phase_03_09_riscvdv_lockstep"
SUMMARY = PHASE / "riscvdv_lockstep_summary.json"
RESULTS = [
    ROOT / "flow/v2_pipeline/phase_05_leader/J19_result.md",
    ROOT / "flow/v2_pipeline/phase_05_leader/J18_result.md",
    ROOT / "flow/v2_pipeline/phase_05_leader/J16_result.md",
    ROOT / "flow/v2_pipeline/phase_05_leader/J15_result.md",
    ROOT / "flow/v2_pipeline/phase_05_leader/J13_result.md",
    ROOT / "flow/v2_pipeline/phase_05_leader/J12_result.md",
    ROOT / "flow/v2_pipeline/phase_05_leader/J11_result.md",
]


def test_phase_03_09_artifacts_exist():
    for path in [
        PHASE / "run_riscvdv_lockstep.py",
        PHASE / "tb_riscvdv_lockstep.v",
        PHASE / "firmware.lds",
        PHASE / "config/m1_riscvdv/testlist.yaml",
        PHASE / "config/m1_riscvdv/riscv_core_setting.sv",
        SUMMARY,
    ]:
        assert path.exists(), f"missing J11 artifact: {path}"
        assert path.stat().st_size > 0, f"empty J11 artifact: {path}"
    assert any(path.exists() and path.stat().st_size > 0 for path in RESULTS), "missing riscv-dv result artifact"


def test_phase_03_09_isa_scope_is_m1_safe():
    testlist = (PHASE / "config/m1_riscvdv/testlist.yaml").read_text(encoding="utf-8")
    setting = (PHASE / "config/m1_riscvdv/riscv_core_setting.sv").read_text(encoding="utf-8")
    runner = (PHASE / "run_riscvdv_lockstep.py").read_text(encoding="utf-8")
    for required in [
        "--no_data_page=0",
        "--no_csr_instr=0",
        "--no_fence=0",          # P1/bar-B-minus: FENCE/FENCE.I (Zifencei) now IN scope (ADR-0012)
        "--enable_interrupt=0",  # async IRQ still excluded (deferred to Gold SKU, ADR-0012)
        "--no_ebreak=1",
        "--illegal_instr_ratio=0",
        "--enable_unaligned_load_store=1",
        "--bare_program_mode=0",
    ]:
        assert required in testlist
    assert "--no_load_store=1" not in testlist
    assert "--no_branch_jump=1" not in testlist
    assert "--no_fence=1" not in testlist  # fence must be enabled for bar-B-minus
    assert "RV32I, RV32M, RV32C" in setting
    assert "FENCE_I" in setting and "EBREAK" in setting
    assert "rv32imc_zicsr_zifencei" in runner
    assert "SPIKE_PC_BASE = 0x1000" in runner
    assert "normalize_wdata_base=False" in runner


def test_phase_03_09_result_is_honest_and_sufficient():
    data = json.loads(SUMMARY.read_text(encoding="utf-8"))
    result_path = next(path for path in RESULTS if path.exists())
    result = result_path.read_text(encoding="utf-8")
    assert data["status"] in {"PASS", "DIVERGENCE-FOUND", "INCOMPLETE"}
    assert result_path.name in {"J19_result.md", "J18_result.md", "J16_result.md"}
    assert "## summary" in result or "## root_cause" in result
    assert "## scope" in result or "## trap_handler" in result
    assert "## divergences" in result or "## divergences_found" in result
    assert "## revalidate" in result or "## gate_status" in result
    assert "sync-trap" in result
    assert "interrupts" in result
    assert "CSR" in result
    assert "RV32M" in result or "M" in result
    scope = data.get("scope", {})
    excluded = " ".join(scope.get("excluded", []))
    included = " ".join(scope.get("included", []))
    assert "sync-trap" in included
    assert "interrupt" in excluded
    assert "CSR" in included

    unresolved_real = data.get("unresolved_real_dut_divergences", 0)
    has_100k = data["total_matched_commits"] >= 100000
    if has_100k and unresolved_real == 0:
        assert data["status"] == "PASS"
        assert sum(1 for row in data["seeds"] if row["ok"]) >= 2
        assert "PASS" in result
    else:
        assert data["status"] in {"DIVERGENCE-FOUND", "INCOMPLETE"}
        if data["status"] == "DIVERGENCE-FOUND":
            bad = [row for row in data["seeds"] if not row["ok"]]
            assert bad, "DIVERGENCE-FOUND requires a failing seed row"
            assert (PHASE / "divergence").exists()
            assert "DIVERGENCE" in result
        else:
            assert data["total_matched_commits"] < 100000
            assert "INCOMPLETE" in result
