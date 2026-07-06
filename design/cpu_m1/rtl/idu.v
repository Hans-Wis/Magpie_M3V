// =============================================================================
// idu.v — Instruction Decode Unit (純組合)  [lab05 版本]
// -----------------------------------------------------------------------------
// 變動於 lab04：
//   * 加 CSR* 指令解碼 (CSRRW/RS/RC + 3 個 immediate 版本)
//   * 加 MRET 偵測 (完整 32-bit pattern 比對)
//   * wb_sel 從 2-bit 擴成 3-bit，多一個 source = csr_rdata
//   * illegal 判斷重寫：SYSTEM 不再一律 trap，CSR 跟 MRET 是合法
//
// 把 32-bit instruction 拆成：
//   - 暫存器索引 (rd, rs1, rs2)
//   - sign-extended immediate (I/S/B/U/J 五種格式都處理)
//   - ALU 控制 (alu_op, alu_b_use_imm)
//   - Write-back / next-PC / memory 控制
//   - CSR 控制 (is_csr / csr_op / csr_uses_imm / csr_addr / csr_zimm)
//   - is_mret (給 core 在 WB 把 PC ← mepc)
//   - illegal flag → core.v 觸發 trap (ebreak / ecall 走這條)
//
// 此模組沒有任何 register / clock，是純組合邏輯。
// =============================================================================

`include "def.vh"

module idu #(
    parameter RV32A = 0,
    parameter EN_RVV = 0,
    parameter EN_F = 0
) (
    input  [31:0] instr,

    // Register indices
    output [ 4:0] rd_idx,
    output [ 4:0] rs1_idx,
    output [ 4:0] rs2_idx,

    // Sign-extended immediate
    output reg [31:0] imm,

    // ALU control
    output reg [ 3:0] alu_op,
    output            alu_b_use_imm,

    // M1A A2 (ADR-0026): BMU (Zba/Zbb/Zbs/Zicond) control — single-cycle EX unit
    output reg        is_bmu,
    output reg [ 4:0] bmu_op,

    // Write-back control
    output            rd_we,
    output reg [ 2:0] wb_sel,         // 000=ALU 001=PC+imm 010=PC+4 011=LSU 100=CSR

    // Branch / jump control
    output            is_branch,
    output            branch_invert,   // 1 = BNE/BGE/BGEU
    output      [1:0] br_type,         // funct3[2:1]: 00=eq 10=lt_s 11=lt_u (valid when is_branch)
    output            is_jal,
    output            is_jalr,

    // Memory control
    output            is_load,
    output            is_store,
    output [ 2:0]     ls_funct3,

    // RV32A atomics (optional, ADR-0023)
    output            is_amo,
    output            amo_is_lr,
    output            amo_is_sc,
    output [ 3:0]     amo_op,

    // CSR / MRET (lab05 新加)
    output            is_csr,
    output [ 1:0]     csr_op,         // CSR_OP_W/S/C (def.vh)
    output            csr_uses_imm,    // 0 = use rs1, 1 = use zimm
    output [11:0]     csr_addr,
    output [31:0]     csr_zimm,
    output            is_mret,
    output            is_dret,

    // M extension (lab06 新加)
    output            is_muldiv,       // 1 = RV32M 指令 (mul/div family)
    output [ 2:0]     md_op,           // = funct3 (MD_MUL/MULH/.../REMU)
    output            md_is_div,       // 1 = 走 div unit; 0 = 走 mul unit

    // RVV Stage 3A config instruction (OP-V funct3=111: vsetvli/vsetivli/vsetvl)
    output            is_vset,
    // RVV Stage 3B: OP-V execute-class funct3s (OPIVV/OPMVV/OPIVI/OPIVX/OPMVX) —
    // routed to vexu at EX; op-level legality is vexu's q_illegal. Float funct3s
    // (001/101) stay unknown-opcode illegal (Zve32x has no vector FP).
    output            is_vexec,

    // Exception
    output            is_fexec,    // ADR-0050: F opcode spaces (fexu judges ops)
    output            illegal
);

    // -------------------------------------------------------------------------
    // 拆 instruction field
    // -------------------------------------------------------------------------
    wire [ 6:0] opcode = instr[ 6: 0];
    wire [ 2:0] funct3 = instr[14:12];
    /* verilator lint_off UNUSEDSIGNAL */
    wire [ 6:0] funct7 = instr[31:25]; // RV32I 只實際讀 funct7[5] (SUB/SRA bit)
    /* verilator lint_on UNUSEDSIGNAL */
    wire [ 4:0] funct5 = instr[31:27];

    assign rd_idx  = instr[11: 7];
    assign rs1_idx = instr[19:15];
    assign rs2_idx = instr[24:20];

    // -------------------------------------------------------------------------
    // 五種 immediate 格式 (RISC-V spec)
    // -------------------------------------------------------------------------
    wire [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};
    wire [31:0] imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    wire [31:0] imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    wire [31:0] imm_u = {instr[31:12], 12'b0};
    wire [31:0] imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

    // -------------------------------------------------------------------------
    // 主分類 (基於 opcode)
    // -------------------------------------------------------------------------
    wire is_lui    = (opcode == `OPC_LUI);
    wire is_auipc  = (opcode == `OPC_AUIPC);
    wire is_op_imm = (opcode == `OPC_OP_IMM);
    wire is_op     = (opcode == `OPC_OP);
    wire is_system = (opcode == `OPC_SYSTEM);
    wire is_fence  = (opcode == `OPC_FENCE);
    wire is_amo_opcode = (opcode == `OPC_AMO);
    wire is_op_v   = (opcode == `OPC_OP_V);

    assign is_jal    = (opcode == `OPC_JAL);
    assign is_jalr   = (opcode == `OPC_JALR) && (funct3 == 3'b000);
    assign is_branch = (opcode == `OPC_BRANCH);
    assign is_load  = ((opcode == `OPC_LOAD)) | is_fmem_ld;
    assign is_store = ((opcode == `OPC_STORE)) | is_fmem_st;

    wire amo_funct5_valid =
        (funct5 == `AMO_F5_ADD)  || (funct5 == `AMO_F5_SWAP) ||
        (funct5 == `AMO_F5_LR)   || (funct5 == `AMO_F5_SC)   ||
        (funct5 == `AMO_F5_XOR)  || (funct5 == `AMO_F5_OR)   ||
        (funct5 == `AMO_F5_AND)  || (funct5 == `AMO_F5_MIN)  ||
        (funct5 == `AMO_F5_MAX)  || (funct5 == `AMO_F5_MINU) ||
        (funct5 == `AMO_F5_MAXU);
    assign is_amo    = (RV32A != 0) && is_amo_opcode && (funct3 == `F3_LW) &&
                       amo_funct5_valid && ((funct5 != `AMO_F5_LR) || (rs2_idx == 5'd0));
    assign amo_is_lr = is_amo && (funct5 == `AMO_F5_LR);
    assign amo_is_sc = is_amo && (funct5 == `AMO_F5_SC);
    assign amo_op    =
        (funct5 == `AMO_F5_SWAP) ? `AMO_OP_SWAP :
        (funct5 == `AMO_F5_XOR)  ? `AMO_OP_XOR  :
        (funct5 == `AMO_F5_OR)   ? `AMO_OP_OR   :
        (funct5 == `AMO_F5_AND)  ? `AMO_OP_AND  :
        (funct5 == `AMO_F5_MIN)  ? `AMO_OP_MIN  :
        (funct5 == `AMO_F5_MAX)  ? `AMO_OP_MAX  :
        (funct5 == `AMO_F5_MINU) ? `AMO_OP_MINU :
        (funct5 == `AMO_F5_MAXU) ? `AMO_OP_MAXU :
                                    `AMO_OP_ADD;

    // -------------------------------------------------------------------------
    // SYSTEM opcode (lab05) 區分三類：
    //   * funct3 != 0 → CSR* (6 種，funct3 = 1/2/3/5/6/7)
    //   * 完整 32-bit instr 等於 INSTR_MRET/INSTR_DRET → MRET/DRET
    //   * 其他 (ECALL/EBREAK/WFI/SFENCE.VMA/...) → illegal → ST_TRAP
    // -------------------------------------------------------------------------
    assign is_csr  = is_system && (funct3 != 3'b000);
    assign is_mret = (instr == `INSTR_MRET);
    assign is_dret = (instr == `INSTR_DRET);

    assign csr_op       = funct3[1:0];           // 01=W, 10=S, 11=C
    assign csr_uses_imm = funct3[2];             // 0=use rs1, 1=use zimm
    assign csr_addr     = instr[31:20];
    assign csr_zimm     = {27'b0, instr[19:15]}; // zero-ext rs1 field

    // -------------------------------------------------------------------------
    // M extension (lab06): opcode = OP (0110011) + funct7 = 0000001
    //   funct3 直接編碼成 md_op:
    //     000 MUL    001 MULH   010 MULHSU 011 MULHU
    //     100 DIV    101 DIVU   110 REM    111 REMU
    //   md_is_div = funct3[2] (DIV/DIVU/REM/REMU)
    // -------------------------------------------------------------------------
    assign is_muldiv = is_op && (funct7 == `F7_MULDIV);
    assign md_op     = funct3;
    assign md_is_div = funct3[2];

    wire opv_vsetvli  = is_op_v && (funct3 == 3'b111) && (instr[31] == 1'b0);
    wire opv_vsetivli = is_op_v && (funct3 == 3'b111) && (instr[31:30] == 2'b11);
    wire opv_vsetvl   = is_op_v && (funct3 == 3'b111) && (instr[31:25] == 7'b1000000);
    assign is_vset = (EN_RVV != 0) && (opv_vsetvli || opv_vsetivli || opv_vsetvl);

    // 3B execute-class OP-V (not funct3=111 config, not float 001/101).
    // 3C adds the LOAD-FP/STORE-FP opcode spaces: with no scalar F, every such
    // encoding routes to vexu, which accepts only legal unit-stride vector
    // forms and flags the rest illegal (incl. would-be FLW/FSW — same trap
    // Spike raises without F).
    // ADR-0050: with scalar F, f3=010 in the FP mem spaces is FLW/FSW (a real
    // scalar word load/store); without F it stays routed to vexu (illegal).
    wire is_fmem_ld = (EN_F != 0) && (opcode == 7'b0000111) && (funct3 == 3'b010);
    wire is_fmem_st = (EN_F != 0) && (opcode == 7'b0100111) && (funct3 == 3'b010);
    wire is_vmem_opc = ((opcode == 7'b0000111) || (opcode == 7'b0100111)) &&
                       !(is_fmem_ld || is_fmem_st);
    wire is_fexec_w = (EN_F != 0) &&
                      ((opcode == 7'b1010011) || (opcode == 7'b1000011) ||
                       (opcode == 7'b1000111) || (opcode == 7'b1001011) ||
                       (opcode == 7'b1001111)) || is_fmem_ld || is_fmem_st;
    assign is_fexec = is_fexec_w;
    assign is_vexec = (EN_RVV != 0) &&
                      ((is_op_v &&
                        ((funct3 == 3'b000) || (funct3 == 3'b010) || (funct3 == 3'b011) ||
                         (funct3 == 3'b100) || (funct3 == 3'b110))) || is_vmem_opc);
    // vector ops that write a scalar GPR rd: vmv.x.s + (Phase-D D1a) vcpop.m/vfirst.m.
    // All are OPMVV f6=010000 (VWXUNARY0); vs1 field selects: 0=vmv.x.s, 10000=vcpop,
    // 10001=vfirst. (vmv.x.s also needs vm=1; the mask-scan ones are maskable.)
    // gate on is_op_v (not is_vexec, which also covers LOAD-FP/STORE-FP mem opcodes) so
    // an illegal segment/mem encoding with f3=010 & f6=010000 can't assert scalar rd_we
    // (Codex whole-design review — squashed by the trap today, but a cleaner classification).
    wire opv_vwx0   = is_op_v && (funct3 == 3'b010) && (instr[31:26] == 6'b010000);
    wire opv_mv_x_s = opv_vwx0 && (instr[19:15] == 5'd0) && instr[25];
    wire opv_vcpop  = opv_vwx0 && (instr[19:15] == 5'b10000);
    wire opv_vfirst = opv_vwx0 && (instr[19:15] == 5'b10001);
    wire opv_scalar_rd = opv_mv_x_s || opv_vcpop || opv_vfirst;

    // -------------------------------------------------------------------------
    // Immediate mux
    // -------------------------------------------------------------------------
    always @* begin
        case (1'b1)
            is_lui, is_auipc            : imm = imm_u;
            is_jal                      : imm = imm_j;
            is_jalr, is_load, is_op_imm : imm = imm_i;
            is_amo                      : imm = 32'h0;
            is_store                    : imm = imm_s;
            is_branch                   : imm = imm_b;
            default                     : imm = 32'h0;
        endcase
    end

    // -------------------------------------------------------------------------
    // ALU 控制
    //   * OP-IMM / OP: funct3 + funct7 決定 alu_op
    //   * BRANCH     : funct3 決定比較類型，branch_invert 處理 != / ≥ 系列
    //   * LOAD/STORE/JALR/AUIPC: ALU 做 ADD (rs1 + imm) 或 (pc + imm)
    //                            但 PC-relative 用 core 的 pc adder，故此處只
    //                            需要 rs1+imm 的 case
    //   * LUI        : ALU 用 COPY_B (op_b = imm_u → result = imm)
    // -------------------------------------------------------------------------
    wire is_sub_or_sra = funct7[5]; // F7_SUB_SRA bit (用 bit 5 一條判斷取代 7-bit 比較)

    always @* begin
        alu_op = `ALU_ADD;  // 預設加法 (load/store/jalr/auipc 都用 ADD)

        if (is_op_imm) begin
            case (funct3)
                `F3_ADD_SUB : alu_op = `ALU_ADD;   // ADDI (沒有 SUBI)
                `F3_SLT     : alu_op = `ALU_SLT;
                `F3_SLTU    : alu_op = `ALU_SLTU;
                `F3_XOR     : alu_op = `ALU_XOR;
                `F3_OR      : alu_op = `ALU_OR;
                `F3_AND     : alu_op = `ALU_AND;
                `F3_SLL     : alu_op = `ALU_SLL;
                `F3_SRL_SRA : alu_op = is_sub_or_sra ? `ALU_SRA : `ALU_SRL;
                // verilator coverage_off
                default     : alu_op = `ALU_ADD;
                // verilator coverage_on
                // ^ CS-COV-1 exclusion: funct3 is 3-bit fully enumerated — coding standard CS-COV-1: defensive arm, unreachable by construction
            endcase
        end else if (is_op) begin
            case (funct3)
                `F3_ADD_SUB : alu_op = is_sub_or_sra ? `ALU_SUB : `ALU_ADD;
                `F3_SLT     : alu_op = `ALU_SLT;
                `F3_SLTU    : alu_op = `ALU_SLTU;
                `F3_XOR     : alu_op = `ALU_XOR;
                `F3_OR      : alu_op = `ALU_OR;
                `F3_AND     : alu_op = `ALU_AND;
                `F3_SLL     : alu_op = `ALU_SLL;
                `F3_SRL_SRA : alu_op = is_sub_or_sra ? `ALU_SRA : `ALU_SRL;
                // verilator coverage_off
                default     : alu_op = `ALU_ADD;
                // verilator coverage_on
                // ^ CS-COV-1 exclusion: funct3 is 3-bit fully enumerated — coding standard CS-COV-1: defensive arm, unreachable by construction
            endcase
        end else if (is_branch) begin
            case (funct3)
                `F3_BEQ, `F3_BNE   : alu_op = `ALU_SEQ;
                `F3_BLT, `F3_BGE   : alu_op = `ALU_SLT;
                `F3_BLTU, `F3_BGEU : alu_op = `ALU_SLTU;
                default            : alu_op = `ALU_SEQ;
            endcase
        end else if (is_lui) begin
            alu_op = `ALU_COPY_B; // result = imm_u
        end
        // 其他 case (load/store/jalr/auipc/jal/fence) → ALU_ADD (default)
    end

    // -------------------------------------------------------------------------
    // M1A A2: BMU decode (Zba/Zbb/Zbs/Zicond) + OP/OP-IMM reserved-space tightening
    //   Encoding truth source: flow/v2_pipeline/phase_a2_zb_zicond/toolchain_probe.S
    //   disasm (gcc 13.2) + Spike retire log. Undecoded funct7 slots in the OP space
    //   and the OP-IMM shift rows (f3=001/101) are ILLEGAL (negative-tested) — note
    //   the M1 baseline silently wrong-decoded these reserved encodings as base ops.
    // -------------------------------------------------------------------------
    wire [4:0] zbb_sel = rs2_idx;   // OP-IMM f3=001 unary selector / rs2 pattern checks

    reg bmu_slot_illegal;           // reserved encoding inside an otherwise-known opcode
    always @* begin
        is_bmu = 1'b0;
        bmu_op = `BMU_SH1ADD;
        bmu_slot_illegal = 1'b0;
        if (is_op) begin
            case (funct7)
                `F7_DEFAULT, `F7_MULDIV: ;                       // base RV32I / M — legal, not BMU
                `F7_SUB_SRA: begin                               // SUB/SRA base + Zbb andn/orn/xnor
                    case (funct3)
                        3'b000, 3'b101: ;                        // SUB / SRA (base)
                        3'b111: begin is_bmu = 1'b1; bmu_op = `BMU_ANDN; end
                        3'b110: begin is_bmu = 1'b1; bmu_op = `BMU_ORN;  end
                        3'b100: begin is_bmu = 1'b1; bmu_op = `BMU_XNOR; end
                        default: bmu_slot_illegal = 1'b1;
                    endcase
                end
                `F7_ZBA: begin
                    case (funct3)
                        3'b010: begin is_bmu = 1'b1; bmu_op = `BMU_SH1ADD; end
                        3'b100: begin is_bmu = 1'b1; bmu_op = `BMU_SH2ADD; end
                        3'b110: begin is_bmu = 1'b1; bmu_op = `BMU_SH3ADD; end
                        default: bmu_slot_illegal = 1'b1;
                    endcase
                end
                `F7_MINMAX: begin
                    case (funct3)
                        3'b100: begin is_bmu = 1'b1; bmu_op = `BMU_MIN;  end
                        3'b101: begin is_bmu = 1'b1; bmu_op = `BMU_MINU; end
                        3'b110: begin is_bmu = 1'b1; bmu_op = `BMU_MAX;  end
                        3'b111: begin is_bmu = 1'b1; bmu_op = `BMU_MAXU; end
                        default: bmu_slot_illegal = 1'b1;       // clmul* (Zbc) not implemented
                    endcase
                end
                `F7_ROT: begin
                    case (funct3)
                        3'b001: begin is_bmu = 1'b1; bmu_op = `BMU_ROL; end
                        3'b101: begin is_bmu = 1'b1; bmu_op = `BMU_ROR; end
                        default: bmu_slot_illegal = 1'b1;
                    endcase
                end
                `F7_BCLR_EXT: begin
                    case (funct3)
                        3'b001: begin is_bmu = 1'b1; bmu_op = `BMU_BCLR; end
                        3'b101: begin is_bmu = 1'b1; bmu_op = `BMU_BEXT; end
                        default: bmu_slot_illegal = 1'b1;
                    endcase
                end
                `F7_BINV:
                    if (funct3 == 3'b001) begin is_bmu = 1'b1; bmu_op = `BMU_BINV; end
                    else bmu_slot_illegal = 1'b1;
                `F7_BSET:
                    if (funct3 == 3'b001) begin is_bmu = 1'b1; bmu_op = `BMU_BSET; end
                    else bmu_slot_illegal = 1'b1;
                `F7_ZEXTH:
                    if (funct3 == 3'b100 && zbb_sel == 5'b00000) begin
                        is_bmu = 1'b1; bmu_op = `BMU_ZEXTH;
                    end else bmu_slot_illegal = 1'b1;
                `F7_ZICOND: begin
                    case (funct3)
                        3'b101: begin is_bmu = 1'b1; bmu_op = `BMU_CZEQZ; end
                        3'b111: begin is_bmu = 1'b1; bmu_op = `BMU_CZNEZ; end
                        default: bmu_slot_illegal = 1'b1;
                    endcase
                end
                default: bmu_slot_illegal = 1'b1;               // any other funct7 in OP = reserved
            endcase
        end else if (is_op_imm && funct3 == 3'b001) begin       // shift-left row
            case (funct7)
                `F7_DEFAULT: ;                                   // SLLI (base)
                `F7_ROT: begin                                   // unary Zbb (rs2 field selects)
                    is_bmu = 1'b1;
                    case (zbb_sel)
                        5'b00000: bmu_op = `BMU_CLZ;
                        5'b00001: bmu_op = `BMU_CTZ;
                        5'b00010: bmu_op = `BMU_CPOP;
                        5'b00100: bmu_op = `BMU_SEXTB;
                        5'b00101: bmu_op = `BMU_SEXTH;
                        default : begin is_bmu = 1'b0; bmu_slot_illegal = 1'b1; end
                    endcase
                end
                `F7_BCLR_EXT: begin is_bmu = 1'b1; bmu_op = `BMU_BCLR; end   // bclri
                `F7_BINV    : begin is_bmu = 1'b1; bmu_op = `BMU_BINV; end   // binvi
                `F7_BSET    : begin is_bmu = 1'b1; bmu_op = `BMU_BSET; end   // bseti
                // verilator coverage_off
                default     : bmu_slot_illegal = 1'b1;
                // verilator coverage_on
                // ^ CS-COV-1 exclusion: reserved-encoding decode-catch; reached ONLY by illegal
                //   instructions (never emitted by legal-SKU traffic). Trap BEHAVIOR is directed-
                //   verified: gate_a2 illegal-negative (4 reserved -> mcause=2) + ERRATA-0002 probe->div.
            endcase
        end else if (is_op_imm && funct3 == 3'b101) begin       // shift-right row
            case (funct7)
                `F7_DEFAULT, `F7_SUB_SRA: ;                      // SRLI / SRAI (base)
                `F7_ROT     : begin is_bmu = 1'b1; bmu_op = `BMU_ROR;  end   // rori
                `F7_BCLR_EXT: begin is_bmu = 1'b1; bmu_op = `BMU_BEXT; end   // bexti
                `F7_BSET:
                    if (zbb_sel == 5'b00111) begin is_bmu = 1'b1; bmu_op = `BMU_ORCB; end
                    else bmu_slot_illegal = 1'b1;
                `F7_BINV:
                    if (zbb_sel == 5'b11000) begin is_bmu = 1'b1; bmu_op = `BMU_REV8; end
                    else bmu_slot_illegal = 1'b1;
                // verilator coverage_off
                default     : bmu_slot_illegal = 1'b1;
                // verilator coverage_on
                // ^ CS-COV-1 exclusion: reserved-encoding decode-catch; reached ONLY by illegal
                //   instructions (never emitted by legal-SKU traffic). Trap BEHAVIOR is directed-
                //   verified: gate_a2 illegal-negative (4 reserved -> mcause=2) + ERRATA-0002 probe->div.
            endcase
        end
    end

    // BRANCH operand 也是 rs2，不是 imm
    assign alu_b_use_imm = is_op_imm | is_lui | is_auipc | is_load | is_store | is_amo
                         | is_jal     | is_jalr;

    assign branch_invert = is_branch && (funct3 == `F3_BNE ||
                                         funct3 == `F3_BGE ||
                                         funct3 == `F3_BGEU);
    assign br_type = funct3[2:1]; // 00=BEQ/BNE(eq) 10=BLT/BGE(lt_s) 11=BLTU/BGEU(lt_u)

    // -------------------------------------------------------------------------
    // Write-back 控制
    // -------------------------------------------------------------------------
    assign rd_we = is_op | is_op_imm | is_lui | is_auipc
                 | is_jal | is_jalr | (is_load & ~is_fmem_ld) | is_csr | is_amo
                 | is_vset | opv_scalar_rd;

    always @* begin
        case (1'b1)
            is_auipc       : wb_sel = `WB_SEL_PCIMM; // pc + imm
            is_jal, is_jalr: wb_sel = `WB_SEL_PC4;   // pc + 4 (link)
            is_load, is_amo: wb_sel = `WB_SEL_LSU;
            is_csr         : wb_sel = `WB_SEL_CSR;   // csr_rdata (lab05)
            is_muldiv      : wb_sel = `WB_SEL_MD;    // mul/div (lab06)
            default        : wb_sel = `WB_SEL_ALU;   // LUI / OP / OP-IMM
        endcase
    end

    // -------------------------------------------------------------------------
    // 記憶體存取
    // -------------------------------------------------------------------------
    assign ls_funct3 = is_amo ? `F3_LW : funct3;

    // -------------------------------------------------------------------------
    // 例外
    //   * Fence  : NOP
    //   * CSR* / MRET : 合法 (lab05 新加)
    //   * ECALL / EBREAK / WFI / 其他 SYSTEM 變種 : illegal → ST_TRAP
    //   * 未知 opcode : illegal
    // -------------------------------------------------------------------------
    wire branch_funct3_valid =
        (funct3 == `F3_BEQ)  || (funct3 == `F3_BNE)  ||
        (funct3 == `F3_BLT)  || (funct3 == `F3_BGE)  ||
        (funct3 == `F3_BLTU) || (funct3 == `F3_BGEU);

    wire known_base_opcode =
        is_lui | is_auipc | is_jal | (is_branch && branch_funct3_valid)
      | is_load | is_store | is_op_imm | is_op | is_fence | is_amo
      | is_jalr | is_csr | is_mret | is_vset | is_vexec | is_fexec_w;
    wire known_opcode = known_base_opcode | is_dret;

    assign illegal = !known_opcode | bmu_slot_illegal;   // M1A A2: reserved OP/OP-IMM-shift slots trap (Spike parity)

endmodule
