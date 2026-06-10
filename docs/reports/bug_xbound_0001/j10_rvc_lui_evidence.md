## finding
Seed 2026060801 did not expose an RTL C.LUI decode bug. The fetched halfword at normalized pc=0x000000d2 was correct:
`i_mem_rdata=6db58e95`, `cur_at_high=1`, `cinstr=6db5`, `cdec_expanded=0000ddb7`, `cdec_illegal=0`, `cross_assemble=0`, `any_stall=0`.

## root cause
The false mismatch was in `flow/v2_pipeline/lib/spike_commit.py`. The old Spike parser subtracted `pc_base` from any writeback inside `[pc_base, pc_base + 0x10000)`. Raw Spike log for `0x6db5 c.lui s11,0xd` writes `x27=0x0000d000`, matching the DUT. The parser changed that to `0x0000c000`.

## fix
The parser now computes normalized RV32IMC integer writebacks from Spike commits using normalized PC/register state. This preserves PC-relative AUIPC/link behavior while leaving plain constants such as C.LUI untouched.

## status
No RTL or ADR change. This is a lockstep comparator correctness fix.
