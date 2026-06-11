# Magpie_M1 — Regression Log Archive (Tier-2 §05 deliverable)

Rev 1.0 · 2026-06-11 · Owner: PL (Claude) · design_id = `cpu_m1`
The §05 "Regression Log Archive (reproducible, seed-locked)" deliverable: the full regression set, how
to reproduce it, and where the logs live. To be SHA-locked at customer acceptance (record the git SHA
alongside this file when the package is frozen).

## 1. One-command core regression
```
python3 -m pytest tests/gates/ -q          # 55 gate files
```
Status: all pass except `gate_04_09::test_toggle_coverage_meets_mvp_bar` (xfail, tracked — whole-core
toggle below bar, see `coverage_report.md` §2). No silent skips; xfail is the single honest red.

## 2. Regression set by category (reproducible)

| Category | Gates | Evidence dir | Reproduce |
|---|---|---|---|
| Spec / scope | `gate_00_spec` | `flow/state/magpie_m1.isa_scope.*` | pytest |
| Fetch / RV32C / cross-boundary | `gate_01_01`, `gate_03_11`, `gate_03_12` | `phase_01_01`, `phase_03_11`, `phase_03_12` | `make all` in phase + pytest |
| Decode / ALU / M | `gate_01_02`, `gate_p02/p07/p08` | `phase_01_02`, `phase_p0*` | pytest |
| Hazard / forward / BP / RAS | `gate_01_03/04`, `gate_03_07`, `gate_04_02/06` | `phase_01_03/04` | pytest |
| Trap / IRQ / CSR / through-trap | `gate_02_00`, `gate_03_01/02`, `gate_03_12`, `gate_04_01` | `phase_02_00`, `phase_03_01`, `phase_03_12` | `make all` + pytest |
| Mem wrapper / misalign / mepc | `gate_02_01/02/03` | `phase_02_0*` | pytest |
| **Spike lockstep (directed)** | `gate_03_00/03/04/05/06/08/10` | `phase_03_0*` | `make all` (Verilator+Spike) |
| **riscv-dv lockstep (random)** | `gate_03_09` | `phase_03_09_riscvdv_lockstep` | `run_riscvdv_lockstep.py` |
| Coverage | `gate_04_00..09` | `phase_04_0*` | pytest |
| Lint / synth | `gate_05_00/01`, `gate_10` | `phase_05_*`, `phase_p_*` | OUTSIDE-SANDBOX |
| Per-module signoff | `gate_p01..p19` | `phase_p*` | pytest |

## 3. Large-scale lockstep run (seed-locked)
- **riscv-dv 105,111 commits vs Spike, 0 divergence / 0 waiver** — seeds `2026061001..2026061019`.
  Summary: `flow/v2_pipeline/phase_03_09_riscvdv_lockstep/riscvdv_lockstep_summary.json`
  (`status=PASS`, `total_matched_commits=105111`, `unresolved_real_dut_divergences=0`).
  Reproduce: `python3 run_riscvdv_lockstep.py --start-seed 2026061001 --seeds 120 --instr-cnt 20000
  --target-commits 100000 --max-cycles 10000000`.
- ISA: `rv32imc_zicsr_zifencei`; Spike golden `rv32imc_zicsr_zifencei_zicntr`.
- Scope EXCLUDED (directed-only, not in the random farm): async interrupts, riscv-dv SYNCH/fence stream,
  A/F/D/V. (Blocker #4 — to fold into the farm; see `tier2_acceptance_gap_and_closure.md` §3.)

## 4. Licensed-EDA evidence (OUTSIDE-SANDBOX, retained)
- Spyglass lint 0/0: `phase_p_lint_current/` · CDC/RDC/X-prop clean: `phase_p_cdc_rdc_xprop/`
- VC Formal 40/40 proven: `phase_p_formal/` · formal coverage (4/5 modules): `phase_p_formal_coverage/`
- Multi-corner DC trial (setup): `phase_p_multicorner_dc/` · arch-test 74/74: `phase_p_archtest/`

## 5. Reproducibility caveats (honest)
- Spike build: 1.1.1-dev — `--log-commits` halts logging after the first M-mode sync trap (see
  `gate_03_12`); through-trap handler is spec-validated, prefix is Spike-locked.
- No nightly CI farm yet (§05 wants automated nightly + coverage-DB merge) — currently on-demand.
- Coverage DBs are per-TB (not a single merged whole-core DB) — see `coverage_report.md` §2.
