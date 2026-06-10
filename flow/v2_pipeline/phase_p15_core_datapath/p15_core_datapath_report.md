# P15 Core Datapath Integration Report

Spike lockstep: PASS: P15 datapath lockstep matched 162 commits

## core.v Toggle Delta

| Source | Hit/Total | Toggle % |
| --- | ---: | ---: |
| BEFORE baseline (`phase_03_06_multi_seed_coverage`) | 3332/4878 | 68.31% |
| P15 directed alone | 4076/5426 | 75.12% |
| AFTER baseline + P15 | 3851/4878 | 78.95% |
| DELTA closed | +519 toggles | +10.64 pp |

After percentage is computed on the baseline `core.v` toggle-point universe. The raw merged coverage artifact is still written to `coverage/merged_with_phase_p15.dat`.

## Datapath-Owned Roster Signals Now Covered

- `mem_stall`
- `ex_mem_pc_plus_4_r[19:8]`
- `ex_mem_pc_r[19:8]`
- `ex_wb_pc_plus_4_r[19:8]`
- `ex_wb_pc_r[19:8]`

## Datapath-Owned Roster Signals Still Uncovered

### REACHABLE

- `ex_mem_is_misaligned_r`: Add privileged lockstep or non-commit trap harness and observe propagation into EX/MEM.
- `ex_mem_pc_plus_4_r[31:20]`: Place committed code at a higher `.org` and execute JAL/JALR link-producing instructions.
- `ex_mem_pc_r[31:20]`: Place committed code at a higher `.org` so EX/MEM PC bits toggle.
- `ex_wb_pc_plus_4_r[31:20]`: Place committed code at a higher `.org` and let link-producing instructions reach WB.
- `ex_wb_pc_r[31:20]`: Place committed code at a higher `.org` so EX/WB PC bits toggle.
- `id_mem_align_error`: Add privileged lockstep or non-commit trap harness for odd `LH` and misaligned `LW`.
- `id_mem_misaligned`: Add privileged lockstep or non-commit trap harness for odd `LH` and misaligned `LW`.
- `wb_take_data_trap`: Add privileged lockstep trap handler and compare Spike trap entry through `mtvec`.

### STRUCTURAL

- `ex_mem_pc_plus_4_r[0]`: PC/link bit 0 is instruction-alignment constrained; `if_ex_pc_plus_4 = if_ex_pc + 2/4` at IP/cpu_m1/rtl/core.v:487 and latched at line 783.
- `ex_mem_pc_r[0]`: Instruction PCs are aligned; IF/EX PC is latched from the fetch PC at IP/cpu_m1/rtl/core.v:291 and propagated at line 780.
- `ex_wb_pc_plus_4_r[0]`: PC/link bit 0 is instruction-alignment constrained; `if_ex_pc_plus_4 = if_ex_pc + 2/4` at IP/cpu_m1/rtl/core.v:487 and propagated at lines 908/982.
- `ex_wb_pc_r[0]`: Instruction PCs are aligned; EX/MEM PC propagates to EX/WB at IP/cpu_m1/rtl/core.v:905.

### cross-slice

- none

## Fixture Scope

- Back-to-back `addi` plus `lw` -> dependent `add` load-use stall.
- EX/MEM and WB ALU forwarding consumers.
- `mul`/`div` M-unit busy stalls while younger ALU work is held.
- Taken branch redirect near a recent load-use pair.
- `WB_SEL_LSU`, `WB_SEL_MD`, ALU, PC4/PCIMM paths, and load sign/zero extension.
- Testbench-driven `mem_stall` wait states on active data-port accesses.

No IF, CSR/trap, BP, or RAS coverage is claimed here.
