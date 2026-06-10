//      // verilator_coverage annotation
        `timescale 1ns/1ps
        `include "def.vh"
        
        module tb_forward_unit;
 000169     reg  [ 4:0] id_rs1_idx;
 000168     reg  [ 4:0] id_rs2_idx;
 000681     reg  [31:0] rfu_rs1_data;
 000681     reg  [31:0] rfu_rs2_data;
%000001     reg         em_valid;
 000201     reg         em_rd_we;
 000302     reg  [ 4:0] em_rd_idx;
 000623     reg  [31:0] em_fwd_val;
 000201     reg         em_is_load;
 000401     reg         wb_valid;
%000001     reg         wb_rd_we;
 000337     reg  [ 4:0] wb_rd_idx;
 000618     reg  [31:0] wb_data;
 000601     reg         wb_is_load;
 000581     wire [31:0] rs1_val;
 000581     wire [31:0] rs2_val;
        
            integer vectors;
            integer errors;
            integer pidx;
            integer ridx;
        
            reg [31:0] patterns [0:67];
~000016     reg [4:0]  rs2_target_idx;
~000016     reg [4:0]  ridx_idx;
        
            forward dut (
                .id_rs1_idx(id_rs1_idx),
                .id_rs2_idx(id_rs2_idx),
                .rfu_rs1_data(rfu_rs1_data),
                .rfu_rs2_data(rfu_rs2_data),
                .em_valid(em_valid),
                .em_rd_we(em_rd_we),
                .em_rd_idx(em_rd_idx),
                .em_fwd_val(em_fwd_val),
                .em_is_load(em_is_load),
                .wb_valid(wb_valid),
                .wb_rd_we(wb_rd_we),
                .wb_rd_idx(wb_rd_idx),
                .wb_data(wb_data),
                .wb_is_load(wb_is_load),
                .rs1_val(rs1_val),
                .rs2_val(rs2_val)
            );
        
 002808     function [31:0] golden_operand;
                input [4:0]  rs_idx;
                input [31:0] rfu_data;
                input        f_em_valid;
                input        f_em_rd_we;
                input [4:0]  f_em_rd_idx;
                input [31:0] f_em_fwd_val;
                input        f_em_is_load;
                input        f_wb_valid;
                input        f_wb_rd_we;
                input [4:0]  f_wb_rd_idx;
                input [31:0] f_wb_data;
 002808         reg          em_can_forward;
 002808         reg          em_match;
 002808         reg          wb_can_forward;
 002808         reg          wb_match;
 002808         begin
~002808             em_can_forward = f_em_valid && f_em_rd_we && !f_em_is_load && (f_em_rd_idx != 5'd0);
 002808             em_match       = em_can_forward && (rs_idx == f_em_rd_idx);
~002808             wb_can_forward = f_wb_valid && f_wb_rd_we && (f_wb_rd_idx != 5'd0);
 002808             wb_match       = wb_can_forward && !em_match && (rs_idx == f_wb_rd_idx);
        
 000404             if (em_match)
 000404                 golden_operand = f_em_fwd_val;
 002204             else if (wb_match)
 000200                 golden_operand = f_wb_data;
                    else
 002204                 golden_operand = rfu_data;
                end
            endfunction
        
 001404     task check_outputs;
                input [8*40-1:0] tag;
 001404         reg [31:0] exp_rs1;
 001404         reg [31:0] exp_rs2;
 001404         begin
 001404             #1;
 001404             exp_rs1 = golden_operand(id_rs1_idx, rfu_rs1_data,
 001404                                      em_valid, em_rd_we, em_rd_idx, em_fwd_val, em_is_load,
 001404                                      wb_valid, wb_rd_we, wb_rd_idx, wb_data);
 001404             exp_rs2 = golden_operand(id_rs2_idx, rfu_rs2_data,
 001404                                      em_valid, em_rd_we, em_rd_idx, em_fwd_val, em_is_load,
 001404                                      wb_valid, wb_rd_we, wb_rd_idx, wb_data);
 001404             vectors = vectors + 1;
~001404             if (rs1_val !== exp_rs1 || rs2_val !== exp_rs2) begin
                        errors = errors + 1;
                        $error("FAIL[%0d] %0s rs1_idx=%0d rs2_idx=%0d em_v/we/rd/load=%b/%b/%0d/%b wb_v/we/rd/load=%b/%b/%0d/%b rs1=%h exp_rs1=%h rs2=%h exp_rs2=%h",
                               vectors, tag, id_rs1_idx, id_rs2_idx,
                               em_valid, em_rd_we, em_rd_idx, em_is_load,
                               wb_valid, wb_rd_we, wb_rd_idx, wb_is_load,
                               rs1_val, exp_rs1, rs2_val, exp_rs2);
                    end
                end
            endtask
        
 001403     task drive_case;
                input [4:0]  t_rs1_idx;
                input [4:0]  t_rs2_idx;
                input [31:0] t_rfu_rs1_data;
                input [31:0] t_rfu_rs2_data;
                input        t_em_valid;
                input        t_em_rd_we;
                input [4:0]  t_em_rd_idx;
                input [31:0] t_em_fwd_val;
                input        t_em_is_load;
                input        t_wb_valid;
                input        t_wb_rd_we;
                input [4:0]  t_wb_rd_idx;
                input [31:0] t_wb_data;
                input        t_wb_is_load;
                input [8*40-1:0] tag;
 001403         begin
 001403             id_rs1_idx   = t_rs1_idx;
 001403             id_rs2_idx   = t_rs2_idx;
 001403             rfu_rs1_data = t_rfu_rs1_data;
 001403             rfu_rs2_data = t_rfu_rs2_data;
 001403             em_valid     = t_em_valid;
 001403             em_rd_we     = t_em_rd_we;
 001403             em_rd_idx    = t_em_rd_idx;
 001403             em_fwd_val   = t_em_fwd_val;
 001403             em_is_load   = t_em_is_load;
 001403             wb_valid     = t_wb_valid;
 001403             wb_rd_we     = t_wb_rd_we;
 001403             wb_rd_idx    = t_wb_rd_idx;
 001403             wb_data      = t_wb_data;
 001403             wb_is_load   = t_wb_is_load;
 001403             check_outputs(tag);
                end
            endtask
        
 000100     task run_truth_table_for_rs1;
                input [4:0]  target_idx;
                input [31:0] base_pattern;
 000100         begin
 000100             drive_case(target_idx, 5'd22, base_pattern ^ 32'h1111_0001, base_pattern ^ 32'h2222_0002,
 000100                        1'b1, 1'b1, 5'd9,  base_pattern ^ 32'he0e0_e0e0, 1'b0,
 000100                        1'b1, 1'b1, 5'd10, base_pattern ^ 32'h0b0b_0b0b, 1'b0, "RS1_NO_MATCH");
 000100             drive_case(target_idx, 5'd22, base_pattern ^ 32'h1111_0003, base_pattern ^ 32'h2222_0004,
 000100                        1'b1, 1'b1, target_idx, base_pattern ^ 32'he1e1_e1e1, 1'b0,
 000100                        1'b1, 1'b1, 5'd10,      base_pattern ^ 32'h0b0b_0b0c, 1'b1, "RS1_EX_MEM_MATCH");
 000100             drive_case(target_idx, 5'd22, base_pattern ^ 32'h1111_0005, base_pattern ^ 32'h2222_0006,
 000100                        1'b1, 1'b1, 5'd9,       base_pattern ^ 32'he2e2_e2e2, 1'b0,
 000100                        1'b1, 1'b1, target_idx, base_pattern ^ 32'h0b0b_0b0d, 1'b0, "RS1_EX_WB_MATCH");
 000100             drive_case(target_idx, 5'd22, base_pattern ^ 32'h1111_0007, base_pattern ^ 32'h2222_0008,
 000100                        1'b1, 1'b1, target_idx, base_pattern ^ 32'he3e3_e3e3, 1'b0,
 000100                        1'b1, 1'b1, target_idx, base_pattern ^ 32'h0b0b_0b0e, 1'b1, "RS1_BOTH_EM_PRIORITY");
 000100             drive_case(target_idx, 5'd22, base_pattern ^ 32'h1111_0009, base_pattern ^ 32'h2222_000a,
 000100                        1'b1, 1'b0, target_idx, base_pattern ^ 32'he4e4_e4e4, 1'b0,
 000100                        1'b0, 1'b1, target_idx, base_pattern ^ 32'h0b0b_0b0f, 1'b0, "RS1_MATCH_WE0_NO_FWD");
 000100             drive_case(5'd0, 5'd22, base_pattern ^ 32'h1111_000b, base_pattern ^ 32'h2222_000c,
 000100                        1'b1, 1'b1, 5'd0, base_pattern ^ 32'he5e5_e5e5, 1'b0,
 000100                        1'b1, 1'b1, 5'd0, base_pattern ^ 32'h0b0b_0b10, 1'b1, "RS1_MATCH_X0_NO_FWD");
 000100             drive_case(target_idx, 5'd22, base_pattern ^ 32'h1111_000d, base_pattern ^ 32'h2222_000e,
 000100                        1'b1, 1'b1, target_idx, base_pattern ^ 32'he6e6_e6e6, 1'b1,
 000100                        1'b0, 1'b1, target_idx, base_pattern ^ 32'h0b0b_0b11, 1'b0, "RS1_EM_LOAD_NO_FWD");
                end
            endtask
        
 000100     task run_truth_table_for_rs2;
                input [4:0]  target_idx;
                input [31:0] base_pattern;
 000100         begin
 000100             drive_case(5'd21, target_idx, base_pattern ^ 32'h3333_0001, base_pattern ^ 32'h4444_0002,
 000100                        1'b1, 1'b1, 5'd9,  base_pattern ^ 32'he7e7_e7e7, 1'b0,
 000100                        1'b1, 1'b1, 5'd10, base_pattern ^ 32'h0c0c_0c0c, 1'b0, "RS2_NO_MATCH");
 000100             drive_case(5'd21, target_idx, base_pattern ^ 32'h3333_0003, base_pattern ^ 32'h4444_0004,
 000100                        1'b1, 1'b1, target_idx, base_pattern ^ 32'he8e8_e8e8, 1'b0,
 000100                        1'b1, 1'b1, 5'd10,      base_pattern ^ 32'h0c0c_0c0d, 1'b1, "RS2_EX_MEM_MATCH");
 000100             drive_case(5'd21, target_idx, base_pattern ^ 32'h3333_0005, base_pattern ^ 32'h4444_0006,
 000100                        1'b1, 1'b1, 5'd9,       base_pattern ^ 32'he9e9_e9e9, 1'b0,
 000100                        1'b1, 1'b1, target_idx, base_pattern ^ 32'h0c0c_0c0e, 1'b0, "RS2_EX_WB_MATCH");
 000100             drive_case(5'd21, target_idx, base_pattern ^ 32'h3333_0007, base_pattern ^ 32'h4444_0008,
 000100                        1'b1, 1'b1, target_idx, base_pattern ^ 32'heaea_eaea, 1'b0,
 000100                        1'b1, 1'b1, target_idx, base_pattern ^ 32'h0c0c_0c0f, 1'b1, "RS2_BOTH_EM_PRIORITY");
 000100             drive_case(5'd21, target_idx, base_pattern ^ 32'h3333_0009, base_pattern ^ 32'h4444_000a,
 000100                        1'b1, 1'b0, target_idx, base_pattern ^ 32'hebeb_ebeb, 1'b0,
 000100                        1'b0, 1'b1, target_idx, base_pattern ^ 32'h0c0c_0c10, 1'b0, "RS2_MATCH_WE0_NO_FWD");
 000100             drive_case(5'd21, 5'd0, base_pattern ^ 32'h3333_000b, base_pattern ^ 32'h4444_000c,
 000100                        1'b1, 1'b1, 5'd0, base_pattern ^ 32'hecec_ecec, 1'b0,
 000100                        1'b1, 1'b1, 5'd0, base_pattern ^ 32'h0c0c_0c11, 1'b1, "RS2_MATCH_X0_NO_FWD");
 000100             drive_case(5'd21, target_idx, base_pattern ^ 32'h3333_000d, base_pattern ^ 32'h4444_000e,
 000100                        1'b1, 1'b1, target_idx, base_pattern ^ 32'heded_eded, 1'b1,
 000100                        1'b0, 1'b1, target_idx, base_pattern ^ 32'h0c0c_0c12, 1'b0, "RS2_EM_LOAD_NO_FWD");
                end
            endtask
        
%000001     initial begin
%000001         patterns[0] = 32'h0000_0000;
%000001         patterns[1] = 32'hffff_ffff;
%000001         patterns[2] = 32'haaaa_aaaa;
%000001         patterns[3] = 32'h5555_5555;
~000032         for (pidx = 0; pidx < 32; pidx = pidx + 1) begin
 000032             patterns[4 + pidx]  = 32'h0000_0001 << pidx;
 000032             patterns[36 + pidx] = ~(32'h0000_0001 << pidx);
                end
        
%000001         vectors      = 0;
%000001         errors       = 0;
%000001         id_rs1_idx   = 5'd0;
%000001         id_rs2_idx   = 5'd0;
%000001         rfu_rs1_data = 32'h0000_0000;
%000001         rfu_rs2_data = 32'h0000_0000;
%000001         em_valid     = 1'b0;
%000001         em_rd_we     = 1'b0;
%000001         em_rd_idx    = 5'd0;
%000001         em_fwd_val   = 32'h0000_0000;
%000001         em_is_load   = 1'b0;
%000001         wb_valid     = 1'b0;
%000001         wb_rd_we     = 1'b0;
%000001         wb_rd_idx    = 5'd0;
%000001         wb_data      = 32'h0000_0000;
%000001         wb_is_load   = 1'b0;
        
%000001         check_outputs("RESET_NO_FORWARD");
        
~000032         for (ridx = 0; ridx < 32; ridx = ridx + 1) begin
 000032             run_truth_table_for_rs1(ridx[4:0], patterns[(ridx * 7) % 68]);
 000032             ridx_idx = ridx[4:0];
 000032             rs2_target_idx = ~ridx_idx;
 000032             run_truth_table_for_rs2(rs2_target_idx, patterns[(ridx * 11) % 68]);
                end
        
~000068         for (pidx = 0; pidx < 68; pidx = pidx + 1) begin
 000068             run_truth_table_for_rs1(5'd13, patterns[pidx]);
 000068             run_truth_table_for_rs2(5'd17, ~patterns[pidx]);
                end
        
%000001         drive_case(5'd12, 5'd14, 32'h1200_1200, 32'h1400_1400,
%000001                    1'b0, 1'b1, 5'd12, 32'heeee_1212, 1'b0,
%000001                    1'b0, 1'b1, 5'd14, 32'hbbbb_1414, 1'b0, "EM_VALID0_OTHER_PREDICATES_TRUE");
%000001         drive_case(5'd15, 5'd16, 32'h1500_1500, 32'h1600_1600,
%000001                    1'b0, 1'b1, 5'd20, 32'heeee_1515, 1'b0,
%000001                    1'b1, 1'b0, 5'd15, 32'hbbbb_1515, 1'b1, "WB_WE0_OTHER_PREDICATES_TRUE");
%000001         drive_case(5'd31, 5'd30, 32'hffff_ffff, 32'h0000_0000,
%000001                    1'b0, 1'b0, 5'd31, 32'h5555_5555, 1'b1,
%000001                    1'b0, 1'b0, 5'd30, 32'haaaa_aaaa, 1'b1, "ALL_ENABLES_LOW");
        
%000001         if (errors == 0) begin
%000001             $display("PASS: forward unit %0d/%0d vectors", vectors, vectors);
%000001             $finish;
                end else begin
                    $display("FAIL: forward unit %0d/%0d vectors failed", errors, vectors);
                    $fatal(1);
                end
            end
        endmodule
        
