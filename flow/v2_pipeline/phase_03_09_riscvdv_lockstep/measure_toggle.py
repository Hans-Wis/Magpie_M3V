#!/usr/bin/env python3
"""Union-merge Verilator toggle coverage across many per-seed coverage.dat files and print a
per-module hit/total breakdown + raw total + in-SKU total (after a fixed structural-waiver bit
count). A toggle point is HIT if its count > 0 in ANY merged seed (set-union, the same as
`verilator_coverage --write` then threshold).

Usage:
    measure_toggle.py [--waiver N] <glob-or-file> [<glob-or-file> ...]
Default waiver N = 3651 (the §04 PMP+trigger structural waiver used for the 67.6% in-SKU baseline).
"""
import sys, glob, re
from pathlib import Path

POINT = re.compile(r"^C '(.*)' (\d+)\s*$")


def _fields(key: str):
    # fields separated by \001; each field is "<keychar>\002<value>"
    for f in key.split("\001"):
        if "\002" in f:
            k, v = f.split("\002", 1)
            yield k, v


def hier_leaf(key: str) -> str:
    for k, v in _fields(key):
        if k == "h":
            leaf = v.split(".")[-1]
            # collapse instance arrays / numeric suffixes into a family (u_pmp_0 -> u_pmp_*)
            m = re.match(r"^(u_[a-z]+?)_?\d+$", leaf)
            return f"{m.group(1)}_*" if m else leaf
    return "?"


def is_toggle(key: str) -> bool:
    return any(k == "t" and v == "toggle" for k, v in _fields(key))


def main() -> int:
    args = sys.argv[1:]
    waiver = 3651
    if args and args[0] == "--waiver":
        waiver = int(args[1]); args = args[2:]
    files = []
    for a in args:
        files += glob.glob(a) if any(c in a for c in "*?[") else [a]
    files = [f for f in files if Path(f).is_file()]
    if not files:
        print("no coverage.dat files matched", file=sys.stderr); return 2

    hit, tot = {}, {}            # per toggle-point identity -> max count seen
    for f in files:
        for line in Path(f).read_text(errors="replace").splitlines():
            m = POINT.match(line)
            if not m:
                continue
            key, cnt = m.group(1), int(m.group(2))
            if not is_toggle(key):
                continue
            tot[key] = hier_leaf(key)
            if cnt > 0:
                hit[key] = True

    mod_hit, mod_tot = {}, {}
    for key, mod in tot.items():
        mod_tot[mod] = mod_tot.get(mod, 0) + 1
        if key in hit:
            mod_hit[mod] = mod_hit.get(mod, 0) + 1
    H = sum(mod_hit.values()); T = sum(mod_tot.values())

    print(f"# merged {len(files)} coverage.dat files")
    print(f"# {'module':24s} {'hit/tot':>12s} {'%':>7s} {'untoggled':>10s}")
    for mod in sorted(mod_tot, key=lambda m: -(mod_tot[m] - mod_hit.get(m, 0))):
        h, t = mod_hit.get(mod, 0), mod_tot[mod]
        print(f"  {mod:24s} {h:6d}/{t:<6d} {100*h/t:6.1f}  {t-h:9d}")
    print(f"  {'TOTAL':24s} {H:6d}/{T:<6d} {100*H/T:6.1f}  {T-H:9d}")
    denom = T - waiver
    print(f"\n# raw total      : {H}/{T} = {100*H/T:.1f}%")
    print(f"# in-SKU (waiver {waiver}): {H}/{denom} = {100*H/denom:.1f}%")
    return 0


if __name__ == "__main__":
    sys.exit(main())
