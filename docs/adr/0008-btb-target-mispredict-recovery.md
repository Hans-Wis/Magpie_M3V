# ADR-0008 - BTB target-mispredict recovery

- Status: Accepted (2026-06-08)
- Deciders: Claude (architect), User
- Flow stage: J12 riscv-dv load/store + branch/jump lockstep
- Supersedes: none. Builds on ADR-0007 cross-boundary fetch.

## Context

J12 enabled riscv-dv branch/jump generation beyond the J11 arithmetic-only
scope. Several 2000-instruction seeds diverged from Spike after a committed
conditional branch. Example: seed 2026061201 matched through idx 54 at
PC 0x000000ec (`bgeu s9,gp,0x000000f8`), then Spike executed PC 0x000000f8
while the DUT executed PC 0x000000f0. The DUT later fetched wrong-path bytes and
reported illegal instruction.

This is a real DUT control-flow bug, not a harness or Spike parse issue: the
commit rows match before the branch, the generated disassembly shows the Spike
target, and the first divergence is PC/instruction control flow.

## Decision

`core.v` now latches the predicted target into IF/EX and treats a predicted-taken
branch/JAL/JALR as correct only when the resolved target also matches. Direction
mismatch handling is unchanged. RAS-predicted returns keep their existing
MEM-stage actual-target check.

`core.v` also gives redirect flush priority over ordinary stalls and adds a
one-cycle `redirect_warmup` refetch bubble after `pc_redirect`. The active I-port
memory is synchronous: immediately after redirect, `if_pc` has the target but
`i_mem_rdata` can still be the old word. Without the bubble, IF/EX can latch a
new target PC paired with stale instruction bits.

The recovery target remains resolved from EX/MEM registers, preserving the
existing redirect priority and keeping branch/JAL targets as `pc+imm` and JALR
targets as `(rs1+imm)&~1`.

## Consequences

- BTB alias/stale-target hits no longer silently execute the wrong path.
- Redirected fetches no longer pair target PC with stale synchronous I-memory
  data.
- Correctly predicted taken branches with correct targets still avoid redirect.
- JALR remains excluded from BTB update, but an accidental BTB hit at a JALR PC is
  now recovered by target mismatch.
- J12 riscv-dv branch/jump seeds are the regression evidence for this ADR.
