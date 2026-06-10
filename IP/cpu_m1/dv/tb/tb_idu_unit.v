`timescale 1ns/1ps

module tb_idu_unit;
    localparam [6:0] OPC_LUI    = 7'b0110111;
    localparam [6:0] OPC_AUIPC  = 7'b0010111;
    localparam [6:0] OPC_JAL    = 7'b1101111;
    localparam [6:0] OPC_JALR   = 7'b1100111;
    localparam [6:0] OPC_BRANCH = 7'b1100011;
    localparam [6:0] OPC_LOAD   = 7'b0000011;
    localparam [6:0] OPC_STORE  = 7'b0100011;
    localparam [6:0] OPC_OP_IMM = 7'b0010011;
    localparam [6:0] OPC_OP     = 7'b0110011;
    localparam [6:0] OPC_SYSTEM = 7'b1110011;
    localparam [6:0] OPC_FENCE  = 7'b0001111;
    localparam [6:0] OPC_AMO    = 7'b0101111;

    localparam [3:0] ALU_ADD    = 4'd0;
    localparam [3:0] ALU_SUB    = 4'd1;
    localparam [3:0] ALU_AND    = 4'd2;
    localparam [3:0] ALU_OR     = 4'd3;
    localparam [3:0] ALU_XOR    = 4'd4;
    localparam [3:0] ALU_SLL    = 4'd5;
    localparam [3:0] ALU_SRL    = 4'd6;
    localparam [3:0] ALU_SRA    = 4'd7;
    localparam [3:0] ALU_SLT    = 4'd8;
    localparam [3:0] ALU_SLTU   = 4'd9;
    localparam [3:0] ALU_SEQ    = 4'd10;
    localparam [3:0] ALU_COPY_B = 4'd11;

    localparam [2:0] WB_ALU   = 3'b000;
    localparam [2:0] WB_PCIMM = 3'b001;
    localparam [2:0] WB_PC4   = 3'b010;
    localparam [2:0] WB_LSU   = 3'b011;
    localparam [2:0] WB_CSR   = 3'b100;
    localparam [2:0] WB_MD    = 3'b101;

    reg  [31:0] instr;
    wire [ 4:0] rd_idx;
    wire [ 4:0] rs1_idx;
    wire [ 4:0] rs2_idx;
    wire [31:0] imm;
    wire [ 3:0] alu_op;
    wire        alu_b_use_imm;
    wire        rd_we;
    wire [ 2:0] wb_sel;
    wire        is_branch;
    wire        branch_invert;
    wire [ 1:0] br_type;
    wire        is_jal;
    wire        is_jalr;
    wire        is_load;
    wire        is_store;
    wire [ 2:0] ls_funct3;
    wire        is_amo;
    wire        amo_is_lr;
    wire        amo_is_sc;
    wire [ 3:0] amo_op;
    wire        is_csr;
    wire [ 1:0] csr_op;
    wire        csr_uses_imm;
    wire [11:0] csr_addr;
    wire [31:0] csr_zimm;
    wire        is_mret;
    wire        is_dret;
    wire        is_muldiv;
    wire [ 2:0] md_op;
    wire        md_is_div;
    wire        illegal;

    integer vectors;
    integer errors;
    integer i;

    reg [4:0]  exp_rd_idx;
    reg [4:0]  exp_rs1_idx;
    reg [4:0]  exp_rs2_idx;
    reg [31:0] exp_imm;
    reg [3:0]  exp_alu_op;
    reg        exp_alu_b_use_imm;
    reg        exp_rd_we;
    reg [2:0]  exp_wb_sel;
    reg        exp_is_branch;
    reg        exp_branch_invert;
    reg [1:0]  exp_br_type;
    reg        exp_is_jal;
    reg        exp_is_jalr;
    reg        exp_is_load;
    reg        exp_is_store;
    reg [2:0]  exp_ls_funct3;
    reg        exp_is_amo;
    reg        exp_amo_is_lr;
    reg        exp_amo_is_sc;
    reg [3:0]  exp_amo_op;
    reg        exp_is_csr;
    reg [1:0]  exp_csr_op;
    reg        exp_csr_uses_imm;
    reg [11:0] exp_csr_addr;
    reg [31:0] exp_csr_zimm;
    reg        exp_is_mret;
    reg        exp_is_dret;
    reg        exp_is_muldiv;
    reg [2:0]  exp_md_op;
    reg        exp_md_is_div;
    reg        exp_illegal;

    idu dut (
        .instr(instr),
        .rd_idx(rd_idx),
        .rs1_idx(rs1_idx),
        .rs2_idx(rs2_idx),
        .imm(imm),
        .alu_op(alu_op),
        .alu_b_use_imm(alu_b_use_imm),
        .rd_we(rd_we),
        .wb_sel(wb_sel),
        .is_branch(is_branch),
        .branch_invert(branch_invert),
        .br_type(br_type),
        .is_jal(is_jal),
        .is_jalr(is_jalr),
        .is_load(is_load),
        .is_store(is_store),
        .ls_funct3(ls_funct3),
        .is_amo(is_amo),
        .amo_is_lr(amo_is_lr),
        .amo_is_sc(amo_is_sc),
        .amo_op(amo_op),
        .is_csr(is_csr),
        .csr_op(csr_op),
        .csr_uses_imm(csr_uses_imm),
        .csr_addr(csr_addr),
        .csr_zimm(csr_zimm),
        .is_mret(is_mret),
        .is_dret(is_dret),
        .is_muldiv(is_muldiv),
        .md_op(md_op),
        .md_is_div(md_is_div),
        .illegal(illegal)
    );

    function [31:0] r_type;
        input [6:0] f7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] f3;
        input [4:0] rd;
        input [6:0] opc;
        begin
            r_type = {f7, rs2, rs1, f3, rd, opc};
        end
    endfunction

    function [31:0] amo_type;
        input [4:0] f5;
        input       aq;
        input       rl;
        input [4:0] rs2;
        input [4:0] rs1;
        input [4:0] rd;
        begin
            amo_type = {f5, aq, rl, rs2, rs1, 3'b010, rd, OPC_AMO};
        end
    endfunction

    function [31:0] i_type;
        input [11:0] imm12;
        input [4:0]  rs1;
        input [2:0]  f3;
        input [4:0]  rd;
        input [6:0]  opc;
        begin
            i_type = {imm12, rs1, f3, rd, opc};
        end
    endfunction

    function [31:0] s_type;
        input [11:0] imm12;
        input [4:0]  rs2;
        input [4:0]  rs1;
        input [2:0]  f3;
        input [6:0]  opc;
        begin
            s_type = {imm12[11:5], rs2, rs1, f3, imm12[4:0], opc};
        end
    endfunction

    function [31:0] b_type;
        input [12:0] imm13;
        input [4:0]  rs2;
        input [4:0]  rs1;
        input [2:0]  f3;
        input [6:0]  opc;
        begin
            b_type = {imm13[12], imm13[10:5], rs2, rs1, f3, imm13[4:1], imm13[11], opc};
        end
    endfunction

    function [31:0] u_type;
        input [19:0] imm20;
        input [4:0]  rd;
        input [6:0]  opc;
        begin
            u_type = {imm20, rd, opc};
        end
    endfunction

    function [31:0] j_type;
        input [20:0] imm21;
        input [4:0]  rd;
        input [6:0]  opc;
        begin
            j_type = {imm21[20], imm21[10:1], imm21[11], imm21[19:12], rd, opc};
        end
    endfunction

    function [31:0] sext12;
        input [11:0] v;
        begin
            sext12 = {{20{v[11]}}, v};
        end
    endfunction

    function [31:0] sext13;
        input [12:0] v;
        begin
            sext13 = {{19{v[12]}}, v};
        end
    endfunction

    function [31:0] sext21;
        input [20:0] v;
        begin
            sext21 = {{11{v[20]}}, v};
        end
    endfunction

    task expect_base;
        input [31:0] t_instr;
        begin
            exp_rd_idx        = t_instr[11:7];
            exp_rs1_idx       = t_instr[19:15];
            exp_rs2_idx       = t_instr[24:20];
            exp_imm           = 32'h0000_0000;
            exp_alu_op        = ALU_ADD;
            exp_alu_b_use_imm = 1'b0;
            exp_rd_we         = 1'b0;
            exp_wb_sel        = WB_ALU;
            exp_is_branch     = 1'b0;
            exp_branch_invert = 1'b0;
            exp_br_type       = t_instr[14:13];
            exp_is_jal        = 1'b0;
            exp_is_jalr       = 1'b0;
            exp_is_load       = 1'b0;
            exp_is_store      = 1'b0;
            exp_ls_funct3     = t_instr[14:12];
            exp_is_amo        = 1'b0;
            exp_amo_is_lr     = 1'b0;
            exp_amo_is_sc     = 1'b0;
            exp_amo_op        = 4'd0;
            exp_is_csr        = 1'b0;
            exp_csr_op        = t_instr[13:12];
            exp_csr_uses_imm  = t_instr[14];
            exp_csr_addr      = t_instr[31:20];
            exp_csr_zimm      = {27'b0, t_instr[19:15]};
            exp_is_mret       = (t_instr == 32'h3020_0073);
            exp_is_dret       = (t_instr == 32'h7b20_0073);
            exp_is_muldiv     = 1'b0;
            exp_md_op         = t_instr[14:12];
            exp_md_is_div     = t_instr[14];
            exp_illegal       = 1'b1;
        end
    endtask

    task expect_decode;
        input [31:0] t_instr;
        reg [6:0] opc;
        reg [2:0] f3;
        reg [6:0] f7;
        reg [4:0] f5;
        reg       branch_f3_valid;
        reg       amo_f5_valid;
        begin
            expect_base(t_instr);
            opc = t_instr[6:0];
            f3  = t_instr[14:12];
            f7  = t_instr[31:25];
            f5  = t_instr[31:27];
            branch_f3_valid = (f3 == 3'b000) || (f3 == 3'b001) ||
                              (f3 == 3'b100) || (f3 == 3'b101) ||
                              (f3 == 3'b110) || (f3 == 3'b111);
            amo_f5_valid = (f5 == 5'h00) || (f5 == 5'h01) || (f5 == 5'h02) ||
                           (f5 == 5'h03) || (f5 == 5'h04) || (f5 == 5'h08) ||
                           (f5 == 5'h0c) || (f5 == 5'h10) || (f5 == 5'h14) ||
                           (f5 == 5'h18) || (f5 == 5'h1c);

            case (opc)
                OPC_LUI: begin
                    exp_imm = {t_instr[31:12], 12'b0};
                    exp_alu_op = ALU_COPY_B;
                    exp_alu_b_use_imm = 1'b1;
                    exp_rd_we = 1'b1;
                    exp_illegal = 1'b0;
                end
                OPC_AUIPC: begin
                    exp_imm = {t_instr[31:12], 12'b0};
                    exp_alu_b_use_imm = 1'b1;
                    exp_rd_we = 1'b1;
                    exp_wb_sel = WB_PCIMM;
                    exp_illegal = 1'b0;
                end
                OPC_JAL: begin
                    exp_imm = {{11{t_instr[31]}}, t_instr[31], t_instr[19:12],
                               t_instr[20], t_instr[30:21], 1'b0};
                    exp_alu_b_use_imm = 1'b1;
                    exp_rd_we = 1'b1;
                    exp_wb_sel = WB_PC4;
                    exp_is_jal = 1'b1;
                    exp_illegal = 1'b0;
                end
                OPC_JALR: begin
                    exp_imm = (f3 == 3'b000) ? sext12(t_instr[31:20]) : 32'h0000_0000;
                    exp_alu_b_use_imm = (f3 == 3'b000);
                    exp_rd_we = (f3 == 3'b000);
                    exp_wb_sel = (f3 == 3'b000) ? WB_PC4 : WB_ALU;
                    exp_is_jalr = (f3 == 3'b000);
                    exp_illegal = (f3 != 3'b000);
                end
                OPC_BRANCH: begin
                    exp_imm = {{19{t_instr[31]}}, t_instr[31], t_instr[7],
                               t_instr[30:25], t_instr[11:8], 1'b0};
                    exp_is_branch = 1'b1;
                    exp_branch_invert = (f3 == 3'b001) || (f3 == 3'b101) || (f3 == 3'b111);
                    case (f3)
                        3'b000, 3'b001: exp_alu_op = ALU_SEQ;
                        3'b100, 3'b101: exp_alu_op = ALU_SLT;
                        3'b110, 3'b111: exp_alu_op = ALU_SLTU;
                        default:        exp_alu_op = ALU_SEQ;
                    endcase
                    exp_illegal = !branch_f3_valid;
                end
                OPC_LOAD: begin
                    exp_imm = sext12(t_instr[31:20]);
                    exp_alu_b_use_imm = 1'b1;
                    exp_rd_we = 1'b1;
                    exp_wb_sel = WB_LSU;
                    exp_is_load = 1'b1;
                    exp_illegal = 1'b0;
                end
                OPC_STORE: begin
                    exp_imm = {{20{t_instr[31]}}, t_instr[31:25], t_instr[11:7]};
                    exp_alu_b_use_imm = 1'b1;
                    exp_is_store = 1'b1;
                    exp_illegal = 1'b0;
                end
                OPC_OP_IMM: begin
                    exp_imm = sext12(t_instr[31:20]);
                    exp_alu_b_use_imm = 1'b1;
                    exp_rd_we = 1'b1;
                    case (f3)
                        3'b000: exp_alu_op = ALU_ADD;
                        3'b001: exp_alu_op = ALU_SLL;
                        3'b010: exp_alu_op = ALU_SLT;
                        3'b011: exp_alu_op = ALU_SLTU;
                        3'b100: exp_alu_op = ALU_XOR;
                        3'b101: exp_alu_op = t_instr[30] ? ALU_SRA : ALU_SRL;
                        3'b110: exp_alu_op = ALU_OR;
                        3'b111: exp_alu_op = ALU_AND;
                        default: exp_alu_op = ALU_ADD;
                    endcase
                    exp_illegal = 1'b0;
                end
                OPC_OP: begin
                    exp_rd_we = 1'b1;
                    exp_is_muldiv = (f7 == 7'b0000001);
                    exp_wb_sel = exp_is_muldiv ? WB_MD : WB_ALU;
                    case (f3)
                        3'b000: exp_alu_op = t_instr[30] ? ALU_SUB : ALU_ADD;
                        3'b001: exp_alu_op = ALU_SLL;
                        3'b010: exp_alu_op = ALU_SLT;
                        3'b011: exp_alu_op = ALU_SLTU;
                        3'b100: exp_alu_op = ALU_XOR;
                        3'b101: exp_alu_op = t_instr[30] ? ALU_SRA : ALU_SRL;
                        3'b110: exp_alu_op = ALU_OR;
                        3'b111: exp_alu_op = ALU_AND;
                        default: exp_alu_op = ALU_ADD;
                    endcase
                    exp_illegal = 1'b0;
                end
                OPC_SYSTEM: begin
                    exp_is_csr = (f3 != 3'b000);
                    exp_rd_we = exp_is_csr;
                    exp_wb_sel = exp_is_csr ? WB_CSR : WB_ALU;
                    exp_illegal = !(exp_is_csr || exp_is_mret || exp_is_dret);
                end
                OPC_FENCE: begin
                    exp_illegal = 1'b0;
                end
                OPC_AMO: begin
                    exp_is_amo = (f3 == 3'b010) && amo_f5_valid &&
                                 ((f5 != 5'h02) || (t_instr[24:20] == 5'd0));
                    exp_amo_is_lr = exp_is_amo && (f5 == 5'h02);
                    exp_amo_is_sc = exp_is_amo && (f5 == 5'h03);
                    exp_amo_op = (f5 == 5'h01) ? 4'd1 :
                                 (f5 == 5'h04) ? 4'd2 :
                                 (f5 == 5'h08) ? 4'd3 :
                                 (f5 == 5'h0c) ? 4'd4 :
                                 (f5 == 5'h10) ? 4'd5 :
                                 (f5 == 5'h14) ? 4'd6 :
                                 (f5 == 5'h18) ? 4'd7 :
                                 (f5 == 5'h1c) ? 4'd8 : 4'd0;
                    exp_imm = 32'h0;
                    exp_alu_b_use_imm = exp_is_amo;
                    exp_rd_we = exp_is_amo;
                    exp_wb_sel = exp_is_amo ? WB_LSU : WB_ALU;
                    exp_ls_funct3 = exp_is_amo ? 3'b010 : f3;
                    exp_illegal = !exp_is_amo;
                end
                default: begin
                    exp_illegal = 1'b1;
                end
            endcase
        end
    endtask

    task check_vector;
        input [31:0] t_instr;
        input [8*32-1:0] tag;
        begin
            instr = t_instr;
            expect_decode(t_instr);
            #1;
            vectors = vectors + 1;
            if (rd_idx !== exp_rd_idx ||
                rs1_idx !== exp_rs1_idx ||
                rs2_idx !== exp_rs2_idx ||
                imm !== exp_imm ||
                alu_op !== exp_alu_op ||
                alu_b_use_imm !== exp_alu_b_use_imm ||
                rd_we !== exp_rd_we ||
                wb_sel !== exp_wb_sel ||
                is_branch !== exp_is_branch ||
                branch_invert !== exp_branch_invert ||
                br_type !== exp_br_type ||
                is_jal !== exp_is_jal ||
                is_jalr !== exp_is_jalr ||
                is_load !== exp_is_load ||
                is_store !== exp_is_store ||
                ls_funct3 !== exp_ls_funct3 ||
                is_amo !== exp_is_amo ||
                amo_is_lr !== exp_amo_is_lr ||
                amo_is_sc !== exp_amo_is_sc ||
                (exp_is_amo && (amo_op !== exp_amo_op)) ||
                is_csr !== exp_is_csr ||
                csr_op !== exp_csr_op ||
                csr_uses_imm !== exp_csr_uses_imm ||
                csr_addr !== exp_csr_addr ||
                csr_zimm !== exp_csr_zimm ||
                is_mret !== exp_is_mret ||
                is_dret !== exp_is_dret ||
                is_muldiv !== exp_is_muldiv ||
                md_op !== exp_md_op ||
                md_is_div !== exp_md_is_div ||
                illegal !== exp_illegal) begin
                errors = errors + 1;
                $error("FAIL[%0d] %0s instr=%h rd/rs=%h/%h/%h exp=%h/%h/%h imm=%h exp=%h alu=%h exp=%h flags jal/jalr/br/ld/st/amo/csr/mret/dret/md/ill=%b%b%b%b%b%b%b%b%b%b%b exp=%b%b%b%b%b%b%b%b%b%b%b",
                       vectors, tag, t_instr,
                       rd_idx, rs1_idx, rs2_idx, exp_rd_idx, exp_rs1_idx, exp_rs2_idx,
                       imm, exp_imm, alu_op, exp_alu_op,
                       is_jal, is_jalr, is_branch, is_load, is_store, is_amo, is_csr, is_mret, is_dret, is_muldiv, illegal,
                       exp_is_jal, exp_is_jalr, exp_is_branch, exp_is_load, exp_is_store,
                       exp_is_amo, exp_is_csr, exp_is_mret, exp_is_dret, exp_is_muldiv, exp_illegal);
            end
        end
    endtask

    task check_x_default_alu;
        input [31:0] t_instr;
        input [8*32-1:0] tag;
        begin
            instr = t_instr;
            #1;
            vectors = vectors + 1;
            if (alu_op !== ALU_ADD) begin
                errors = errors + 1;
                $error("FAIL[%0d] %0s instr=%h alu=%h exp_default_add", vectors, tag, t_instr, alu_op);
            end
        end
    endtask

    initial begin
        vectors = 0;
        errors = 0;
        instr = 32'h0000_0013;
        #1;

        check_vector(u_type(20'h12345, 5'd1, OPC_LUI), "LUI");
        check_vector(u_type(20'hfedcb, 5'd2, OPC_AUIPC), "AUIPC");
        check_vector(j_type(21'h15554, 5'd3, OPC_JAL), "JAL_POS");
        check_vector(j_type(21'h1aaa8, 5'd4, OPC_JAL), "JAL_NEG");
        check_vector(i_type(12'hffc, 5'd5, 3'b000, 5'd6, OPC_JALR), "JALR");
        check_vector(i_type(12'h004, 5'd5, 3'b001, 5'd6, OPC_JALR), "JALR_BAD_F3");
        check_vector(i_type(12'h000, 5'd0, 3'b000, 5'd0, OPC_FENCE), "FENCE");

        check_vector(i_type(12'h801, 5'd1, 3'b000, 5'd7, OPC_LOAD), "LB");
        check_vector(i_type(12'h07e, 5'd2, 3'b001, 5'd8, OPC_LOAD), "LH");
        check_vector(i_type(12'h120, 5'd3, 3'b010, 5'd9, OPC_LOAD), "LW");
        check_vector(i_type(12'hfff, 5'd4, 3'b100, 5'd10, OPC_LOAD), "LBU");
        check_vector(i_type(12'h555, 5'd5, 3'b101, 5'd11, OPC_LOAD), "LHU");

        check_vector(s_type(12'h800, 5'd12, 5'd6, 3'b000, OPC_STORE), "SB");
        check_vector(s_type(12'h07c, 5'd13, 5'd7, 3'b001, OPC_STORE), "SH");
        check_vector(s_type(12'h3a4, 5'd14, 5'd8, 3'b010, OPC_STORE), "SW");

        check_vector(amo_type(5'h02, 1'b0, 1'b0, 5'd0, 5'd8, 5'd9), "LR_W");
        check_vector(amo_type(5'h03, 1'b1, 1'b1, 5'd10, 5'd8, 5'd9), "SC_W_AQRL");
        check_vector(amo_type(5'h00, 1'b0, 1'b0, 5'd10, 5'd8, 5'd9), "AMOADD_W");
        check_vector(amo_type(5'h01, 1'b0, 1'b0, 5'd10, 5'd8, 5'd9), "AMOSWAP_W");
        check_vector(amo_type(5'h04, 1'b0, 1'b0, 5'd10, 5'd8, 5'd9), "AMOXOR_W");
        check_vector(amo_type(5'h08, 1'b0, 1'b0, 5'd10, 5'd8, 5'd9), "AMOOR_W");
        check_vector(amo_type(5'h0c, 1'b0, 1'b0, 5'd10, 5'd8, 5'd9), "AMOAND_W");
        check_vector(amo_type(5'h10, 1'b0, 1'b0, 5'd10, 5'd8, 5'd9), "AMOMIN_W");
        check_vector(amo_type(5'h14, 1'b0, 1'b0, 5'd10, 5'd8, 5'd9), "AMOMAX_W");
        check_vector(amo_type(5'h18, 1'b0, 1'b0, 5'd10, 5'd8, 5'd9), "AMOMINU_W");
        check_vector(amo_type(5'h1c, 1'b0, 1'b0, 5'd10, 5'd8, 5'd9), "AMOMAXU_W");
        check_vector(amo_type(5'h02, 1'b0, 1'b0, 5'd1, 5'd8, 5'd9), "LR_BAD_RS2");
        check_vector({5'h00, 2'b00, 5'd10, 5'd8, 3'b001, 5'd9, OPC_AMO}, "AMO_BAD_F3");
        check_vector(amo_type(5'h1f, 1'b0, 1'b0, 5'd10, 5'd8, 5'd9), "AMO_BAD_F5");

        check_vector(b_type(13'h0004, 5'd1, 5'd2, 3'b000, OPC_BRANCH), "BEQ");
        check_vector(b_type(13'h1ffc, 5'd3, 5'd4, 3'b001, OPC_BRANCH), "BNE");
        check_vector(b_type(13'h0100, 5'd5, 5'd6, 3'b100, OPC_BRANCH), "BLT");
        check_vector(b_type(13'h1f00, 5'd7, 5'd8, 3'b101, OPC_BRANCH), "BGE");
        check_vector(b_type(13'h0020, 5'd9, 5'd10, 3'b110, OPC_BRANCH), "BLTU");
        check_vector(b_type(13'h1fe0, 5'd11, 5'd12, 3'b111, OPC_BRANCH), "BGEU");
        check_vector(b_type(13'h0040, 5'd13, 5'd14, 3'b010, OPC_BRANCH), "BR_BAD_F3");

        check_vector(i_type(12'h001, 5'd1, 3'b000, 5'd15, OPC_OP_IMM), "ADDI");
        check_vector(i_type(12'h01f, 5'd2, 3'b001, 5'd16, OPC_OP_IMM), "SLLI");
        check_vector(i_type(12'hffe, 5'd3, 3'b010, 5'd17, OPC_OP_IMM), "SLTI");
        check_vector(i_type(12'h7ff, 5'd4, 3'b011, 5'd18, OPC_OP_IMM), "SLTIU");
        check_vector(i_type(12'h0a5, 5'd5, 3'b100, 5'd19, OPC_OP_IMM), "XORI");
        check_vector(i_type(12'h003, 5'd6, 3'b101, 5'd20, OPC_OP_IMM), "SRLI");
        check_vector(i_type(12'h403, 5'd7, 3'b101, 5'd21, OPC_OP_IMM), "SRAI");
        check_vector(i_type(12'h155, 5'd8, 3'b110, 5'd22, OPC_OP_IMM), "ORI");
        check_vector(i_type(12'haa5, 5'd9, 3'b111, 5'd23, OPC_OP_IMM), "ANDI");

        check_vector(r_type(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd10, OPC_OP), "ADD");
        check_vector(r_type(7'b0100000, 5'd3, 5'd2, 3'b000, 5'd11, OPC_OP), "SUB");
        check_vector(r_type(7'b0000000, 5'd4, 5'd3, 3'b001, 5'd12, OPC_OP), "SLL");
        check_vector(r_type(7'b0000000, 5'd5, 5'd4, 3'b010, 5'd13, OPC_OP), "SLT");
        check_vector(r_type(7'b0000000, 5'd6, 5'd5, 3'b011, 5'd14, OPC_OP), "SLTU");
        check_vector(r_type(7'b0000000, 5'd7, 5'd6, 3'b100, 5'd15, OPC_OP), "XOR");
        check_vector(r_type(7'b0000000, 5'd8, 5'd7, 3'b101, 5'd16, OPC_OP), "SRL");
        check_vector(r_type(7'b0100000, 5'd9, 5'd8, 3'b101, 5'd17, OPC_OP), "SRA");
        check_vector(r_type(7'b0000000, 5'd10, 5'd9, 3'b110, 5'd18, OPC_OP), "OR");
        check_vector(r_type(7'b0000000, 5'd11, 5'd10, 3'b111, 5'd19, OPC_OP), "AND");

        for (i = 0; i < 8; i = i + 1)
            check_vector(r_type(7'b0000001, (i[4:0] + 5'd1), (i[4:0] + 5'd9),
                                i[2:0], (i[4:0] + 5'd17), OPC_OP), "RV32M");

        check_vector(i_type(12'h300, 5'd1, 3'b001, 5'd2, OPC_SYSTEM), "CSRRW");
        check_vector(i_type(12'h304, 5'd3, 3'b010, 5'd4, OPC_SYSTEM), "CSRRS");
        check_vector(i_type(12'h305, 5'd5, 3'b011, 5'd6, OPC_SYSTEM), "CSRRC");
        check_vector(i_type(12'h340, 5'd1, 3'b101, 5'd7, OPC_SYSTEM), "CSRRWI_Z1");
        check_vector(i_type(12'h341, 5'd2, 3'b110, 5'd8, OPC_SYSTEM), "CSRRSI_Z2");
        check_vector(i_type(12'h342, 5'd4, 3'b111, 5'd9, OPC_SYSTEM), "CSRRCI_Z4");
        check_vector(i_type(12'h343, 5'd8, 3'b101, 5'd10, OPC_SYSTEM), "CSRRWI_Z8");
        check_vector(i_type(12'h344, 5'd16, 3'b110, 5'd11, OPC_SYSTEM), "CSRRSI_Z16");
        check_vector(i_type(12'hc00, 5'd31, 3'b111, 5'd12, OPC_SYSTEM), "CSRRCI_Z31");
        check_vector(32'h3020_0073, "MRET");
        check_vector(32'h7b20_0073, "DRET");
        check_vector(32'h0000_0073, "ECALL_ILLEGAL");
        check_vector(32'h0010_0073, "EBREAK_ILLEGAL");

        check_vector({25'h0123456, 7'b0001011}, "RESERVED_OPCODE");
        check_vector({25'h0765432, 7'b0001100}, "RESERVED_OPCODE_LSB00");
        check_vector({25'h0012345, 7'b0101101}, "RESERVED_OPCODE_LSB01");
        check_vector({25'h01abcde, 7'b1011110}, "RESERVED_OPCODE_LSB10");
        check_vector({25'h0, OPC_OP_IMM}, "OPIMM_ZERO");

        check_x_default_alu({7'b0000000, 5'd1, 5'd2, 3'bxxx, 5'd3, OPC_OP_IMM}, "OPIMM_X_F3_DEFAULT");
        check_x_default_alu({7'b0000000, 5'd1, 5'd2, 3'bxxx, 5'd3, OPC_OP}, "OP_X_F3_DEFAULT");

        if (errors == 0) begin
            $display("PASS: idu unit %0d/%0d vectors", vectors, vectors);
            $finish;
        end else begin
            $display("FAIL: idu unit %0d/%0d vectors failed", errors, vectors);
            $fatal(1);
        end
    end
endmodule
