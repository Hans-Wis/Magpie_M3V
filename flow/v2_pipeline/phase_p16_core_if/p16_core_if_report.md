# P16 Core IF / RV32C Cross-Boundary Report

Status: P16 slice analyzed; overall gate is not marked green.

Spike lockstep: PASS: P16 IF cross-boundary lockstep matched 42 commits

## BUG-XBOUND-0001

The directed grid includes odd-aligned 32-bit ADDI, compressed tail + 32-bit head, consecutive cross-boundary 32-bit assembly, C.J/C.JAL to high-halfword targets, consecutive C.LW + 32-bit head, and redirect-after-cross-boundary. Spike lockstep is the authority.

## core.v IF Delta

| Source | Hit/Total | Toggle % |
| --- | ---: | ---: |
| BEFORE baseline (`phase_03_06_multi_seed_coverage`) | 3332/4878 | 68.31% |
| P16 directed alone | 3509/5426 | 64.67% |
| AFTER baseline + P16 | 3813/4878 | 78.17% |
| DELTA closed | +481 toggles | +9.86 pp |

## Owned Roster

- Covered after merge: 96/200
- Newly covered by P16: 96
- Remaining reachable: 96
- Remaining structural: 8
- Remaining cross-slice: 0

### Newly Covered

- `dbg_pc[8, 21:11]`
- `ex_mem_pc_r[8, 21:11]`
- `ex_wb_pc_r[8, 21:11]`
- `i_mem_addr[8, 21:11]`
- `if_ex_pc[8, 21:11]`
- `if_pc[8, 21:11]`
- `next_pc_w[8, 21:11]`
- `redirect_target[8, 21:11]`

### Remaining Structural

- `dbg_pc[0]`: PC bit 0 is 16-bit instruction-alignment constrained; `dbg_pc = if_ex_pc` at IP/cpu_m1/rtl/core.v:1079.
- `ex_mem_pc_r[0]`: EX/MEM PC is propagated from aligned IF/EX PC; see IP/cpu_m1/rtl/core.v:780.
- `ex_wb_pc_r[0]`: EX/WB PC is propagated from aligned EX/MEM PC; see IP/cpu_m1/rtl/core.v:905.
- `i_mem_addr[0]`: All fetch address choices are based on aligned `if_pc` plus 2/4/6 or `next_pc_w`; see IP/cpu_m1/rtl/core.v:221.
- `if_ex_pc[0]`: IF/EX PC is latched from aligned `if_pc`; see IP/cpu_m1/rtl/core.v:291.
- `if_pc[0]`: `ifu` PC is RV32IMC 16-bit aligned and advances by +2/+4; see IP/cpu_m1/rtl/ifu.v:45-52.
- `next_pc_w[0]`: `ifu.next_pc` selects aligned redirect/prediction targets or `pc_reg + pc_inc`; see IP/cpu_m1/rtl/ifu.v:45-52.
- `redirect_target[0]`: JALR redirect recovery masks bit 0 with `& ~32'd1`; see IP/cpu_m1/rtl/core.v:1045.

### Remaining Reachable

- `dbg_pc[10]`: Run committed code at varied high offsets so debug PC high bits toggle.
- `dbg_pc[22]`: Run committed code at varied high offsets so debug PC high bits toggle.
- `dbg_pc[23]`: Run committed code at varied high offsets so debug PC high bits toggle.
- `dbg_pc[24]`: Run committed code at varied high offsets so debug PC high bits toggle.
- `dbg_pc[25]`: Run committed code at varied high offsets so debug PC high bits toggle.
- `dbg_pc[26]`: Run committed code at varied high offsets so debug PC high bits toggle.
- `dbg_pc[27]`: Run committed code at varied high offsets so debug PC high bits toggle.
- `dbg_pc[28]`: Run committed code at varied high offsets so debug PC high bits toggle.
- `dbg_pc[29]`: Run committed code at varied high offsets so debug PC high bits toggle.
- `dbg_pc[30]`: Run committed code at varied high offsets so debug PC high bits toggle.
- `dbg_pc[31]`: Run committed code at varied high offsets so debug PC high bits toggle.
- `dbg_pc[9]`: Run committed code at varied high offsets so debug PC high bits toggle.
- `ex_mem_pc_r[10]`: Let high-address IF PCs advance into EX/MEM; this is P15-deferred PC-range closure owned by P16.
- `ex_mem_pc_r[22]`: Let high-address IF PCs advance into EX/MEM; this is P15-deferred PC-range closure owned by P16.
- `ex_mem_pc_r[23]`: Let high-address IF PCs advance into EX/MEM; this is P15-deferred PC-range closure owned by P16.
- `ex_mem_pc_r[24]`: Let high-address IF PCs advance into EX/MEM; this is P15-deferred PC-range closure owned by P16.
- `ex_mem_pc_r[25]`: Let high-address IF PCs advance into EX/MEM; this is P15-deferred PC-range closure owned by P16.
- `ex_mem_pc_r[26]`: Let high-address IF PCs advance into EX/MEM; this is P15-deferred PC-range closure owned by P16.
- `ex_mem_pc_r[27]`: Let high-address IF PCs advance into EX/MEM; this is P15-deferred PC-range closure owned by P16.
- `ex_mem_pc_r[28]`: Let high-address IF PCs advance into EX/MEM; this is P15-deferred PC-range closure owned by P16.
- `ex_mem_pc_r[29]`: Let high-address IF PCs advance into EX/MEM; this is P15-deferred PC-range closure owned by P16.
- `ex_mem_pc_r[30]`: Let high-address IF PCs advance into EX/MEM; this is P15-deferred PC-range closure owned by P16.
- `ex_mem_pc_r[31]`: Let high-address IF PCs advance into EX/MEM; this is P15-deferred PC-range closure owned by P16.
- `ex_mem_pc_r[9]`: Let high-address IF PCs advance into EX/MEM; this is P15-deferred PC-range closure owned by P16.
- `ex_wb_pc_r[10]`: Let high-address EX/MEM PCs advance into EX/WB; this is P15-deferred PC-range closure owned by P16.
- `ex_wb_pc_r[22]`: Let high-address EX/MEM PCs advance into EX/WB; this is P15-deferred PC-range closure owned by P16.
- `ex_wb_pc_r[23]`: Let high-address EX/MEM PCs advance into EX/WB; this is P15-deferred PC-range closure owned by P16.
- `ex_wb_pc_r[24]`: Let high-address EX/MEM PCs advance into EX/WB; this is P15-deferred PC-range closure owned by P16.
- `ex_wb_pc_r[25]`: Let high-address EX/MEM PCs advance into EX/WB; this is P15-deferred PC-range closure owned by P16.
- `ex_wb_pc_r[26]`: Let high-address EX/MEM PCs advance into EX/WB; this is P15-deferred PC-range closure owned by P16.
- `ex_wb_pc_r[27]`: Let high-address EX/MEM PCs advance into EX/WB; this is P15-deferred PC-range closure owned by P16.
- `ex_wb_pc_r[28]`: Let high-address EX/MEM PCs advance into EX/WB; this is P15-deferred PC-range closure owned by P16.
- `ex_wb_pc_r[29]`: Let high-address EX/MEM PCs advance into EX/WB; this is P15-deferred PC-range closure owned by P16.
- `ex_wb_pc_r[30]`: Let high-address EX/MEM PCs advance into EX/WB; this is P15-deferred PC-range closure owned by P16.
- `ex_wb_pc_r[31]`: Let high-address EX/MEM PCs advance into EX/WB; this is P15-deferred PC-range closure owned by P16.
- `ex_wb_pc_r[9]`: Let high-address EX/MEM PCs advance into EX/WB; this is P15-deferred PC-range closure owned by P16.
- `i_mem_addr[10]`: Fetch from varied/high offsets, including high-halfword cross-boundary addresses.
- `i_mem_addr[22]`: Fetch from varied/high offsets, including high-halfword cross-boundary addresses.
- `i_mem_addr[23]`: Fetch from varied/high offsets, including high-halfword cross-boundary addresses.
- `i_mem_addr[24]`: Fetch from varied/high offsets, including high-halfword cross-boundary addresses.
- `i_mem_addr[25]`: Fetch from varied/high offsets, including high-halfword cross-boundary addresses.
- `i_mem_addr[26]`: Fetch from varied/high offsets, including high-halfword cross-boundary addresses.
- `i_mem_addr[27]`: Fetch from varied/high offsets, including high-halfword cross-boundary addresses.
- `i_mem_addr[28]`: Fetch from varied/high offsets, including high-halfword cross-boundary addresses.
- `i_mem_addr[29]`: Fetch from varied/high offsets, including high-halfword cross-boundary addresses.
- `i_mem_addr[30]`: Fetch from varied/high offsets, including high-halfword cross-boundary addresses.
- `i_mem_addr[31]`: Fetch from varied/high offsets, including high-halfword cross-boundary addresses.
- `i_mem_addr[9]`: Fetch from varied/high offsets, including high-halfword cross-boundary addresses.
- `if_ex_pc[10]`: Commit instructions from varied/high offsets and PC[1]=0/1 sites.
- `if_ex_pc[22]`: Commit instructions from varied/high offsets and PC[1]=0/1 sites.
- `if_ex_pc[23]`: Commit instructions from varied/high offsets and PC[1]=0/1 sites.
- `if_ex_pc[24]`: Commit instructions from varied/high offsets and PC[1]=0/1 sites.
- `if_ex_pc[25]`: Commit instructions from varied/high offsets and PC[1]=0/1 sites.
- `if_ex_pc[26]`: Commit instructions from varied/high offsets and PC[1]=0/1 sites.
- `if_ex_pc[27]`: Commit instructions from varied/high offsets and PC[1]=0/1 sites.
- `if_ex_pc[28]`: Commit instructions from varied/high offsets and PC[1]=0/1 sites.
- `if_ex_pc[29]`: Commit instructions from varied/high offsets and PC[1]=0/1 sites.
- `if_ex_pc[30]`: Commit instructions from varied/high offsets and PC[1]=0/1 sites.
- `if_ex_pc[31]`: Commit instructions from varied/high offsets and PC[1]=0/1 sites.
- `if_ex_pc[9]`: Commit instructions from varied/high offsets and PC[1]=0/1 sites.
- `if_pc[10]`: Execute high/odd-halfword fetch sites through the IFU PC register.
- `if_pc[22]`: Execute high/odd-halfword fetch sites through the IFU PC register.
- `if_pc[23]`: Execute high/odd-halfword fetch sites through the IFU PC register.
- `if_pc[24]`: Execute high/odd-halfword fetch sites through the IFU PC register.
- `if_pc[25]`: Execute high/odd-halfword fetch sites through the IFU PC register.
- `if_pc[26]`: Execute high/odd-halfword fetch sites through the IFU PC register.
- `if_pc[27]`: Execute high/odd-halfword fetch sites through the IFU PC register.
- `if_pc[28]`: Execute high/odd-halfword fetch sites through the IFU PC register.
- `if_pc[29]`: Execute high/odd-halfword fetch sites through the IFU PC register.
- `if_pc[30]`: Execute high/odd-halfword fetch sites through the IFU PC register.
- `if_pc[31]`: Execute high/odd-halfword fetch sites through the IFU PC register.
- `if_pc[9]`: Execute high/odd-halfword fetch sites through the IFU PC register.
- `next_pc_w[10]`: Exercise +2/+4 sequential PC, redirect, and high-address target selection.
- `next_pc_w[22]`: Exercise +2/+4 sequential PC, redirect, and high-address target selection.
- `next_pc_w[23]`: Exercise +2/+4 sequential PC, redirect, and high-address target selection.
- `next_pc_w[24]`: Exercise +2/+4 sequential PC, redirect, and high-address target selection.
- `next_pc_w[25]`: Exercise +2/+4 sequential PC, redirect, and high-address target selection.
- `next_pc_w[26]`: Exercise +2/+4 sequential PC, redirect, and high-address target selection.
- `next_pc_w[27]`: Exercise +2/+4 sequential PC, redirect, and high-address target selection.
- `next_pc_w[28]`: Exercise +2/+4 sequential PC, redirect, and high-address target selection.
- `next_pc_w[29]`: Exercise +2/+4 sequential PC, redirect, and high-address target selection.
- `next_pc_w[30]`: Exercise +2/+4 sequential PC, redirect, and high-address target selection.
- `next_pc_w[31]`: Exercise +2/+4 sequential PC, redirect, and high-address target selection.
- `next_pc_w[9]`: Exercise +2/+4 sequential PC, redirect, and high-address target selection.
- `redirect_target[10]`: Take branches/JAL/JALR to varied high addresses; bit 0 remains structural for JALR mask.
- `redirect_target[22]`: Take branches/JAL/JALR to varied high addresses; bit 0 remains structural for JALR mask.
- `redirect_target[23]`: Take branches/JAL/JALR to varied high addresses; bit 0 remains structural for JALR mask.
- `redirect_target[24]`: Take branches/JAL/JALR to varied high addresses; bit 0 remains structural for JALR mask.
- `redirect_target[25]`: Take branches/JAL/JALR to varied high addresses; bit 0 remains structural for JALR mask.
- `redirect_target[26]`: Take branches/JAL/JALR to varied high addresses; bit 0 remains structural for JALR mask.
- `redirect_target[27]`: Take branches/JAL/JALR to varied high addresses; bit 0 remains structural for JALR mask.
- `redirect_target[28]`: Take branches/JAL/JALR to varied high addresses; bit 0 remains structural for JALR mask.
- `redirect_target[29]`: Take branches/JAL/JALR to varied high addresses; bit 0 remains structural for JALR mask.
- `redirect_target[30]`: Take branches/JAL/JALR to varied high addresses; bit 0 remains structural for JALR mask.
- `redirect_target[31]`: Take branches/JAL/JALR to varied high addresses; bit 0 remains structural for JALR mask.
- `redirect_target[9]`: Take branches/JAL/JALR to varied high addresses; bit 0 remains structural for JALR mask.

### Cross-Slice

- none

## Tokens

Token budget/usage was not exposed by the local goal API for this turn; see `token_record.txt`.
