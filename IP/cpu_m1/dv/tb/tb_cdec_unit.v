`timescale 1ns/1ps

module tb_cdec_unit;
    reg  [15:0] cinstr;
    wire [31:0] expanded;
    wire        illegal;

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

    function [4:0] prime_reg;
        input [2:0] r3;
        begin
            prime_reg = {2'b01, r3};
        end
    endfunction

    function [31:0] enc_i;
        input [11:0] imm;
        input [4:0]  rs1;
        input [2:0]  funct3;
        input [4:0]  rd;
        input [6:0]  opcode;
        begin
            enc_i = {imm, rs1, funct3, rd, opcode};
        end
    endfunction

    function [31:0] enc_s;
        input [11:0] imm;
        input [4:0]  rs2;
        input [4:0]  rs1;
        input [2:0]  funct3;
        input [6:0]  opcode;
        begin
            enc_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
        end
    endfunction

    function [31:0] enc_b;
        input [12:0] imm;
        input [4:0]  rs2;
        input [4:0]  rs1;
        input [2:0]  funct3;
        begin
            enc_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], OPC_BRANCH};
        end
    endfunction

    function [31:0] enc_r;
        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        begin
            enc_r = {funct7, rs2, rs1, funct3, rd, OPC_OP};
        end
    endfunction

    function [31:0] enc_j;
        input [20:0] imm;
        input [4:0]  rd;
        begin
            enc_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, OPC_JAL};
        end
    endfunction

    function [11:0] imm_addi4spn;
        input [15:0] c;
        begin
            imm_addi4spn = {2'b0, c[10:7], c[12:11], c[5], c[6], 2'b0};
        end
    endfunction

    function [11:0] imm_lwsw;
        input [15:0] c;
        begin
            imm_lwsw = {5'b0, c[5], c[12:10], c[6], 2'b0};
        end
    endfunction

    function [11:0] imm_addi;
        input [15:0] c;
        begin
            imm_addi = {{7{c[12]}}, c[6:2]};
        end
    endfunction

    function [19:0] imm_lui;
        input [15:0] c;
        begin
            imm_lui = {{15{c[12]}}, c[6:2]};
        end
    endfunction

    function [11:0] imm_addi16sp;
        input [15:0] c;
        begin
            imm_addi16sp = {{3{c[12]}}, c[4:3], c[5], c[2], c[6], 4'b0};
        end
    endfunction

    function [20:0] imm_cj;
        input [15:0] c;
        begin
            imm_cj = {{10{c[12]}}, c[8], c[10:9], c[6], c[7], c[2], c[11], c[5:3], 1'b0};
        end
    endfunction

    function [12:0] imm_cb;
        input [15:0] c;
        begin
            imm_cb = {{5{c[12]}}, c[6:5], c[2], c[11:10], c[4:3], 1'b0};
        end
    endfunction

    function [11:0] imm_lwsp;
        input [15:0] c;
        begin
            imm_lwsp = {4'b0, c[3:2], c[12], c[6:4], 2'b0};
        end
    endfunction

    function [11:0] imm_swsp;
        input [15:0] c;
        begin
            imm_swsp = {4'b0, c[8:7], c[12:9], 2'b0};
        end
    endfunction

    function golden_illegal;
        input [15:0] c;
        reg [1:0] op;
        reg [2:0] funct3;
        reg [4:0] rd_rs1_5;
        reg [4:0] rs2_5;
        begin
            op        = c[1:0];
            funct3    = c[15:13];
            rd_rs1_5  = c[11:7];
            rs2_5     = c[6:2];
            golden_illegal = 1'b0;

            case (op)
                2'b00: begin
                    case (funct3)
                        3'b000: golden_illegal = (c[12:5] == 8'h00);
                        3'b010: golden_illegal = 1'b0;
                        3'b110: golden_illegal = 1'b0;
                        default: golden_illegal = 1'b1;
                    endcase
                end
                2'b01: begin
                    case (funct3)
                        3'b000: golden_illegal = 1'b0;
                        3'b001: golden_illegal = 1'b0;
                        3'b010: golden_illegal = 1'b0;
                        3'b011: begin
                            if (rd_rs1_5 == 5'd2)
                                golden_illegal = (c[12] == 1'b0 && c[6:2] == 5'b0);
                            else
                                // C.LUI: imm=0 reserved; rd=0 with imm!=0 is a HINT (NOP), not illegal (ADR-0016)
                                golden_illegal = (c[12] == 1'b0 && c[6:2] == 5'b0);
                        end
                        3'b100: begin
                            case (c[11:10])
                                2'b00: golden_illegal = c[12];
                                2'b01: golden_illegal = c[12];
                                2'b10: golden_illegal = 1'b0;
                                2'b11: golden_illegal = (c[12] == 1'b1);
                            endcase
                        end
                        3'b101: golden_illegal = 1'b0;
                        3'b110: golden_illegal = 1'b0;
                        3'b111: golden_illegal = 1'b0;
                    endcase
                end
                2'b10: begin
                    case (funct3)
                        3'b000: golden_illegal = c[12];
                        3'b010: golden_illegal = (rd_rs1_5 == 5'd0);
                        3'b100: begin
                            if (c[12] == 1'b0)
                                golden_illegal = (rs2_5 == 5'd0) && (rd_rs1_5 == 5'd0);
                            else if (rs2_5 == 5'd0)
                                golden_illegal = 1'b0;
                            else
                                golden_illegal = 1'b0;
                        end
                        3'b110: golden_illegal = 1'b0;
                        default: golden_illegal = 1'b1;
                    endcase
                end
                2'b11: golden_illegal = 1'b1;
            endcase
        end
    endfunction

    function [31:0] golden_expand;
        input [15:0] c;
        reg [1:0] op;
        reg [2:0] funct3;
        reg [4:0] rd_rs1_5;
        reg [4:0] rs2_5;
        reg [4:0] rd_rs1_p;
        reg [4:0] rs2_p;
        begin
            op        = c[1:0];
            funct3    = c[15:13];
            rd_rs1_5  = c[11:7];
            rs2_5     = c[6:2];
            rd_rs1_p  = prime_reg(c[9:7]);
            rs2_p     = prime_reg(c[4:2]);
            golden_expand = 32'h0000_0000;

            if (!golden_illegal(c)) begin
                case (op)
                    2'b00: begin
                        case (funct3)
                            3'b000: golden_expand = enc_i(imm_addi4spn(c), 5'd2, 3'b000, rs2_p, OPC_OP_IMM);
                            3'b010: golden_expand = enc_i(imm_lwsw(c), rd_rs1_p, 3'b010, rs2_p, OPC_LOAD);
                            3'b110: golden_expand = enc_s(imm_lwsw(c), rs2_p, rd_rs1_p, 3'b010, OPC_STORE);
                            default: golden_expand = 32'h0000_0000;
                        endcase
                    end
                    2'b01: begin
                        case (funct3)
                            3'b000: golden_expand = enc_i(imm_addi(c), rd_rs1_5, 3'b000, rd_rs1_5, OPC_OP_IMM);
                            3'b001: golden_expand = enc_j(imm_cj(c), 5'd1);
                            3'b010: golden_expand = enc_i(imm_addi(c), 5'd0, 3'b000, rd_rs1_5, OPC_OP_IMM);
                            3'b011: begin
                                if (rd_rs1_5 == 5'd2)
                                    golden_expand = enc_i(imm_addi16sp(c), 5'd2, 3'b000, 5'd2, OPC_OP_IMM);
                                else
                                    golden_expand = {imm_lui(c), rd_rs1_5, OPC_LUI};
                            end
                            3'b100: begin
                                case (c[11:10])
                                    2'b00: golden_expand = enc_i({7'b0, c[6:2]}, rd_rs1_p, 3'b101, rd_rs1_p, OPC_OP_IMM);
                                    2'b01: golden_expand = enc_i({7'b0100000, c[6:2]}, rd_rs1_p, 3'b101, rd_rs1_p, OPC_OP_IMM);
                                    2'b10: golden_expand = enc_i(imm_addi(c), rd_rs1_p, 3'b111, rd_rs1_p, OPC_OP_IMM);
                                    2'b11: begin
                                        case (c[6:5])
                                            2'b00: golden_expand = enc_r(7'b0100000, rs2_p, rd_rs1_p, 3'b000, rd_rs1_p);
                                            2'b01: golden_expand = enc_r(7'b0000000, rs2_p, rd_rs1_p, 3'b100, rd_rs1_p);
                                            2'b10: golden_expand = enc_r(7'b0000000, rs2_p, rd_rs1_p, 3'b110, rd_rs1_p);
                                            2'b11: golden_expand = enc_r(7'b0000000, rs2_p, rd_rs1_p, 3'b111, rd_rs1_p);
                                        endcase
                                    end
                                endcase
                            end
                            3'b101: golden_expand = enc_j(imm_cj(c), 5'd0);
                            3'b110: golden_expand = enc_b(imm_cb(c), 5'd0, rd_rs1_p, 3'b000);
                            3'b111: golden_expand = enc_b(imm_cb(c), 5'd0, rd_rs1_p, 3'b001);
                        endcase
                    end
                    2'b10: begin
                        case (funct3)
                            3'b000: golden_expand = enc_i({7'b0, c[6:2]}, rd_rs1_5, 3'b001, rd_rs1_5, OPC_OP_IMM);
                            3'b010: golden_expand = enc_i(imm_lwsp(c), 5'd2, 3'b010, rd_rs1_5, OPC_LOAD);
                            3'b100: begin
                                if (c[12] == 1'b0) begin
                                    if (rs2_5 == 5'd0)
                                        golden_expand = enc_i(12'b0, rd_rs1_5, 3'b000, 5'd0, OPC_JALR);
                                    else
                                        golden_expand = enc_r(7'b0, rs2_5, 5'd0, 3'b000, rd_rs1_5);
                                end else begin
                                    if (rs2_5 == 5'd0) begin
                                        if (rd_rs1_5 == 5'd0)
                                            golden_expand = 32'h0010_0073;
                                        else
                                            golden_expand = enc_i(12'b0, rd_rs1_5, 3'b000, 5'd1, OPC_JALR);
                                    end else begin
                                        golden_expand = enc_r(7'b0, rs2_5, rd_rs1_5, 3'b000, rd_rs1_5);
                                    end
                                end
                            end
                            3'b110: golden_expand = enc_s(imm_swsp(c), rs2_5, 5'd2, 3'b010, OPC_STORE);
                            default: golden_expand = 32'h0000_0000;
                        endcase
                    end
                    default: golden_expand = 32'h0000_0000;
                endcase
            end
        end
    endfunction

    task check_vector;
        input [15:0] t_cinstr;
        input [8*40-1:0] tag;
        reg [31:0] exp_expanded;
        reg        exp_illegal;
        begin
            cinstr = t_cinstr;
            #1;

            exp_expanded = golden_expand(t_cinstr);
            exp_illegal  = golden_illegal(t_cinstr);
            vectors = vectors + 1;
            if (expanded !== exp_expanded || illegal !== exp_illegal) begin
                errors = errors + 1;
                $error("FAIL[%0d] %0s cinstr=%h expanded=%h exp=%h illegal=%b exp_illegal=%b",
                       vectors, tag, t_cinstr, expanded, exp_expanded, illegal, exp_illegal);
            end
        end
    endtask

    task check_vector_expect;
        input [15:0] t_cinstr;
        input [8*40-1:0] tag;
        input [31:0] exp_expanded;
        input        exp_illegal;
        reg [31:0] golden_expanded;
        reg        golden_exp_illegal;
        begin
            cinstr = t_cinstr;
            #1;

            golden_expanded    = golden_expand(t_cinstr);
            golden_exp_illegal = golden_illegal(t_cinstr);
            vectors = vectors + 1;
            if (golden_expanded !== exp_expanded || golden_exp_illegal !== exp_illegal ||
                expanded !== exp_expanded || illegal !== exp_illegal) begin
                errors = errors + 1;
                $error("FAIL[%0d] %0s cinstr=%h expanded=%h exp=%h illegal=%b exp_illegal=%b golden=%h golden_illegal=%b",
                       vectors, tag, t_cinstr, expanded, exp_expanded, illegal, exp_illegal,
                       golden_expanded, golden_exp_illegal);
            end
        end
    endtask

    task check_q0_lwsw_prime_rs1_sweep;
        begin
            for (i = 0; i < 8; i = i + 1) begin
                check_vector({3'b010, 3'b101, i[2:0], 1'b1, 1'b0, 3'b010, 2'b00}, "C.LW_RS1P_SWEEP");
                check_vector({3'b110, 3'b011, i[2:0], 1'b0, 1'b1, 3'b101, 2'b00}, "C.SW_RS1P_SWEEP");
            end
        end
    endtask

    initial begin
        vectors = 0;
        errors  = 0;
        cinstr  = 16'h0000;
        #1;

        check_vector(16'h9002, "C.EBREAK");
        check_vector(16'h0001, "C.NOP");
        check_vector(16'h6105, "C.ADDI16SP_POS");
        check_vector(16'h717d, "C.ADDI16SP_NEG");
        check_vector(16'h7101, "C.ADDI16SP_NEG_LOW_ZERO");

        check_q0_lwsw_prime_rs1_sweep();
        check_vector_expect(16'h0000, "C.ADDI4SPN_ILLEGAL_ZERO", 32'h0000_0000, 1'b1);
        check_vector(16'h0080, "C.ADDI4SPN_LEGAL");
        check_vector(16'h2000, "Q0_ILLEGAL_FUNCT3_001");
        check_vector(16'ha000, "Q0_ILLEGAL_FUNCT3_101");

        check_vector(16'h00bd, "C.ADDI_POS_SIGNEXT_ZERO");
        check_vector(16'h107d, "C.ADDI_NEG_SIGNEXT_ONE");
        check_vector(16'h40fd, "C.LI_NEG");
        check_vector_expect(16'h4001, "C.LI_HINT_NOP",
                            enc_i(imm_addi(16'h4001), 5'd0, 3'b000, 5'd0, OPC_OP_IMM), 1'b0);
        check_vector(16'h6505, "C.LUI_POS");
        check_vector(16'h70fd, "C.LUI_NEG");
        check_vector(16'h7501, "C.LUI_NEG_LOW_ZERO");
        check_vector(16'h6001, "C.LUI_X0_ILLEGAL");
        check_vector(16'h6501, "C.LUI_ZERO_IMM_ILLEGAL");
        check_vector(16'h6101, "C.ADDI16SP_ILLEGAL_ZERO");

        check_vector(16'h2011, "C.JAL_POS");
        check_vector(16'h3ffd, "C.JAL_NEG");
        check_vector(16'ha021, "C.J_POS");
        check_vector(16'hbffd, "C.J_NEG");
        check_vector(16'hc011, "C.BEQZ_POS");
        check_vector(16'hdcfd, "C.BEQZ_NEG");
        check_vector(16'he011, "C.BNEZ_POS");
        check_vector(16'hfcfd, "C.BNEZ_NEG");

        check_vector(16'h8005, "C.SRLI");
        check_vector(16'h9005, "C.SRLI_SHAMT32_ILLEGAL");
        check_vector(16'h8405, "C.SRAI");
        check_vector(16'h9405, "C.SRAI_SHAMT32_ILLEGAL");
        check_vector(16'h987d, "C.ANDI_NEG");
        check_vector(16'h8c11, "C.SUB");
        check_vector(16'h8c31, "C.XOR");
        check_vector(16'h8c51, "C.OR");
        check_vector(16'h8c71, "C.AND");

        check_vector(16'h0086, "C.SLLI");
        check_vector(16'h1006, "C.SLLI_SHAMT32_ILLEGAL");
        check_vector_expect(16'h0002, "C.SLLI_X0_HINT_NOP",
                            enc_i(12'h000, 5'd0, 3'b001, 5'd0, OPC_OP_IMM), 1'b0);
        check_vector(16'h408a, "C.LWSP");
        check_vector(16'h4002, "C.LWSP_X0_ILLEGAL");
        check_vector(16'h8082, "C.JR");
        check_vector_expect(16'h8002, "C.JR_RESERVED_ILLEGAL", 32'h0000_0000, 1'b1);
        check_vector(16'h808e, "C.MV");
        check_vector_expect(16'h800e, "C.MV_X0_HINT_NOP",
                            enc_r(7'b0, 5'd3, 5'd0, 3'b000, 5'd0), 1'b0);
        check_vector(16'h9082, "C.JALR");
        check_vector(16'h908e, "C.ADD");
        check_vector_expect(16'h900e, "C.ADD_X0_HINT_NOP",
                            enc_r(7'b0, 5'd3, 5'd0, 3'b000, 5'd0), 1'b0);
        check_vector(16'hc086, "C.SWSP");
        check_vector(16'h2002, "Q2_ILLEGAL_FUNCT3_001");
        check_vector(16'ha002, "Q2_ILLEGAL_FUNCT3_101");
        check_vector(16'h0003, "Q3_ILLEGAL_NORMAL32");

        if (errors == 0) begin
            $display("PASS: cdec unit %0d/%0d vectors", vectors, vectors);
            $finish;
        end else begin
            $display("FAIL: cdec unit %0d/%0d vectors failed", errors, vectors);
            $fatal(1);
        end
    end
endmodule
