# Magpie_M1 — Commercial Signoff Evidence Pack

> Customer-facing signoff evidence for **Magpie_M1**, a **RV32IMC, M-mode-only embedded CPU IP +
> subsystem**. Mapped to the RISC-V 商品化 IP Coverage Signoff standard (7 sections). **Honest
> positioning**: M1 is a **correctness-qualified, compliance-100%, formally-proven embedded core**
> delivered as a core *and* an FPGA/ASIC/RTOS subsystem — with a documented UVM/RVA22 boundary (different
> SKU, not a gap).
>
> **Reproducible finality**: every numeric claim is produced by a re-runnable gate (`tests/gates/`).
> `python3 -m pytest tests/gates/ -q` reproduces the pack. Date: 2026-06-10 · Authority = Spike per-commit
> lockstep + pytest gates.

## Product summary

| | |
|---|---|
| ISA | RV32IMC_Zicsr_Zifencei, **M-mode only**; **official riscv-arch-test 74/74 = 100%** |
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
| **01 Code Coverage** | line/branch/expr/toggle/FSM | ✅ **CLOSED** | 13 island modules at Tier-2 (line 100 · branch 100 · expr ≥95 · toggle ≥95 · FSM 100), dual-number RAW+ADJUSTED. `gate_p02..p14`; integration `gate_p15..p19` (merged core.v branch 96.0%, residual attributed). |
| **02 Functional Coverage** | riscvISACOV + custom covergroup | ✅ **CLOSED** | Custom functional 72/72 bins (`gate_04_08`) + **riscvISACOV-mapped operand 103/103, value 12/12, immediate 23/23 = 100% effective** (1 justified mem-bound exclusion). `docs/reports/riscvisacov_equivalence.md`. |
| **03 Formal / SVA** | assert property formal-proven | ✅ **CLOSED** | **VC Formal FPV: core 22/22 PROVEN** (alu/forward/lsu/csr/rfu) **+ AXI4-Lite 18/18 PROVEN**, 0 CEX. `docs/reports/formal_assertions.md`. |
| **04 Coverage Exclusion / Waiver** | % after justified exclusion, DB retained | ✅ **CLOSED** | Dual-number RAW+ADJUSTED; waiver files RTL-verified, structural-only, `spike_impact:none`, **producer≠approver**; green-wash rejected (1 caught: 45%→100% real). |
| **05 DV Delivery (UVM/RVVI)** | UVM TB (≥80% reuse) + RVVI lockstep | ⚪ **DOCUMENTED DEVIATION** | Directed Verilog unit TBs + **Spike per-commit lockstep** (PC/GPR/CSR every retire) + **riscv-dv** + **official riscv-arch-test 74/74**. RVVI-equivalent audit trail; UVM wrapper is a funded Phase-B enabler, not a correctness blocker. `docs/reports/dv_methodology_equivalence.md`. |
| **06 Android RVA22** | RV64IMAFDC + Zb* + Sv39 + Sstc | ⚪ **DIFFERENT SKU** | M1 is intentionally RV32IMC M-only embedded. The applicable subset (**riscv-arch-test RV32IMC compliance**) is **CLOSED 74/74**; RVA22 (RV64/MMU/FP) is a separate application-core product, not an M1 gap. |
| **07 RTL Sign-off** | lint clean · multi-corner QoR · UPF | ✅ **CLOSED** (UPF n/a) | Lint **0/0** (`gate_05_00`). **Multi-corner DC** TT/SLOW/FAST all 699.30 MHz WNS=0 (SLOW signoff −10% margin met), power 13.1/16.1/17.5 mW (`multicorner_qor.md`). **FPGA passing bitstream** @ 50 MHz. UPF deferred (no power domains in this SKU). |

## SoC / subsystem evidence (beyond the 7-section core standard)

| Capability | Status | Evidence |
|---|---|---|
| **AXI4-Lite master** | ✅ verified | native-vs-AXI commit traces byte-identical @0/3 wait states; FPV 18/18 PROVEN. `flow/v2_pipeline/phase_p_axi`. |
| **FPGA subsystem** | ✅ deployable | PYNQ-Z2 (xc7z020) **passing bitstream @ 50 MHz**, boot ROM→BRAM→LED blink. `flow/fpga/pynq_z2/system_pynq_m1.bit`. |
| **ASIC subsystem** | ✅ verified | CPU+AXI+TSMC28 1RW1R SRAM macro, boot→MMIO PASS; DC 699.30 MHz, 42 682 µm². `flow/v2_pipeline/phase_p_asic`. |
| **RTOS subsystem (CLINT+PLIC+UART)** | ✅ verified | CLINT MTIP/MSIP (ADR-0019, mcause 0x80000007/3) + PLIC MEIP (ADR-0020, mcause 0x8000000b, claim/complete deasserts) + UART console (string captured); `cpu_m1_soc_top`, directed + highest-risk-flush corner PASS, no regression. `phase_05_02`/`phase_05_03`. |
| **Debug (RISC-V v0.13.2)** | ✅ verified | DM + DTM (JTAG) + core debug-mode + Trigger module (ADR-0021/0022). **Real OpenOCD** over JTAG: TAP enumerated, core examined, halt/resume/single-step, GPR/CSR R+W, **HW breakpoint** (`halted due to breakpoint`) + RV32C-cross-boundary trigger corner. SW+HW breakpoints + watchpoints. `phase_06_*`. |

## Honest 3-layer positioning

**Closed (truthfully claimable today):**
- §01 Tier-2 structural coverage (13 islands) + Spike-lockstep integration · §02 functional/riscvISACOV ·
  §03 VC Formal (40/40 proven) · §04 waiver discipline · §07 multi-corner DC + Spyglass 0/0.
- **Official riscv-arch-test 74/74 (RV32IMC compliance)**; 2 RV32C bugs + 1 green-wash + 2 spec bugs caught.
- **AXI4-Lite** (proven) · **FPGA bitstream** · **ASIC subsystem** · **RTOS subsystem (CLINT+PLIC+UART)** ·
  **RISC-V Debug** (DM/DTM/trigger, real OpenOCD: halt/step/HW-breakpoint/watchpoint) · CoreMark 2.690/MHz.

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
Coverage DBs, waivers (`IP/cpu_m1/dv/cov/waivers/`), ADRs (`docs/adr/0001..0019`), lockstep traces,
formal results, the FPGA bitstream, and the design report (`magpie_m1_design_report.html`) are retained
for customer audit.
