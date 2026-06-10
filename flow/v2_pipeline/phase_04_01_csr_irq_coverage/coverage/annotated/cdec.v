//      // verilator_coverage annotation
        // =============================================================================
        // cdec.v — Lab08d RV32C (compressed) instruction expander
        // -----------------------------------------------------------------------------
        // 純組合模組：吃 16-bit compressed instruction，輸出 32-bit equivalent 加 illegal flag。
        //
        // 設計：直接套 RISC-V Compressed Spec v2.0 / Unprivileged Spec Ch.16 表格，每條
        // compressed instr 對應一條 32-bit RV32I/M 形式。展開後的 32-bit 餵給既有 idu.v
        // 完全 transparent (idu.v 不需要改)。
        //
        // 編碼分四個 quadrant (cinstr[1:0])：
        //   00 = Q0 (loads, stores, ADDI4SPN)
        //   01 = Q1 (arithmetic with immediate, control flow)
        //   10 = Q2 (loads/stores to sp, JR/JALR, MV/ADD)
        //   11 = 32-bit normal instruction (caller 處理，cdec 不應該被 invoke)
        //
        // 暫存器編碼：
        //   - 3-bit 'rd''/'rs1''/'rs2'' (Q0 + 部分 Q1)：映射到 x8-x15
        //   - 5-bit 'rd' / 'rs1' / 'rs2' (Q1/Q2 部分)：完整 x0-x31
        //
        // illegal output：encoding 是 reserved / rsvd-imm / 未實作 → 1。caller 把 instr
        // 當作 illegal-instr exception。LED firmware 只用 standard subset 不會踩 illegal。
        // =============================================================================
        
        `include "def.vh"
        
        module cdec (
~000132     input      [15:0] cinstr,
~000020     output reg [31:0] expanded,
 000023     output reg        illegal
        );
        
            // -------------------------------------------------------------------------
            // 提取常用 field
            // -------------------------------------------------------------------------
~000019     wire [1:0] op       = cinstr[1:0];        // quadrant
~000075     wire [2:0] funct3   = cinstr[15:13];      // 主功能
~000132     wire [4:0] rd_rs1_5 = cinstr[11:7];       // 5-bit (Q2 / 部分 Q1)
~000076     wire [4:0] rs2_5    = cinstr[6:2];        // 5-bit (Q2)
~000132     wire [2:0] rd_rs1_3 = cinstr[9:7];        // 3-bit "rs1'/rd'" (Q1)
~000054     wire [2:0] rs2_3    = cinstr[4:2];        // 3-bit "rs2'/rd'" (Q0/Q1)
~000132     wire [2:0] rs1_q0_3 = cinstr[9:7];        // 3-bit (Q0)
~000054     wire [2:0] rd_q0_3  = cinstr[4:2];        // 3-bit (Q0 c.lw target)
        
            // 3-bit → 5-bit (映射 x8-x15)
~000132     wire [4:0] rd_rs1_p = {2'b01, rd_rs1_3};
~000054     wire [4:0] rs2_p    = {2'b01, rs2_3};
        
            // -------------------------------------------------------------------------
            // Helper：組合 32-bit instr from fields
            //   為了可讀，每條 expand 直接寫成 32-bit literal pattern
            //   I-type:    imm[11:0]    rs1   funct3 rd     opcode  (imm sign-ext to 12-bit)
            //   S-type:    imm[11:5] rs2 rs1  funct3 imm[4:0] opcode
            //   B-type:    imm[12,10:5] rs2 rs1 funct3 imm[4:1,11] opcode
            //   U-type:    imm[31:12]   rd  opcode
            //   J-type:    imm[20,10:1,11,19:12]  rd  opcode
            //   R-type:    funct7   rs2  rs1  funct3 rd  opcode
            // -------------------------------------------------------------------------
        
            // 各種 immediate (compressed → 32-bit sign-ext)
            // C.ADDI4SPN: imm[5:4|9:6|2|3] from cinstr[12:5]  (10-bit zext，4-byte align)
~000132     wire [11:0] imm_addi4spn = {2'b0, cinstr[10:7], cinstr[12:11], cinstr[5], cinstr[6], 2'b0};
        
            // C.LW / C.SW: imm[5:3|2|6] from cinstr[12:10,6,5] (zext)
~000080     wire [11:0] imm_lwsw = {5'b0, cinstr[5], cinstr[12:10], cinstr[6], 2'b0};
        
            // C.ADDI / C.LI / C.ANDI: imm[5|4:0] sign-ext
~000076     wire [11:0] imm_addi = {{7{cinstr[12]}}, cinstr[6:2]};
        
            // C.LUI: imm[17|16:12] sign-ext (Notice: LUI imm 是 32-bit imm[31:12])
~000076     wire [19:0] imm_lui  = {{15{cinstr[12]}}, cinstr[6:2]};
        
            // C.ADDI16SP: imm[9|4|6|8:7|5] sign-ext (10-bit imm, 16-byte align)
~000076     wire [11:0] imm_addi16sp = {{3{cinstr[12]}}, cinstr[4:3], cinstr[5], cinstr[2], cinstr[6], 4'b0};
        
            // C.SRLI / C.SRAI / C.SLLI shamt: cinstr[12,6:2] (6-bit but RV32 只用低 5-bit)
~000076     wire [4:0] shamt = cinstr[6:2];
        
            // C.J / C.JAL: imm[11|4|9:8|10|6|7|3:1|5] sign-ext (11-bit aligned to 2-byte) → 21-bit
~000132     wire [20:0] imm_cj = {{10{cinstr[12]}}, cinstr[8], cinstr[10:9], cinstr[6], cinstr[7],
                                  cinstr[2], cinstr[11], cinstr[5:3], 1'b0};
        
            // C.BEQZ / C.BNEZ: imm[8|4:3|7:6|2:1|5] sign-ext (9-bit aligned to 2-byte) → 13-bit
~000080     wire [12:0] imm_cb = {{5{cinstr[12]}}, cinstr[6:5], cinstr[2], cinstr[11:10], cinstr[4:3], 1'b0};
        
            // C.LWSP: imm[5|4:2|7:6] from cinstr[12,6:4,3:2] zext
~000076     wire [11:0] imm_lwsp = {4'b0, cinstr[3:2], cinstr[12], cinstr[6:4], 2'b0};
        
            // C.SWSP: imm[5:2|7:6] from cinstr[12:9,8:7] zext
~000132     wire [11:0] imm_swsp = {4'b0, cinstr[8:7], cinstr[12:9], 2'b0};
        
 001320     always @* begin
 001320         expanded = 32'h0;
 001320         illegal  = 1'b0;
        
 001320         case (op)
                // =====================================================================
                // Quadrant 0 (op=00)
                // =====================================================================
~000013         2'b00: case (funct3)
%000008             3'b000: begin
                        // C.ADDI4SPN: addi rd', x2, imm
%000007                 if (cinstr[12:5] == 8'h0) illegal = 1'b1;    // imm=0 reserved
%000001                 else expanded = {imm_addi4spn, 5'd2, 3'b000, rs2_p, `OPC_OP_IMM};
                    end
%000002             3'b010: begin
                        // C.LW: lw rd', imm(rs1')
%000002                 expanded = {imm_lwsw, rd_rs1_p, 3'b010, rs2_p, `OPC_LOAD};
                    end
%000003             3'b110: begin
                        // C.SW: sw rs2', imm(rs1')
%000003                 expanded = {imm_lwsw[11:5], rs2_p, rd_rs1_p, 3'b010, imm_lwsw[4:0], `OPC_STORE};
                    end
%000003             default: illegal = 1'b1;        // C.FLD/FSD/etc 浮點/RV64-only → skip
                endcase
        
                // =====================================================================
                // Quadrant 1 (op=01)
                // =====================================================================
 000300         2'b01: case (funct3)
%000009             3'b000: begin
                        // C.NOP (rd=0,imm=0) → addi x0,x0,0; C.ADDI (rd!=0): addi rd,rd,imm
%000009                 expanded = {imm_addi, rd_rs1_5, 3'b000, rd_rs1_5, `OPC_OP_IMM};
                    end
%000000             3'b001: begin
                        // C.JAL (RV32 only): jal x1, imm
%000000                 expanded = {imm_cj[20], imm_cj[10:1], imm_cj[11], imm_cj[19:12], 5'd1, `OPC_JAL};
                    end
~000016             3'b010: begin
                        // C.LI: addi rd, x0, imm
~000016                 if (rd_rs1_5 == 5'd0) illegal = 1'b1;   // hint (skip)
~000016                 else expanded = {imm_addi, 5'd0, 3'b000, rd_rs1_5, `OPC_OP_IMM};
                    end
%000001             3'b011: begin
%000001                 if (rd_rs1_5 == 5'd2) begin
                            // C.ADDI16SP: addi x2, x2, imm
%000000                     if (cinstr[12] == 1'b0 && cinstr[6:2] == 5'b0) illegal = 1'b1;
%000000                     else expanded = {imm_addi16sp, 5'd2, 3'b000, 5'd2, `OPC_OP_IMM};
%000001                 end else begin
                            // C.LUI: lui rd, imm[17:12]
%000000                     if (rd_rs1_5 == 5'd0) illegal = 1'b1;
%000001                     else if (cinstr[12] == 1'b0 && cinstr[6:2] == 5'b0) illegal = 1'b1;
%000001                     else expanded = {imm_lui, rd_rs1_5, `OPC_LUI};
                        end
                    end
%000001             3'b100: begin
                        // 多種 sub-encoding by cinstr[11:10]
%000001                 case (cinstr[11:10])
%000000                     2'b00: begin
                                // C.SRLI: srli rd', rd', shamt
%000000                         if (cinstr[12]) illegal = 1'b1;    // RV32 不允許 shamt>=32
%000000                         else expanded = {7'b0, shamt, rd_rs1_p, 3'b101, rd_rs1_p, `OPC_OP_IMM};
                            end
%000000                     2'b01: begin
                                // C.SRAI: srai rd', rd', shamt
%000000                         if (cinstr[12]) illegal = 1'b1;
%000000                         else expanded = {7'b0100000, shamt, rd_rs1_p, 3'b101, rd_rs1_p, `OPC_OP_IMM};
                            end
%000000                     2'b10: begin
                                // C.ANDI: andi rd', rd', imm
%000000                         expanded = {imm_addi, rd_rs1_p, 3'b111, rd_rs1_p, `OPC_OP_IMM};
                            end
%000001                     2'b11: begin
                                // C.SUB/XOR/OR/AND/SUBW/ADDW
%000001                         case ({cinstr[12], cinstr[6:5]})
%000000                             3'b000: expanded = {7'b0100000, rs2_p, rd_rs1_p, 3'b000, rd_rs1_p, `OPC_OP};  // SUB
%000000                             3'b001: expanded = {7'b0000000, rs2_p, rd_rs1_p, 3'b100, rd_rs1_p, `OPC_OP};  // XOR
%000000                             3'b010: expanded = {7'b0000000, rs2_p, rd_rs1_p, 3'b110, rd_rs1_p, `OPC_OP};  // OR
%000000                             3'b011: expanded = {7'b0000000, rs2_p, rd_rs1_p, 3'b111, rd_rs1_p, `OPC_OP};  // AND
%000001                             default: illegal = 1'b1;     // RV64-only (SUBW/ADDW)
                                endcase
                            end
                        endcase
                    end
~000288             3'b101: begin
                        // C.J: jal x0, imm
~000288                 expanded = {imm_cj[20], imm_cj[10:1], imm_cj[11], imm_cj[19:12], 5'd0, `OPC_JAL};
                    end
%000000             3'b110: begin
                        // C.BEQZ: beq rs1', x0, imm
%000000                 expanded = {imm_cb[12], imm_cb[10:5], 5'd0, rd_rs1_p, 3'b000,
%000000                             imm_cb[4:1], imm_cb[11], `OPC_BRANCH};
                    end
%000002             3'b111: begin
                        // C.BNEZ: bne rs1', x0, imm
%000002                 expanded = {imm_cb[12], imm_cb[10:5], 5'd0, rd_rs1_p, 3'b001,
%000002                             imm_cb[4:1], imm_cb[11], `OPC_BRANCH};
                    end
                endcase
        
                // =====================================================================
                // Quadrant 2 (op=10)
                // =====================================================================
~000047         2'b10: case (funct3)
%000001             3'b000: begin
                        // C.SLLI: slli rd, rd, shamt
%000000                 if (cinstr[12]) illegal = 1'b1;     // RV32 不允許 shamt>=32
%000001                 else if (rd_rs1_5 == 5'd0) illegal = 1'b1;   // hint
%000001                 else expanded = {7'b0, shamt, rd_rs1_5, 3'b001, rd_rs1_5, `OPC_OP_IMM};
                    end
%000000             3'b010: begin
                        // C.LWSP: lw rd, imm(x2)
%000000                 if (rd_rs1_5 == 5'd0) illegal = 1'b1;
%000000                 else expanded = {imm_lwsp, 5'd2, 3'b010, rd_rs1_5, `OPC_LOAD};
                    end
~000046             3'b100: begin
                        // 多種 sub-encoding by cinstr[12] + rs2 zero
~000041                 if (cinstr[12] == 1'b0) begin
%000005                     if (rs2_5 == 5'd0) begin
                                // C.JR: jalr x0, rs1, 0
%000000                         if (rd_rs1_5 == 5'd0) illegal = 1'b1;     // reserved
%000000                         else expanded = {12'b0, rd_rs1_5, 3'b000, 5'd0, `OPC_JALR};
%000005                     end else begin
                                // C.MV: add rd, x0, rs2
%000005                         if (rd_rs1_5 == 5'd0) illegal = 1'b1;     // hint
%000005                         else expanded = {7'b0, rs2_5, 5'd0, 3'b000, rd_rs1_5, `OPC_OP};
                            end
~000041                 end else begin    // cinstr[12]==1
~000041                     if (rs2_5 == 5'd0) begin
~000041                         if (rd_rs1_5 == 5'd0) begin
                                    // C.EBREAK
~000041                             expanded = 32'h0010_0073;
%000000                         end else begin
                                    // C.JALR: jalr x1, rs1, 0
%000000                             expanded = {12'b0, rd_rs1_5, 3'b000, 5'd1, `OPC_JALR};
                                end
%000000                     end else begin
                                // C.ADD: add rd, rd, rs2
%000000                         if (rd_rs1_5 == 5'd0) illegal = 1'b1;     // hint
%000000                         else expanded = {7'b0, rs2_5, rd_rs1_5, 3'b000, rd_rs1_5, `OPC_OP};
                            end
                        end
                    end
%000000             3'b110: begin
                        // C.SWSP: sw rs2, imm(x2)
%000000                 expanded = {imm_swsp[11:5], rs2_5, 5'd2, 3'b010, imm_swsp[4:0], `OPC_STORE};
                    end
%000000             default: illegal = 1'b1;        // 浮點 / RV64-only
                endcase
        
                // Q3 (op=11) 不該進 cdec — caller 必須保證 cinstr[1:0] != 11
 001232         2'b11: illegal = 1'b1;
                endcase
            end
        
        endmodule
        
