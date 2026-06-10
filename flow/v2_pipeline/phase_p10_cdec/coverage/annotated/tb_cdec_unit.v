//      // verilator_coverage annotation
        `timescale 1ns/1ps
        
        module tb_cdec_unit;
~000019     reg  [15:0] cinstr;
~000019     wire [31:0] expanded;
~000010     wire        illegal;
        
            integer vectors;
            integer errors;
            integer i;
        
            localparam [6:0] OPC_LUI    = 7'b0110111;
            localparam [6:0] OPC_JAL    = 7'b1101111;
            localparam [6:0] OPC_JALR   = 7'b1100111;
            localparam [6:0] OPC_BRANCH = 7'b1100011;
            localparam [6:0] OPC_LOAD   = 7'b0000011;
            localparam [6:0] OPC_STORE  = 7'b0100011;
            localparam [6:0] OPC_OP_IMM = 7'b0010011;
            localparam [6:0] OPC_OP     = 7'b0110011;
        
            cdec dut (
                .cinstr   (cinstr),
                .expanded (expanded),
                .illegal  (illegal)
            );
        
 000136     function [4:0] prime_reg;
                input [2:0] r3;
 000136         begin
 000136             prime_reg = {2'b01, r3};
                end
            endfunction
        
 000027     function [31:0] enc_i;
                input [11:0] imm;
                input [4:0]  rs1;
                input [2:0]  funct3;
                input [4:0]  rd;
                input [6:0]  opcode;
 000027         begin
 000027             enc_i = {imm, rs1, funct3, rd, opcode};
                end
            endfunction
        
%000009     function [31:0] enc_s;
                input [11:0] imm;
                input [4:0]  rs2;
                input [4:0]  rs1;
                input [2:0]  funct3;
                input [6:0]  opcode;
%000009         begin
%000009             enc_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
                end
            endfunction
        
%000004     function [31:0] enc_b;
                input [12:0] imm;
                input [4:0]  rs2;
                input [4:0]  rs1;
                input [2:0]  funct3;
%000004         begin
%000004             enc_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], OPC_BRANCH};
                end
            endfunction
        
 000010     function [31:0] enc_r;
                input [6:0] funct7;
                input [4:0] rs2;
                input [4:0] rs1;
                input [2:0] funct3;
                input [4:0] rd;
 000010         begin
 000010             enc_r = {funct7, rs2, rs1, funct3, rd, OPC_OP};
                end
            endfunction
        
%000004     function [31:0] enc_j;
                input [20:0] imm;
                input [4:0]  rd;
%000004         begin
%000004             enc_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, OPC_JAL};
                end
            endfunction
        
%000001     function [11:0] imm_addi4spn;
                input [15:0] c;
%000001         begin
%000001             imm_addi4spn = {2'b0, c[10:7], c[12:11], c[5], c[6], 2'b0};
                end
            endfunction
        
 000016     function [11:0] imm_lwsw;
                input [15:0] c;
 000016         begin
 000016             imm_lwsw = {5'b0, c[5], c[12:10], c[6], 2'b0};
                end
            endfunction
        
%000007     function [11:0] imm_addi;
                input [15:0] c;
%000007         begin
%000007             imm_addi = {{7{c[12]}}, c[6:2]};
                end
            endfunction
        
%000003     function [19:0] imm_lui;
                input [15:0] c;
%000003         begin
%000003             imm_lui = {{15{c[12]}}, c[6:2]};
                end
            endfunction
        
%000003     function [11:0] imm_addi16sp;
                input [15:0] c;
%000003         begin
%000003             imm_addi16sp = {{3{c[12]}}, c[4:3], c[5], c[2], c[6], 4'b0};
                end
            endfunction
        
%000004     function [20:0] imm_cj;
                input [15:0] c;
%000004         begin
%000004             imm_cj = {{10{c[12]}}, c[8], c[10:9], c[6], c[7], c[2], c[11], c[5:3], 1'b0};
                end
            endfunction
        
%000004     function [12:0] imm_cb;
                input [15:0] c;
%000004         begin
%000004             imm_cb = {{5{c[12]}}, c[6:5], c[2], c[11:10], c[4:3], 1'b0};
                end
            endfunction
        
%000001     function [11:0] imm_lwsp;
                input [15:0] c;
%000001         begin
%000001             imm_lwsp = {4'b0, c[3:2], c[12], c[6:4], 2'b0};
                end
            endfunction
        
%000001     function [11:0] imm_swsp;
                input [15:0] c;
%000001         begin
%000001             imm_swsp = {4'b0, c[8:7], c[12:9], 2'b0};
                end
            endfunction
        
 000136     function golden_illegal;
                input [15:0] c;
 000136         reg [1:0] op;
 000136         reg [2:0] funct3;
 000136         reg [4:0] rd_rs1_5;
 000136         reg [4:0] rs2_5;
 000136         begin
 000136             op        = c[1:0];
 000136             funct3    = c[15:13];
 000136             rd_rs1_5  = c[11:7];
 000136             rs2_5     = c[6:2];
 000136             golden_illegal = 1'b0;
        
 000136             case (op)
 000040                 2'b00: begin
 000040                     case (funct3)
%000004                         3'b000: golden_illegal = (c[12:5] == 8'h00);
 000016                         3'b010: golden_illegal = 1'b0;
 000016                         3'b110: golden_illegal = 1'b0;
%000004                         default: golden_illegal = 1'b1;
                            endcase
                        end
 000062                 2'b01: begin
 000062                     case (funct3)
%000006                         3'b000: golden_illegal = 1'b0;
%000004                         3'b001: golden_illegal = 1'b0;
%000004                         3'b010: golden_illegal = 1'b0;
 000018                         3'b011: begin
~000010                             if (rd_rs1_5 == 5'd2)
%000008                                 golden_illegal = (c[12] == 1'b0 && c[6:2] == 5'b0);
                                    else
                                        // C.LUI: imm=0 reserved; rd=0 with imm!=0 is a HINT (NOP), not illegal (ADR-0016)
~000010                                 golden_illegal = (c[12] == 1'b0 && c[6:2] == 5'b0);
                                end
 000018                         3'b100: begin
 000018                             case (c[11:10])
%000004                                 2'b00: golden_illegal = c[12];
%000004                                 2'b01: golden_illegal = c[12];
%000002                                 2'b10: golden_illegal = 1'b0;
%000008                                 2'b11: golden_illegal = (c[12] == 1'b1);
                                    endcase
                                end
%000004                         3'b101: golden_illegal = 1'b0;
%000004                         3'b110: golden_illegal = 1'b0;
%000004                         3'b111: golden_illegal = 1'b0;
                            endcase
                        end
 000032                 2'b10: begin
 000032                     case (funct3)
%000006                         3'b000: golden_illegal = c[12];
%000004                         3'b010: golden_illegal = (rd_rs1_5 == 5'd0);
 000016                         3'b100: begin
%000008                             if (c[12] == 1'b0)
%000008                                 golden_illegal = (rs2_5 == 5'd0) && (rd_rs1_5 == 5'd0);
%000004                             else if (rs2_5 == 5'd0)
%000004                                 golden_illegal = 1'b0;
                                    else
%000004                                 golden_illegal = 1'b0;
                                end
%000002                         3'b110: golden_illegal = 1'b0;
%000004                         default: golden_illegal = 1'b1;
                            endcase
                        end
%000002                 2'b11: golden_illegal = 1'b1;
                    endcase
                end
            endfunction
        
 000068     function [31:0] golden_expand;
                input [15:0] c;
 000068         reg [1:0] op;
 000068         reg [2:0] funct3;
 000068         reg [4:0] rd_rs1_5;
 000068         reg [4:0] rs2_5;
 000068         reg [4:0] rd_rs1_p;
 000068         reg [4:0] rs2_p;
 000068         begin
 000068             op        = c[1:0];
 000068             funct3    = c[15:13];
 000068             rd_rs1_5  = c[11:7];
 000068             rs2_5     = c[6:2];
 000068             rd_rs1_p  = prime_reg(c[9:7]);
 000068             rs2_p     = prime_reg(c[4:2]);
 000068             golden_expand = 32'h0000_0000;
        
 000054             if (!golden_illegal(c)) begin
 000054                 case (op)
 000017                     2'b00: begin
 000017                         case (funct3)
%000001                             3'b000: golden_expand = enc_i(imm_addi4spn(c), 5'd2, 3'b000, rs2_p, OPC_OP_IMM);
%000008                             3'b010: golden_expand = enc_i(imm_lwsw(c), rd_rs1_p, 3'b010, rs2_p, OPC_LOAD);
%000008                             3'b110: golden_expand = enc_s(imm_lwsw(c), rs2_p, rd_rs1_p, 3'b010, OPC_STORE);
%000000                             default: golden_expand = 32'h0000_0000;
                                endcase
                            end
 000026                     2'b01: begin
 000026                         case (funct3)
%000003                             3'b000: golden_expand = enc_i(imm_addi(c), rd_rs1_5, 3'b000, rd_rs1_5, OPC_OP_IMM);
%000002                             3'b001: golden_expand = enc_j(imm_cj(c), 5'd1);
%000002                             3'b010: golden_expand = enc_i(imm_addi(c), 5'd0, 3'b000, rd_rs1_5, OPC_OP_IMM);
%000006                             3'b011: begin
%000003                                 if (rd_rs1_5 == 5'd2)
%000003                                     golden_expand = enc_i(imm_addi16sp(c), 5'd2, 3'b000, 5'd2, OPC_OP_IMM);
                                        else
%000003                                     golden_expand = {imm_lui(c), rd_rs1_5, OPC_LUI};
                                    end
%000007                             3'b100: begin
%000007                                 case (c[11:10])
%000001                                     2'b00: golden_expand = enc_i({7'b0, c[6:2]}, rd_rs1_p, 3'b101, rd_rs1_p, OPC_OP_IMM);
%000001                                     2'b01: golden_expand = enc_i({7'b0100000, c[6:2]}, rd_rs1_p, 3'b101, rd_rs1_p, OPC_OP_IMM);
%000001                                     2'b10: golden_expand = enc_i(imm_addi(c), rd_rs1_p, 3'b111, rd_rs1_p, OPC_OP_IMM);
%000004                                     2'b11: begin
%000004                                         case (c[6:5])
%000001                                             2'b00: golden_expand = enc_r(7'b0100000, rs2_p, rd_rs1_p, 3'b000, rd_rs1_p);
%000001                                             2'b01: golden_expand = enc_r(7'b0000000, rs2_p, rd_rs1_p, 3'b100, rd_rs1_p);
%000001                                             2'b10: golden_expand = enc_r(7'b0000000, rs2_p, rd_rs1_p, 3'b110, rd_rs1_p);
%000001                                             2'b11: golden_expand = enc_r(7'b0000000, rs2_p, rd_rs1_p, 3'b111, rd_rs1_p);
                                                endcase
                                            end
                                        endcase
                                    end
%000002                             3'b101: golden_expand = enc_j(imm_cj(c), 5'd0);
%000002                             3'b110: golden_expand = enc_b(imm_cb(c), 5'd0, rd_rs1_p, 3'b000);
%000002                             3'b111: golden_expand = enc_b(imm_cb(c), 5'd0, rd_rs1_p, 3'b001);
                                endcase
                            end
 000011                     2'b10: begin
 000011                         case (funct3)
%000002                             3'b000: golden_expand = enc_i({7'b0, c[6:2]}, rd_rs1_5, 3'b001, rd_rs1_5, OPC_OP_IMM);
%000001                             3'b010: golden_expand = enc_i(imm_lwsp(c), 5'd2, 3'b010, rd_rs1_5, OPC_LOAD);
%000007                             3'b100: begin
%000004                                 if (c[12] == 1'b0) begin
%000002                                     if (rs2_5 == 5'd0)
%000001                                         golden_expand = enc_i(12'b0, rd_rs1_5, 3'b000, 5'd0, OPC_JALR);
                                            else
%000002                                         golden_expand = enc_r(7'b0, rs2_5, 5'd0, 3'b000, rd_rs1_5);
%000004                                 end else begin
%000002                                     if (rs2_5 == 5'd0) begin
%000001                                         if (rd_rs1_5 == 5'd0)
%000001                                             golden_expand = 32'h0010_0073;
                                                else
%000001                                             golden_expand = enc_i(12'b0, rd_rs1_5, 3'b000, 5'd1, OPC_JALR);
%000002                                     end else begin
%000002                                         golden_expand = enc_r(7'b0, rs2_5, rd_rs1_5, 3'b000, rd_rs1_5);
                                            end
                                        end
                                    end
%000001                             3'b110: golden_expand = enc_s(imm_swsp(c), rs2_5, 5'd2, 3'b010, OPC_STORE);
%000000                             default: golden_expand = 32'h0000_0000;
                                endcase
                            end
%000000                     default: golden_expand = 32'h0000_0000;
                        endcase
                    end
                end
            endfunction
        
 000062     task check_vector;
                input [15:0] t_cinstr;
                input [8*40-1:0] tag;
 000062         reg [31:0] exp_expanded;
 000062         reg        exp_illegal;
 000062         begin
 000062             cinstr = t_cinstr;
 000062             #1;
        
 000062             exp_expanded = golden_expand(t_cinstr);
 000062             exp_illegal  = golden_illegal(t_cinstr);
 000062             vectors = vectors + 1;
~000062             if (expanded !== exp_expanded || illegal !== exp_illegal) begin
                        errors = errors + 1;
                        $error("FAIL[%0d] %0s cinstr=%h expanded=%h exp=%h illegal=%b exp_illegal=%b",
                               vectors, tag, t_cinstr, expanded, exp_expanded, illegal, exp_illegal);
                    end
                end
            endtask
        
%000006     task check_vector_expect;
                input [15:0] t_cinstr;
                input [8*40-1:0] tag;
                input [31:0] exp_expanded;
                input        exp_illegal;
%000006         reg [31:0] golden_expanded;
%000006         reg        golden_exp_illegal;
%000006         begin
%000006             cinstr = t_cinstr;
%000006             #1;
        
%000006             golden_expanded    = golden_expand(t_cinstr);
%000006             golden_exp_illegal = golden_illegal(t_cinstr);
%000006             vectors = vectors + 1;
%000006             if (golden_expanded !== exp_expanded || golden_exp_illegal !== exp_illegal ||
%000006                 expanded !== exp_expanded || illegal !== exp_illegal) begin
                        errors = errors + 1;
                        $error("FAIL[%0d] %0s cinstr=%h expanded=%h exp=%h illegal=%b exp_illegal=%b golden=%h golden_illegal=%b",
                               vectors, tag, t_cinstr, expanded, exp_expanded, illegal, exp_illegal,
                               golden_expanded, golden_exp_illegal);
                    end
                end
            endtask
        
%000001     task check_q0_lwsw_prime_rs1_sweep;
%000001         begin
%000008             for (i = 0; i < 8; i = i + 1) begin
%000008                 check_vector({3'b010, 3'b101, i[2:0], 1'b1, 1'b0, 3'b010, 2'b00}, "C.LW_RS1P_SWEEP");
%000008                 check_vector({3'b110, 3'b011, i[2:0], 1'b0, 1'b1, 3'b101, 2'b00}, "C.SW_RS1P_SWEEP");
                    end
                end
            endtask
        
%000001     initial begin
%000001         vectors = 0;
%000001         errors  = 0;
%000001         cinstr  = 16'h0000;
%000001         #1;
        
%000001         check_vector(16'h9002, "C.EBREAK");
%000001         check_vector(16'h0001, "C.NOP");
%000001         check_vector(16'h6105, "C.ADDI16SP_POS");
%000001         check_vector(16'h717d, "C.ADDI16SP_NEG");
%000001         check_vector(16'h7101, "C.ADDI16SP_NEG_LOW_ZERO");
        
%000001         check_q0_lwsw_prime_rs1_sweep();
%000001         check_vector_expect(16'h0000, "C.ADDI4SPN_ILLEGAL_ZERO", 32'h0000_0000, 1'b1);
%000001         check_vector(16'h0080, "C.ADDI4SPN_LEGAL");
%000001         check_vector(16'h2000, "Q0_ILLEGAL_FUNCT3_001");
%000001         check_vector(16'ha000, "Q0_ILLEGAL_FUNCT3_101");
        
%000001         check_vector(16'h00bd, "C.ADDI_POS_SIGNEXT_ZERO");
%000001         check_vector(16'h107d, "C.ADDI_NEG_SIGNEXT_ONE");
%000001         check_vector(16'h40fd, "C.LI_NEG");
%000001         check_vector_expect(16'h4001, "C.LI_HINT_NOP",
%000001                             enc_i(imm_addi(16'h4001), 5'd0, 3'b000, 5'd0, OPC_OP_IMM), 1'b0);
%000001         check_vector(16'h6505, "C.LUI_POS");
%000001         check_vector(16'h70fd, "C.LUI_NEG");
%000001         check_vector(16'h7501, "C.LUI_NEG_LOW_ZERO");
%000001         check_vector(16'h6001, "C.LUI_X0_ILLEGAL");
%000001         check_vector(16'h6501, "C.LUI_ZERO_IMM_ILLEGAL");
%000001         check_vector(16'h6101, "C.ADDI16SP_ILLEGAL_ZERO");
        
%000001         check_vector(16'h2011, "C.JAL_POS");
%000001         check_vector(16'h3ffd, "C.JAL_NEG");
%000001         check_vector(16'ha021, "C.J_POS");
%000001         check_vector(16'hbffd, "C.J_NEG");
%000001         check_vector(16'hc011, "C.BEQZ_POS");
%000001         check_vector(16'hdcfd, "C.BEQZ_NEG");
%000001         check_vector(16'he011, "C.BNEZ_POS");
%000001         check_vector(16'hfcfd, "C.BNEZ_NEG");
        
%000001         check_vector(16'h8005, "C.SRLI");
%000001         check_vector(16'h9005, "C.SRLI_SHAMT32_ILLEGAL");
%000001         check_vector(16'h8405, "C.SRAI");
%000001         check_vector(16'h9405, "C.SRAI_SHAMT32_ILLEGAL");
%000001         check_vector(16'h987d, "C.ANDI_NEG");
%000001         check_vector(16'h8c11, "C.SUB");
%000001         check_vector(16'h8c31, "C.XOR");
%000001         check_vector(16'h8c51, "C.OR");
%000001         check_vector(16'h8c71, "C.AND");
        
%000001         check_vector(16'h0086, "C.SLLI");
%000001         check_vector(16'h1006, "C.SLLI_SHAMT32_ILLEGAL");
%000001         check_vector_expect(16'h0002, "C.SLLI_X0_HINT_NOP",
%000001                             enc_i(12'h000, 5'd0, 3'b001, 5'd0, OPC_OP_IMM), 1'b0);
%000001         check_vector(16'h408a, "C.LWSP");
%000001         check_vector(16'h4002, "C.LWSP_X0_ILLEGAL");
%000001         check_vector(16'h8082, "C.JR");
%000001         check_vector_expect(16'h8002, "C.JR_RESERVED_ILLEGAL", 32'h0000_0000, 1'b1);
%000001         check_vector(16'h808e, "C.MV");
%000001         check_vector_expect(16'h800e, "C.MV_X0_HINT_NOP",
%000001                             enc_r(7'b0, 5'd3, 5'd0, 3'b000, 5'd0), 1'b0);
%000001         check_vector(16'h9082, "C.JALR");
%000001         check_vector(16'h908e, "C.ADD");
%000001         check_vector_expect(16'h900e, "C.ADD_X0_HINT_NOP",
%000001                             enc_r(7'b0, 5'd3, 5'd0, 3'b000, 5'd0), 1'b0);
%000001         check_vector(16'hc086, "C.SWSP");
%000001         check_vector(16'h2002, "Q2_ILLEGAL_FUNCT3_001");
%000001         check_vector(16'ha002, "Q2_ILLEGAL_FUNCT3_101");
%000001         check_vector(16'h0003, "Q3_ILLEGAL_NORMAL32");
        
%000001         if (errors == 0) begin
%000001             $display("PASS: cdec unit %0d/%0d vectors", vectors, vectors);
%000001             $finish;
                end else begin
                    $display("FAIL: cdec unit %0d/%0d vectors failed", errors, vectors);
                    $fatal(1);
                end
            end
        endmodule
        
