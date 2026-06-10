#!/usr/bin/env python3
"""Run vendored riscv-arch-test RV32I/M/C on Magpie_M1 and compare signatures."""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import shutil
import subprocess
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[2]
ARCH = Path("/home/edauser/project/RISC-V/reference/ibex/vendor/riscv-arch-tests")
SUITE = ARCH / "riscv-test-suite"
TOOLBIN = Path("/home/edauser/.local/opt/riscv/xpack-riscv-none-elf-gcc-13.2.0-2/bin")
GCC = TOOLBIN / "riscv-none-elf-gcc"
OBJCOPY = TOOLBIN / "riscv-none-elf-objcopy"
OBJDUMP = TOOLBIN / "riscv-none-elf-objdump"
NM = TOOLBIN / "riscv-none-elf-nm"
SPIKE = Path("/home/edauser/.local/bin/spike")
SIM = ROOT / "obj_dir/Vtb_archtest"
ELF_BASE = 0x1000
ISA = "rv32imc_zicsr_zifencei"
SPIKE_ISA = "rv32imc_zicsr_zifencei_zicntr"

EXT_DIRS = {
    "RV32I": SUITE / "rv32i_m/I/src",
    "RV32M": SUITE / "rv32i_m/M/src",
    "RV32C": SUITE / "rv32i_m/C/src",
}


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
    run_cmd(["make", str(SIM.relative_to(ROOT))], ROOT, ROOT / "verilator_build.log")


def emit_verilog_hex(binary: Path, hex_path: Path) -> None:
    data = binary.read_bytes()
    if len(data) % 4:
        data += b"\x00" * (4 - (len(data) % 4))
    lines = []
    for off in range(0, len(data), 4):
        lines.append(f"{int.from_bytes(data[off:off + 4], 'little'):08x}\n")
    hex_path.write_text("".join(lines), encoding="utf-8")


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
        str(ROOT),
        "-I",
        str(SUITE / "env"),
        "-Wl,-Bstatic,-T," + str(ROOT / "archtest.lds") + ",--strip-debug",
        "-o",
        "firmware.elf",
        str(ROOT / "crt0.S"),
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
    if syms["rvtest_sig_end"] < syms["rvtest_sig_begin"]:
        raise RuntimeError("invalid signature range")
    return syms


def memory_from_binary(binary: Path) -> dict[int, int]:
    data = binary.read_bytes()
    mem: dict[int, int] = {}
    for off in range(0, len(data), 4):
        chunk = data[off:off + 4].ljust(4, b"\x00")
        mem[ELF_BASE + off] = int.from_bytes(chunk, "little")
    return mem


MEM_RE = re.compile(r"mem\s+0x([0-9a-fA-F]+)\s+0x([0-9a-fA-F]+)")


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


def dump_signature_from_mem(mem: dict[int, int], syms: dict[str, int]) -> list[str]:
    sig = []
    for addr in range(syms["rvtest_sig_begin"], syms["rvtest_sig_end"], 4):
        sig.append(f"{mem.get(addr, 0):08x}")
    return sig


def run_dut(work: Path, syms: dict[str, int], max_cycles: int) -> list[str]:
    cmd = [
        str(SIM),
        f"+HEX={work / 'firmware.hex'}",
        f"+SIGNATURE={work / 'dut.signature'}",
        f"+MAX_CYCLES={max_cycles}",
        f"+STOP_ADDR={syms['tohost']:08x}",
        f"+SIG_BEGIN={syms['rvtest_sig_begin']:08x}",
        f"+SIG_END={syms['rvtest_sig_end']:08x}",
    ]
    proc = run_cmd(cmd, work, work / "sim.log", check=False)
    if proc.returncode != 0:
        raise RuntimeError(f"DUT sim failed rc={proc.returncode}; see {work / 'sim.log'}")
    sig_path = work / "dut.signature"
    if not sig_path.exists():
        raise RuntimeError("DUT did not produce signature")
    return [line.strip().lower() for line in sig_path.read_text(encoding="utf-8").splitlines() if line.strip()]


def first_mismatch(dut: list[str], ref: list[str]) -> str:
    for idx, (dval, rval) in enumerate(zip(dut, ref)):
        if dval != rval:
            return f"word {idx}: dut={dval} ref={rval}"
    if len(dut) != len(ref):
        return f"length: dut={len(dut)} ref={len(ref)}"
    return ""


def test_sources(exts: list[str]) -> list[tuple[str, Path]]:
    rows: list[tuple[str, Path]] = []
    for ext in exts:
        for src in sorted(EXT_DIRS[ext].glob("*.S")):
            rows.append((ext, src))
    return rows


def run_one(ext: str, src: Path, args: argparse.Namespace) -> dict[str, str | int | bool]:
    name = src.stem
    work = ROOT / "runs" / ext / name
    if work.exists():
        shutil.rmtree(work)
    work.mkdir(parents=True, exist_ok=True)
    row: dict[str, str | int | bool] = {"extension": ext, "test": name, "source": str(src), "status": "ERROR"}
    try:
        syms = build_test(src, work)
        row["sig_words"] = (syms["rvtest_sig_end"] - syms["rvtest_sig_begin"]) // 4
        ref = replay_spike_signature(work, syms, args.spike_instructions)
        (work / "reference.signature").write_text("\n".join(ref) + "\n", encoding="utf-8")
        dut = run_dut(work, syms, args.max_cycles)
        mismatch = first_mismatch(dut, ref)
        if mismatch:
            row["status"] = "FAIL"
            row["detail"] = mismatch
        else:
            row["status"] = "PASS"
            row["detail"] = "signature match"
    except Exception as exc:
        row["status"] = "ERROR"
        row["detail"] = str(exc)
    return row


def write_outputs(rows: list[dict[str, str | int | bool]], started: float) -> None:
    fields = ["extension", "test", "status", "sig_words", "detail", "source"]
    with (ROOT / "results.csv").open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})

    by_ext = {}
    for ext in EXT_DIRS:
        ext_rows = [row for row in rows if row["extension"] == ext]
        passed = sum(1 for row in ext_rows if row["status"] == "PASS")
        by_ext[ext] = {"passed": passed, "total": len(ext_rows), "rate": (passed / len(ext_rows) if ext_rows else 0.0)}
    passed_total = sum(1 for row in rows if row["status"] == "PASS")
    summary = {
        "status": "COMPLETE",
        "scope": "RV32I/RV32M/RV32C riscv-arch-test signature comparison",
        "dut": "Magpie_M1 Verilator core harness",
        "reference": "Spike commit-log reconstructed signature",
        "isa": ISA,
        "spike_isa": SPIKE_ISA,
        "extensions": by_ext,
        "overall": {"passed": passed_total, "total": len(rows), "rate": (passed_total / len(rows) if rows else 0.0)},
        "elapsed_sec": time.time() - started,
        "rows": rows,
    }
    (ROOT / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")

    lines = [
        "# Magpie_M1 riscv-arch-test RV32I/M/C",
        "",
        "Result is a signature comparison only. No gate is marked green.",
        "",
        "| Extension | Pass rate |",
        "| --- | ---: |",
    ]
    for ext, data in by_ext.items():
        lines.append(f"| {ext} | {data['passed']}/{data['total']} ({data['rate'] * 100:.1f}%) |")
    lines += [
        f"| Overall | {passed_total}/{len(rows)} ({summary['overall']['rate'] * 100:.1f}%) |",
        "",
        "## Non-PASS Tests",
        "",
        "| Extension | Test | Status | First mismatch / error |",
        "| --- | --- | --- | --- |",
    ]
    nonpass = [row for row in rows if row["status"] != "PASS"]
    if nonpass:
        for row in nonpass:
            detail = str(row.get("detail", "")).replace("|", "\\|")
            lines.append(f"| {row['extension']} | {row['test']} | {row['status']} | {detail} |")
    else:
        lines.append("| - | - | - | - |")
    lines += [
        "",
        "Artifacts: `results.csv`, `summary.json`, and per-test directories under `runs/<extension>/<test>/`.",
        "",
    ]
    (ROOT / "summary.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--extensions", nargs="+", choices=sorted(EXT_DIRS), default=sorted(EXT_DIRS))
    parser.add_argument("--max-cycles", type=int, default=5_000_000)
    parser.add_argument("--spike-instructions", type=int, default=500_000)
    parser.add_argument("--limit", type=int, default=0)
    args = parser.parse_args()

    started = time.time()
    ensure_sim()
    selected = test_sources(args.extensions)
    if args.limit:
        selected = selected[:args.limit]

    rows = []
    for idx, (ext, src) in enumerate(selected, start=1):
        print(f"[{idx}/{len(selected)}] {ext} {src.stem}", flush=True)
        rows.append(run_one(ext, src, args))
        print(f"  {rows[-1]['status']}: {rows[-1].get('detail', '')}", flush=True)
        write_outputs(rows, started)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
