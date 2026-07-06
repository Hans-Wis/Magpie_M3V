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
_H = re.compile("\x01h\x02.*$")            # hierarchy suffix — stripped for effective merge


def parse(dat):
    # EFFECTIVE coverage: collapse instance hierarchy so a source line / net counted as
    # covered if it was exercised in ANY DUT instance. Without this, the same file
    # instantiated in an unexercised DUT (e.g. vexu inside the host top) would dilute the
    # denominator. Line keyed by (file,line); toggle by (file, net-signature w/o hier).
    lseen, lhit = defaultdict(set), defaultdict(set)
    tseen, thit = defaultdict(set), defaultdict(set)
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
                    lseen[f].add(lm.group(1))
                    if cnt:
                        lhit[f].add(lm.group(1))
            else:
                sig = _H.sub("", ln.split("' ")[0])   # point identity minus hierarchy
                tseen[f].add(sig)
                if cnt:
                    thit[f].add(sig)
    files = sorted(set(lseen) | set(tseen))
    rows = {f: {"line": [len(lhit[f]), len(lseen[f])],
                "toggle": [len(thit[f]), len(tseen[f])]} for f in files}
    tl = [sum(len(lhit[f]) for f in files), sum(len(lseen[f]) for f in files)]
    tg = [sum(len(thit[f]) for f in files), sum(len(tseen[f]) for f in files)]
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
