# ADR-0011: Precise `mepc` and WARL Bit Mask

## Status

Accepted

## Context

RV32IMC has IALIGN=16. Machine `mepc[0]` is not writable, while `mepc[1]`
remains writable so halfword-aligned RVC return PCs are representable.
Synchronous exceptions must save the faulting instruction address in `mepc`.

Directed observation found two real defects in lab08e:

- Software `csrw mepc, 0x83; csrr mepc` read back `0x83`, not `0x82`.
- Synchronous/data traps saved `ex_wb_pc_r - 4`; observed `mepc` values were
  `0x7c/0x8a/0x94/0x9c/0xa4` for expected PCs
  `0x80/0x8e/0x98/0xa0/0xa8`.

## Decision

1. `csr.v` masks software writes to `mepc` with `{new_val[31:1], 1'b0}`.
   Bit 1 is preserved for RV32C halfword-aligned return PCs.
2. `core.v` uses `ex_wb_pc_r` directly for synchronous and data exception
   `mepc`. In this pipeline `ex_wb_pc_r` is the original instruction PC:
   `if_ex_pc -> ex_mem_pc_r -> ex_wb_pc_r`.
3. Async interrupt `mepc` behavior remains next-PC based via the existing
   branch/JAL/JALR/PC+size path.

## Validation

`flow/v2_pipeline/phase_02_03_mepc_directed` verifies:

- `csrw mepc, 0x83; csrr mepc` observes `0x82`.
- 32-bit illegal at `0x80`, cross-boundary 32-bit illegal at `0x8e`,
  compressed illegal at `0x98`, `ebreak` at `0xa0`, and misaligned `lw` at
  `0xa8` all save exact fault PCs in `mepc`.
