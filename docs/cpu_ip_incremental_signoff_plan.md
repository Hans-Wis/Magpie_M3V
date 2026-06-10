# CPU IP Incremental RTL Sign-off Plan Template

Date: 2026-06-07

This is the reusable CPU IP development template for Magpie_M1 and later RISC-V
CPU IP projects. Development stages are phase gates derived from the active
ADR/spec scope. They are independent from microarchitecture pipeline stages.
The current active gate list is derived from ADR-0002: Ch2 `lab08e`
`RV32IMC_Zicsr_Zifencei` 4-stage pipeline + BP + RAS + RV32C + pre-fetch.

## Claude Code Recommendation Review

Verdict: mostly reasonable and adopted with one policy adjustment.

- Adopt Option 1 revised: `ADR-0001` FSM implementation is superseded and
  `ADR-0002` lab08e is the single active productization line.
- Adopt: active scope is `RV32IMC_Zicsr_Zifencei`, M-mode, lab08e 4-stage
  pipeline with BP/RAS/RV32C/pre-fetch.
- Adopt: defer `A` into an independent roadmap item with its own ADR, gates,
  Google RISC-V DV constraints, Spike comparison policy, and coverage.
- Adopt with clarification: use `CLAUDE.md` section 2 as the reference shape for
  scope-derived development gates, not as a fixed sacred count.
- Adopt: make `gate_00_spec` check engineering facts: accepted ADR, no TBD in
  spec, ISA/interface consistency with `ip.json`.
- Adopt: use `platform/design-ide/server.py` terminology. Do not make gates
  depend on old `rview` branding.
- Adopt: split sign-off into active lab08e must-have and stretch/roadmap scope.
- Adjust: references are not limited to flow/DV harness patterns. Legal internal
  and open-source references may inform RTL/DV decisions, but provenance,
  license constraints, and Magpie_M1-specific verification evidence must be
  recorded. Direct third-party RTL inclusion requires explicit license review
  and ADR/waiver.

## Active Scope

Must-have active target:

- ISA: `RV32IMC_Zicsr_Zifencei`
- Privilege: M-mode only
- Microarchitecture: Ch2 lab08e 4-stage pipeline + BP + RAS + RV32C + pre-fetch
- Interfaces: Magpie_M1 `imem` and `dmem` valid-ready via wrapper or active protocol ADR
- Correctness authority: directed tests plus Spike lockstep/reference compare
- Required tooling: Verilator sim, code coverage, smoke/gate tests,
  Python/pytest checks, lint/PPA, full verification report

Roadmap/stretch:

- `A` extension
- riscv-arch-test compatibility pack
- riscv-formal selected checks
- CoreMark/Dhrystone benchmark correctness
- FPGA bring-up and FPGA-based PPA
- ASIC PPA

## Scope-Derived Development Gate List

The following list is the active lab08e development flow. It may change when ISA
scope or microarchitecture changes by ADR.

| # | Development gate | Incremental RTL/function scope | Required evidence | Gate |
|---:|---|---|---|---|
| 0 | `isa_scope` | ADR/spec/ip.json contract for active lab08e `RV32IMC_Zicsr_Zifencei` scope | ADR-0002 accepted, ADR-0001 superseded, spec no TBD, ip.json consistent | `gate_00_spec.py` |
| 1.0 | `pipeline_reference` | lab08e RTL copied, filelist/provenance recorded, lint-only parses | Verilator lint-only, provenance, full verification report shell | `gate_10_pipeline_v2_reference.py` |
| 1.1 | `fetch_rv32c_prefetch` | PC +2/+4, compressed fetch, pre-fetch residue, cross-boundary fallback | directed RV32C/pre-fetch tests, VCD, coverage | `gate_01_01_fetch_rv32c_prefetch.py` |
| 1.2 | `decode_execute_rv32imc` | RV32I/M/C decode, ALU, regfile, M unit/corners, illegal encodings | directed ISA tests, code coverage, Python commit checker | `gate_01_02_decode_execute_rv32imc.py` |
| 1.3 | `pipeline_hazard` | forwarding, load-use stall, mul/div busy stall, wrong-path suppression | hazard directed tests, assertions, VCD | `gate_01_03_pipeline_hazard.py` |
| 1.4 | `bp_ras_redirect` | BP update, RAS push/pop, branch/jump/JALR redirect priority | predictor/redirect tests, assertions, VCD | `gate_01_04_bp_ras_redirect.py` |
| 1.99 | `phase1_closure` | close lab08e structural bring-up; transfer directed/coverage/Spike residuals to later phases | Phase 1 closure report, state/action consistency, no qualification overclaim | `gate_01_99_phase1_closure.py` |
| 2.0 | `trap_interrupt` | Zicsr, selected M-mode traps, IRQ timing, 16-bit mepc behavior | CSR/trap/IRQ directed tests, Spike/reference compare | `gate_02_00_trap_interrupt.py` |
| 2.1 | `mem_wrapper` | Magpie_M1 valid-ready wrapper, load/store widths, byte lanes, misalign policy | memory scoreboard, wrapper tests, coverage residual | `gate_02_01_mem_wrapper.py` |
| 3.0 | `spike_lockstep` | RV32IMC per-commit trace and reference comparison | Spike first-fail report, Google RISC-V DV smoke seeds when stable | `gate_03_00_spike_lockstep.py` |
| 4.0 | `coverage` | line/toggle/functional coverage closure | line 100% or uncovered-line reason list; toggle/function target or waiver | `gate_04_00_coverage.py` |
| 5.0 | `lint_synth_ppa_signoff` | RTL quality, lint, synthesis/FPGA PPA handoff | no unwaived high/critical lint; PPA reports; full verification report | `gate_05_00_lint.py`, `gate_05_01_synth_ppa.py` |

## Required Evidence Per Stage

Every development gate must produce or explicitly mark not-applicable:

- Verilator lint and simulation log.
- Verilator code coverage report.
- Smoke test result.
- Gate test result.
- Python/pytest result for parsers, state JSON, scoreboards, and policy checks.
- Short VCD excerpt when simulation behavior is relevant.
- `flow/state/*.state.json` with `design_id=cpu_m1`.
- Residual risk/waiver notes.

Coverage rule:

- Line coverage target is 100%.
- If line coverage is below 100%, list every uncovered line/item, reason,
  reachability, closure plan or waiver.
- Toggle target is >= 85%, unless waived.
- Functional target is >= 95%, unless waived.

DV rule:

- Directed tests close intent first.
- Spike is the instruction-level reference for lockstep or first-fail triage.
- Google RISC-V DV (`google/riscv-dv`) is used for constrained random after the
  deterministic directed path is stable.
- DV seeds, constraints, generated programs, Spike mismatch reports, and rerun
  commands must be archived.

## Must-Have vs Stretch Sign-off

| Category | Must-have v1 | Stretch / roadmap |
|---|---|---|
| ISA | RV32I, RV32M, Zicsr | C, A |
| Privilege | selected M-mode CSR/trap | full interrupt/timer/platform closure |
| DV | directed tests, Spike lockstep/reference compare, Google RISC-V DV smoke-to-signoff ladder for supported ISA | full architecture compatibility sweep |
| Coverage | line 100% or documented uncovered reasons; toggle/function target or waiver | assertion/formal coverage dashboard |
| Quality | Verilator lint, Spyglass or equivalent lint with no unwaived high/critical issue | CDC/reset methodology pack |
| Performance | CPI/commit trace sanity | CoreMark/Dhrystone |
| Implementation | RTL sign-off package | FPGA bring-up, FPGA-based PPA, ASIC PPA |

## Optional FPGA / PPA Evaluation

FPGA/PPA is an evaluation track, not a substitute for functional sign-off.

Required if enabled:

- FPGA part/board, constraints, clock target, synthesis options, and memory
  inference policy.
- Timing report: WNS/TNS and estimated Fmax.
- Utilization report: LUT, FF, BRAM, DSP, clocking resources.
- Optional power report, or a documented not-run reason.
- Regression delta versus previous baseline.
- Board smoke evidence if bitstream is generated.

Preferred artifact paths:

- `flow/fpga/<run>/synth.log`
- `flow/fpga/<run>/timing.rpt`
- `flow/fpga/<run>/utilization.rpt`
- `flow/ppa/fpga_ppa.md`

## Appendix A — Architecture Subtask Mapping

The earlier P0-P15 breakdown is now a subtask/backlog mapping onto the
scope-derived development gates.

| Old subtask | Status in optimized plan | Development gate |
|---|---|---|
| P0 Spec/contract | kept as stage 1 content | `isa_scope` |
| P1 Fetch baseline | kept | `fetch` |
| P2 RV32I decode/ALU | kept | `decode_execute` |
| P3 Branch/jump/control | kept as FSM redirect subtask; no pipeline flush | `core_assembly` |
| P4 Load/store | kept | `mem_integration` |
| P5 RV32M | kept | `decode_execute` |
| P6 CSR/trap/IRQ | narrowed to selected M-mode CSR/trap | `trap_interrupt` |
| P7 RVC | roadmap, independent ADR/gates | backlog |
| P8 RV32A | roadmap, independent ADR/gates | backlog |
| P9 Pipeline closure | not-applicable to multi-cycle FSM v1; requires future pipeline ADR | backlog |
| P10 Arch compatibility | stretch | backlog |
| P11 Random DV | kept as Google RISC-V DV + Spike within cosim | `spike_lockstep` |
| P12 Formal | stretch | backlog |
| P13 RTL sign-off pack | kept as final packaging | `lint_synth_signoff` |
| P14 FPGA bring-up | optional evaluation | backlog |
| P15 FPGA-based PPA | optional evaluation | backlog |

## Sign-off Checklist

- [ ] `ADR-0001` is accepted.
- [ ] `IP/cpu_m1/docs/spec.md` has no TBD.
- [ ] `IP/cpu_m1/ip.json` interfaces and risks match the spec.
- [ ] All scope-derived development gates are present or explicitly not-applicable.
- [ ] Must-have RV32IM_Zicsr directed tests pass.
- [ ] Spike lockstep/reference comparison is archived for supported tests.
- [ ] Google RISC-V DV seeds are constrained to implemented v1 ISA and
      reproducible.
- [ ] Verilator simulation logs and VCD excerpts are archived.
- [ ] Line coverage is 100%, or every uncovered line has reason, reachability,
      closure plan or waiver.
- [ ] Toggle/functional coverage meets target or has approved waiver.
- [ ] No unwaived high/critical lint issue remains.
- [ ] AI Design IDE can display RTL hierarchy, gate matrix, logs, VCD, coverage
      report, and handoff report.
- [ ] Stretch items are not used to block v1 unless explicitly promoted by ADR.
