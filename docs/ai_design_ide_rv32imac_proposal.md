# Magpie_M1 Legacy RV32IM_Zicsr Proposal - Superseded

Date: 2026-06-06

This proposal is retained as historical context. It has been superseded for
implementation by ADR-0002, which promotes Ch2 `lab08e`
`RV32IMC_Zicsr_Zifencei` 4-stage pipeline + BP + RAS + RV32C + pre-fetch as the
active Magpie_M1 productization line.

Customer HTML version:

- `docs/ai_design_ide_rv32imac_proposal.html`

Claude-provided reference artifacts reviewed and folded into this plan:

- `docs/rv32_proposal.html` - visual proposal with closed-loop IDE flow,
  in-order datapath diagram, gate matrix, coverage chart, and interactive
  customer checklist.
- `docs/RV32_report.pdf` - verification report for a separate
  `claude-rv32` RV32IMC_Zicsr design. It is used as an evidence-pack template,
  not as Magpie_M1 pass evidence.

## Goal

Build Magpie_M1 as a greenfield CPU IP flow example that reuses proven engineering lessons instead of rediscovering known CPU design and DV pitfalls:

- v1 ISA target: `RV32IM_Zicsr`, M-mode only.
- Roadmap: `C` and `A` are independent future stages with their own ADRs.
- Evidence model: every stage records spec, RTL, logs, VCD, coverage, DV result, risk, and waiver.
- Review model: AI Design IDE shows RTL, block diagram, simulation artifacts, waveform, PM rollup, and gate matrix.
- Sign-off rule: a stage is not called qualified until its gate evidence exists and is reviewed.

## Reference Baseline

The flow references `~/project/lab/CPU/Ch2`, prior Claude Code CPU work, and relevant open-source RISC-V projects for proven architecture, RTL, and DV patterns:

- DV_TRACE / RVFI-lite commit trace.
- Directed ISA bring-up.
- Spike ISS lockstep/reference compare.
- Google RISC-V DV (`google/riscv-dv`) constrained random.
- Exception / CSR / interrupt closure.
- Coverage and sign-off report.

Reference use is allowed when it is legally compatible with Magpie_M1. Decisions and implementation choices influenced by references should record provenance, license constraints where applicable, and the Magpie_M1 evidence that proves the behavior.

Claude's `RV32_report.pdf` adds several sign-off practices that should be
adopted for Magpie_M1:

- Add `riscv-arch-test` as a separate architecture-compatibility gate before
  large random DV. Track RV32I/M/C and machine-mode CSR/trap groups separately.
- Make the commit trace/RVFI-lite stream the shared observation point for
  directed tests, Spike lockstep, coverage triage, and formal.
- Add self-checking benchmark programs as correctness tests, not just
  performance demos. CoreMark CRC is useful because it can expose memory-system
  bugs missed by arch tests.
- Add a bug taxonomy table to every sign-off report: bug, found-by layer, fix,
  and regression gate. This shows why layered DV is valuable.
- Add Coverage residual analysis. Line coverage target is 100%; if line coverage
  is below 100%, the report must list every uncovered item with reason,
  reachability, closure plan or waiver. For other coverage metrics below their
  headline target, separate reachable gaps from structural or environment-limited
  gaps and link waivers.
- Add a formal plan using `riscv-formal` on RVFI. Initial target: RV32I/M/C
  instruction checks, register consistency, PC progression, unique retire, and
  selected CSR checks. Trap CSR, counters, and bus/fault checks can be planned
  as later formal scope.
- Add FPGA-based PPA evaluation after RTL behavior is stable. Use FPGA
  utilization, post-route timing/Fmax, and optional power reports as the first
  implementation PPA proxy; keep these results separate from functional sign-off.

The report's measured numbers, such as 82.8% total coverage and 78/78 formal
checks, belong to the referenced `claude-rv32` design only. Magpie_M1 must
generate its own logs, VCDs, coverage database, and state records.

## Scope-Derived Development Gate List

Magpie_M1 derives its development gate list from ADR-0001 ISA scope and the
selected microarchitecture. `CLAUDE.md` section 2 is the current v1 reference
shape, not a fixed-count rule. These development gates are phase gates, not
microarchitecture pipeline stages.

| Gate # | Development gate | Purpose | Primary evidence |
|---:|---|---|---|
| 1 | isa_scope | accepted ADR/spec/ip.json for RV32IM_Zicsr, M-mode, valid-ready memory | `gate_00_spec.py` |
| 2 | fetch | PC, reset, imem valid-ready | Verilator log, VCD |
| 3 | decode_execute | RV32I/M decode, ALU, regfile, M corners | directed tests |
| 4 | core_assembly | multi-cycle FSM core, commit trace, branch/jump redirect | assertions, waveform |
| 5 | trap_interrupt | Zicsr and selected M-mode trap behavior | directed + ISS compare |
| 6 | mem_integration | dmem valid-ready, load/store byte lanes, misalign policy | memory scoreboard |
| 7 | spike_lockstep | Spike per-commit/reference compare, Google RISC-V DV seeds when stable | seed archive, Spike mismatch report |
| 8 | coverage | line/toggle/functional coverage closure | coverage report |
| 9 | lint_synth_signoff | lint, optional synthesis/PPA handoff | lint report, optional PPA |

## Appendix: Architecture Subtask Mapping

The following rows refine what each development gate must eventually cover. They
are not separate top-level stage numbers.

| Subtask | Architecture scope | Development gate | Gate criterion |
|---:|---|---|---|
| A0 | Spec/contract | isa_scope | ADR/spec/ip.json complete; unsupported behavior explicit |
| A1 | Fetch baseline | fetch | reset/sequential PC/imem handshake PASS |
| A2 | RV32I decode/ALU | decode_execute | directed RV32I PASS; x0 invariant |
| A3 | Branch/jump/control | core_assembly | FSM redirect correct; no pipeline flush |
| A4 | Load/store | mem_integration | memory side effects match commit trace |
| A5 | RV32M | decode_execute | M corner tests and Spike compare PASS |
| A6 | CSR/trap | trap_interrupt | selected M-mode CSR/trap state matches contract |
| R1 | RVC | roadmap | independent ADR/gate required |
| R2 | RV32A | roadmap | independent ADR/gate required |
| S1 | Arch compatibility | stretch | supported groups PASS or exclusions named |
| S2 | Formal | stretch | selected checks PASS or unsupported scope documented |
| S3 | FPGA/PPA | stretch | FPGA PPA report reviewed; regressions explained |

## Spyglass and DV Partitioning

Spyglass lint should be run in two layers:

- Phase-local lint: run when a new architectural block lands, such as decoder,
  LSU, CSR, or future pipeline/RVC/atomic units. This catches
  structural issues close to the change and lets waivers cite the exact phase.
- Full-IP lint: run at the lint_synth_signoff gate on the integrated CPU. This is the sign-off
  report used for customer handoff.

DV must be partitioned by RV32 architecture phase. A global Google RISC-V DV run
alone is not enough, because it can hide gaps in CSR, RVC, atomic, trap, or
future pipeline corner behavior. Each phase needs directed tests first, then
phase-specific Google RISC-V DV constraints where applicable, then integrated
random after the feature is closed. Spike is the reference for per-commit
lockstep or first-fail triage.

Spyglass waivers should reference DV evidence when possible. For example, a
case statement default waiver for an illegal decode path should link to illegal
instruction tests. Future RVC/atomic waivers must link to the corresponding
unsupported encoding or memory-model matrix. Lint is structural, DV is
behavioral; the sign-off report should show both.

## Evidence Pack Additions from Claude RV32 Report

Magpie_M1's final customer pack should include these report sections:

| Evidence section | Why it matters | Magpie_M1 artifact |
|---|---|---|
| Architecture compatibility | Standard ISA agreement, separated from local directed tests | `flow/arch-test/*.log`, `gate_08_archtest.py` |
| Spike lockstep | Finds the exact retiring instruction where DUT diverges | `flow/sim/*lockstep*.log`, commit trace |
| Directed/self-check tests | Fast debug for each architecture phase | `IP/cpu_m1/dv/tests/*`, phase logs |
| Google RISC-V DV random | Reaches states directed tests usually miss | `dv/riscv-dv/out`, seed archive |
| Benchmark correctness | CoreMark CRC/Dhrystone sanity as long-running software tests | `flow/bench/coremark.log`, `flow/bench/dhrystone.log` |
| Coverage residual analysis | Measure, find lowest module, add directed test, remeasure, then list every uncovered line below 100% with reason, reachability, closure plan or waiver; separate other reachable gaps from structural/environment-limited gaps | `flow/coverage/dashboard.html`, waiver table |
| Formal | Stimulus-independent bounded ISA checks over RVFI-lite | `flow/formal/*.log`, `formal/README.md` |
| Bug taxonomy | Shows value of each DV layer and prevents regressions | `docs/bug_taxonomy.md` |
| Reproduction commands | Lets customer rerun any result | `scripts/run_regression.sh`, per-gate commands |
| FPGA-based PPA | Gives implementation area/performance proxy before ASIC PPA | `flow/ppa/fpga_ppa.md`, `flow/fpga/*/timing.rpt`, `utilization.rpt` |

## AI Design IDE Integration

Recommended setup:

```sh
python3 ~/project/platform/design-ide/server.py --port 8810 --bind 127.0.0.1
```

The IDE reads these Magpie_M1 artifacts:

- `tests/gates/gate_*.py` for the gate matrix.
- `flow/state/*.state.json` for stage state.
- `flow/sim/**/*.log` and `flow/sim/**/*.vcd` for sim and waveform.
- `IP/cpu_m1/rtl` for RTL/module review.
- `docs/*.md` and generated reports for customer review.

## Must-Have v1 Sign-off Checklist

- [ ] ISA support matrix lists RV32I, M, Zicsr support and C/A exclusions.
- [ ] ADR-0001 is accepted; C and A are roadmap items with future ADRs.
- [ ] Verilator lint and sim regressions are one-command reproducible.
- [ ] Directed ISA groups pass with archived logs and commit traces.
- [ ] Spike per-commit lockstep reports first mismatch with PC/instruction/state.
- [ ] Google RISC-V DV random seeds are constrained to implemented ISA and reproducible.
- [ ] CSR/trap tests cover selected M-mode entry, mret, illegal access, and timing corners.
- [ ] Pipeline hazard/forwarding/flush/wrong-path suppression is marked not-applicable for v1 multi-cycle FSM; future pipeline work has its own ADR/gates.
- [ ] Line coverage is 100%, or every uncovered line has a documented reason,
      reachability assessment, closure plan or approved waiver.
- [ ] Functional and toggle coverage meet targets or have approved waivers.
- [ ] Spyglass has no unwaived high/critical issues.
- [ ] Final handoff pack includes spec, RTL, DV, coverage, waiver, and re-run commands.

## Stretch / Roadmap Checklist

- [ ] `riscv-arch-test` supported groups pass or have scoped exclusions.
- [ ] `riscv-formal` RVFI checks pass for selected formal scope.
- [ ] CoreMark/Dhrystone or equivalent long-running software tests self-check.
- [ ] A-extension atomic tests and memory side-effect scoreboard pass.
- [ ] C-extension fetch/decode/PC update tests pass.
- [ ] FPGA-based PPA evaluation reports LUT/FF/BRAM/DSP, timing/Fmax, optional
      power, and regression deltas if the FPGA/PPA option is enabled.
- [ ] Each phase has a compact VCD review excerpt showing the behavior that
      closed the gate.
- [ ] Spyglass waivers cite the related phase, design intent, and DV evidence
      when the warning is tied to reachable architecture behavior.

## Coverage Targets

| Metric | Initial target |
|---|---:|
| Line coverage | 100%; if below 100%, list uncovered-line reasons |
| Toggle coverage | >= 85% |
| Functional coverage | >= 95% |
| Spyglass high/critical unwaived issues | 0 |
| Formal selected RVFI checks | 100% pass |
| Architecture compatibility tests | 100% supported groups pass |
| Sign-off Google RISC-V DV mixed tests | 10,000+ |
| FPGA-based PPA evaluation | LUT/FF/BRAM/DSP + timing/Fmax; optional power |
