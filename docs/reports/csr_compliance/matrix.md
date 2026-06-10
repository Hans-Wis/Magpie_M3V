# Magpie_M1 CSR/Trap Compliance Matrix

This document provides a compliance mapping between the Magpie_M1 RTL implementation (`pipeline_v2/ch2_lab08e`) and the RISC-V Privileged Specification (M-mode).

**Target ISA:** RV32IMC_Zicsr_Zifencei
**Privilege Level:** M-mode only

---

## 1. M-mode CSR Implementation Status

| CSR | Address | Implemented | WARL / Field Behavior | Compliance | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `mstatus` | `0x300` | Yes (Partial) | MIE, MPIE, MPP (2'b11). | Partial | Other fields hardwired to 0. MPP is RW but forced to 3 on trap. |
| `misa` | `0x301` | No | Returns 0. | Compliant | Optional. Returning 0 is valid but lacks discovery info. |
| `mie` | `0x304` | Yes (Partial) | MEIE (bit 11). | Partial | Only machine external interrupt enable implemented. |
| `mtvec` | `0x305` | Yes | BASE (30 bits), MODE (00). | Compliant | Direct mode only. MODE is read-only 0. |
| `mscratch` | `0x340` | Yes | 32-bit RW. | Compliant | |
| `mepc` | `0x341` | Yes | 32-bit RW. | **Non-compliant** | Bit 0 not masked on software write (IALIGN=16). |
| `mcause` | `0x342` | Yes | 32-bit RW. | Compliant | |
| `mtval` | `0x343` | Yes | 32-bit RW. | Compliant | Holds faulting addr or instr. |
| `mip` | `0x344` | Yes (Partial) | MEIP (bit 11). | Compliant | MEIP is RO to software, hardware managed pulse. |
| `mvendorid`| `0xF11` | No | Returns 0. | Compliant | 0 is valid for unknown/not-impl. |
| `marchid` | `0xF12` | No | Returns 0. | Compliant | |
| `mimpid` | `0xF13` | No | Returns 0. | Compliant | |
| `mhartid` | `0xF14` | No | Returns 0. | Compliant | |
| `mcycle` | `0xC00` | Yes | 64-bit RO. | Compliant | Via `cycle` / `cycleh` aliases. |
| `minstret` | `0xC02` | Yes | 64-bit RO. | Compliant | Via `instret` / `instreth` aliases. |

---

## 2. Field-level Detailed Checks

### `mstatus`
- **MIE** (bit 3): Machine Interrupt Enable. Functional.
- **MPIE** (bit 7): Machine Previous Interrupt Enable. Functional.
- **MPP** (bits 12:11): Machine Previous Privilege. Hardcoded to `2'b11` on trap entry.
  - *Deviation*: Software can write non-3 values via `csrrw`. In an M-mode only core, these bits should be hardwired to 3.
- **Other fields**: `SD`, `TSR`, `TW`, `TVM`, `MXR`, `SUM`, `MPRV`, `FS`, `XS` are all hardwired to 0. Correct for M-mode only RV32IMC.

### `mcause`
- **Interrupt** (bit 31): Set for external IRQ (`8000_000B`).
- **Exception Codes**:
  - `2`: Illegal Instruction
  - `3`: Breakpoint (`ebreak`)
  - `4`: Load Address Misaligned
  - `6`: Store Address Misaligned
  - `11`: Environment Call from M-mode (`ecall`)

### `mtvec`
- **BASE** (bits 31:2): 4-byte aligned base address for trap handler.
- **MODE** (bits 1:0): Hardcoded to `00` (Direct). Vectors are not supported. Software writes to bits [1:0] are masked/ignored in `csr.v` (`mtvec_base <= new_val[31:2]`).

### `mepc`
- **IALIGN**: The core supports RVC, so `IALIGN=16`. `mepc` must be 2-byte aligned.
- **Compliance Issue**: `csr.v` allows software to write values with `bit 0 = 1`. The spec requires `mepc[0]` to be always 0.

---

## 3. Trap Semantics & Flow

| Feature | RTL Implementation | Spec Compliance |
| :--- | :--- | :--- |
| **Trap Entry** | Updates `mepc`, `mcause`, `mtval`. Sets `MPIE=MIE`, `MIE=0`, `MPP=3`. | Compliant |
| **Trap Exit** | `mret` restores `MIE=MPIE`, sets `MPIE=1`. | Compliant |
| **Exception Priority** | Illegal > Misaligned > External IRQ. | Compliant |
| **Misaligned Support** | Precise traps on misaligned 16/32-bit access. | Compliant |
| **Counter Increment** | `cycle` always increments; `instret` increments on WB retire. | Compliant |

---

## 4. FINDINGS (Verify as Candidate Bugs)

### 1. [Verify] mepc LSB Masking (Spec Deviation)
In `csr.v`, `mepc_reg <= new_val` on software write does not mask `bit 0`.
- **Impact**: Software can set an illegal odd-address return target, potentially causing immediate instruction address misaligned exceptions or inconsistent fetch behavior.
- **Fix**: Mask `new_val[0]` in `csr.v`.

### 2. [Verify] Precise mepc for Synchronous Exceptions (MAJOR)
In `core.v`, `wb_sync_exception_pc` is calculated as `ex_wb_pc_r - 32'd4`.
- **Evidence**: `ex_wb_pc_r` is the PC of the instruction currently in the Write-Back stage. If that instruction causes an exception (Illegal, Ecall, Misaligned), `mepc` should point to the instruction's own address (`ex_wb_pc_r`).
- **Suspicion**: Subtracting 4 will cause `mepc` to point to the *previous* instruction (or even middle of a previous 32-bit instruction if RVC is used).
- **Impact**: `mret` will return to the wrong instruction, likely leading to an infinite loop or crash.

### 3. [Verify] mstatus.MPP WARL behavior
The `mstatus.MPP` field is a register that accepts any 2-bit value from software.
- **Requirement**: For M-mode only cores, `MPP` should be hardwired to `3`.
- **Impact**: Minor, as trap entry forces it back to `3`, but technically non-compliant with the "hardwired to 3" recommendation for M-only.

### 4. [Verify] mtvec MODE bits
Software writes to `mtvec` bits [1:0] are ignored (Direct mode only).
- **Note**: This is a valid implementation choice, but should be documented as "Direct Mode Only".

### 5. [Verify] Exception Priority Collision
The core prioritizes Illegal Instruction over Misaligned Load/Store.
- **Note**: This is compliant with the RISC-V spec priority (Instruction-level exceptions > Data-level exceptions).

---
**Verifier:** Gemini CLI (YOLO mode)
**Date:** 2026-06-08
