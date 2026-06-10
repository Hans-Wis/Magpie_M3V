# Magpie_M1 — incremental per-stage coverage gate plan (P00→P19+)

Date 2026-06-09. 4-agent co-design (Grok methodology + Codex coverability + Gemini per-module data).
PL = Claude (sole committer + per-stage acceptance). Methodology shift (User): decompose into many
small gates; each stage's RTL slice must hit its coverage target before advancing — never whole-core
at once. Reuse existing RTL/flow; agents review+optimize, no from-scratch redesign.

## Per-stage acceptance rule (every P01+ gate) — Grok
Gate passes iff ALL: (1) scoped metrics meet ADJUSTED target (RAW reported alongside); (2) scoped
regression lock (existing + new tests pass); (3) scoped Spike per-commit lockstep where the slice is
architecturally visible; (4) per-stage waiver file `waivers/Pnn_<scope>.json` (Codex produces, Codex
reviews, Claude approves — producer≠approver, no end-of-flow deferral); (5) record_step with dual-number
table. **No advance until green.** Targets (Tier-1, after justified exclusions):
line 100 · branch ≥95 · expr/cond ≥90 · toggle ≥90 · FSM state+arc 100 · functional bins hit.
Tools: Verilator = line/toggle; **VCS+URG = branch/expr/FSM + coverage-DB merge** (via Codex
`-s danger-full-access`). No stage "done" on branch/expr/FSM if only Verilator ran.

## Current per-module toggle (Gemini) — where effort goes
DONE (≥90, lock cheaply): alu 99 · forward 100 · hazard 100 · rfu 100 · lsu 100 · mul 90.
PARTIAL: idu 88 · cdec 85 · **div 65** · core 71.   TODO (low): bp 37 · csr 22 · ifu 19 · ras 16 · **cpu_m1_top <10**.
=> leaf datapath cheap-lock; spend on div, csr, ifu, ras, bp, core, cpu_m1_top.

## Coverability (Codex) — EASY / HARD / STRUCTURAL
EASY unit-closeable: alu, lsu, rfu, mul, forward, hazard, idu, cdec, div(+directed ÷0/overflow/sign).
HARD (need integration/focused-lockstep): ifu cross-boundary, csr trap/IRQ commit, core, forwarding/
hazard pipeline timing, cpu_m1_top bus wait-states.  STRUCTURAL waiver candidates (per-bit, justified):
ras upper-PC stack bits, bp unused sets/tags, csr 64-bit counter high halves.

## The ladder (integrated P00→P19, reconciled across the 3)
- **P00** ✅ env/tool gate (Verilator+cov, VCS/URG, Spike, riscv-dv, Spyglass/DC; no JasperGold).
- **P01** Coverage INFRASTRUCTURE gate: dual-number (RAW+ADJUSTED) metric reporter lib, waiver JSON
  schema, per-gate harness template, VCS/URG run+merge wrapper, coverpoint map. No RTL work.
- **Phase L — leaf unit gates (cheap lock + close to Tier-1 metrics via VCS):**
  P02 alu · P03 lsu · P04 rfu · P05 forward · P06 hazard · P07 mul · P08 **div** (FSM+÷0/overflow/sign).
- **Phase D — decode unit gates:** P09 idu (ISA matrix) · P10 cdec (compressed legal/reserved sweep).
- **Phase U — stateful unit gates (+ structural waivers, dual-number):**
  P11 csr (direct-port R/W + WARL + counter-high waiver) · P12 ras (stack depth/wrap/pop + upper-PC
  waiver) · P13 bp (predictor algorithm; coverage-param small build or waiver) · P14 ifu PC-mux unit.
- **Phase I — focused core lockstep slices (NOT whole-core; delta-uncovered vs merged islands):**
  P15 core datapath (ALU/load/store/forward/load-use/muldiv) · P16 core IF/RV32C cross-boundary
  (tie BUG-XBOUND-0001; fix-correctness-first) · P17 core CSR/trap/IRQ/MRET · P18 core BP/RAS recovery
  · P19a cpu_m1_top wrapper (bus wait-states; the FIX-HARNESS for mem_stall).
- **Phase S — merge/signoff:** P19b riscvISACOV functional bins · P20 VCS coverage-DB merge (Tier-1
  union on cpu_m1_top; islands must not regress) · P21 Spike lockstep farm lock (≥100k post-xbound)
  · P22 customer Tier-1 signoff checklist + URG report (producer≠approver final waiver bundle).

## Design optimizations (Codex) — coverability, Spike-equivalent (no ADR) unless noted
- bp/ras coverage-only parameters (default = production 32-set/8-entry); small cov build proves algorithm.
- Split core IF cross-boundary logic into a helper module (core.v ~117/221/230) → enables unit coverage.
- Extract core redirect-priority mux (core.v ~1022) + CSR pipeline-bypass (core.v ~707) into combinational helpers.
- `ifdef COV` / bind-only probes for bp hit/way/counter, ras ptr, core cross signals, CSR trap/IRQ state.
- **Behavior-changing (NEED ADR):** shrink bp/ras capacity; change RAS empty-pop/same-cycle push+pop;
  trap on unknown/RO CSR write; change IF redirect/stall priority. Default: do NOT change behavior; cover as-is + waive.

## Lock-what's-done discipline (Grok)
Snapshot WS6 per-module baseline → P-leaf meta-gate fails on any metric drop >0.5%. Freeze ownership on
alu/mul/forward/hazard/lsu/rfu unless meta-gate fails or lockstep implicates. riscv-dv farm runs only at
merge (P20+) to save disk/time (disk-hygiene rule).

## Adversarial flags (Grok+Codex) — optimize, don't redesign
ras low = STIMULUS problem (needs CALL/JALR depth; only upper-PC bits legit-waiver) · ifu fix xbound
before coverage (correctness first) · core: delta-uncovered shells, never blank-slate whole-core
(WS6 mountain) · csr trap × ifu mepc-16bit must be ONE integration test (P17) not split-by-module ·
189 existing gates = regression LOCKS not coverage proof (most lack VCS Tier-1 metrics).

## Co-work loop (one cycle, e.g. P16 IFU cross-boundary)
1 Grok: stage charter (scope, acceptance table, directed matrix, "uncoverable without X" flags).
2 Codex: implement directed/unit tests + run Verilator/VCS coverage + draft waiver JSON.
3 Gemini: ingest URG/Verilator logs → ≤10-line dual-number summary + top uncovered bins.
4 Claude: read summary only + pytest gate_Pnn + Spike lockstep (where visible) + approve/reject waivers
  + COMMIT + record_step.
5 Codex: read-only review of the commit vs charter (scope creep? waiver cheat?).
Parallelism: Grok charters Pnn+1 while Claude accepts Pnn; Codex runs VCS on non-colliding islands.

## Top risks (Grok) + mitigation
local-100%-integration-hole (→ P15-18 shells + Spike subset) · unit-TB overfit (→ each control gate
≥1 existing-phase test + ≥1 riscv-dv-derived hex + lockstep) · waiver creep (→ ADJUSTED still meets
Tier-1; Codex adversarial review; behavioral waivers need Spike-unreachability log) · tool divergence
(→ both tool classes per table; P20 hard union) · gate fatigue/skip (→ P-leaf-lock + P20 merge are hard
stops in pytest ordering).
