#!/usr/bin/env python3
"""#4a — fence / fence.i IN-STREAM riscv-dv lockstep.

The riscv-dv pyflow does NOT emit fence in the random stream (pygen instr_category skip),
so the 105k farm excluded fence — covered only directed (gate_03_10). This driver closes the
"fence excluded" gap AT SCALE: generate a riscv-dv program, INJECT fence/fence.i into the main
instruction stream, then run the SAME farm DUT+Spike per-commit lockstep. fence.i is an
architected NOP on cpu_m1 (no I-cache) and a NOP in Spike's trace, so a correct DUT retires it
identically — any mis-handling (e.g. decode-trap as illegal) diverges immediately.

Reuses the farm's own machinery (generate_seed/build_firmware/run_dut/run_spike/compare) so the
terminal-alignment + Spike-budget logic is identical to the J19 farm.
"""
import sys, re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
import run_riscvdv_lockstep as farm


def inject_fence(fw: Path, every: int = 12) -> int:
    """Insert `fence.i` / `fence` on their own lines after every Nth instruction in the main
    code region (between `main:` and the first sub-section / write_tohost). Returns count."""
    lines = fw.read_text(encoding="utf-8").splitlines()
    out, n, inj, in_main = [], 0, 0, False
    def is_instr(s: str) -> bool:
        t = s.strip()
        if not t or t.startswith((".", "#")):
            return False
        # strip a leading "label:" (named or numeric) then check for a mnemonic
        t = re.sub(r"^[A-Za-z0-9_]+:\s*", "", t)
        return bool(re.match(r"[a-z]", t))
    for ln in lines:
        out.append(ln)
        s = ln.strip()
        if s.startswith("main:"):
            in_main = True
        if in_main and (s.startswith("write_tohost") or re.match(r"sub_\d+:", s)
                        or s.startswith(".section .data")):
            in_main = False
        if in_main and is_instr(ln):
            # never split a branch/jump from a following label target by inserting between
            # the instruction and a label — we always insert AFTER a full instruction line, ok.
            n += 1
            if n % every == 0:
                out.append("                  fence.i")
                inj += 1
                if n % (every * 3) == 0:
                    out.append("                  fence")
                    inj += 1
    fw.write_text("\n".join(out) + "\n", encoding="utf-8")
    return inj


def main() -> int:
    seeds = [int(s) for s in sys.argv[1:]] or [2026061201, 2026061202, 2026061203]
    farm.verilator_bin()  # build the shared sim once (non-coverage)
    results = []
    runs = ROOT / "fence_runs"
    runs.mkdir(exist_ok=True)
    for seed in seeds:
        work = runs / f"seed_{seed}"
        work.mkdir(parents=True, exist_ok=True)
        src = farm.generate_seed(seed, work, 8000)   # raw riscv-dv asm
        farm.adapt_asm(src, work / "firmware.S")      # -> farm firmware.S
        nf = inject_fence(work / "firmware.S")         # sprinkle fence/fence.i into the stream
        matched, ok, waived, msg = farm.sim_compare_seed(seed, work, max_cycles=5_000_000)
        # confirm fence actually landed in the compiled program
        disasm = (work / "firmware.disasm").read_text(encoding="utf-8", errors="replace")
        n_fi = len(re.findall(r"\bfence\.i\b", disasm))
        n_f = len(re.findall(r"\bfence\b(?!\.)", disasm))
        results.append((seed, nf, n_fi, n_f, matched, ok, waived, msg))
        print(f"seed {seed}: injected={nf} disasm_fence.i={n_fi} fence={n_f} "
              f"matched={matched} ok={ok} waived={waived} :: {msg}")
    allok = all(r[5] for r in results)
    total = sum(r[4] for r in results)
    fi_ok = all(r[2] >= 1 for r in results)
    status = "PASS" if (allok and fi_ok) else "FAIL"
    import json
    summary = {
        "status": status, "kind": "fence-in-stream riscv-dv lockstep", "seeds": len(results),
        "total_matched_commits": total, "divergences": 0 if allok else sum(1 for r in results if not r[5]),
        "isa": farm.ISA, "spike_isa": farm.SPIKE_ISA,
        "note": "fence/fence.i injected into random riscv-dv programs; fence.i is a NOP on cpu_m1 (no "
                "I-cache) and in Spike's trace, so a correct DUT retires it identically. Closes the farm "
                "'fence excluded' gap AT SCALE (vs directed-only gate_03_10).",
        "per_seed": [{"seed": s, "injected": nf, "disasm_fence_i": fi, "disasm_fence": f,
                      "matched_commits": m, "ok": ok, "message": msg}
                     for (s, nf, fi, f, m, ok, wv, msg) in results],
    }
    (ROOT / "fence_in_stream_summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(f"\n{status}: fence-in-stream lockstep — {len(results)} seeds, {total} commits matched, "
          f"fence.i present in every program")
    return 0 if (allok and fi_ok) else 1


if __name__ == "__main__":
    sys.exit(main())
