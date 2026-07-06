> **M1A REV (2026-06-12, design_id=cpu_m1a)** — this document is INHERITED from frozen M1 with the
> following deltas; the authoritative current-state evidence is `docs/reports/m1a_tier2_evidence_pack.md`.
> Checklist authority for M1A = docs/reports/m1a_tier2_evidence_pack.md (row->artifact map, fresh evidence only).

# cpu_m1 DV Sign-off Checklist — Tier-2 (Industrial), RV32IMC SKU-1

Rev 0.2 (2026-06-11). Reconciled to current state after the Gemini+Grok customer-acceptance review.
Authority = Spike per-commit lockstep + pytest gates. Legend: ✅ done · 🟡 partial · ❌ missing ·
⬜ excluded (documented, see `FEATURE_FREEZE.md`). **Not a sign-off claim** until all non-excluded rows
are ✅ and an independent approver (producer≠approver) signs at a locked git SHA.
Full gap analysis + closure plan: `docs/reports/tier2_acceptance_gap_and_closure.md`.

## §01 Code coverage (whole-core — the number the customer signs)
- ❌ Line 100% — whole-core ~95.95% (1374/1432)
- ❌ Branch 100% — whole-core ~96% (`gate_p19`)
- ❌ Expr/Condition ≥95% — whole-core ~79% (`gate_p19` floor 78%)
- ❌ Toggle ≥95% — whole-core **62.93%** (12745/20252); tracked `gate_04_09` xfail
- ✅ FSM state+arc 100% — per-island (`gate_p02..p14`)
- NOTE: per-island 13 modules ARE at Tier-2 (line/branch 100, expr/toggle ≥95, FSM 100). Island ✅ ≠ core ✅.

## §02 Functional coverage
- ✅ ISA instruction (riscvISACOV-mapped 100%, `riscvisacov_equivalence.md`)
- 🟡 Compressed C (mapped; per-mnemonic RVC bins missing)
- ✅ M corner (mapped 100%)
- 🟡 A atomic (RV32A directed LR/SC+AMO; ungated — optional config)
- 🟡 Pipeline hazard cross (micro-stalls; ISA-level RAW/WAW/WAR cross missing)
- 🟡 Priv/IRQ/CSR (mapped; per-CSR address bins missing)
- ✅ Corner operands (mapped 100%)

## §03 Formal / static
- ✅ SVA Pipeline+CSR proven — **VC Formal 40/40 properties proven, 0 CEX** (`formal_assertions.md`)
- 🟡 Formal coverage closure ≥90% — alu/rfu/forward/lsu **100%**; csr **10%** (needs more csr properties). `phase_p_formal_coverage/`
- ✅ Lint clean 0 error / 0 warn (`gate_05_00`)
- ✅ CDC 0 unsync crossings · ✅ RDC 0 crossings · ✅ X-prop 0 messages (`phase_p_cdc_rdc_xprop/`; trigger.v filelist-omission waived)

## §04 Waiver
- ✅ JSON waivers retained, dual-number RAW+ADJUSTED, structural-only, `spike_impact:none`
- 🟡 Written waivers for the whole-core line/branch/expr/toggle residuals — to be authored per-exclusion
- ❌ Human DV-lead review signature artifact

## §05 DV delivery
- ⬜ UVM/SV TB reuse ≥80% — directed Verilog TBs (deviation; equivalence memo required)
- 🟡 Reference lockstep — Spike per-commit PC/GPR/CSR (not RVVI shim); ✅ through-trap verified (`gate_03_12`: prefix lockstep + spec-validated handler mepc/mcause/mstatus; this Spike build halts commit-log post-trap, documented)
- 🟡 Constrained-random — riscv-dv 105k commits + ✅ fence/fence.i in-stream at scale (gate_03_13, 10539 commits 0-div); ❌ async IRQ still excluded (Spike no deterministic ext-IRQ injection — msip path pending)
- ❌ Regression automation zero-waived — `gate_04_09` xfail present; no nightly CI farm
- ✅ ISA compliance — riscv-arch-test 74/74 (`phase_p_archtest`)
- ✅ DV docs: ✅ V-Plan · ✅ this checklist · ✅ Feature Freeze · ✅ Coverage Report (`docs/reports/coverage_report.md`) ·
  ✅ Bug-tracking summary (`docs/reports/bug_tracking_summary.md`) · ✅ Regression archive (`docs/reports/regression_archive.md`, SHA-lock at acceptance)

## §06 RTL sign-off
- ✅ Lint clean · ✅ CDC (0 unsync) · ✅ RDC (0) · ✅ X-prop (0) (`phase_p_cdc_rdc_xprop/`)
- 🟡 Synthesis QoR — multi-corner 699 MHz WNS=0 (setup, ideal clock). Hold: ⬜ back-end (APR/CTS) stage — there is NO place-and-route flow; FF-corner hold violations are pre-CTS ideal-clock synthesis artifacts, fixed during CTS/APR (not in this DC-trial). Physical/hold signoff = integrator back-end scope.
- ⬜ Power intent UPF — single-domain N/A (needs signed N/A)
- ❌ DFT scan ≥95% — no scan/DFT in this SKU
- ❌ Code coverage Tier target (see §01) · ❌ Regression 100% zero-waived (xfail)
- ✅ SVA/Formal proven (40/40)
- 🟡 RTL feature freeze — ✅ `FEATURE_FREEZE.md`; ❌ Databook/Register-Map freeze doc

## §08 Embedded integration (SoC-integrator scope unless contracted in)
- 🟡 AXI4-Lite (FPV 18/18 proven) · 🟡 CLINT/PLIC/UART directed · 🟡 Debug DM/DTM/Trigger directed+OpenOCD smoke
- ❌ none gated/lockstep-closed — see `FEATURE_FREEZE.md` (out-of-scope) or promote to gates

## Honest verdict (2026-06-11)
**M1 is NOT Tier-2 signable today.** Real closure exists (lint 0/0, formal 40/40, arch-test 74/74,
105k-commit lockstep 0-divergence, multi-corner DC); the blockers are **whole-core coverage (toggle 63%,
expr 79%, branch/line <100%) + the xfail, scope-carved lockstep + through-trap granularity, CDC/RDC/X-prop,
formal coverage, and the missing DV deliverable docs**. Two honest paths in `FEATURE_FREEZE.md`:
full Tier-2 (~4–6 wks) or Tier-2-Narrow core-only (~2 wks). No row above is fake-green.
