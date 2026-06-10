# cpu_m1 — CPU IP spec

This is the active `isa_scope` contract for `design_id=cpu_m1`.
See `../../../docs/adr/0002-pipeline-v2-ch2-integration.md`. ADR-0001 is kept
as historical greenfield FSM context and is superseded for implementation.

Terminology:

- Development stage: a phase-gate step in the CPU IP development flow.
- Pipeline stage: a microarchitecture pipeline depth concept such as IF/ID/EX.
- Active implementation uses the Ch2 `lab08e` 4-stage pipeline.

## ISA scope
- Active ISA subset: RV32IMC_Zicsr_Zifencei
- XLEN: 32
- Privilege: M-mode only
- Deferred roadmap extensions: A
- Deferred stretch items: riscv-arch-test sign-off, riscv-formal,
  CoreMark/Dhrystone, ASIC PPA

## Microarchitecture
- Active microarchitecture: Ch2 `lab08e` derived 4-stage pipeline.
- Features: BP, RAS, RV32C compressed decoder, pre-fetch residue buffer,
  forwarding, hazard/stall, flush/redirect, CSR, IRQ.
- Historical FSM baseline: superseded by ADR-0002 and not a sign-off track.

## Interfaces (see ADR-0005)
Top = `cpu_m1_top` (wraps `core`). Harvard, single-outstanding, ready-gated
valid/ready. The bare `core` keeps its fixed-latency ports plus one new global
`mem_stall` input asserted by the wrapper while a request is outstanding-not-ready.

- I-bus (read-only): `ibus_req` (out), `ibus_addr[31:0]` (out);
  `ibus_ready` (in), `ibus_rdata[31:0]` (in). `req` held until `req & ready`;
  `rdata` sampled that cycle. Wait state = `ready` low N cycles.
- D-bus: `dbus_req` (out), `dbus_addr[31:0]`, `dbus_we` (out, = `|wstrb`),
  `dbus_wstrb[3:0]`, `dbus_wdata[31:0]` (out); `dbus_ready` (in),
  `dbus_rdata[31:0]` (in). Same ready-gated single-outstanding semantics.
- Misalign: precise trap (mcause 4 load / 6 store, mtval = addr). Spike runs
  misaligned-trap for lockstep equivalence.
- Byte lanes: write enables from `dbus_wstrb`; load sign/zero-ext stays in lsu.
- Regression-safety: `ready` tied high (0 wait) ⇒ behaviour identical to bare core.
- SoC/fabric (AXI) adapters: out of v1 CPU IP scope.

## Verification contract
- Development gate list is derived from ADR-0002 scope and microarchitecture.
- Directed smoke/gate tests for every implemented development stage.
- Per-commit lockstep or first-fail reference comparison vs Spike.
- Google RISC-V DV is used after the deterministic directed path is stable.
- Verilator simulation and line/toggle coverage evidence are required.
- Line coverage target is 100%; every uncovered line needs reason,
  reachability, closure plan or waiver.
- design_id = cpu_m1 on all artifacts.

## Must-have sign-off
- ADR-0002 accepted and this spec has no undecided fields.
- RV32IMC_Zicsr_Zifencei directed tests pass.
- RV32C/pre-fetch/RAS/BP/pipeline hazard tests pass.
- Spike comparison passes for supported directed/random programs.
- Verilator simulation and coverage gates pass.
- Spyglass or equivalent lint has no unwaived high/critical issue.
- Complete verification report:
  `docs/v2_pipeline_full_verification_report.md`.

## Stretch / roadmap
- RV32A support.
- riscv-arch-test supported group sign-off.
- riscv-formal selected checks.
- CoreMark/Dhrystone software tests.
- FPGA bring-up and FPGA-based PPA report.

## Pipeline integration
- Target source: `~/project/lab/CPU/Ch2/lab08e`.
- Local target RTL: `IP/cpu_m1/rtl`.
- Status: active implementation target, not yet qualified.
- Expected scope: RV32IMC_Zicsr_Zifencei 4-stage pipeline with BP, RAS and
  pre-fetch residue buffer.
- Required before qualification: valid-ready wrapper, pipeline directed tests,
  RV32C/pre-fetch/RAS/BP tests, Spike lockstep, coverage closure,
  lint/synth/PPA evidence.
- Complete verification report:
  `docs/v2_pipeline_full_verification_report.md`. Copied Ch2 logs or reports
  are references only; Magpie_M1 qualification requires Magpie_M1-owned logs,
  VCDs, coverage, lint/PPA, waivers, and rerun commands.

## References
- RISC-V Unprivileged ISA specification.
- RISC-V Privileged Architecture specification.
- Prior internal CPU labs, Claude Code results, and legal open-source references
  may inform design/DV decisions with provenance and license notes.
