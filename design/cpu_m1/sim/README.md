# cpu_m1 / sim — simulation build & run (IP deliverable)

Single entry point to build and run the cpu_m1 verification against the deliverable RTL.

- `cpu_m1.f`     — sim filelist = rtl filelist (`../rtl/filelist.f`) + DV testbench(es) from `../dv/tb/`.
- RTL source of truth: `../rtl/` (flat, extracted from the former `ch2_lab08e` lab tree, 2026-06-09).
- Correctness authority: Spike per-commit lockstep (`../dv/lib/spike_commit.py`) + pytest gates
  (`../../../tests/gates/`).

## Status (honest)
The *executable* development flow currently lives under `../../../flow/v2_pipeline/phase_*` (30 phases,
189 gates + 1 xfail). This `sim/` + `dv/` tree is the **curated deliverable view** of that flow being
assembled for customer hand-off (V-Plan, reusable TB, coverage model, signoff checklist). It is NOT yet
a standalone one-button regression — see `../dv/vplan/DV_SIGNOFF_CHECKLIST.md` for what is done vs pending.

## Build (Verilator, OSS)
```
verilator --binary -j 4 -f cpu_m1.f --top-module <tb> --trace --coverage
```
Licensed signoff sims (VCS/Questa/IMC) + coverage merge are a Tier-1 deliverable item (pending).
