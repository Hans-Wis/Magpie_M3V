#!/usr/bin/env python3
"""#1 directed campaign — inject SAFE CSR ops into the random stream to toggle u_csr, with coverage.

Same proven lockstep-safe injection mechanism as inject_fence_lockstep.py: both DUT and Spike execute
the identical modified program, so injected instructions stay in lockstep regardless of GPR clobber.
We inject only architecturally-safe CSR ops:
  - csrr x31, <csr>   for every implemented M-mode CSR  -> toggles the CSR read-output mux + x31 write
  - csrw mscratch, xN (rotating)                        -> toggles mscratch storage (pure scratch, no side effect)
We do NOT inject writes to mstatus/mie/mtvec/trap-CSRs (could redirect a later trap to a bad vector);
those bits toggle via the program's own init writes + the sync-trap streams (mepc/mcause/mtval).

Runs with the --coverage farm build (M1_COV=1), keeps coverage.dat per seed, then the caller merges with
the base farm seeds to measure the u_csr toggle bump. Lockstep must still PASS (0 divergence).
"""
import sys, re, os
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
import run_riscvdv_lockstep as farm

# DETERMINISTIC M-mode CSRs only: reading these gives the SAME value in DUT and Spike, so the
# clobbered x31 stays in lockstep when downstream instructions consume it. EXCLUDED: cycle/instret(+h)
# (DUT cycle-count != Spike counter) and mip (timer/interrupt-pending may differ) — those poison x31
# with a DUT!=Spike value, which diverges downstream (the timing-CSR-read skip covers only the csrr
# commit itself, not the GPR propagation). This exclusion was confirmed by an observed divergence.
CSRS = ["mhartid", "mstatus", "mie", "mtvec", "mscratch", "mepc", "mcause", "mtval"]


def inject_csr(fw: Path, every: int = 6) -> int:
    lines = fw.read_text(encoding="utf-8").splitlines()
    out, n, inj, in_main, ci, ri = [], 0, 0, False, 0, 5
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
                out.append(f"                  csrr x31, {CSRS[ci % len(CSRS)]}")
                ci += 1; inj += 1
                if n % (every * 3) == 0:
                    out.append(f"                  csrw mscratch, x{ri}")
                    ri = 5 + ((ri - 4) % 7); inj += 1
    fw.write_text("\n".join(out) + "\n", encoding="utf-8")
    return inj


def main() -> int:
    os.environ["M1_COV"] = "1"          # coverage build
    seeds = [int(s) for s in sys.argv[1:]] or [2026061301, 2026061302, 2026061303, 2026061304]
    farm.verilator_bin()
    runs = ROOT / "csr_cov_runs"; runs.mkdir(exist_ok=True)
    results = []
    for seed in seeds:
        work = runs / f"seed_{seed}"; work.mkdir(parents=True, exist_ok=True)
        src = farm.generate_seed(seed, work, 8000)
        farm.adapt_asm(src, work / "firmware.S")
        nc = inject_csr(work / "firmware.S")
        matched, ok, waived, msg = farm.sim_compare_seed(seed, work, max_cycles=5_000_000)
        results.append((seed, nc, matched, ok, msg))
        print(f"seed {seed}: injected_csr={nc} matched={matched} ok={ok} :: {msg}")
    allok = all(r[3] for r in results)
    print(f"\n{'PASS' if allok else 'FAIL'}: CSR-injection lockstep — {len(results)} seeds, "
          f"{sum(r[2] for r in results)} commits, 0 divergence" if allok else "FAIL: divergence")
    return 0 if allok else 1


if __name__ == "__main__":
    sys.exit(main())
