"""gate_93_sim_benchmark_harness — ADR-0064: /sim benchmark harness consistency.

Guards the harness SSOT without re-running the sims (the 4 rtl_e2e benches are gated by
gate_48/49/50/82 already). Checks:
  - bench.yaml parses; every rtl_e2e:true benchmark names an existing gate file;
  - every not-run benchmark names a blocker (honest — no silent green);
  - the committed functional_matrix.json agrees with bench.yaml on which are rtl_e2e.

Authority (G1/honest-界): functional correctness = the per-bench gate's Spike/BUILTIN_REF
bit-exact proof; this gate only guards the harness bookkeeping.
"""
import json
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
BENCH = ROOT / "sim/bench.yaml"
MATRIX = ROOT / "sim/functional_matrix.json"
GATES = ROOT / "tests/gates"


def _specs():
    return yaml.safe_load(BENCH.read_text())["benchmarks"]


def test_bench_yaml_parses_and_has_all_four_families():
    fams = {s["family"] for s in _specs()}
    for expect in ("cnn", "mobilenet", "mlperf_tiny", "llm"):
        assert expect in fams, f"bench.yaml missing family {expect}"


def test_rtl_e2e_benches_name_existing_gates():
    for s in _specs():
        if s.get("rtl_e2e"):
            assert (GATES / s["gate"]).exists(), f"{s['id']} gate {s['gate']} missing"


def test_not_run_benches_name_a_blocker():
    # honest-界: nothing is silently 'not-run' — each must state why.
    for s in _specs():
        if not s.get("rtl_e2e"):
            assert s.get("blocker"), f"{s['id']} is not-run but names no blocker"


def test_functional_matrix_matches_ssot():
    assert MATRIX.exists(), "run sim/run_bench.py --json sim/functional_matrix.json"
    rows = {r["id"]: r for r in json.loads(MATRIX.read_text())}
    for s in _specs():
        assert s["id"] in rows, f"{s['id']} missing from functional_matrix.json"
        assert rows[s["id"]]["rtl_e2e"] == s.get("rtl_e2e"), f"{s['id']} rtl_e2e drift"
    # the 4 CNN-class rtl_e2e benches must be recorded bit-exact (not FAIL)
    for bid in ("tflm_fc", "tflm_mlp", "cnn_conv_fc", "mobilenet_block"):
        assert "FAIL" not in rows[bid]["status"], f"{bid} regressed: {rows[bid]['status']}"
