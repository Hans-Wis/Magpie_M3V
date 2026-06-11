#!/usr/bin/env python3
"""#1 directed campaign — RAS coverage via INLINE control-flow-neutral call/return injection.

The native lever (riscv-dv --num_of_sub_program) hangs the pyflow generator, so we inject self-
contained call/return snippets into the random stream. Each snippet saves/restores ra via mscratch
(so the surrounding program's link register is preserved) and is control-flow-neutral (falls through to
the next instruction). Two kinds:

  CORRECT (RAS push + correctly-predicted pop):
        csrw mscratch, ra
        jal  ra, .Lrx_N          # RAS push, ra = .Lra_N
    .Lra_N: j .Ldone_N           # (return lands here) skip to done
    .Lrx_N: jalr x0, 0(ra)       # ret -> .Lra_N   (RAS predicts .Lra_N = correct)
    .Ldone_N: csrr ra, mscratch

  MISPREDICT (RAS push + pop whose target != RAS top -> mispredict-recovery, ADR-0008):
        csrw mscratch, ra
        jal  ra, .Lmx_N          # RAS push, ra = .Lma_N
    .Lma_N: j .Lmdone_N          # dead (the RAS-predicted target, never executed)
    .Lmx_N: la ra, .Lmdone_N     # change ra so actual ret target != RAS top
        jalr x0, 0(ra)           # ret -> .Lmdone_N (predicted .Lma_N -> MISPREDICT)
    .Lmdone_N: csrr ra, mscratch

Lockstep-safe: DUT and Spike execute the identical snippet; the RAS is a predictor whose mispredict the
DUT recovers (invisible to retire), and Spike has no RAS, so both jalr to the same architectural target.
Coverage build (M1_COV=1); caller merges + measures u_ras.
"""
import sys, re, os
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
import run_riscvdv_lockstep as farm


def _correct(n):
    return [f"                  csrw mscratch, ra",
            f"                  jal  ra, .Lrx_{n}",
            f".Lra_{n}:         j    .Ldone_{n}",
            f".Lrx_{n}:         jalr x0, 0(ra)",
            f".Ldone_{n}:       csrr ra, mscratch"]


def _mispredict(n):
    return [f"                  csrw mscratch, ra",
            f"                  jal  ra, .Lmx_{n}",
            f".Lma_{n}:         j    .Lmdone_{n}",
            f".Lmx_{n}:         la   ra, .Lmdone_{n}",
            f"                  jalr x0, 0(ra)",
            f".Lmdone_{n}:      csrr ra, mscratch"]


def inject_ras(fw: Path, every: int = 22) -> int:
    lines = fw.read_text(encoding="utf-8").splitlines()
    out, n, inj, in_main = [], 0, 0, False
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
                out += _correct(inj) if (inj % 2 == 0) else _mispredict(inj)
                inj += 1
    fw.write_text("\n".join(out) + "\n", encoding="utf-8")
    return inj


def main() -> int:
    os.environ["M1_COV"] = "1"
    seeds = [int(s) for s in sys.argv[1:]] or [2026061501, 2026061502, 2026061503, 2026061504]
    farm.verilator_bin()
    runs = ROOT / "rr"; runs.mkdir(exist_ok=True)
    results = []
    for seed in seeds:
        work = runs / f"seed_{seed}"; work.mkdir(parents=True, exist_ok=True)
        src = farm.generate_seed(seed, work, 8000)
        farm.adapt_asm(src, work / "firmware.S")
        nr = inject_ras(work / "firmware.S")
        matched, ok, waived, msg = farm.sim_compare_seed(seed, work, max_cycles=5_000_000)
        results.append((seed, nr, matched, ok, msg))
        print(f"seed {seed}: ras_snippets={nr} matched={matched} ok={ok} :: {msg}")
    allok = all(r[3] for r in results)
    print(f"\n{'PASS' if allok else 'FAIL'}: RAS inline-injection lockstep — {len(results)} seeds, "
          f"{sum(r[2] for r in results)} commits, {'0 divergence' if allok else 'DIVERGENCE'}")
    return 0 if allok else 1


if __name__ == "__main__":
    sys.exit(main())
