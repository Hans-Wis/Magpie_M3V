# ADR-0010: CSR State and Synchronous Trap Lockstep

## Status
Accepted

## Context
J14 enabled Zicsr lockstep against Spike for the M1 M-mode CSR subset. The
first active CSR sweep exposed real DUT state mismatches:

- `mstatus` dropped MPP bits. Spike read `0x00001880` after the riscv-dv
  machine-mode init sequence, while the DUT read `0x00000080`.
- A back-to-back `csrrw mscratch` / `csrr mscratch` read old DUT CSR state.
  Spike read the just-written value.
- ECALL/EBREAK/illegal were decoded as terminal illegal state, not precise
  `mtvec` trap entries with `mepc/mcause/mtval` updates.

The same run also exposed harness limits: Spike 1.1.1-dev in this environment
stops at M-mode `ecall`/`ebreak` after logging the exception, so full
sync-trap continuation cannot yet be included in the riscv-dv lockstep stream.

## Decision
Implement the M-mode CSR behavior needed for exact non-timing CSR comparison:

1. Preserve and report `mstatus.MPP` as M-mode (`2'b11`) in this M-only core.
2. Forward pending CSR writes to following CSR reads in EX/MEM and same-cycle
   WB.
3. Convert synchronous exceptions to precise trap entry: save exception PC in
   `mepc`, set `mcause` for illegal/breakpoint/ecall, set `mtval`, and redirect
   to `mtvec`. `mret` returns via `mepc`.

Timing CSR read data (`cycle/cycleh/instret/instreth`, plus machine-counter
aliases if present in Spike logs) remains excluded from writeback-data compare
only, because the DUT counts real pipeline/wait cycles and Spike does not.

## Consequences
Non-timing CSR reads and writes remain exact lockstep obligations. Timing CSR
rows still compare PC, instruction, and destination register; only their read
data is marked do-not-compare by the comparator.

Full ECALL/EBREAK/illegal continuation remains a harness open item until the
Spike invocation or trap model can continue after those exceptions.
