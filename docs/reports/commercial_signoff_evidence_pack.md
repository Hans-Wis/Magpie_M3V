# Magpie_M1 — Commercial Signoff Evidence Pack

> ⚠️ **Tier-2 acceptance status (2026-06-11): NOT signable today.** This pack is an **evidence
> inventory**, not a Tier-2 sign-off claim. An independent customer-acceptance review (Gemini + Grok)
> found genuine closure on the execution path but **real whole-core coverage gaps and missing sign-off
> deliverables**. Read this pack together with the authoritative gap+closure plan:
> [`tier2_acceptance_gap_and_closure.md`](tier2_acceptance_gap_and_closure.md). Where a row below says
> "CLOSED", it is qualified there as **per-island vs whole-core**. Do not read any §n cell as Tier-2
> customer acceptance.

> Customer-facing evidence for **Magpie_M1**, a **RV32IMC, M-mode-only embedded CPU IP + subsystem**.
> Mapped to the RISC-V 商品化 IP Coverage Signoff standard (Tier-2 Industrial target). **Honest
> positioning**: M1 is a **correctness-qualified (Spike lockstep), compliance-100% (arch-test 74/74),
> formally-proven (VC Formal 40/40) embedded core** delivered as a core *and* an FPGA/ASIC/RTOS
> subsystem — but **below Tier-2 customer acceptance** pending the closure items in the gap doc.
>
> **Reproducibility**: the *core-flow* numeric claims are produced by re-runnable gates (`tests/gates/`,
> `python3 -m pytest tests/gates/ -q`). NOTE: the SoC-subsystem rows (debug / RV32A / PMP / PLIC / UART)
> are **directed sim only — not yet gate-backed or lockstep/coverage-closed** (see gap doc §1, §3).
> Date: 2026-06-10 (rev 2026-06-11 honesty reconciliation) · Authority = Spike per-commit lockstep + pytest gates.

## Product summary

| | |
|---|---|
| ISA | **RV32IMC** (default) / **RV32IMAC** (optional A) + optional **PMP**, M-mode only; **official riscv-arch-test 74/74 = 100%** |
| Microarch | 4-stage pipeline + branch predictor + RAS + RV32C cross-boundary prefetch |
| Interfaces | native valid/ready (I/D) **+ AXI4-Lite master** (M_AXI_I/D, formally proven) |
| Subsystem | **FPGA** (PYNQ-Z2 bitstream @ 50 MHz) · **ASIC** (CPU+AXI+TSMC28 SRAM, 699 MHz) · **RTOS** (CLINT+PLIC+UART) · **JTAG debug** (OpenOCD/GDB) |
| Performance | **CoreMark 2.690/MHz**, IPC 0.779 (3-way cross-checked; competitive vs Ibex/Cortex-M0+/ESP32-C3) |
| Process | TSMC 28HPC+ — **multi-corner** DC: 699.30 MHz (TT/SLOW/FAST, WNS=0) · ~26.8 kµm² · 13–17.5 mW |
| Verification authority | Spike per-commit lockstep + 53 pytest gates (273 pass / 1 xfail) |
| RTL quality | Spyglass lint **0 errors / 0 warnings**; 2 spec bugs found+fixed via lint |

## Section-by-section evidence vs the standard

| # | Standard (Tier-2) | M1 status | Evidence (re-runnable) |
|---|---|---|---|
| **01 Code Coverage** | line/branch/expr/toggle/FSM | 🟡 **PARTIAL — islands closed, whole-core gap** | **Per-island (`gate_p02..p14`)**: 13 modules at Tier-2 (line 100 · branch 100 · expr ≥95 · toggle ≥95 · FSM 100). **Whole-core (the number a customer signs)**: line ~95.95%, branch ~96%, expr ~79%, **toggle 62.93%** — below Tier-2 (100/100/95/95). Toggle tracked behind `gate_04_09` `@pytest.mark.xfail`. Close via stimulus + §04 waivers; see gap doc §3. |
| **02 Functional Coverage** | riscvISACOV + custom covergroup | ✅ **CLOSED** | Custom functional 72/72 bins (`gate_04_08`) + **riscvISACOV-mapped operand 103/103, value 12/12, immediate 23/23 = 100% effective** (1 justified mem-bound exclusion). `docs/reports/riscvisacov_equivalence.md`. |
| **03 Formal / SVA** | assert property formal-proven | ✅ **CLOSED** | **VC Formal FPV: core 22/22 PROVEN** (alu/forward/lsu/csr/rfu) **+ AXI4-Lite 18/18 PROVEN**, 0 CEX. `docs/reports/formal_assertions.md`. |
| **04 Coverage Exclusion / Waiver** | % after justified exclusion, DB retained | ✅ **CLOSED** | Dual-number RAW+ADJUSTED; waiver files RTL-verified, structural-only, `spike_impact:none`, **producer≠approver**; green-wash rejected (1 caught: 45%→100% real). |
| **05 DV Delivery (UVM/RVVI)** | UVM TB (≥80% reuse) + RVVI lockstep | ⚪ **DOCUMENTED DEVIATION** | Directed Verilog unit TBs + **Spike per-commit lockstep** (PC/GPR/CSR every retire) + **riscv-dv** + **official riscv-arch-test 74/74**. RVVI-equivalent audit trail; UVM wrapper is a funded Phase-B enabler, not a correctness blocker. `docs/reports/dv_methodology_equivalence.md`. |
| **06 Android RVA22** | RV64IMAFDC + Zb* + Sv39 + Sstc | ⚪ **DIFFERENT SKU** | M1 is intentionally RV32IMC M-only embedded. The applicable subset (**riscv-arch-test RV32IMC compliance**) is **CLOSED 74/74**; RVA22 (RV64/MMU/FP) is a separate application-core product, not an M1 gap. |
| **07 RTL Sign-off** | lint · CDC/RDC/X-prop · multi-corner QoR · DFT · UPF | 🟡 **PARTIAL** | ✅ Lint **0/0** (`gate_05_00`). ✅ **Multi-corner DC** TT/SLOW/FAST 699.30 MHz **WNS=0 (setup)**, power 13.1/16.1/17.5 mW (`multicorner_qor.md`). ⬜ UPF n/a (single power domain — needs signed N/A). **Open**: ❌ **2 APR hold violators** (WNS=0 is setup only), ❌ **no CDC / RDC / X-prop report**, ❌ **no DFT scan** (`multicorner_qor.md` states "no scan/DFT"). Not RTL-signoff-complete; see gap doc §3. |

## SoC / subsystem evidence (beyond the 7-section core standard)

> **Maturity caveat (2026-06-11):** "✅ verified" below means **directed simulation passed** (and, where
> noted, Spike lockstep on the directed program). It does **NOT** mean gate-backed regression, coverage
> closure, or constrained-random lockstep. There are **no `tests/gates/` gates** for debug / RV32A / PMP /
> PLIC / UART yet, so these rows are not reproduced by `pytest tests/gates/`. For Tier-2 acceptance each
> must be either promoted to a gated lockstep+coverage phase **or** declared SoC-integrator scope in the
> Feature Freeze. See `tier2_acceptance_gap_and_closure.md` §1/§3.

| Capability | Status | Evidence |
|---|---|---|
| **AXI4-Lite master** | ✅ verified | native-vs-AXI commit traces byte-identical @0/3 wait states; FPV 18/18 PROVEN. `flow/v2_pipeline/phase_p_axi`. |
| **FPGA subsystem** | ✅ deployable | PYNQ-Z2 (xc7z020) **passing bitstream @ 50 MHz**, boot ROM→BRAM→LED blink. `flow/fpga/pynq_z2/system_pynq_m1.bit`. |
| **ASIC subsystem** | ✅ verified | CPU+AXI+TSMC28 1RW1R SRAM macro, boot→MMIO PASS; DC 699.30 MHz, 42 682 µm². `flow/v2_pipeline/phase_p_asic`. |
| **RTOS subsystem (CLINT+PLIC+UART)** | ✅ verified | CLINT MTIP/MSIP (ADR-0019, mcause 0x80000007/3) + PLIC MEIP (ADR-0020, mcause 0x8000000b, claim/complete deasserts) + UART console (string captured); `cpu_m1_soc_top`, directed + highest-risk-flush corner PASS, no regression. `phase_05_02`/`phase_05_03`. |
| **Debug (RISC-V v0.13.2)** | ✅ verified | DM + DTM (JTAG) + core debug-mode + Trigger module (ADR-0021/0022). **Real OpenOCD** over JTAG: TAP enumerated, core examined, halt/resume/single-step, GPR/CSR R+W, **HW breakpoint** (`halted due to breakpoint`) + RV32C-cross-boundary trigger corner. SW+HW breakpoints + watchpoints. `phase_06_*`. |
| **RV32A atomics (optional)** | ✅ verified | LR/SC + AMO via parameter `RV32A` (ADR-0023). RV32A=1: arch-test 74/74 + directed LR/SC + all AMO + misaligned→mcause6 + stall-plus-IRQ reservation corner + Spike lockstep. `phase_07_00`. (RV32A=0 default == original.) |
| **PMP (optional)** | ✅ verified | up to 8 regions via `PMP_ENTRIES` (ADR-0024, adapted ibex_pmp.sv Apache-2.0). PMP=8: directed TOR/NA4/NAPOT R/W/X allow+deny → access fault mcause 1/5/7 + mtval + lowest-index priority + locked-M deny + fetch-fault-on-RVC precise mepc. `phase_07_10`. |
| **Configurability** | ✅ verified | ibex-style params RV32A (0/1) + PMP_ENTRIES (0/4/8); per-config matrix re-verified: default RV32IMC == original (273 gates + arch-test 74/74), RV32IMAC + PMP=8 each pass. Customer picks PPA/area config. |

## Honest 3-layer positioning

**Closed (truthfully claimable today):**
- §01 Tier-2 structural coverage (13 islands) + Spike-lockstep integration · §02 functional/riscvISACOV ·
  §03 VC Formal (40/40 proven) · §04 waiver discipline · §07 multi-corner DC + Spyglass 0/0.
- **Official riscv-arch-test 74/74 (RV32IMC compliance)**; 2 RV32C bugs + 1 green-wash + 2 spec bugs caught.
- **AXI4-Lite** (proven) · **FPGA bitstream** · **ASIC subsystem** · **RTOS subsystem (CLINT+PLIC+UART)** ·
  **RISC-V Debug** (DM/DTM/trigger, real OpenOCD: halt/step/HW-breakpoint/watchpoint) · CoreMark 2.690/MHz.
- **Configurable ISA**: RV32IMC (default == original) / **RV32IMAC** (optional A) + optional **PMP** — each
  config independently re-verified (default == original on the full corpus); customer picks by PPA/area.

**Near-term closeable (funded increments):**
- ASIC SRAM tiling to 16 KB · FPGA pipelining to clear 83 MHz · whole-core riscv-dv ≥100k-commit campaign ·
  end-to-end OpenOCD-on-FPGA · debug trigger scale-up (more triggers / SBA / program buffer).

**Deliberate non-goals (unless funded):**
- Full UVM/SV + RVVI-standard interface (§05) · RVA22 application profile / RV64 / MMU / FP (§06) ·
  full UPF power-domain methodology (§07) · multi-port AXI4 bursts.

## How to reproduce
```
python3 -m pytest tests/gates/ -q                 # 53 gates (273 pass / 1 xfail)
# arch-test 74/74, AXI equiv, formal, multi-corner, CLINT directed, FPGA bitstream, ASIC DC:
#   flow/v2_pipeline/phase_p_archtest | phase_p_axi | phase_p_formal | phase_p_multicorner_dc
#   phase_05_02_clint_directed | ../fpga/pynq_z2 | phase_p_asic
```
Coverage DBs, waivers (`design/cpu_m1/dv/cov/waivers/`), ADRs (`docs/adr/0001..0019`), lockstep traces,
formal results, the FPGA bitstream, and the design report (`magpie_m1_design_report.html`) are retained
for customer audit.
