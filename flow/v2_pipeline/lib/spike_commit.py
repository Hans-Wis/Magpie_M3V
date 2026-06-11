"""RV32 Spike commit-trace helpers for Magpie_M1 v2 pipeline phases."""

from __future__ import annotations

import csv
import re
import subprocess
from pathlib import Path


Commit = dict[str, int]
TrapEvent = dict[str, tuple[int, int]]

COMMIT_RE = re.compile(
    r"core\s+0:\s+3\s+0x(?P<pc>[0-9a-f]+)\s+\(0x(?P<instr>[0-9a-f]+)\)"
    r"(?:\s+x\s*(?P<rd>\d+)\s+0x(?P<wdata>[0-9a-f]+))?"
)


def run_spike(
    *,
    work_dir: Path,
    elf: Path,
    log: Path,
    isa: str = "rv32imc_zicsr_zifencei",
    priv: str = "m",
    pc_base: int = 0x8000_0000,
    instructions: int = 80,
    allowed_returncodes: tuple[int, ...] = (0, 255),
) -> None:
    """Run Spike with commit logging for a bounded RV32 program."""
    cmd = [
        "spike",
        f"--isa={isa}",
        "--priv=m",   # M1A A2: M-only hart, misa parity (S/U bits dropped)
        f"--priv={priv}",
        f"--pc=0x{pc_base:08x}",
        "--log-commits",
        "-l",
        f"--log={log}",
        f"--instructions={instructions}",
        str(elf),
    ]
    result = subprocess.run(cmd, cwd=work_dir, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if result.returncode not in allowed_returncodes:
        result.check_returncode()


def parse_dut_commits(path: Path) -> list[Commit]:
    """Parse the Magpie_M1 DUT commit CSV format."""
    with path.open(newline="", encoding="utf-8") as fh:
        return [
            {
                "idx": int(row["idx"]),
                "pc": int(row["pc"], 16),
                "instr": int(row["instr"], 16),
                "rd": int(row["rd"]),
                "wdata": int(row["wdata"], 16),
                "csr": int(row.get("csr", "0"), 16),
            }
            for row in csv.DictReader(fh)
        ]


def parse_spike_commits(
    log: Path,
    *,
    limit: int,
    pc_base: int = 0x8000_0000,
    stop_pc: int | None = None,
    stop_instrs: set[int] | None = None,
    normalize_wdata_base: bool = True,
    normalize_window: int = 0x10000,
) -> list[Commit]:
    """Parse Spike commit log and normalize PC/writeback addresses to DUT base."""
    stop_instrs = stop_instrs or set()
    rows: list[Commit] = []
    norm_regs = [0] * 32

    def _u32(value: int) -> int:
        return value & 0xFFFF_FFFF

    def _s32(value: int) -> int:
        value &= 0xFFFF_FFFF
        return value - 0x1_0000_0000 if value & 0x8000_0000 else value

    def _sext(value: int, bits: int) -> int:
        sign = 1 << (bits - 1)
        return (value & (sign - 1)) - (value & sign)

    def _rs1(instr: int) -> int:
        return (instr >> 15) & 0x1F

    def _rs2(instr: int) -> int:
        return (instr >> 20) & 0x1F

    def _c_rd(instr: int) -> int:
        return (instr >> 7) & 0x1F

    def _c_rs2(instr: int) -> int:
        return (instr >> 2) & 0x1F

    def _c_rd_p(instr: int) -> int:
        return 8 + ((instr >> 7) & 0x7)

    def _c_rs2_p(instr: int) -> int:
        return 8 + ((instr >> 2) & 0x7)

    def _eval_muldiv(funct3: int, a: int, b: int) -> int:
        if funct3 == 0:
            return _u32(a * b)
        if funct3 == 1:
            return _u32((_s32(a) * _s32(b)) >> 32)
        if funct3 == 2:
            return _u32((_s32(a) * (b & 0xFFFF_FFFF)) >> 32)
        if funct3 == 3:
            return _u32(((a & 0xFFFF_FFFF) * (b & 0xFFFF_FFFF)) >> 32)
        if b == 0:
            return 0xFFFF_FFFF if funct3 in (4, 5) else a
        if funct3 == 4:
            if a == 0x8000_0000 and b == 0xFFFF_FFFF:
                return 0x8000_0000
            sa = _s32(a)
            sb = _s32(b)
            return _u32((abs(sa) // abs(sb)) * (-1 if (sa < 0) ^ (sb < 0) else 1))
        if funct3 == 5:
            return _u32((a & 0xFFFF_FFFF) // (b & 0xFFFF_FFFF))
        if funct3 == 6:
            if a == 0x8000_0000 and b == 0xFFFF_FFFF:
                return 0
            sa = _s32(a)
            sb = _s32(b)
            quot = (abs(sa) // abs(sb)) * (-1 if (sa < 0) ^ (sb < 0) else 1)
            return _u32(sa - quot * sb)
        return _u32((a & 0xFFFF_FFFF) % (b & 0xFFFF_FFFF))

    # ---- M1A A2: Zba/Zbb/Zbs/Zicond evaluation in NORMALIZED space (funct7-aware).
    # The normalizer re-computes OP/OP-IMM results from norm_regs so PC-derived operand
    # chains stay base-normalized; pre-A2 it dispatched on funct3 only and mis-evaluated
    # Zb encodings as base ops (e.g. sh1add -> SLT). Caught by the A2 directed lockstep.
    def _zb_unary(sel, a):
        if sel == 0x00:   # clz
            for i in range(31, -1, -1):
                if (a >> i) & 1: return 31 - i
            return 32
        if sel == 0x01:   # ctz
            for i in range(32):
                if (a >> i) & 1: return i
            return 32
        if sel == 0x02:   # cpop
            return bin(a & 0xFFFF_FFFF).count("1")
        if sel == 0x04:   # sext.b
            return _u32(_sext(a & 0xFF, 8))
        if sel == 0x05:   # sext.h
            return _u32(_sext(a & 0xFFFF, 16))
        return None

    def _eval_zb_op(funct7, funct3, a, b):
        """OP (0x33) Zb/Zicond register forms; None = not a Zb encoding."""
        sh = b & 0x1F
        if funct7 == 0x10:  # Zba
            return {2: _u32((a << 1) + b), 4: _u32((a << 2) + b), 6: _u32((a << 3) + b)}.get(funct3)
        if funct7 == 0x20:  # andn/orn/xnor (SUB/SRA slot)
            return {7: _u32(a & ~b), 6: _u32(a | ~b), 4: _u32(~(a ^ b))}.get(funct3)
        if funct7 == 0x05:  # min/minu/max/maxu
            sa, sb = _s32(a), _s32(b)
            ua, ub = a & 0xFFFF_FFFF, b & 0xFFFF_FFFF
            return {4: _u32(sa if sa < sb else sb), 5: ua if ua < ub else ub,
                    6: _u32(sa if sa > sb else sb), 7: ua if ua > ub else ub}.get(funct3)
        if funct7 == 0x30:  # rol/ror
            if funct3 == 1: return _u32((a << sh) | (a >> ((32 - sh) & 31))) if sh else _u32(a)
            if funct3 == 5: return _u32((a >> sh) | (a << ((32 - sh) & 31))) if sh else _u32(a)
        if funct7 == 0x24 and funct3 == 1: return _u32(a & ~(1 << sh))      # bclr
        if funct7 == 0x24 and funct3 == 5: return (a >> sh) & 1             # bext
        if funct7 == 0x34 and funct3 == 1: return _u32(a ^ (1 << sh))      # binv
        if funct7 == 0x14 and funct3 == 1: return _u32(a | (1 << sh))      # bset
        if funct7 == 0x04 and funct3 == 4: return a & 0xFFFF               # zext.h
        if funct7 == 0x07:  # Zicond
            if funct3 == 5: return 0 if (b & 0xFFFF_FFFF) == 0 else _u32(a)   # czero.eqz
            if funct3 == 7: return 0 if (b & 0xFFFF_FFFF) != 0 else _u32(a)   # czero.nez
        return None

    def _eval_zb_imm(funct7, funct3, rs2f, a):
        """OP-IMM (0x13) f3=001/101 Zb forms; None = base/unknown."""
        sh = rs2f & 0x1F
        if funct3 == 1:
            if funct7 == 0x30: return _u32(_zb_unary(rs2f, a)) if _zb_unary(rs2f, a) is not None else None
            if funct7 == 0x24: return _u32(a & ~(1 << sh))                  # bclri
            if funct7 == 0x34: return _u32(a ^ (1 << sh))                   # binvi
            if funct7 == 0x14: return _u32(a | (1 << sh))                   # bseti
        if funct3 == 5:
            if funct7 == 0x30:                                              # rori
                return _u32((a >> sh) | (a << ((32 - sh) & 31))) if sh else _u32(a)
            if funct7 == 0x24: return (a >> sh) & 1                         # bexti
            if funct7 == 0x14 and rs2f == 0x07:                             # orc.b
                r = 0
                for byte in range(4):
                    if (a >> (8 * byte)) & 0xFF: r |= 0xFF << (8 * byte)
                return _u32(r)
            if funct7 == 0x34 and rs2f == 0x18:                             # rev8
                return _u32(((a & 0xFF) << 24) | ((a & 0xFF00) << 8) |
                            ((a >> 8) & 0xFF00) | ((a >> 24) & 0xFF))
        return None

    def _eval_norm_wdata(instr: int, pc: int, rd: int, raw_wdata: int) -> int:
        if rd == 0:
            return 0
        if (instr & 0x3) != 0x3:
            funct3 = (instr >> 13) & 0x7
            op = instr & 0x3
            if op == 0x0 and funct3 == 0x0:
                imm = ((instr >> 7) & 0xF) << 6 | ((instr >> 11) & 0x3) << 4 | ((instr >> 5) & 0x1) << 3 | ((instr >> 6) & 0x1) << 2
                return _u32(norm_regs[2] + imm)
            if op == 0x1:
                if funct3 == 0x0:
                    return _u32(norm_regs[rd] + _sext((instr >> 2) & 0x1F | ((instr >> 7) & 0x20), 6))
                if funct3 == 0x3:
                    if rd == 2:
                        imm = ((instr >> 3) & 0x3) << 7 | ((instr >> 5) & 0x1) << 6 | ((instr >> 2) & 0x1) << 5 | ((instr >> 6) & 0x1) << 4 | ((instr >> 12) & 0x1) << 9
                        return _u32(norm_regs[2] + _sext(imm, 10))
                    return _u32(_sext(((instr >> 2) & 0x1F) | ((instr >> 7) & 0x20), 6) << 12)
                if funct3 == 0x2:
                    return _u32(_sext(((instr >> 2) & 0x1F) | ((instr >> 7) & 0x20), 6))
                if funct3 == 0x1:
                    return _u32(pc + 2)
                if funct3 == 0x4:
                    subop = (instr >> 10) & 0x3
                    shamt = (instr >> 2) & 0x1F
                    lhs = norm_regs[_c_rd_p(instr)]
                    rhs = norm_regs[_c_rs2_p(instr)]
                    if subop == 0:
                        return _u32(lhs >> shamt)
                    if subop == 1:
                        return _u32(_s32(lhs) >> shamt)
                    if subop == 2:
                        return _u32(lhs & _sext(((instr >> 2) & 0x1F) | ((instr >> 7) & 0x20), 6))
                    op3 = ((instr >> 12) & 0x1) << 2 | ((instr >> 5) & 0x3)
                    return _u32({0: lhs - rhs, 1: lhs ^ rhs, 2: lhs | rhs, 3: lhs & rhs}.get(op3, raw_wdata))
            if op == 0x2 and funct3 == 0x4:
                if ((instr >> 12) & 0x1) == 0:
                    return norm_regs[_c_rs2(instr)]  # C.MV
                return _u32(pc + 2) if _c_rs2(instr) == 0 else _u32(norm_regs[_c_rd(instr)] + norm_regs[_c_rs2(instr)])
            if op == 0x2 and funct3 == 0x0:
                return _u32(norm_regs[rd] << ((instr >> 2) & 0x1F))
            return raw_wdata


        opcode = instr & 0x7F
        funct3 = (instr >> 12) & 0x7
        a = norm_regs[_rs1(instr)]
        b = norm_regs[_rs2(instr)]
        imm_i = _sext((instr >> 20) & 0xFFF, 12)
        # CSR read of a PC-holding CSR (mepc/mtvec/mtval) returns an absolute PC; the DUT runs at base
        # 0x0 while Spike runs at pc_base, so normalize by subtracting pc_base. This is the harness fix
        # that enables THROUGH-TRAP per-commit lockstep (a handler reading mepc/mcause then mret) —
        # previously the mepc read mismatched by pc_base. mcause/mstatus are not PC-based and pass as-is.
        if opcode == 0x73 and funct3 != 0:
            csr = (instr >> 20) & 0xFFF
            if csr in (0x341, 0x305, 0x343) and raw_wdata >= pc_base:  # mepc, mtvec, mtval
                return _u32(raw_wdata - pc_base)
        if opcode == 0x37:
            return _u32(instr & 0xFFFF_F000)
        if opcode == 0x17:
            return _u32(pc + (instr & 0xFFFF_F000))
        if opcode == 0x6F or opcode == 0x67:
            return _u32(pc + 4)
        if opcode == 0x13:
            if funct3 == 0:
                return _u32(a + imm_i)
            if funct3 == 2:
                return 1 if _s32(a) < imm_i else 0
            if funct3 == 3:
                return 1 if (a & 0xFFFF_FFFF) < (imm_i & 0xFFFF_FFFF) else 0
            if funct3 == 4:
                return _u32(a ^ imm_i)
            if funct3 == 6:
                return _u32(a | imm_i)
            if funct3 == 7:
                return _u32(a & imm_i)
            if funct3 in (1, 5):
                zb = _eval_zb_imm((instr >> 25) & 0x7F, funct3, (instr >> 20) & 0x1F, a)
                if zb is not None:
                    return zb
            if funct3 == 1:
                return _u32(a << ((instr >> 20) & 0x1F))
            if funct3 == 5:
                return _u32((_s32(a) if (instr & 0x4000_0000) else (a & 0xFFFF_FFFF)) >> ((instr >> 20) & 0x1F))
        if opcode == 0x33:
            if ((instr >> 25) & 0x7F) == 1:
                return _eval_muldiv(funct3, a, b)
            zb = _eval_zb_op((instr >> 25) & 0x7F, funct3, a, b)
            if zb is not None:
                return zb
            if funct3 == 0:
                return _u32(a - b if (instr & 0x4000_0000) else a + b)
            if funct3 == 1:
                return _u32(a << (b & 0x1F))
            if funct3 == 2:
                return 1 if _s32(a) < _s32(b) else 0
            if funct3 == 3:
                return 1 if (a & 0xFFFF_FFFF) < (b & 0xFFFF_FFFF) else 0
            if funct3 == 4:
                return _u32(a ^ b)
            if funct3 == 5:
                return _u32((_s32(a) if (instr & 0x4000_0000) else (a & 0xFFFF_FFFF)) >> (b & 0x1F))
            if funct3 == 6:
                return _u32(a | b)
            if funct3 == 7:
                return _u32(a & b)
        return raw_wdata

    for line in log.read_text(encoding="utf-8", errors="replace").splitlines():
        match = COMMIT_RE.search(line)
        if not match:
            continue
        pc = int(match.group("pc"), 16) - pc_base
        if pc < 0:
            continue
        if stop_pc is not None and pc >= stop_pc:
            break
        instr = int(match.group("instr"), 16)
        if instr in stop_instrs:
            break
        rd = int(match.group("rd") or "0")
        wdata = int(match.group("wdata") or "0", 16)
        if normalize_wdata_base:
            wdata = _eval_norm_wdata(instr, pc, rd, wdata)
        if rd != 0:
            assert wdata is not None, f"normalizer returned None for instr={instr:#x} pc={pc:#x}"
            norm_regs[rd] = wdata
        rows.append({"idx": len(rows), "pc": pc, "instr": instr, "rd": rd, "wdata": wdata})
        if len(rows) >= limit:
            break
    return rows


def write_commit_csv(path: Path, rows: list[Commit]) -> None:
    path.write_text(
        "idx,pc,instr,rd,wdata\n"
        + "".join(
            f"{r['idx']},{r['pc']:08x},{r['instr']:08x},{r['rd']},{r['wdata']:08x}\n"
            for r in rows
        ),
        encoding="utf-8",
    )


TIMING_CSRS = {0xB00, 0xB02, 0xB80, 0xB82, 0xC00, 0xC01, 0xC02, 0xC80, 0xC81, 0xC82}


def _is_timing_csr_read(row: Commit) -> bool:
    instr = row["instr"]
    csr = row.get("csr", ((instr >> 20) & 0xFFF) if ((instr & 0x7F) == 0x73 and ((instr >> 12) & 0x7) != 0) else 0)
    return (
        (instr & 0x7F) == 0x73
        and ((instr >> 12) & 0x7) != 0
        and row["rd"] != 0
        and csr in TIMING_CSRS
    )


def compare_commits(dut: list[Commit], spike: list[Commit], *, label: str = "lockstep") -> tuple[bool, str]:
    if len(dut) != len(spike):
        return False, f"{label} commit count mismatch: dut={len(dut)} spike={len(spike)}"
    for drow, srow in zip(dut, spike):
        for key in ["pc", "instr", "rd", "wdata"]:
            if key == "wdata" and _is_timing_csr_read(drow) and _is_timing_csr_read(srow):
                continue
            if drow[key] != srow[key]:
                return (
                    False,
                    "{label} first mismatch at idx={idx}: {key} dut={dut:08x} spike={spike:08x}".format(
                        label=label,
                        idx=drow["idx"],
                        key=key,
                        dut=drow[key],
                        spike=srow[key],
                    ),
                )
    return True, f"{label} matched {len(dut)} commits"


def parse_trap_events(path: Path) -> TrapEvent:
    events: TrapEvent = {}
    with path.open(newline="", encoding="utf-8") as fh:
        for row in csv.DictReader(fh):
            events[row["event"]] = (int(row["pc"], 16), int(row["value"], 16))
    return events


def check_expected_events(
    events: TrapEvent,
    expected: dict[str, tuple[int | None, int]],
) -> tuple[bool, str]:
    for name, (expected_pc, expected_value) in expected.items():
        if name not in events:
            return False, f"missing trap event {name}"
        pc, value = events[name]
        if expected_pc is not None and pc != expected_pc:
            return False, f"{name} pc mismatch: got 0x{pc:08x} expected 0x{expected_pc:08x}"
        if value != expected_value:
            return False, f"{name} value mismatch: got 0x{value:08x} expected 0x{expected_value:08x}"
    return True, "trap events matched expected values"
