# ADR-0023 — RV32A atomic extension (optional)

- Status: accepted (design); implementation gated by no-regression + arch-test RV32A + per-config matrix
- Date: 2026-06-10
- Deciders: Claude (PL), Grok (M1 design), Gemini (spec). Original M1 RTL from the RISC-V Unprivileged spec
  (ibex has NO A — no reuse; origin=original). Must be **optional** (config back to RV32IMC).

## Decision

- **Instructions**: opcode `0101111`, funct3=`010` (.W), funct5 select: LR(0x02)/SC(0x03)/AMOSWAP(0x01)/
  AMOADD(0x00)/AMOXOR(0x04)/AMOAND(0x0C)/AMOOR(0x08)/AMOMIN(0x10)/AMOMAX(0x14)/AMOMINU(0x18)/AMOMAXU(0x1C).
- **aq/rl** (bits 26/25): **decode no-ops** — single-hart in-order, no reordering vs Spike; still decoded.
- **AMO = 2-beat RMW** reusing the mul/div `mem_stall` freeze (ADR-0005): beat0 load (old→rd), compute
  `op(old, rs2)`, beat1 store the result to the same addr; WB/commit only after the final beat.
- **LR.W** = load + set reservation `{valid, paddr[31:2]}`. **SC.W** = if `valid && paddr match` → store +
  `rd=0`, else `rd=1` and **no store**.
- **Reservation lifetime**: set on LR; cleared on any overlapping store (incl. AMO beat1, failed SC),
  **`trap_enter`** (no ghost reservation across a trap mid-AMO), reset, or a new LR.
- **Alignment**: a naturally-misaligned AMO/LR/SC → **mcause 6** (store/AMO misaligned, ADR-0005),
  `mtval=addr`, no bus transfer.
- **Optional**: parameter **`RV32A` (0/1)**. `RV32A=0` → opcode `0101111` is illegal-trap, no reservation
  register, AMO FSM not generated. **`misa.A`** (bit 0) WARL reflects the build.

## Verification
- **Highest-risk corner first** (Grok): SC/LR vs a 2-beat AMO under `mem_stall` + an IRQ/trigger arriving
  mid-AMO — assert the reservation is cleared on the correct cycle, no store on SC-fail, no ghost
  reservation across the trap, precise mepc.
- Directed: LR/SC success+fail, every AMO op (old value to rd, mem updated), misaligned → mcause 6.
- **Spike `rv32imac` lockstep** on AMO/LR/SC programs (the authority).
- **Per-config matrix**: full gates + arch-test pass at **RV32IMC** (RV32A=0, no regression) AND
  **RV32IMAC** (RV32A=1) + **arch-test RV32A**.

## Consequences
- **+** RV32IMAC capability; A is the common ask for RTOS/lock primitives.
- **+** Single-hart makes atomicity trivial (the RMW is just a 2-beat bus op; no coherence).
- **−** Touches LSU/MEM (2-beat FSM + reservation) + decode + csr (misa). Delicate around mem_stall/trap;
  PL-led integration + full re-verify. Mitigated by reusing the proven mul/div freeze path.
