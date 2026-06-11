#!/usr/bin/env python3
"""#1 directed campaign — RAS (call/return) coverage via riscv-dv sub-programs.

GOAL: the farm testlist uses --num_of_sub_program=0 -> zero nested calls/returns -> RAS (return-address
stack) barely toggles (5.5%). Raising num_of_sub_program should make riscv-dv generate a real call graph
(jal ra / ret) to exercise RAS push/pop/predict natively.

⚠️ FINDING (2026-06-11): the vendored riscv-dv PYFLOW generator HANGS with --num_of_sub_program > 0
(observed at 2 and 8 — the gen process sits at 0 CPU / blocked, no asm produced, for >5 min). This is a
riscv-dv pyflow limitation, NOT a cpu_m1 issue. So the native sub-program lever is unavailable here.

FALLBACK (next step, not yet implemented): inline control-flow-neutral call/return injection — a
self-returning snippet `jal ra,2f; 1: beq x0,x0,3f; 2: jalr x0,0(ra); 3:` exercises RAS push (jal ra) +
pop (ret) and is lockstep-safe (same proven mechanism as inject_fence/inject_csr). Mispredict-recovery
(mem_ras_mispredict) additionally needs a return whose target != RAS top (modify ra between call/ret).
This driver is retained as the record of the sub-program attempt; do not run with SUBPROGS>0 until the
pyflow hang is fixed or a VCS/cocotb gen path is used.
"""
import sys, re, os
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
import run_riscvdv_lockstep as farm

TESTLIST = ROOT / "config" / farm.M1_CONFIG / "testlist.yaml"
SUBPROGS = 8


def main() -> int:
    os.environ["M1_COV"] = "1"
    seeds = [int(s) for s in sys.argv[1:]] or [2026061401, 2026061402, 2026061403, 2026061404]
    orig = TESTLIST.read_text(encoding="utf-8")
    patched = re.sub(r"--num_of_sub_program=\d+", f"--num_of_sub_program={SUBPROGS}", orig)
    assert patched != orig, "num_of_sub_program knob not found in testlist"
    farm.verilator_bin()
    runs = ROOT / "ras_cov_runs"; runs.mkdir(exist_ok=True)
    results = []
    try:
        TESTLIST.write_text(patched, encoding="utf-8")   # raise sub-program count for these gens
        for seed in seeds:
            work = runs / f"seed_{seed}"; work.mkdir(parents=True, exist_ok=True)
            src = farm.generate_seed(seed, work, 8000)
            farm.adapt_asm(src, work / "firmware.S")
            n_call = len(re.findall(r"\bjal\b", (work / "firmware.S").read_text(encoding="utf-8", errors="replace")))
            matched, ok, waived, msg = farm.sim_compare_seed(seed, work, max_cycles=5_000_000)
            results.append((seed, n_call, matched, ok, msg))
            print(f"seed {seed}: jal_count={n_call} matched={matched} ok={ok} :: {msg}")
    finally:
        TESTLIST.write_text(orig, encoding="utf-8")       # ALWAYS restore the shared testlist
    allok = all(r[3] for r in results)
    print(f"\n{'PASS' if allok else 'FAIL'}: RAS sub-program lockstep — {len(results)} seeds, "
          f"{sum(r[2] for r in results)} commits, {'0 divergence' if allok else 'DIVERGENCE'}")
    return 0 if allok else 1


if __name__ == "__main__":
    sys.exit(main())
