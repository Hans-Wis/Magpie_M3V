# Gemini full-context review 2026-07-04 — ADR-0034/0035 backfill + replaceability cross-check + Coral vector dossier

> Run mode: background + file-polling (User-directed pattern), single-shot inlined prompt, gemini-3.1-flash.

## A. Backfill Review — ADR-0034 + ADR-0035

### 1. Contract Consistency Analysis
The architectural contracts defined in **ADR-0034** (scalar core integration) and **ADR-0035** (command queue implementation) are highly consistent with each other, the ISA contract, and the existing gap review, while establishing an elegant, pragmatically adjusted offload model compared to the Google Coral NPU (Kelvin).

*   **Memory-Map & Address Decoding Harmony:** ADR-0034 establishes a flat, core-local Harvard memory map where unified TCM starts at `0x0000_0000` and the `DONE` mailbox resides at `0x0001_0000` (triggered when the core's data bus decodes `addr[16]==1`). ADR-0035 extends this decode logic to `addr[17]==1` for the NPU-local CSR mirror window at `0x0002_xxxx`. Because the address bits are clean and orthogonal (bit 16 for mailbox, bit 17 for CSRs), there are no decoding collisions between the sequencer's control loop and its termination register.
*   **Offload Loop & Termination Consistency:** In Coral's native offload loop, the host releases the core via a clock-gate control register (`io_cg = resetReg[1]` in `04_core_assembly_debug.sv`), and the core executes a custom `mpause` instruction to assert `io_halted` and signal completion. M3V replaces clock-gating with reset-gating (`core_resetn = resetn & CTRL.start`) and maps completion to a standard MMIO store to the `DONE` mailbox (`0x0001_0000`), which latches `STATUS.npu_done` and fires an IRQ. This deviation from Coral is extremely elegant: it avoids the need to implement custom compiler assembly patches for `mpause`, enabling standard, open-source compiler toolchains (`clang`/`gcc`) to compile the sequencer's firmware out-of-the-box.
*   **TCM Porting & Arbitration Safety:** In ADR-0034, reads from TCM require no arbitration, while writes utilize a fixed priority scheme: `dma_w > core_dbus > host`. ADR-0035's command queue requires the sequencer core to poll shared memory (`0x8000_xxxx`) and program the `npu_dma` read engine to fetch descriptors and weights into the TCM scratchpad (fixed at TCM byte `0x400`). When the DMA writes these weights, the core's data bus is stalled natively via `mem_stall` (`dbus_ready=0`). This ensures complete data integrity during high-throughput DMA bursts without requiring complex, cycle-accurate handshakes or phase-switching FSMs.
*   **Error Handling & State Recovery:** Under ADR-0035, decoding a `MAT.OP` (0x03) or `MAT.RESCALE` (0x04) command triggers an immediate `ENGINE_NOT_READY` (0x04) halt. This freezes `CQ_HEAD`, sets `CQ_STATUS.err=1`, and inhibits `npu_done`. Recovery is initiated by toggling `CQ_CTRL` (enable-toggle). Although the true `soft_reset` and abort-drain paths are stubs (deferred to P0⑤), the error-latching state machine is fully consistent with the simplified reset-gating of ADR-0034.

### 2. Omissions & Parity Deviations
*   **Claims Unbacked by RTL:** There are no false or over-claimed capabilities. Both ADRs are rigorously honest: ADR-0035 explicitly states that `RING_OVERRUN` (0x03) detection is not implemented in the firmware (relying on host discipline instead) and that `DMA_FAULT` (0x05) is only exercised at the DMA engine level rather than the command-queue level. It also confirms that matrix execution opcodes halt on errors because the physical matrix engines are absent.
*   **Unrecorded Coral-Parity Deviations:** All significant architectural compromises are fully documented. The split 8KB ITCM / 32KB DTCM 128-bit memory configuration of Kelvin is reduced to a unified 4KB TCM with a 32-bit port in ADR-0034; however, this is correctly filed under the P1 road-map scope-cut, as the host-facing 64KB window matches the eventual target layout.

### 3. Explicit Consistency Declarations
*   **ADR-0034 Consistency Statement:** ADR-0034 is highly consistent with the ISA contract and Coral's offload model, providing a simplified MMIO-based completion protocol rather than Coral's custom `mpause` instruction to ensure standard toolchain compatibility, while honestly recording unified 4KB TCM and lack of fault reporting as P1 items.
*   **ADR-0035 Consistency Statement:** ADR-0035 is highly consistent, establishing a single-source-of-truth (SSOT) command descriptor contract that perfectly integrates with the bidirectional DMA and sequencer, while honestly recording omissions such as deferred ring overrun detection and non-computation of matrix operations.

---

## B. Replaceability Cross-Check

Based on the committed status report (`docs/reports/2026-07-03_replaceability_status.md`), the replaceability grades for each of the eight parity rows are evaluated below:

1.  **Pure Scalar ISA (RV32IMF_Zbb) [PARTIAL]:** **CONFIRM.** The stripped scalar sequencer successfully executes standard `rv32im` in lockstep, but `Zbb` instructions are not yet integrated into the verification corpus, and scalar `F` remains a deferred scope-cut.
2.  **Vector (RVV Zve32x + CSR lockstep) [MISSING]:** **CONFIRM.** Although the toolchain and Spike ISS compilation flow are fully proven (`gate_p0`), the RTL currently contains absolutely no vector execution datapath.
3.  **Matrix (256-MAC + Requant) [MISSING]:** **CONFIRM.** The physical matrix array does not exist, and the command queue handler correctly halts with an `ENGINE_NOT_READY` error if a matrix operation is dispatched.
4.  **Memory (ITCM 8K / DTCM 32K, 128-bit) [MISSING]:** **CONFIRM.** The memory architecture is currently a unified 4KB TCM accessed via a 32-bit port; sizing, port-width, and banking/splitting are deferred to P1.
5.  **Offload (Doorbell -> DMA -> Compute -> Writeback -> IRQ) [PARTIAL]:** **CONFIRM.** Descriptor-driven bidirectional AXI DMA transfers (weights read and results writeback), doorbell polling, and interrupt routing are fully functional, but "compute" is strictly limited to the scalar core.
6.  **Exception / Control (Traps + Abort/Reset) [MISSING]:** **CONFIRM.** Basic `ERR_CAUSE` and status-freeze mechanics are present for command-queue faults, but actual host-level exception routing, soft-reset wiring, and abort-drain loops remain unimplemented stubs.
7.  **Software (clang-RVV + TFLM + CQ Encoder) [PARTIAL]:** **CONFIRM.** Clang-compiled RVV assembly runs flawlessly on the Spike golden ISS (`gate_p0_toolchain_iss`), and the SSOT-derived CQ Python encoder matches the RTL decoder, but end-to-end TFLM integration is deferred to Phase 6.
8.  **Debug (RVVI/RVFI Trace Port) [MISSING]:** **CONFIRM.** No physical RVVI or RVFI instruction/data tracing ports are instantiated in the NPU RTL.

### Bottom-Line Replaceability Status
*While the NPU's control path and offload mechanics are fully established, true Coral replaceability remains blocked until vector and matrix execution units are implemented.*

---

## C. Coral Vector-Unit Dossier

To prepare for the Phase 3 RVV `Zve32x` Execution Unit (EXU) design, the architectural shape of the open Google Coral NPU (Kelvin) vector unit is compiled below from the Ch5 de-blackbox lab evidence (`CLAUDE.md` and `00_handcraft_split_plan.md`):

### 1. VLEN, ELEN, and Zve32x Subset
*   **Hardware Config:** Kelvin implements the standard RISC-V Vector Extension version 1.0 under the `Zve32x` and `Zvl128b` constraints.
*   **Vector Parameterization:** The physical vector register length (**VLEN**) is pinned at **128 bits**, and the maximum element length (**ELEN**) is **32 bits** (`docs/adr/0031` / `IP/npu/docs/00_isa_contract.md`). 
*   **Supported EEW/SEW:** It supports Element Execution Widths (EEW) and Selected Element Widths (SEW) of **8, 16, and 32 bits**.
*   **Float Support:** In strict alignment with `Zve32x`, vector floating-point support is completely omitted (integer-only datapath).

### 2. Dual-ALU Arrangement & Vector Command Queue (VCQ)
*   **Dual Vector Pipelines:** The vector backend features a dual-execution lane structure (two parallel 128-bit Vector ALUs), which is reflected in the 11-module `alu family` and 3-module `mul/mac` sub-blocks (`00_handcraft_split_plan.md` G06).
*   **Decoupled Offload (VCQ):** To prevent the scalar sequencer from stalling during long-running vector executions, the scalar-to-vector boundary is fully decoupled by the **Vector Command Queue (VCQ)** inside the `RvvFrontEnd` module.
    *   **Dispatch Mechanism:** The scalar core decodes vector instructions and pushes them as command descriptors into the VCQ. This is a non-blocking "fire-and-forget" push. The scalar core immediately proceeds to execute subsequent instructions (such as loop index increments, address calculations, or host doorbell polling) while the vector backend pops instructions from the VCQ and executes them asynchronously.
    *   **Queue Depth & Backpressure:** If the VCQ depth (typically 8 entries) is exhausted, the dispatch interface in `RvvFrontEnd` asserts backpressure, stalling the scalar pipeline's decode stage.
    *   **Scalar <-> Vector Hazards:** 
        *   *Scalar-to-Vector (Read-after-Write):* If a vector instruction requires a scalar operand (e.g., `vmv.v.x`), the scalar register value is read at dispatch time and queued with the descriptor. Subsequent scalar register writes by the sequencer do not cause hazards.
        *   *Vector-to-Scalar (Write-after-Read / Read-after-Write):* Vector instructions that write back to scalar registers (e.g., reduction operations like `vredsum.vs` or scalar moves `vmv.s.x`) are tracked via a scoreboard in the scalar retirement buffer (`RetirementBuffer` and `SCore`). The scalar core will stall if it attempts to read a destination register of an in-flight vector instruction before that vector instruction retires.

### 3. Vector LSU Path to DTCM
*   **Data Bus Width:** The Vector Load-Store Unit (VLSU) is connected to a dedicated **128-bit wide port** directly serving the DTCM (`docs/adr/0031` / `docs/arch/00_handcraft_split_plan.md`). This allows an entire 128-bit vector register to be populated or written back in a single clock cycle.
*   **Unit-Stride vs. Strided Support:**
    *   *Unit-Stride (`vle8.v`, `vse32.v`):* Fully accelerated. The VLSU transfers contiguous blocks of 128 bits per cycle.
    *   *Strided/Indexed (`vlse`, `vsse`, `vlxe`, `vsxe`):* These instructions are supported via an address-generation and mapping unit (`lsu_remap` / `lsu` modules). If the accessed elements span non-contiguous memory locations, the VLSU serializes the access, executing multi-cycle sub-transfers over the 128-bit DTCM bus.

### 4. Vector CSR Behavior & Kelvin Deviations
*   **Standard Vector CSRs:** The vector unit implements standard RVV 1.0 CSRs: `vtype`, `vl`, `vstart`, `vxrm`, and `vxsat`.
*   **vsetvli Execution:** The `vsetvli rd, rs1, vtypei` instruction calculates the legal vector length (`vl`) based on standard LMUL and SEW parameters against `VLEN=128`, writing the result to the destination register `rd` and updating `vtype` and `vl`.
*   **Kelvin-Specific Deviations:**
    *   *No Vector Floats:* Floating-point vector instructions are treated as illegal instructions, aligning with `Zve32x`.
    *   *Vector Trap Resumption:* While standard RVV 1.0 supports resuming interrupted vector loops via the `vstart` register, the open emit of Kelvin heavily relies on the scalar sequencer stalling or aborting on vector memory faults (reported via `fault` or `fault_manager`), with `vstart` primarily hardwired or utilized strictly inside the internal vector reorder buffer (`rob`) rather than supporting fully resumable host-level context switching.

### 5. Minimum Zve32x Slice for TFLM int8 Parity
To pass the Phase 0 proof kernel (`vsetvli e8/mf4`, `vle8.v`, `vwmul.vv`, `vwadd.wv`, `vredsum.vs`, `vse32.v`), the minimum physical vector hardware slice must implement:

*   **Supported SEWs:** `8` (input activation/weight loading), `16` (widened products), and `32` (widened accumulation and scalar reduction).
*   **Supported LMULs:** Fractional LMULs `mf4` (1/4 vector register grouping) and `mf2` (1/2 grouping) to support the widening operations (`vwmul` and `vwadd` double the element width, meaning an `mf4` group of 8-bit elements widens to an `mf2` group of 16-bit elements), and integer LMUL `m1` for final reduction.
*   **Instruction Set Primitives:**
    *   `vsetvli` (SEW/LMUL configuration logic).
    *   `vle8.v` (Unit-stride 8-bit vector load).
    *   `vwmul.vv` (8-bit signed integer widening multiplication: $8\text{b} \times 8\text{b} \rightarrow 16\text{b}$).
    *   `vwadd.wv` (Widening addition of a 16-bit vector with a 32-bit vector).
    *   `vredsum.vs` (Sum reduction of 32-bit elements to a single 32-bit scalar vector element).
    *   `vse32.v` (Unit-stride 32-bit vector store).
*   **What Can Be Honestly Deferred:**
    *   *All Vector Floating-Point Instructions:* Fully deferred (unnecessary for int8 inference).
    *   *Strided and Indexed/Gather-Scatter Loads/Stores:* Since the proof kernel uses only unit-stride operations, strided (`vlse`/`vsse`) and indexed (`vlxe`/`vsxe`) memory address-generation hardware can be deferred to P1.
    *   *Large LMULs (`m4`, `m8`):* Multi-register grouping state machines can be deferred; mapping groups to a maximum of `m1`/`m2` simplifies the vector register file (VRF) port arbitration.
    *   *Non-Essential Integer Ops:* Vector division, shifts, vector-integer merges, and masked vector instructions can be deferred (TFLM quantization and scaling are executed on the matrix unit's requantization engine via `MAT.RESCALE`, leaving the vector unit to handle pure dot-product operations).
    *   *Fixed-Point Rounding/Saturation CSRs:* The tracking of rounding and saturation modes (`vxrm`, `vxsat`) can be bypassed or hardwired to default states initially, as the scaling/rounding is handled at the matrix-to-memory writeback boundary.
