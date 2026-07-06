# Magpie_M1 lab08e pipeline full verification report

Status: **draft / not-yet-qualified**

This report is the required sign-off container for turning the copied Ch2
`lab08e` RTL into the active reusable Magpie_M1 CPU IP. The copied RTL and
lint-only gate are not sufficient qualification evidence.

## Scope

- Active variant: `v2_pipeline_ch2_lab08e`
- Source RTL: `~/project/lab/CPU/Ch2/lab08e/rtl`
- Local RTL: `design/cpu_m1/rtl`
- ISA target: `RV32IMC_Zicsr_Zifencei`
- Microarchitecture: 4-stage pipeline + BP + RAS + RV32C + pre-fetch residue
  buffer
- Status: not qualified until every must-have item below is closed

## Superseded FSM Check

ADR-0001's FSM path is superseded for implementation. It remains historical
context only and must not be presented as an active sign-off baseline.

Required compatibility decisions before lab08e qualification:

- Define a stable architectural commit trace format for lab08e Spike lockstep.
- Wrap Ch2 synchronous I/D memory behavior to the Magpie_M1 valid-ready
  contract, or explicitly ADR any active protocol change.
- Keep the reduced lab08b checkpoint separate from the active lab08e product
  line.

## Must-Have Verification Matrix

| Area | Required evidence | Current status |
|---|---|---|
| Provenance | Ch2 source path, copied file list, ADR-0002 | present |
| RTL parse | Verilator lint-only on local lab08e RTL | pass |
| Wrapper | Magpie_M1 imem/dmem valid-ready wrapper or v2 protocol ADR | not-run |
| Directed RV32I/M | ALU, branch, load/store, mul/div corner tests | directed-lockstep-pass for bounded RV32IMC slice plus Phase 3.7 directed M-unit hazard/corner regression; broader corners still needed |
| Directed RV32C | compressed decode, PC +2/+4, illegal compressed encodings | smoke-sim-pass for boot/LED/IRQ firmware with forced compressed boot sequence |
| Pre-fetch | cross-boundary zero-cycle assemble and fallback path | structural gate + smoke-sim-pass; targeted cross-boundary assertions still needed |
| BP/RAS | predictor update, return prediction, mispredict recovery | structural-lint-pass; directed predictor/RAS simulation not-run |
| Hazards | RAW forwarding, load-use stall, mul/div busy stall | Phase 3.7 directed mul/div hazard lockstep pass; broader non-M hazard simulation still needed |
| Flush | redirect priority and wrong-path side-effect suppression | structural-lint-pass; targeted wrong-path assertions not-run |
| CSR/trap/IRQ | mstatus/mepc/mcause, mret, IRQ timing, 16-bit mepc behavior | irq-collision-contract-pass for 16-bit IRQ mepc plus current pulse-contract collision regression; broader CSR/IRQ corners not-run |
| Spike lockstep | RV32IMC per-commit first mismatch report | bounded directed-slice pass: 14 normal commits + 13 pre-IRQ commits + 40 expanded directed commits + 81 deterministic random commits + 405 multi-seed random commits matched Spike; broader random/DV seeds still needed |
| Google RISC-V DV | constrained RV32IMC seeds and replay archive | not-run |
| Coverage | line 100% or per-line reason/reachability/waiver | residual-analysis-pass: 236 uncovered lines listed with reason/reachability/closure plan; not closure |
| Lint | no unwaived high/critical issues | not-run |
| FPGA PPA | LUT/FF/BRAM/DSP, timing/Fmax, optional power, regression delta | not-run |
| Handoff | commands, logs, VCD excerpts, waiver table, bug taxonomy | not-run |

## Qualification Tier Policy

Pytest `pass` only means the gate executed its current checks successfully. The
qualification tier is the phase-local status, for example:

- `structural-lint-pass`: source structure and lint are checked, but behavior is
  not qualified.
- `smoke-sim-pass`: one smoke program ran, but it is not a directed closure
  claim.
- `directed-sim-pass`: a named architectural or microarchitectural behavior was
  exercised and checked by simulation.
- `spike-lockstep-pass`: commit trace was compared against Spike for the named
  program or seed set.
- `coverage-closed`: coverage target met, or every miss has a reason/waiver.

IDE gate matrices must display this tier next to pytest status; otherwise a
structural green result can be mistaken for CPU qualification.

## Coverage Policy

Line coverage target is 100%. If line coverage is below 100%, the report must
list every uncovered line with:

- reason,
- reachability assessment,
- closure test plan or approved waiver,
- owner and date.

Toggle and functional coverage targets follow the CPU IP sign-off plan unless a
variant-specific ADR changes them.

## VCD Review Policy

VCD generation follows `docs/vcd_review_policy.md`. Each simulation-producing
phase must provide a phase-local `vcd_manifest.md` before its VCD is treated as
review evidence. The manifest must define review questions, required signals,
dump windows, trace settings, full-debug escape hatch, size envelope, and known
blind spots.

The default VCD is allowed to be focused, but not underspecified. If a reviewer
cannot answer the phase's stated review questions from the default waveform and
log, the phase must either expand its default signal set/window or document why
full-debug tracing is required for that class of failure.

## Required Report Artifacts

- `tests/gates/gate_01_01_fetch_rv32c_prefetch.py`
- `tests/gates/gate_01_99_phase1_closure.py`
- `tests/gates/gate_02_00_trap_interrupt.py`
- `tests/gates/gate_03_00_spike_lockstep.py`
- `docs/phase1_closure_report.md`
- `flow/v2_pipeline/phase_01_01_fetch_rv32c_prefetch/Makefile`
- `flow/v2_pipeline/phase_01_01_fetch_rv32c_prefetch/vcd_manifest.md`
- `flow/v2_pipeline/phase_01_01_fetch_rv32c_prefetch/system_pynq.v`
- `flow/v2_pipeline/phase_01_01_fetch_rv32c_prefetch/tb_core.v`
- `flow/v2_pipeline/phase_01_01_fetch_rv32c_prefetch/firmware.S`
- `flow/v2_pipeline/phase_01_01_fetch_rv32c_prefetch/firmware.c`
- `flow/v2_pipeline/phase_01_01_fetch_rv32c_prefetch/firmware.lds`
- `flow/v2_pipeline/phase_01_01_fetch_rv32c_prefetch/firmware.hex`
- `flow/v2_pipeline/phase_01_01_fetch_rv32c_prefetch/firmware.disasm`
- `flow/v2_pipeline/phase_01_01_fetch_rv32c_prefetch/sim.log`
- `flow/v2_pipeline/phase_01_01_fetch_rv32c_prefetch/wave.vcd`
- `flow/v2_pipeline/phase_02_00_trap_interrupt/README.md`
- `flow/v2_pipeline/phase_02_00_trap_interrupt/Makefile`
- `flow/v2_pipeline/phase_02_00_trap_interrupt/tb_trap_irq.v`
- `flow/v2_pipeline/phase_02_00_trap_interrupt/firmware.S`
- `flow/v2_pipeline/phase_02_00_trap_interrupt/firmware.lds`
- `flow/v2_pipeline/phase_02_00_trap_interrupt/firmware.hex`
- `flow/v2_pipeline/phase_02_00_trap_interrupt/firmware.disasm`
- `flow/v2_pipeline/phase_02_00_trap_interrupt/sim.log`
- `flow/v2_pipeline/phase_02_00_trap_interrupt/wave.vcd`
- `flow/v2_pipeline/phase_02_00_trap_interrupt/vcd_manifest.md`
- `flow/v2_pipeline/phase_03_00_spike_lockstep/README.md`
- `flow/v2_pipeline/phase_03_00_spike_lockstep/Makefile`
- `flow/v2_pipeline/phase_03_00_spike_lockstep/tb_spike_lockstep.v`
- `flow/v2_pipeline/phase_03_00_spike_lockstep/spike_lockstep.py`
- `flow/v2_pipeline/phase_03_00_spike_lockstep/firmware.S`
- `flow/v2_pipeline/phase_03_00_spike_lockstep/firmware.lds`
- `flow/v2_pipeline/phase_03_00_spike_lockstep/firmware_spike.lds`
- `flow/v2_pipeline/phase_03_00_spike_lockstep/dut_commit.trace`
- `flow/v2_pipeline/phase_03_00_spike_lockstep/spike_commit.trace`
- `flow/v2_pipeline/phase_03_00_spike_lockstep/lockstep.log`
- `flow/v2_pipeline/phase_03_00_spike_lockstep/lockstep_report.md`
- `tests/gates/gate_03_01_trap_irq_lockstep.py`
- `flow/v2_pipeline/phase_03_01_trap_irq_lockstep/README.md`
- `flow/v2_pipeline/phase_03_01_trap_irq_lockstep/Makefile`
- `flow/v2_pipeline/phase_03_01_trap_irq_lockstep/tb_trap_irq_lockstep.v`
- `flow/v2_pipeline/phase_03_01_trap_irq_lockstep/trap_irq_lockstep.py`
- `flow/v2_pipeline/phase_03_01_trap_irq_lockstep/dut_commit.trace`
- `flow/v2_pipeline/phase_03_01_trap_irq_lockstep/dut_trap.trace`
- `flow/v2_pipeline/phase_03_01_trap_irq_lockstep/spike_prefix.trace`
- `flow/v2_pipeline/phase_03_01_trap_irq_lockstep/trap_irq_lockstep.log`
- `flow/v2_pipeline/phase_03_01_trap_irq_lockstep/trap_irq_lockstep_report.md`
- `tests/gates/gate_03_02_irq_collision.py`
- `flow/v2_pipeline/phase_03_02_irq_collision/README.md`
- `flow/v2_pipeline/phase_03_02_irq_collision/Makefile`
- `flow/v2_pipeline/phase_03_02_irq_collision/tb_irq_collision.v`
- `flow/v2_pipeline/phase_03_02_irq_collision/firmware.S`
- `flow/v2_pipeline/phase_03_02_irq_collision/firmware.lds`
- `flow/v2_pipeline/phase_03_02_irq_collision/irq_collision.trace`
- `flow/v2_pipeline/phase_03_02_irq_collision/sim.log`
- `flow/v2_pipeline/lib/spike_commit.py`
- `tests/gates/gate_03_03_spike_comparator_lib.py`
- `tests/gates/gate_03_04_directed_lockstep.py`
- `flow/v2_pipeline/phase_03_04_directed_lockstep/README.md`
- `flow/v2_pipeline/phase_03_04_directed_lockstep/Makefile`
- `flow/v2_pipeline/phase_03_04_directed_lockstep/tb_directed_lockstep.v`
- `flow/v2_pipeline/phase_03_04_directed_lockstep/directed_lockstep.py`
- `flow/v2_pipeline/phase_03_04_directed_lockstep/firmware.S`
- `flow/v2_pipeline/phase_03_04_directed_lockstep/dut_commit.trace`
- `flow/v2_pipeline/phase_03_04_directed_lockstep/spike_commit.trace`
- `flow/v2_pipeline/phase_03_04_directed_lockstep/directed_lockstep.log`
- `flow/v2_pipeline/phase_03_04_directed_lockstep/directed_lockstep_report.md`
- `tests/gates/gate_03_05_random_lockstep.py`
- `flow/v2_pipeline/phase_03_05_random_lockstep/README.md`
- `flow/v2_pipeline/phase_03_05_random_lockstep/Makefile`
- `flow/v2_pipeline/phase_03_05_random_lockstep/gen_random_program.py`
- `flow/v2_pipeline/phase_03_05_random_lockstep/tb_random_lockstep.v`
- `flow/v2_pipeline/phase_03_05_random_lockstep/random_lockstep.py`
- `flow/v2_pipeline/phase_03_05_random_lockstep/firmware.S`
- `flow/v2_pipeline/phase_03_05_random_lockstep/dut_commit.trace`
- `flow/v2_pipeline/phase_03_05_random_lockstep/spike_commit.trace`
- `flow/v2_pipeline/phase_03_05_random_lockstep/random_lockstep.log`
- `flow/v2_pipeline/phase_03_05_random_lockstep/random_lockstep_report.md`
- `tests/gates/gate_03_06_multi_seed_coverage.py`
- `flow/v2_pipeline/phase_03_06_multi_seed_coverage/README.md`
- `flow/v2_pipeline/phase_03_06_multi_seed_coverage/Makefile`
- `flow/v2_pipeline/phase_03_06_multi_seed_coverage/run_seed_sweep.py`
- `flow/v2_pipeline/phase_03_06_multi_seed_coverage/seed_summary.csv`
- `flow/v2_pipeline/phase_03_06_multi_seed_coverage/multi_seed_coverage.log`
- `flow/v2_pipeline/phase_03_06_multi_seed_coverage/multi_seed_coverage_report.md`
- `flow/v2_pipeline/phase_03_06_multi_seed_coverage/coverage/merged_coverage.dat`
- `flow/v2_pipeline/phase_03_06_multi_seed_coverage/coverage/coverage.info`
- `flow/v2_pipeline/phase_03_06_multi_seed_coverage/coverage/annotated/`
- `tests/gates/gate_03_07_muldiv_hazard.py`
- `flow/v2_pipeline/phase_03_07_muldiv_hazard/README.md`
- `flow/v2_pipeline/phase_03_07_muldiv_hazard/Makefile`
- `flow/v2_pipeline/phase_03_07_muldiv_hazard/firmware.S`
- `flow/v2_pipeline/phase_03_07_muldiv_hazard/tb_muldiv_hazard.v`
- `flow/v2_pipeline/phase_03_07_muldiv_hazard/muldiv_hazard.py`
- `flow/v2_pipeline/phase_03_07_muldiv_hazard/dut_commit.trace`
- `flow/v2_pipeline/phase_03_07_muldiv_hazard/spike_commit.trace`
- `flow/v2_pipeline/phase_03_07_muldiv_hazard/muldiv_hazard.log`
- `flow/v2_pipeline/phase_03_07_muldiv_hazard/muldiv_hazard_report.md`
- `flow/v2_pipeline/phase_03_07_muldiv_hazard/wave.vcd`
- `tests/gates/gate_04_00_coverage.py`
- `flow/v2_pipeline/phase_04_00_coverage_residual/README.md`
- `flow/v2_pipeline/phase_04_00_coverage_residual/analyze_coverage.py`
- `flow/v2_pipeline/phase_04_00_coverage_residual/module_coverage_summary.csv`
- `flow/v2_pipeline/phase_04_00_coverage_residual/uncovered_lines.csv`
- `flow/v2_pipeline/phase_04_00_coverage_residual/coverage_residual_report.md`
- `docs/adr/0003-csr-external-irq-pending-collision.md`
- `docs/adr/0004-m-unit-result-latch.md`
- `flow/v2_pipeline/sim/*.log`
- `flow/v2_pipeline/sim/*.vcd`
- `flow/v2_pipeline/spike/*.log`
- `flow/v2_pipeline/riscv-dv/*`
- `flow/v2_pipeline/coverage/*`
- `flow/v2_pipeline/lint/*`
- `flow/v2_pipeline/fpga/*`
- `flow/v2_pipeline/waivers/*.md`
- `docs/v2_pipeline_bug_taxonomy.md`

## Current Conclusion

The lab08e RTL is integrated, lint-parsable, has one Magpie_M1-owned Phase 1.1
Verilator smoke simulation passing, and now has a Phase 2.0 directed IRQ test
for the high-risk 16-bit `mepc` path. The smoke program exercises RV32IMC boot
code, forced compressed instructions, LED MMIO progress, and BTN1 machine
external interrupt return. The Phase 2.0 directed program injects IRQ on a
fixed 16-bit instruction and checks `mepc=0x82`, `mcause=0x8000000b`, and `mret`
resume. Phase 3.0 now has the first bounded Spike lockstep slice: 14 commits of
a directed RV32IMC program match Spike on PC, instruction encoding, destination
register, and writeback data. Phase 3.1 extends that into the high-risk
compressed-instruction IRQ case: 13 pre-IRQ commits match Spike, then the
deterministic trap model checks `mepc=0x82`, `mcause=0x8000000b`,
handler-observed `mstatus=0x80`, and `mret` resume.

Phase 3.1 found a real IRQ pending collision in the pulse-based external IRQ
model: `csr.v` previously prioritized `irq_external_pulse` over `trap_enter` in
the `ext_pending` mux. If the pulse overlapped trap entry, pending could remain
set and retrigger after `mret`. Magpie_M1 now carries a local RTL deviation that
gives trap-entry hardware ack priority. ADR-0003 records the provenance and
rationale. Phase 3.2 closes the current pulse contract with a directed
collision regression: a pulse sampled in the same cycle as `trap_enter` is
acknowledged with that trap entry, while a pulse sampled after `trap_enter` is
latched and causes a second IRQ after `mret`.

Phase 3.5 scales the lockstep path to a deterministic bounded pseudo-random
RV32IMC program. Seed `20260607`, count `48`, matched 81 DUT commits against
Spike. This run found and closed a real M-unit result-routing bug: a divide
instruction wrote `0x00000000` in DUT while Spike expected `0x0000007b`.
Magpie_M1 now carries a local `core.v` RTL deviation that latches the active
M-operation type and completed result before writeback. ADR-0004 records the
provenance and rationale.

Phase 3.6 converts that single-seed random test into a small seed ladder and
turns on Verilator coverage. Seeds `20260607` through `20260611`, each with
`COUNT=48`, matched 405 total commits against Spike. The merged Verilator lcov
line measurement is 894 / 1130 lines = 79.12%. This is measurement evidence, not
coverage closure; every uncovered line still needs directed closure, reason, or
waiver before sign-off.

Phase 3.7 adds a directed M-unit hazard regression for ADR-0004. The program
matched 45 commits against Spike and covers back-to-back `mul`/`div`/`rem`,
immediate M-result consumers, M-result store/load/address use, divide-by-zero,
signed overflow, unsigned divide/remainder, and compressed instructions after
the M stress window. The testbench VCD exposes `md_started`,
`md_active_is_div`, `md_result_valid`, `md_result_q`, `md_done`, `md_busy`, and
M-result pipeline registers for review.

Phase 4.0 converts the Phase 3.6 coverage measurement into a residual list.
The sign-off headline is DUT-only: line coverage is 818 / 1054 = 77.61%, with
236 DUT uncovered lines. Total line coverage including the testbench is
894 / 1130 = 79.12%, but testbench coverage is not counted toward DUT sign-off.
DUT toggle coverage is 7500 / 12246 = 61.24%, below the >=85% target.
Functional coverage bins are not implemented yet. Every uncovered line is
listed in `uncovered_lines.csv` with category, reachability, reason, closure
plan, owner/date, and waiver status. This phase is not coverage closure; it is
the input backlog for directed closure and waiver review.

Phase 4.1 starts directed coverage closure on the highest-risk CSR/IRQ bucket.
It adds CSR write/set/clear, unknown CSR, counter, pending-MIP, external IRQ,
trap-entry, handler CSR-read, and mret-resume stimulus, then merges its
coverage with the Phase 3.6 seed baseline. DUT line coverage improves to
946 / 1054 = 89.75% (+128 lines), and DUT toggle coverage improves to
7904 / 12246 = 64.54% (+404 normalized toggle points). Coverage remains not
closed.

Phase 4.2 adds directed BP/RAS coverage closure. It trains backward branches,
exercises another predictor entry, and drives nested `jal ra` / `ret` sequences
through the RAS while proving loop/call/return progress with MMIO markers. The
coverage database is merged on top of Phase 4.1. DUT line coverage improves to
991 / 1054 = 94.02% (+45 lines), and DUT toggle coverage improves to
8082 / 12246 = 66.00% (+178 normalized toggle points). Coverage remains not
closed.

Phase 4.3 adds directed RV32C decode and cross-boundary pre-fetch coverage.
It exercises legal compressed Q0/Q1/Q2 decode forms and both sequential
cross-boundary fast path and redirect-to-high-half fallback path. The coverage
database is merged on top of Phase 4.2. DUT line coverage improves to
1022 / 1054 = 96.96% (+31 lines), and DUT toggle coverage improves to
8138 / 12246 = 66.45% (+56 normalized toggle points). Coverage remains not
closed.

Phase 4.4 adds illegal compressed terminal-trap coverage and M-unit
coverage merge/corners. `cdec.v` line coverage reaches 106 / 106 = 100.00%,
`div.v` line coverage reaches 70 / 71 = 98.59%, and `mul.v` toggle coverage
reaches 608 / 610 = 99.67%. DUT line coverage improves to
1035 / 1054 = 98.20% (+13 lines), and DUT toggle coverage improves to
8235 / 12246 = 67.25% (+97 normalized toggle points). Coverage remains not
closed.

Phase 4.5 triages the remaining coverage residuals after Phase 4.4. There are
19 DUT uncovered lines: 14 require more directed evidence and 5 are
waiver-candidates only. No waiver is approved by this phase. DUT line coverage
remains 1035 / 1054 = 98.20%, DUT toggle remains 8235 / 12246 = 67.25%, and
functional coverage is still not implemented.

Phase 4.6 closes the RAS residual line bucket with directed behavior evidence.
The integration firmware poisons `ra` before `ret`, forcing the IF-stage RAS
prediction to disagree with the actual JALR target. The testbench observes
`mem_ras_mispredict`, the RAS recovery redirect, and the actual-return marker
while proving the wrong-path predicted-return marker does not commit. The same
simulation also includes a direct `ras` instance for empty/non-empty same-cycle
push+pop pointer edges that firmware cannot naturally generate. DUT line
coverage improves to 1042 / 1054 = 98.86% (+7 lines), and DUT toggle coverage
improves to 8296 / 12246 = 67.74% (+61 normalized toggle points). `core.v` and
`ras.v` both reach 100% line coverage. Coverage remains not closed.

It is not qualified as Magpie_M1 CPU IP until wrapper, broader directed
simulation, more Spike/random/RISC-V DV seeds, coverage, lint, FPGA/PPA, waiver,
and handoff evidence are produced and reviewed.

## Phase 1 Closure

Phase 1 structural bring-up is closed when
`tests/gates/gate_01_99_phase1_closure.py` passes. This closure is explicitly
**not CPU-qualified** status. It means the lab08e active RTL baseline is
integrated, lint-parsable, smoke-runnable, structurally checked across
fetch/RV32C/pre-fetch, decode/execute, hazards, and BP/RAS/redirect, and ready
for Phase 2/3 functional qualification.

Closure report:

- `docs/phase1_closure_report.md`

Residuals transferred out of Phase 1:

- directed RV32I/M/C execute tests,
- directed hazard and wrong-path assertion tests,
- directed BP/RAS/redirect tests,
- CSR/trap/IRQ timing,
- Magpie_M1 valid-ready memory wrapper,
- commit trace and Spike lockstep,
- Google RISC-V DV,
- line/toggle/functional coverage,
- lint/synth/FPGA PPA sign-off.

## Phase 1.1 Evidence: Fetch / RV32C / Pre-Fetch Smoke

- Command: `make -B sim.log` in
  `flow/v2_pipeline/phase_01_01_fetch_rv32c_prefetch`
- Gate command:
  `python -m pytest tests/gates/gate_00_spec.py tests/gates/gate_10_pipeline_v2_reference.py tests/gates/gate_01_01_fetch_rv32c_prefetch.py`
- Result: `17 passed`
- Simulation result: `PASS: 35 LED transitions, BTN1 IRQ reset observed`
- Firmware evidence: `firmware.disasm` contains compressed boot opcodes
  (`0x0001`, `0x4281`) and trap return (`mret`)
- Waveform: `wave.vcd` generated as a focused review VCD with `tb_core` and
  wrapper-level `dut` scopes, including LED, IRQ, I/D memory, and
  `dbg_pc/dbg_instr/dbg_state`.
- VCD size policy: default `TRACE_DEPTH=2 REVIEW_TRACE=1` keeps wrapper/debug
  visibility and disables full `u_core` hierarchy tracing; measured VCD size was
  reduced from about 110 MB to about 11 MB. Deep debug remains available with
  `TRACE_DEPTH=5 REVIEW_TRACE=0 RUN_ARGS=+full_vcd`.
- VCD manifest: `flow/v2_pipeline/phase_01_01_fetch_rv32c_prefetch/vcd_manifest.md`
  records the review questions, required signals, dump windows, size envelope,
  and blind spots. This is required to prevent later phases from becoming too
  sparse to review.
- Limitation: this is a smoke test, not line coverage closure and not Spike
  lockstep.

## Phase 1.2 Evidence: Decode / Execute RV32IMC

- Gate:
  `tests/gates/gate_01_02_decode_execute_rv32imc.py`
- Evidence directory:
  `flow/v2_pipeline/phase_01_02_decode_execute_rv32imc`
- Gate command:
  `python -m pytest tests/gates/gate_00_spec.py tests/gates/gate_10_pipeline_v2_reference.py tests/gates/gate_01_01_fetch_rv32c_prefetch.py tests/gates/gate_01_02_decode_execute_rv32imc.py`
- Result: `25 passed`
- Covered by structural checks: RV32I opcode/funct constants, immediate formats,
  IDU ALU/branch/memory/CSR/M-extension controls, ALU operation mux, RF x0
  invariant, RV32M mul/div signed/unsigned behavior hooks, divide-by-zero and
  overflow constants, core mul/div stall integration, MD writeback mux, and RF
  write gating.
- Limitation: this closes only structural + Verilator lint evidence. Directed
  RV32I/M/C simulation, Python commit checking, coverage, and Spike lockstep are
  still not-run.

## Phase 1.3 Evidence: Pipeline Hazard

- Gate:
  `tests/gates/gate_01_03_pipeline_hazard.py`
- Evidence directory:
  `flow/v2_pipeline/phase_01_03_pipeline_hazard`
- Gate command:
  `python -m pytest tests/gates/gate_00_spec.py tests/gates/gate_10_pipeline_v2_reference.py tests/gates/gate_01_01_fetch_rv32c_prefetch.py tests/gates/gate_01_02_decode_execute_rv32imc.py tests/gates/gate_01_03_pipeline_hazard.py`
- Result: `33 passed`
- Covered by structural checks: EX/MEM over EX/WB forwarding priority, load
  exclusion from EX/MEM forwarding, load-use stall, mul/div busy stall,
  IF/EX/EX/MEM/EX/WB hold-or-bubble behavior, data-memory/CSR/RF side-effect
  suppression on redirect or IRQ, and redirect priority/recovery target
  selection.
- Limitation: this closes only structural + Verilator lint evidence. Directed
  hazard tests, wrong-path assertions, VCD-reviewed hazard cases, coverage, and
  Spike lockstep are still not-run.

## Phase 1.4 Evidence: BP / RAS / Redirect

- Gate:
  `tests/gates/gate_01_04_bp_ras_redirect.py`
- Evidence directory:
  `flow/v2_pipeline/phase_01_04_bp_ras_redirect`
- Gate command:
  `python -m pytest tests/gates/gate_00_spec.py tests/gates/gate_10_pipeline_v2_reference.py tests/gates/gate_01_01_fetch_rv32c_prefetch.py tests/gates/gate_01_02_decode_execute_rv32imc.py tests/gates/gate_01_03_pipeline_hazard.py tests/gates/gate_01_04_bp_ras_redirect.py`
- Result: `43 passed`
- Covered by structural checks: 2-way set-associative BP, RV32C-aware BP index,
  2-bit saturating counters, LRU replacement, JALR exclusion from BP update,
  RAS top/push/pop behavior, 16-bit and 32-bit return detection, RAS target
  mismatch recovery, redirect priority, and branch/JAL/JALR/not-taken recovery
  target selection.
- VCD policy: this structural phase does not generate a VCD. Directed
  predictor/RAS simulation must create a phase-local `vcd_manifest.md` following
  `docs/vcd_review_policy.md` before its waveform is accepted as review
  evidence.
- Limitation: this closes only structural + Verilator lint evidence. Directed
  predictor tests, VCD-reviewed redirect cases, coverage, and Spike lockstep are
  still not-run.

## Phase 2.0 Evidence: Trap / Interrupt

- Gate:
  `tests/gates/gate_02_00_trap_interrupt.py`
- Evidence directory:
  `flow/v2_pipeline/phase_02_00_trap_interrupt`
- Gate command:
  `python -m pytest tests/gates/gate_02_00_trap_interrupt.py`
- Result: `15 passed`
- Simulation command:
  `make -C flow/v2_pipeline/phase_02_00_trap_interrupt -B sim.log`
- Simulation result:
  `PASS: directed IRQ on 16-bit instruction saved mepc=00000082 mcause=8000000b and mret resumed`
- Covered by structural checks: M-mode CSR constants, CSR read mux, CSR
  write/set/clear operations, `mtvec` direct-mode masking, `mstatus` MIE/MPIE,
  `mie.MEIE`, `mip.MEIP`, external interrupt pending latch, trap entry, trap
  exit via `mret`, cycle/instret counter hooks, IDU CSR/MRET legality, WB
  commit-boundary IRQ handling, RF/CSR side-effect suppression on IRQ,
  redirect priority, illegal SYSTEM trap latch, and 16-bit-aware interrupt
  `mepc` next-PC selection.
- Covered by directed simulation: IRQ injection while the fixed 16-bit
  instruction at `PC=0x80` is in the pipeline, WB trap candidate
  `trap_pc=0x82`, handler-observed `mepc=0x82`, handler-observed
  `mcause=0x8000000b`, and successful `mret` resume to the instruction at
  `PC=0x82`.
- Waveform: `flow/v2_pipeline/phase_02_00_trap_interrupt/wave.vcd` generated
  with focused debug signals. The phase-local
  `flow/v2_pipeline/phase_02_00_trap_interrupt/vcd_manifest.md` records review
  questions, required signals, trace settings, size envelope, and full-debug
  escape hatch.
- Limitation: this closes one directed high-risk CSR/IRQ timing case, not
  complete CSR read/write coverage. Branch/JAL/JALR interrupted-commit corners,
  Spike lockstep, Google RISC-V DV, and coverage are still not-run.

## Phase 3.0 Evidence: Spike Lockstep

- Gate:
  `tests/gates/gate_03_00_spike_lockstep.py`
- Evidence directory:
  `flow/v2_pipeline/phase_03_00_spike_lockstep`
- Command:
  `make -C flow/v2_pipeline/phase_03_00_spike_lockstep -B lockstep.log`
- Result:
  `PASS: lockstep matched 14 commits`
- Compared fields: commit `pc`, `instr`, destination `rd`, and writeback
  `wdata`.
- Directed program coverage: compressed `c.li`/`c.addi`, RV32I ALU, RAM
  store/load, taken branch, RV32M `mul`, and `ebreak` terminator excluded from
  comparison.
- Spike memory-map note: Spike executes a separately linked ELF at
  `0x80000000`; the comparator normalizes Spike PCs and PC-relative register
  values back to the DUT's `0x0` reset/link address space.
- Limitation: this is a bounded directed vertical slice, not random DV,
  interrupt/CSR lockstep, full memory side-effect comparison, or coverage
  closure.

## Phase 3.1 Evidence: Trap / IRQ Lockstep

- Gate:
  `tests/gates/gate_03_01_trap_irq_lockstep.py`
- Evidence directory:
  `flow/v2_pipeline/phase_03_01_trap_irq_lockstep`
- Command:
  `make -C flow/v2_pipeline/phase_03_01_trap_irq_lockstep -B trap_irq_lockstep.log`
- Result:
  `PASS: prefix lockstep matched 13 commits; trap events matched mepc/mcause/mstatus/mret`
- Compared prefix fields: commit `pc`, `instr`, destination `rd`, and writeback
  `wdata` before the IRQ target.
- Checked trap fields: IRQ entry at `PC=0x80`, trap return candidate `0x82`,
  handler-observed `mepc=0x82`, `mcause=0x8000000b`, `mstatus=0x80`, `mret`
  target `0x82`, and resume marker `0x600d`.
- Local RTL deviation introduced by this phase: `csr.v` `ext_pending` priority
  changed from lab08e pulse-priority to trap-entry ack priority to prevent
  repeated IRQ after `mret` in the single-IRQ directed slice.
- Limitation: Spike is used for the pre-IRQ architectural prefix. External IRQ
  timing and CSR trap state are checked by a deterministic expected-event model,
  not by Spike's external interrupt injection.
- Follow-up: Phase 3.2 owns the collision-contract regression for the current
  pulse-based IRQ input.

## Phase 3.2 IRQ Collision Contract Evidence

- Gate:
  `tests/gates/gate_03_02_irq_collision.py`
- Evidence directory:
  `flow/v2_pipeline/phase_03_02_irq_collision`
- Command:
  `make -C flow/v2_pipeline/phase_03_02_irq_collision -B sim.log`
- Result:
  `PASS: IRQ collision contract validated`
- Contract checked:
  same-cycle `trap_enter` pulse is acknowledged with the current trap and does
  not create a third IRQ entry; a pulse sampled after `trap_enter` remains
  pending while MIE is disabled and causes a second IRQ after `mret`.
- Observed trace:
  first IRQ entry at `PC=0x80`, `mepc=0x82`; second IRQ entry at `PC=0x82`,
  `mepc=0x84`; exactly two handler entries and one final resume marker.
- Remaining architecture item:
  a future level-sensitive or claim/clear external interrupt wrapper may replace
  this pulse contract and should get its own ADR/gate.

## Phase 3.3 Spike Comparator Library Evidence

- Gate:
  `tests/gates/gate_03_03_spike_comparator_lib.py`
- Shared helper:
  `flow/v2_pipeline/lib/spike_commit.py`
- Scope:
  common RV32 Spike commit-log parsing, PC/writeback base normalization,
  commit CSV writing, commit comparison, and deterministic trap-event checking.
- Consumers:
  `phase_03_00_spike_lockstep/spike_lockstep.py` and
  `phase_03_01_trap_irq_lockstep/trap_irq_lockstep.py`.
- Result:
  parser/unit tests pass and Phase 3.0/3.1 gates replay through the shared
  helper. This reduces comparator drift before random/riscv-dv scaling.

## Phase 3.4 Expanded Directed Lockstep Evidence

- Gate:
  `tests/gates/gate_03_04_directed_lockstep.py`
- Evidence directory:
  `flow/v2_pipeline/phase_03_04_directed_lockstep`
- Command:
  `make -C flow/v2_pipeline/phase_03_04_directed_lockstep -B directed_lockstep.log`
- Result:
  `PASS: directed lockstep matched 40 commits`
- Added coverage pressure:
  compressed arithmetic, compressed load/store, byte/halfword/word
  load-store, taken/not-taken branch, `jal`, `jalr x0`, multiply,
  divide/remainder, load-use, and forwarding-sensitive producer/consumer chains.
- Harness note:
  JALR-to-x0 commit trace normalizes `rd=0,wdata=0` to match Spike's
  architectural no-write behavior.
- Limitation:
  bounded directed DV only; still not random DV, riscv-dv, or coverage closure.

## Phase 3.5 Deterministic Random Lockstep Evidence

- Gate:
  `tests/gates/gate_03_05_random_lockstep.py`
- Evidence directory:
  `flow/v2_pipeline/phase_03_05_random_lockstep`
- Command:
  `make -C flow/v2_pipeline/phase_03_05_random_lockstep -B random_lockstep.log`
- Result:
  `PASS: random lockstep matched 81 commits`
- Seed and size:
  deterministic seed `20260607`, generated instruction count `48`, DUT commit
  count `81`.
- Compared fields:
  commit `pc`, `instr`, destination `rd`, and writeback `wdata`.
- Generator guardrails:
  reserves `x31` as data base, reserves `x30` as non-zero divisor, emits aligned
  load/store offsets, and excludes privileged state, interrupts, atomics,
  self-modifying code, and loops.
- Bug found and fixed:
  `BUG-MD-0001` / ADR-0004. The random seed exposed a divide writeback mismatch
  at commit index 34; `core.v` now latches active M operation type and completed
  result before pipeline advance.
- Waveform:
  `wave.vcd` includes top-level commit, PC/instruction/state, memory interface,
  and M-unit decode context sufficient to review the observed class of failure.
- Limitation:
  deterministic bounded pseudo-random DV only; not Google RISC-V DV, not broad
  seed regression, and not coverage closure.

## Phase 3.6 Multi-Seed Random Lockstep and Coverage Evidence

- Gate:
  `tests/gates/gate_03_06_multi_seed_coverage.py`
- Evidence directory:
  `flow/v2_pipeline/phase_03_06_multi_seed_coverage`
- Command:
  `make -C flow/v2_pipeline/phase_03_06_multi_seed_coverage -B multi_seed_coverage.log`
- Result:
  `PASS: multi-seed lockstep matched 5 seeds / 405 commits; line coverage 79.12% (894/1130)`
- Seeds:
  `20260607`, `20260608`, `20260609`, `20260610`, `20260611`.
- Compared fields:
  commit `pc`, `instr`, destination `rd`, and writeback `wdata` for each seed.
- Coverage artifacts:
  per-seed `coverage.dat`, merged `coverage/merged_coverage.dat`,
  `coverage/coverage.info`, and annotated source under `coverage/annotated/`.
- Current coverage measurement:
  Verilator total coverage log reports 647 / 1130 coverage points = 57.00%;
  lcov `DA` line records report 894 / 1130 lines hit = 79.12%.
- Known high-level gaps from annotated coverage:
  external IRQ input, BP/RAS paths, CSR/trap paths, and several redirect paths
  are not exercised by this non-privileged random grammar.
- Limitation:
  this is not 100% line coverage closure. Phase 4.0 must either hit every
  uncovered line or list the reason, reachability, closure plan, owner/date, or
  waiver.

## Phase 3.7 Mul/Div Hazard Directed Lockstep Evidence

- Gate:
  `tests/gates/gate_03_07_muldiv_hazard.py`
- Evidence directory:
  `flow/v2_pipeline/phase_03_07_muldiv_hazard`
- Command:
  `make -C flow/v2_pipeline/phase_03_07_muldiv_hazard -B muldiv_hazard.log`
- Result:
  `PASS: muldiv hazard lockstep matched 45 commits`
- Covered behavior:
  back-to-back M operations, dependent ALU consumers, M-result store/load data,
  M-result address calculation, load-use around M-result consumers,
  divide-by-zero quotient/remainder, signed overflow quotient/remainder,
  unsigned divide/remainder, branch compare on M result, and compressed
  instructions after M stress.
- Comparator note:
  this phase uses DUT-aware Spike writeback normalization so literal data value
  `0x80000000` is not mistaken for a normalized PC-relative address.
- Waveform:
  `wave.vcd` is focused and includes top-level commit/memory/debug signals plus
  `md_started`, `md_active_is_div`, `md_result_valid`, `md_result_q`,
  `md_done`, `md_busy`, `ex_mem_md_result_r`, and `ex_wb_md_result_r`.
- Limitation:
  this is directed M-unit hazard regression only; it does not close all
  forwarding, branch, random DV, or coverage gaps.

## Phase 4.0 Coverage Residual Analysis Evidence

- Gate:
  `tests/gates/gate_04_00_coverage.py`
- Evidence directory:
  `flow/v2_pipeline/phase_04_00_coverage_residual`
- Command:
  `python3 flow/v2_pipeline/phase_04_00_coverage_residual/analyze_coverage.py`
- Result:
  `PASS: coverage residual analysis listed 236 DUT uncovered lines; DUT line coverage 77.61%; DUT toggle coverage 61.24%`
- Input coverage:
  `flow/v2_pipeline/phase_03_06_multi_seed_coverage/coverage/coverage.info`
  and `flow/v2_pipeline/phase_03_06_multi_seed_coverage/coverage/merged_coverage.dat`
- Line coverage:
  DUT-only 818 / 1054 = 77.61%; total including testbench 894 / 1130 =
  79.12%. Target remains 100% DUT line coverage or approved waivers/reasons for
  every miss.
- Toggle coverage:
  DUT-only 7500 / 12246 = 61.24%; target is >=85%, not closed.
- Functional coverage:
  not implemented; target is >=95%, coverplan and bins are required.
- Residual categories:
  `bp_ras_redirect` 59, `csr_irq_trap` 58, `directed_gap` 57,
  `rv32c_corner` 44, `m_extension_corner` 9, `reset_or_interface` 6,
  `hazard_forwarding` 3.
- Worst residual modules:
  `core.v` 73 uncovered, `csr.v` 48 uncovered, `cdec.v` 43 uncovered,
  `bp.v` 25 uncovered, `idu.v` 17 uncovered, `ras.v` 12 uncovered.
- Closure status:
  not closed. No uncovered line has an approved waiver yet; all waiver entries
  are `none`. Testbench coverage is tracked as supporting data only and is not
  included in the DUT coverage headline.

## Phase 4.1 CSR/IRQ Directed Coverage Delta Evidence

- Gate:
  `tests/gates/gate_04_01_csr_irq_coverage.py`
- Evidence directory:
  `flow/v2_pipeline/phase_04_01_csr_irq_coverage`
- Command:
  `make -C flow/v2_pipeline/phase_04_01_csr_irq_coverage -B csr_irq_coverage.log`
- Result:
  `PASS: CSR/IRQ directed coverage merged; DUT line 946/1054 (89.75%, +128); DUT toggle 7904/12246 (64.54%, +404)`
- Directed behavior checked:
  CSR write/set/clear on `mscratch`, unknown CSR read returns zero, `cycle` and
  `instret` counters are non-zero, external IRQ pulse sets `mip.MEIP` while
  global MIE is disabled, enabling global MIE takes the pending external IRQ,
  and the handler observes external interrupt `mcause`, trap-entry `mstatus`,
  and returns through `mret`.
- CSR module delta:
  line coverage improves from 43 / 91 = 47.25% to 86 / 91 = 94.51%; normalized
  toggle coverage improves from 208 / 1288 = 16.15% to 361 / 1288 = 28.03%.
- DUT coverage delta:
  line coverage improves from 818 / 1054 = 77.61% to 946 / 1054 = 89.75%;
  normalized toggle coverage improves from 7500 / 12246 = 61.24% to
  7904 / 12246 = 64.54%.
- Waveform:
  `wave.vcd` is focused (about 206 KB) and includes top-level instruction/data
  memory, MMIO evidence flags, CSR internals, `wb_take_irq`, `wb_is_mret`, and
  `wb_trap_pc_for_mepc`; full dump remains available with `+full_vcd`.
- Closure status:
  not closed. Remaining high-value buckets are BP/RAS loop/call-return,
  RV32C decode corners, M-unit coverage merge/corners, and functional cover
  bins.

## Phase 4.2 BP/RAS Directed Coverage Delta Evidence

- Gate:
  `tests/gates/gate_04_02_bp_ras_coverage.py`
- Evidence directory:
  `flow/v2_pipeline/phase_04_02_bp_ras_coverage`
- Command:
  `make -C flow/v2_pipeline/phase_04_02_bp_ras_coverage -B bp_ras_coverage.log`
- Result:
  `PASS: BP/RAS directed coverage merged; DUT line 991/1054 (94.02%, +45); DUT toggle 8082/12246 (66.00%, +178)`
- Directed behavior checked:
  backward branch loop trains taken history and exits not-taken, a second
  backward branch loop exercises another predictor entry, nested `jal ra` calls
  push multiple RAS entries, nested `ret` instructions pop the RAS, and MMIO
  markers prove loop exit, nested call bodies, return path, and second loop
  completion.
- Scope note:
  this test uses `.option norvc` to isolate BP/RAS coverage from RV32C halfword
  control-flow corner behavior. RV32C decode/cross-boundary control-flow
  coverage remains a separate closure bucket.
- BP/RAS module delta:
  `bp.v` line coverage improves from 51 / 59 = 86.44% to 59 / 59 = 100.00%;
  normalized toggle coverage improves from 217 / 872 = 24.89% to
  270 / 872 = 30.96%. `ras.v` line coverage improves from
  12 / 24 = 50.00% to 21 / 24 = 87.50%; normalized toggle coverage improves
  from 21 / 660 = 3.18% to 45 / 660 = 6.82%.
- DUT coverage delta:
  line coverage improves from 946 / 1054 = 89.75% to
  991 / 1054 = 94.02%; normalized toggle coverage improves from
  7904 / 12246 = 64.54% to 8082 / 12246 = 66.00%.
- Waveform:
  `wave.vcd` is focused (about 444 KB) and includes instruction/data memory,
  MMIO evidence flags, BP prediction/update signals, mispredict flags, RAS
  push/pop/top, and `u_ras.ptr`; full dump remains available with `+full_vcd`.
- Closure status:
  not closed. Remaining high-value buckets are RV32C decode corners, M-unit
  coverage merge/corners, residual CSR/RAS toggle closure, and functional cover
  bins.

## Phase 4.3 RV32C / Cross-Boundary Directed Coverage Delta Evidence

- Gate:
  `tests/gates/gate_04_03_rv32c_cross_coverage.py`
- Evidence directory:
  `flow/v2_pipeline/phase_04_03_rv32c_cross_coverage`
- Command:
  `make -C flow/v2_pipeline/phase_04_03_rv32c_cross_coverage -B rv32c_cross_coverage.log`
- Result:
  `PASS: RV32C/cross directed coverage merged; DUT line 1022/1054 (96.96%, +31); DUT toggle 8138/12246 (66.45%, +56)`
- Directed behavior checked:
  legal RV32C Q0/Q1/Q2 decode paths including stack-relative, compact-register
  load/store, arithmetic, branch, jump, call, and return forms; sequential
  low-half 16-bit followed by high-half 32-bit instruction; redirect to
  high-half 32-bit instruction; MMIO markers prove compressed-call return,
  RV32C sequence completion, cross fast path, and cross fallback path.
- Scope note:
  illegal compressed encodings are intentionally left out of this phase because
  they require trap/CSR semantic checks. They remain a separate closure item.
- RV32C/cross module delta:
  `cdec.v` line coverage improves from 72 / 106 = 67.92% to
  101 / 106 = 95.28%; normalized toggle coverage improves from
  364 / 434 = 83.87% to 370 / 434 = 85.25%. `core.v` line coverage improves
  from 417 / 422 = 98.82% to 418 / 422 = 99.05%; normalized toggle coverage
  improves from 3603 / 4878 = 73.86% to 3621 / 4878 = 74.23%.
- DUT coverage delta:
  line coverage improves from 991 / 1054 = 94.02% to
  1022 / 1054 = 96.96%; normalized toggle coverage improves from
  8082 / 12246 = 66.00% to 8138 / 12246 = 66.45%.
- Waveform:
  `wave.vcd` is focused (about 930 KB) and includes instruction/data memory,
  MMIO evidence flags, `upcoming_cross`, `at_cross_boundary`, `cross_assemble`,
  `residue`, `cinstr`, `cdec_expanded`, `cdec_illegal`, and
  `instr_assembled`; full dump remains available with `+full_vcd`.
- Closure status:
  not closed. Remaining high-value buckets are illegal compressed/trap
  coverage, M-unit coverage merge/corners, residual toggle closure, functional
  cover bins, and final uncovered-line waiver review.

## Phase 4.4 Illegal Compressed Trap + M-Unit Coverage Delta Evidence

- Gate:
  `tests/gates/gate_04_04_illegal_munit_coverage.py`
- Evidence directory:
  `flow/v2_pipeline/phase_04_04_illegal_munit_coverage`
- Command:
  `make -C flow/v2_pipeline/phase_04_04_illegal_munit_coverage -B illegal_munit_coverage.log`
- Result:
  `PASS: illegal compressed/M-unit coverage merged; DUT line 1035/1054 (98.20%, +13); DUT toggle 8235/12246 (67.25%, +97)`
- Directed behavior checked:
  M-unit signed/unsigned multiply variants, divide/remainder, divide-by-zero,
  signed overflow, legal `C.JALR`, and three illegal compressed encodings
  (`C.LUI rd=x0`, RV32-invalid `C.SLLI shamt[5]=1`, and Q2 default/RV64-only)
  propagating through `cdec_illegal` / WB illegal into terminal `trap`.
- Scope note:
  the active RTL's illegal instruction behavior is a simplified terminal trap
  path. This phase checks that model. It does not claim full illegal instruction
  CSR exception semantics (`mcause`, `mepc`, `mtvec`) because that behavior is
  not implemented for illegal instructions in this RTL.
- Illegal/M-unit module delta:
  `cdec.v` line coverage improves from 101 / 106 = 95.28% to
  106 / 106 = 100.00%. `div.v` line coverage improves from
  62 / 71 = 87.32% to 70 / 71 = 98.59%; normalized toggle coverage improves
  from 488 / 686 = 71.14% to 517 / 686 = 75.36%. `mul.v` normalized toggle
  coverage improves from 587 / 610 = 96.23% to 608 / 610 = 99.67%.
- DUT coverage delta:
  line coverage improves from 1022 / 1054 = 96.96% to
  1035 / 1054 = 98.20%; normalized toggle coverage improves from
  8138 / 12246 = 66.45% to 8235 / 12246 = 67.25%.
- Waveform:
  `wave.vcd` is focused (about 234 KB) and includes M-unit result-latch
  signals plus illegal compressed decode/pipe/trap signals; full dump remains
  available with `+full_vcd`.
- Closure status:
  not closed. Remaining work is residual line/toggle triage, functional cover
  bins, final waiver review, and lint/synth/FPGA PPA sign-off.

## Phase 4.5 Residual Coverage Triage Evidence

- Gate:
  `tests/gates/gate_04_05_residual_triage.py`
- Evidence directory:
  `flow/v2_pipeline/phase_04_05_residual_triage`
- Command:
  `python3 flow/v2_pipeline/phase_04_05_residual_triage/analyze_residual.py`
- Result:
  `PASS: residual triage generated; DUT line 1035/1054 (98.20%); DUT toggle 8235/12246 (67.25%); residual_lines=19`
- Residual summary:
  19 DUT uncovered lines remain. Category counts are `ras_mispredict_recovery`
  4, `ras_push_edge` 3, `csr_high_counters` 2,
  `csr_explicit_write_mepc_mcause` 2, `branch_unsigned_and_default` 2,
  `decode_default_alu_op` 2, plus one each for `alu_default`,
  `csr_write_default`, `div_fsm_default`, and `fence_decode`.
- Waiver status:
  14 residuals have waiver=`none`; 5 are only `waiver-candidate`. No waiver is
  approved by this phase.
- Next closure actions:
  add directed RAS mispredict and RAS pointer-edge tests; add CSR high-counter,
  explicit `mepc`/`mcause`, and unsupported CSR write tests or waivers; add
  FENCE/FENCE.I and unsigned branch decode tests; add SVA/FSM assertion or
  waiver for defensive default states; build functional coverage bins.
- Closure status:
  not closed. This phase explains why line coverage is not 100%; it does not
  approve waivers or qualify the CPU IP.

## Phase 4.6 RAS Recovery + Pointer Edge Coverage Delta Evidence

- Gate:
  `tests/gates/gate_04_06_ras_recovery_coverage.py`
- Evidence directory:
  `flow/v2_pipeline/phase_04_06_ras_recovery_coverage`
- Command:
  `make -C flow/v2_pipeline/phase_04_06_ras_recovery_coverage -B ras_recovery_coverage.log`
- Result:
  `PASS: RAS recovery coverage merged; DUT line 1042/1054 (98.86%, +7); DUT toggle 8296/12246 (67.74%, +61)`
- Behavior evidence:
  simulation observed `mem_ras_mispredict pred=00000010 actual=00000020`,
  RAS recovery redirect to `00000020`, and actual-return marker
  `mmio[00000000] <= 00000406`. The wrong-path predicted-return marker is a
  fatal check and did not commit.
- Coverage delta:
  `core.v` line coverage improved from 418 / 422 to 422 / 422; `ras.v` line
  coverage improved from 21 / 24 to 24 / 24.
- VCD policy:
  focused review VCD is 114 KB and includes RAS prediction/recovery and direct
  RAS pointer-edge signals; full dump remains available with `+full_vcd`.
- Claude Code review:
  `advisory-pass-with-caveats`; see
  `flow/v2_pipeline/phase_04_06_ras_recovery_coverage/claude_review.md`.
  The corrected headless invocation used a one-shot session, stdin prompt,
  JSON output, explicit Magpie_M1 cwd/add-dir, and read-only tool allow list.
  Claude verified the Phase 4.6 evidence and agreed with `coverage-delta-pass`,
  not sign-off.
- Closure status:
  not closed. Remaining coverage work includes CSR high-counter/write paths,
  FENCE/FENCE.I, unsigned branch/default decode triage, defensive default
  assertions/waivers, and functional cover bins.

## Phase 4.7 CSR/IDU Residual Coverage Delta Evidence

- Gate:
  `tests/gates/gate_04_07_csr_idu_residual_coverage.py`
- Evidence directory:
  `flow/v2_pipeline/phase_04_07_csr_idu_residual_coverage`
- Command:
  `make -C flow/v2_pipeline/phase_04_07_csr_idu_residual_coverage -B csr_idu_residual_coverage.log`
- Result:
  `PASS: CSR/IDU residual coverage merged; DUT line 1051/1055 (99.62%, +9); DUT toggle 8306/12250 (67.80%, +10); csr=91/91 (100.00%); idu=90/92 (97.83%)`
- Behavior evidence:
  direct CSR stimulus reads `cycleh` and `instreth`, explicitly writes and
  reads back `mepc` and `mcause`, and writes unsupported CSR `0x7c1` to confirm
  the default write path ignores it. Direct IDU stimulus decodes `FENCE`,
  `FENCE.I`, `BLTU`, `BGEU`, and reserved branch funct3 `011` to hit the
  branch default compare arm while confirming the reserved encoding asserts
  `illegal=1`.
- Coverage delta:
  `csr.v` line coverage improved from 86 / 91 to 91 / 91; `idu.v` line coverage
  improved from 86 / 92 to 90 / 92. DUT line coverage improved from
  1042 / 1054 = 98.86% to 1051 / 1055 = 99.62%.
- Claude Code review:
  completed with JSON success. Claude verified the coverage evidence and found
  one low-severity RTL correctness issue: reserved BRANCH funct3 encodings were
  treated as legal. `idu.v` now qualifies branch legality with
  `branch_funct3_valid`; `BUG-IDU-0001` records the finding and fix. See
  `flow/v2_pipeline/phase_04_07_csr_idu_residual_coverage/claude_review.md`.
- VCD policy:
  focused review VCD includes CSR register/counter state and IDU branch decode
  outputs; full dump remains available with `+full_vcd`.
- Closure status:
  not closed. Remaining line residuals are defensive defaults in `alu.v`,
  `div.v`, and selected decode default arms, plus toggle and functional coverage
  targets. These need assertion/waiver review and functional cover bins rather
  than more architectural directed tests.
