#!/usr/bin/env python3
"""run_bench — ADR-0064 /sim unified benchmark runner.

Reads bench.yaml (SSOT), runs the rtl_e2e benches through their gates (Verilator + Spike/
BUILTIN_REF bit-exact), and emits an HONEST functional-correctness matrix. not-run stays
not-run (blocker named). Authority = Spike lockstep + bit-accurate golden (G1: functional
correctness, not a coverage number).

Usage:
  run_bench.py                 # run all rtl_e2e benches, print matrix
  run_bench.py <id> ...        # run specific benchmark(s)
  run_bench.py --json OUT      # also write the matrix JSON
"""
import argparse
import json
import subprocess
import sys
import time
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
BENCH = Path(__file__).resolve().parent / "bench.yaml"
GATES = ROOT / "sim/gates"


def run_gate(gate):
    """Run one gate via pytest; return (passed, seconds, tail)."""
    t0 = time.time()
    r = subprocess.run([sys.executable, "-m", "pytest", str(GATES / gate), "-q"],
                       cwd=ROOT, capture_output=True, text=True, timeout=900)
    dt = time.time() - t0
    ok = r.returncode == 0
    tail = (r.stdout or "")[-300:]
    return ok, dt, tail


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("ids", nargs="*")
    ap.add_argument("--json")
    a = ap.parse_args()
    specs = yaml.safe_load(BENCH.read_text())["benchmarks"]
    if a.ids:
        specs = [s for s in specs if s["id"] in a.ids]

    rows = []
    for s in specs:
        bid, fam, e2e = s["id"], s["family"], s.get("rtl_e2e", False)
        if e2e:
            ok, dt, tail = run_gate(s["gate"])
            status = "BIT-EXACT ✓" if ok else "FAIL"
            detail = f"{s['gate']} ({dt:.0f}s)" if ok else tail
        else:
            status = "not-run"
            detail = "blocked: " + s.get("blocker", "?")
        rows.append(dict(id=bid, family=fam, verify=s.get("verify"),
                         rtl_e2e=e2e, status=status, detail=detail,
                         effort=s.get("effort")))

    w = max(len(r["id"]) for r in rows)
    print(f"\n{'benchmark':<{w}}  {'family':<13}{'verify':<11}{'status':<14}detail")
    print("-" * (w + 60))
    for r in rows:
        print(f"{r['id']:<{w}}  {r['family']:<13}{str(r['verify']):<11}"
              f"{r['status']:<14}{r['detail'][:52]}")
    n_e2e = sum(1 for r in rows if r["rtl_e2e"])
    n_pass = sum(1 for r in rows if "✓" in r["status"])
    print("-" * (w + 60))
    print(f"RTL-e2e bit-exact: {n_pass}/{n_e2e} pass  ·  "
          f"not-run (blocked): {sum(1 for r in rows if not r['rtl_e2e'])}")
    print("(not-run = honest; blockers in bench.yaml — F1 roadmap ADR-0064)")

    if a.json:
        Path(a.json).write_text(json.dumps(rows, indent=1))
    return 0 if all("FAIL" not in r["status"] for r in rows) else 1


if __name__ == "__main__":
    sys.exit(main())
