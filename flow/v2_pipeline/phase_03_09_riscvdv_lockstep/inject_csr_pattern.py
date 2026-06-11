#!/usr/bin/env python3
"""#1 directed campaign — toggle u_csr STORAGE/write-enable/read-mux high bits via
save-modify-restore CSR pattern injection (lockstep-safe).

The earlier inject_csr_cov.py only did `csrr x31,<csr>` (read mux) + `csrw mscratch` — it
toggles the read path but NOT the write-data path / storage high bits of the functional
M-CSRs, so u_csr stalled at 18.4%. This injector writes WALKING BIT PATTERNS into each
writable M-CSR and then restores the original value.

  csrr  x31, <csr>        # save OLD value (committed to x31 -> COMPARED; agrees: same arch
                          #   state on DUT and Spike, exactly the read the base farm already
                          #   does at scale with 0 divergence)
  li    x30, <patA>       # deterministic constant (COMPARED; agrees)
  csrw  <csr>, x30        # write pattern A  -> rd=x0, NO GPR write -> NOT in the commit trace
  li    x30, <patB>       #   -> NEVER compared, so even subset-vs-full CSRs (mstatus/mtvec/mie,
  csrw  <csr>, x30        #   where DUT implements fewer bits than Spike) cannot diverge here.
  csrw  <csr>, x31        # restore OLD value (rd=x0) -> program state unchanged after snippet

Why this is divergence-proof (verified against flow/v2_pipeline/lib/spike_commit.py):
the lockstep compares only (pc, rd, wdata) GPR writebacks parsed from Spike --log-commits;
a `csrw csr,rs` (rd=x0) emits no `x<rd> 0x<wdata>` field, so the patterned (possibly
WARL-legalized-differently) CSR value is invisible to the comparator. Only the save-read
(old value) and the `li` constants reach a GPR, and both agree.

Coverage build (M1_COV=1). Caller merges the per-seed coverage.dat with the base/CSR/fence/
RAS farm seeds and measures the u_csr toggle bump. Lockstep must still PASS (0 divergence).
"""
import sys, re, os
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
import run_riscvdv_lockstep as farm

# Writable M-mode CSRs whose storage / new_val / read-mux high bits we want to toggle.
# Full-width plain regs (biggest yield) first; subset/masked regs after (read-mux + the few
# implemented storage bits). All are pattern-written via rd=x0 csrw, so none is compared.
CSRS = [
    "0x340",  # mscratch : 32b plain scratch (no side effect)
    "0x341",  # mepc     : 31b (bit0 masked, same as Spike RV32C)
    "0x342",  # mcause   : 32b plain
    "0x343",  # mtval    : 32b plain
    "0x305",  # mtvec    : 30b base (MODE bits masked)
    "0x300",  # mstatus  : MIE/MPIE implemented subset
    "0x304",  # mie      : MEIE/MTIE/MSIE
]

# Pattern pairs — across the rotation every storage bit sees a 0 and a 1 and BOTH edges.
PATS = [
    ("0xAAAAAAAA", "0x55555555"),
    ("0xFFFFFFFF", "0x00000000"),
    ("0x0000FFFF", "0xFFFF0000"),
    ("0x12345678", "0xEDCBA987"),
    ("0x80000001", "0x7FFFFFFE"),
]


def _snippet(csr, pa, pb):
    return [f"                  csrr  x31, {csr}",
            f"                  li    x30, {pa}",
            f"                  csrw  {csr}, x30",
            f"                  li    x30, {pb}",
            f"                  csrw  {csr}, x30",
            f"                  csrw  {csr}, x31"]


def inject_csr_pattern(fw: Path, every: int = 28) -> int:
    lines = fw.read_text(encoding="utf-8").splitlines()
    out, n, inj, in_main, ci, pi = [], 0, 0, False, 0, 0
    def is_instr(s):
        t = s.strip()
        if not t or t.startswith((".", "#")):
            return False
        t = re.sub(r"^[A-Za-z0-9_]+:\s*", "", t)
        return bool(re.match(r"[a-z]", t))
    for ln in lines:
        out.append(ln)
        s = ln.strip()
        if s.startswith("main:"):
            in_main = True
        if in_main and (s.startswith("write_tohost") or re.match(r"sub_\d+:", s) or s.startswith(".section .data")):
            in_main = False
        if in_main and is_instr(ln):
            n += 1
            if n % every == 0:
                pa, pb = PATS[pi % len(PATS)]
                out += _snippet(CSRS[ci % len(CSRS)], pa, pb)
                ci += 1
                if ci % len(CSRS) == 0:
                    pi += 1
                inj += 1
    fw.write_text("\n".join(out) + "\n", encoding="utf-8")
    return inj


def main() -> int:
    os.environ["M1_COV"] = "1"
    seeds = [int(s) for s in sys.argv[1:]] or [2026061601, 2026061602, 2026061603, 2026061604]
    farm.verilator_bin()
    runs = ROOT / "csr_pat_runs"; runs.mkdir(exist_ok=True)
    results = []
    for seed in seeds:
        work = runs / f"seed_{seed}"; work.mkdir(parents=True, exist_ok=True)
        src = farm.generate_seed(seed, work, 8000)
        farm.adapt_asm(src, work / "firmware.S")
        nc = inject_csr_pattern(work / "firmware.S")
        matched, ok, waived, msg = farm.sim_compare_seed(seed, work, max_cycles=5_000_000)
        results.append((seed, nc, matched, ok, msg))
        print(f"seed {seed}: csr_pattern_snippets={nc} matched={matched} ok={ok} :: {msg}")
    allok = all(r[3] for r in results)
    print(f"\n{'PASS' if allok else 'FAIL'}: CSR-pattern injection lockstep — {len(results)} seeds, "
          f"{sum(r[2] for r in results)} commits, {'0 divergence' if allok else 'DIVERGENCE'}")
    return 0 if allok else 1


if __name__ == "__main__":
    sys.exit(main())
