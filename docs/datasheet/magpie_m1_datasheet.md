# Magpie_M1 CPU IP — Datasheet & Integration Guide (Outline)

Below is the draft for `docs/datasheet/magpie_m1_datasheet.md` (~90 lines). Known signoff numbers are filled; items that need a fresh run or customer-specific binding are marked `TODO`.

---

```markdown
# Magpie_M1 — RV32 Embedded CPU IP
## Datasheet & Integration Guide

| Field | Value |
|---|---|
| Product ID | `cpu_m1` / `magpie_m1` |
| ISA | RV32IMC + Zicsr + Zifencei |
| Privilege | Machine-mode only (no U/S, no MMU/PMP) |
| Process target | TSMC 28HPC+ (digital sign-off reference) |
| Doc rev | 0.1-draft |
| Status | Commercial signoff evidence pack available; customer-facing datasheet initial release |

---

## 1. Overview

Magpie_M1 is a compact, embedded-class RV32 CPU IP for IoT, MCU, and control SoCs that need a verified RISC-V core without an application-processor MMU. The core is a 4-stage in-order pipeline with branch prediction, return-address stack (RAS), and RV32C cross-boundary instruction prefetch.

**Key features**
- RV32IMC + Zicsr + Zifencei; M-mode only
- 4-stage pipeline: Fetch → Decode → Execute → Writeback
- Hazard forwarding, load-use stalls, mul/div busy stalls
- Branch predictor + RAS; mispredict redirect
- RV32C decompress + cross-boundary 32-bit instruction assembly
- Valid/ready instruction and data memory interfaces (wrapper over fixed-latency backend)
- M-mode trap/IRQ model with 16-bit instruction `mepc` alignment support
- Spike per-commit lockstep signoff; Tier-2 structural coverage; Spyglass lint-clean

**Target applications**
- IoT edge nodes, sensor hubs, industrial MCUs
- Always-on control processors in mixed-signal SoCs
- Soft-real-time embedded firmware (no OS MMU requirement)

**Not in scope (see §8)** — RVA22 profile, U-mode/S-mode, PMP/MMU, UVM/RVVI VIP flow.

---

## 2. ISA & Programmer's Model

### 2.1 Supported extensions
| Extension | Support |
|---|---|
| RV32I | Full (M-mode subset) |
| M | Mul/div |
| C | Compressed; cross-boundary prefetch |
| Zicsr | M-mode CSRs listed below |
| Zifencei | `fence.i` |

### 2.2 M-mode CSRs (implemented)
`mstatus`, `mie`, `mip`, `mtvec`, `mepc`, `mcause`, `mtval`, `mscratch`, `mcycle`, `minstret`

- **`mstatus.MPP`**: read-only WARL, hardwired to M (ADR-0015). No delegation to less-privileged modes.
- **Compressed HINTs**: treated as NOP per ADR-0016 (architecturally inert, no trap).

### 2.3 Trap model
- Exceptions: illegal instruction, ecall, ebreak, misaligned load/store (policy per ADR), interrupts per `mie`/`mip`
- Vector: `mtvec` direct mode; `mepc`/`mcause`/`mtval` on entry; `mret` return
- Nested traps: handler behavior per project ADR/trap spec — see `design/cpu_m1/docs/spec.md`
- **IRQ timing**: level/edge hookup via top-level IRQ port; precise cycle relationship `TODO` (see integration §5.3)

### 2.4 Reset architectural state
- PC → `RESET_PC` parameter (default `TODO`, typical `0x0000_0000`)
- `mstatus.MIE=0`; CSRs per `spec.md` reset table

---

## 3. Microarchitecture

| Stage | Function |
|---|---|
| IF | PC gen, I-fetch, RV32C decompress, cross-boundary prefetch residue buffer |
| ID | Decode RV32I/M/C, reg read, branch decode |
| EX | ALU, mul/div, branch resolve, BP update |
| WB | Reg write, load data, CSR side effects |

**Hazards**: EX/MEM/WB forwarding; load-use stall; mul/div multi-cycle busy; flush on mispredict/trap.

**Branch prediction**: local predictor + RAS for returns; wrong-path suppression on redirect.

**RV32C prefetch**: PC+2/+4 cross-boundary assembly with fallback path; verified under Spike lockstep (incl. regression for cross-boundary stress — see evidence pack).

**Performance** (single-issue, no cache in IP): CPI heavily memory-bound; benchmark CPI `TODO`.

---

## 4. Interfaces

### 4.1 Clock & reset
- `clk` — single clock domain
- `rst_n` — asynchronous assert, synchronous deassert recommended

### 4.2 Instruction memory (valid/ready)
| Signal | Dir | Description |
|---|---|---|
| `imem_addr` | O | Word-aligned fetch address |
| `imem_req` | O | Request valid |
| `imem_ready` | I | Data accepted / valid |
| `imem_rdata` | I | 32-bit instruction data |
| `imem_rvalid` | I | Read data valid (timing per wrapper spec) |

Fixed-latency backend: tie `ready`/`rvalid` per integration §5.2.

### 4.3 Data memory (valid/ready)
| Signal | Dir | Description |
|---|---|---|
| `dmem_addr` | O | Byte address |
| `dmem_we` | O | Write enable |
| `dmem_wdata` | O | Store data |
| `dmem_be` | O | Byte enables |
| `dmem_req` | O | Request valid |
| `dmem_ready` | I | Transaction complete |
| `dmem_rdata` | I | Load data |

**Misalign**: load/store misalignment traps with `mcause` 4/6 per signoff evidence.

### 4.4 Interrupts
- `irq_i[N-1:0]` — external IRQ vector; width `N = TODO` (see `spec.md`)
- Synchronization: `TODO` cycles from assert to trap entry

### 4.5 Debug / trace (optional)
- Commit-trace export for cosim — not part of production netlist unless enabled by parameter `TODO`

---

## 5. Integration Guide

### 5.1 Instantiation checklist
1. Set `RESET_PC` to boot ROM or SRAM base.
2. Connect imem/dmem to SRAM controllers or bus bridges (AHB/APB fabric outside IP).
3. Route `irq_i` from peripheral aggregator; ensure `mie`/`mip` software enable path.
4. Provide constant or programmable clock; meet §6 timing at SoC corner of interest.

### 5.2 Memory map expectations
| Region | Typical use |
|---|---|
| `RESET_PC` | Boot vectors / init code |
| Code | Executable ROM or XIP flash behind imem wrapper |
| Data | RW SRAM behind dmem wrapper |

Magpie_M1 does not include an internal memory map decoder — SoC must decode addresses and honor imem/dmem protocol.

**Fixed-latency shim** (example): 1-cycle SRAM — assert `imem_ready`/`imem_rvalid` and `dmem_ready` with documented phase relation in `design/cpu_m1/docs/spec.md`.

### 5.3 Reset sequence
1. Assert `rst_n=0` for ≥ `TODO` cycles.
2. Deassert `rst_n`; core fetches from `RESET_PC`.
3. Software init: setup `mtvec`, stack pointer (`x2`), `mie` as needed before enabling interrupts.

### 5.4 Parameters
| Parameter | Default | Description |
|---|---|---|
| `RESET_PC` | `TODO` | Reset program counter |
| `IRQ_WIDTH` | `TODO` | Width of `irq_i` |

### 5.5 Clocking
- Recommended operating frequency at TSMC28 TT, 0.9V nominal: up to **~699 MHz** post-synthesis (see §6); SoC must close timing on imem/dmem paths.

---

## 6. Verification & Signoff Summary

Signoff authority: **Spike per-commit lockstep** + pytest development gates + structural coverage + lint/synth trial.

| Item | Result | Evidence |
|---|---|---|
| Spike lockstep | Pass (per-commit equivalent) | Commercial Signoff Evidence Pack — `flow/sim/lockstep/` |
| Development gates | 176/176 pass | `tests/gates/`, `flow/state/*.state.json` |
| Functional coverage | Tier-2, 72/72 goals (100%) | Coverage DB in evidence pack |
| Line/toggle coverage | Tier-2 structural | URG/Verilator artifacts — `flow/sim/coverage/` |
| Spyglass lint | 0 errors | Lint report in evidence pack |
| DC synthesis PPA (TT, single corner) | ~699 MHz, ~26805 µm², ~16 mW | `flow/synth/` — confirm exact corner/Vt in report |

**Caveat**: PPA is single-corner trial, not full SS/FF signoff (see §8). Re-verify at SoC top level.

---

## 7. Deliverables Manifest

| Category | Path / artifact |
|---|---|
| RTL | `design/cpu_m1/rtl/` + `design/cpu_m1/dv/sim/*.f` filelist |
| IP manifest | `design/cpu_m1/ip.json` |
| DV | `design/cpu_m1/dv/tb/`, `dv/fixtures/`, gate tests `tests/gates/` |
| Documentation | `design/cpu_m1/docs/spec.md`, `docs/adr/`, this datasheet |
| Coverage | Tier-2 DB + exclusion/waiver list `TODO path` |
| Waivers | Spyglass/coverage waivers with justification |
| ADRs | Architecture decisions (`docs/adr/0001`–`0016` relevant set) |
| Evidence pack | `flow/state/`, `flow/sim/`, synth/lint logs — IDE report via `platform/design-ide` |

**Delivery format**: encrypted RTL `TODO` / plain RTL per license agreement.

---

## 8. Known Limitations & SKU Scope

**In scope (this SKU)**
- RV32IMC + Zicsr + Zifencei, M-mode only
- Valid/ready memory wrappers; external IRQ
- TSMC28HPC+ reference PPA (single TT corner)

**Known limitations**
- No MMU, no PMP, no S/U privilege — flat M-mode only
- No RVA22 profile compliance claim
- No built-in cache, TCM, or bus fabric
- Multi-corner timing (SS/FF), UPF/low-power flow, and vectorless power signoff: **not** part of this SKU
- DV collateral is Verilator/Spike/pytest oriented — **no** UVM/RVVI VIP deliverable

**Non-goals**
- 64-bit (RV64), A extension, custom CSRs beyond documented set
- Formal equivalence / CDC signoff beyond Spyglass lint scope `TODO`

For integration support and evidence-pack access, contact `TODO`.
```

---

This skeleton is ready to drop into `docs/datasheet/magpie_m1_datasheet.md`. The main `TODO` buckets are: exact `RESET_PC`/IRQ width, IRQ latency cycles, delivery/licensing format, waiver paths, and any customer-specific memory-timing figures from `spec.md`.

I did not write the file (per your no-tools instruction). Say if you want this committed and the `TODO`s filled from the repo.
