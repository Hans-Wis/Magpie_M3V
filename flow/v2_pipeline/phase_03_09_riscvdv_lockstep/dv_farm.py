#!/usr/bin/env python3
"""dv_farm -- parallel riscv-dv lockstep campaign (codified mechanical loop).

Replaces "one Codex agent drives a serial gen->sim->compare loop" (the bottleneck +
a code-first violation) with a parallel script farm + status-file blackboard:

  Stage 0 (once):   build the Verilator sim binary  -> shared, read-only to workers.
  Stage 1 (serial): riscv-dv generation (mutates shared vendored state -> must be
                    serial); each generated seed is immediately submitted to ...
  Stage 2 (parallel): a worker pool (cap --jobs) that runs build+DUT+Spike+lockstep
                    compare (run_riscvdv_lockstep.sim_compare_seed). Generation of
                    seed N+1 overlaps with simulation of seed N (producer-consumer).
  Blackboard:       each finished seed writes <campaign>/status/seed_<n>.json
                    (verdict + git rev + RTL cksum + ts) the moment it completes, so a
                    caller polls files instead of blocking on the run.
  Rollup:           <campaign>/summary.json aggregates all seeds.

Run it detached (fire-and-forget) and poll the status dir:
  python3 dv_farm.py --start-seed 2026070101 --seeds 64 --jobs 4 --instr-cnt 2000 &

Codex is OUT of the driver path; Claude triggers this and reads the blackboard.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

import run_riscvdv_lockstep as H  # reuse the single-source-of-truth primitives

ROOT = H.ROOT


def git_rev() -> str:
    try:
        return subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT,
                              capture_output=True, text=True).stdout.strip() or "unknown"
    except Exception:
        return "unknown"


def rtl_cksum() -> str:
    """Stable digest of the RTL + harness so a status file is tied to exact sources."""
    h = hashlib.sha256()
    files = sorted(H.RTL_DIR.glob("*.v")) + sorted(H.RTL_DIR.glob("*.vh"))
    files.append(Path(H.__file__))
    for f in files:
        try:
            h.update(f.read_bytes())
        except OSError:
            pass
    return h.hexdigest()[:12]


def gen_and_sim(seed: int, instr_cnt: int, max_cycles: int):
    """One parallel worker: gen (gen_core -- NO install; the dispatcher installs the
    shared M1 target config ONCE before the pool) + adapt + build + DUT + Spike +
    lockstep compare. Returns (seed, count, ok, waived, message). The short `runs/seed_n`
    work dir avoids the Verilator +plusarg path-length truncation."""
    import shutil
    work = ROOT / "runs" / f"seed_{seed}"
    if work.exists():
        shutil.rmtree(work)
    work.mkdir(parents=True)
    src = H.gen_core(seed, work, instr_cnt)
    H.adapt_asm(src, work / "firmware.S")
    count, ok, waived, message = H.sim_compare_seed(seed, work, max_cycles)
    return seed, count, ok, waived, message


def main() -> int:
    ap = argparse.ArgumentParser(description="parallel riscv-dv lockstep farm")
    ap.add_argument("--start-seed", type=int, default=2026070101)
    ap.add_argument("--seeds", type=int, default=16)
    ap.add_argument("--instr-cnt", type=int, default=2000)
    ap.add_argument("--max-cycles", type=int, default=4_000_000)
    ap.add_argument("--jobs", type=int, default=min(4, max(1, (os.cpu_count() or 4) - 2)),
                    help="parallel sim+compare workers (cap); gen stays serial")
    ap.add_argument("--campaign", default=None, help="campaign dir name (default farm_<rev>_<start>)")
    args = ap.parse_args()

    rev, cksum = git_rev(), rtl_cksum()
    name = args.campaign or f"farm_{rev}_{args.start_seed}"
    camp = ROOT / "campaigns" / name
    status_dir = camp / "status"
    status_dir.mkdir(parents=True, exist_ok=True)
    # NOTE: per-seed work dirs live under the SHORT `runs/seed_<n>` path, not under the
    # (long) campaign dir: the Verilator testbench has a fixed-size +plusarg string
    # buffer, and a long absolute firmware.hex/trace path silently truncates ($readmem
    # file not found). The campaign dir holds only the blackboard (status) + rollup.
    seeds = list(range(args.start_seed, args.start_seed + args.seeds))

    meta = {"campaign": name, "git_rev": rev, "rtl_cksum": cksum, "jobs": args.jobs,
            "seeds": [seeds[0], seeds[-1]], "instr_cnt": args.instr_cnt,
            "spike": str(H.SPIKE), "status": "RUNNING"}
    (camp / "meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    print(f"[farm] {name} rev={rev} cksum={cksum} seeds={len(seeds)} jobs={args.jobs}", flush=True)

    # Stage 0: build the sim once so parallel workers only READ it; install the M1
    # riscv-dv target config ONCE so parallel gen_core() calls all read the same
    # (unchanging) config instead of each install/restore-ing the shared vendored state.
    H.verilator_bin()
    backups = H.install_riscvdv_target()
    print(f"[farm] sim built + target installed; fanning out gen+sim across {args.jobs} workers",
          flush=True)

    def write_status(seed: int, rec: dict) -> None:
        rec.update({"seed": seed, "git_rev": rev, "rtl_cksum": cksum})
        (status_dir / f"seed_{seed}.json").write_text(json.dumps(rec), encoding="utf-8")

    done = 0
    try:
        with ProcessPoolExecutor(max_workers=args.jobs) as ex:
            # BOTH gen and sim run in the worker pool (gen_core is parallel-safe now).
            futures = {ex.submit(gen_and_sim, seed, args.instr_cnt, args.max_cycles): seed
                       for seed in seeds}
            for fut in as_completed(futures):
                seed = futures[fut]
                try:
                    _seed, count, ok, waived, message = fut.result()
                    rec = {"ok": bool(ok), "waived": bool(waived), "matched_commits": int(count),
                           "stage": "sim", "message": message[:400]}
                except Exception as exc:
                    rec = {"ok": False, "waived": False, "stage": "gen_or_sim",
                           "error": str(exc)[:300]}
                write_status(seed, rec)
                done += 1
                tag = "PASS" if rec.get("ok") else "FAIL"
                tag += "(waived)" if rec.get("waived") else ""
                print(f"[farm] {done}/{len(seeds)} seed {seed}: {tag} "
                      f"matched={rec.get('matched_commits','-')}", flush=True)
    finally:
        H.restore_riscvdv_target(backups)

    # Rollup
    recs = []
    for f in sorted(status_dir.glob("seed_*.json")):
        try:
            recs.append(json.loads(f.read_text(encoding="utf-8")))
        except Exception:
            pass
    passed = [r for r in recs if r.get("ok") and not r.get("waived")]
    waived = [r for r in recs if r.get("ok") and r.get("waived")]
    failed = [r for r in recs if not r.get("ok")]
    total_matched = sum(int(r.get("matched_commits", 0)) for r in recs)
    summary = {**meta, "status": ("PASS" if not failed else "DIVERGENCE-FOUND"),
               "n_seeds": len(recs), "n_pass": len(passed), "n_waived": len(waived),
               "n_fail": len(failed), "total_matched_commits": total_matched,
               "failed_seeds": [r["seed"] for r in failed],
               "waived_seeds": [r["seed"] for r in waived]}
    (camp / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(f"[farm] DONE {name}: pass={len(passed)} waived={len(waived)} fail={len(failed)} "
          f"total_matched={total_matched}", flush=True)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
