#!/usr/bin/env python3
import argparse
import re
from pathlib import Path


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--iterations", type=int, required=True)
    ap.add_argument("--freq-mhz", type=float, required=True)
    args = ap.parse_args()

    log = Path("sim.log").read_text(errors="replace")
    mmio = {}
    for idx, val in re.findall(r"MMIO_RESULT\[(\d+)\]=([0-9a-fA-F]{8})", log):
        mmio[int(idx)] = int(val, 16)

    passed = "PASS: CoreMark firmware reached ebreak" in log
    validated = "Correct operation validated" in log
    cycles = mmio.get(1)
    instret = mmio.get(2)
    iterations = mmio.get(0, args.iterations)
    tb_timed_re = re.search(
        r"TB_TIMED cycles=(\d+) commits=(\d+) load_use_stall=(\d+) "
        r"muldiv_stall=(\d+) fetch_stall=(\d+) redirect=(\d+) other_stall=(\d+)",
        log,
    )
    progress = re.findall(r"PROGRESS: cycles=(\d+) commits=(\d+) pc=([0-9a-fA-F]{8})", log)
    last_progress = progress[-1] if progress else None
    watchdog = "FAIL: watchdog timeout" in log

    print("# Magpie_M1 CoreMark Result")
    print()
    print(f"- Status: {'completed' if passed else 'did not complete'}")
    print(f"- Correct operation validated: {'yes' if validated else 'no'}")
    print(f"- Iterations: {iterations}")
    if cycles is not None and cycles != 0:
        coremark_per_mhz = iterations * 1_000_000.0 / cycles
        absolute = coremark_per_mhz * args.freq_mhz
        print(f"- Total cycles: {cycles}")
        print(f"- Retired instructions in timed region: {instret if instret is not None else 'unavailable'}")
        print(f"- CoreMark/MHz: {coremark_per_mhz:.6f}")
        print(f"- Implied CoreMark at {args.freq_mhz:g} MHz: {absolute:.3f}")
        print(f"- Cycles per iteration: {cycles / iterations:.3f}")
        if instret:
            print(f"- IPC: {instret / cycles:.6f}")
            print(f"- CPI: {cycles / instret:.6f}")
    else:
        print("- Total cycles: unavailable")
        print("- CoreMark/MHz: unavailable")
    if tb_timed_re:
        tcyc, commits, load_use, muldiv, fetch, redirect, other = map(int, tb_timed_re.groups())
        print()
        print("## Testbench Timed-Region Counters")
        print()
        print(f"- TB cycles: {tcyc}")
        print(f"- TB committed instructions: {commits}")
        if tcyc:
            print(f"- TB IPC: {commits / tcyc:.6f}")
            print(f"- TB CPI: {tcyc / commits:.6f}" if commits else "- TB CPI: unavailable")
        print(f"- Load-use stall cycles: {load_use}")
        print(f"- Mul/div stall cycles: {muldiv}")
        print(f"- Fetch/cross-boundary stall cycles: {fetch}")
        print(f"- Redirect/refetch cycles: {redirect}")
        print(f"- Other stall cycles: {other}")
    if watchdog:
        print("- Non-completion point: testbench watchdog timeout before CoreMark `stop_time()`/MMIO cycle result")
    if last_progress:
        cyc, commits, pc = last_progress
        print(f"- Last progress marker: simulated cycles={cyc}, retired commits={commits}, debug fetch PC=0x{pc}")
    print("- Compiler: riscv-none-elf-gcc 13.2.0-2 xPack")
    print("- Compiler flags: `-O2 -funroll-loops -fno-common -fno-builtin -march=rv32imc -mabi=ilp32 -ffreestanding -nostartfiles -nostdlib -DITERATIONS=%d -DTOTAL_DATA_SIZE=2000 -DPERFORMANCE_RUN=1 -DMEM_METHOD=MEM_STATIC`" % args.iterations)
    print("- RTL changes: none")
    print()
    print("## Log Pointers")
    print()
    print("- Build/run log: `sim.log`")
    print("- Firmware disassembly: `firmware.disasm`")
    print("- Firmware map: `firmware.map`")

    return 0 if passed and validated and cycles else 1


if __name__ == "__main__":
    raise SystemExit(main())
