"""gate_01_99_phase1_closure - Phase 1 structural bring-up closure gate.

This gate closes Phase 1 as structural bring-up complete. It explicitly does not
qualify the CPU IP; directed tests, Spike, coverage, and sign-off remain later
phases.
"""

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


PHASE1_GATES = {
    "pipeline_reference": "gates/gate_10_pipeline_v2_reference.py",
    "fetch_rv32c_prefetch": "gates/gate_01_01_fetch_rv32c_prefetch.py",
    "decode_execute_rv32imc": "gates/gate_01_02_decode_execute_rv32imc.py",
    "pipeline_hazard": "gates/gate_01_03_pipeline_hazard.py",
    "bp_ras_redirect": "gates/gate_01_04_bp_ras_redirect.py",
    "phase1_closure": "gates/gate_01_99_phase1_closure.py",
}


PHASE1_ARTIFACTS = [
    "docs/phase1_closure_report.md",
    "docs/vcd_review_policy.md",
    "docs/v2_pipeline_full_verification_report.md",
    "flow/v2_pipeline/phase_01_01_fetch_rv32c_prefetch/vcd_manifest.md",
    "flow/v2_pipeline/phase_01_01_fetch_rv32c_prefetch/sim.log",
    "flow/v2_pipeline/phase_01_01_fetch_rv32c_prefetch/wave.vcd",
    "flow/v2_pipeline/phase_01_02_decode_execute_rv32imc/README.md",
    "flow/v2_pipeline/phase_01_03_pipeline_hazard/README.md",
    "flow/v2_pipeline/phase_01_04_bp_ras_redirect/README.md",
    "flow/v2_pipeline/phase_01_99_phase1_closure/README.md",
]


def _read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def _json(path: str):
    return json.loads(_read(path))


def test_phase1_gate_map_is_hierarchical_and_complete():
    data = _json("IP/cpu_m1/ip.json")
    gate_map = data["gate_map"]
    for key, path in PHASE1_GATES.items():
        assert gate_map[key] == path
        assert (ROOT / path).is_file()

    text = json.dumps(gate_map)
    for stale in [f"gate_{idx}" for idx in range(12, 21)]:
        assert stale not in text


def test_phase1_required_artifacts_exist():
    for rel in PHASE1_ARTIFACTS:
        path = ROOT / rel
        assert path.exists(), rel
        assert path.stat().st_size > 0, rel


def test_phase1_closure_report_has_clear_scope_and_residual_transfer():
    text = _read("docs/phase1_closure_report.md")
    for required in [
        "phase1-structural-closure-pass / not CPU-qualified",
        "structural bring-up complete",
        "does not mean the CPU IP is functionally qualified",
        "Residuals Transferred Out Of Phase 1",
        "Phase 2.0",
        "Phase 2.1",
        "Phase 3.0",
        "Phase 4.0",
        "Phase 5.0",
        "not-yet-qualified",
    ]:
        assert required in text


def test_full_verification_report_records_phase1_closure_without_overclaiming():
    text = _read("docs/v2_pipeline_full_verification_report.md")
    for required in [
        "Phase 1 Closure",
        "Phase 1 structural bring-up is closed",
        "not CPU-qualified",
        "docs/phase1_closure_report.md",
        "Directed RV32I/M",
        "not-run",
        "Spike lockstep",
        "Coverage",
    ]:
        assert required in text


def test_phase1_vcd_policy_is_per_phase_and_not_over_simplified():
    policy = _read("docs/vcd_review_policy.md")
    manifest = _read("flow/v2_pipeline/phase_01_01_fetch_rv32c_prefetch/vcd_manifest.md")
    for required in [
        "Every simulation phase that produces a VCD must provide a phase-local",
        "review questions",
        "required signals",
        "full-debug",
        "Phase 1.1",
        "Phase 1.2",
        "Phase 1.3",
        "Phase 1.4",
    ]:
        assert required in policy

    for required in [
        "Review Questions",
        "Required Signals",
        "Dump Windows",
        "Size Envelope",
        "Known Blind Spots",
        "TRACE_DEPTH=5 REVIEW_TRACE=0 RUN_ARGS=+full_vcd",
    ]:
        assert required in manifest


def test_phase1_state_records_closure_and_non_qualification():
    state = _json("flow/state/magpie_m1.isa_scope.state.json")
    metrics = state["metrics"]
    assert state["stage"] in {
        "phase1_closure",
        "trap_interrupt",
        "spike_lockstep",
        "trap_irq_lockstep",
        "irq_collision_contract",
        "spike_comparator_lib",
        "directed_lockstep",
        "random_lockstep",
        "multi_seed_coverage",
        "muldiv_hazard",
        "coverage_residual",
        "csr_irq_coverage",
        "bp_ras_coverage",
        "rv32c_cross_coverage",
        "illegal_munit_coverage",
            "residual_triage",
            "ras_recovery_coverage",
            "csr_idu_residual_coverage",
        }
    assert metrics["phase_01_99_phase1_closure_gate"] == "gates/gate_01_99_phase1_closure.py"
    assert metrics["phase_01_99_phase1_closure_status"] == "pass"
    assert metrics["phase_01_99_phase1_closure_result"] == "structural-bringup-complete-not-qualified"
    assert metrics["v2_pipeline_status"] == "active-signoff-baseline-not-yet-qualified"
    assert metrics["phase_01_02_decode_execute_rv32imc_directed_sim"] == "not-run"
    assert metrics["phase_01_03_pipeline_hazard_directed_sim"] == "not-run"
    assert metrics["phase_01_04_bp_ras_redirect_directed_sim"] == "not-run"
    assert metrics["phase_01_04_bp_ras_redirect_spike"] == "not-run"


def test_phase1_smoke_artifacts_are_current_and_reviewable():
    sim_log = _read("flow/v2_pipeline/phase_01_01_fetch_rv32c_prefetch/sim.log")
    assert "PASS:" in sim_log
    assert "BTN1 IRQ reset observed" in sim_log

    vcd = ROOT / "flow/v2_pipeline/phase_01_01_fetch_rv32c_prefetch/wave.vcd"
    size_mb = vcd.stat().st_size / (1024 * 1024)
    assert 0.1 < size_mb < 50
