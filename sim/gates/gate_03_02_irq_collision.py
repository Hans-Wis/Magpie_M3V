"""gate_03_02_irq_collision - directed IRQ collision contract gate."""

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE_DIR = ROOT / "flow/v2_pipeline/phase_03_02_irq_collision"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def _read_head(path: Path, size: int = 4096) -> str:
    with path.open("rb") as fh:
        return fh.read(size).decode("utf-8", errors="replace")


def test_phase_03_02_artifacts_exist():
    required = [
        "README.md",
        "Makefile",
        "firmware.S",
        "firmware.lds",
        "tb_irq_collision.v",
        "firmware.hex",
        "firmware.disasm",
        "firmware.elf",
        "sim.log",
        "irq_collision.trace",
        "wave.vcd",
    ]
    for name in required:
        path = PHASE_DIR / name
        assert path.exists(), f"missing Phase 3.2 artifact: {name}"
        assert path.stat().st_size > 0, f"empty Phase 3.2 artifact: {name}"


def test_phase_03_02_collision_trace_contract():
    rows = _rows(PHASE_DIR / "irq_collision.trace")
    by_event = {}
    for row in rows:
        by_event.setdefault(row["event"], []).append(row)

    assert len(by_event["inject_initial"]) == 1
    assert len(by_event["inject_samecycle"]) == 1
    assert len(by_event["inject_delayed"]) == 1
    assert len(by_event["irq_entry"]) == 2
    assert len(by_event["mepc_store"]) == 2
    assert len(by_event["mret"]) == 2
    assert len(by_event["resume"]) == 1

    first_irq, second_irq = by_event["irq_entry"]
    assert first_irq["idx"] == "1"
    assert first_irq["pc"] == "00000080"
    assert first_irq["value"] == "00000082"
    assert second_irq["idx"] == "2"
    assert int(second_irq["value"], 16) > 0x82

    samecycle = by_event["inject_samecycle"][0]
    assert samecycle["idx"] == "1"
    delayed = by_event["inject_delayed"][0]
    assert delayed["idx"] == "1"


def test_phase_03_02_logs_and_docs_record_contract():
    sim_log = _read(PHASE_DIR / "sim.log")
    readme = _read(PHASE_DIR / "README.md")
    adr = _read(ROOT / "docs/adr/0003-csr-external-irq-pending-collision.md")
    taxonomy = _read(ROOT / "docs/v2_pipeline_bug_taxonomy.md")

    assert "PASS: IRQ collision contract validated" in sim_log
    assert "same cycle as `trap_enter` is treated as acknowledged" in readme
    assert "pulse sampled after `trap_enter`" in readme
    assert "a pulse sampled in the same cycle as `trap_enter`" in adr
    assert "a pulse sampled after `trap_enter`" in adr
    assert "RISK-IRQ-0002" in taxonomy


def test_phase_03_02_vcd_has_review_signals():
    vcd_head = _read_head(PHASE_DIR / "wave.vcd")
    for required in [
        "$scope module tb_irq_collision",
        "irq_external_pulse",
        "irq_entry_count",
        "handler_store_count",
        "injected_samecycle_pulse",
        "injected_delayed_pulse",
        "first_mepc",
        "second_mepc",
        "dbg_pc",
        "dbg_instr",
    ]:
        assert required in vcd_head
