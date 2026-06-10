`timescale 1ns/1ps
`include "def.vh"

module tb_forward_unit;
    reg  [ 4:0] id_rs1_idx;
    reg  [ 4:0] id_rs2_idx;
    reg  [31:0] rfu_rs1_data;
    reg  [31:0] rfu_rs2_data;
    reg         em_valid;
    reg         em_rd_we;
    reg  [ 4:0] em_rd_idx;
    reg  [31:0] em_fwd_val;
    reg         em_is_load;
    reg         wb_valid;
    reg         wb_rd_we;
    reg  [ 4:0] wb_rd_idx;
    reg  [31:0] wb_data;
    reg         wb_is_load;
    wire [31:0] rs1_val;
    wire [31:0] rs2_val;

    integer vectors;
    integer errors;
    integer pidx;
    integer ridx;

    reg [31:0] patterns [0:67];
    reg [4:0]  rs2_target_idx;
    reg [4:0]  ridx_idx;

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

    function [31:0] golden_operand;
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
        reg          em_can_forward;
        reg          em_match;
        reg          wb_can_forward;
        reg          wb_match;
        begin
            em_can_forward = f_em_valid && f_em_rd_we && !f_em_is_load && (f_em_rd_idx != 5'd0);
            em_match       = em_can_forward && (rs_idx == f_em_rd_idx);
            wb_can_forward = f_wb_valid && f_wb_rd_we && (f_wb_rd_idx != 5'd0);
            wb_match       = wb_can_forward && !em_match && (rs_idx == f_wb_rd_idx);

            if (em_match)
                golden_operand = f_em_fwd_val;
            else if (wb_match)
                golden_operand = f_wb_data;
            else
                golden_operand = rfu_data;
        end
    endfunction

    task check_outputs;
        input [8*40-1:0] tag;
        reg [31:0] exp_rs1;
        reg [31:0] exp_rs2;
        begin
            #1;
            exp_rs1 = golden_operand(id_rs1_idx, rfu_rs1_data,
                                     em_valid, em_rd_we, em_rd_idx, em_fwd_val, em_is_load,
                                     wb_valid, wb_rd_we, wb_rd_idx, wb_data);
            exp_rs2 = golden_operand(id_rs2_idx, rfu_rs2_data,
                                     em_valid, em_rd_we, em_rd_idx, em_fwd_val, em_is_load,
                                     wb_valid, wb_rd_we, wb_rd_idx, wb_data);
            vectors = vectors + 1;
            if (rs1_val !== exp_rs1 || rs2_val !== exp_rs2) begin
                errors = errors + 1;
                $error("FAIL[%0d] %0s rs1_idx=%0d rs2_idx=%0d em_v/we/rd/load=%b/%b/%0d/%b wb_v/we/rd/load=%b/%b/%0d/%b rs1=%h exp_rs1=%h rs2=%h exp_rs2=%h",
                       vectors, tag, id_rs1_idx, id_rs2_idx,
                       em_valid, em_rd_we, em_rd_idx, em_is_load,
                       wb_valid, wb_rd_we, wb_rd_idx, wb_is_load,
                       rs1_val, exp_rs1, rs2_val, exp_rs2);
            end
        end
    endtask

    task drive_case;
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
        begin
            id_rs1_idx   = t_rs1_idx;
            id_rs2_idx   = t_rs2_idx;
            rfu_rs1_data = t_rfu_rs1_data;
            rfu_rs2_data = t_rfu_rs2_data;
            em_valid     = t_em_valid;
            em_rd_we     = t_em_rd_we;
            em_rd_idx    = t_em_rd_idx;
            em_fwd_val   = t_em_fwd_val;
            em_is_load   = t_em_is_load;
            wb_valid     = t_wb_valid;
            wb_rd_we     = t_wb_rd_we;
            wb_rd_idx    = t_wb_rd_idx;
            wb_data      = t_wb_data;
            wb_is_load   = t_wb_is_load;
            check_outputs(tag);
        end
    endtask

    task run_truth_table_for_rs1;
        input [4:0]  target_idx;
        input [31:0] base_pattern;
        begin
            drive_case(target_idx, 5'd22, base_pattern ^ 32'h1111_0001, base_pattern ^ 32'h2222_0002,
                       1'b1, 1'b1, 5'd9,  base_pattern ^ 32'he0e0_e0e0, 1'b0,
                       1'b1, 1'b1, 5'd10, base_pattern ^ 32'h0b0b_0b0b, 1'b0, "RS1_NO_MATCH");
            drive_case(target_idx, 5'd22, base_pattern ^ 32'h1111_0003, base_pattern ^ 32'h2222_0004,
                       1'b1, 1'b1, target_idx, base_pattern ^ 32'he1e1_e1e1, 1'b0,
                       1'b1, 1'b1, 5'd10,      base_pattern ^ 32'h0b0b_0b0c, 1'b1, "RS1_EX_MEM_MATCH");
            drive_case(target_idx, 5'd22, base_pattern ^ 32'h1111_0005, base_pattern ^ 32'h2222_0006,
                       1'b1, 1'b1, 5'd9,       base_pattern ^ 32'he2e2_e2e2, 1'b0,
                       1'b1, 1'b1, target_idx, base_pattern ^ 32'h0b0b_0b0d, 1'b0, "RS1_EX_WB_MATCH");
            drive_case(target_idx, 5'd22, base_pattern ^ 32'h1111_0007, base_pattern ^ 32'h2222_0008,
                       1'b1, 1'b1, target_idx, base_pattern ^ 32'he3e3_e3e3, 1'b0,
                       1'b1, 1'b1, target_idx, base_pattern ^ 32'h0b0b_0b0e, 1'b1, "RS1_BOTH_EM_PRIORITY");
            drive_case(target_idx, 5'd22, base_pattern ^ 32'h1111_0009, base_pattern ^ 32'h2222_000a,
                       1'b1, 1'b0, target_idx, base_pattern ^ 32'he4e4_e4e4, 1'b0,
                       1'b0, 1'b1, target_idx, base_pattern ^ 32'h0b0b_0b0f, 1'b0, "RS1_MATCH_WE0_NO_FWD");
            drive_case(5'd0, 5'd22, base_pattern ^ 32'h1111_000b, base_pattern ^ 32'h2222_000c,
                       1'b1, 1'b1, 5'd0, base_pattern ^ 32'he5e5_e5e5, 1'b0,
                       1'b1, 1'b1, 5'd0, base_pattern ^ 32'h0b0b_0b10, 1'b1, "RS1_MATCH_X0_NO_FWD");
            drive_case(target_idx, 5'd22, base_pattern ^ 32'h1111_000d, base_pattern ^ 32'h2222_000e,
                       1'b1, 1'b1, target_idx, base_pattern ^ 32'he6e6_e6e6, 1'b1,
                       1'b0, 1'b1, target_idx, base_pattern ^ 32'h0b0b_0b11, 1'b0, "RS1_EM_LOAD_NO_FWD");
        end
    endtask

    task run_truth_table_for_rs2;
        input [4:0]  target_idx;
        input [31:0] base_pattern;
        begin
            drive_case(5'd21, target_idx, base_pattern ^ 32'h3333_0001, base_pattern ^ 32'h4444_0002,
                       1'b1, 1'b1, 5'd9,  base_pattern ^ 32'he7e7_e7e7, 1'b0,
                       1'b1, 1'b1, 5'd10, base_pattern ^ 32'h0c0c_0c0c, 1'b0, "RS2_NO_MATCH");
            drive_case(5'd21, target_idx, base_pattern ^ 32'h3333_0003, base_pattern ^ 32'h4444_0004,
                       1'b1, 1'b1, target_idx, base_pattern ^ 32'he8e8_e8e8, 1'b0,
                       1'b1, 1'b1, 5'd10,      base_pattern ^ 32'h0c0c_0c0d, 1'b1, "RS2_EX_MEM_MATCH");
            drive_case(5'd21, target_idx, base_pattern ^ 32'h3333_0005, base_pattern ^ 32'h4444_0006,
                       1'b1, 1'b1, 5'd9,       base_pattern ^ 32'he9e9_e9e9, 1'b0,
                       1'b1, 1'b1, target_idx, base_pattern ^ 32'h0c0c_0c0e, 1'b0, "RS2_EX_WB_MATCH");
            drive_case(5'd21, target_idx, base_pattern ^ 32'h3333_0007, base_pattern ^ 32'h4444_0008,
                       1'b1, 1'b1, target_idx, base_pattern ^ 32'heaea_eaea, 1'b0,
                       1'b1, 1'b1, target_idx, base_pattern ^ 32'h0c0c_0c0f, 1'b1, "RS2_BOTH_EM_PRIORITY");
            drive_case(5'd21, target_idx, base_pattern ^ 32'h3333_0009, base_pattern ^ 32'h4444_000a,
                       1'b1, 1'b0, target_idx, base_pattern ^ 32'hebeb_ebeb, 1'b0,
                       1'b0, 1'b1, target_idx, base_pattern ^ 32'h0c0c_0c10, 1'b0, "RS2_MATCH_WE0_NO_FWD");
            drive_case(5'd21, 5'd0, base_pattern ^ 32'h3333_000b, base_pattern ^ 32'h4444_000c,
                       1'b1, 1'b1, 5'd0, base_pattern ^ 32'hecec_ecec, 1'b0,
                       1'b1, 1'b1, 5'd0, base_pattern ^ 32'h0c0c_0c11, 1'b1, "RS2_MATCH_X0_NO_FWD");
            drive_case(5'd21, target_idx, base_pattern ^ 32'h3333_000d, base_pattern ^ 32'h4444_000e,
                       1'b1, 1'b1, target_idx, base_pattern ^ 32'heded_eded, 1'b1,
                       1'b0, 1'b1, target_idx, base_pattern ^ 32'h0c0c_0c12, 1'b0, "RS2_EM_LOAD_NO_FWD");
        end
    endtask

    initial begin
        patterns[0] = 32'h0000_0000;
        patterns[1] = 32'hffff_ffff;
        patterns[2] = 32'haaaa_aaaa;
        patterns[3] = 32'h5555_5555;
        for (pidx = 0; pidx < 32; pidx = pidx + 1) begin
            patterns[4 + pidx]  = 32'h0000_0001 << pidx;
            patterns[36 + pidx] = ~(32'h0000_0001 << pidx);
        end

        vectors      = 0;
        errors       = 0;
        id_rs1_idx   = 5'd0;
        id_rs2_idx   = 5'd0;
        rfu_rs1_data = 32'h0000_0000;
        rfu_rs2_data = 32'h0000_0000;
        em_valid     = 1'b0;
        em_rd_we     = 1'b0;
        em_rd_idx    = 5'd0;
        em_fwd_val   = 32'h0000_0000;
        em_is_load   = 1'b0;
        wb_valid     = 1'b0;
        wb_rd_we     = 1'b0;
        wb_rd_idx    = 5'd0;
        wb_data      = 32'h0000_0000;
        wb_is_load   = 1'b0;

        check_outputs("RESET_NO_FORWARD");

        for (ridx = 0; ridx < 32; ridx = ridx + 1) begin
            run_truth_table_for_rs1(ridx[4:0], patterns[(ridx * 7) % 68]);
            ridx_idx = ridx[4:0];
            rs2_target_idx = ~ridx_idx;
            run_truth_table_for_rs2(rs2_target_idx, patterns[(ridx * 11) % 68]);
        end

        for (pidx = 0; pidx < 68; pidx = pidx + 1) begin
            run_truth_table_for_rs1(5'd13, patterns[pidx]);
            run_truth_table_for_rs2(5'd17, ~patterns[pidx]);
        end

        drive_case(5'd12, 5'd14, 32'h1200_1200, 32'h1400_1400,
                   1'b0, 1'b1, 5'd12, 32'heeee_1212, 1'b0,
                   1'b0, 1'b1, 5'd14, 32'hbbbb_1414, 1'b0, "EM_VALID0_OTHER_PREDICATES_TRUE");
        drive_case(5'd15, 5'd16, 32'h1500_1500, 32'h1600_1600,
                   1'b0, 1'b1, 5'd20, 32'heeee_1515, 1'b0,
                   1'b1, 1'b0, 5'd15, 32'hbbbb_1515, 1'b1, "WB_WE0_OTHER_PREDICATES_TRUE");
        drive_case(5'd31, 5'd30, 32'hffff_ffff, 32'h0000_0000,
                   1'b0, 1'b0, 5'd31, 32'h5555_5555, 1'b1,
                   1'b0, 1'b0, 5'd30, 32'haaaa_aaaa, 1'b1, "ALL_ENABLES_LOW");

        if (errors == 0) begin
            $display("PASS: forward unit %0d/%0d vectors", vectors, vectors);
            $finish;
        end else begin
            $display("FAIL: forward unit %0d/%0d vectors failed", errors, vectors);
            $fatal(1);
        end
    end
endmodule
