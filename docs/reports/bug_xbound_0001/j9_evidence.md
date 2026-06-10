# J9 Evidence: BUG-XBOUND-0001

Temporary lockstep testbench probe, before the RTL fix, at `if_pc == 0x0e`:

```text
J9_PROBE pc=0000000e instr_assembled=8f930000 cross_assemble=0 residue=0f97 cur_half_lo=0000 cur_half_hi=8f93 is_comp_lo=1 is_comp_hi=0 at_cross_boundary=1 upcoming_cross=0 i_mem_rdata=8f930000 i_mem_addr=00000010
J9_PROBE pc=0000000e instr_assembled=8f930000 cross_assemble=0 residue=8067 cur_half_lo=0000 cur_half_hi=8f93 is_comp_lo=1 is_comp_hi=0 at_cross_boundary=1 upcoming_cross=0 i_mem_rdata=8f930000 i_mem_addr=00000010
J9_PROBE pc=0000000e instr_assembled=00cf8f93 cross_assemble=1 residue=8f93 cur_half_lo=00cf cur_half_hi=8067 is_comp_lo=0 is_comp_hi=0 at_cross_boundary=0 upcoming_cross=0 i_mem_rdata=806700cf i_mem_addr=00000012
```

Expected instruction at `pc=0x0e` was `0x00cf8f93`.  The first value presented
by IF was `0x8f930000`, with `cross_assemble=0` and `at_cross_boundary=1`.
This shows that the previous high-half 32-bit instruction was consumed without
arming residue for the next high-half 32-bit instruction.
