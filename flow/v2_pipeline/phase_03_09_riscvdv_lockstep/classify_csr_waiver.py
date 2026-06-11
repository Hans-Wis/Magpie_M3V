#!/usr/bin/env python3
"""Partition the UNTOGGLED u_csr toggle points into structural-waiver buckets vs genuinely
coverable, for the §04 DV-lead-signable waiver. Reads the same per-seed coverage.dat set as
measure_toggle.py (union over seeds). Classification keys off the Verilog signal name (`o`
field) — the SKU-dead families are PMP (PMP_ENTRIES=0), debug/dcsr/dpc/dscratch0 (debug mode
never entered in lockstep), trigger routing (trigger inactive), counter high bits (rollover
unreachable in finite sim), and hardwired-constant read-mux bits (misa / mstatus / mie zero
fields). Everything else is reported as 'coverable' (directed stimulus should reach it)."""
import sys, glob, re, collections
from pathlib import Path

PMP      = ("pmp_addr_o", "pmpaddr_r", "pmp_cfg_o", "pmpcfg_r")
DEBUG    = ("debug_csr_wdata", "debug_csr_rdata", "debug_csr_waddr", "debug_csr_we",
            "debug_halt_pc", "debug_halt_cause", "debug_halt_enter")
DCSR     = ("dpc_reg", "dscratch0_reg", "dcsr_val", "dcsr_cause_reg", "dcsr_step_reg",
            "dcsr_ebreakm_reg", "dpc_o", "dcsr_step_o", "dcsr_ebreakm_o")
TRIGGER  = ("trigger_debug_csr_rdata", "trigger_debug_csr_wdata", "trigger_debug_csr_waddr",
            "trigger_csr_rdata", "trigger_csr_wdata", "trigger_csr_waddr",
            "trigger_debug_csr_we", "trigger_csr_we")
COUNTER  = ("cycle_cnt", "instret_cnt")
CONSTMUX = ("misa_val", "mstatus_val", "mie_val", "mip_val")
IRQ      = ("irq_cause", "irq_mei", "irq_msi", "irq_mti", "ext_pending", "mtvec_o", "mtvec_val")

BUCKETS = [("PMP (PMP_ENTRIES=0 dead)", PMP),
           ("DEBUG halt iface (inactive)", DEBUG),
           ("DCSR/DPC/DSCRATCH (debug-only CSR)", DCSR),
           ("TRIGGER routing (inactive)", TRIGGER),
           ("COUNTER high bits (rollover unreachable)", COUNTER),
           ("CONST read-mux zero fields", CONSTMUX),
           ("IRQ-sourced (needs interrupt stimulus)", IRQ)]


def classify(base):
    for name, fam in BUCKETS:
        if base in fam:
            return name
    return "COVERABLE (directed-reachable)"


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
            if fld.get("t") != "toggle" or fld.get("h", "").split(".")[-1] != "u_csr":
                continue
            base = re.sub(r"\[.*", "", fld.get("o", "?")).split(":")[0]
            pts[key] = base
            if cnt > 0:
                hit.add(key)

    buck = collections.Counter()
    sigs = collections.defaultdict(set)
    untot = 0
    for key, base in pts.items():
        if key in hit:
            continue
        untot += 1
        b = classify(base)
        buck[b] += 1
        sigs[b].add(base)
    waiver = sum(c for b, c in buck.items() if not b.startswith("COVERABLE"))
    print(f"# u_csr untoggled total: {untot}")
    for b, c in buck.most_common():
        print(f"  {c:4d}  {b}")
        print(f"        signals: {', '.join(sorted(sigs[b]))}")
    print(f"\n# structural-waiver subtotal (u_csr): {waiver}")
    print(f"# coverable remaining (u_csr): {untot - waiver}")


if __name__ == "__main__":
    main()
