> **M1A REV (2026-06-12, design_id=cpu_m1a)** — this document is INHERITED from frozen M1 with the
> following deltas; the authoritative current-state evidence is `docs/reports/m1a_tier2_evidence_pack.md`.
> SKU-1 ISA extends to RV32IMC+Zb+Zicond per ADR-0026 (A2 gates green); perf baseline CoreMark/MHz 3.23 (O3+Zb)/2.74 (O2), MACSTREAM 3.63 c/MAC; ERRATA-0001 FIXED on this line.

# cpu_m1 — Feature Freeze / SKU Contract Declaration

Rev 1.0 · 2026-06-11 · Owner: PL (Claude) · design_id = `cpu_m1`
Purpose: the honest, customer-facing scope contract for Tier-2 (Industrial) acceptance. Tier-2 coverage
and sign-off claims apply **only** to the IN-SCOPE deliverable; everything else is OUT-of-scope (SoC
integrator) or OPTIONAL (config-gated) and must not inherit core sign-off evidence.

This freeze is the §05/§09 deliverable the customer-acceptance review (Gemini+Grok) flagged as missing.
After this freeze, any RTL change re-runs the affected coverage/formal (closed-loop, per standard §09).

## SKU-1 (acceptance target) — IN SCOPE: RV32IMC core
- **ISA**: RV32I + M + C + Zicsr (M-mode CSRs) + Zifencei (FENCE.I). Privilege: **M-mode only**.
- **Microarch**: 4-stage in-order pipeline + branch predictor + RAS + RV32C cross-boundary prefetch.
- **Memory IF**: native valid/ready (I/D) fixed-latency wrapper; load/store byte-lane, sign/zero-ext,
  misalign trap policy (mcause 4/6).
- **Traps/IRQ**: illegal / ecall / ebreak / mret; external interrupt (MEI via `irq_external_pulse`).
- **Correctness authority**: Spike per-commit lockstep + pytest gates.

## OPTIONAL (config-gated, separately verified — NOT in the base acceptance number)
- **RV32A** (`RV32A=0/1`, ADR-0023) — LR/SC + AMO. Default `RV32A=0` == base RV32IMC.
- **PMP** (`PMP_ENTRIES=0/4/8`, ADR-0024) — TOR/NA4/NAPOT.
- Each optional config requires its **own gated lockstep + coverage closure** before it may be marketed
  as Tier-2 verified. Today: directed sim only → **NOT Tier-2 closed** (gap doc §1).

## OUT OF SCOPE — SoC integrator responsibility (not part of CPU-core Tier-2 sign-off)
- **CLINT / PLIC / UART** peripheral subsystem (ADR-0019/0020) — directed sim only.
- **Debug Module / DTM / Trigger** (ADR-0021/0022) — directed + OpenOCD smoke only; no gate/lockstep.
- **AXI4-Lite** bridge — proven (FPV 18/18) but a bridge, not the core ISA contract.
- **FPGA / ASIC** subsystems — integration demonstrators.
- If the customer contract includes any of these, they move to SKU-2 with their own V-Plan rows and gates.

## DELIBERATE NON-GOALS (unless funded → new SKU)
- S/U-mode, Sv32/Sv39 MMU, F/D/B/V/Crypto, async MTI/MSI random closure at scale.
- Full UVM/SV + RVVI-standard interface; RVA22 application profile / RV64; ISO 26262 ASIL safety (Tier-3).
- UPF multi-domain power methodology; DFT scan (no DFT in this SKU unless contracted).

## Two valid acceptance contracts (customer picks)
1. **Full Tier-2** — close all gap-doc §3 blockers (toggle/expr/branch to bars+waivers, expanded
   lockstep, through-trap per-commit, CDC/RDC/X-prop, formal coverage ≥90%, no xfails). ~4–6 weeks.
2. **Tier-2-Narrow (RV32IMC core-only)** — this freeze as-is: no DM, no A, integrator owns interrupt
   controller; coverage closed on the core + signed §04 waivers; honest deviations documented. ~2 weeks.

Version lock: tie this freeze to the git SHA at acceptance; Databook/Register-Map freeze accompanies it.
