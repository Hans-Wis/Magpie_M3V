//      // verilator_coverage annotation
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
        
        module idu (
~000136     input  [31:0] instr,
        
            // Register indices
 000136     output [ 4:0] rd_idx,
 000074     output [ 4:0] rs1_idx,
 000106     output [ 4:0] rs2_idx,
        
            // Sign-extended immediate
 000091     output reg [31:0] imm,
        
            // ALU control
 000058     output reg [ 3:0] alu_op,
 000070     output            alu_b_use_imm,
        
            // Write-back control
 000038     output            rd_we,
 000053     output reg [ 2:0] wb_sel,         // 000=ALU 001=PC+imm 010=PC+4 011=LSU 100=CSR
        
            // Branch / jump control
%000000     output            is_branch,
%000000     output            branch_invert,   // 1 = BNE/BGE/BGEU
 000062     output      [1:0] br_type,         // funct3[2:1]: 00=eq 10=lt_s 11=lt_u (valid when is_branch)
%000000     output            is_jal,
%000001     output            is_jalr,
        
            // Memory control
 000029     output            is_load,
 000028     output            is_store,
 000063     output [ 2:0]     ls_funct3,
        
            // CSR / MRET (lab05 新加)
%000000     output            is_csr,
 000063     output [ 1:0]     csr_op,         // CSR_OP_W/S/C (def.vh)
 000062     output            csr_uses_imm,    // 0 = use rs1, 1 = use zimm
 000106     output [11:0]     csr_addr,
~000074     output [31:0]     csr_zimm,
%000000     output            is_mret,
        
            // M extension (lab06 新加)
 000025     output            is_muldiv,       // 1 = RV32M 指令 (mul/div family)
 000063     output [ 2:0]     md_op,           // = funct3 (MD_MUL/MULH/.../REMU)
 000062     output            md_is_div,       // 1 = 走 div unit; 0 = 走 mul unit
        
            // Exception
 000013     output            illegal
        );
        
            // -------------------------------------------------------------------------
            // 拆 instruction field
            // -------------------------------------------------------------------------
~000076     wire [ 6:0] opcode = instr[ 6: 0];
 000063     wire [ 2:0] funct3 = instr[14:12];
            /* verilator lint_off UNUSEDSIGNAL */
 000087     wire [ 6:0] funct7 = instr[31:25]; // RV32I 只實際讀 funct7[5] (SUB/SRA bit)
            /* verilator lint_on UNUSEDSIGNAL */
        
            assign rd_idx  = instr[11: 7];
            assign rs1_idx = instr[19:15];
            assign rs2_idx = instr[24:20];
        
            // -------------------------------------------------------------------------
            // 五種 immediate 格式 (RISC-V spec)
            // -------------------------------------------------------------------------
 000106     wire [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};
 000136     wire [31:0] imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
~000136     wire [31:0] imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
~000106     wire [31:0] imm_u = {instr[31:12], 12'b0};
~000106     wire [31:0] imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
        
            // -------------------------------------------------------------------------
            // 主分類 (基於 opcode)
            // -------------------------------------------------------------------------
%000005     wire is_lui    = (opcode == `OPC_LUI);
%000005     wire is_auipc  = (opcode == `OPC_AUIPC);
 000068     wire is_op_imm = (opcode == `OPC_OP_IMM);
 000062     wire is_op     = (opcode == `OPC_OP);
%000005     wire is_system = (opcode == `OPC_SYSTEM);
%000000     wire is_fence  = (opcode == `OPC_FENCE);
        
            assign is_jal    = (opcode == `OPC_JAL);
            assign is_jalr   = (opcode == `OPC_JALR) && (funct3 == 3'b000);
            assign is_branch = (opcode == `OPC_BRANCH);
            assign is_load   = (opcode == `OPC_LOAD);
            assign is_store  = (opcode == `OPC_STORE);
        
            // -------------------------------------------------------------------------
            // SYSTEM opcode (lab05) 區分三類：
            //   * funct3 != 0 → CSR* (6 種，funct3 = 1/2/3/5/6/7)
            //   * 完整 32-bit instr 等於 INSTR_MRET → MRET
            //   * 其他 (ECALL/EBREAK/WFI/SFENCE.VMA/...) → illegal → ST_TRAP
            // -------------------------------------------------------------------------
            assign is_csr  = is_system && (funct3 != 3'b000);
            assign is_mret = (instr == `INSTR_MRET);
        
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
        
            // -------------------------------------------------------------------------
            // Immediate mux
            // -------------------------------------------------------------------------
 001320     always @* begin
 001320         case (1'b1)
 000010             is_lui, is_auipc            : imm = imm_u;
%000000             is_jal                      : imm = imm_j;
 000409             is_jalr, is_load, is_op_imm : imm = imm_i;
 000037             is_store                    : imm = imm_s;
%000000             is_branch                   : imm = imm_b;
 000864             default                     : imm = 32'h0;
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
 000068     wire is_sub_or_sra = funct7[5]; // F7_SUB_SRA bit (用 bit 5 一條判斷取代 7-bit 比較)
        
 001320     always @* begin
 001320         alu_op = `ALU_ADD;  // 預設加法 (load/store/jalr/auipc 都用 ADD)
        
 000361         if (is_op_imm) begin
 000361             case (funct3)
 000274                 `F3_ADD_SUB : alu_op = `ALU_ADD;   // ADDI (沒有 SUBI)
 000017                 `F3_SLT     : alu_op = `ALU_SLT;
 000013                 `F3_SLTU    : alu_op = `ALU_SLTU;
%000006                 `F3_XOR     : alu_op = `ALU_XOR;
%000006                 `F3_OR      : alu_op = `ALU_OR;
 000011                 `F3_AND     : alu_op = `ALU_AND;
 000014                 `F3_SLL     : alu_op = `ALU_SLL;
~000191                 `F3_SRL_SRA : alu_op = is_sub_or_sra ? `ALU_SRA : `ALU_SRL;
%000000                 default     : alu_op = `ALU_ADD;
                    endcase
 000816         end else if (is_op) begin
 000816             case (funct3)
~000803                 `F3_ADD_SUB : alu_op = is_sub_or_sra ? `ALU_SUB : `ALU_ADD;
%000006                 `F3_SLT     : alu_op = `ALU_SLT;
 000021                 `F3_SLTU    : alu_op = `ALU_SLTU;
 000328                 `F3_XOR     : alu_op = `ALU_XOR;
 000152                 `F3_OR      : alu_op = `ALU_OR;
 000119                 `F3_AND     : alu_op = `ALU_AND;
 000023                 `F3_SLL     : alu_op = `ALU_SLL;
~000803                 `F3_SRL_SRA : alu_op = is_sub_or_sra ? `ALU_SRA : `ALU_SRL;
%000000                 default     : alu_op = `ALU_ADD;
                    endcase
%000000         end else if (is_branch) begin
%000000             case (funct3)
%000000                 `F3_BEQ, `F3_BNE   : alu_op = `ALU_SEQ;
%000000                 `F3_BLT, `F3_BGE   : alu_op = `ALU_SLT;
%000000                 `F3_BLTU, `F3_BGEU : alu_op = `ALU_SLTU;
%000000                 default            : alu_op = `ALU_SEQ;
                    endcase
~000138         end else if (is_lui) begin
%000005             alu_op = `ALU_COPY_B; // result = imm_u
                end
                // 其他 case (load/store/jalr/auipc/jal/fence) → ALU_ADD (default)
            end
        
            // BRANCH operand 也是 rs2，不是 imm
            assign alu_b_use_imm = is_op_imm | is_lui | is_auipc | is_load | is_store
                                 | is_jal     | is_jalr;
        
            assign branch_invert = is_branch && (funct3 == `F3_BNE ||
                                                 funct3 == `F3_BGE ||
                                                 funct3 == `F3_BGEU);
            assign br_type = funct3[2:1]; // 00=BEQ/BNE(eq) 10=BLT/BGE(lt_s) 11=BLTU/BGEU(lt_u)
        
            // -------------------------------------------------------------------------
            // Write-back 控制
            // -------------------------------------------------------------------------
            assign rd_we = is_op | is_op_imm | is_lui | is_auipc
                         | is_jal | is_jalr | is_load | is_csr;
        
 001320     always @* begin
 001320         case (1'b1)
%000005             is_auipc       : wb_sel = `WB_SEL_PCIMM; // pc + imm
%000001             is_jal, is_jalr: wb_sel = `WB_SEL_PC4;   // pc + 4 (link)
 000047             is_load        : wb_sel = `WB_SEL_LSU;
%000000             is_csr         : wb_sel = `WB_SEL_CSR;   // csr_rdata (lab05)
 000732             is_muldiv      : wb_sel = `WB_SEL_MD;    // mul/div (lab06)
 000535             default        : wb_sel = `WB_SEL_ALU;   // LUI / OP / OP-IMM
                endcase
            end
        
            // -------------------------------------------------------------------------
            // 記憶體存取
            // -------------------------------------------------------------------------
            assign ls_funct3 = funct3;
        
            // -------------------------------------------------------------------------
            // 例外
            //   * Fence  : NOP
            //   * CSR* / MRET : 合法 (lab05 新加)
            //   * ECALL / EBREAK / WFI / 其他 SYSTEM 變種 : illegal → ST_TRAP
            //   * 未知 opcode : illegal
            // -------------------------------------------------------------------------
~000011     wire known_opcode =
                is_lui | is_auipc | is_jal | is_jalr | is_branch
              | is_load | is_store | is_op_imm | is_op | is_fence
              | is_csr | is_mret;
        
            assign illegal = !known_opcode;
        
        endmodule
        
