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
    0x00b52063,  # BRANCH f3=010 (reserved) — ring-FIRST: the 14-probe cap starves tail slots
    0xfeb50533,  # OP outer-default: f7=1111111 matches no Zb group -> idu OP funct7 default
    0x1eb55513,  # OP-IMM shift-right outer-default
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
# illegal 16-bit C encodings (cdec illegal legs: FP / RV64-only) — trap identically both sides
C_ILLEGALS = [0x2000, 0xa000, 0x7002, 0x9c01]  # +c.subw (RV64-only C1 leg)  # c.fld(q0 f3=001) / c.fsd(q0 f3=101) / c.flwsp-class(q2)


# line-coverage mopup snippets (each self-contained, state-restoring, lockstep-safe):
MOPUP = [
    # RV32C load/store group (cdec C.LW/C.SW/C.LWSP/C.SWSP) — sp-window scratch, x8 saved
    # sp is NOT trustworthy mid-program (riscv-dv uses x2 as a general reg with random
    # values -> misalign storm). All memory work happens in our own aligned scratch blob;
    # sp/x8/x9 fully saved/restored there.
    ["                  csrw mscratch, x8",
     "                  la   x8, zbcov_scratch",
     "                  sw   x9, 0(x8)",
     "                  sw   sp, 4(x8)",
     "                  addi sp, x8, 8",
     "                  c.swsp x31, 0(sp)",
     "                  c.lwsp x30, 0(sp)",
     "                  sw   x31, 8(x8)",
     "                  c.lw  x9, 8(x8)",
     "                  c.sw  x9, 8(x8)",
     "                  lw   sp, 4(x8)",
     "                  lw   x9, 0(x8)",
     "                  csrr x8, mscratch"],
    # C.JAL (cdec C1 001) + RAS push/pop same-region (ras.v same-cycle attempt)
    ["                  csrw mscratch, ra",
     "                  c.jal 81191f",
     "81191:            jal  ra, 81192f",
     "81192:            jal  ra, 81193f",
     "81193:            la   ra, 81194f",
     "                  jalr x0, 0(ra)",
     "81194:            csrr ra, mscratch"],
    # DIV spec edges: INT_MIN/-1 overflow + div-by-zero (deterministic per spec)
    ["                  li   x30, 0x80000000",
     "                  li   x31, -1",
     "                  div  x31, x30, x31",
     "                  rem  x31, x30, x30",
     "                  li   x31, 0",
     "                  divu x31, x30, x31",
     "                  li   x31, 0",
     "                  rem  x31, x30, x31"],
    # CSR same-addr write->set-read forward (core.v CSR_OP_S id_csr_rdata leg)
    ["                  csrw mscratch, x30",
     "                  csrrs x31, mscratch, x0",
     "                  csrrc x31, mscratch, x0"],
]

EVERY = int(os.environ.get("M1_ZB_EVERY", "10"))
PROBE_W = int(os.environ.get("M1_ZB_PROBE_W", "8"))   # .word probe spacing
PROBE_H = int(os.environ.get("M1_ZB_PROBE_H", "24"))   # .hword probe spacing

def inject_zb(fw: Path, every: int = None, rot0: int = 0) -> int:
    every = every or EVERY
    lines = fw.read_text(encoding="utf-8").splitlines()
    out, n, inj, in_main = [], 0, rot0, False
    nw, nh = 0, 0   # per-program probe caps (big programs would otherwise accumulate 100+ traps)   # rot0: per-seed rotation offset so the
    # full OPS/ILLEGALS/MOPUP rings cycle across the seed set (tail ops were under-cycled)
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
                # EXECUTED reserved probes, ROTATING (all idu reserved arms + cdec C-illegal
                # legs need distinct encodings). Density = the zb2-proven safe recipe
                # (1/8 .word; .hword sparser — high densities overwhelm the trap-waiver
                # machinery, measured). Both sides trap identically; handler resumes.
                if inj % PROBE_W == 7 % PROBE_W and nw < int(os.environ.get("M1_ZB_CAP","14")):
                    out.append(f"                  .word {hex(ILLEGALS[(inj // PROBE_W) % len(ILLEGALS)])}   # reserved -> trap, rotate arms")
                    nw += 1
                if inj % PROBE_H == 11 % PROBE_H and nh < 4:
                    out.append(f"                  .hword {hex(C_ILLEGALS[(inj // PROBE_H) % len(C_ILLEGALS)])}  # C-illegal leg -> trap")
                    out.append("                  .hword 0x0001")
                    nh += 1
                # RAS same-cycle push+pop attempt: ret on the jal fall-through (wrong path,
                # pre-decode pop while the jal pushes; squashed before retire)
                if inj % 16 == 13:
                    out.append("                  csrw mscratch, ra")
                    out.append(f"                  jal  ra, 82{inj}1f")
                    out.append("                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop")
                    out.append(f"82{inj}1:          csrr ra, mscratch")
                # line-mopup snippets: ~1 per 5 snippets, rotating classes
                if inj % 5 == 4:
                    for m in MOPUP[(inj // 5) % len(MOPUP)]:
                        out.append(m.replace("81191", f"81{inj}1").replace("81192", f"81{inj}2").replace("81193", f"81{inj}3").replace("81194", f"81{inj}4"))
                inj += 1
    out += ["", ".section .data", ".balign 8",
            "zbcov_scratch:", ".word 0, 0, 0, 0   # inject_zb aligned scratch (sp-independent)"]
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
        src = farm.generate_seed(seed, work, int(os.environ.get("M1_ZB_INSTR", "8000")))
        farm.adapt_asm(src, work / "firmware.S")
        nz = inject_zb(work / "firmware.S", rot0=(seeds.index(seed) * 7) % 31)
        matched, ok, waived, msg = farm.sim_compare_seed(seed, work, max_cycles=5_000_000)
        results.append((seed, nz, matched, ok, msg))
        print(f"seed {seed}: zb_snippets={nz} matched={matched} ok={ok} :: {msg}")
    allok = all(r[3] for r in results)
    print(f"\n{'PASS' if allok else 'FAIL'}: Zb-injection lockstep — {len(results)} seeds, "
          f"{sum(r[2] for r in results)} commits, {'0 divergence' if allok else 'DIVERGENCE'}")
    return 0 if allok else 1


if __name__ == "__main__":
    sys.exit(main())
