# ADR-0001 — Magpie_M1 CPU IP: ISA scope + microarchitecture

- Status: **superseded-for-implementation**
- Date: 2026-06-07
- Deciders: user + Codex, based on Claude Code recommendation review
- Superseded by: ADR-0002 for the active Magpie_M1 implementation baseline

## Context

Update 2026-06-07: this ADR remains as the historical greenfield bring-up
decision, but it no longer defines the active Magpie_M1 implementation target.
The active productization line is ADR-0002: Ch2 `lab08e`
`RV32IMC_Zicsr_Zifencei` 4-stage pipeline + BP + RAS + pre-fetch.

Magpie_M1 is a greenfield CPU IP, developed IP-first to exercise and harden the
AI Design IDE's **CPU IP development flow** (see `../../CLAUDE.md` §2 and
`~/project/doc/ip_flow_plan_of_record.md`). This is flow **stage 1 (isa_scope)** — the first gate.
Nothing downstream (RTL, DV, cosim) should start before this is decided and recorded here.

Reference policy: use the RISC-V specs as the architecture contract, and legally reference
prior internal work, Claude Code experiments, and open-source CPUs/tools to avoid repeating
known design and DV mistakes. When reference material shapes a decision or implementation,
record the source/provenance, license constraints, and Magpie_M1-specific verification evidence.

## Decision

1. **v1 ISA subset**: `RV32IM_Zicsr`, M-mode only.
2. **Roadmap extensions**: `C` and `A` are deferred. Each requires an independent
   ADR, dedicated stage/gate plan, directed tests, Google RISC-V DV constraints,
   Spike comparison policy, and coverage closure.
3. **Microarchitecture**: v1 is an in-order **multi-cycle FSM** core. It has no
   pipeline stages. Pipeline hazards, forwarding, flush priority, and wrong-path
   suppression are not applicable to v1. Introducing a pipelined
   microarchitecture requires a later ADR and additional gates.
4. **Memory interfaces**: standalone `imem` and `dmem` simple `valid/ready`
   manager interfaces. AXI4-Lite/AXI4/TileLink adapters are later integration
   work and are not part of CPU IP v1 sign-off.
5. **Privilege / traps**: selected M-mode CSR/trap subset sufficient for Zicsr,
   illegal instruction, `ecall`, `ebreak`, and `mret` directed tests. External
   interrupt timing is a stretch item unless explicitly accepted by a later ADR.
6. **Verification authority**: per-commit lockstep/reference comparison against
   Spike with directed tests and random programs; pytest gates record objective
   evidence for every scope-derived development stage.
7. **Reference policy**: legal reference material may be used to avoid known
   mistakes, but source/provenance and license constraints must be recorded when
   they shape design. Magpie_M1 qualification still requires Magpie_M1-owned
   logs, traces, coverage, and gate evidence.

## Consequences

- Historical greenfield FSM contract only; it is not the current product RTL
  sign-off target.
- The development-stage list is derived from this ADR's ISA scope and
  microarchitecture. It is not a fixed sacred count.
- The FSM path may still be useful as a learning/reference note, but it is not
  pursued as a parallel sign-off baseline.
- ADR-0002 supersedes this ADR for implementation scope, gate plan, evidence,
  and sign-off reporting.

## References

- RISC-V Unprivileged ISA Spec; RISC-V Privileged Spec (the architecture contract).
- Prior internal CPU labs, Claude Code CPU experiments, and open-source RISC-V CPUs/tools
  may be used as legal references with provenance and license notes.
- `~/project/doc/ip_flow_plan_of_record.md` — CPU flow definition.
