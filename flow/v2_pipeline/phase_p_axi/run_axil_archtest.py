#!/usr/bin/env python3
"""Run selected riscv-arch-test cases through cpu_m1_axil_top."""

from __future__ import annotations

import argparse
import csv
import json
import re
import shutil
import subprocess
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parent
ARCH_ROOT = Path("/home/edauser/project/RISC-V/reference/ibex/vendor/riscv-arch-tests")
SUITE = ARCH_ROOT / "riscv-test-suite"
TOOLBIN = Path("/home/edauser/.local/opt/riscv/xpack-riscv-none-elf-gcc-13.2.0-2/bin")
GCC = TOOLBIN / "riscv-none-elf-gcc"
OBJCOPY = TOOLBIN / "riscv-none-elf-objcopy"
OBJDUMP = TOOLBIN / "riscv-none-elf-objdump"
NM = TOOLBIN / "riscv-none-elf-nm"
SPIKE = Path("/home/edauser/.local/bin/spike")
SIM = ROOT / "obj_dir_arch/Vtb_axil_archtest"
ELF_BASE = 0x1000
ISA = "rv32imc_zicsr_zifencei"
SPIKE_ISA = "rv32imc_zicsr_zifencei_zicntr"

EXT_DIRS = {
    "RV32I": SUITE / "rv32i_m/I/src",
    "RV32M": SUITE / "rv32i_m/M/src",
    "RV32C": SUITE / "rv32i_m/C/src",
}

MEM_RE = re.compile(r"mem\s+0x([0-9a-fA-F]+)\s+0x([0-9a-fA-F]+)")


def run_cmd(cmd: list[str], cwd: Path, log: Path, check: bool = True) -> subprocess.CompletedProcess[str]:
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open("w", encoding="utf-8") as fh:
        proc = subprocess.run(cmd, cwd=cwd, stdout=fh, stderr=subprocess.STDOUT, text=True)
    if check and proc.returncode != 0:
        raise RuntimeError(f"rc={proc.returncode}: {' '.join(cmd)}; see {log}")
    return proc


def ensure_sim() -> None:
    if SIM.exists():
        return
    run_cmd(["make", "arch-sim"], ROOT, ROOT / "verilator_arch_build.log")


def emit_verilog_hex(binary: Path, hex_path: Path) -> None:
    data = binary.read_bytes()
    if len(data) % 4:
        data += b"\x00" * (4 - (len(data) % 4))
    hex_path.write_text(
        "".join(f"{int.from_bytes(data[off:off + 4], 'little'):08x}\n" for off in range(0, len(data), 4)),
        encoding="utf-8",
    )


def symbols(work: Path) -> dict[str, int]:
    proc = subprocess.run([str(NM), "-n", "firmware.elf"], cwd=work, text=True, capture_output=True, check=True)
    out: dict[str, int] = {}
    for line in proc.stdout.splitlines():
        parts = line.split()
        if len(parts) >= 3:
            out[parts[2]] = int(parts[0], 16)
    return out


def build_test(src: Path, work: Path) -> dict[str, int]:
    text = src.read_text(encoding="utf-8", errors="replace")
    defines = ["-DTEST_CASE_1"]
    for name in ("rvtest_mtrap_routine", "rvtest_strap_routine", "rvtest_vtrap_routine", "rvtest_gpr_save"):
        if f"def {name}=True" in text:
            defines.append(f"-D{name}")
    cmd = [
        str(GCC),
        *defines,
        "-Os",
        f"-march={ISA}",
        "-mabi=ilp32",
        "-nostartfiles",
        "-nostdlib",
        "-ffreestanding",
        "-I",
        str(ROOT.parent / "phase_p_archtest"),
        "-I",
        str(SUITE / "env"),
        "-Wl,-Bstatic,-T," + str(ROOT.parent / "phase_p_archtest" / "archtest.lds") + ",--strip-debug",
        "-o",
        "firmware.elf",
        str(ROOT.parent / "phase_p_archtest" / "crt0.S"),
        str(src),
    ]
    run_cmd(cmd, work, work / "build.log")
    run_cmd([str(OBJCOPY), "-O", "binary", "firmware.elf", "firmware.bin"], work, work / "objcopy.log")
    emit_verilog_hex(work / "firmware.bin", work / "firmware.hex")
    run_cmd([str(OBJDUMP), "-d", "firmware.elf"], work, work / "firmware.disasm")
    syms = symbols(work)
    for required in ("rvtest_sig_begin", "rvtest_sig_end", "tohost"):
        if required not in syms:
            raise RuntimeError(f"missing ELF symbol {required}")
    return syms


def memory_from_binary(binary: Path) -> dict[int, int]:
    data = binary.read_bytes()
    mem: dict[int, int] = {}
    for off in range(0, len(data), 4):
        mem[ELF_BASE + off] = int.from_bytes(data[off:off + 4].ljust(4, b"\x00"), "little")
    return mem


def dump_signature_from_mem(mem: dict[int, int], syms: dict[str, int]) -> list[str]:
    return [f"{mem.get(addr, 0):08x}" for addr in range(syms["rvtest_sig_begin"], syms["rvtest_sig_end"], 4)]


def replay_spike_signature(work: Path, syms: dict[str, int], max_instructions: int) -> list[str]:
    log = work / "spike.log"
    cmd = [
        str(SPIKE),
        f"--isa={SPIKE_ISA}",
        "--priv=m",
        "--disable-dtb",
        "-m0x1000:0x300000",
        f"--pc=0x{ELF_BASE:08x}",
        "--log-commits",
        "-l",
        f"--log={log}",
        f"--instructions={max_instructions}",
        "firmware.elf",
    ]
    proc = run_cmd(cmd, work, work / "spike.stdout", check=False)
    if proc.returncode not in (0, 133, 255):
        raise RuntimeError(f"spike failed rc={proc.returncode}; see {work / 'spike.stdout'}")

    mem = memory_from_binary(work / "firmware.bin")
    saw_tohost = False
    for line in log.read_text(encoding="utf-8", errors="replace").splitlines():
        match = MEM_RE.search(line)
        if not match:
            continue
        addr = int(match.group(1), 16)
        raw_value = match.group(2)
        value = int(raw_value, 16) & 0xFFFFFFFF
        width = len(raw_value) // 2
        base = addr & ~0x3
        old = mem.get(base, 0)
        byte_shift = (addr & 0x3) * 8
        if width == 1:
            mask = 0xFF << byte_shift
            mem[base] = (old & ~mask) | ((value & 0xFF) << byte_shift)
        elif width == 2:
            mask = 0xFFFF << byte_shift
            mem[base] = (old & ~mask) | ((value & 0xFFFF) << byte_shift)
        else:
            mem[base] = value
        if addr == syms["tohost"] and value != 0:
            saw_tohost = True
            break
    if not saw_tohost:
        raise RuntimeError(f"spike did not reach tohost within {max_instructions} instructions")
    return dump_signature_from_mem(mem, syms)


def run_axi(work: Path, syms: dict[str, int], max_cycles: int, wait: int) -> list[str]:
    cmd = [
        str(SIM),
        f"+HEX={work / 'firmware.hex'}",
        f"+SIGNATURE={work / f'axi_wait{wait}.signature'}",
        f"+MAX_CYCLES={max_cycles}",
        f"+WAIT={wait}",
        f"+STOP_ADDR={syms['tohost']:08x}",
        f"+SIG_BEGIN={syms['rvtest_sig_begin']:08x}",
        f"+SIG_END={syms['rvtest_sig_end']:08x}",
    ]
    proc = run_cmd(cmd, work, work / f"sim_wait{wait}.log", check=False)
    if proc.returncode != 0:
        raise RuntimeError(f"AXI sim failed rc={proc.returncode}; see {work / f'sim_wait{wait}.log'}")
    sig_path = work / f"axi_wait{wait}.signature"
    if not sig_path.exists():
        raise RuntimeError("AXI sim did not produce signature")
    return [line.strip().lower() for line in sig_path.read_text(encoding="utf-8").splitlines() if line.strip()]


def first_mismatch(dut: list[str], ref: list[str]) -> str:
    for idx, (dval, rval) in enumerate(zip(dut, ref)):
        if dval != rval:
            return f"word {idx}: axi={dval} ref={rval}"
    if len(dut) != len(ref):
        return f"length: axi={len(dut)} ref={len(ref)}"
    return ""


def source_for(name: str) -> tuple[str, Path]:
    if "/" in name:
        ext, test = name.split("/", 1)
        return ext, EXT_DIRS[ext] / f"{test}.S"
    for ext, directory in EXT_DIRS.items():
        src = directory / f"{name}.S"
        if src.exists():
            return ext, src
    raise FileNotFoundError(name)


def run_one(test_name: str, args: argparse.Namespace) -> dict[str, str | int]:
    ext, src = source_for(test_name)
    work = ROOT / "runs" / ext / src.stem
    if work.exists():
        shutil.rmtree(work)
    work.mkdir(parents=True, exist_ok=True)
    row: dict[str, str | int] = {"extension": ext, "test": src.stem, "status": "ERROR", "detail": ""}
    try:
        syms = build_test(src, work)
        ref = replay_spike_signature(work, syms, args.spike_instructions)
        (work / "reference.signature").write_text("\n".join(ref) + "\n", encoding="utf-8")
        for wait in args.wait:
            axi = run_axi(work, syms, args.max_cycles, wait)
            mismatch = first_mismatch(axi, ref)
            if mismatch:
                row["status"] = "FAIL"
                row["detail"] = f"wait={wait}: {mismatch}"
                return row
        row["status"] = "PASS"
        row["detail"] = "signature match at waits " + ",".join(str(w) for w in args.wait)
    except Exception as exc:
        row["status"] = "ERROR"
        row["detail"] = str(exc)
    return row


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tests", nargs="+", default=["add-01", "mul-01"])
    parser.add_argument("--wait", nargs="+", type=int, default=[0, 3])
    parser.add_argument("--max-cycles", type=int, default=8_000_000)
    parser.add_argument("--spike-instructions", type=int, default=500_000)
    args = parser.parse_args()

    started = time.time()
    ensure_sim()
    rows = []
    for test in args.tests:
        print(f"[AXI arch-test] {test}", flush=True)
        row = run_one(test, args)
        rows.append(row)
        print(f"  {row['status']}: {row['detail']}", flush=True)

    with (ROOT / "archtest_axi_results.csv").open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=["extension", "test", "status", "detail"])
        writer.writeheader()
        writer.writerows(rows)
    summary = {
        "scope": "selected riscv-arch-test cases through cpu_m1_axil_top",
        "tests": rows,
        "wait_states": args.wait,
        "passed": sum(1 for row in rows if row["status"] == "PASS"),
        "total": len(rows),
        "elapsed_sec": time.time() - started,
    }
    (ROOT / "archtest_axi_summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    return 0 if summary["passed"] == summary["total"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
