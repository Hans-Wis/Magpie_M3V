"""gate_03_06_multi_seed_coverage - multi-seed lockstep and coverage gate."""

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PHASE_DIR = ROOT / "flow/v2_pipeline/phase_03_06_multi_seed_coverage"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def _line_coverage(path: Path) -> tuple[int, int, float]:
    found = 0
    hit = 0
    for line in _read(path).splitlines():
        if line.startswith("DA:"):
            found += 1
            _, payload = line.split(":", 1)
            _, count = payload.split(",", 1)
            if int(count) > 0:
                hit += 1
    return found, hit, (hit * 100.0 / found) if found else 0.0


def test_phase_03_06_artifacts_exist():
    required = [
        "README.md",
        "Makefile",
        "gen_random_program.py",
        "run_seed_sweep.py",
        "tb_random_lockstep.v",
        "multi_seed_coverage.log",
        "multi_seed_coverage_report.md",
        "seed_summary.csv",
        "coverage/merged_coverage.dat",
        "coverage/coverage.info",
        "coverage/annotated/core.v",
        "coverage/annotated/div.v",
        "coverage/annotated/mul.v",
    ]
    for name in required:
        path = PHASE_DIR / name
        assert path.exists(), f"missing Phase 3.6 artifact: {name}"
        assert path.stat().st_size > 0, f"empty Phase 3.6 artifact: {name}"


def test_phase_03_06_seed_ladder_all_passed_lockstep():
    rows = _rows(PHASE_DIR / "seed_summary.csv")
    assert [row["seed"] for row in rows] == ["20260607", "20260608", "20260609", "20260610", "20260611"]
    assert sum(int(row["commits"]) for row in rows) == 405
    for row in rows:
        assert row["count"] == "48"
        assert row["commits"] == "81"
        assert row["status"] == "pass"
        assert row["coverage_dat"] == "yes"
        run_dir = PHASE_DIR / "runs" / f"seed_{row['seed']}"
        assert "PASS: seed" in _read(run_dir / "lockstep.log")
        assert (run_dir / "dut_commit.trace").exists()
        assert (run_dir / "spike_commit.trace").exists()
        assert (run_dir / "coverage.dat").exists()


def test_phase_03_06_coverage_is_measured_not_closed():
    log = _read(PHASE_DIR / "multi_seed_coverage.log")
    report = _read(PHASE_DIR / "multi_seed_coverage_report.md")
    found, hit, percent = _line_coverage(PHASE_DIR / "coverage/coverage.info")

    assert "PASS: multi-seed lockstep matched 5 seeds / 405 commits" in log
    assert "Total coverage (647/1130) 57.00%" in log
    assert (found, hit) == (1130, 894)
    assert 79.11 < percent < 79.13
    assert "Line coverage from lcov info: 894 / 1130 (79.12%)" in report
    assert "not 100% line coverage closure" in report
    assert "uncovered lines require later reason" in report


def test_phase_03_06_runner_uses_shared_spike_comparator_and_coverage_merge():
    script = _read(PHASE_DIR / "run_seed_sweep.py")
    makefile = _read(PHASE_DIR / "Makefile")
    for required in [
        "from spike_commit import",
        "parse_dut_commits",
        "parse_spike_commits",
        "compare_commits",
        "verilator_coverage",
        "--annotate",
        "coverage.info",
    ]:
        assert required in script
    assert "--coverage" in makefile
    assert "SEEDS ?= 20260607 20260608 20260609 20260610 20260611" in makefile


def test_phase_03_06_annotated_coverage_exposes_known_gaps():
    core = _read(PHASE_DIR / "coverage/annotated/core.v")
    csr = _read(PHASE_DIR / "coverage/annotated/csr.v")
    bp = _read(PHASE_DIR / "coverage/annotated/bp.v")
    assert "%000000     input             irq_external_pulse" in core
    assert "%000000     wire        bp_predict_taken" in core
    assert "%000000" in csr
    assert "%000000" in bp
