# Magpie_M1 — CPU IP & Subsystem Datasheet (v2)

> **Magpie_M1** is a clean, compliance-verified **RV32IMC_Zicsr_Zifencei, M-mode embedded CPU IP**,
> delivered both as a **core** (native or AXI4-Lite interface) and as a **drop-in compute subsystem**
> (CPU + AXI + memory + boot ROM) with FPGA and ASIC build flows. Date: 2026-06-10.
>
> Every claim below is backed by a re-runnable gate / report (`tests/gates/`, `docs/reports/`,
> `flow/v2_pipeline/`). `python3 -m pytest tests/gates/ -q` reproduces the verification evidence.

---

## 1. Overview

| | |
|---|---|
| ISA | RV32IMC_Zicsr_Zifencei, **machine-mode only** (embedded SKU) |
| Pipeline | 4-stage, in-order, single-hart; branch predictor + RAS + RV32C cross-boundary prefetch |
| Compliance | **official riscv-arch-test 74/74 (RV32I 39 + RV32M 8 + RV32C 27) = 100%** |
| Interfaces | native single-outstanding valid/ready (I/D) **and** AXI4-Lite master (M_AXI_I / M_AXI_D) |
| Debug | **RISC-V External Debug v0.13.2**: JTAG DTM + DM, halt/resume/step, SW+HW breakpoints + watchpoints; real OpenOCD/GDB |
| Delivery | CPU core · subsystem (FPGA: AXI→BRAM · ASIC: AXI→TSMC28 SRAM · CLINT: RTOS-capable) |
| Process | TSMC 28HPC+ — multi-corner DC: **699.30 MHz** (TT/SLOW/FAST, WNS=0) · ~26.8 kµm² · 13–17.5 mW |
| Performance | **CoreMark 2.690/MHz** (IPC 0.779) · FPGA PYNQ-Z2 passing bitstream @ 50 MHz |
| Quality | Tier-2 structural coverage · VC Formal proofs · Spyglass lint 0 errors / 0 warnings |
| Target apps | MCU / IoT / embedded control; **RTOS-capable** (CLINT timer + software interrupt, ADR-0019) |

---

## 2. ISA & Programmer's Model

- **Extensions**: RV32 **I** (base), **M** (mul/div), **C** (compressed), **Zicsr**, **Zifencei**.
- **Privilege**: **M-mode only**. `mstatus.MPP` is read-only WARL = M (ADR-0015). No S/U mode, no MMU/PMP.
- **M-mode CSRs**: mstatus, mie, mip, mtvec (direct mode), mepc, mcause, mtval, mscratch, mcycle/minstret.
- **Trap model**: illegal-instruction, ecall, ebreak, mret, misaligned load/store (mcause 4/6), external IRQ.
- **Compressed HINTs** execute as NOP per spec (ADR-0016 + addendum: C.LI/SLLI/MV/ADD/LUI rd=x0);
  reserved compressed encodings trap (illegal). Verified by riscv-arch-test RV32C 27/27.
- **Reset state**: PC = `RESET_PC` (parameter, default 0); x0 hardwired 0 (reset on regfile[0]).

---

## 3. Microarchitecture

4-stage in-order pipeline (IF / ID-EX / MEM / WB-class) with full forwarding (EX/MEM + EX/WB), load-use
and mul/div busy stalls, flush-vs-forward priority. Branch prediction + a return-address stack (RAS).
RV32C cross-boundary prefetch (residue buffer) assembles 32-bit instructions straddling 4-byte boundaries
with 0-cycle penalty on the predicted path (ADR-0017 hardened the redirect/stale-fetch corner).

---

## 4. Interfaces

### 4.1 Native bus (default)
Harvard, **single-outstanding, ready-gated valid/ready** I/D busses: `ibus_req/addr/ready/rdata`,
`dbus_req/addr/we/wstrb/wdata/ready/rdata`. `req` held until `ready`; `dbus_we = |dbus_wstrb`.

### 4.2 AXI4-Lite master (cpu_m1_axil_top)
Standard **AXI4-Lite masters** for SoC interconnect:
- **M_AXI_I** — instruction fetch (read-only: AR + R).
- **M_AXI_D** — data load/store (read+write: AR + R + AW + W + B).

32-bit, no bursts, single-outstanding (no ID/outstanding tracking). **Latency-tolerant** (the core stalls
via `mem_stall` until the AXI transaction completes). **Verified**: native-vs-AXI commit traces are
**byte-identical at 0 and 3 wait states**; AXI4-Lite master protocol properties **18/18 PROVEN (VC Formal
FPV, 0 CEX)**. Sticky `dbg_axi_err` surfaces non-OKAY responses.

### 4.3 Debug (RISC-V External Debug v0.13.2)
JTAG-based external debug — **real OpenOCD/GDB** connect over a 4-wire JTAG TAP:
- **DTM** (`dtm.v`): IEEE 1149.1 16-state TAP + IDCODE/DTMCS/DMI; pins `tck/tms/tdi/tdo`.
- **DM** (`dm.v`): DMI (7b-addr/32b-data), dmcontrol/dmstatus/abstractcs/command (access-register)/data;
  halt/resume/reset, abstract **GPR/CSR** read+write via a direct backdoor while halted.
- **Core debug-mode**: `dcsr`/`dpc`/`dscratch0` + **dret**; halt at a clean WB-retire boundary,
  **single-step**, IRQ masked in debug, `ebreak` → debug entry (SW breakpoints).
- **Trigger module** (`trigger.v`): **4 triggers** (mcontrol6) — **HW instruction breakpoints**
  (ROM/flash-capable, non-intrusive) + **data watchpoints** (load/store address). `tselect/tdata1/tdata2/
  tinfo`; trigger match → debug entry with `dpc` = the triggering PC; anti-re-fire on resume.
- **Verified**: real OpenOCD enumerates the TAP (IDCODE), examines the core, halts, reads GPR/CSR,
  single-steps, and sets a **HW breakpoint** (`halted due to breakpoint`). ADR-0021/0022.

### 4.4 Interrupts (RTOS-capable)
Full M-mode interrupt model: **MEIP** (`mip[11]`, external), **MTIP** (`mip[7]`, timer), **MSIP**
(`mip[3]`, software) — `mip[3,7,11]` are CLINT/external-sourced (read-only to CSR writes); `mie[3,7,11]`
SW-writable; trap priority **MEI > MSI > MTI** (priv spec). `mcause` = `0x8000_000B`/`0x8000_0007`/
`0x8000_0003`. Interrupts are taken only on a valid commit (wrong-path suppressed). The CLINT
(`clint.v`, 64-bit mtime/mtimecmp + msip, map base `0x0200_0000`) supplies MTIP/MSIP — see §5 (ADR-0019).
Clock/reset: single `clk`, active-low `resetn`.

---

## 5. CPU Subsystem (drop-in compute block)

`cpu_m1_axil_top` + memory + boot ROM, in two build-targeted variants sharing the same AXI wrapper:

| | FPGA variant (`cpu_m1_fpga_top`) | ASIC variant |
|---|---|---|
| RAM | dual-port **block RAM** (`axil_dp_bram`) | dual-port **TSMC28 SRAM macro** (`tsdn28hpcpa…`) |
| Boot ROM | LUT (`axil_bootrom`): `lui+jalr` → jump to RAM_BASE (or spin, `BOOT_DEBUG`) | small std-cell ROM |
| Map | ROM @ [0, RAM_BASE) · RAM @ RAM_BASE (0x2000_0000) | same |
| I/D share | dual-port (port A = I read, port B = D read+write) — no arbiter | same |

**Verified (FPGA)**: boot ROM → jump → program runs from RAM → MMIO write, `dbg_axi_err=0`, PASS
(Verilator). **PYNQ-Z2 (xc7z020) Vivado: passing bitstream `system_pynq_m1.bit` at 50 MHz** (all timing
met; 4 817 LUT / 9.05%) + LED blink. **Verified (ASIC)**: `cpu_m1_asic_top` boots ROM → TSMC28 1RW1R SRAM
macro → MMIO PASS; DC TSMC28HPC+ 699.30 MHz, total area 42 682 µm² (logic ~27 167 + SRAM macro 15 515).
**RTOS-capable subsystem (`cpu_m1_clint_top`)**: CLINT (MTIP/MSIP) integrated — timer + software interrupt
verified (§4.4, ADR-0019). PLIC (ext int) + UART are the next first-party-X3-RTL increment.

---

## 6. Performance

| Metric | Value | Source |
|---|---|---|
| Fmax (multi-corner) | **699.30 MHz** (TT / SLOW-ssg / FAST-ffg, all WNS=0) | DC TSMC28HPC+ `multicorner_qor.md` |
| Area | ~26.8 kµm² (gate) | DC |
| Power | 13.1 / 16.1 / 17.5 mW (SLOW/TT/FAST) | DC |
| **CoreMark/MHz** | **2.690** (CoreMark CRC-validated; iter×1e6/cycles, freq-independent) | `phase_p_coremark` |
| **IPC / CPI** | **0.779 / 1.284** (289 600 instr / 371 729 cycles) | core-sim instrumentation |
| FPGA (PYNQ-Z2 xc7z020) | **passing bitstream @ 50 MHz** (all timing met) · 4 817 LUT (9.05%); 83.3 MHz marginal (WNS −0.26 ns) | `flow/fpga/pynq_z2/system_pynq_m1.bit` |
| ASIC subsystem (CPU+AXI+T28 SRAM) | DC TSMC28HPC+ **699.30 MHz**, 42 682 µm² (logic 27 167 + SRAM macro 15 515) | `flow/v2_pipeline/phase_p_asic` |

**CoreMark/MHz cross-check (3 independent views agree)**: Codex measured 2.690; Gemini independently
recomputed 2.6901 (match); Grok's published-core baseline puts M1 in the expected RV32IMC-4-stage band:

| core | CoreMark/MHz | core | CoreMark/MHz |
|---|---|---|---|
| PicoRV32 (multi-cycle) | 0.5 | **Magpie_M1 (4-stage)** | **2.69** |
| Ibex (2-stage) | 2.44 | SiFive E31 (5-stage) | 2.73–3.17 |
| Cortex-M0+ | 2.46 | Hazard3 +Zb | 3.02 |
| ESP32-C3 (4-stage RV32IMC) | 2.55 | Cortex-M3 / M4 | 3.34 / 3.42 |

M1 (2.69) beats Ibex / Cortex-M0+ / ESP32-C3 and trails 5-stage E31 / Cortex-M3/M4 — competitive for a
4-stage in-order RV32IMC. _Numbers reported faithfully; the FPGA does not meet the 125 MHz reference
constraint (soft core on a 28nm-equivalent FPGA fabric) — re-target the FPGA clock to ≤83 MHz._

---

## 7. Verification & Signoff

| Axis | Result |
|---|---|
| **Compliance** | official **riscv-arch-test 74/74 = 100%** (RV32I 39 + RV32M 8 + RV32C 27) |
| **Code coverage** | 13 island modules at **Tier-2** (line 100 / branch 100 / expr ≥95 / toggle ≥95 / FSM 100) + integration slices Spike-lockstep-verified (merged core.v branch 96%) |
| **Functional coverage** | riscvISACOV-mapped: operand/value/immediate 100% (1 memory-bound exclusion) |
| **Formal (VC Formal FPV)** | core invariants **22/22 PROVEN** (alu/forward/lsu/csr/rfu) + AXI4-Lite **18/18 PROVEN** |
| **ISS lockstep** | Spike per-commit (PC/GPR/CSR) — the correctness authority |
| **Lint** | Spyglass **0 errors / 0 warnings** (reviewed waivers); 2 spec bugs found+fixed (ADR-0015/16) |
| **PPA** | multi-corner DC TSMC28HPC+ (above) |
| **Debug** | **real OpenOCD** over JTAG: TAP enumerated, core examined, halt/resume/single-step, GPR/CSR read+write, **HW breakpoint** (`halted due to breakpoint`) + the RV32C-cross-boundary trigger corner. ADR-0021/0022 |
| Gates | 53 pytest gates, 273 pass / 1 xfail; dual-number RAW+ADJUSTED, every waiver RTL-verified |

---

## 8. Deliverables Manifest

- **RTL**: core (`IP/cpu_m1/rtl/`: core + 13 leaf/decode/stateful modules), AXI bridge
  (`cpu_m1_axil_top`, `axil_bridge`), SoC blocks (`IP/cpu_m1/soc/`: `axil_bootrom`, `axil_dp_bram`,
  `cpu_m1_fpga_top`), board top (`flow/fpga/pynq_z2/system_pynq_m1`).
- **DV**: unit TBs, directed firmware, Spike-lockstep harness, riscv-dv, coverage DB, waiver JSON.
- **Docs**: this datasheet, ADRs (`docs/adr/`), signoff evidence pack, DV-methodology brief, debug report.
- **Reports**: coverage, multi-corner QoR, formal results, AXI verification, arch-test 74/74, lint.

---

## 9. Known Limitations & SKU Scope

- **In scope**: RV32IMC M-only embedded core + AXI/subsystem. RTOS-capable with the CLINT roadmap.
- **Out of scope (deliberate, different SKU)**: S/U mode, MMU/PMP, A/F/D extensions, RVA22 application
  profile, full UVM/RVVI deliverable, multi-port AXI4 bursts, full UPF power-domain methodology.
  Customer integration (pads, PLL, DDR, interconnect matrix, APR/STA signoff) is the SoC tier
  (cf. Magpie_X3), which consumes M1 as a `cpu_subsys` instance.
