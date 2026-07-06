# PL Decision — Magpie_M1 toward a commercializable CPU IP (incl DV + coverage)

Date 2026-06-09. PL = Claude Code (synthesis of Grok product / Codex RTL-signoff / Gemini deliverable
inventory; PL owns the decision + acceptance). Provenance: .run/ipcommercial_20260609/ (3 agent logs).
Authority unchanged = Spike per-commit lockstep + pytest gates. Clean-room + ADR for deviations.

## DECISION (headline): two-SKU staged commercialization
Adopt a **two-SKU staged path** that reconciles the User's "bar B = full ISA incl async IRQ" choice
with the commercial reality surfaced by the 3-agent review:

- **SKU-1 = MVP-commercial (`qualified-mvp`)** — scope-honest **sync-IRQ** RV32IMC_Zicsr_Zifencei core:
  FENCE.I in; **async MTI/MSI explicitly out-of-scope (documented, NOT silently waived)**; DV =
  "passes riscv-dv full-mix EXCLUDING async IRQ" (Grok's "bar B-minus"); code+functional coverage
  closed on declared scope; integrator doc set + handoff test. Ship the **flow/IDE re-verifiability**
  story, not spec-breadth theater.
- **SKU-2 = Gold (`production-qualified`)** — MVP **plus** the User's full bar B: async MTI/MSI RTL+ADR,
  riscv-dv async stress, riscv-arch-test/compliance, CDC/RDC + DFT/scan + multi-corner hold-clean STA,
  first-class observability ports, full datasheet/SDC package.

Rationale: async IRQ is a HARD RTL+ADR gap (only `irq_external_pulse`/MEI exists). Grok: don't block
the first commercial story on it. Gemini ranks it #1 customer-missing — so it is the headline gold
feature, not dropped. **The User's bar-B goal is preserved as the Gold target; MVP is the honest
near-term ship.** This is a fork for User confirmation (see end).

## VERIFIED HONESTY CALLOUTS (PL-checked, not agent-asserted)
1. **"functional coverage 100% (72/72)" ≠ code coverage.** Verified in flow/state: line **~77–79%**,
   toggle **~61–65%** — far below signoff (~85–95%). Code-coverage closure is a real MVP gap; the
   176-green / functional-100% headline obscures it. (Gemini flagged ~67.8% toggle; actual is lower.)
2. **DC is trial-not-signoff**: single tt corner, vectorless power, zero-wireload, **2 hold violators**
   (constraints.rpt: u_csr/cycle_cnt_reg[0]/D, primed_reg/D). Indicative, NOT production PPA.
3. **`design/cpu_m1/dv/` is empty** (only README) — DV collateral lives flow-internal; packaging gap.
4. **RESET_PC hardcoded**: `cpu_m1_top` boot-primes address 0 (cpu_m1_top.v:86/91); nonzero reset
   vector fetches wrong first word — a real integration bug, not cosmetic.
5. Do NOT rename `draft`→`production` on gate count alone; do NOT pass bar B by shrinking ISA; do NOT
   ship half-implemented async IRQ (worse than honest sync-only).

## INTEGRATED GAP INVENTORY (3 angles)
### A. RTL / signoff BLOCKERS (Codex, file:line)
- Top interface not an integration boundary: custom Harvard valid/ready, **no bus error/response,
  no fault→trap path, no size/prot metadata** (cpu_m1_top.v:35/45). Integrator can't map AXI/AHB/TL
  errors. → freeze iface + provide adapter, or document strict contract.
- IRQ iface too narrow: only MEI (csr.v:70/79/91, def.vh:145/163). Missing MTI/MSI mip[7]/[3],
  mie bits, causes, priority, level-vs-pulse, async synchronizers. [= SKU-2 / WS3]
- Lint not IP-clean: RFU synthesis-ignored `initial` (rfu.v:36) — scan/ATPG-hostile; repeated-NBA
  (cpu_m1_top.v:98/109, csr.v:170-199); dead/unused (cdec_illegal core.v:142, open LSU ports).
- No CDC/RDC, no DFT/scan, trial-not-signoff timing (above). RESET_PC hardcoded (above).
- DV via hierarchy-snoop (wb_instr_retired core.v:1064; ex_wb_*); `trap` is sync-only latch
  (core.v:1069), not a full trap_event — not a deliverable verification interface.
- Hygiene: Chinese-only comments + lab04/lab08 framing in sellable RTL; stale lsu.v:26 comment.

### B. Deliverable package gaps (Gemini) — EXISTS / THIN / MISSING
- EXISTS: RTL+filelist, DV plan/roadmap, lint signoff (no CDC).
- THIN: datasheet, programmer's model (no CSR bit-field/exception-priority map), DV signoff report,
  functional cov (fence.i + IRQ bins missing), code cov (toggle low), SDC, release notes.
- MISSING: integration guide, interface timing spec, DFT, legal/LICENSE + clean-room attestation.
- Top-10 customer-blocking: async IRQ, integration guide, toggle closure, datasheet, dv/ packaging,
  CSR map, standalone SDC, CDC/RDC, legal attestation, multi-corner PPA.

### C. DV + coverage signoff bar (Grok) — credible-to-buyer ≠ "100% functional"
Needs: DV plan doc + regression tiers; documented lockstep scale + repro one-liner; riscv-dv category
table with **named exclusions**; directed corner suites; coverage taxonomy (functional + line/toggle,
waivers ADR-linked); a few well-chosen SVA (bus + X-prop); signoff exec summary with known-bugs=0.
Gold adds riscv-arch-test/RVI compliance + assertion coverage + optional formal.

## ROADMAP (Grok phases, mapped)
- **P0 Scope-freeze (gating)**: ADR for MVP IRQ model (sync MEI only, async→gold), FENCE.I in-scope;
  extend spec.md → programmer's model + integration contract. Fix RESET_PC top exposure.
- **P1 DV bar B-minus (gating MVP)**: close FENCE.I in testlist; finish passes_riscv_dv sync full-mix;
  lockstep farm ≥100k green; named async exclusion.
- **P2 Coverage+observability (gating MVP)**: fence.i + MEI/exception coverpoints; **toggle/line
  closure to ≥85% or ADR waivers**; optional first-class retire/trap observability port (helps both
  DV-packaging and gold).
- **P3 MVP package + handoff gate (gating)**: integration guide + datasheet + DV signoff report +
  SDC template + move dv collateral into design/cpu_m1/dv/; ip.json draft→qualified-mvp; non-author
  handoff test green.
- **P4 Gold RTL/DV**: async MTI/MSI RTL+ADR+DV+coverage; riscv-arch-test; bar B FULL.
- **P5 Gold signoff**: CDC/RDC, multi-corner hold-clean STA, DFT/scan, full binders; production-qualified.

Priority: (1) scope ADR (2) FENCE.I + bar-B-minus (3) in-scope coverage closure (4) integrator docs +
handoff test (5) async IRQ = gold (6) CDC/DFT/multi-corner = gold.

## FORK — RESOLVED (User 2026-06-09): **(a) MVP-first, two SKU**
Ship MVP-commercial sync-IRQ SKU-1 first; full bar B (async IRQ + CDC/DFT/multi-corner) = Gold SKU-2.
async IRQ is OFF the MVP critical path. Next 4-agent wave is steered to the MVP roadmap (P0->P3).

## IMMEDIATE NEXT (MVP P0, Claude owns)
1. ADR `0012-mvp-irq-scope-and-commercial-cut.md`: MVP IRQ model = sync MEI (`irq_external_pulse`)
   only; async MTI/MSI deferred to Gold; FENCE.I in-scope. Freezes the commercial scope contract.
2. Fix verified RESET_PC bug: expose `RESET_PC` at `cpu_m1_top`, remove hardcoded boot addr 0
   (cpu_m1_top.v:86/91) — re-verify 176 gates + lockstep no-regress (Rust+RTL/ADR discipline).
3. Set ip.json maturity taxonomy: add `qualified-mvp` / `production-qualified`; record the two-SKU
   plan + MVP scope contract.
Then P1 fence.i + bar-B-minus DV, P2 coverage closure (toggle/line >=85% or ADR waiver), P3 package.
