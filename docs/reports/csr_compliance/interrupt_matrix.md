# Magpie_M1 Interrupt/IRQ Compliance Matrix

**Project:** Magpie_M1 (RV32IMC_Zicsr)  
**Scope:** M-mode Privileged Interrupts  
**Reference:** RISC-V Privileged Specification (v20190608)  
**Source RTL:** `csr.v`, `core.v` (Ch2 lab08e)

## 1. M-Mode Interrupt CSR Compliance

| CSR Field | Bits | Implemented? | WARL / Behavior | Compliance Note |
|:---|:---:|:---:|:---|:---|
| `mstatus.MIE` | 3 | Yes | RW | Standard M-mode Interrupt Enable. |
| `mstatus.MPIE` | 7 | Yes | RW | Saves MIE on trap entry; restored on `mret`. |
| `mstatus.MPP` | 12:11 | Yes | WARL | Fixed to `2'b11` (M-mode only). Correct for this IP. |
| `mie.MEIE` | 11 | Yes | RW | M-mode External Interrupt Enable. |
| `mie.MTIE` | 7 | No | Fixed 0 | Machine Timer Interrupt not implemented. |
| `mie.MSIE` | 3 | No | Fixed 0 | Machine Software Interrupt not implemented. |
| `mip.MEIP` | 11 | Yes | RO | Reflected from hardware `ext_pending` latch. |
| `mip.MTIP` | 7 | No | Fixed 0 | N/A |
| `mip.MSIP` | 3 | No | Fixed 0 | N/A |
| `mtvec.base` | 31:2 | Yes | RW | 4-byte aligned base address. |
| `mtvec.mode` | 1:0 | No | Fixed 00 | **Direct Mode only**. Vectored mode not implemented (MODE is WARL). |
| `mepc` | 31:0 | Yes | RW | LSB masked to 0 on write. |
| `mcause.Int` | 31 | Yes | RO | Set on interrupt entry. |
| `mcause.Code`| 30:0 | Yes | RO | `11` for External Interrupt. |

---

## 2. Interrupt-Entry Semantics

| Feature | RTL Implementation | Compliance |
|:---|:---|:---:|
| **Firing Condition** | `irq_pending = ext_pending & mie_meie & mstatus_mie` | **PASS** |
| **Commit Boundary** | Interrupt taken in WB stage (`wb_take_irq`). | **PASS** |
| **mstatus Update** | `MPIE <- MIE`, `MIE <- 0`, `MPP <- 3` | **PASS** |
| **mcause Update** | `32'h8000_000B` (Interrupt bit + Code 11) | **PASS** |
| **mepc Update** | **CRITICAL BUG**: Saves `PC+4` (or branch target). | **FAIL** |
| **Priority** | Sync Exceptions > Data Traps > External IRQ. | **PASS** |

### Priority Details
RTL in `core.v` prioritizes synchronous traps within the same instruction cycle in WB:
1. `wb_take_sync_trap` (Illegal, Ecall, Ebreak)
2. `wb_take_data_trap` (Misaligned Load/Store)
3. `wb_take_irq` (External Interrupt)

---

## 3. Interrupt Return (mret)

| Action | RTL implementation | Compliance |
|:---|:---|:---:|
| **PC Restore** | `pc_redirect` to `mepc`. | **PASS** |
| **MIE Restore** | `MIE <- MPIE`. | **PASS** |
| **MPIE Set** | `MPIE <- 1`. | **PASS** |
| **MPP Restore** | `MPP <- 3` (Fixed M-mode). | **PASS** |

---

## 4. Findings & Candidate Bugs

### [CRITICAL] mepc Corruption on Interrupts
*   **Observation**: In `core.v`, the logic for `wb_trap_pc_for_mepc` for an interrupt uses the "Next PC" (e.g., `ex_wb_pc_plus_4_r` or branch target).
*   **Impact**: When an interrupt is taken, the instruction currently in the WB stage is **cancelled** (`wb_instr_retired` goes low). However, `mepc` points to the *following* instruction. Upon `mret`, the cancelled instruction is **skipped**.
*   **Fix**: For interrupts, `mepc` must save `ex_wb_pc_r` (the address of the instruction that was about to retire but was preempted).

### [MEDIUM] Clock Domain Crossing (CDC) Risk on `irq_external_pulse`
*   **Observation**: `irq_external_pulse` is sampled directly by `always @(posedge clk)` in `csr.v` to set the `ext_pending` latch.
*   **Impact**: If the external interrupt source (e.g., a button or async peripheral) is not synchronized to the core clock, this can lead to metastability in the `ext_pending` register.
*   **Evidence**: No visible synchronizer chain in `csr.v` or `core.v`.

### [LOW] Non-Standard `mip.MEIP` Sticky Behavior
*   **Observation**: `ext_pending` (MEIP) is a hardware latch that is **auto-cleared** by `trap_enter`.
*   **Impact**: In standard RISC-V, `MEIP` is a level-sensitive reflection of the interrupt signal (e.g., from a PLIC). Software typically clears the source at the peripheral. Magpie_M1 treats it as a pulse-triggered sticky bit.
*   **Note**: This is acceptable for a simplified SoC but may cause issues with standard drivers expecting level-triggered behavior.

### [NOTE] mtvec MODE WARL
*   **Observation**: `mtvec[1:0]` is hardcoded to `00`. 
*   **Impact**: Writing to `mtvec` to enable Vectored mode will be silently ignored (WARL compliance). This is compliant but restricts functionality.
