> **M1A REV (2026-06-12, design_id=cpu_m1a)** — this document is INHERITED from frozen M1 with the
> following deltas; the authoritative current-state evidence is `docs/reports/m1a_tier2_evidence_pack.md`.
> V-Plan rows: ISA = RV32IMC+Zba/Zbb/Zbs/Zicond (misa 0x40001106); Zb stimulus = directed (phase_a2) + farm injection; new units bmu/dtcm rows per gate_a2/gate_a3.

# cpu_m1 Verification Plan (V-Plan) — RV32IMC_Zicsr_Zifencei, M-mode

Rev 0.2 (2026-06-11). Owner: PL (Claude). Authority = Spike per-commit lockstep + pytest gates.
This V-Plan maps each RTL feature → test → coverage, with HONEST status. It is the customer-facing
trace matrix the agent reviews flagged as MISSING. Acceptance target = **Tier-2 (Industrial), RV32IMC
SKU-1** per `FEATURE_FREEZE.md`. Current state is **below Tier-2** — see the full gap+closure plan in
`docs/reports/tier2_acceptance_gap_and_closure.md` and the per-row status in `DV_SIGNOFF_CHECKLIST.md`
(rev 0.2). Optional A/PMP and SoC peripherals (CLINT/PLIC/UART/Debug) are scoped in `FEATURE_FREEZE.md`.

## Scope (and explicit exclusions — required for justified coverage)
- IN: RV32I, M, C, Zicsr (M-mode CSRs), Zifencei (FENCE.I), sync traps (illegal/ecall/ebreak/mret),
  external interrupt (MEI via irq_external_pulse), fixed-latency valid/ready memory.
- OUT (documented, not silently waived): S/U-mode, Sv32/Sv39 MMU, PMP, Debug Module, A/F/D/B/V/Crypto,
  async MTI/MSI (deferred to Gold SKU, ADR-0012). => M1 CANNOT claim full Priv-spec / RVA22 / safety tiers.

## Feature → Test → Coverage trace
| Feature | RTL | Test (flow phase) | Coverage | Status |
|---|---|---|---|---|
| IF + RV32C + cross-boundary prefetch | ifu.v, cdec.v, core.v | phase_01_01, phase_03_10 fence | line/toggle + cross cg | PASS (lockstep) |
| Decode + ALU + M (mul/div) | idu.v, alu.v, mul.v, div.v | phase_01_02, phase_03_07 | cg_alu_m_funct | PASS |
| Hazard: forward/load-use/md-busy/flush | forward.v, hazard.v, core.v | phase_01_03 | cg_hazard_flush | PARTIAL (cross-hazard shallow) |
| BP + RAS + redirect | bp.v, ras.v, core.v | phase_01_04, phase_04_02/06 | cg_branch_jump_bp_ras | PASS; toggle low (RAS) |
| CSR + M-mode trap | csr.v, core.v | phase_02_00, phase_03_01 | cg_csr_trap | PASS (M-mode only) |
| FENCE.I (Zifencei) | idu.v, core.v | phase_03_10 directed lockstep | (coverpoint pending) | PASS |
| mem valid/ready wrapper + misalign | cpu_m1_top.v, lsu.v | phase_02_01/02 | — | PASS |
| Spike lockstep (directed+random) | full | phase_03_*, phase_03_09 riscv-dv | per-commit PC/GPR/CSR | PASS (sync mix incl real CSR) |

## Coverage goals vs current (customer Tier-1 bars)
| Metric | Tier-1 bar | M1 current | Status |
|---|---|---|---|
| Line | 100% | ~77–95% (by module/build) | GAP |
| Branch | 95% | not separately reported | MISSING-METRIC |
| Expr/Condition | 90% | not measured (Verilator) | MISSING-METRIC |
| **Toggle** | **90%** | **~63–74% (WS6 in progress)** | **GAP (tracked: gate_04_09 xfail)** |
| FSM state+arc | 100% | not separately reported | MISSING-METRIC |
| Functional (riscvISACOV) | 95% bins | 100% on **own** coverpoints (NOT riscvISACOV) | GAP (re-language) |

## Pending V-Plan / deliverable items (to reach Tier-1)
Coverage report (per-block + exclusions), regression archive, DV signoff checklist (see sibling file),
bug-tracking summary, riscvISACOV mapping, RVVI-equivalent replay bundle, key-module SVA, lint 0-warn,
CDC/RDC/X-prop reports. See docs/reports/dv_roadmap/commercialization_decision.md for the staged plan.
