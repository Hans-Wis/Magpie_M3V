# dv_farm — parallel riscv-dv lockstep campaign

Codifies the mechanical `gen -> sim -> compare` loop into a parallel script farm with a
status-file blackboard, so it runs **without an agent in the driver path** (the
orchestration decision, 2026-06-08). Claude triggers it and polls files; Codex never
drives sim.

## Run (fire-and-forget; poll the blackboard)
```sh
cd flow/v2_pipeline/phase_03_09_riscvdv_lockstep
python3 dv_farm.py --start-seed 2026070101 --seeds 64 --jobs 4 --instr-cnt 2000 &
# poll progress without blocking:
ls campaigns/<name>/status/                 # one seed_<n>.json per finished seed
cat campaigns/<name>/summary.json           # rollup (written at the end)
```
`--campaign <name>` sets the dir (default `farm_<rev>_<startseed>`).

## What it does
- **Stage 0 (once):** build the Verilator sim; `install_riscvdv_target()` once so all
  workers read the same (unchanging) M1 config instead of each mutating shared state.
- **Fan-out (`--jobs` workers):** each worker does `gen_core` (parallel-safe generation,
  no install/restore) + adapt + build + DUT + Spike + lockstep compare
  (`sim_compare_seed`). Both gen and sim are parallel.
- **Blackboard:** each finished seed writes `campaigns/<name>/status/seed_<n>.json`
  (`ok`/`waived`/`matched_commits`/`message` + `git_rev` + `rtl_cksum`) the moment it
  completes — poll these instead of blocking.
- **Rollup:** `campaigns/<name>/summary.json` (pass/waived/fail counts, total matched,
  failed/waived seed lists, provenance).

## Measured
6 seeds, `--jobs 4`: **18s vs ~46s serial (~2.5x)** on small/gen-bound seeds; the win
grows with larger (sim-bound) seeds and more jobs (target 4–8x). Verdicts identical to
the serial `run_riscvdv_lockstep.py` (same `gen_core`/`sim_compare_seed` primitives —
single source of truth).

## Notes / limits
- Per-seed work dirs are the SHORT `runs/seed_<n>` (a long campaign path overflows the
  Verilator `+plusarg` string buffer -> silent `$readmem file not found`).
- `--jobs` cap ~= cores-2; bounded by CPU/memory + filesystem contention, not rebuild
  thrash (the sim is built once).
- Triage of `fail`/`waived` seeds and any RTL fix stay with Claude (the committer);
  Codex does read-only advisory review of landed changes only.
