#!/usr/bin/env python3
"""In-SKU EFFECTIVE line / branch / expression coverage for the Tier-2-Narrow contract.

Verilator emits line/branch/expr coverage points keyed by (file, line) — no signal names — so the
SKU exclusion is done by source location: a cold point is OUT-OF-SKU if its file is an out-of-SKU
module (pmp.v / trigger.v) OR its source line belongs to an out-of-SKU code path (RV32A atomics,
PMP, Debug/DM/Trigger), detected by keyword on the actual RTL line. Everything else is in-SKU
(covered or genuine debt). Same Feature-Freeze SKU-1 basis as classify_signoff.py (toggle).
"""
import sys, re, glob
from pathlib import Path

RTL = Path(__file__).resolve().parents[3] / "design/cpu_m1/rtl"
OUT_FILES = {"pmp", "trigger"}                       # whole out-of-SKU modules
OUT_KW = ("pmp", "amo", "debug", "dm_acc", "dm_halt", "dbg_", "dcsr", "dpc", "dscratch",
          "trigger", "tdata", "tselect", "tinfo", "rv32a", "lr_", "_lr_", "sc_fail", "sc_succ",
          "is_amo", "is_lr", "is_sc", "is_dret", "dret", "halt_req", "halt_enter", "havereset")
KINDS = ("line", "branch", "expr")

_src_cache = {}
def src_line(fname, ln):
    if fname not in _src_cache:
        p = RTL / f"{fname}.v"
        _src_cache[fname] = p.read_text(errors="replace").splitlines() if p.exists() else []
    lines = _src_cache[fname]
    return lines[ln - 1].lower() if 0 < ln <= len(lines) else ""


_block_cache = {}
def _out_of_sku_ranges(fname):
    """Line ranges of out-of-SKU BLOCKS whose interior lines lack tell-tale keywords
    (csr.v debug_csr_we write block; core.v AMO state machine). begin/end nesting tracked."""
    if fname in _block_cache:
        return _block_cache[fname]
    p = RTL / f"{fname}.v"
    ranges = []
    if p.exists():
        lines = p.read_text(errors="replace").splitlines()
        starts = []
        if fname == "csr":
            starts = [i for i, l in enumerate(lines) if "if (debug_csr_we) begin" in l]
        elif fname == "core":
            starts = [i for i, l in enumerate(lines) if re.search(r"case \(amo_state\)", l)]
        for s in starts:
            depth = 0
            for j in range(s, len(lines)):
                depth += lines[j].count("begin") + lines[j].count("case (")
                depth -= lines[j].count("end")          # endcase contains 'end'
                if j > s and depth <= 0:
                    ranges.append((s + 1, j + 1))
                    break
    _block_cache[fname] = ranges
    return ranges

def is_env_waitstate(fname, ln):
    """core_mem_stall hold branches: the farm TB is 0-wait BY DESIGN (random mem_stall would
    violate the ADR-0005 contract — empirically diverges); these lines are EXERCISED AND GREEN
    in the dedicated wrapper wait-state environment (phase_02_01 REPAIR-0001: I/D WAIT 1/3/RAND
    modes + 81-commit lockstep). Excluded-with-evidence, NOT debt."""
    return "core_mem_stall" in src_line(fname, ln)

def is_out_of_sku(fname, ln):
    if fname in OUT_FILES:
        return True
    txt = src_line(fname, ln)
    if any(k in txt for k in OUT_KW):
        return True
    return any(a <= ln <= b for a, b in _out_of_sku_ranges(fname))


def main():
    files = []
    for a in sys.argv[1:]:
        files += glob.glob(a) if any(c in a for c in "*?[") else [a]
    files = [f for f in files if Path(f).is_file()]
    hit = {k: set() for k in KINDS}
    pts = {k: {} for k in KINDS}
    for f in files:
        for line in Path(f).read_text(errors="replace").splitlines():
            m = re.match(r"^C '(.*)' (\d+)\s*$", line)
            if not m:
                continue
            key, cnt = m.group(1), int(m.group(2))
            fld = dict((x[0], x.split("\002", 1)[1]) for x in key.split("\001") if "\002" in x)
            t = fld.get("t")
            if t not in KINDS:
                continue
            fname = Path(fld.get("f", "?")).stem
            if fname.startswith("tb_"):
                continue                       # DUT-scoped sign-off: testbench is not the deliverable
            ln = fld.get("l", "0")
            pts[t][key] = (fname, int(ln) if ln.isdigit() else 0)
            if cnt > 0:
                hit[t].add(key)

    snap = {}
    for t in KINDS:
        H = len(hit[t]); T = len(pts[t])
        out_cold = in_debt = 0
        debt_lines = []
        for key, (fname, ln) in pts[t].items():
            if key in hit[t]:
                continue
            if is_out_of_sku(fname, ln) or is_env_waitstate(fname, ln):
                out_cold += 1
            else:
                in_debt += 1
                debt_lines.append(f"{fname}.v:{ln}")
        eff_denom = T - out_cold
        eff = 100.0 * H / eff_denom if eff_denom else 0.0
        snap[t] = {"raw_hit": H, "raw_total": T, "raw_pct": round(100.0 * H / T, 1) if T else 0,
                   "out_of_sku_cold": out_cold, "in_sku_debt": in_debt,
                   "effective_denom": eff_denom, "effective_pct": round(eff, 1)}
        print(f"=== {t}: raw {H}/{T}={100*H/T:.1f}%  ->  in-SKU effective {H}/{eff_denom}={eff:.1f}%  "
              f"(out-of-SKU cold {out_cold}, in-SKU debt {in_debt})")
        if debt_lines:
            import collections
            c = collections.Counter(debt_lines)
            print(f"    in-SKU debt lines: {dict(c)}")
    import json
    print("\nJSON " + json.dumps(snap))


if __name__ == "__main__":
    main()
