# cpu_m1 DV Sign-off Checklist — Tier-1 (Consumer/IoT), RV32IMC SKU-1

Rev 0.1 (2026-06-09). Honest status per 3-agent review (Grok/Codex/Gemini) vs customer standard.
Legend: ✅ done · 🟡 partial · ❌ missing · ⬜ excluded(documented). NOT a signoff claim until all
non-excluded rows are ✅ and an independent approver (producer≠approver) signs.

## Code coverage (after justified exclusions)
- ❌ Line 100% (now ~77–95%)
- ❌ Branch ≥95% (not separately measured)
- ❌ Expr/Condition ≥90% (not measured)
- ❌ Toggle ≥90% (now ~63–74%; WS6 in progress, gate_04_09 xfail; RAW + adjusted dual-number per Grok)
- ❌ FSM state+arc 100% (not separately measured)

## Functional coverage
- 🟡 ISA coverage (100% own coverpoints; ❌ riscvISACOV bins not used)
- 🟡 Hazard cross ≥80% (M-unit done; broader RAW/WAW/WAR×forward×flush shallow)
- 🟡 Priv/IRQ/CSR ≥90% (M-mode only; ⬜ S/U/MMU excluded)
- 🟡 Corner operands ≥85% (ALU/MD corners; no full random sweep)

## Methodology / TB
- 🟡 Reference lockstep (Spike per-commit PC/GPR/CSR via Python harness; ❌ NOT RVVI SV / UVM)
- 🟡 Constrained random (riscv-dv, sync mix incl real CSR; ⬜ async IRQ Gold-deferred; ❌ pyflow fence-gen)
- ✅ Regression automation (pytest gates, 189 pass/1 xfail; ❌ no nightly CI farm/coverage-DB merge)
- ❌ UVM env (agent/monitor/scoreboard, reuse ≥80%) — justified-equivalent argued, customer-mandate = SKU-2

## Formal / static signoff
- ❌ SVA key-module proofs (decode legality, ALU eq, x0, CSR WARL, valid-ready stability, no-X-control)
- ✅ Lint base PASS (0 error); ❌ 0-warn (24 advisory, ADR-0006)
- ❌ CDC report (single-clock → low risk but report MISSING) · ❌ RDC · ❌ X-prop
- 🟡 Synthesis (DC TRIAL ~699MHz, 2 hold violators, single corner) — ❌ multi-corner signoff QoR
- ⬜ DFT scan / power-intent (SKU-1 excluded, SKU-2 roadmap)

## Deliverables
- 🟡 V-Plan (this dir, rev 0.1) · ❌ final Coverage Report (per-block + exclusions)
- 🟡 Bug-tracking summary (docs/v2_pipeline_bug_taxonomy.md; no severity/fix-SHA/regress matrix)
- ❌ Regression log archive (frozen, reproducible) · ❌ DV signoff checklist SIGNED · ❌ Databook
- 🟡 Integration guide (PENDING, P3)

## Honest verdict
**M1 is BELOW Tier-1 today** (development-qualified exemplar). Tier-1 RV32IMC is reachable in ~8–12
months with the items above closed + a written exclusion list. M1 does NOT claim Tier-2/3, ASIL-D,
Android RVA22, riscvISACOV-met, RVVI/UVM-compliant, lint-clean(0-warn), or PPA-signoff.
