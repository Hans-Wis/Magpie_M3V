#!/usr/bin/env python3
"""combine_cov — ADR-0063 V5: combine multi-DUT Verilator coverage honestly.

The same RTL file is instantiated in several DUTs (vector tb_npu_lockstep, tflm
tb_npu_tflm_model, host tb_spike_lockstep). Naive cross-DUT merge dilutes TOGGLE because
a module's unexercised instance in a non-owner DUT (different params -> distinct net
signatures) inflates the denominator. So:
  - LINE  = union across all DUTs (a source line executed in ANY DUT counts) => effective.
  - TOGGLE = the max per-DUT-group toggle% (each module's OWNING harness has clean toggle).

Groups by dat filename prefix: vec_* (vector), tflm_* (offload), host_* (scalar).
Authority note (G1): coverage is completeness; every run is Spike-lockstep verified.

Usage: combine_cov.py DATS_DIR [--json OUT.json]
"""
import argparse
import glob
import importlib.util
import json
import os
import subprocess
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("cc", HERE / "codecov_report.py")
cc = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cc)


def _merge_parse(files):
    if not files:
        return {}
    tmp = tempfile.mktemp(suffix=".dat")
    subprocess.run(["verilator_coverage", "--write", tmp] + files, capture_output=True)
    rows, _ = cc.parse(tmp)
    os.unlink(tmp)
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dats")
    ap.add_argument("--json")
    a = ap.parse_args()
    g = lambda p: sorted(glob.glob(f"{a.dats}/{p}"))
    groups = {"vec": _merge_parse(g("vec_*.dat")),
              "tflm": _merge_parse(g("tflm_*.dat")),
              "host": _merge_parse(g("host_*.dat"))}
    allr = _merge_parse(g("*.dat"))
    mods = sorted(allr)
    print(f"{'file':<18}{'line(union)':>16}{'toggle(owner)':>16}{'owner':>7}")
    print("-" * 57)
    out, tlc, tlt = {}, 0, 0
    for m in mods:
        lc, lt = allr[m]["line"]
        tlc += lc
        tlt += lt
        best = (0, 0, -1.0, "-")
        for name, gr in groups.items():
            if m in gr:
                tc, tg = gr[m]["toggle"]
                p = 100 * tc / tg if tg else 0
                if p > best[2] or (p == best[2] and tg > best[1]):
                    best = (tc, tg, p, name)
        tc, tg, tp, owner = best
        out[m] = {"line": [lc, lt], "toggle": [tc, tg], "toggle_owner": owner}
        lp = f"{100*lc/lt:.0f}% ({lc}/{lt})" if lt else "-"
        tps = f"{tp:.0f}% ({tc}/{tg})" if tg else "-"
        print(f"{m:<18}{lp:>16}{tps:>16}{owner:>7}")
    print("-" * 57)
    print(f"{'TOTAL line(union)':<18}{f'{100*tlc/tlt:.0f}% ({tlc}/{tlt})':>16}")
    if a.json:
        Path(a.json).write_text(json.dumps(
            {"per_file": out, "total_line": [tlc, tlt],
             "method": "line=union effective; toggle=max per owning DUT (vec/tflm/host)"},
            indent=1))


if __name__ == "__main__":
    main()
