// =============================================================================
// def.vh — Lab04 共用常數
// -----------------------------------------------------------------------------
// 所有模組 (`ifu.v` / `idu.v` / `rfu.v` / `alu.v` / `lsu.v` / `core.v`) 都
// `include "def.vh"` 來取得 RISC-V opcode、ALU op 編碼、CPU FSM state 等。
//
// 命名規則：
//   `OPC_*    : RISC-V opcode[6:0]
//   `F3_*     : funct3
//   `F7_*     : funct7
//   `ALU_*    : Lab04 自定的 ALU 操作碼 (4-bit)
//   `ST_*     : CPU FSM state (5-bit one-hot)
// =============================================================================

`ifndef DEF_VH
`define DEF_VH

// -----------------------------------------------------------------------------
// RISC-V opcode (RV32I, instr[6:0])
// -----------------------------------------------------------------------------
`define OPC_LUI     7'b0110111  // U-type
`define OPC_AUIPC   7'b0010111  // U-type
`define OPC_JAL     7'b1101111  // J-type
`define OPC_JALR    7'b1100111  // I-type, funct3=000
`define OPC_BRANCH  7'b1100011  // B-type
`define OPC_LOAD    7'b0000011  // I-type
`define OPC_STORE   7'b0100011  // S-type
`define OPC_OP_IMM  7'b0010011  // I-type ALU (addi, slti, ...)
`define OPC_OP      7'b0110011  // R-type ALU (add, sub, ...)
`define OPC_SYSTEM  7'b1110011  // ecall/ebreak/csr (ebreak only here)
`define OPC_FENCE   7'b0001111  // fence (NOP in lab04)
`define OPC_AMO     7'b0101111  // RV32A atomics

// -----------------------------------------------------------------------------
// funct3 — branch
// -----------------------------------------------------------------------------
`define F3_BEQ      3'b000
`define F3_BNE      3'b001
`define F3_BLT      3'b100
`define F3_BGE      3'b101
`define F3_BLTU     3'b110
`define F3_BGEU     3'b111

// -----------------------------------------------------------------------------
// funct3 — load / store
// -----------------------------------------------------------------------------
`define F3_LB       3'b000
`define F3_LH       3'b001
`define F3_LW       3'b010
`define F3_LBU      3'b100
`define F3_LHU      3'b101

`define F3_SB       3'b000
`define F3_SH       3'b001
`define F3_SW       3'b010

// -----------------------------------------------------------------------------
// funct3 — OP-IMM / OP
// -----------------------------------------------------------------------------
`define F3_ADD_SUB  3'b000  // funct7 distinguishes add/sub (sub only in R-type)
`define F3_SLL      3'b001
`define F3_SLT      3'b010
`define F3_SLTU     3'b011
`define F3_XOR      3'b100
`define F3_SRL_SRA  3'b101  // funct7 distinguishes srl/sra
`define F3_OR       3'b110
`define F3_AND      3'b111

`define F7_DEFAULT  7'b0000000  // add, srl, slli, srli, etc.
`define F7_SUB_SRA  7'b0100000  // sub, sra, srai

// -----------------------------------------------------------------------------
// ALU 操作碼 (Lab04 自定，4-bit，由 IDU 產生餵給 ALU)
// -----------------------------------------------------------------------------
`define ALU_ADD     4'd0
`define ALU_SUB     4'd1
`define ALU_AND     4'd2
`define ALU_OR      4'd3
`define ALU_XOR     4'd4
`define ALU_SLL     4'd5
`define ALU_SRL     4'd6
`define ALU_SRA     4'd7
`define ALU_SLT     4'd8   // signed   <  → result 0/1
`define ALU_SLTU    4'd9   // unsigned <  → result 0/1
`define ALU_SEQ     4'd10  // ==       (給 BEQ/BNE 用，與 SLT 共用比較器)
`define ALU_COPY_B  4'd11  // result = op_b (給 LUI 用：imm 已含 << 12)

// ============================================================
// M1A A2 (ADR-0026): BMU (bit-manip unit) op codes — Zba/Zbb/Zbs/Zicond
// Separate 5-bit space; heavy ops stay OUT of the base ALU case mux.
// ============================================================
`define BMU_SH1ADD  5'd0
`define BMU_SH2ADD  5'd1
`define BMU_SH3ADD  5'd2
`define BMU_ANDN    5'd3
`define BMU_ORN     5'd4
`define BMU_XNOR    5'd5
`define BMU_CLZ     5'd6
`define BMU_CTZ     5'd7
`define BMU_CPOP    5'd8
`define BMU_MIN     5'd9
`define BMU_MINU    5'd10
`define BMU_MAX     5'd11
`define BMU_MAXU    5'd12
`define BMU_SEXTB   5'd13
`define BMU_SEXTH   5'd14
`define BMU_ZEXTH   5'd15
`define BMU_ROL     5'd16
`define BMU_ROR     5'd17
`define BMU_ORCB    5'd18
`define BMU_REV8    5'd19
`define BMU_BCLR    5'd20
`define BMU_BEXT    5'd21
`define BMU_BINV    5'd22
`define BMU_BSET    5'd23
`define BMU_CZEQZ   5'd24
`define BMU_CZNEZ   5'd25

// Zb*/Zicond funct7 selectors (OPC_OP / OPC_OP_IMM space)
`define F7_ZBA      7'b0010000  // sh1add/sh2add/sh3add (f3=010/100/110)
`define F7_ZBB_NEG  7'b0100000  // andn/orn/xnor (f3=111/110/100) — shares SUB/SRA f7
`define F7_MINMAX   7'b0000101  // min/minu/max/maxu (f3=100/101/110/111)
`define F7_ROT      7'b0110000  // rol(001)/ror(101); OP-IMM: clz/ctz/cpop/sext (001 + rs2 sel), rori(101)
`define F7_BCLR_EXT 7'b0100100  // bclr(001)/bext(101) (+ *i forms in OP-IMM)
`define F7_BINV     7'b0110100  // binv(001); OP-IMM 101: rev8 (rs2=11000)
`define F7_BSET     7'b0010100  // bset(001); OP-IMM 101: orc.b (rs2=00111)
`define F7_ZEXTH    7'b0000100  // zext.h (OP, f3=100, rs2=00000)
`define F7_ZICOND   7'b0000111  // czero.eqz(101)/czero.nez(111)


// -----------------------------------------------------------------------------
// Branch 條件碼 (3-bit, 直接用 funct3 即可)
//   core.v 將 funct3 餵給 branch comparator，所以無需獨立 encoding
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// CPU FSM state (6 個 state，one-hot 編碼，方便波形觀察)
//   TRAP 用於 ebreak / illegal instruction，永久停留等 reset
// -----------------------------------------------------------------------------
`define ST_FETCH    6'b000001
`define ST_DECODE   6'b000010
`define ST_EXEC     6'b000100
`define ST_MEM      6'b001000
`define ST_WB       6'b010000
`define ST_TRAP     6'b100000

// -----------------------------------------------------------------------------
// Memory request type (1-bit: 給 mem_instr 用)
// -----------------------------------------------------------------------------
`define MEM_FETCH   1'b1   // instruction fetch
`define MEM_DATA    1'b0   // load/store

// -----------------------------------------------------------------------------
// Reset / 例外向量
// -----------------------------------------------------------------------------
`define PC_RESET    32'h0000_0000  // 與 lab01 / firmware.lds 一致

// =============================================================================
// 以下是 lab05 新增 (CSR + M-mode IRQ + counters)
// =============================================================================

// -----------------------------------------------------------------------------
// CSR address (12-bit)
// -----------------------------------------------------------------------------
`define CSR_MSTATUS  12'h300
`define CSR_MIE      12'h304
`define CSR_MTVEC    12'h305
`define CSR_MSCRATCH 12'h340
`define CSR_MEPC     12'h341
`define CSR_MTVAL    12'h343
`define CSR_MCAUSE   12'h342
`define CSR_MIP      12'h344
`define CSR_MISA     12'h301
`define CSR_PMPCFG0  12'h3A0
`define CSR_PMPCFG1  12'h3A1
`define CSR_PMPADDR0 12'h3B0
`define CSR_PMPADDR1 12'h3B1
`define CSR_PMPADDR2 12'h3B2
`define CSR_PMPADDR3 12'h3B3
`define CSR_PMPADDR4 12'h3B4
`define CSR_PMPADDR5 12'h3B5
`define CSR_PMPADDR6 12'h3B6
`define CSR_PMPADDR7 12'h3B7

`define CSR_CYCLE    12'hC00
`define CSR_CYCLEH   12'hC80
`define CSR_INSTRET  12'hC02
`define CSR_INSTRETH 12'hC82
`define CSR_DCSR     12'h7B0
`define CSR_DPC      12'h7B1
`define CSR_DSCRATCH0 12'h7B2
`define CSR_TSELECT  12'h7A0
`define CSR_TDATA1   12'h7A1
`define CSR_TDATA2   12'h7A2
`define CSR_TINFO    12'h7A4

// -----------------------------------------------------------------------------
// CSR 操作 (funct3[1:0]; funct3[2] 區分 imm/reg 由 core.v 處理)
// -----------------------------------------------------------------------------
`define CSR_OP_W     2'b01   // CSRRW(I)  csr <- rhs
`define CSR_OP_S     2'b10   // CSRRS(I)  csr <- old | rhs
`define CSR_OP_C     2'b11   // CSRRC(I)  csr <- old & ~rhs

// -----------------------------------------------------------------------------
// IRQ cause (mcause 內容)
// -----------------------------------------------------------------------------
`define MCAUSE_EXT_IRQ 32'h8000_000B  // bit 31 = 1 (interrupt), code 11 = M ext
`define MCAUSE_TIMER_IRQ 32'h8000_0007 // code 7 = M timer (CLINT mtime>=mtimecmp), ADR-0019
`define MCAUSE_MSW_IRQ   32'h8000_0003 // code 3 = M software (CLINT msip), ADR-0019
`define MCAUSE_ILLEGAL_INSTRUCTION 32'h0000_0002
`define MCAUSE_BREAKPOINT 32'h0000_0003
`define MCAUSE_LOAD_ADDR_MISALIGNED 32'h0000_0004
`define MCAUSE_STORE_ADDR_MISALIGNED 32'h0000_0006
`define MCAUSE_INSTR_ACCESS_FAULT 32'h0000_0001
`define MCAUSE_LOAD_ACCESS_FAULT 32'h0000_0005
`define MCAUSE_STORE_ACCESS_FAULT 32'h0000_0007
`define MCAUSE_ECALL_MMODE 32'h0000_000B

// -----------------------------------------------------------------------------
// mstatus bit positions
// -----------------------------------------------------------------------------
`define MSTATUS_MIE_BIT  3
`define MSTATUS_MPIE_BIT 7
`define MSTATUS_MPP_LO_BIT 11
`define MSTATUS_MPP_HI_BIT 12

// -----------------------------------------------------------------------------
// mie / mip bit positions
// -----------------------------------------------------------------------------
`define MIE_MEIE_BIT 11
`define MIP_MEIP_BIT 11
`define MIE_MTIE_BIT 7      // M timer interrupt enable (ADR-0019)
`define MIP_MTIP_BIT 7      // M timer interrupt pending (CLINT-sourced, RO)
`define MIE_MSIE_BIT 3      // M software interrupt enable (ADR-0019)
`define MIP_MSIP_BIT 3      // M software interrupt pending (CLINT-sourced, RO)

// -----------------------------------------------------------------------------
// MRET instruction (full 32-bit pattern)
//   funct12 = 0x302, rs1=0, funct3=0, rd=0, opcode=SYSTEM
// -----------------------------------------------------------------------------
`define INSTR_MRET   32'h3020_0073
`define INSTR_DRET   32'h7B20_0073

// -----------------------------------------------------------------------------
// Extended next-PC source for IFU (lab05 adds 2'b11)
//   00 = pc+4, 01 = pc+imm, 10 = jalr (alu_result & ~1), 11 = special (mtvec/mepc)
// -----------------------------------------------------------------------------

// =============================================================================
// 以下是 lab06 新增 (3-stage pipeline + RV32M extension)
// =============================================================================

// -----------------------------------------------------------------------------
// RV32M funct7 (與 RV32I OP 共用 opcode 0110011，但 funct7 不同)
//   RV32I OP : funct7 = 0000000 (default) / 0100000 (SUB/SRA)
//   RV32M    : funct7 = 0000001
// -----------------------------------------------------------------------------
`define F7_MULDIV    7'b0000001

// -----------------------------------------------------------------------------
// RV32A funct5 (instr[31:27]) for .W atomics (funct3=010)
// -----------------------------------------------------------------------------
`define AMO_F5_ADD    5'b00000
`define AMO_F5_SWAP   5'b00001
`define AMO_F5_LR     5'b00010
`define AMO_F5_SC     5'b00011
`define AMO_F5_XOR    5'b00100
`define AMO_F5_OR     5'b01000
`define AMO_F5_AND    5'b01100
`define AMO_F5_MIN    5'b10000
`define AMO_F5_MAX    5'b10100
`define AMO_F5_MINU   5'b11000
`define AMO_F5_MAXU   5'b11100

`define AMO_OP_ADD    4'd0
`define AMO_OP_SWAP   4'd1
`define AMO_OP_XOR    4'd2
`define AMO_OP_OR     4'd3
`define AMO_OP_AND    4'd4
`define AMO_OP_MIN    4'd5
`define AMO_OP_MAX    4'd6
`define AMO_OP_MINU   4'd7
`define AMO_OP_MAXU   4'd8

// -----------------------------------------------------------------------------
// MD (mul/div) 操作碼 — 直接複用 funct3 (8 種)
//   MUL/MULH/MULHSU/MULHU 走 mul.v
//   DIV/DIVU/REM/REMU     走 div.v (用 funct3[2] 區分)
// -----------------------------------------------------------------------------
`define MD_MUL       3'b000
`define MD_MULH      3'b001
`define MD_MULHSU    3'b010
`define MD_MULHU     3'b011
`define MD_DIV       3'b100
`define MD_DIVU      3'b101
`define MD_REM       3'b110
`define MD_REMU      3'b111

// -----------------------------------------------------------------------------
// Write-back source (lab06 比 lab05 多一個 MD)
//   000=ALU 001=PC+imm 010=PC+4 011=LSU 100=CSR 101=MD (lab06 新增)
// -----------------------------------------------------------------------------
`define WB_SEL_ALU    3'b000
`define WB_SEL_PCIMM  3'b001
`define WB_SEL_PC4    3'b010
`define WB_SEL_LSU    3'b011
`define WB_SEL_CSR    3'b100
`define WB_SEL_MD     3'b101

// -----------------------------------------------------------------------------
// DIV by zero / overflow 預期結果 (RISC-V Spec)
// -----------------------------------------------------------------------------
`define DIV_BY_ZERO_QUOT    32'hFFFF_FFFF   // 既 signed=-1 也 unsigned=max
`define DIV_OVERFLOW_QUOT   32'h8000_0000   // INT_MIN

`endif // DEF_VH
