`timescale 1ns/1ns
`include "def.vh"

module cpu_m1_func_cov_observer (
    input         clk,
    input         resetn,
    input         stall,
    input         fetch_stall,
    input         mem_stall,
    input         pc_redirect,
    input         id_advance_to_ex_mem,
    input         ex_mem_advance_to_wb,
    input         if_ex_valid,
    input  [31:0] if_ex_instr,
    input         if_ex_is_16bit,
    input         id_is_branch,
    input         branch_taken,
    input         id_is_jal,
    input         id_is_jalr,
    input         id_is_load,
    input         id_is_store,
    input  [2:0]  id_ls_funct3,
    input         id_is_csr,
    input  [1:0]  id_csr_op,
    input         id_is_mret,
    input         id_is_muldiv,
    input  [2:0]  id_md_op,
    input         id_md_is_div,
    input         id_illegal,
    input  [31:0] id_imm,
    input  [4:0]  id_rd_idx,
    input  [4:0]  id_rs1_idx,
    input  [4:0]  id_rs2_idx,
    input  [31:0] rs1_val,
    input  [31:0] rs2_val,
    input  [1:0]  store_addr_lo,
    input         ex_mem_valid_r,
    input         ex_mem_is_load_r,
    input         ex_mem_is_store_r,
    input  [2:0]  ex_mem_ls_funct3_r,
    input  [1:0]  ex_mem_addr_lo_r,
    input         ex_mem_is_branch_taken_r,
    input         ex_mem_is_jal_r,
    input         ex_mem_is_jalr_r,
    input         ex_mem_mispredict_r,
    input         ex_mem_pred_ras_r,
    input         ex_mem_bp_upd_valid_r,
    input         ex_wb_valid_r,
    input         ex_wb_illegal_r,
    input         ex_wb_is_mret_r,
    input         wb_instr_retired,
    input         wb_csr_we,
    input  [1:0]  ex_wb_csr_op_r,
    input         wb_take_irq,
    input         wb_take_data_trap,
    input         ex_wb_is_misaligned_store_r,
    input         ras_push,
    input         ras_pop,
    input         md_busy
);
    integer fd;
    reg [31:0] obs_ex_mem_instr;
    reg [31:0] obs_ex_wb_instr;
    reg        obs_ex_mem_16bit;
    reg        obs_ex_wb_16bit;
    reg [4:0]  obs_ex_mem_rd_idx;
    reg [4:0]  obs_ex_mem_rs1_idx;
    reg [4:0]  obs_ex_mem_rs2_idx;
    reg [31:0] obs_ex_mem_rs1_val;
    reg [31:0] obs_ex_mem_rs2_val;
    reg [4:0]  obs_ex_wb_rd_idx;
    reg [4:0]  obs_ex_wb_rs1_idx;
    reg [4:0]  obs_ex_wb_rs2_idx;
    reg [31:0] obs_ex_wb_rs1_val;
    reg [31:0] obs_ex_wb_rs2_val;
    wire [6:0] dec_opcode = if_ex_instr[6:0];
    wire [2:0] dec_funct3 = if_ex_instr[14:12];
    wire [6:0] dec_funct7 = if_ex_instr[31:25];
    wire [6:0] wb_opcode = obs_ex_wb_instr[6:0];
    wire [11:0] wb_funct12 = obs_ex_wb_instr[31:20];
    wire wb_retire_valid = resetn && wb_instr_retired && ex_wb_valid_r && !ex_wb_illegal_r;
    wire branch_backward = id_imm[31];
    wire load_use_stall = stall && !id_is_muldiv && !md_busy;
    wire muldiv_busy_stall = stall && id_is_muldiv && md_busy;
    wire bp_event = ex_mem_valid_r && (ex_mem_bp_upd_valid_r || ex_mem_is_jalr_r || ex_mem_pred_ras_r);
    wire [1:0] bp_result = ex_mem_mispredict_r ? 2'd2 : 2'd1;
    wire [2:0] trap_kind =
        wb_take_irq ? 3'd3 :
        (wb_take_data_trap && !ex_wb_is_misaligned_store_r) ? 3'd4 :
        (wb_take_data_trap &&  ex_wb_is_misaligned_store_r) ? 3'd5 :
        (ex_wb_illegal_r && wb_opcode == `OPC_SYSTEM && wb_funct12 == 12'h000) ? 3'd1 :
        (ex_wb_illegal_r && wb_opcode == `OPC_SYSTEM && wb_funct12 == 12'h001) ? 3'd2 :
        3'd0;

    localparam [2:0] FMT_NONE = 3'd0;
    localparam [2:0] FMT_I    = 3'd1;
    localparam [2:0] FMT_S    = 3'd2;
    localparam [2:0] FMT_B    = 3'd3;
    localparam [2:0] FMT_U    = 3'd4;
    localparam [2:0] FMT_J    = 3'd5;

    function [2:0] instr_class;
        input [6:0] opcode;
        begin
            case (opcode)
                `OPC_OP, `OPC_OP_IMM: instr_class = 3'd1;
                `OPC_LOAD:            instr_class = 3'd2;
                `OPC_STORE:           instr_class = 3'd3;
                `OPC_BRANCH:          instr_class = 3'd4;
                `OPC_JAL, `OPC_JALR:  instr_class = 3'd5;
                `OPC_SYSTEM:          instr_class = 3'd6;
                `OPC_LUI, `OPC_AUIPC: instr_class = 3'd7;
                default:              instr_class = 3'd0;
            endcase
        end
    endfunction

    function [2:0] imm_format;
        input [6:0] opcode;
        begin
            case (opcode)
                `OPC_OP_IMM, `OPC_LOAD, `OPC_JALR, `OPC_SYSTEM, `OPC_FENCE: imm_format = FMT_I;
                `OPC_STORE:  imm_format = FMT_S;
                `OPC_BRANCH: imm_format = FMT_B;
                `OPC_LUI, `OPC_AUIPC: imm_format = FMT_U;
                `OPC_JAL: imm_format = FMT_J;
                default: imm_format = FMT_NONE;
            endcase
        end
    endfunction

    function [31:0] decode_imm;
        input [31:0] instr;
        input [2:0] fmt;
        begin
            case (fmt)
                FMT_I: decode_imm = {{20{instr[31]}}, instr[31:20]};
                FMT_S: decode_imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
                FMT_B: decode_imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
                FMT_U: decode_imm = {instr[31:12], 12'h000};
                FMT_J: decode_imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
                default: decode_imm = 32'h0;
            endcase
        end
    endfunction

    function [2:0] imm_corner;
        input [31:0] imm;
        input [2:0] fmt;
        begin
            if (fmt == FMT_NONE) imm_corner = 3'd0;
            else if (imm == 32'h0000_0000) imm_corner = 3'd1;
            else begin
                case (fmt)
                    FMT_I, FMT_S: imm_corner =
                        (imm == 32'hffff_f800) ? 3'd2 :
                        (imm == 32'h0000_07ff) ? 3'd3 : 3'd0;
                    FMT_B: imm_corner =
                        (imm == 32'hffff_f000) ? 3'd2 :
                        (imm == 32'h0000_0ffe) ? 3'd3 : 3'd0;
                    FMT_U: imm_corner =
                        (imm == 32'h8000_0000) ? 3'd2 :
                        (imm == 32'h7fff_f000) ? 3'd3 :
                        (imm == 32'hffff_f000) ? 3'd4 : 3'd0;
                    FMT_J: imm_corner =
                        (imm == 32'hfff0_0000) ? 3'd2 :
                        (imm == 32'h000f_fffe) ? 3'd3 : 3'd0;
                    default: imm_corner = 3'd0;
                endcase
            end
        end
    endfunction

    wire [2:0] wb_instr_class = instr_class(wb_opcode);
    wire [2:0] wb_imm_format = imm_format(wb_opcode);
    wire [31:0] wb_imm = decode_imm(obs_ex_wb_instr, wb_imm_format);
    wire [1:0] wb_imm_sign =
        (wb_imm_format == FMT_NONE) ? 2'd0 :
        (wb_imm == 32'h0) ? 2'd1 :
        wb_imm[31] ? 2'd3 : 2'd2;
    wire [2:0] wb_imm_corner = imm_corner(wb_imm, wb_imm_format);

    covergroup cg_opcode_instr_class @(posedge clk);
        option.per_instance = 1;
        cp_opcode: coverpoint dec_opcode iff (resetn && if_ex_valid) {
            bins lui = {`OPC_LUI}; bins auipc = {`OPC_AUIPC}; bins jal = {`OPC_JAL};
            bins jalr = {`OPC_JALR}; bins branch = {`OPC_BRANCH}; bins load = {`OPC_LOAD};
            bins store = {`OPC_STORE}; bins op_imm = {`OPC_OP_IMM}; bins op = {`OPC_OP};
            bins system = {`OPC_SYSTEM}; bins fence = {`OPC_FENCE};
        }
        cp_size: coverpoint if_ex_is_16bit iff (resetn && if_ex_valid) { bins rvc = {1}; bins rv32 = {0}; }
        opcode_x_size: cross cp_opcode, cp_size;
    endgroup

    covergroup cg_alu_m_funct @(posedge clk);
        option.per_instance = 1;
        cp_alu_funct3: coverpoint dec_funct3 iff (resetn && if_ex_valid && (dec_opcode == `OPC_OP || dec_opcode == `OPC_OP_IMM)) { bins f3[] = {[0:7]}; }
        cp_funct7: coverpoint dec_funct7 iff (resetn && if_ex_valid && dec_opcode == `OPC_OP) { bins base = {`F7_DEFAULT}; bins sub_sra = {`F7_SUB_SRA}; bins muldiv = {`F7_MULDIV}; }
        cp_md_op: coverpoint id_md_op iff (resetn && if_ex_valid && id_is_muldiv) { bins md[] = {[0:7]}; }
        cp_md_kind: coverpoint id_md_is_div iff (resetn && if_ex_valid && id_is_muldiv) { bins mul = {0}; bins div = {1}; }
    endgroup

    covergroup cg_load_store @(posedge clk);
        option.per_instance = 1;
        cp_ls_kind: coverpoint {ex_mem_is_store_r, ex_mem_is_load_r} iff (resetn && ex_mem_valid_r && (ex_mem_is_load_r || ex_mem_is_store_r)) { bins load = {2'b01}; bins store = {2'b10}; }
        cp_width: coverpoint ex_mem_ls_funct3_r[1:0] iff (resetn && ex_mem_valid_r && (ex_mem_is_load_r || ex_mem_is_store_r)) { bins byte_bin = {0}; bins half = {1}; bins word = {2}; }
        cp_sign: coverpoint ex_mem_ls_funct3_r[2] iff (resetn && ex_mem_valid_r && ex_mem_is_load_r) { bins signed_load = {0}; bins unsigned_load = {1}; }
        cp_addr_lo: coverpoint ex_mem_addr_lo_r iff (resetn && ex_mem_valid_r && (ex_mem_is_load_r || ex_mem_is_store_r)) { bins lo[] = {[0:3]}; }
        ls_shape: cross cp_ls_kind, cp_width, cp_addr_lo;
    endgroup

    covergroup cg_branch_jump_bp_ras @(posedge clk);
        option.per_instance = 1;
        cp_branch_taken: coverpoint branch_taken iff (resetn && if_ex_valid && id_is_branch) { bins not_taken = {0}; bins taken = {1}; }
        cp_branch_dir: coverpoint branch_backward iff (resetn && if_ex_valid && id_is_branch) { bins forward = {0}; bins backward = {1}; }
        cp_jump: coverpoint {id_is_jal, id_is_jalr} iff (resetn && if_ex_valid && (id_is_jal || id_is_jalr)) { bins jal = {2'b10}; bins jalr = {2'b01}; }
        cp_ras: coverpoint {ras_push, ras_pop} iff (resetn && (ras_push || ras_pop)) { bins push = {2'b10}; bins pop = {2'b01}; bins push_pop = {2'b11}; }
        cp_bp: coverpoint bp_result iff (resetn && bp_event) { bins hit = {1}; bins miss = {2}; }
        branch_shape: cross cp_branch_taken, cp_branch_dir;
    endgroup

    covergroup cg_hazard_flush @(posedge clk);
        option.per_instance = 1;
        cp_hazard: coverpoint {load_use_stall, muldiv_busy_stall, fetch_stall, mem_stall} iff (resetn && (stall || fetch_stall || mem_stall)) {
            bins load_use = {4'b1000}; bins muldiv_busy = {4'b0100}; bins fetch = {4'b0010}; bins memory = {4'b0001};
        }
        cp_redirect: coverpoint pc_redirect iff (resetn) { bins no_redirect = {0}; bins redirect = {1}; }
    endgroup

    covergroup cg_csr_trap @(posedge clk);
        option.per_instance = 1;
        cp_csr_op: coverpoint ex_wb_csr_op_r iff (resetn && wb_csr_we) { bins rw = {`CSR_OP_W}; bins rs = {`CSR_OP_S}; bins rc = {`CSR_OP_C}; }
        cp_trap: coverpoint trap_kind iff (resetn && (wb_take_irq || wb_take_data_trap || ex_wb_illegal_r)) {
            bins illegal = {0}; bins ecall = {1}; bins ebreak = {2}; bins irq = {3}; bins load_misalign = {4}; bins store_misalign = {5};
        }
        cp_mret: coverpoint ex_wb_is_mret_r iff (resetn && ex_wb_valid_r) { bins no = {0}; bins yes = {1}; }
    endgroup

    covergroup cg_riscvisacov_operands @(posedge clk);
        option.per_instance = 1;
        cp_instr_class: coverpoint wb_instr_class iff (wb_retire_valid) {
            bins alu = {1}; bins load = {2}; bins store = {3}; bins branch = {4};
            bins jump = {5}; bins csr = {6}; bins upper = {7};
        }
        cp_rd: coverpoint obs_ex_wb_rd_idx iff (wb_retire_valid) { bins x0 = {0}; bins x[] = {[1:31]}; }
        cp_rs1: coverpoint obs_ex_wb_rs1_idx iff (wb_retire_valid) { bins x0 = {0}; bins x[] = {[1:31]}; }
        cp_rs2: coverpoint obs_ex_wb_rs2_idx iff (wb_retire_valid) { bins x0 = {0}; bins x[] = {[1:31]}; }
        rd_x_class: cross cp_rd, cp_instr_class;
        rs1_x_class: cross cp_rs1, cp_instr_class;
        rs2_x_class: cross cp_rs2, cp_instr_class;
    endgroup

    covergroup cg_riscvisacov_value_corners @(posedge clk);
        option.per_instance = 1;
        cp_rs1_val: coverpoint obs_ex_wb_rs1_val iff (wb_retire_valid) {
            bins zero = {32'h0000_0000}; bins one = {32'h0000_0001};
            bins minus_one = {32'hffff_ffff}; bins max_pos = {32'h7fff_ffff};
            bins min_neg = {32'h8000_0000}; bins all_ones = {32'hffff_ffff};
        }
        cp_rs2_val: coverpoint obs_ex_wb_rs2_val iff (wb_retire_valid) {
            bins zero = {32'h0000_0000}; bins one = {32'h0000_0001};
            bins minus_one = {32'hffff_ffff}; bins max_pos = {32'h7fff_ffff};
            bins min_neg = {32'h8000_0000}; bins all_ones = {32'hffff_ffff};
        }
    endgroup

    covergroup cg_riscvisacov_immediates @(posedge clk);
        option.per_instance = 1;
        cp_imm_format: coverpoint wb_imm_format iff (wb_retire_valid && wb_imm_format != FMT_NONE) {
            bins i = {FMT_I}; bins s = {FMT_S}; bins b = {FMT_B}; bins u = {FMT_U}; bins j = {FMT_J};
        }
        cp_imm_sign: coverpoint wb_imm_sign iff (wb_retire_valid && wb_imm_format != FMT_NONE) {
            bins zero = {1}; bins positive = {2}; bins negative = {3};
        }
        cp_imm_corner: coverpoint wb_imm_corner iff (wb_retire_valid && wb_imm_format != FMT_NONE) {
            bins zero = {1}; bins min = {2}; bins max = {3}; bins u_all_ones = {4};
        }
        format_x_sign: cross cp_imm_format, cp_imm_sign;
        format_x_corner: cross cp_imm_format, cp_imm_corner;
    endgroup

    cg_opcode_instr_class cg_opcode_instr_class_i = new();
    cg_alu_m_funct cg_alu_m_funct_i = new();
    cg_load_store cg_load_store_i = new();
    cg_branch_jump_bp_ras cg_branch_jump_bp_ras_i = new();
    cg_hazard_flush cg_hazard_flush_i = new();
    cg_csr_trap cg_csr_trap_i = new();
    cg_riscvisacov_operands cg_riscvisacov_operands_i = new();
    cg_riscvisacov_value_corners cg_riscvisacov_value_corners_i = new();
    cg_riscvisacov_immediates cg_riscvisacov_immediates_i = new();

    initial begin
        fd = $fopen("functional_events.csv", "w");
        $fdisplay(fd, "cycle,event,a,b,c,d,e");
    end

    integer cycle;
    always @(posedge clk) begin
        if (!resetn) begin
            cycle <= 0;
            obs_ex_mem_instr <= 32'h0;
            obs_ex_wb_instr <= 32'h0;
            obs_ex_mem_16bit <= 1'b0;
            obs_ex_wb_16bit <= 1'b0;
            obs_ex_mem_rd_idx <= 5'h0;
            obs_ex_mem_rs1_idx <= 5'h0;
            obs_ex_mem_rs2_idx <= 5'h0;
            obs_ex_mem_rs1_val <= 32'h0;
            obs_ex_mem_rs2_val <= 32'h0;
            obs_ex_wb_rd_idx <= 5'h0;
            obs_ex_wb_rs1_idx <= 5'h0;
            obs_ex_wb_rs2_idx <= 5'h0;
            obs_ex_wb_rs1_val <= 32'h0;
            obs_ex_wb_rs2_val <= 32'h0;
        end else begin
            cycle <= cycle + 1;
            if (id_advance_to_ex_mem) begin
                obs_ex_mem_instr <= if_ex_instr;
                obs_ex_mem_16bit <= if_ex_is_16bit;
                obs_ex_mem_rd_idx <= id_rd_idx;
                obs_ex_mem_rs1_idx <= id_rs1_idx;
                obs_ex_mem_rs2_idx <= id_rs2_idx;
                obs_ex_mem_rs1_val <= rs1_val;
                obs_ex_mem_rs2_val <= rs2_val;
            end
            if (ex_mem_advance_to_wb) begin
                obs_ex_wb_instr <= obs_ex_mem_instr;
                obs_ex_wb_16bit <= obs_ex_mem_16bit;
                obs_ex_wb_rd_idx <= obs_ex_mem_rd_idx;
                obs_ex_wb_rs1_idx <= obs_ex_mem_rs1_idx;
                obs_ex_wb_rs2_idx <= obs_ex_mem_rs2_idx;
                obs_ex_wb_rs1_val <= obs_ex_mem_rs1_val;
                obs_ex_wb_rs2_val <= obs_ex_mem_rs2_val;
            end
            if (wb_retire_valid) begin
                $fdisplay(fd, "%0d,operand,%0d,%0d,%0d,%0d,%0d", cycle, obs_ex_wb_rd_idx, obs_ex_wb_rs1_idx, obs_ex_wb_rs2_idx, wb_instr_class, wb_opcode);
                $fdisplay(fd, "%0d,value,%0d,%0d,0,0,0", cycle, obs_ex_wb_rs1_val, obs_ex_wb_rs2_val);
                if (wb_imm_format != FMT_NONE) $fdisplay(fd, "%0d,imm,%0d,%0d,%0d,%0d,0", cycle, wb_imm_format, wb_imm_sign, wb_imm_corner, wb_imm);
            end
            if (if_ex_valid) begin
                $fdisplay(fd, "%0d,decode,%0d,%0d,%0d,%0d,%0d", cycle, dec_opcode, if_ex_is_16bit, dec_funct3, dec_funct7, id_md_op);
                if (id_is_branch) $fdisplay(fd, "%0d,branch,%0d,%0d,0,0,0", cycle, branch_taken, branch_backward);
                if (id_is_jal || id_is_jalr) $fdisplay(fd, "%0d,jump,%0d,%0d,0,0,0", cycle, id_is_jal, id_is_jalr);
                if (id_is_csr) $fdisplay(fd, "%0d,csr_decode,%0d,0,0,0,0", cycle, id_csr_op);
                if (id_is_mret) $fdisplay(fd, "%0d,mret_decode,1,0,0,0,0", cycle);
            end
            if (ex_mem_valid_r && (ex_mem_is_load_r || ex_mem_is_store_r)) $fdisplay(fd, "%0d,ls,%0d,%0d,%0d,%0d,0", cycle, ex_mem_is_load_r, ex_mem_is_store_r, ex_mem_ls_funct3_r, ex_mem_addr_lo_r);
            if (ras_push) $fdisplay(fd, "%0d,ras,push,0,0,0,0", cycle);
            if (ras_pop) $fdisplay(fd, "%0d,ras,pop,0,0,0,0", cycle);
            if (bp_event) $fdisplay(fd, "%0d,bp,%0d,0,0,0,0", cycle, ex_mem_mispredict_r);
            if (load_use_stall) $fdisplay(fd, "%0d,hazard,load_use,0,0,0,0", cycle);
            if (muldiv_busy_stall) $fdisplay(fd, "%0d,hazard,muldiv_busy,0,0,0,0", cycle);
            if (fetch_stall) $fdisplay(fd, "%0d,hazard,fetch_stall,0,0,0,0", cycle);
            if (mem_stall) $fdisplay(fd, "%0d,hazard,mem_stall,0,0,0,0", cycle);
            if (pc_redirect) $fdisplay(fd, "%0d,redirect,1,0,0,0,0", cycle);
            if (wb_csr_we) $fdisplay(fd, "%0d,csr,%0d,0,0,0,0", cycle, ex_wb_csr_op_r);
            if (wb_take_irq || wb_take_data_trap || ex_wb_illegal_r) $fdisplay(fd, "%0d,trap,%0d,0,0,0,0", cycle, trap_kind);
            if (ex_wb_valid_r && ex_wb_is_mret_r) $fdisplay(fd, "%0d,mret,1,0,0,0,0", cycle);
        end
    end

    final begin
        $fclose(fd);
    end
endmodule

bind core cpu_m1_func_cov_observer u_cpu_m1_func_cov_observer (
    .clk(clk), .resetn(resetn), .stall(stall), .fetch_stall(fetch_stall), .mem_stall(mem_stall),
    .pc_redirect(pc_redirect), .id_advance_to_ex_mem(id_advance_to_ex_mem), .ex_mem_advance_to_wb(ex_mem_advance_to_wb),
    .if_ex_valid(if_ex_valid), .if_ex_instr(if_ex_instr), .if_ex_is_16bit(if_ex_is_16bit),
    .id_is_branch(id_is_branch), .branch_taken(branch_taken), .id_is_jal(id_is_jal), .id_is_jalr(id_is_jalr),
    .id_is_load(id_is_load), .id_is_store(id_is_store), .id_ls_funct3(id_ls_funct3),
    .id_is_csr(id_is_csr), .id_csr_op(id_csr_op), .id_is_mret(id_is_mret), .id_is_muldiv(id_is_muldiv),
    .id_md_op(id_md_op), .id_md_is_div(id_md_is_div), .id_illegal(id_illegal), .id_imm(id_imm),
    .id_rd_idx(id_rd_idx), .id_rs1_idx(id_rs1_idx), .id_rs2_idx(id_rs2_idx), .rs1_val(rs1_val), .rs2_val(rs2_val),
    .store_addr_lo(store_addr_lo),
    .ex_mem_valid_r(ex_mem_valid_r), .ex_mem_is_load_r(ex_mem_is_load_r), .ex_mem_is_store_r(ex_mem_is_store_r),
    .ex_mem_ls_funct3_r(ex_mem_ls_funct3_r), .ex_mem_addr_lo_r(ex_mem_addr_lo_r),
    .ex_mem_is_branch_taken_r(ex_mem_is_branch_taken_r), .ex_mem_is_jal_r(ex_mem_is_jal_r), .ex_mem_is_jalr_r(ex_mem_is_jalr_r),
    .ex_mem_mispredict_r(ex_mem_mispredict_r), .ex_mem_pred_ras_r(ex_mem_pred_ras_r), .ex_mem_bp_upd_valid_r(ex_mem_bp_upd_valid_r),
    .ex_wb_valid_r(ex_wb_valid_r), .ex_wb_illegal_r(ex_wb_illegal_r), .ex_wb_is_mret_r(ex_wb_is_mret_r),
    .wb_instr_retired(wb_instr_retired), .wb_csr_we(wb_csr_we), .ex_wb_csr_op_r(ex_wb_csr_op_r),
    .wb_take_irq(wb_take_irq), .wb_take_data_trap(wb_take_data_trap), .ex_wb_is_misaligned_store_r(ex_wb_is_misaligned_store_r),
    .ras_push(ras_push), .ras_pop(ras_pop), .md_busy(md_busy)
);
