"""gate_00_spec - CPU development flow active ISA-scope gate.

This gate checks engineering facts for the active Magpie_M1 implementation:
ADR-0001 is superseded for implementation, ADR-0002 is accepted, spec.md has no
undecided fields, and ip.json agrees with the lab08e RV32IMC pipeline scope.
ADR-0003 and ADR-0004 record local RTL deviations from the lab08e source.
"""

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_adr_scope_is_superseded_to_lab08e():
    text = _read("docs/adr/0001-isa-scope.md")
    assert "Status: **superseded-for-implementation**" in text
    assert "RV32IM_Zicsr" in text
    assert "Superseded by: ADR-0002" in text
    active = _read("docs/adr/0002-pipeline-v2-ch2-integration.md")
    assert "Status: **accepted**" in active
    assert "RV32IMC + Zicsr + Zifencei" in active
    assert "lab08e" in active
    deviation = _read("docs/adr/0003-csr-external-irq-pending-collision.md")
    assert "Status: **accepted**" in deviation
    assert "local Magpie_M1 RTL deviation" in deviation
    assert "Phase 3.2 closes the current Magpie_M1 pulse contract" in deviation
    munit = _read("docs/adr/0004-m-unit-result-latch.md")
    assert "Status: **accepted**" in munit
    assert "Phase 3.5 deterministic random Spike lockstep found" in munit
    assert "local Magpie_M1 RTL" in munit


def test_spec_has_no_tbd_and_matches_active_scope():
    text = _read("design/cpu_m1/docs/spec.md")
    assert "TBD" not in text
    for required in [
        "RV32IMC_Zicsr_Zifencei",
        "M-mode only",
        "4-stage pipeline",
        "BP",
        "RAS",
        "RV32C",
        "pre-fetch",
        "valid/ready",
        "Spike",
        "Google RISC-V DV",
        "Line coverage target is 100%",
    ]:
        assert required in text


def test_ip_json_matches_spec_scope_and_interfaces():
    data = json.loads(_read("design/cpu_m1/ip.json"))
    # design_id identity is enforced by gate_00_identity_m3v (M3V line); the stale M1A
    # assertion here was removed in the M1-legacy gate cleanup (design evolved past M1A).
    assert data["kind"] == "cpu"
    assert data["flow"] == "cpu"

    interfaces = {item["name"]: item for item in data["interfaces"]}
    assert interfaces["imem"]["protocol"] == "valid-ready"
    assert interfaces["dmem"]["protocol"] == "valid-ready"
    assert interfaces["imem"]["role"] == "manager"
    assert interfaces["dmem"]["role"] == "manager"

    risks = "\n".join(data.get("risks", []))
    assert "A extension is roadmap" in risks
    assert "Spike lockstep" in risks
    assert data["active_variant"] == "v2_pipeline_ch2_lab08e"
    assert data["microarchitecture"]["kind"] == "4-stage-pipeline-bp-ras-rv32c-prefetch"
    assert data["microarchitecture"]["pipeline_stages"] == 4
    assert data["variants"]["v1_fsm"]["status"] == "superseded-for-implementation"
    assert data["variants"]["v2_pipeline_ch2_lab08b"]["status"] == "roadmap-reference-integration"
    assert data["variants"]["v2_pipeline_ch2_lab08b"]["local_rtl"] == "design/cpu_m1/rtl/variants/ch2_lab08b"
    assert data["variants"]["v2_pipeline_ch2_lab08e"]["status"] == "active-signoff-baseline"
    assert data["variants"]["v2_pipeline_ch2_lab08e"]["local_rtl"] == "design/cpu_m1/rtl"
    assert data["variants"]["v2_pipeline_ch2_lab08e"]["qualification_status"] == "not-yet-qualified"
    modifications = {
        item["file"]: item for item in data["variants"]["v2_pipeline_ch2_lab08e"]["local_modifications"]
    }
    assert modifications["design/cpu_m1/rtl/csr.v"]["adr"] == (
        "docs/adr/0003-csr-external-irq-pending-collision.md"
    )
    assert "ext_pending priority" in modifications["design/cpu_m1/rtl/csr.v"]["change"]
    assert modifications["design/cpu_m1/rtl/core.v"]["adr"] == (
        "docs/adr/0004-m-unit-result-latch.md"
    )
    assert "md_result_q" in modifications["design/cpu_m1/rtl/core.v"]["change"]
    assert data["evidence"]["verification_report"] == "docs/v2_pipeline_full_verification_report.md"
    assert data["evidence"]["rtl_deviation_adr"] == "docs/adr/0003-csr-external-irq-pending-collision.md"
    assert data["evidence"]["bug_taxonomy"] == "docs/v2_pipeline_bug_taxonomy.md"


def test_gate_map_matches_lab08e_development_flow():
    data = json.loads(_read("design/cpu_m1/ip.json"))
    expected = {
        # M1A line additions (ADR-0026: identity + Phase A planned stages, status not-run until opened)
        "m1a_identity",
        "m1a_a1_mul_throughput",
        "m1a_a2_zb_zicond",
        "m1a_a3_dtcm",
        "isa_scope",
        "pipeline_reference",
        "fetch_rv32c_prefetch",
        "decode_execute_rv32imc",
        "pipeline_hazard",
        "bp_ras_redirect",
        "phase1_closure",
        "trap_interrupt",
        "mem_wrapper",
        "spike_lockstep",
        "trap_irq_lockstep",
        "irq_collision_contract",
        "spike_comparator_lib",
        "directed_lockstep",
        "random_lockstep",
        "multi_seed_coverage",
        "muldiv_hazard",
        "coverage",
        "csr_irq_coverage",
        "bp_ras_coverage",
        "rv32c_cross_coverage",
        "illegal_munit_coverage",
        "residual_triage",
        "ras_recovery_coverage",
        "lint_synth_ppa_signoff",
    }
    assert set(data["gate_map"]) == expected
