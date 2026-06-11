#!/usr/bin/env python3
"""#1 directed campaign — RAS DEEP-stack coverage via NESTED-call injection (lockstep-safe).

The depth-1 inline injection (inject_ras_inline.py) only ever drove the RAS pointer to 1, so
stack[1..7] were never written (485/512 stack toggle bits cold) and ptr[1]/ptr[2] never toggled.
This injects a self-contained, control-flow-NEUTRAL nested-call chain (unrolled depth 8) that
climbs the RAS pointer 0->8 (writing stack[0..7] with per-level return PCs) and unwinds back,
toggling ptr[2:0] and every stack entry's low (address-reachable) bits.

Mechanism — proper recursion using the program's stack (sp), so EVERY level saves/restores its
own return address and sp is balanced; the chain falls through to .Lrnd and leaves all
architectural state (ra, sp) exactly as it found it -> program-safe AND lockstep-safe (DUT and
Spike run the identical asm; the RAS is a predictor invisible to retire and Spike has no RAS, so
both jalr to the same architectural target). Injected only inside `main`, where riscv-dv has a
valid stack pointer.

  jal  ra, .Lrn0        # push#1 (ptr 0->1); ra = .Lrnd
  j    .Lrnd
.Lrn0: addi sp,sp,-4; sw ra,0(sp); jal ra,.Lrn1; lw ra,0(sp); addi sp,sp,4; jalr x0,0(ra)
.Lrn1: ... (same, calls .Lrn2) ...
.Lrn7: jalr x0,0(ra)    # innermost: just return (pop)
.Lrnd:

Coverage build (M1_COV=1). Caller merges with the farm seeds and measures the u_ras bump.
NOTE: this is FARM-TB injection (same tb_riscvdv_lockstep hierarchy), so it MERGES into the farm
toggle number (unlike the cross-TB directed islands). Lockstep must still PASS (0 divergence).
"""
import sys, re, os
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
import run_riscvdv_lockstep as farm

DEPTH = 8


def _nested(n):
    # Climb the RAS pointer 0->DEPTH with a chain of `jal ra, <next instr>`: each is a call
    # (id_is_jal && rd==ra) so it PUSHES the RAS (ptr++, stack[ptr]<=pc+4), but its target is the
    # immediately-following instruction, so ARCHITECTURALLY the chain is just straight-line
    # execution -> DUT and Spike commit the identical sequence (the RAS is a predictor invisible to
    # retire; Spike has no RAS). NO memory and NO extra register clobber — only ra, which we save in
    # mscratch and restore (an sp-based recursion is unsafe here: riscv-dv `sp` can point into the
    # unified code memory, so `sw ra,0(sp)` self-modifies an instruction -> infinite loop). The
    # count-up 0..7(->wrap 0) toggles ptr[2:0] both directions and writes stack[0..7] with distinct
    # per-jal return PCs (low/address-reachable bits toggle).
    out = [f"                  csrw mscratch, ra"]
    for k in range(DEPTH):
        out.append(f"                  jal  ra, .Lrn{k}_{n}")
        out.append(f".Lrn{k}_{n}:")
    out.append(f"                  csrr ra, mscratch")
    return out


def inject_nested(fw: Path, every: int = 40) -> int:
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
                out += _nested(inj)
                inj += 1
    fw.write_text("\n".join(out) + "\n", encoding="utf-8")
    return inj


def main() -> int:
    os.environ["M1_COV"] = "1"
    seeds = [int(s) for s in sys.argv[1:]] or [2026061701, 2026061702, 2026061703, 2026061704]
    farm.verilator_bin()
    runs = ROOT / "rn"; runs.mkdir(exist_ok=True)
    results = []
    for seed in seeds:
        work = runs / f"seed_{seed}"; work.mkdir(parents=True, exist_ok=True)
        src = farm.generate_seed(seed, work, 8000)
        farm.adapt_asm(src, work / "firmware.S")
        nr = inject_nested(work / "firmware.S")
        matched, ok, waived, msg = farm.sim_compare_seed(seed, work, max_cycles=5_000_000)
        results.append((seed, nr, matched, ok, msg))
        print(f"seed {seed}: nested_chains={nr} matched={matched} ok={ok} :: {msg}")
    allok = all(r[3] for r in results)
    print(f"\n{'PASS' if allok else 'FAIL'}: RAS nested-injection lockstep — {len(results)} seeds, "
          f"{sum(r[2] for r in results)} commits, {'0 divergence' if allok else 'DIVERGENCE'}")
    return 0 if allok else 1


if __name__ == "__main__":
    sys.exit(main())
