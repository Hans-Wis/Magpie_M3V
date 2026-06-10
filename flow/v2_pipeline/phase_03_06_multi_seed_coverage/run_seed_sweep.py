#!/usr/bin/env python3
"""Run deterministic random lockstep across multiple seeds with coverage."""

from __future__ import annotations

import argparse
import csv
import os
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "lib"))
from spike_commit import compare_commits, parse_dut_commits, parse_spike_commits, run_spike, write_commit_csv


ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[2]
SIM_BIN = ROOT / "obj_dir/Vtb_random_lockstep"
SPIKE_BASE = 0x8000_0000
TOOLCHAIN_DIR = Path("/home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin")
TOOLCHAIN_PREFIX = TOOLCHAIN_DIR / "riscv64-unknown-elf-"
TOOLCHAIN_LIBS = ":".join(
    [
        "/home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib",
        "/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib",
        "/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib",
    ]
)
VERILATOR_COVERAGE = Path("/home/edauser/miniforge3/envs/magpie_claude/bin/verilator_coverage")


def _run(cmd: list[str | Path], *, cwd: Path, stdout: Path | None = None) -> None:
    env = os.environ.copy()
    env["LD_LIBRARY_PATH"] = TOOLCHAIN_LIBS
    out = None
    if stdout is not None:
        out = stdout.open("w", encoding="utf-8")
    try:
        subprocess.run([str(item) for item in cmd], cwd=cwd, env=env, check=True, stdout=out)
    finally:
        if out is not None:
            out.close()


def _compile_firmware(run_dir: Path, count: int, seed: int) -> None:
    _run(
        [
            "python3",
            ROOT / "gen_random_program.py",
            "--seed",
            str(seed),
            "--count",
            str(count),
            "--out",
            run_dir / "firmware.S",
        ],
        cwd=ROOT,
    )
    for name, linker in [
        ("firmware.elf", ROOT / "firmware.lds"),
        ("firmware_spike.elf", ROOT / "firmware_spike.lds"),
    ]:
        _run(
            [
                TOOLCHAIN_PREFIX.with_name(TOOLCHAIN_PREFIX.name + "gcc"),
                "-Os",
                "-march=rv32imc_zicsr_zifencei",
                "-mabi=ilp32",
                "-nostartfiles",
                "-nostdlib",
                "-ffreestanding",
                f"-Wl,-Bstatic,-T,{linker},--strip-debug",
                "-o",
                run_dir / name,
                run_dir / "firmware.S",
            ],
            cwd=run_dir,
        )
    _run(
        [
            TOOLCHAIN_PREFIX.with_name(TOOLCHAIN_PREFIX.name + "objcopy"),
            "-O",
            "verilog",
            "--verilog-data-width=4",
            run_dir / "firmware.elf",
            run_dir / "firmware.hex",
        ],
        cwd=run_dir,
    )
    _run(
        [
            TOOLCHAIN_PREFIX.with_name(TOOLCHAIN_PREFIX.name + "objdump"),
            "-d",
            run_dir / "firmware.elf",
        ],
        cwd=run_dir,
        stdout=run_dir / "firmware.disasm",
    )


def _run_one_seed(seed: int, count: int) -> dict[str, str]:
    run_dir = ROOT / "runs" / f"seed_{seed}"
    if run_dir.exists():
        shutil.rmtree(run_dir)
    run_dir.mkdir(parents=True)
    _compile_firmware(run_dir, count, seed)
    _run([SIM_BIN], cwd=run_dir, stdout=run_dir / "sim.log")

    dut = parse_dut_commits(run_dir / "dut_commit.trace")
    run_spike(
        work_dir=run_dir,
        elf=run_dir / "firmware_spike.elf",
        log=run_dir / "spike.log",
        pc_base=SPIKE_BASE,
        instructions=320,
    )
    spike = parse_spike_commits(
        run_dir / "spike.log",
        limit=len(dut),
        pc_base=SPIKE_BASE,
        stop_instrs={0x0000_9002},
    )
    write_commit_csv(run_dir / "spike_commit.trace", spike)
    ok, message = compare_commits(dut, spike, label=f"seed {seed}")
    (run_dir / "lockstep.log").write_text(("PASS: " if ok else "FAIL: ") + message + "\n", encoding="utf-8")
    if not ok:
        raise RuntimeError(f"seed {seed} mismatch: {message}")
    coverage = run_dir / "coverage.dat"
    return {
        "seed": str(seed),
        "count": str(count),
        "commits": str(len(dut)),
        "status": "pass",
        "coverage_dat": "yes" if coverage.exists() and coverage.stat().st_size > 0 else "no",
    }


def _coverage_line_summary(info: Path) -> tuple[int, int, float]:
    if not info.exists():
        return (0, 0, 0.0)
    found = 0
    hit = 0
    for line in info.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("LF:"):
            found += int(line.split(":", 1)[1])
        elif line.startswith("LH:"):
            hit += int(line.split(":", 1)[1])
        elif line.startswith("DA:"):
            found += 1
            _, payload = line.split(":", 1)
            _, count = payload.split(",", 1)
            if int(count) > 0:
                hit += 1
    percent = (hit * 100.0 / found) if found else 0.0
    return found, hit, percent


def _merge_coverage(rows: list[dict[str, str]]) -> tuple[Path, Path, int, int, float]:
    cov_dir = ROOT / "coverage"
    if cov_dir.exists():
        shutil.rmtree(cov_dir)
    cov_dir.mkdir()
    coverage_files = [
        ROOT / "runs" / f"seed_{row['seed']}" / "coverage.dat"
        for row in rows
        if row["coverage_dat"] == "yes"
    ]
    if coverage_files:
        _run([VERILATOR_COVERAGE, "-write", cov_dir / "merged_coverage.dat", *coverage_files], cwd=ROOT)
        _run([VERILATOR_COVERAGE, "-write-info", cov_dir / "coverage.info", cov_dir / "merged_coverage.dat"], cwd=ROOT)
        _run([VERILATOR_COVERAGE, "--annotate", cov_dir / "annotated", cov_dir / "merged_coverage.dat"], cwd=ROOT)
    found, hit, percent = _coverage_line_summary(cov_dir / "coverage.info")
    return cov_dir / "merged_coverage.dat", cov_dir / "coverage.info", found, hit, percent


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seeds", nargs="+", type=int, required=True)
    parser.add_argument("--count", type=int, default=48)
    args = parser.parse_args()

    if not SIM_BIN.exists():
        raise SystemExit(f"missing simulator binary: {SIM_BIN}")

    rows = [_run_one_seed(seed, args.count) for seed in args.seeds]
    summary = ROOT / "seed_summary.csv"
    with summary.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=["seed", "count", "commits", "status", "coverage_dat"])
        writer.writeheader()
        writer.writerows(rows)

    merged, info, found, hit, percent = _merge_coverage(rows)
    total_commits = sum(int(row["commits"]) for row in rows)
    status = "pass" if all(row["status"] == "pass" for row in rows) and merged.exists() and info.exists() else "fail"
    report = ROOT / "multi_seed_coverage_report.md"
    report.write_text(
        "# Phase 3.6 Multi-Seed Random Lockstep and Coverage Report\n\n"
        f"Status: {status}\n\n"
        f"Seeds: {', '.join(str(seed) for seed in args.seeds)}\n\n"
        f"Generated instruction count per seed: {args.count}\n\n"
        f"Total matched commits: {total_commits}\n\n"
        f"Coverage files present: {sum(1 for row in rows if row['coverage_dat'] == 'yes')} / {len(rows)}\n\n"
        f"Line coverage from lcov info: {hit} / {found} ({percent:.2f}%)\n\n"
        "Coverage status: measurement-only. This is not 100% line coverage closure; "
        "uncovered lines require later reason, directed closure, or waiver.\n",
        encoding="utf-8",
    )
    if status != "pass":
        print("FAIL: multi-seed sweep did not produce complete pass artifacts")
        return 1
    print(
        f"PASS: multi-seed lockstep matched {len(rows)} seeds / {total_commits} commits; "
        f"line coverage {percent:.2f}% ({hit}/{found})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
