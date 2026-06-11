# Magpie_M1 — Tier-2 (Industrial) Customer Acceptance: Gap Analysis & Closure Plan

Rev 1.0 · 2026-06-11 · Owner: PL (Claude) · Authority = Spike per-commit lockstep + pytest gates
Standard: `~/project/SOC/RISCV_sign_off.html` (Tier-2 Industrial, RV32IMC + optional A)
Reviewers (customer-acceptance role): **Gemini** (full-corpus artifact audit) + **Grok** (sign-off-meeting
hold list). Both independent reviews converged; this document integrates them and records what was
closed in this session vs what remains EDA-gated.

---

## 0. Verdict (both reviewers, independently)

> **NOT Tier-2 signable today — REJECT customer acceptance.**
> The core execution path has real closure (Spyglass lint 0/0, 105k-commit Spike lockstep with 0
> divergence, riscv-arch-test 74/74, VC Formal 40/40 properties proven, multi-corner DC trial). But the
> **acceptance package is internally inconsistent**: it advertised "Tier-2 CLOSED" while the honest
> baseline docs (`VPLAN.md`/`DV_SIGNOFF_CHECKLIST.md` rev 0.1) say "below Tier-1", and several "CLOSED"
> claims conflate **per-island** coverage with **whole-core** reality. That island-green / core-red
> pattern is an automatic sign-off reject.

**Root cause (honesty-界):** `commercial_signoff_evidence_pack.md` (2026-06-10) over-claimed Tier-2
CLOSED one day after the honest `VPLAN`/`DV_SIGNOFF_CHECKLIST` (2026-06-09) said "below Tier-1". This
closure work **reconciles to the honest baseline** while crediting the genuine progress made since.

---

## 1. Tier-2 requirement matrix (integrated from Gemini's artifact audit)

Legend: ✅ MET · 🟡 PARTIAL · ❌ FAIL · ⚠️ OVERCLAIM (claimed CLOSED, not backed) · ⬜ documented deviation/N-A

| § | Tier-2 requirement | target | M1 actual (artifact) | verdict |
|---|---|---|---|---|
| 01 | Line / Statement | 100% | whole-core best **95.95%** (1374/1432, phase logs); pack said CLOSED | ⚠️ needs §04 waiver or close |
| 01 | Branch / Decision | 100% | whole-core **~96%** (`gate_p19`); pack said CLOSED | ❌/⚠️ |
| 01 | Expression / Condition | 95–100% | whole-core **~79%** (`gate_p19` floor 78%) | ❌ |
| 01 | **Toggle** | **95%** | whole-core **62.93%** (12745/20252), held behind `@pytest.mark.xfail` (`gate_04_09`) | ❌ **biggest gap** |
| 01 | FSM State+Arc | 100% | per-island 100% (`gate_p02..p14`) | ✅ (island) |
| 02 | ISA instruction | 100% | riscvISACOV-mapped 100% (`riscvisacov_equivalence.md`) | ✅ |
| 02 | Compressed C | 100% | mapped; per-mnemonic RVC bins partial | 🟡 |
| 02 | M corner | 98% | mapped 100% | ✅ |
| 02 | A atomic (IMAC) | 98% | RV32A directed LR/SC+AMO (`phase_07_00`) | 🟡 (directed, ungated) |
| 02 | Pipeline hazard cross | 90–95% | micro-stalls tracked; ISA-level RAW/WAW/WAR cross missing | 🟡 |
| 02 | Privilege/IRQ/CSR | 100% | mapped; per-CSR address bins missing | 🟡 |
| 02 | Corner operands | 95% | mapped 100% | ✅ |
| 03 | SVA proven (Pipeline+CSR) | proven | **VC Formal 40/40 proven** (`formal_assertions.md`) | ✅ |
| 03 | Formal coverage closure | 90% | **no formal-coverage (FCA/reachability) metric** | ❌ |
| 04 | Written waiver + DV-lead sign | required | JSON waivers + dual-number; **no human DV-lead sign artifact** | 🟡 |
| 05 | UVM TB reuse ≥80% | required | directed Verilog TBs (documented deviation) | ⬜ deviation |
| 05 | Reference lockstep (RVVI) | per-retire PC/GPR/CSR | Spike per-commit (not RVVI shim); **through-trap not commit-level** (`--priv=m`) | 🟡 |
| 05 | Constrained-random | riscv-dv+directed | 105k commits; **excludes async IRQ + fence/SYNCH** | 🟡 scope-carve |
| 05 | Regression automation | CI, zero waived | **xfail present** (`gate_04_09`); no nightly CI farm | ❌ |
| 05 | DV docs (V-Plan/Cov/Bug/Archive/Checklist) | required | V-Plan + checklist exist (rev 0.1); Coverage Report / Bug Summary / Regression Archive incomplete | 🟡 |
| 05 | ISA compliance arch-test | pass all | **74/74** (`phase_p_archtest`) | ✅ |
| 06 | Lint clean | 0/0 | Spyglass **0 error / 0 warn** (`gate_05_00`) | ✅ |
| 06 | CDC / RDC / X-prop | no violation | **no CDC/RDC/X-prop artifact** | ❌ |
| 06 | Synthesis QoR | −10% margin | multi-corner 699 MHz WNS=0 (`multicorner_qor.md`); **2 APR hold violators open** | 🟡 |
| 06 | Power intent UPF/CPF | or justified N/A | single-domain → N/A (needs signed N/A) | ⬜ |
| 06 | DFT scan ≥95% | required | **no scan/DFT** (`multicorner_qor.md`) | ❌ |
| 06 | Regression pass 100% | zero waived fail | xfail present | ❌ |
| 08 | Bus / CLINT / PLIC / Debug | verified | AXI4-Lite + CLINT + PLIC/UART + JTAG directed; **debug/PLIC ungated, no lockstep** | 🟡 |

---

## 2. Prioritized hold list (from Grok's sign-off-meeting role)

### Genuine blockers (cannot sign Tier-2 without fix or written contract change)
1. **Whole-core toggle 62.93%** + **`gate_04_09` xfail** — Tier-2 needs toggle ≥95% and regression zero-waived. Island-green/core-red is the #1 reject.
2. **Whole-core branch ~96% / expr ~79%** — need 100% / ≥95%, or per-exclusion structural-unreachable §04 waivers.
3. **riscv-dv scope carve-out** (async IRQ + fence.i excluded) + **trap path not per-commit lockstep** — for an M-mode MCU these are not optional.
4. **Missing/incomplete DV acceptance package** (Coverage Report w/ exclusions, Bug Summary sev1–2, Regression Archive, item-by-item DV Signoff Checklist, SHA-locked).
5. **No formal-coverage closure metric** (40/40 proven ≠ 90% reachability).
6. **No CDC / RDC / X-prop evidence.**

### Acceptable as documented deviations (industrial MCU, if contract narrowed honestly)
- **Non-UVM TB** — with an equivalence memo + directed/CR closure meeting §01–02 and customer methodology waiver.
- **No UPF / vectorless power** — single power domain, signed N/A in Integration Guide.
- **No RV32A / PLIC in core IP** — if deliverable = CPU core only; atomics/PLIC = SoC integrator scope (freeze doc says so).
- **2 hold violators** — only as conditional sign-off with PD fix-commitment date; not for tapeout acceptance.
- **Debug Module ungated** — only if SKU is "CPU without DM" and contract drops §05 DM requirement.

---

## 3. Closure status — closed THIS session vs EDA-gated roadmap

### ✅ Closed this session (documentation / honesty — no fake green)
- **C1 This gap+closure document** (the customer-facing acceptance trace the reviewers said was missing).
- **C2 Honesty reconciliation of `commercial_signoff_evidence_pack`** — downgrade unbacked "Tier-2 CLOSED"
  to honest per-island-vs-whole-core status; keep genuinely-closed rows (lint, formal 40/40, arch-test,
  functional bins) scoped correctly. Removes the instant-reject overclaim.
- **C3 `VPLAN.md` / `DV_SIGNOFF_CHECKLIST.md` → rev 0.2** — reconciled to true current state (Tier-2 target,
  real formal/synth/arch-test progress + honest residual gaps), full item-by-item Tier-2 §01–09 mapping.
- **C4 Feature Freeze / SKU contract declaration** — honest in-scope (RV32IMC+Zicsr+Zifencei M-mode core)
  vs SoC-integrator scope (PLIC/UART/Debug) vs optional (A/PMP).

### 🔧 EDA-gated / multi-day DV (planned, NOT closed — owners + effort)
| Item | What it needs | Engine | Sandbox | Est |
|---|---|---|---|---|
| Toggle 62.93%→95% | new stimulus to toggle remaining bits; re-merge full farm+directed coverage DB; then §04 waivers for true-unreachable | Verilator cov / VCS URG | OSS in / VCS OUT | days |
| Branch 100% / expr ≥95% on core.v | targeted seeds + per-exclusion waivers | Verilator/VCS | mixed | days |
| Expanded lockstep | enable async IRQ + fence.i streams in riscv-dv farm; 0 divergence | Verilator+Spike | OSS in | days |
| Through-trap per-commit | Spike `--priv=m` harness fix; rerun trap suite commit-by-commit | Spike | OSS in | 1–2 d |
| Formal coverage ≥90% | VC Formal FCA/reachability report | VC Formal | OUT (Codex `-s danger-full-access`) | 1–2 d |
| CDC / RDC / X-prop | Spyglass CDC/RDC + X-prop pass | Spyglass | OUT | 1–2 d |
| 2 hold violators | APR hold fix + STA signoff | DC/PT/APR | OUT | days |
| DFT scan ≥95% | scan insertion + ATPG coverage (if SKU includes DFT) | DFT compiler | OUT | days |
| Debug/A/PMP gates | promote directed phases to gated lockstep+coverage if in-scope | Verilator+Spike | OSS in | days |

---

## 4. Fastest honest path to signable (per Grok, condensed)
1. **Publish Feature Freeze** (SKU = RV32IMC core; A/PMP optional; PLIC/UART/Debug = integrator or explicitly in-scope).
2. **Assemble SHA-locked DV package** — checklist row→artifact, honest pass/fail/na/waiver.
3. **Independent rerun** of the genuinely-closed evidence (formal, arch-test 74/74, ≥1 lockstep seed) attached to SHA.
4. **Close real blockers**: trap per-commit lockstep → expand riscv-dv scope → merged toggle/expr/branch to bars or §04 waivers → **delete all xfails** → CDC/RDC/X-prop → formal coverage.
5. **Customer spot-check** (rerun pytest coverage gates, 3 lockstep seeds, arch-test subset, 1 formal property) → sign **full Tier-2** or **Tier-2-Narrow (RV32IMC core, no DM/A)** — both valid if the checklist matches the contract.

> Estimate: ~4–6 weeks full Tier-2 parallelized; ~2 weeks for an honest **Tier-2-Narrow core-only** contract.
