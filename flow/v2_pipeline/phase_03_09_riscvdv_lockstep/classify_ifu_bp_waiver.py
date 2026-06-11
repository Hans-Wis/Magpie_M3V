#!/usr/bin/env python3
"""Bit-index-aware classification of untoggled u_ifu / u_bp toggle points, to separate the
address-range-limited structural tail (high PC/target/tag bits unreachable in a low-address
lockstep farm — max executed PC ~0x6A2C, so PC[31:15] is stuck at 0) and other structural
edges (sticky valid 1->0, monotonic saturating counter) from any GENUINELY coverable remainder
that more directed branch stimulus could still hit. Reads the merged farm coverage.dat."""
import sys, re, glob, collections
from pathlib import Path

# Programs execute in [0, ~0x6A2C]; PC bit >= ADDR_HI is always 0 -> address-range-limited.
ADDR_HI = 15
PC_SIGS = {"pc", "next_pc", "pc_reg", "if_pc", "upd_pc", "redirect_target",
           "bp_predict_target", "ras_predict_target", "pc_inc"}
TAG_SIGS = {"rd_tag", "wr_tag"}          # tag bit b corresponds to PC bit (b + 7)
TAG_LSB = 7


def classify(sig, bit, edge):
    if sig in PC_SIGS:
        if bit is not None and bit >= ADDR_HI:
            return "ADDR-LIMITED (high PC/target bit, PC<0x8000)"
        return "COVERABLE (low PC bit)"
    if sig in TAG_SIGS:
        if bit is not None and (bit + TAG_LSB) >= ADDR_HI:
            return "ADDR-LIMITED (high tag bit = high PC)"
        return "COVERABLE (low tag bit)"
    if sig in ("valid0", "valid1"):
        return "STRUCTURAL (sticky valid, 1->0 never clears)" if edge == "1->0" \
            else "COVERABLE (valid 0->1: predictor entry never filled)"
    if sig.startswith("counter") or sig.startswith("cnt"):
        return "STRUCTURAL (monotonic saturating-counter edge)"
    if sig == "resetn":
        return "STRUCTURAL (reset)"
    return "COVERABLE (other)"


def main():
    files = []
    for a in sys.argv[1:]:
        files += glob.glob(a) if any(c in a for c in "*?[") else [a]
    files = [f for f in files if Path(f).is_file()]
    hit, pts = set(), {}
    for f in files:
        for line in Path(f).read_text(errors="replace").splitlines():
            m = re.match(r"^C '(.*)' (\d+)\s*$", line)
            if not m:
                continue
            key, cnt = m.group(1), int(m.group(2))
            fld = dict((x[0], x.split("\002", 1)[1]) for x in key.split("\001") if "\002" in x)
            if fld.get("t") != "toggle":
                continue
            mod = fld.get("h", "").split(".")[-1]
            if mod not in ("u_ifu", "u_bp"):
                continue
            o = fld.get("o", "")
            sig = re.sub(r"\[.*", "", o).split(":")[0]
            mbit = re.search(r"\[(\d+)\]", o)
            bit = int(mbit.group(1)) if mbit else None
            edge = o.split(":")[-1] if ":" in o else "?"
            pts[key] = (mod, sig, bit, edge)
            if cnt > 0:
                hit.add(key)

    for MOD in ("u_ifu", "u_bp"):
        buck = collections.Counter()
        cover_sigs = collections.Counter()
        un = 0
        for key, (mod, sig, bit, edge) in pts.items():
            if mod != MOD or key in hit:
                continue
            un += 1
            c = classify(sig, bit, edge)
            buck[c] += 1
            if c.startswith("COVERABLE"):
                cover_sigs[f"{sig}:{edge}"] += 1
        waiver = sum(v for k, v in buck.items() if not k.startswith("COVERABLE"))
        print(f"\n==== {MOD}: {un} untoggled ====")
        for c, n in buck.most_common():
            print(f"  {n:4d}  {c}")
        print(f"  -> structural/addr-limited waiver: {waiver}, COVERABLE: {un - waiver}")
        if cover_sigs:
            print(f"     coverable detail: {dict(cover_sigs)}")


if __name__ == "__main__":
    main()
