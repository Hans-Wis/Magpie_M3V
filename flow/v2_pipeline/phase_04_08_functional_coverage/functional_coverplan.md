# Phase 4.8 cpu_m1 Functional Coverplan

Scope: cpu_m1 RV32IMC_Zicsr_Zifencei advisory stimulus coverage. The covergroups are bound to `core`; no RTL state or behavior is changed.

## Covergroups

| covergroup | intent | primary bins |
| --- | --- | --- |
| `cg_opcode_instr_class` | ISA class and instruction length | LUI/AUIPC/JAL/JALR/BRANCH/LOAD/STORE/OP-IMM/OP/SYSTEM/FENCE, compressed vs 32-bit |
| `cg_alu_m_funct` | ALU and M-unit decode fields | OP/OP-IMM funct3, funct7 default/sub-sra/muldiv, M funct3 MUL..REMU |
| `cg_load_store` | Memory operation shape | load/store, byte/half/word, signed/unsigned/none, address low bits 0..3 |
| `cg_branch_jump_bp_ras` | Control-flow prediction and recovery | branch taken/not-taken, forward/backward, JAL/JALR, RAS push/pop, BP hit/miss |
| `cg_hazard_flush` | Pipeline interlocks and redirects | load-use stall, mul/div busy stall, fetch/memory stall, flush/redirect |
| `cg_csr_trap` | CSR and trap behavior | CSR RW/RS/RC, ecall/ebreak/illegal/IRQ/load-misalign/store-misalign, mret |
| `cg_riscvisacov_operands` | riscvISACOV operand coverage | rd/rs1/rs2 x0 and x1..x31, instruction class, register-by-class crosses |
| `cg_riscvisacov_value_corners` | riscvISACOV operand value corners | rs1/rs2 values 0, 1, -1, 0x7fffffff, 0x80000000, 0xffffffff |
| `cg_riscvisacov_immediates` | riscvISACOV immediate corners | I/S/B/U/J format, sign, zero/min/max corners, format crosses |

## Closure Rule

`analyze_functional_coverage.py` computes per-group and overall hit percentages from the observer event CSV. Every unhit bin is listed with reason, reachability, and waiver candidate status in `functional_coverage_report.md`.

The gate threshold remains 100%. Reports below that level must stay gate-visible and must not be marked green; remaining unhit bins require either measured stimulus closure or explicit justified exclusion. Structural exclusions remain visible in uncovered-bin triage and are removed only from the effective closure denominator.
