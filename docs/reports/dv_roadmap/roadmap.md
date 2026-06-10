# Magpie_M1 DV Roadmap: Toward a Credible "Passes Google riscv-dv" Claim

**Scope**: RV32IMC + Zicsr + Zifencei, M-mode only (no U/S-mode, no PMP, no F/D/V unless later ADR).

## 1. What "Passes riscv-dv" Should Mean (Industry-Grade Definition)

"Passes Google riscv-dv" is a customer-defensible claim only when the following are all true:

- The DUT runs the **standard riscv-dv test library** (not a single custom generator stream) with a configuration limited to the exact supported ISA and privileged subset.
- **Per-commit ISS lockstep** (Spike) is performed on architectural state (GPRs, PC, mepc/mcause/mstatus/mtval, relevant CSRs) for every instruction, including synchronous traps. Non-deterministic timing state (cycle, instret) is explicitly excluded from comparison, as already practiced.
- **Functional coverage** is collected on every run, merged across seeds/categories, reported as part of the regression, and reaches 100% on the committed covergroups (or 100% with a documented, reviewed waiver list). Line/toggle coverage is also tracked.
- **Scale** is statistically meaningful: multiple seeds per category, hundreds of thousands to low millions of instructions per major regression wave.
- Both fast iteration (Verilator) and sign-off quality (VCS) simulators are used, with demonstrated parity on key categories.
- Full provenance is captured and archived (riscv-dv version + config, Spike version + any patches, DUT git SHA, seeds, command lines, logs, coverage databases) so any result is independently replayable.
- All real DUT bugs found are fixed (or explicitly waived with evidence); there are zero unwaived mismatches at the end of a completed wave.

**Standard riscv-dv test categories appropriate for RV32IMC_Zicsr_Zifencei (M-mode only)** (others disabled via yaml/config):

- `riscv_rand_instr_test` (full-mix random instruction stream — the current "instr stream" usage)
- `riscv_arithmetic_basic_test`
- `riscv_compressed_instr_test` (RV32C)
- `riscv_load_store_test`
- `riscv_unaligned_load_store_test`
- `riscv_jump_test`
- `riscv_csr_test` (Zicsr M-mode behavior)
- `riscv_illegal_instr_test`
- `riscv_full_interrupt_test` (async interrupts, mie/mip, priority, wfi)
- `riscv_mmu_stress_test` / `riscv_privileged_mode_test` (adapted / limited for bare M-mode only; many sub-tests will be no-op or skipped)

Unsupported categories (F/D, vector, U-mode, S-mode, hypervisor, debug-mode heavy, PMP stress) are explicitly turned off.

**Minimum quantitative bar for a credible claim**:
- ≥5 seeds × 50k–200k commits for core categories (arithmetic, load/store, compressed, jump, csr, full-mix).
- ≥3 seeds for interrupt and illegal categories (initially lower volume due to complexity).
- At least one aggregate hero wave of ≥1M total commits across the matrix.
- 100% functional coverage on the M1 covergroups (or explicit waiver log).
- Clean lockstep (0 unwaived mismatches) on both Verilator and VCS parity runs.

## 2. Prioritized Phased Roadmap (P0–P3)

### P0: Unblock Full Instruction Streams (Spike Traps + Category Expansion)

**P0.1 — Resolve Spike sync-trap logging limitation**  
**Goal**: Make random streams that generate synchronous traps (ecall, ebreak, illegal, misaligned load/store) fully locksteppable; eliminate the current "halts logging at M-mode ecall entry" behavior with Spike 1.1.1-dev.  
**Concrete steps**:
1. Reproduce the exact truncation point using current Spike + `--log-commits` on M-mode ecall and other traps.
2. Adopt a newer Spike build (riscv-isa-sim mainline after 1.1.1-dev) or a minimal, documented local patch that keeps commit logging alive through trap entry, mcause/mepc/mstatus/mtval update, and the first post-trap instruction.
3. Update the cosim harness/log consumer to parse and compare state across the trap boundary.
4. Validate with both directed trap tests and random seeds that deliberately hit ecall/ecall-in-stream.
**Agent**: Grok (plan/spec Spike version/patch strategy and exact comparison points around traps); Codex (implement harness changes and any patch); Claude (integrate, commit updated Spike build harness + provenance recording, and rebase ongoing waves).
**Risk**: Medium (Spike logging around ecall/exit is brittle; may require a maintained DV-oriented Spike variant).
**Done-criterion**: ≥10k–50k commit random run containing multiple ecalls/traps shows 100% architectural match (pre-trap, trap state, post-trap) with continuous commit log on both DUT and Spike; no truncation.

**P0.2 — Switch from single instr stream to the standard riscv-dv category library**  
**Goal**: Drive the full set of M1-appropriate categories (listed in §1) instead of one generator stream.  
**Concrete steps**:
1. Create `riscv_dv_m1.yaml` (or equivalent) that enables only RV32IMC_Zicsr_Zifencei, compressed, muldiv, Zicsr, Zifencei, priv=m, and disables all unsupported extensions/modes.
2. Extend the pyflow to accept a category list or "full_m1_matrix" and map each to appropriate seed/iteration counts and config overrides.
3. Execute smoke-scale runs (5k–10k instr) on every category; promote clean ones into the main regression.
4. Document category-specific configuration and any required waivers (e.g., tests that assume U-mode or PMP).
**Agent**: Codex (implement yaml + multi-category driver and config matrix); Claude (integrate into existing flow, commit, and wire to J-wave style runs); Grok (specify the exact enabled subset and M-mode-only knobs).
**Risk**: Low–Medium (some categories will immediately expose gaps (b) and (e)).
**Done-criterion**: All §1 categories are invocable; non-interrupt categories complete small-scale lockstep runs and are logged; a single target or script exercises the "standard library" for M1. (J16 full-mix 100k run counts as the first P0.2 data point.)

### P1: Interrupts, Integrated Coverage, and Credible Scale (Close Core Gaps)

**P1.1 — Enable async interrupts in lockstep**  
**Goal**: Exercise and verify M-mode interrupt handling (mie, mip, mstatus.MIE, mepc on interrupt entry, priority, preemption, wfi) under both dedicated tests and random injection.  
**Concrete steps**:
1. Add controllable IRQ sources (MTI, MEI, MSI) to the Verilator testbench, driven from the pyflow with random or scripted timelines.
2. Implement consistent Spike-side interrupt injection (Spike API mip poke at a given step count, or external event log + replay).
3. Extend comparison to recognize interrupt traps vs. sync traps and tolerate architecturally allowed latency windows.
4. Enable `riscv_full_interrupt_test`; add random interrupt overlay to other categories and directed timing cases (interrupt during mul, load, immediately after mret, during compressed sequence).
**Agent**: Codex (testbench driver + Spike injection logic); Claude (lockstep comparison updates and end-to-end integration); Grok (spec the injection protocol, architectural expectations for M-mode only, and pass criteria for latency/priority).
**Risk**: High (classic source of non-deterministic "almost match" failures; requires robust sync points).
**Done-criterion**: `riscv_full_interrupt_test` (or equivalent) passes ≥3 seeds at 10k–50k instr with 0 unwaived mismatches; random injection during arithmetic/load/store streams is also clean; interrupt cover bins are hit on both sides.

**P1.2 — Tie the existing 100% functional coverage into the main DV regression**  
**Goal**: The current separate covergroup harness becomes mandatory, always-on, merged, and reported for every riscv-dv run.  
**Concrete steps**:
1. Port/include the covergroup definitions and sampling into the primary cosim testbench used by the riscv-dv pyflow.
2. Add per-run + cross-seed/cros-category merge and report generation (text + machine-readable for IDE).
3. Surface coverage % in wave logs, Jxx status, and regression summaries.
4. Move from "report only" to threshold enforcement (initially overall or critical bins) with a formal waiver process.
**Agent**: Codex (integrate covergroups and merge/report scripts); Gemini (whole-corpus analysis: map the current 100% covergroups against RTL, all prior large-run logs, and the new standard categories to identify gaps, over-constrained bins, or missing cross-boundary/trap/interrupt points); Claude (wire into regression driver, state recording, and gate logic).
**Risk**: Low (coverage already proven on a separate harness).
**Done-criterion**: Every simulation in the regression produces a coverage database and summary; a P1-scale run reports the same (or better) 100% numbers as the prior separate harness; coverage artifacts are versioned with each wave.

**P1.3 — Ramp scale to customer-defensible volumes**  
**Goal**: Move from "few thousand commits" per wave to hundreds of k–M+ with multiple seeds and the full category matrix.  
**Concrete steps**:
1. Lock explicit targets (see §1 quantitative bar): arithmetic/compressed/load-store/jump ≥100k–200k × ≥5 seeds; CSR/full-mix ≥50k–100k × ≥5 seeds; interrupt/illegal ≥20k–50k × ≥3 seeds; one hero wave ≥1M aggregate commits.
2. Add seed sweeping, parallel job control, resumability, and automated triage (DUT bug vs. harness/Spike vs. known waiver) to the pyflow.
3. Update storage and CI resource requirements.
4. Treat the in-flight J16 100k full-mix as the immediate baseline and extend it.
**Agent**: Claude (scale orchestration, artifact capture, and status plumbing); Codex (parallel execution and triage tooling); Grok (finalize the exact scale matrix and statistical justification for the claim).
**Risk**: Medium (runtime and log storage).
**Done-criterion**: At least one P1 hero wave completes at/above the 1M aggregate target, all P0/P1 categories exercised, coverage integrated, and 0 unwaived lockstep failures after fixes.

### P2: Signoff Quality and Stress Hardening

**P2.1 — VCS signoff simulator parity**  
**Goal**: Prove key results are not Verilator-specific.  
**Concrete steps**:
1. Maintain a VCS-compatible filelist/top and cosim linkage (same seeds/configs).
2. Run a defined parity subset (full-mix + csr + interrupt at 1–2 seeds) on VCS.
3. Compare pass/fail, URG coverage, and any 4-state/X behavior vs. Verilator golden.
4. Document and close divergences (if any).
**Agent**: Claude (orchestrate VCS flow and parity execution); Codex (tb/linkage differences); Grok (define mandatory signoff subset vs. Verilator-fast-only categories).
**Risk**: Medium (license, runtime, potential semantic differences).
**Done-criterion**: VCS parity subset matches Verilator results on identical seeds; coverage within tolerance; "VCS signoff" section appears in the final report.

**P2.2 — Long-stress, negative testing, and residual gap closure**  
**Goal**: Exercise rare corners and confirm no systemic gaps remain.  
**Concrete steps**:
1. Add multi-million-commit background stress (full-mix + interrupt overlay).
2. Layer negative/constrained-random overlays (illegal bursts, bad CSR writes, cross-boundary RVC + trap, M-unit + interrupt races, fence.i + fetch, Zifencei edge cases).
3. Run Gemini-scale corpus analysis on all large prior logs (J16 + P1 waves) for low-hit or suspicious patterns.
4. Close any remaining coverage holes or add micro-arch coverpoints required for customer review.
**Agent**: Gemini (large-scale log/corpus analysis for hidden patterns); Codex (stress/negative generators); Claude (integration, triage, and fixes); Grok (curate negative list and long-stress success bar).
**Risk**: Low–Medium (may surface new subtle bugs).
**Done-criterion**: ≥1 clean multi-million commit stress run; high-priority negative scenarios added and passing; no new DUT bugs indicating a missed class of behavior.

### P3: Claim Packaging, Gates, and Continuous Regression

**P3.1 — Produce the defensible evidence package and integrate as a gate**  
**Goal**: Turn technical completion into a reviewable, blocking milestone with full artifacts and reproducibility.  
**Concrete steps**:
1. Write the final report (this roadmap + results matrix, coverage numbers, full bug log including the 6 already fixed, waiver list with justification, Spike/riscv-dv provenance + patches, exact replay commands for golden seeds).
2. Archive all artifacts under `docs/reports/dv_roadmap/` and `flow/`.
3. Add/extend a pytest gate (e.g., `gate_03_xx_riscvdv_full.py` or successor) that runs a defined smoke subset of the matrix and enforces pass + coverage thresholds.
4. Wire the gate into the project phase-gate sequence so "cpu_m1 passes riscv-dv regression" is a tracked, blocking item.
**Agent**: Claude (author report, implement gate script, `record_step` the milestone); Grok (review claim language and quantitative targets for defensibility); Gemini (supply corpus-backed summary statistics from all runs); Codex (final tooling polish).
**Risk**: Low.
**Done-criterion**: Report checked in and internally reviewed; gate script exists and the P3 smoke target is green on a blessed seed set; IDE shows the riscv-dv milestone for magpie_m1; clear instructions exist for an independent party to replay a 10k–50k commit subset and obtain matching results.

**Overall P3 exit criteria (the actual claim)**:
- All P0–P2 done-criteria satisfied.
- ≥1 full hero regression (P1.3 scale) clean on both Verilator and VCS parity.
- 100% functional coverage (or explicit waiver log).
- The 6 previously found real DUT bugs (cross-boundary fetch, branch-target latch, M-unit done-race, wrong-path M-start, mstatus.MPP, mscratch forwarding) plus any later discoveries are fixed and non-regressed.
- All named gaps closed: sync traps lockstepped, interrupts exercised, standard categories used, coverage tied into the regression, scale at target.
- Full provenance and replay instructions published.

## 3. Summary & Dependencies

- **P0** (traps + categories) is the critical path; start immediately and use J16 data.
- **P1** items are largely parallel once P0.1 (Spike traps) is green.
- **P2** follows P1; **P3** is packaging + gate integration.
- **Key external dependencies**: newer/patchable Spike build; licensed VCS for P2; continued agent bandwidth (Claude for integration/commit, Codex for implementation, Gemini for corpus analysis, Grok for planning).
- **Token / process discipline**: large log/coverage/divergence corpuses go to Gemini for condensation before Claude review; every wave records provenance; producer ≠ approver on final claim.

When P3 completes, the statement "Magpie_M1 passes Google riscv-dv for RV32IMC_Zicsr_Zifencei (M-mode only)" will be both technically accurate at industry scale and defensible to customers or auditors, with artifacts that survive external scrutiny.
