#!/usr/bin/env python3
"""isa_cov — ADR-0063 V1: instruction-coverage tracker from Spike commit logs.

Authority: Spike --log-commits disassembly is the ISA golden already used for lockstep.
This ingests spike.log DISASM lines (mnemonics), normalizes pseudo-instructions to their
base op (each pseudo IS the base instruction), buckets by extension against the in-scope
SCOPE SSOT, and reports per-extension mnemonic coverage.

Honest-界 (green-wash guards, ADR-0063 §4/§6):
  - excluded (scope-cut) mnemonics are removed from the denominator AND hitting one gives
    NO credit (it is reported as a surprise, not covered) — so rogue firmware can't inflate.
  - the exclusion ledger cites ADRs; shrinking it without new coverage is a gate failure.
  - coverage% is completeness, NOT correctness (lockstep remains the authority).

Usage:
  python3 isa_cov.py LOG...            # ingest logs, print report
  python3 isa_cov.py --json out.json LOG...
  python3 isa_cov.py --dump-scope      # emit the SCOPE SSOT as JSON
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

# disasm line: "core N: 0xPC (0xENC) mnemonic ops"  — PC directly after colon (no priv digit)
_DISASM = re.compile(r"^core\s+\d+:\s+0x[0-9a-f]+\s+\(0x[0-9a-f]{4,8}\)\s+([a-z][a-z0-9._]*)")

# pseudo -> canonical base op (each pseudo executes the base instruction)
PSEUDO = {
    "li": "addi", "mv": "addi", "nop": "addi", "sext.w": "addiw",
    "not": "xori", "neg": "sub", "negw": "subw", "seqz": "sltiu", "snez": "sltu",
    "sltz": "slt", "sgtz": "slt",
    "beqz": "beq", "bnez": "bne", "blez": "bge", "bgez": "bge", "bltz": "blt",
    "bgtz": "blt", "bgt": "blt", "ble": "bge", "bgtu": "bltu", "bleu": "bgeu",
    "j": "jal", "jr": "jalr", "ret": "jalr", "call": "jalr", "tail": "jalr",
    "csrr": "csrrs", "csrw": "csrrw", "csrs": "csrrs", "csrc": "csrrc",
    "csrwi": "csrrwi", "csrsi": "csrrsi", "csrci": "csrrci", "csrrc": "csrrc",
    "fmv.s": "fsgnj.s", "fabs.s": "fsgnjx.s", "fneg.s": "fsgnjn.s",
    "fmv.x.s": "fmv.x.w", "fmv.s.x": "fmv.w.x",
    "zext.b": "andi", "rdcycle": "csrrs", "rdinstret": "csrrs", "rdtime": "csrrs",
    "unimp": "csrrw",
}

VV = ["vv", "vx", "vi"]


def _fam(base, forms):
    return [f"{base}.{f}" for f in forms]


def build_scope():
    """The in-scope canonical mnemonic SSOT per extension (Spike disasm naming)."""
    i = ["lui", "auipc", "jal", "jalr", "beq", "bne", "blt", "bge", "bltu", "bgeu",
         "lb", "lh", "lw", "lbu", "lhu", "sb", "sh", "sw", "addi", "slti", "sltiu",
         "xori", "ori", "andi", "slli", "srli", "srai", "add", "sub", "sll", "slt",
         "sltu", "xor", "srl", "sra", "or", "and", "fence", "ecall", "ebreak"]
    c = ["c.addi", "c.li", "c.lui", "c.j", "c.jal", "c.jr", "c.jalr", "c.beqz",
         "c.bnez", "c.lw", "c.sw", "c.lwsp", "c.swsp", "c.add", "c.mv", "c.sub",
         "c.and", "c.or", "c.xor", "c.andi", "c.slli", "c.srli", "c.srai", "c.addi4spn",
         "c.addi16sp", "c.nop", "c.ebreak"]
    m = ["mul", "mulh", "mulhsu", "mulhu", "div", "divu", "rem", "remu"]
    f = ["flw", "fsw", "fmadd.s", "fmsub.s", "fnmsub.s", "fnmadd.s", "fadd.s",
         "fsub.s", "fmul.s", "fdiv.s", "fsqrt.s", "fsgnj.s", "fsgnjn.s", "fsgnjx.s",
         "fmin.s", "fmax.s", "fcvt.w.s", "fcvt.wu.s", "fmv.x.w", "feq.s", "flt.s",
         "fle.s", "fclass.s", "fcvt.s.w", "fcvt.s.wu", "fmv.w.x"]
    zicsr = ["csrrw", "csrrs", "csrrc", "csrrwi", "csrrsi", "csrrci"]
    zifencei = ["fence.i"]
    zba = ["sh1add", "sh2add", "sh3add"]
    zbb = ["andn", "orn", "xnor", "clz", "ctz", "cpop", "max", "maxu", "min", "minu",
           "sext.b", "sext.h", "zext.h", "rol", "ror", "rori", "orc.b", "rev8.rv32"]
    priv = ["mret", "wfi"]
    zbs = ["bclr", "bclri", "bext", "bexti", "binv", "binvi", "bset", "bseti"]
    zicond = ["czero.eqz", "czero.nez"]

    v = ["vsetvli", "vsetivli", "vsetvl"]
    v += _fam("vle8", ["v"]) + _fam("vle16", ["v"]) + _fam("vle32", ["v"])
    v += _fam("vse8", ["v"]) + _fam("vse16", ["v"]) + _fam("vse32", ["v"])
    # unit-stride segment (nf 2..8, eew 8/16/32) — the supported family
    for nf in range(2, 9):
        for e in (8, 16, 32):
            v += [f"vlseg{nf}e{e}.v", f"vsseg{nf}e{e}.v"]
    for b in ("vadd", "vand", "vor", "vxor", "vsll", "vsrl", "vsra"):
        v += _fam(b, VV)
    v += _fam("vsub", ["vv", "vx"]) + _fam("vrsub", ["vx", "vi"])
    for b in ("vnsrl", "vnsra", "vnclipu", "vnclip", "vssrl", "vssra"):
        v += _fam(b, ["wv", "wx", "wi"]) if b.startswith("vn") else _fam(b, ["vv", "vx", "vi"])
    for b in ("vmin", "vminu", "vmax", "vmaxu"):
        v += _fam(b, ["vv", "vx"])
    for b in ("vmul", "vmulh", "vmulhu", "vmulhsu", "vdivu", "vdiv", "vremu", "vrem"):
        v += _fam(b, ["vv", "vx"])
    for b in ("vwmul", "vwmulu", "vwmulsu"):
        v += _fam(b, ["vv", "vx"])
    for b in ("vwaddu", "vwadd", "vwsubu", "vwsub"):
        v += _fam(b, ["vv", "vx", "wv", "wx"])
    for b in ("vmacc", "vnmsac", "vmadd", "vnmsub"):
        v += _fam(b, ["vv", "vx"])
    for b in ("vwmaccu", "vwmacc", "vwmaccsu"):
        v += _fam(b, ["vv", "vx"])
    v += ["vwmaccus.vx"]
    v += _fam("vadc", ["vvm", "vxm", "vim"]) + _fam("vsbc", ["vvm", "vxm"])
    v += _fam("vmadc", ["vvm", "vxm", "vim", "vv", "vx", "vi"]) + _fam("vmsbc", ["vvm", "vxm", "vv", "vx"])
    v += ["vzext.vf2", "vzext.vf4", "vsext.vf2", "vsext.vf4"]
    for b in ("vmseq", "vmsne"):
        v += _fam(b, VV)
    for b in ("vmsltu", "vmslt"):
        v += _fam(b, ["vv", "vx"])
    for b in ("vmsleu", "vmsle"):
        v += _fam(b, ["vv", "vx", "vi"])
    for b in ("vmsgtu", "vmsgt"):
        v += _fam(b, ["vx", "vi"])
    v += [f"{b}.mm" for b in ("vmand", "vmnand", "vmandn", "vmxor", "vmor", "vmnor", "vmorn", "vmxnor")]
    v += ["vcpop.m", "vfirst.m", "vmsbf.m", "vmsof.m", "vmsif.m", "viota.m", "vid.v"]
    v += [f"{b}.vs" for b in ("vredsum", "vredand", "vredor", "vredxor",
                              "vredminu", "vredmin", "vredmaxu", "vredmax",
                              "vwredsum", "vwredsumu")]
    v += _fam("vslideup", ["vx", "vi"]) + _fam("vslidedown", ["vx", "vi"])
    v += ["vslide1up.vx", "vslide1down.vx"]
    v += _fam("vrgather", VV) + ["vcompress.vm"]
    v += ["vmv1r.v", "vmv2r.v", "vmv4r.v", "vmv8r.v"]
    v += ["vmv.v.v", "vmv.v.x", "vmv.v.i", "vmv.x.s", "vmv.s.x"]
    v += _fam("vmerge", ["vvm", "vxm", "vim"])
    for b in ("vsaddu", "vsadd"):
        v += _fam(b, ["vv", "vx", "vi"])
    for b in ("vssubu", "vssub", "vaaddu", "vaadd", "vasubu", "vasub", "vsmul"):
        v += _fam(b, ["vv", "vx"])

    return {"i": i, "c": c, "m": m, "f": f, "zicsr": zicsr, "zifencei": zifencei,
            "zba": zba, "zbb": zbb, "zbs": zbs, "zicond": zicond, "priv": priv,
            "zve32x": sorted(set(v))}


# scope-cut exclusions (removed from denominator; hitting one = surprise, no credit)
def build_exclusions():
    ex = {}
    def add(names, adr, reason):
        for n in names:
            ex[n] = {"bucket": "scope-cut", "adr": adr, "reason": reason}
    for e in (8, 16, 32):
        add([f"vlse{e}.v", f"vsse{e}.v"], "ADR-0054/0060", "strided load/store — deferred")
        add([f"vluxei{e}.v", f"vloxei{e}.v", f"vsuxei{e}.v", f"vsoxei{e}.v"],
            "ADR-0054/0060", "indexed load/store — deferred")
        add([f"vle{e}ff.v"], "ADR-0054/0060", "fault-only-first — deferred")
    add(["vrgatherei16.vv"], "ADR-0058", "16-bit index gather — deferred (EMUL index group)")
    add(["vlm.v", "vsm.v"], "ADR-0054", "mask load/store — deferred (low value)")
    add([f"vl{n}r.v" for n in (1, 2, 4, 8)] + [f"vs{n}r.v" for n in (1, 2, 4, 8)],
        "ADR-0054", "whole-register load/store — deferred (low value)")
    return ex


def ingest(logs):
    """Return {mnemonic: hit_count} after pseudo-normalization, and per-file sets."""
    hits = {}
    per_file = {}
    for lg in logs:
        seen = set()
        try:
            text = Path(lg).read_text(errors="ignore")
        except OSError:
            continue
        for line in text.splitlines():
            m = _DISASM.match(line)
            if not m:
                continue
            mn = m.group(1)
            mn = PSEUDO.get(mn, mn)
            hits[mn] = hits.get(mn, 0) + 1
            seen.add(mn)
        per_file[str(lg)] = seen
    return hits, per_file


def report(hits, scope, excl):
    observed = set(hits)
    ext_of = {}
    for ext, mns in scope.items():
        for mn in mns:
            ext_of[mn] = ext
    rows = []
    for ext, mns in scope.items():
        mset = set(mns)
        covered = sorted(m for m in mset if m in observed)
        missing = sorted(m for m in mset if m not in observed)
        rows.append((ext, len(mset), len(covered), missing))
    # surprises: observed but neither in-scope nor excluded (forgot to list / new pseudo)
    in_scope = set().union(*[set(v) for v in scope.values()])
    surprises = sorted(m for m in observed if m not in in_scope and m not in excl)
    # excluded that were hit (no credit; flag as green-wash risk)
    excl_hit = sorted(m for m in observed if m in excl)
    return rows, surprises, excl_hit


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("logs", nargs="*")
    ap.add_argument("--json", type=str)
    ap.add_argument("--dump-scope", action="store_true")
    a = ap.parse_args()
    scope = build_scope()
    excl = build_exclusions()
    if a.dump_scope:
        print(json.dumps({"scope": scope, "exclusions": excl}, indent=1))
        return
    hits, per_file = ingest(a.logs)
    rows, surprises, excl_hit = report(hits, scope, excl)

    print(f"# ISA instruction coverage — {len(a.logs)} logs, "
          f"{sum(len(s) for s in per_file.values()) and len(set().union(*per_file.values()))} distinct mnemonics observed\n")
    print(f"{'ext':<10}{'in-scope':>9}{'covered':>9}{'cov%':>7}   missing")
    print("-" * 78)
    tot_s = tot_c = 0
    for ext, n, c, missing in rows:
        tot_s += n; tot_c += c
        pct = 100.0 * c / n if n else 0.0
        miss = ", ".join(missing[:6]) + (f" (+{len(missing)-6})" if len(missing) > 6 else "")
        print(f"{ext:<10}{n:>9}{c:>9}{pct:>6.0f}%   {miss}")
    print("-" * 78)
    print(f"{'TOTAL':<10}{tot_s:>9}{tot_c:>9}{100.0*tot_c/tot_s:>6.0f}%")
    print(f"\nexcluded (scope-cut, out of denominator): {len(excl)}")
    if excl_hit:
        print(f"  !! excluded ops HIT (no credit — investigate): {', '.join(excl_hit)}")
    if surprises:
        print(f"\nobserved but NOT in scope/exclusions ({len(surprises)}) — classify:")
        print("  " + ", ".join(surprises))
    if a.json:
        Path(a.json).write_text(json.dumps({
            "per_ext": {ext: {"in_scope": n, "covered": c, "missing": miss}
                        for ext, n, c, miss in rows},
            "total": {"in_scope": tot_s, "covered": tot_c},
            "excluded": len(excl), "excluded_hit": excl_hit, "surprises": surprises,
        }, indent=1))
        print(f"\nwrote {a.json}")


if __name__ == "__main__":
    main()
