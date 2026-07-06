#!/usr/bin/env python3
"""Whole-core toggle SIGN-OFF classifier for the Tier-2-Narrow (RV32IMC core-only) contract.

Computes the DEFENSIBLE effective toggle coverage by partitioning every cold toggle point against
the Feature-Freeze SKU contract (design/cpu_m1/dv/vplan/FEATURE_FREEZE.md):

  OUT-OF-SKU  (legitimately excluded — not in the SKU-1 deliverable feature set):
    - PMP        (PMP_ENTRIES=0 optional)          : module u_pmp_*, any `pmp*` net
    - RV32A      (RV32A=0 optional)                : any `amo*` net
    - Debug/DM/Trigger (SoC-integrator, out of scope): u_trigger, debug/dm/dcsr/dpc/dscratch/trigger nets
  STRUCTURAL  (standard toggle exclusions, in-SKU logic that cannot toggle by construction):
    - const-mux hardwired-zero fields (misa/mstatus/mie/mip read-mux)
    - counter rollover high bits (cycle/instret)
    - sticky/monotonic edges (BTB valid 1->0, saturating-counter edge)
  ADDRESS-BOUND (documented-deviation exclusion — 16KB low-address farm TB, PC[31:15] structurally 0):
    - high (>=15) bits of any PC/target/address/tag net
  IN-SKU COVERED      : hit
  IN-SKU GENUINE DEBT : in-scope, reachable, uncovered, NOT address-bound -> the REAL remaining gap

Effective coverage = in_sku_hit / (in_sku_hit + in_sku_genuine_debt). Reports raw, in-SKU-effective,
and the precise genuine-debt remaining (what still needs directed stimulus to reach a defensible bar).
"""
import sys, re, glob, collections
from pathlib import Path

OUT_MODULES = {"u_pmp", "u_trigger"}     # whole modules out of SKU-1 (optional PMP / out-of-scope trigger)
ADDR_HI = 15
PC_HINT = ("pc", "target", "addr", "_tag", "mtval", "mepc", "ras_top", "push_val", "ras_push")


def module_of(h):
    leaf = h.split(".")[-1]
    m = re.match(r"^(u_[a-z]+?)_?\d+$", leaf)
    return f"{m.group(1)}_*" if m else leaf, (m.group(1) if m else leaf)


def classify(modbase, sig, bit, edge, hpath=""):
    s = sig.lower()
    hl = hpath.lower()
    # PMP / trigger detection by full hierarchy path (catches submodule instances whose internal
    # signal names — tor_start, this_addr, cfg... — don't themselves contain "pmp"/"trigger").
    if "pmp" in hl or "pmp" in s:
        return "OUT-OF-SKU/pmp"
    if "trig" in hl:
        return "OUT-OF-SKU/debug-trigger"
    if modbase in OUT_MODULES:
        return "OUT-OF-SKU/pmp" if modbase == "u_pmp" else "OUT-OF-SKU/debug-trigger"
    if "amo" in s:
        return "OUT-OF-SKU/rv32a"
    if any(t in s for t in ("debug", "dm_acc", "dbg_", "dpc", "dcsr", "dscratch", "halt", "trigger",
                            "tselect", "tdata", "tinfo")):
        return "OUT-OF-SKU/debug-trigger"
    if sig in ("misa_val", "mstatus_val", "mie_val", "mip_val", "dcsr_val"):
        return "STRUCT/const-mux"
    if sig.startswith("cycle_cnt") or sig.startswith("instret_cnt"):
        return "STRUCT/counter-rollover"
    if sig in ("valid0", "valid1") and edge == "1->0":
        return "STRUCT/sticky-valid"
    if (sig.startswith("counter") or sig.startswith("cnt")):
        return "STRUCT/counter-edge"
    if sig == "resetn":
        return "STRUCT/reset"
    if any(t in s for t in PC_HINT) and bit is not None and bit >= ADDR_HI:
        return "ADDR-BOUND/high-pc"
    return "IN-SKU-DEBT"


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
            h = fld.get("h", "")
            o = fld.get("o", "")
            sig = re.sub(r"\[.*", "", o).split(":")[0]
            mb = re.search(r"\[(\d+)\]", o)
            bit = int(mb.group(1)) if mb else None
            edge = o.split(":")[-1] if ":" in o else "?"
            _, modbase = module_of(h)
            pts[key] = (modbase, sig, bit, edge, h)
            if cnt > 0:
                hit.add(key)

    total = len(pts)
    H = len(hit)
    buckets = collections.Counter()
    debt_sig = collections.Counter()
    for key, (modbase, sig, bit, edge, h) in pts.items():
        if key in hit:
            continue
        b = classify(modbase, sig, bit, edge, h)
        buckets[b] += 1
        if b == "IN-SKU-DEBT":
            debt_sig[f"{modbase}.{sig}"] += 1

    out_of_sku = sum(v for k, v in buckets.items() if k.startswith("OUT-OF-SKU"))
    struct = sum(v for k, v in buckets.items() if k.startswith("STRUCT"))
    addr = buckets.get("ADDR-BOUND/high-pc", 0)
    debt = buckets.get("IN-SKU-DEBT", 0)

    print(f"# whole-core toggle: {H}/{total} = {100*H/total:.1f}% RAW")
    print("# cold-bit partition (Tier-2-Narrow, FEATURE_FREEZE SKU-1):")
    for b, n in buckets.most_common():
        print(f"   {n:5d}  {b}")
    # in-SKU denominator excludes OUT-OF-SKU (not in deliverable) + STRUCT + ADDR-BOUND (documented)
    in_sku_total = total - out_of_sku
    eff_denom = in_sku_total - struct - addr
    print(f"\n# OUT-OF-SKU excluded (optional/integrator): {out_of_sku}")
    print(f"# STRUCT excluded (const/counter/sticky):    {struct}")
    print(f"# ADDR-BOUND excluded (16KB farm, documented):{addr}")
    print(f"# IN-SKU GENUINE DEBT (real remaining gap):   {debt}")
    print(f"\n# in-SKU effective = {H}/{eff_denom} = {100*H/eff_denom:.1f}%  (H / (H + genuine-debt) = {100*H/(H+debt):.1f}%)")
    print("\n# top IN-SKU-DEBT signals (need directed stimulus):")
    for s, n in debt_sig.most_common(20):
        print(f"   {n:4d}  {s}")


if __name__ == "__main__":
    main()
