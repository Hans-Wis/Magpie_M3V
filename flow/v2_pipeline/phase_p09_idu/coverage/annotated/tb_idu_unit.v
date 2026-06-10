//      // verilator_coverage annotation
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
        
~000027     reg  [31:0] instr;
~000027     wire [ 4:0] rd_idx;
~000022     wire [ 4:0] rs1_idx;
~000022     wire [ 4:0] rs2_idx;
~000011     wire [31:0] imm;
~000011     wire [ 3:0] alu_op;
%000004     wire        alu_b_use_imm;
%000005     wire        rd_we;
%000004     wire [ 2:0] wb_sel;
%000001     wire        is_branch;
%000003     wire        branch_invert;
~000017     wire [ 1:0] br_type;
%000001     wire        is_jal;
%000001     wire        is_jalr;
%000001     wire        is_load;
%000001     wire        is_store;
~000025     wire [ 2:0] ls_funct3;
%000001     wire        is_amo;
%000001     wire        amo_is_lr;
%000001     wire        amo_is_sc;
~000013     wire [ 3:0] amo_op;
%000001     wire        is_csr;
 000025     wire [ 1:0] csr_op;
%000009     wire        csr_uses_imm;
~000022     wire [11:0] csr_addr;
~000022     wire [31:0] csr_zimm;
%000001     wire        is_mret;
%000001     wire        is_dret;
%000001     wire        is_muldiv;
~000025     wire [ 2:0] md_op;
%000009     wire        md_is_div;
%000004     wire        illegal;
        
            integer vectors;
            integer errors;
            integer i;
        
~000026     reg [4:0]  exp_rd_idx;
~000022     reg [4:0]  exp_rs1_idx;
~000021     reg [4:0]  exp_rs2_idx;
~000011     reg [31:0] exp_imm;
~000011     reg [3:0]  exp_alu_op;
%000004     reg        exp_alu_b_use_imm;
%000005     reg        exp_rd_we;
%000004     reg [2:0]  exp_wb_sel;
%000001     reg        exp_is_branch;
%000003     reg        exp_branch_invert;
~000017     reg [1:0]  exp_br_type;
%000001     reg        exp_is_jal;
%000001     reg        exp_is_jalr;
%000001     reg        exp_is_load;
%000001     reg        exp_is_store;
~000025     reg [2:0]  exp_ls_funct3;
%000001     reg        exp_is_amo;
%000001     reg        exp_amo_is_lr;
%000001     reg        exp_amo_is_sc;
%000004     reg [3:0]  exp_amo_op;
%000001     reg        exp_is_csr;
 000025     reg [1:0]  exp_csr_op;
%000009     reg        exp_csr_uses_imm;
~000021     reg [11:0] exp_csr_addr;
~000022     reg [31:0] exp_csr_zimm;
%000001     reg        exp_is_mret;
%000001     reg        exp_is_dret;
%000001     reg        exp_is_muldiv;
~000025     reg [2:0]  exp_md_op;
%000009     reg        exp_md_is_div;
%000004     reg        exp_illegal;
        
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
        
 000018     function [31:0] r_type;
                input [6:0] f7;
                input [4:0] rs2;
                input [4:0] rs1;
                input [2:0] f3;
                input [4:0] rd;
                input [6:0] opc;
 000018         begin
 000018             r_type = {f7, rs2, rs1, f3, rd, opc};
                end
            endfunction
        
 000013     function [31:0] amo_type;
                input [4:0] f5;
                input       aq;
                input       rl;
                input [4:0] rs2;
                input [4:0] rs1;
                input [4:0] rd;
 000013         begin
 000013             amo_type = {f5, aq, rl, rs2, rs1, 3'b010, rd, OPC_AMO};
                end
            endfunction
        
 000026     function [31:0] i_type;
                input [11:0] imm12;
                input [4:0]  rs1;
                input [2:0]  f3;
                input [4:0]  rd;
                input [6:0]  opc;
 000026         begin
 000026             i_type = {imm12, rs1, f3, rd, opc};
                end
            endfunction
        
%000003     function [31:0] s_type;
                input [11:0] imm12;
                input [4:0]  rs2;
                input [4:0]  rs1;
                input [2:0]  f3;
                input [6:0]  opc;
%000003         begin
%000003             s_type = {imm12[11:5], rs2, rs1, f3, imm12[4:0], opc};
                end
            endfunction
        
%000007     function [31:0] b_type;
                input [12:0] imm13;
                input [4:0]  rs2;
                input [4:0]  rs1;
                input [2:0]  f3;
                input [6:0]  opc;
%000007         begin
%000007             b_type = {imm13[12], imm13[10:5], rs2, rs1, f3, imm13[4:1], imm13[11], opc};
                end
            endfunction
        
%000002     function [31:0] u_type;
                input [19:0] imm20;
                input [4:0]  rd;
                input [6:0]  opc;
%000002         begin
%000002             u_type = {imm20, rd, opc};
                end
            endfunction
        
%000002     function [31:0] j_type;
                input [20:0] imm21;
                input [4:0]  rd;
                input [6:0]  opc;
%000002         begin
%000002             j_type = {imm21[20], imm21[10:1], imm21[11], imm21[19:12], rd, opc};
                end
            endfunction
        
 000016     function [31:0] sext12;
                input [11:0] v;
 000016         begin
 000016             sext12 = {{20{v[11]}}, v};
                end
            endfunction
        
%000000     function [31:0] sext13;
                input [12:0] v;
%000000         begin
%000000             sext13 = {{19{v[12]}}, v};
                end
            endfunction
        
%000000     function [31:0] sext21;
                input [20:0] v;
%000000         begin
%000000             sext21 = {{11{v[20]}}, v};
                end
            endfunction
        
 000081     task expect_base;
                input [31:0] t_instr;
 000081         begin
 000081             exp_rd_idx        = t_instr[11:7];
 000081             exp_rs1_idx       = t_instr[19:15];
 000081             exp_rs2_idx       = t_instr[24:20];
 000081             exp_imm           = 32'h0000_0000;
 000081             exp_alu_op        = ALU_ADD;
 000081             exp_alu_b_use_imm = 1'b0;
 000081             exp_rd_we         = 1'b0;
 000081             exp_wb_sel        = WB_ALU;
 000081             exp_is_branch     = 1'b0;
 000081             exp_branch_invert = 1'b0;
 000081             exp_br_type       = t_instr[14:13];
 000081             exp_is_jal        = 1'b0;
 000081             exp_is_jalr       = 1'b0;
 000081             exp_is_load       = 1'b0;
 000081             exp_is_store      = 1'b0;
 000081             exp_ls_funct3     = t_instr[14:12];
 000081             exp_is_amo        = 1'b0;
 000081             exp_amo_is_lr     = 1'b0;
 000081             exp_amo_is_sc     = 1'b0;
 000081             exp_amo_op        = 4'd0;
 000081             exp_is_csr        = 1'b0;
 000081             exp_csr_op        = t_instr[13:12];
 000081             exp_csr_uses_imm  = t_instr[14];
 000081             exp_csr_addr      = t_instr[31:20];
 000081             exp_csr_zimm      = {27'b0, t_instr[19:15]};
 000081             exp_is_mret       = (t_instr == 32'h3020_0073);
 000081             exp_is_dret       = (t_instr == 32'h7b20_0073);
 000081             exp_is_muldiv     = 1'b0;
 000081             exp_md_op         = t_instr[14:12];
 000081             exp_md_is_div     = t_instr[14];
 000081             exp_illegal       = 1'b1;
                end
            endtask
        
 000081     task expect_decode;
                input [31:0] t_instr;
 000081         reg [6:0] opc;
 000081         reg [2:0] f3;
 000081         reg [6:0] f7;
 000081         reg [4:0] f5;
 000081         reg       branch_f3_valid;
 000081         reg       amo_f5_valid;
 000081         begin
 000081             expect_base(t_instr);
 000081             opc = t_instr[6:0];
 000081             f3  = t_instr[14:12];
 000081             f7  = t_instr[31:25];
 000081             f5  = t_instr[31:27];
 000081             branch_f3_valid = (f3 == 3'b000) || (f3 == 3'b001) ||
 000081                               (f3 == 3'b100) || (f3 == 3'b101) ||
~000081                               (f3 == 3'b110) || (f3 == 3'b111);
 000081             amo_f5_valid = (f5 == 5'h00) || (f5 == 5'h01) || (f5 == 5'h02) ||
 000081                            (f5 == 5'h03) || (f5 == 5'h04) || (f5 == 5'h08) ||
 000081                            (f5 == 5'h0c) || (f5 == 5'h10) || (f5 == 5'h14) ||
~000081                            (f5 == 5'h18) || (f5 == 5'h1c);
        
 000081             case (opc)
%000001                 OPC_LUI: begin
%000001                     exp_imm = {t_instr[31:12], 12'b0};
%000001                     exp_alu_op = ALU_COPY_B;
%000001                     exp_alu_b_use_imm = 1'b1;
%000001                     exp_rd_we = 1'b1;
%000001                     exp_illegal = 1'b0;
                        end
%000001                 OPC_AUIPC: begin
%000001                     exp_imm = {t_instr[31:12], 12'b0};
%000001                     exp_alu_b_use_imm = 1'b1;
%000001                     exp_rd_we = 1'b1;
%000001                     exp_wb_sel = WB_PCIMM;
%000001                     exp_illegal = 1'b0;
                        end
%000002                 OPC_JAL: begin
%000002                     exp_imm = {{11{t_instr[31]}}, t_instr[31], t_instr[19:12],
%000002                                t_instr[20], t_instr[30:21], 1'b0};
%000002                     exp_alu_b_use_imm = 1'b1;
%000002                     exp_rd_we = 1'b1;
%000002                     exp_wb_sel = WB_PC4;
%000002                     exp_is_jal = 1'b1;
%000002                     exp_illegal = 1'b0;
                        end
%000002                 OPC_JALR: begin
~000067                     exp_imm = (f3 == 3'b000) ? sext12(t_instr[31:20]) : 32'h0000_0000;
%000002                     exp_alu_b_use_imm = (f3 == 3'b000);
%000002                     exp_rd_we = (f3 == 3'b000);
~000067                     exp_wb_sel = (f3 == 3'b000) ? WB_PC4 : WB_ALU;
%000002                     exp_is_jalr = (f3 == 3'b000);
%000002                     exp_illegal = (f3 != 3'b000);
                        end
%000007                 OPC_BRANCH: begin
%000007                     exp_imm = {{19{t_instr[31]}}, t_instr[31], t_instr[7],
%000007                                t_instr[30:25], t_instr[11:8], 1'b0};
%000007                     exp_is_branch = 1'b1;
~000054                     exp_branch_invert = (f3 == 3'b001) || (f3 == 3'b101) || (f3 == 3'b111);
%000007                     case (f3)
%000002                         3'b000, 3'b001: exp_alu_op = ALU_SEQ;
%000002                         3'b100, 3'b101: exp_alu_op = ALU_SLT;
%000002                         3'b110, 3'b111: exp_alu_op = ALU_SLTU;
%000001                         default:        exp_alu_op = ALU_SEQ;
                            endcase
~000053                     exp_illegal = !branch_f3_valid;
                        end
%000005                 OPC_LOAD: begin
%000005                     exp_imm = sext12(t_instr[31:20]);
%000005                     exp_alu_b_use_imm = 1'b1;
%000005                     exp_rd_we = 1'b1;
%000005                     exp_wb_sel = WB_LSU;
%000005                     exp_is_load = 1'b1;
%000005                     exp_illegal = 1'b0;
                        end
%000003                 OPC_STORE: begin
%000003                     exp_imm = {{20{t_instr[31]}}, t_instr[31:25], t_instr[11:7]};
%000003                     exp_alu_b_use_imm = 1'b1;
%000003                     exp_is_store = 1'b1;
%000003                     exp_illegal = 1'b0;
                        end
 000010                 OPC_OP_IMM: begin
 000010                     exp_imm = sext12(t_instr[31:20]);
 000010                     exp_alu_b_use_imm = 1'b1;
 000010                     exp_rd_we = 1'b1;
 000010                     case (f3)
%000002                         3'b000: exp_alu_op = ALU_ADD;
%000001                         3'b001: exp_alu_op = ALU_SLL;
%000001                         3'b010: exp_alu_op = ALU_SLT;
%000001                         3'b011: exp_alu_op = ALU_SLTU;
%000001                         3'b100: exp_alu_op = ALU_XOR;
~000061                         3'b101: exp_alu_op = t_instr[30] ? ALU_SRA : ALU_SRL;
%000001                         3'b110: exp_alu_op = ALU_OR;
%000001                         3'b111: exp_alu_op = ALU_AND;
%000000                         default: exp_alu_op = ALU_ADD;
                            endcase
 000010                     exp_illegal = 1'b0;
                        end
 000018                 OPC_OP: begin
 000018                     exp_rd_we = 1'b1;
 000018                     exp_is_muldiv = (f7 == 7'b0000001);
~000073                     exp_wb_sel = exp_is_muldiv ? WB_MD : WB_ALU;
 000018                     case (f3)
~000061                         3'b000: exp_alu_op = t_instr[30] ? ALU_SUB : ALU_ADD;
%000002                         3'b001: exp_alu_op = ALU_SLL;
%000002                         3'b010: exp_alu_op = ALU_SLT;
%000002                         3'b011: exp_alu_op = ALU_SLTU;
%000002                         3'b100: exp_alu_op = ALU_XOR;
~000061                         3'b101: exp_alu_op = t_instr[30] ? ALU_SRA : ALU_SRL;
%000002                         3'b110: exp_alu_op = ALU_OR;
%000002                         3'b111: exp_alu_op = ALU_AND;
%000000                         default: exp_alu_op = ALU_ADD;
                            endcase
 000018                     exp_illegal = 1'b0;
                        end
 000013                 OPC_SYSTEM: begin
 000013                     exp_is_csr = (f3 != 3'b000);
 000013                     exp_rd_we = exp_is_csr;
~000072                     exp_wb_sel = exp_is_csr ? WB_CSR : WB_ALU;
~000070                     exp_illegal = !(exp_is_csr || exp_is_mret || exp_is_dret);
                        end
%000001                 OPC_FENCE: begin
%000001                     exp_illegal = 1'b0;
                        end
 000014                 OPC_AMO: begin
~000058                     exp_is_amo = (f3 == 3'b010) && amo_f5_valid &&
 000014                                  ((f5 != 5'h02) || (t_instr[24:20] == 5'd0));
~000075                     exp_amo_is_lr = exp_is_amo && (f5 == 5'h02);
~000080                     exp_amo_is_sc = exp_is_amo && (f5 == 5'h03);
~000077                     exp_amo_op = (f5 == 5'h01) ? 4'd1 :
~000012                                  (f5 == 5'h04) ? 4'd2 :
~000011                                  (f5 == 5'h08) ? 4'd3 :
~000010                                  (f5 == 5'h0c) ? 4'd4 :
%000009                                  (f5 == 5'h10) ? 4'd5 :
%000008                                  (f5 == 5'h14) ? 4'd6 :
%000007                                  (f5 == 5'h18) ? 4'd7 :
%000006                                  (f5 == 5'h1c) ? 4'd8 : 4'd0;
 000014                     exp_imm = 32'h0;
 000014                     exp_alu_b_use_imm = exp_is_amo;
 000014                     exp_rd_we = exp_is_amo;
~000070                     exp_wb_sel = exp_is_amo ? WB_LSU : WB_ALU;
~000070                     exp_ls_funct3 = exp_is_amo ? 3'b010 : f3;
 000070                     exp_illegal = !exp_is_amo;
                        end
%000004                 default: begin
%000004                     exp_illegal = 1'b1;
                        end
                    endcase
                end
            endtask
        
 000081     task check_vector;
                input [31:0] t_instr;
                input [8*32-1:0] tag;
 000081         begin
 000081             instr = t_instr;
 000081             expect_decode(t_instr);
 000081             #1;
 000081             vectors = vectors + 1;
 000081             if (rd_idx !== exp_rd_idx ||
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
        
%000002     task check_x_default_alu;
                input [31:0] t_instr;
                input [8*32-1:0] tag;
%000002         begin
%000002             instr = t_instr;
%000002             #1;
%000002             vectors = vectors + 1;
%000002             if (alu_op !== ALU_ADD) begin
                        errors = errors + 1;
                        $error("FAIL[%0d] %0s instr=%h alu=%h exp_default_add", vectors, tag, t_instr, alu_op);
                    end
                end
            endtask
        
%000001     initial begin
%000001         vectors = 0;
%000001         errors = 0;
%000001         instr = 32'h0000_0013;
%000001         #1;
        
%000001         check_vector(u_type(20'h12345, 5'd1, OPC_LUI), "LUI");
%000001         check_vector(u_type(20'hfedcb, 5'd2, OPC_AUIPC), "AUIPC");
%000001         check_vector(j_type(21'h15554, 5'd3, OPC_JAL), "JAL_POS");
%000001         check_vector(j_type(21'h1aaa8, 5'd4, OPC_JAL), "JAL_NEG");
%000001         check_vector(i_type(12'hffc, 5'd5, 3'b000, 5'd6, OPC_JALR), "JALR");
%000001         check_vector(i_type(12'h004, 5'd5, 3'b001, 5'd6, OPC_JALR), "JALR_BAD_F3");
%000001         check_vector(i_type(12'h000, 5'd0, 3'b000, 5'd0, OPC_FENCE), "FENCE");
        
%000001         check_vector(i_type(12'h801, 5'd1, 3'b000, 5'd7, OPC_LOAD), "LB");
%000001         check_vector(i_type(12'h07e, 5'd2, 3'b001, 5'd8, OPC_LOAD), "LH");
%000001         check_vector(i_type(12'h120, 5'd3, 3'b010, 5'd9, OPC_LOAD), "LW");
%000001         check_vector(i_type(12'hfff, 5'd4, 3'b100, 5'd10, OPC_LOAD), "LBU");
%000001         check_vector(i_type(12'h555, 5'd5, 3'b101, 5'd11, OPC_LOAD), "LHU");
        
%000001         check_vector(s_type(12'h800, 5'd12, 5'd6, 3'b000, OPC_STORE), "SB");
%000001         check_vector(s_type(12'h07c, 5'd13, 5'd7, 3'b001, OPC_STORE), "SH");
%000001         check_vector(s_type(12'h3a4, 5'd14, 5'd8, 3'b010, OPC_STORE), "SW");
        
%000001         check_vector(amo_type(5'h02, 1'b0, 1'b0, 5'd0, 5'd8, 5'd9), "LR_W");
%000001         check_vector(amo_type(5'h03, 1'b1, 1'b1, 5'd10, 5'd8, 5'd9), "SC_W_AQRL");
%000001         check_vector(amo_type(5'h00, 1'b0, 1'b0, 5'd10, 5'd8, 5'd9), "AMOADD_W");
%000001         check_vector(amo_type(5'h01, 1'b0, 1'b0, 5'd10, 5'd8, 5'd9), "AMOSWAP_W");
%000001         check_vector(amo_type(5'h04, 1'b0, 1'b0, 5'd10, 5'd8, 5'd9), "AMOXOR_W");
%000001         check_vector(amo_type(5'h08, 1'b0, 1'b0, 5'd10, 5'd8, 5'd9), "AMOOR_W");
%000001         check_vector(amo_type(5'h0c, 1'b0, 1'b0, 5'd10, 5'd8, 5'd9), "AMOAND_W");
%000001         check_vector(amo_type(5'h10, 1'b0, 1'b0, 5'd10, 5'd8, 5'd9), "AMOMIN_W");
%000001         check_vector(amo_type(5'h14, 1'b0, 1'b0, 5'd10, 5'd8, 5'd9), "AMOMAX_W");
%000001         check_vector(amo_type(5'h18, 1'b0, 1'b0, 5'd10, 5'd8, 5'd9), "AMOMINU_W");
%000001         check_vector(amo_type(5'h1c, 1'b0, 1'b0, 5'd10, 5'd8, 5'd9), "AMOMAXU_W");
%000001         check_vector(amo_type(5'h02, 1'b0, 1'b0, 5'd1, 5'd8, 5'd9), "LR_BAD_RS2");
%000001         check_vector({5'h00, 2'b00, 5'd10, 5'd8, 3'b001, 5'd9, OPC_AMO}, "AMO_BAD_F3");
%000001         check_vector(amo_type(5'h1f, 1'b0, 1'b0, 5'd10, 5'd8, 5'd9), "AMO_BAD_F5");
        
%000001         check_vector(b_type(13'h0004, 5'd1, 5'd2, 3'b000, OPC_BRANCH), "BEQ");
%000001         check_vector(b_type(13'h1ffc, 5'd3, 5'd4, 3'b001, OPC_BRANCH), "BNE");
%000001         check_vector(b_type(13'h0100, 5'd5, 5'd6, 3'b100, OPC_BRANCH), "BLT");
%000001         check_vector(b_type(13'h1f00, 5'd7, 5'd8, 3'b101, OPC_BRANCH), "BGE");
%000001         check_vector(b_type(13'h0020, 5'd9, 5'd10, 3'b110, OPC_BRANCH), "BLTU");
%000001         check_vector(b_type(13'h1fe0, 5'd11, 5'd12, 3'b111, OPC_BRANCH), "BGEU");
%000001         check_vector(b_type(13'h0040, 5'd13, 5'd14, 3'b010, OPC_BRANCH), "BR_BAD_F3");
        
%000001         check_vector(i_type(12'h001, 5'd1, 3'b000, 5'd15, OPC_OP_IMM), "ADDI");
%000001         check_vector(i_type(12'h01f, 5'd2, 3'b001, 5'd16, OPC_OP_IMM), "SLLI");
%000001         check_vector(i_type(12'hffe, 5'd3, 3'b010, 5'd17, OPC_OP_IMM), "SLTI");
%000001         check_vector(i_type(12'h7ff, 5'd4, 3'b011, 5'd18, OPC_OP_IMM), "SLTIU");
%000001         check_vector(i_type(12'h0a5, 5'd5, 3'b100, 5'd19, OPC_OP_IMM), "XORI");
%000001         check_vector(i_type(12'h003, 5'd6, 3'b101, 5'd20, OPC_OP_IMM), "SRLI");
%000001         check_vector(i_type(12'h403, 5'd7, 3'b101, 5'd21, OPC_OP_IMM), "SRAI");
%000001         check_vector(i_type(12'h155, 5'd8, 3'b110, 5'd22, OPC_OP_IMM), "ORI");
%000001         check_vector(i_type(12'haa5, 5'd9, 3'b111, 5'd23, OPC_OP_IMM), "ANDI");
        
%000001         check_vector(r_type(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd10, OPC_OP), "ADD");
%000001         check_vector(r_type(7'b0100000, 5'd3, 5'd2, 3'b000, 5'd11, OPC_OP), "SUB");
%000001         check_vector(r_type(7'b0000000, 5'd4, 5'd3, 3'b001, 5'd12, OPC_OP), "SLL");
%000001         check_vector(r_type(7'b0000000, 5'd5, 5'd4, 3'b010, 5'd13, OPC_OP), "SLT");
%000001         check_vector(r_type(7'b0000000, 5'd6, 5'd5, 3'b011, 5'd14, OPC_OP), "SLTU");
%000001         check_vector(r_type(7'b0000000, 5'd7, 5'd6, 3'b100, 5'd15, OPC_OP), "XOR");
%000001         check_vector(r_type(7'b0000000, 5'd8, 5'd7, 3'b101, 5'd16, OPC_OP), "SRL");
%000001         check_vector(r_type(7'b0100000, 5'd9, 5'd8, 3'b101, 5'd17, OPC_OP), "SRA");
%000001         check_vector(r_type(7'b0000000, 5'd10, 5'd9, 3'b110, 5'd18, OPC_OP), "OR");
%000001         check_vector(r_type(7'b0000000, 5'd11, 5'd10, 3'b111, 5'd19, OPC_OP), "AND");
        
%000008         for (i = 0; i < 8; i = i + 1)
%000008             check_vector(r_type(7'b0000001, (i[4:0] + 5'd1), (i[4:0] + 5'd9),
%000008                                 i[2:0], (i[4:0] + 5'd17), OPC_OP), "RV32M");
        
%000001         check_vector(i_type(12'h300, 5'd1, 3'b001, 5'd2, OPC_SYSTEM), "CSRRW");
%000001         check_vector(i_type(12'h304, 5'd3, 3'b010, 5'd4, OPC_SYSTEM), "CSRRS");
%000001         check_vector(i_type(12'h305, 5'd5, 3'b011, 5'd6, OPC_SYSTEM), "CSRRC");
%000001         check_vector(i_type(12'h340, 5'd1, 3'b101, 5'd7, OPC_SYSTEM), "CSRRWI_Z1");
%000001         check_vector(i_type(12'h341, 5'd2, 3'b110, 5'd8, OPC_SYSTEM), "CSRRSI_Z2");
%000001         check_vector(i_type(12'h342, 5'd4, 3'b111, 5'd9, OPC_SYSTEM), "CSRRCI_Z4");
%000001         check_vector(i_type(12'h343, 5'd8, 3'b101, 5'd10, OPC_SYSTEM), "CSRRWI_Z8");
%000001         check_vector(i_type(12'h344, 5'd16, 3'b110, 5'd11, OPC_SYSTEM), "CSRRSI_Z16");
%000001         check_vector(i_type(12'hc00, 5'd31, 3'b111, 5'd12, OPC_SYSTEM), "CSRRCI_Z31");
%000001         check_vector(32'h3020_0073, "MRET");
%000001         check_vector(32'h7b20_0073, "DRET");
%000001         check_vector(32'h0000_0073, "ECALL_ILLEGAL");
%000001         check_vector(32'h0010_0073, "EBREAK_ILLEGAL");
        
%000001         check_vector({25'h0123456, 7'b0001011}, "RESERVED_OPCODE");
%000001         check_vector({25'h0765432, 7'b0001100}, "RESERVED_OPCODE_LSB00");
%000001         check_vector({25'h0012345, 7'b0101101}, "RESERVED_OPCODE_LSB01");
%000001         check_vector({25'h01abcde, 7'b1011110}, "RESERVED_OPCODE_LSB10");
%000001         check_vector({25'h0, OPC_OP_IMM}, "OPIMM_ZERO");
        
%000001         check_x_default_alu({7'b0000000, 5'd1, 5'd2, 3'bxxx, 5'd3, OPC_OP_IMM}, "OPIMM_X_F3_DEFAULT");
%000001         check_x_default_alu({7'b0000000, 5'd1, 5'd2, 3'bxxx, 5'd3, OPC_OP}, "OP_X_F3_DEFAULT");
        
%000001         if (errors == 0) begin
%000001             $display("PASS: idu unit %0d/%0d vectors", vectors, vectors);
%000001             $finish;
                end else begin
                    $display("FAIL: idu unit %0d/%0d vectors failed", errors, vectors);
                    $fatal(1);
                end
            end
        endmodule
        
