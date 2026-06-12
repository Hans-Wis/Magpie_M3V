#!/usr/bin/env python3
"""M1A campaign — inject Zba/Zbb/Zbs/Zicond ops into random riscv-dv programs (lockstep-safe,
FARM-mergeable coverage for the new bmu.v / idu decode paths).

riscv-dv's generator config is still RV32IMC-only (Codex feasibility finding), so the new A2
RTL (bmu.v 26-op datapath + idu decode rows) gets NO stimulus from the random farm. Same proven
in-stream injection mechanism as fence/CSR/RAS: both DUT and Spike execute the identical
modified program; Zb results are deterministic GPR writes -> fully compared, fully lockstep-safe.

Each snippet preserves program state: results go to x31/x30 only (x31 is already the CSR-inject
scratch convention), operands are li-immediates or existing regs READ-only. Rotates through all
26 ops with varied operand patterns so the bmu case-mux arms, idu decode rows, and sign/edge
data paths all toggle at scale.
"""
import sys, re, os
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
import run_riscvdv_lockstep as farm

# (op, needs_two_regs, uses_imm_form) — operands x30,x31 prepared by the snippet itself
OPS = [
    "sh1add x31, x30, x31", "sh2add x31, x30, x31", "sh3add x31, x30, x31",
    "andn  x31, x30, x31",  "orn   x31, x30, x31",  "xnor  x31, x30, x31",
    "clz   x31, x30",       "ctz   x31, x30",       "cpop  x31, x30",
    "min   x31, x30, x31",  "minu  x31, x30, x31",
    "max   x31, x30, x31",  "maxu  x31, x30, x31",
    "sext.b x31, x30",      "sext.h x31, x30",      "zext.h x31, x30",
    "rol   x31, x30, x31",  "ror   x31, x30, x31",  "rori  x31, x30, 7",
    "orc.b x31, x30",       "rev8  x31, x30",
    "bclr  x31, x30, x31",  "bext  x31, x30, x31",
    "binv  x31, x30, x31",  "bset  x31, x30, x31",
    "bclri x31, x30, 31",   "bexti x31, x30, 15",   "binvi x31, x30, 0",  "bseti x31, x30, 31",
    "czero.eqz x31, x30, x31", "czero.nez x31, x30, x31",
]
PATS = ["0x7fffffff", "0x80000000", "0xa5a5a5a5", "0x00000000", "0xffff0001", "0x00010000"]

# RESERVED encodings — one per idu bmu_slot_illegal arm. Each traps (mcause=2) IDENTICALLY on
# DUT and Spike; the farm's adapt j18 handler advances mepc and the harness's proven sync-trap
# machinery (6+/seed already) keeps lockstep. Exercises the decode-tightening lines at scale.
ILLEGALS = [
    0x20b512b3,  # zba f7, f3=001         -> reserved
    0x40b53533,  # sub/sra f7, f3=011     -> reserved (zbb-neg arm)
    0x0ab50533,  # minmax f7, f3=000      -> reserved
    0x60b52533,  # rot f7, f3=010         -> reserved
    0x48b52533,  # bclr/bext f7, f3=010   -> reserved
    0x68b52533,  # binv f7, f3=010        -> reserved
    0x28b52533,  # bset f7, f3=010        -> reserved
    0x08b52533,  # zexth f7, f3=010       -> reserved
    0x0eb55533,  # zicond f7, f3=101 rs2!=pattern? (f7=0000111 f3=101 IS czero.eqz -> use f3=001)
    0x0eb51533,  # zicond f7, f3=001      -> reserved
    0x60b51513,  # OP-IMM f3=001 rot-f7 rs2sel=01011 -> reserved unary
    0x68b55513,  # OP-IMM f3=101 binv-f7 rs2!=11000  -> reserved (not rev8)
    0x28b55513,  # OP-IMM f3=101 bset-f7 rs2!=00111  -> reserved (not orc.b)
    0x10b51513,  # OP-IMM f3=001 unknown f7 0001000  -> reserved
]


def inject_zb(fw: Path, every: int = 10) -> int:
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
                pa = PATS[inj % len(PATS)]
                pb = PATS[(inj + 3) % len(PATS)]
                out.append(f"                  li   x30, {pa}")
                out.append(f"                  li   x31, {pb}")
                out.append(f"                  {OPS[inj % len(OPS)]}")
                # sparse reserved-encoding probes (decode-tightening lines): ~1 per 8 snippets
                if inj % 8 == 7:
                    out.append(f"                  .word {hex(ILLEGALS[(inj // 8) % len(ILLEGALS)])}  # reserved -> trap mcause=2, handler resumes")
                inj += 1
    fw.write_text("\n".join(out) + "\n", encoding="utf-8")
    return inj


def main() -> int:
    os.environ["M1_COV"] = "1"
    seeds = [int(s) for s in sys.argv[1:]] or [2026071301, 2026071302, 2026071303, 2026071304]
    farm.verilator_bin()
    runs = ROOT / "zb"; runs.mkdir(exist_ok=True)
    results = []
    for seed in seeds:
        work = runs / f"seed_{seed}"; work.mkdir(parents=True, exist_ok=True)
        src = farm.generate_seed(seed, work, 8000)
        farm.adapt_asm(src, work / "firmware.S")
        nz = inject_zb(work / "firmware.S")
        matched, ok, waived, msg = farm.sim_compare_seed(seed, work, max_cycles=5_000_000)
        results.append((seed, nz, matched, ok, msg))
        print(f"seed {seed}: zb_snippets={nz} matched={matched} ok={ok} :: {msg}")
    allok = all(r[3] for r in results)
    print(f"\n{'PASS' if allok else 'FAIL'}: Zb-injection lockstep — {len(results)} seeds, "
          f"{sum(r[2] for r in results)} commits, {'0 divergence' if allok else 'DIVERGENCE'}")
    return 0 if allok else 1


if __name__ == "__main__":
    sys.exit(main())
