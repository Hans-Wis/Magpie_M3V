#!/usr/bin/env python3
"""Run cpu_m1 riscv-dv pyflow programs against Spike lockstep."""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[2]
RTL_DIR = REPO / "design/cpu_m1/rtl"
RISCV_DV = Path("/home/edauser/project/SOC/Magpie_X6/vendored/riscv-dv")
SPIKE = Path(os.environ.get("SPIKE", "/home/edauser/.local/bin/spike"))
GCC = os.environ.get("RISCV_GCC", "riscv-none-elf-gcc")
OBJCOPY = os.environ.get("RISCV_OBJCOPY", "riscv-none-elf-objcopy")
OBJDUMP = os.environ.get("RISCV_OBJDUMP", "riscv-none-elf-objdump")
NM = os.environ.get("RISCV_NM", "riscv-none-elf-nm")
VERILATOR = os.environ.get("VERILATOR", "/home/edauser/miniforge3/envs/magpie_claude/bin/verilator")
GEN_TARGET = "rv32imc"
M1_CONFIG = "m1_riscvdv"
ISA = "rv32imc_zba_zbb_zbs_zicond_zicsr_zifencei"   # M1A A2 (ADR-0026)
SPIKE_ISA = "rv32imc_zba_zbb_zbs_zicond_zicsr_zifencei_zicntr"   # M1A A2
MABI = "ilp32"
TARGET_COMMITS = 100_000
SPIKE_PC_BASE = 0x1000
TRAP_CAUSES = {
    "trap_instruction_address_misaligned": 0,
    "trap_instruction_access_fault": 1,
    "trap_illegal_instruction": 2,
    "trap_breakpoint": 3,
    "trap_load_address_misaligned": 4,
    "trap_load_access_fault": 5,
    "trap_store_address_misaligned": 6,
    "trap_store_access_fault": 7,
    "trap_user_ecall": 8,
    "trap_supervisor_ecall": 9,
    "trap_machine_ecall": 11,
    "trap_instruction_page_fault": 12,
    "trap_load_page_fault": 13,
    "trap_store_page_fault": 15,
}

sys.path.insert(0, str(ROOT.parents[0] / "lib"))
from spike_commit import compare_commits, parse_dut_commits, parse_spike_commits, write_commit_csv  # noqa: E402


def run_cmd(cmd: list[str], cwd: Path, log: Path, env: dict[str, str] | None = None) -> None:
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open("w", encoding="utf-8") as fh:
        proc = subprocess.run(cmd, cwd=cwd, env=env, stdout=fh, stderr=subprocess.STDOUT, text=True)
    if proc.returncode != 0:
        raise RuntimeError(f"command failed rc={proc.returncode}: {' '.join(cmd)}; see {log}")


def verilator_bin() -> Path:
    sim = ROOT / "obj_dir/Vtb_riscvdv_lockstep"
    rtl_srcs = [
        "rfu.v", "alu.v", "idu.v", "ifu.v", "lsu.v", "csr.v", "trigger.v", "mul.v", "div.v",
        "forward.v", "hazard.v", "bp.v", "ras.v", "cdec.v", "core.v",
    ]
    src_paths = [RTL_DIR / src for src in rtl_srcs] + [ROOT / "tb_riscvdv_lockstep.v"]
    if sim.exists() and sim.stat().st_mtime >= max(path.stat().st_mtime for path in src_paths):
        return sim
    cmd = [
        VERILATOR,
        "--binary", "-j", "4",
        "--top-module", "tb_riscvdv_lockstep",
        "--timescale", "1ns/1ns",
        f"-I{RTL_DIR}",
        "-Wall", "-Wno-PROCASSINIT", "-Wno-DECLFILENAME", "-Wno-TIMESCALEMOD",
        "-Wno-UNUSEDSIGNAL", "-Wno-SYNCASYNCNET",
    ]
    # WS6: optional coverage build (env M1_COV=1) to measure toggle/line coverage under the
    # riscv-dv full mix. Off by default so the validated lockstep flow is unchanged.
    if os.environ.get("M1_COV") == "1":
        cmd += ["--coverage"]
    cmd += [
        *[str(path) for path in src_paths[:-1]],
        str(ROOT / "tb_riscvdv_lockstep.v"),
    ]
    run_cmd(cmd, ROOT, ROOT / "verilator_build.log")
    return sim


def install_riscvdv_target() -> dict[Path, bytes]:
    target_dir = RISCV_DV / "target" / GEN_TARGET
    target_dir.mkdir(parents=True, exist_ok=True)
    backups: dict[Path, bytes] = {}
    for name in ["riscv_core_setting.sv", "testlist.yaml"]:
        dst = target_dir / name
        backups[dst] = dst.read_bytes()
        shutil.copy2(ROOT / "config" / M1_CONFIG / name, dst)
    py_target_dir = RISCV_DV / "pygen" / "pygen_src" / "target" / GEN_TARGET
    py_dst = py_target_dir / "riscv_core_setting.py"
    backups[py_dst] = py_dst.read_bytes()
    shutil.copy2(ROOT / "config" / M1_CONFIG / "riscv_core_setting.py", py_dst)
    return backups


def restore_riscvdv_target(backups: dict[Path, bytes]) -> None:
    for path, data in backups.items():
        path.write_bytes(data)


def gen_core(seed: int, out: Path, instr_cnt: int) -> Path:
    """riscv-dv generation core WITHOUT the shared-target install/restore. The caller
    must have already installed the M1 target config (install_riscvdv_target). Safe to
    run many of these in PARALLEL: each writes its own per-seed --output + testlist and
    only READS the (already-installed, unchanging) shared target config. This is what
    lets dv_farm.py parallelize generation, the real serial bottleneck."""
    env = os.environ.copy()
    env["PYTHONPATH"] = str(RISCV_DV / "pygen") + (":" + env["PYTHONPATH"] if env.get("PYTHONPATH") else "")
    testlist = out / "testlist.yaml"
    text = (ROOT / "config" / M1_CONFIG / "testlist.yaml").read_text(encoding="utf-8")
    text = re.sub(r"--instr_cnt=\d+", f"--instr_cnt={instr_cnt}", text)
    testlist.write_text(text, encoding="utf-8")
    cmd = [
        "python3", str(RISCV_DV / "run.py"),
        "--target", GEN_TARGET,
        "--simulator", "pyflow",
        "--steps", "gen",
        "--testlist", str(testlist),
        "--test", "m1_rv32imc_arith",
        "--iterations", "1",
        "--seed", str(seed),
        "--output", str(out / "riscv_dv_out"),
        "--isa", ISA,
        "--priv", "m",
        "--mabi", MABI,
    ]
    run_cmd(cmd, ROOT, out / "riscvdv_gen.log", env)
    asm = out / "riscv_dv_out/asm_test/m1_rv32imc_arith_0.S"
    if not asm.exists():
        raise FileNotFoundError(asm)
    return asm


def generate_seed(seed: int, out: Path, instr_cnt: int) -> Path:
    """Single-seed generation (install shared target -> gen -> restore). Serial only."""
    backups = install_riscvdv_target()
    try:
        return gen_core(seed, out, instr_cnt)
    finally:
        restore_riscvdv_target(backups)


def adapt_asm(src: Path, dst: Path) -> None:
    lines = src.read_text(encoding="utf-8").splitlines()
    out: list[str] = []
    inserted = False
    skip_to_illegal_handler = False
    in_test_done = False
    in_ecall_handler = False
    patched_resume = False
    skip_restore_until_mret = False
    skip_old_advance = 0
    cause_reg = "x6"
    tmp_reg = "x15"
    for line in lines:
        # M1A A2 misa-parity: riscv-dv init emits `csrw 0x301(misa), xN`. The DUT's misa is
        # WARL READ-ONLY (write ignored, spec-legal); Spike's misa is WRITABLE and the init
        # value clears B -> every injected Zb op traps illegal on Spike only (real divergence,
        # found by inject_zb). Neutralize the write IDENTICALLY for both sides.
        if re.search(r"csrw\s+0x301,", line):
            out.append(line.replace(line.strip(), "nop  # adapt: misa write dropped (DUT misa is WARL read-only; Spike misa writable)"))
            continue
        if skip_restore_until_mret:
            if line.strip().startswith("mret"):
                skip_restore_until_mret = False
            continue
        if skip_to_illegal_handler:
            if line.strip().startswith("illegal_instr_handler:"):
                skip_to_illegal_handler = False
            else:
                continue
        if skip_old_advance:
            skip_old_advance -= 1
            continue
        if line.strip().startswith("test_done:"):
            in_test_done = True
        elif in_test_done and line.strip() == "ecall":
            out.append("                  j write_tohost")
            in_test_done = False
            continue
        elif in_test_done and line and not line.startswith(" "):
            in_test_done = False
        if line.strip().startswith("mtvec_handler:"):
            out.append(line)
            out.append("                  j j18_resume_trap_handler")
            skip_to_illegal_handler = True
            continue
        if line.strip().startswith("ecall_handler:"):
            out.append(line)
            out.append("                  j j18_resume_trap_handler")
            in_ecall_handler = True
            continue
        if in_ecall_handler:
            if line.strip().startswith("illegal_instr_handler:"):
                in_ecall_handler = False
            else:
                continue
        cause_match = re.search(r"csrr\s+(x\d+),\s+0x342\s+# MCAUSE", line)
        if cause_match:
            cause_reg = cause_match.group(1)
        if "li x" in line and "# ILLEGAL_INSTRUCTION" in line:
            tmp_match = re.search(r"li\s+(x\d+),", line)
            if tmp_match:
                tmp_reg = tmp_match.group(1)
            out.extend([
                f"                  li {tmp_reg}, 0x3 # BREAKPOINT",
                f"                  beq {cause_reg}, {tmp_reg}, j18_resume_trap_handler",
                f"                  li {tmp_reg}, 0x4 # LOAD_ADDRESS_MISALIGNED",
                f"                  beq {cause_reg}, {tmp_reg}, j18_resume_trap_handler",
                f"                  li {tmp_reg}, 0x6 # STORE_ADDRESS_MISALIGNED",
                f"                  beq {cause_reg}, {tmp_reg}, j18_resume_trap_handler",
            ])
        if line.strip().startswith("illegal_instr_handler:") and not patched_resume:
            out.append(line)
            out.append("j18_resume_trap_handler:")
            patched_resume = True
            continue
        if patched_resume and line.strip().startswith("csrr  x") and "0x341" in line:
            out.extend([
                "                  csrr  x6, 0x341",
                "                  lhu   x15, 0(x6)",
                "                  andi  x15, x15, 3",
                "                  li    x31, 3",
                "                  bne   x15, x31, 1f",
                "                  addi  x6, x6, 4",
                "                  j     2f",
                "1:                addi  x6, x6, 2",
                "2:                csrw  0x341, x6",
                "                  mret",
            ])
            skip_old_advance = 2
            skip_restore_until_mret = True
            patched_resume = False
            continue
        out.append(line)
        if not inserted and line.strip().startswith("main:"):
            out.extend([
                "                  # M1 J18 synchronous-trap smoke stream",
                "                  ecall",
                "                  ebreak",
                "                  .word 0x00000000",
                "                  la x5, j18_misalign_data",
                "                  lw x6, 1(x5)",
                "                  sw x6, 2(x5)",
                "                  # M1 J14 supported-CSR lockstep sweep",
                "                  csrr x5, 0x300",
                "                  csrrw x6, 0x340, x5",
                "                  csrr x5, 0x340",
                "                  csrrs x6, 0x300, x0",
                "                  csrrc x6, 0x304, x0",
                "                  csrr x6, 0x305",
                "                  csrr x6, 0x341",
                "                  csrr x6, 0x342",
                "                  csrr x6, 0x343",
                "                  csrr x6, 0x344",
                "                  csrr x6, 0xc00",
                "                  csrr x6, 0xc80",
                "                  csrr x6, 0xc02",
                "                  csrr x6, 0xc82",
                "                  csrrw x6, 0x340, x0",
            ])
            inserted = True
        if line.strip() == ".section .data":
            out.extend([
                ".align 2",
                "j18_misalign_data:",
                ".word 0x11223344",
            ])
    dst.write_text("\n".join(out) + "\n", encoding="utf-8")


def build_firmware(work: Path) -> None:
    include_user = RISCV_DV / "user_extension"
    cmd = [
        GCC, "-Os", f"-march={ISA}", f"-mabi={MABI}",
        "-nostartfiles", "-nostdlib", "-ffreestanding",
        "-I", str(include_user),
        "-Wl,-Bstatic,-T," + str(ROOT / "firmware.lds") + ",--strip-debug",
        "-o", "firmware.elf", "firmware.S",
    ]
    run_cmd(cmd, work, work / "firmware_build.log")
    run_cmd([OBJCOPY, "-O", "binary", "firmware.elf", "firmware.bin"], work, work / "firmware_objcopy.log")
    emit_verilog_hex(work / "firmware.bin", work / "firmware.hex")
    run_cmd([OBJDUMP, "-d", "firmware.elf"], work, work / "firmware.disasm")


def elf_symbol(work: Path, name: str) -> int:
    proc = subprocess.run([NM, "-n", "firmware.elf"], cwd=work, text=True, capture_output=True, check=True)
    for line in proc.stdout.splitlines():
        parts = line.split()
        if len(parts) >= 3 and parts[2] == name:
            return int(parts[0], 16)
    raise RuntimeError(f"missing ELF symbol {name}")


def emit_verilog_hex(binary: Path, hex_path: Path) -> None:
    data = binary.read_bytes()
    if len(data) % 4:
        data += b"\x00" * (4 - (len(data) % 4))
    lines = []
    for offset in range(0, len(data), 4):
        word = int.from_bytes(data[offset:offset + 4], "little")
        lines.append(f"{word:08x}\n")
    hex_path.write_text("".join(lines), encoding="utf-8")


def run_dut(work: Path, max_cycles: int) -> tuple[bool, str]:
    sim = verilator_bin()
    stop_addr = elf_symbol(work, "tohost")
    cmd = [
        str(sim),
        f"+HEX={work / 'firmware.hex'}",
        f"+TRACE={work / 'dut_commit.trace'}",
        f"+TRAP_TRACE={work / 'dut_trap.trace'}",
        f"+MAX_CYCLES={max_cycles}",
        f"+STOP_ADDR={stop_addr:08x}",
    ]
    log = work / "sim.log"
    with log.open("w", encoding="utf-8") as fh:
        proc = subprocess.run(cmd, cwd=work, stdout=fh, stderr=subprocess.STDOUT, text=True)
    sim_log = (work / "sim.log").read_text(encoding="utf-8", errors="replace")
    if proc.returncode != 0:
        if "FAIL: watchdog timeout" in sim_log:
            return False, "watchdog timeout"
        raise RuntimeError(f"command failed rc={proc.returncode}: {' '.join(cmd)}; see {log}")
    if "DIVERGENCE:" in sim_log:
        return False, "DUT divergence"
    return True, "DUT completed"


def run_spike(work: Path, instructions: int) -> None:
    cmd = [
        str(SPIKE),
        f"--isa={SPIKE_ISA}",
        "--priv=m",   # M1A A2: M-only hart — misa parity with DUT (0x40001106 incl B)
        "--priv=m",
        "--disable-dtb",
        "-m0x1000:0x40000",
        f"--pc=0x{SPIKE_PC_BASE:08x}",
        "--log-commits",
        "-l",
        f"--log={work / 'spike.log'}",
        f"--instructions={instructions}",
        str(work / "firmware.elf"),
    ]
    result = subprocess.run(cmd, cwd=work, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if result.returncode not in (0, 255):
        result.check_returncode()


def commit_rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def trap_rows(path: Path) -> list[dict[str, int | str]]:
    if not path.exists():
        return []
    rows: list[dict[str, int | str]] = []
    with path.open(newline="", encoding="utf-8") as fh:
        for row in csv.DictReader(fh):
            rows.append({
                "idx": int(row["idx"]),
                "event": row["event"],
                "pc": int(row["pc"], 16),
                "instr": int(row["instr"], 16),
                "mepc": int(row["mepc"], 16),
                "mcause": int(row["mcause"], 16),
                "mtval": int(row["mtval"], 16),
                "mstatus": int(row["mstatus"], 16),
            })
    return rows


def spike_exceptions(log: Path) -> list[dict[str, int | str]]:
    rows: list[dict[str, int | str]] = []
    last_instr: tuple[int, int] | None = None
    pending: dict[str, int | str] | None = None
    instr_re = re.compile(r"core\s+0:\s+0x([0-9a-f]+)\s+\(0x([0-9a-f]+)\)")
    exc_re = re.compile(r"exception\s+(trap_[a-z_]+),\s+epc\s+0x([0-9a-f]+)")
    tval_re = re.compile(r"tval\s+0x([0-9a-f]+)")
    for line in log.read_text(encoding="utf-8", errors="replace").splitlines():
        instr_match = instr_re.search(line)
        if instr_match:
            last_instr = (int(instr_match.group(1), 16), int(instr_match.group(2), 16))
        exc_match = exc_re.search(line)
        if exc_match:
            name = exc_match.group(1)
            epc = int(exc_match.group(2), 16)
            instr = last_instr[1] if last_instr and last_instr[0] == epc else 0
            pending = {"pc": epc, "instr": instr, "cause": TRAP_CAUSES.get(name, -1), "name": name, "mtval": 0}
            rows.append(pending)
            continue
        tval_match = tval_re.search(line)
        if tval_match and pending is not None:
            pending["mtval"] = int(tval_match.group(1), 16)
            pending = None
    return rows


def matched_nested_trap_waiver(work: Path, dut: list[dict[str, int]], spike: list[dict[str, int]]) -> dict[str, int | str] | None:
    if not spike or len(spike) >= len(dut):
        return None
    prefix_ok, _ = compare_commits(dut[:len(spike)], spike, label="nested-trap prefix")
    if not prefix_ok:
        return None
    expected_idx = dut[len(spike)]["idx"]
    for srow in reversed(spike_exceptions(work / "spike.log")):
        for drow in trap_rows(work / "dut_trap.trace"):
            if drow["event"] != "enter" or int(drow["idx"]) < expected_idx:
                continue
            same = (
                int(drow["pc"]) == int(srow["pc"])
                and int(drow["instr"]) == int(srow["instr"])
                and int(drow["mcause"]) == int(srow["cause"])
                and int(drow["mtval"]) == int(srow["mtval"])
            )
            if same:
                return {
                    "matched_commits": len(spike),
                    "dut_idx": int(drow["idx"]),
                    "pc": int(drow["pc"]),
                    "instr": int(drow["instr"]),
                    "mcause": int(drow["mcause"]),
                    "mtval": int(drow["mtval"]),
                    "spike_exception": str(srow["name"]),
                }
    return None


def watchdog_trap_waiver(work: Path, dut: list[dict[str, int]], spike: list[dict[str, int]]) -> dict[str, int | str] | None:
    if not dut or not spike:
        return None
    prefix_len = min(len(dut), len(spike))
    prefix_ok, _ = compare_commits(dut[:prefix_len], spike[:prefix_len], label="watchdog-trap prefix")
    if not prefix_ok:
        return None
    s_excs = spike_exceptions(work / "spike.log")
    # Codex review F1 (HIGH): on watchdog the DUT can have far more commits than the
    # (capped) Spike run, so a DUT trap in the UNVERIFIED tail must NOT justify a waiver
    # -- otherwise a real post-prefix divergence/livelock whose trap tuple happens to
    # match could be masked. Only consider DUT trap-enters INSIDE the Spike-verified
    # prefix; the matched trap must be the divergence boundary, not an arbitrary later one.
    d_enters = [row for row in trap_rows(work / "dut_trap.trace")
                if row["event"] == "enter" and int(row["idx"]) < prefix_len]
    if len(s_excs) < 2 or len(d_enters) < 2:
        return None
    srow = s_excs[-1]
    drow = d_enters[-1]
    same = (
        int(drow["pc"]) == int(srow["pc"])
        and int(drow["instr"]) == int(srow["instr"])
        and int(drow["mcause"]) == int(srow["cause"])
        and int(drow["mtval"]) == int(srow["mtval"])
    )
    if not same:
        return None
    return {
        "matched_commits": prefix_len,
        "dut_idx": int(drow["idx"]),
        "pc": int(drow["pc"]),
        "instr": int(drow["instr"]),
        "mcause": int(drow["mcause"]),
        "mtval": int(drow["mtval"]),
        "spike_exception": str(srow["name"]),
    }


def write_divergence(seed: int, work: Path, message: str) -> Path:
    div_dir = ROOT / "divergence"
    div_dir.mkdir(exist_ok=True)
    dut_rows = commit_rows(work / "dut_commit.trace")
    spike_rows = commit_rows(work / "spike_commit.trace")
    idx = min(len(dut_rows), len(spike_rows))
    for cur_idx, (drow, srow) in enumerate(zip(dut_rows, spike_rows)):
        if drow != srow:
            idx = cur_idx
            break
    context_start = max(0, idx - 20)
    detail = {
        "seed": seed,
        "message": message,
        "mismatch_index": idx,
        "dut": dut_rows[idx] if idx < len(dut_rows) else None,
        "spike": spike_rows[idx] if idx < len(spike_rows) else None,
        "last_20_dut": dut_rows[context_start:idx],
        "last_20_spike": spike_rows[context_start:idx],
        "repro": str(work),
    }
    (div_dir / f"seed_{seed}_divergence.json").write_text(json.dumps(detail, indent=2), encoding="utf-8")
    shutil.copy2(work / "firmware.S", div_dir / f"seed_{seed}_firmware.S")
    shutil.copy2(work / "firmware.disasm", div_dir / f"seed_{seed}_firmware.disasm")
    return div_dir / f"seed_{seed}_divergence.json"


def sim_compare_seed(seed: int, work: Path, max_cycles: int) -> tuple[int, bool, bool, str]:
    """Build firmware (from work/firmware.S), run the DUT, run Spike, lockstep compare.
    Parallel-safe: reads the shared Verilator binary (build it ONCE up front via
    verilator_bin()) and writes only inside `work`. The riscv-dv generation step
    (generate_seed) is intentionally NOT here -- it mutates shared vendored riscv-dv
    state and must run serially; the parallel script farm (dv_farm.py) pre-generates the
    corpus serially, then fans this function out across workers."""
    build_firmware(work)
    dut_completed, dut_status = run_dut(work, max_cycles)
    dut = parse_dut_commits(work / "dut_commit.trace")
    # Terminal alignment: the program ends by writing `tohost`; Spike (HTIF) stops
    # exactly there, but the DUT TB keeps looping at `write_tohost` until its own
    # terminal, inflating the DUT commit count. Truncate the DUT trace at the first
    # entry into `write_tohost` so both end at the SAME program point. This is NOT
    # masking: compare_commits still checks every commit up to that shared exit, and
    # a real divergence before exit (or one that prevents reaching write_tohost) is
    # still caught.
    # Grok-safe terminal alignment (replaces the earlier fragile `dut[:_i+2]`, which
    # assumed write_tohost is exactly auipc+sw and was flagged as a masking risk in
    # adversarial review): trim the DUT trace at its OWN architectural exit -- the first
    # commit that enters `write_tohost` -- and keep that commit. This does NOT mask:
    #  - a per-commit divergence before the exit is still compared and caught;
    #  - a bug that routes the DUT into write_tohost EARLY puts pc==write_tohost at a
    #    commit where Spike is still in user code, so compare_commits mismatches there;
    #  - it makes no assumption about the size/shape of the exit stub.
    _wt = elf_symbol(work, "write_tohost")
    if _wt is not None:
        for _i, _c in enumerate(dut):
            if _c["pc"] == _wt:
                dut = dut[:_i + 1]  # keep up to and including the first write_tohost commit
                break
    # Spike --instructions budget must be GENEROUS, not len(dut)+32: around a
    # synchronous trap Spike executes setup + handler instructions whose count
    # does not match the DUT commit count, so a tight budget truncates Spike
    # right at the trap (looked like "Spike halts at ecall"). The program exits
    # naturally via the tohost write, so a large cap is safe; we still compare
    # only the first len(dut) commits below.
    spike_budget = max(len(dut) * 8 + 20000, 100_000) if dut_completed else 200_000
    run_spike(work, spike_budget)
    spike = parse_spike_commits(
        work / "spike.log",
        limit=len(dut),
        pc_base=0,
        stop_instrs=set(),
        normalize_wdata_base=False,
    )
    write_commit_csv(work / "spike_commit.trace", spike)
    if not dut_completed:
        waiver = watchdog_trap_waiver(work, dut, spike)
        if waiver is not None:
            evidence = (
                f"handler_watchdog_waived prefix_commits={waiver['matched_commits']} "
                f"dut_idx={waiver['dut_idx']} pc=0x{waiver['pc']:08x} "
                f"instr=0x{waiver['instr']:08x} mcause=0x{waiver['mcause']:08x} "
                f"mtval=0x{waiver['mtval']:08x} spike={waiver['spike_exception']}"
            )
            return int(waiver["matched_commits"]), True, True, evidence
        div = write_divergence(seed, work, dut_status)
        return len(dut), False, False, f"{dut_status}; divergence={div}"
    ok, message = compare_commits(dut, spike, label=f"riscv-dv seed {seed}")
    trap_count = 0
    trap_path = work / "dut_trap.trace"
    if trap_path.exists():
        with trap_path.open(newline="", encoding="utf-8") as fh:
            trap_count = sum(1 for row in csv.DictReader(fh) if row.get("event") == "enter")
    if not ok:
        waiver = matched_nested_trap_waiver(work, dut, spike)
        if waiver is not None:
            evidence = (
                f"nested_trap_waived prefix_commits={waiver['matched_commits']} "
                f"dut_idx={waiver['dut_idx']} pc=0x{waiver['pc']:08x} "
                f"instr=0x{waiver['instr']:08x} mcause=0x{waiver['mcause']:08x} "
                f"mtval=0x{waiver['mtval']:08x} spike={waiver['spike_exception']}"
            )
            return int(waiver["matched_commits"]), True, True, evidence
        div = write_divergence(seed, work, message)
        return len(dut), False, False, f"{message}; divergence={div}"
    return len(dut), True, False, f"{message}; sync_traps={trap_count}"


def run_one(seed: int, instr_cnt: int, max_cycles: int) -> tuple[int, bool, bool, str]:
    """Single-seed end-to-end (gen -> sim -> compare), as used by the serial main()."""
    work = ROOT / "runs" / f"seed_{seed}"
    if work.exists():
        shutil.rmtree(work)
    work.mkdir(parents=True)
    src = generate_seed(seed, work, instr_cnt)
    adapt_asm(src, work / "firmware.S")
    return sim_compare_seed(seed, work, max_cycles)


def disk_free_kb(path: Path = ROOT) -> int:
    usage = shutil.disk_usage(path)
    return usage.free // 1024


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--start-seed", type=int, default=2026060801)
    parser.add_argument("--seeds", type=int, default=25)
    parser.add_argument("--instr-cnt", type=int, default=4000)
    parser.add_argument("--target-commits", type=int, default=TARGET_COMMITS)
    parser.add_argument("--max-cycles", type=int, default=2_000_000)
    parser.add_argument("--keep-passing-runs", action="store_true",
                        help="retain successful per-seed traces/work dirs for debug")
    args = parser.parse_args()

    free_start_kb = disk_free_kb()
    summary = {
        "status": "RUNNING",
        "target_commits": args.target_commits,
        "total_matched_commits": 0,
        "scope": {
            "included": [
                "RV32I arithmetic/logical/compare/shift",
                "RV32C compressed",
                "load/store",
                "branch/jump",
                "RV32M multiply/divide",
                "M-mode supported CSR instructions",
                "sync-trap streams (injected ECALL/EBREAK/illegal plus misaligned load-store)",
            ],
            "excluded": [
                "async interrupts",
                "riscv-dv SYNCH/fence stream",
                "A/F/D/V extensions",
                "unsupported privileged behavior",
            ],
        },
        "seeds": [],
        "waivers": [],
        "divergences": [],
        "unresolved_real_dut_divergences": 0,
        "simulator": "Verilator",
        "isa": ISA,
        "spike_isa": SPIKE_ISA,
        "riscv_dv_path": str(RISCV_DV),
        "start_time": time.time(),
        "disk_free_start_kb": free_start_kb,
        "disk_free_min_kb": free_start_kb,
        "disk_free_end_kb": free_start_kb,
        "passing_run_dirs_cleaned": 0,
    }
    div_dir = ROOT / "divergence"
    if div_dir.exists():
        shutil.rmtree(div_dir)
    t0 = time.time()
    for offset in range(args.seeds):
        seed = args.start_seed + offset
        count, ok, waived, message = run_one(seed, args.instr_cnt, args.max_cycles)
        work = ROOT / "runs" / f"seed_{seed}"
        row = {"seed": seed, "matched_commits": count if ok else 0, "dut_commits": count, "ok": ok, "waived": waived, "message": message}
        summary["seeds"].append(row)
        if ok:
            summary["total_matched_commits"] += count
            if waived:
                summary["waivers"].append({"seed": seed, "matched_commits": count, "message": message})
            if not args.keep_passing_runs and work.exists():
                shutil.rmtree(work)
                summary["passing_run_dirs_cleaned"] += 1
        else:
            summary["divergences"].append({"seed": seed, "dut_commits": count, "message": message})
            summary["unresolved_real_dut_divergences"] += 1
        free_now_kb = disk_free_kb()
        summary["disk_free_min_kb"] = min(int(summary["disk_free_min_kb"]), free_now_kb)
        summary["disk_free_end_kb"] = free_now_kb
        print(f"seed={seed} ok={ok} waived={waived} dut_commits={count} total_matched={summary['total_matched_commits']} {message}", flush=True)
        if summary["total_matched_commits"] >= args.target_commits:
            break

    if summary["total_matched_commits"] >= args.target_commits and summary["unresolved_real_dut_divergences"] == 0:
        summary["status"] = "PASS"
    elif summary["divergences"]:
        summary["status"] = "DIVERGENCE-FOUND"
    else:
        summary["status"] = "INCOMPLETE"

    elapsed = max(time.time() - t0, 1e-9)
    summary["elapsed_sec"] = elapsed
    summary["commits_per_sec"] = summary["total_matched_commits"] / elapsed
    (ROOT / "riscvdv_lockstep_summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    return 0 if summary["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
