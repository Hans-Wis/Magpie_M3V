# ADR-0012 — MVP IRQ scope freeze + two-SKU commercial cut

- Status: Accepted (2026-06-09)
- Deciders: User (fork decision), Claude Code (PL), with Grok/Codex/Gemini 4-agent review
- Refs: docs/reports/dv_roadmap/commercialization_decision.md, acceptance_spec_B.md,
  passes_riscv_dv_campaign.md; supersedes-scope-of none (refines ADR-0001 ISA scope for productization)

## Context

Magpie_M1 (RV32IMC_Zicsr_Zifencei, 4-stage pipeline) is the greenfield CPU-IP exemplar for the
transferable AI design flow. A 4-agent review (Grok product / Codex RTL-signoff / Gemini deliverable)
assessed the path to a commercializable IP. Key facts:

- The RTL implements only **external interrupt (MEI)** via `irq_external_pulse` / `mip[11]`/`mie[11]`.
  Timer (MTI, `mip[7]`) and software (MSI, `mip[3]`) interrupts, their CSR bits, causes, priority,
  and async-input synchronizers are **not implemented**.
- Adding async MTI/MSI is a real RTL + ADR effort plus deterministic-injection DV (P1.1). It is the
  single largest scope item between "draft" and "full bar B".
- Commercial credibility for this product rests on **flow re-verifiability** (every claim replayable
  by the customer via pytest gates + Spike lockstep), not on ISA breadth.

## Decision

**Two-SKU staged commercialization.** Freeze the first deliverable scope to a **sync-IRQ MVP**:

**SKU-1 MVP-commercial (`qualified-mvp`)** — frozen scope:
- ISA: RV32IMC_Zicsr_Zifencei.
- Interrupts: **external (MEI) only**, via `irq_external_pulse`. **MTI/MSI/async are OUT OF SCOPE**
  and stated as such in the spec and DV report — **not silently waived**.
- FENCE.I (Zifencei): **in scope** (decoded; architected NOP — no I-cache).
- Memory: fixed-latency valid/ready wrapper, no I-cache.
- DV bar = **"bar B-minus"**: passes riscv-dv full instruction mix (load/store, branch/jump, CSR,
  RV32M, RV32C, sync traps, FENCE.I) EXCLUDING async interrupts. Spike per-commit lockstep authority.
- Coverage: functional 100% on declared scope (incl fence.i + MEI paths) AND code coverage closed
  (line/toggle >= 85% or ADR-linked waiver).
- PPA: DC trial labeled **indicative, not production signoff**.
- Package: integration guide + programmer's model + DV signoff report + handoff test.

**SKU-2 Gold (`production-qualified`)** — MVP plus the User's full **bar B**: async MTI/MSI RTL+ADR,
riscv-dv async stress, riscv-arch-test/compliance, CDC/RDC + DFT/scan + multi-corner hold-clean STA,
first-class retire/trap observability ports, full datasheet/SDC package.

async IRQ is therefore **off the MVP critical path** and is the headline Gold feature (Gemini ranked
it #1 customer-missing — deferred, not dropped). The User's bar-B goal is preserved as the Gold target.

## Consequences

- Positive: faster honest first commercial story; MVP claims are fully replayable; no half-implemented
  IRQ controller (which would be worse than honest sync-only).
- Negative / accepted: SKU-1 cannot claim "full RISC-V interrupt support" or "passes RISC-V DV"
  unqualified — only "passes riscv-dv sync full-mix (named async exclusion)". Marketing must use the
  scoped claim. Honesty gate (gate_03_09-style scope assertion) enforces the named exclusion.
- The passes_riscv_dv campaign acceptance bar splits: **B-minus = MVP gate**, **full B = Gold gate**.

## Honesty guardrails (non-negotiable)

- No `draft`->`production` maturity bump on gate count alone; `qualified-mvp` requires the full MVP
  exit bar (DV B-minus + coverage closure + docs + handoff test).
- async-IRQ exclusion is documented in spec + DV report, never a silent `--enable_interrupt=0`.
- DC trial numbers are labeled indicative; production PPA is a Gold deliverable.
