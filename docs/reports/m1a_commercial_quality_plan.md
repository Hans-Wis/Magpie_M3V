# M1A Commercial-Quality Campaign — 3-Agent Consensus Plan

2026-06-12 · PL (Claude) · Reviewers: Grok (ordering) · Codex (repo feasibility) · Gemini (package
completeness: MISSES(8)/STALE(7)/INHERIT(4)) · raw outputs archived in `adr0026_reviews/../` tmp logs
condensed here. Goal: M1A reaches the frozen-M1 Tier-2 package quality, customer-acceptable,
**every item mutually reviewed** (producer≠approver).

## Consensus execution order (Grok waves, Codex/Gemini integrated)

| wave | item | owner→reviewer | status |
|---|---|---|---|
| 0 | **F REPAIR-0001** tb_mem_wrapper full repair → wrapper-eq green (hard blocker) | Claude→Codex | OPEN |
| 0 | **E arch-test** rerun on M1A (IMC suites as-is; **Zb gap = deviation note** — riscv-arch-test has no ratified-B suite in this vendored copy [Codex]; substitute = phase_a2 directed + illegal negatives) | Claude→Grok | OPEN |
| 0 | **A-data coverage farm** M1_COV=1 base+injectors (A2 ISA) | Claude→Gemini(condense) | RUNNING |
| 0 | **D-oss formal (SBY)** re-prove alu/rfu/forward/lsu/csr binds on new RTL (csr changed: misa.B). NOTE: **no mul/bmu props ever existed** (pre-existing gap, Gemini overstated "stale") → prop-gap ADR note + (licensed VC Formal re-run in wave 2) | Claude→Codex | OPEN |
| 1 | **A classify** → effective toggle/line/branch/expr snapshots + gates (M1 baseline 92.4/90.0/93.1/95.3 = comparison target, NOT inherited) | Claude→Grok | blocked on farm |
| 2 | **B Spyglass lint 0/0 + CDC/RDC/X-prop** (filelists pre-fixed: +bmu, +dtcm; dtcm lint-only) | Codex(danger-full-access)→Claude | OPEN |
| 2 | **C DC multi-corner** guardrails ≥650MHz / ≤+15% area / ≤18mW (ADR per-sub-phase, owed for A1+A2+A3; dtcm excluded from cpu_m1_top synth — SoC-side macro, no SRAM lib) | Codex→Claude+Gemini | OPEN |
| 2 | **D VC Formal** re-prove + FCA reachability metric (M1 blocker #5 analog — Gemini MISS list) | Codex→Claude | OPEN |
| 3 | **G docs M1A rev** — Gemini STALE list: ISA strings, perf baseline 3.23, guardrails, design report (bmu/dtcm), formal_assertions, msip/bp_way1 evidence already re-run on M1A RTL ✓, coverage baselines; + MISSES: multicorner_qor M1A, FCA, SoC-subsystem rows honest not-inherited; INHERIT w/ rev note: vcd_review_policy, exclusion discipline, signoff strategy | Claude+Gemini→Grok | OPEN |
| 3 | **H acceptance** — Gemini corpus audit + Grok sign-off hold list, **SHA-locked**; full gate regression + identity gate in the locked bundle (Grok "missed" items) | Gemini+Grok→User | OPEN |

## Standing rules
Authority = Spike lockstep + gates; no row green without fresh M1A evidence or an explicit INHERIT
note; licensed runs via Codex `-s danger-full-access`; big logs → Gemini condensation; every
disposition lands in this doc's status column.
