#!/usr/bin/env python3
"""codecov_report — ADR-0063 V5: per-file line + toggle coverage from a merged
Verilator coverage.dat. Authority note (G1): code coverage is COMPLETENESS (did the
regression exercise the RTL structurally), NOT correctness (lockstep is the authority).

Verilator coverage.dat encodes points as \\x01<field>\\x02<value> ... ' <count>.
We bucket per source file: line-coverage points (page=v_line) -> unique (file,line)
hit/total; toggle points (page=v_toggle) -> hit/total nets.

Usage: codecov_report.py MERGED.dat [--json OUT.json]
"""
import argparse
import json
import re
from collections import defaultdict
from pathlib import Path

_F = re.compile("\x01f\x02([^\x01]+)")
_L = re.compile("\x01l\x02(\\d+)")
_P = re.compile("\x01page\x02(v_line|v_toggle)")
_C = re.compile("' (\\d+)\\s*$")


def parse(dat):
    seen, hit = defaultdict(set), defaultdict(set)
    tt, th = defaultdict(int), defaultdict(int)
    with open(dat, errors="ignore") as fh:
        next(fh, None)
        for ln in fh:
            fm, pm, cm = _F.search(ln), _P.search(ln), _C.search(ln)
            if not (fm and pm and cm):
                continue
            f = fm.group(1).split("/")[-1]
            cnt = int(cm.group(1))
            if pm.group(1) == "v_line":
                lm = _L.search(ln)
                if lm:
                    seen[f].add(lm.group(1))
                    if cnt:
                        hit[f].add(lm.group(1))
            else:
                tt[f] += 1
                th[f] += 1 if cnt else 0
    files = sorted(set(seen) | set(tt))
    rows = {f: {"line": [len(hit[f]), len(seen[f])], "toggle": [th[f], tt[f]]}
            for f in files}
    tl = [sum(len(hit[f]) for f in files), sum(len(seen[f]) for f in files)]
    tg = [sum(th[f] for f in files), sum(tt[f] for f in files)]
    return rows, {"line": tl, "toggle": tg}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dat")
    ap.add_argument("--json")
    a = ap.parse_args()
    rows, total = parse(a.dat)
    print(f"{'file':<18}{'line cov':>16}{'toggle cov':>16}")
    print("-" * 50)
    for f, r in rows.items():
        lc, lt = r["line"]
        tc, tg = r["toggle"]
        lp = f"{100*lc/lt:.0f}% ({lc}/{lt})" if lt else "-"
        tp = f"{100*tc/tg:.0f}% ({tc}/{tg})" if tg else "-"
        print(f"{f:<18}{lp:>16}{tp:>16}")
    print("-" * 50)
    lc, lt = total["line"]
    tc, tg = total["toggle"]
    print(f"{'TOTAL':<18}{f'{100*lc/lt:.0f}% ({lc}/{lt})':>16}"
          f"{f'{100*tc/tg:.0f}% ({tc}/{tg})':>16}")
    if a.json:
        Path(a.json).write_text(json.dumps({"per_file": rows, "total": total}, indent=1))


if __name__ == "__main__":
    main()
