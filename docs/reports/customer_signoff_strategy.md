# Magpie_M1 — Customer Coverage-Signoff Standard: integrated improvement strategy

Date 2026-06-09. PL = Claude (synthesis of Grok product-strategy + Codex DV/RTL-engineering + Gemini
gap-matrix, against the customer "RISC-V 商品化 IP Coverage Signoff 標準"). Principle: each agent errs;
joint review = best design. Authority = Spike lockstep + pytest gates. Sources: .run/custreq/.

## 0. Honest position (all three agree)
**M1 is BELOW customer Tier-1 today** — a development-qualified RV32IMC M-mode exemplar for the AI
design flow, NOT a commercial-signoff IP. Gemini scorecard: Tier-1 **EXISTS 6% / PARTIAL 37% / MISSING 57%**.

**Defensible claim today (verbatim, Grok):** "Magpie_M1 is an RV32IMC M-mode CPU IP exemplar with
reproducible Spike per-commit lockstep and 189 development gates, demonstrating an AI-assisted design
flow with transparent evidence — it does not yet meet Tier-1 commercial coverage signoff (toggle, line,
riscvISACOV, deliverables, PPA) and is out of scope for Android RVA22 and safety-certified tiers."

## 1. Tier reality (Grok)
| Tier | Reachable? | Note |
|---|---|---|
| Tier-1 Consumer/IoT | YES, ~8–12 mo, **with written exclusion list** | only tier reachable without ISA surgery |
| Tier-2 Industrial | SKU-2 + 12–18 mo **+ ISA growth (PMP/U-mode)** | not a rename of Tier-1 |
| Tier-3 Automotive ASIL-D | **NEVER on M1 as-is** | safety lifecycle/FMEDA/FI/cert = different product |
| Android RVA22 | **different IP class** (RV64GC+B+MMU+...) | needs new design (M2/X6), not M1 depth work |

## 2. Over-claim register (Grok+Codex+Gemini) — the honesty backbone
| Over-claim | Honest counter |
|---|---|
| "functional 100%" | 100% of **M1 own coverpoints**, NOT riscvISACOV; hazard-cross/priv only partial |
| "Spike lockstep = RVVI verified" | RVVI-**intent** via custom Python; no RVVI SV monitor / UVM / Imperas |
| "lint PASS = RTL signoff" | 0 err but **24 warn**; no CDC/RDC/X-prop/DFT — necessary not sufficient |
| "DC ~699MHz = PPA signoff" | single-corner TRIAL, 2 hold violators, vectorless — exploratory not signoff |
| "toggle 85% MVP ≈ Tier-1" | toggle **63–74%** today; Tier-1 bar is **90%** (kill the internal 85% bar) |
| "189 gates = commercial DV done" | **development** gates, not customer V-Plan/traceable signoff |

## 3. Concrete gap → action (Codex engineering + Gemini matrix), ranked for Tier-1 RV32IMC
1. **Toggle ≥90%** (now ~63–74%): WS6 — riscv-dv full-mix coverage (built) + directed RAS-depth/high-PC
   + CSR-trap battery + IFU-alignment + wrapper(cpu_m1_top) for mem_stall; minimal LEGIT waivers
   (counter/CSR-reserved) with Grok's math+spec+Codex-approval; **dual-number RAW+adjusted gate**.
2. **Line 100% / Branch ≥95% / Expr ≥90% / FSM 100%**: need licensed-sim (VCS/Questa/IMC) branch/expr/FSM
   metrics (Verilator lacks them); written exclusions for dead/unreachable.
3. **riscvISACOV mapping**: adopt riscvISACOV bins for RV32IMC_Zicsr_Zifencei; stop leading with custom 100%.
4. **DV deliverables**: V-Plan (✅ rev0.1 created) + DV signoff checklist (✅ created) + coverage report
   + regression archive + bug-tracking summary. (Customer audits these first.)
5. **RVVI-equivalent bundle**: document per-retire PC/GPR/CSR compare + replay script + golden logs as
   "RVVI-equivalent" (Option A); full RVVI-SV/UVM = customer-mandated SKU-2.
6. **Key-module SVA** (Codex set): decode legality, ALU eq, x0 immutability, CSR WARL/trap/mret,
   valid-ready stability under mem_stall, no-X-on-control, divider liveness. SymbiYosys for small blocks.
7. **Static signoff reports**: lint 24-warn burn-down to 0; CDC/RDC "N/A but reported" (single-clock);
   X-prop on control; multi-corner synth + fix 2 hold violators.

## 4. Scope decision (Grok): **stay RV32IMC depth → Tier-1; optional +PMP for SKU-2; new design_id for RVA22.**
Depth preserves the hand-off-test and the "Spike-lockstep is the real asset" narrative; breadth (RVA22)
is verification surface ×10 and competes with established IP — out of M1's lane.

## 5. Differentiation (Grok): "every signoff claim is backed by a re-runnable gate, not a static PDF."
Maps onto customer audit-trail/waiver/reproducibility requirements as a STRENGTH (journal/ADR/IDE
publish-gate producer≠approver). Does NOT substitute for: UVM reuse, RVVI-SV interop, 3rd-party
Imperas/Andes review, TÜV/SGS cert, dual-sign human waivers, riscv-arch-test PASS.

## 6. Immediate next (this informs the reorg already done + the WS6 closure already underway)
- ✅ Structure reorg to independent deliverable `design/cpu_m1/{rtl,dv,sim}` (this session) — packaging gap closed.
- ✅ V-Plan + DV signoff checklist scaffolded (honest status).
- ▶ Finish WS6 toggle to **90%** (Grok-vetted: stimulus-first, minimal LEGIT waivers, dual-number).
- ▶ riscvISACOV mapping + branch/expr/FSM metric (needs licensed sim) + lint 0-warn + CDC-N/A report.
