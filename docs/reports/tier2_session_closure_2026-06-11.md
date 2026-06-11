# Magpie_M1 — Tier-2 Closure Session Summary (2026-06-11)

Owner: PL (Claude) · design_id = `cpu_m1` · Authority = Spike per-commit lockstep + pytest gates
Scope: full-Tier-2 closure campaign (customer-chosen path) against `~/project/SOC/RISCV_sign_off.html`.
Companion docs: `tier2_acceptance_gap_and_closure.md`, `coverage_report.md`,
`IP/cpu_m1/dv/vplan/{VPLAN,DV_SIGNOFF_CHECKLIST,FEATURE_FREEZE}.md`.

## 1. Headline
Started from a customer-acceptance review (Gemini+Grok) that found **NOT Tier-2 signable today** —
island-green/core-red overclaim + missing deliverables. This session **reconciled the package to an
honest baseline** and **closed/advanced 8 tracked blockers**. M1 is still **not Tier-2 signable** (honest):
the remaining gaps are whole-core coverage to bar + async-IRQ + CSR-formal. No row was fake-greened.

## 2. Blocker status at session end

| # | Blocker | Status | Evidence |
|---|---|---|---|
| 3 | Through-trap per-commit lockstep | ✅ **DONE** | `gate_03_12` (5/5): DUT runs full ecall handler ×2 (mepc/mcause=11/mstatus=0x1800, mret resume), prefix Spike-locked + spec-validated handler |
| 5 | CDC / RDC / X-prop | ✅ **DONE** | Spyglass: CDC 0 unsync, RDC 0, X-prop 0, 0 unwaived (`phase_p_cdc_rdc_xprop`) |
| 8 | DV deliverable docs | ✅ **DONE** | `coverage_report.md`, `bug_tracking_summary.md`, `regression_archive.md` |
| 4a | fence/fence.i in-stream lockstep | ✅ **DONE** | `gate_03_13`: injected into random riscv-dv, 4 seeds, 10539 commits, 0 div |
| 7 | "2 hold violators" | ✅ **DISPOSITIONED** | No APR/PnR flow; FF-corner hold = pre-CTS ideal-clock artifact → back-end stage, out of RTL-IP scope (figure was a mischaracterization, corrected) |
| 1 | Toggle → 95% | 🟡 **66.4% in-SKU** | farm-coverage measured 53.3% raw; CSR-injection (lockstep-safe) → 54.5%; structural waiver 3651 bits → 66.4%; RAS blocked by pyflow hang |
| 2 | Branch / expr | 🟡 measured | branch 66.7% / expr 59.5% (same farm run); folds into #1 campaign |
| 4b | async IRQ lockstep | ✅ **lockstep-able path DONE** | `gate_03_14` (5/5): msip software-int directed — prefix per-commit lockstep vs Spike (12 commits, 0 div) + spec handler (mcause=0x8000_0003); IRQ-path u_csr bits toggle. Truly-async meip/mtip stay directed-only (no deterministic Spike async injection) |
| 6 | Formal coverage ≥90% | 🟡 4/5 | alu/rfu/forward/lsu 100%, csr 10% (Codex/VC Formal) |

## 3. Honesty findings surfaced (corrections to prior claims)
1. **Spike `--log-commits` halts after the first M-mode sync trap** (verified clean no-MMIO ecall) — the
   prior "needs `--priv=m`" was wrong; the handler is spec-validated instead. (`gate_03_12`)
2. **Coverage "62.93% CLOSED" was best-single-run + cross-TB unmergeable** — real merged number from the
   farm TB is 53.3% raw / 66.4% in-SKU after structural waivers; datapath (alu/forward/hazard/mul/div/
   lsu) is ~100%, the gap is CSR/RAS/debug/PMP.
3. **Injecting timing-CSR reads (cycle/instret/mip) poisons a GPR with DUT≠Spike value → downstream
   divergence** — only deterministic CSRs are injection-safe. (real lockstep catch)
4. **riscv-dv pyflow generator hangs with `num_of_sub_program>0`** (0 CPU) — native RAS lever unavailable.
5. **"2 hold violators" mischaracterized** — FF synthesis shows thousands (pre-CTS, normal); hold is an
   APR/CTS stage not present in this DC-trial.
6. **commercial pack overclaims reconciled** — §01/§07 "CLOSED" → honest PARTIAL with whole-core numbers;
   SoC subsystem rows flagged directed-only/ungated.

## 4. Genuinely-closed evidence (truthfully claimable)
Spyglass lint 0/0 · CDC/RDC/X-prop 0 · VC Formal 40/40 proven · riscv-arch-test 74/74 · 105k-commit
riscv-dv lockstep 0-divergence · through-trap (gate_03_12) · fence-in-stream (gate_03_13) · multi-corner
DC setup trial · per-island coverage at Tier-2 · core datapath toggle ~100%.

## 5. Remaining to full Tier-2 (precise, ~1–2 wks)
- **#1/#2 coverage**: u_ras 624 (inline call/return injection — pyflow sub-program hang blocks the native
  lever), u_csr M-CSR/TRAP storage ~571 (directed walking CSR writes + trap variety), other 495, corner
  top-ups; then re-merge → ≥95% on in-SKU denominator; DV-lead sign the §04 waivers (currently PENDING-SIGN).
- **#4b**: msip software-interrupt lockstep test (deterministic).
- **#6**: csr SVA properties to lift formal coverage 10%→90% (licensed, Codex).
- **Process**: nightly CI farm + coverage-DB merge; Databook/Register-Map freeze; remove `gate_04_09` xfail
  once toggle closes; DV-lead + customer sign at a locked SHA.

## 6. New working rules adopted this session (CLAUDE.md §5.5)
- ≤5-min agent-execution heartbeat (check CPU time, not output size; feed `</dev/null`); key points in Chinese.
- Every user-confirmation option (incl. meta/pause choices) must be agent-ranked (Grok-led) before presenting.

Verdict: **honest, defensible Tier-2-candidate package** with a clear, costed path to signable. The
biggest single remaining item is whole-core coverage closure (toggle/expr) + DV-lead waiver sign-off.
