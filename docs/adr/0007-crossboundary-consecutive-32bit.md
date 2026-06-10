# ADR-0007: Consecutive Cross-Boundary 32-bit Fetch

## Status

Accepted

## Context

RV32C permits 32-bit instructions to begin at the high half-word of a 32-bit
fetch word.  The lab08e fetch path used `residue` and `cross_assemble` to
avoid a stall when a low-half compressed instruction is followed by a high-half
32-bit instruction.

RISC-V DV seed `2026060801` exposed a run of high-half 32-bit instructions:

```text
0x04: c.li
0x06: beq
0x0a: auipc
0x0e: addi
```

The old state machine armed `cross_assemble` for the first high-half 32-bit
instruction, but cleared it while consuming that instruction.  It did not save
the current fetch word's high half as the residue for the next high-half
32-bit instruction, so the next instruction had to fall back through
`at_cross_boundary`.  In the failing seed, this let the front end present
mis-assembled bits at `pc=0x0e` before the fallback correction arrived.

## Decision

Add a `consecutive_cross` case in `core.v` for cycles where the current
instruction is being assembled from a previous residue and the next instruction
starts at the current fetch word's high half as another 32-bit instruction.

When `consecutive_cross` is true:

- keep `cross_assemble` asserted for the next cycle;
- update `residue` with `cur_half_hi`;
- fetch `if_pc + 6`, the word containing the following low half.

The existing `mem_stall` freeze behavior is preserved by gating this path with
`!mem_stall`; when memory is stalled, the state machine holds existing residue
and assembly state exactly as before.

## Consequences

Runs of high-half 32-bit instructions keep the lab08e 0-cycle pre-fetch behavior.
Fallback `at_cross_boundary` remains available after redirects or stalls.
