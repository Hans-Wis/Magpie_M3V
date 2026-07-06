`timescale 1ns/1ps
`include "def.vh"

module tb_hazard_unit;
    reg         id_valid;
    reg  [ 4:0] id_rs1_idx;
    reg  [ 4:0] id_rs2_idx;
    reg         id_is_muldiv;
    reg         em_valid;
    reg         em_rd_we;
    reg  [ 4:0] em_rd_idx;
    reg         em_is_load;
    reg         wb_valid;
    reg         wb_rd_we;
    reg  [ 4:0] wb_rd_idx;
    reg         wb_is_load;
    reg         md_busy;
    wire        stall;

    integer vectors;
    integer errors;
    integer idv_i;
    integer emv_i;
    integer load_i;
    integer we_i;
    integer nonzero_i;
    integer match_i;
    integer muldiv_i;
    integer busy_i;
    integer wb_i;
    integer ridx;

    reg [4:0] producer_idx;

    hazard dut (
        .id_valid(id_valid),
        .id_rs1_idx(id_rs1_idx),
        .id_rs2_idx(id_rs2_idx),
        .id_is_muldiv(id_is_muldiv),
        .em_valid(em_valid),
        .em_rd_we(em_rd_we),
        .em_rd_idx(em_rd_idx),
        .em_is_load(em_is_load),
        .wb_valid(wb_valid),
        .wb_rd_we(wb_rd_we),
        .wb_rd_idx(wb_rd_idx),
        .wb_is_load(wb_is_load),
        .md_busy(md_busy),
        .stall(stall)
    );

    function golden_stall;
        input        f_id_valid;
        input [4:0]  f_id_rs1_idx;
        input [4:0]  f_id_rs2_idx;
        input        f_id_is_muldiv;
        input        f_em_valid;
        input        f_em_rd_we;
        input [4:0]  f_em_rd_idx;
        input        f_em_is_load;
        input        f_md_busy;
        reg          source_reads_pending_load;
        reg          load_wait_required;
        reg          muldiv_wait_required;
        begin
            source_reads_pending_load =
                (f_em_rd_idx != 5'd0) &&
                ((f_id_rs1_idx == f_em_rd_idx) || (f_id_rs2_idx == f_em_rd_idx));
            load_wait_required =
                f_id_valid && f_em_valid && f_em_is_load && f_em_rd_we &&
                source_reads_pending_load;
            muldiv_wait_required = f_id_valid && f_id_is_muldiv && f_md_busy;
            golden_stall = load_wait_required || muldiv_wait_required;
        end
    endfunction

    task check_outputs;
        input [8*48-1:0] tag;
        reg exp_stall;
        begin
            #1;
            exp_stall = golden_stall(id_valid, id_rs1_idx, id_rs2_idx, id_is_muldiv,
                                     em_valid, em_rd_we, em_rd_idx, em_is_load,
                                     md_busy);
            vectors = vectors + 1;
            if (stall !== exp_stall) begin
                errors = errors + 1;
                $error("FAIL[%0d] %0s id_v=%b rs1=%0d rs2=%0d muldiv=%b em_v/we/rd/load=%b/%b/%0d/%b wb_v/we/rd/load=%b/%b/%0d/%b md_busy=%b stall=%b exp=%b",
                       vectors, tag, id_valid, id_rs1_idx, id_rs2_idx, id_is_muldiv,
                       em_valid, em_rd_we, em_rd_idx, em_is_load,
                       wb_valid, wb_rd_we, wb_rd_idx, wb_is_load,
                       md_busy, stall, exp_stall);
            end
        end
    endtask

    task drive_case;
        input        t_id_valid;
        input [4:0]  t_id_rs1_idx;
        input [4:0]  t_id_rs2_idx;
        input        t_id_is_muldiv;
        input        t_em_valid;
        input        t_em_rd_we;
        input [4:0]  t_em_rd_idx;
        input        t_em_is_load;
        input        t_wb_valid;
        input        t_wb_rd_we;
        input [4:0]  t_wb_rd_idx;
        input        t_wb_is_load;
        input        t_md_busy;
        input [8*48-1:0] tag;
        begin
            id_valid    = t_id_valid;
            id_rs1_idx  = t_id_rs1_idx;
            id_rs2_idx  = t_id_rs2_idx;
            id_is_muldiv = t_id_is_muldiv;
            em_valid    = t_em_valid;
            em_rd_we    = t_em_rd_we;
            em_rd_idx   = t_em_rd_idx;
            em_is_load  = t_em_is_load;
            wb_valid    = t_wb_valid;
            wb_rd_we    = t_wb_rd_we;
            wb_rd_idx   = t_wb_rd_idx;
            wb_is_load  = t_wb_is_load;
            md_busy     = t_md_busy;
            check_outputs(tag);
        end
    endtask

    task drive_match_class;
        input [1:0] match_class;
        input [4:0] rd_idx;
        output [4:0] rs1_idx;
        output [4:0] rs2_idx;
        begin
            case (match_class)
                2'd0: begin
                    rs1_idx = rd_idx + 5'd1;
                    rs2_idx = rd_idx + 5'd2;
                end
                2'd1: begin
                    rs1_idx = rd_idx;
                    rs2_idx = rd_idx + 5'd3;
                end
                2'd2: begin
                    rs1_idx = rd_idx + 5'd4;
                    rs2_idx = rd_idx;
                end
                default: begin
                    rs1_idx = rd_idx;
                    rs2_idx = rd_idx;
                end
            endcase
        end
    endtask

    task run_vector;
        input        t_id_valid;
        input        t_em_valid;
        input        t_em_is_load;
        input        t_em_rd_we;
        input        t_rd_nonzero;
        input [1:0]  t_match_class;
        input        t_id_is_muldiv;
        input        t_md_busy;
        input        t_wb_toggle;
        input [4:0]  t_seed_idx;
        input [8*48-1:0] tag;
        reg [4:0] t_rs1_idx;
        reg [4:0] t_rs2_idx;
        begin
            producer_idx = t_rd_nonzero ? t_seed_idx : 5'd0;
            if (producer_idx == 5'd0 && t_rd_nonzero)
                producer_idx = 5'd1;

            drive_match_class(t_match_class, producer_idx, t_rs1_idx, t_rs2_idx);
            if (!t_rd_nonzero && t_match_class == 2'd0) begin
                t_rs1_idx = 5'd3;
                t_rs2_idx = 5'd5;
            end

            drive_case(t_id_valid, t_rs1_idx, t_rs2_idx, t_id_is_muldiv,
                       t_em_valid, t_em_rd_we, producer_idx, t_em_is_load,
                       t_wb_toggle, ~t_wb_toggle, t_seed_idx ^ 5'd21, ~t_wb_toggle,
                       t_md_busy, tag);
        end
    endtask

    initial begin
        vectors      = 0;
        errors       = 0;
        id_valid     = 1'b0;
        id_rs1_idx   = 5'd0;
        id_rs2_idx   = 5'd0;
        id_is_muldiv = 1'b0;
        em_valid     = 1'b0;
        em_rd_we     = 1'b0;
        em_rd_idx    = 5'd0;
        em_is_load   = 1'b0;
        wb_valid     = 1'b0;
        wb_rd_we     = 1'b0;
        wb_rd_idx    = 5'd0;
        wb_is_load   = 1'b0;
        md_busy      = 1'b0;

        check_outputs("DEFAULT_NO_STALL");

        drive_case(1'b1, 5'd8, 5'd9, 1'b0,
                   1'b1, 1'b1, 5'd8, 1'b1,
                   1'b0, 1'b0, 5'd0, 1'b0,
                   1'b0, "LOAD_USE_RS1");
        drive_case(1'b1, 5'd8, 5'd9, 1'b0,
                   1'b1, 1'b1, 5'd9, 1'b1,
                   1'b1, 1'b0, 5'd9, 1'b1,
                   1'b0, "LOAD_USE_RS2");
        drive_case(1'b1, 5'd10, 5'd10, 1'b0,
                   1'b1, 1'b1, 5'd10, 1'b1,
                   1'b0, 1'b1, 5'd11, 1'b0,
                   1'b0, "LOAD_USE_BOTH");
        drive_case(1'b1, 5'd12, 5'd13, 1'b0,
                   1'b1, 1'b1, 5'd14, 1'b1,
                   1'b1, 1'b1, 5'd12, 1'b1,
                   1'b0, "LOAD_USE_NEITHER");
        drive_case(1'b1, 5'd0, 5'd0, 1'b0,
                   1'b1, 1'b1, 5'd0, 1'b1,
                   1'b0, 1'b0, 5'd0, 1'b0,
                   1'b0, "LOAD_USE_RD_X0_SUPPRESS");
        drive_case(1'b1, 5'd15, 5'd16, 1'b1,
                   1'b0, 1'b0, 5'd0, 1'b0,
                   1'b1, 1'b0, 5'd31, 1'b1,
                   1'b1, "MULDIV_BUSY");
        drive_case(1'b1, 5'd15, 5'd16, 1'b1,
                   1'b0, 1'b0, 5'd0, 1'b0,
                   1'b0, 1'b1, 5'd30, 1'b0,
                   1'b0, "MULDIV_NOT_BUSY");
        drive_case(1'b0, 5'd1, 5'd2, 1'b0,
                   1'b0, 1'b0, 5'd0, 1'b0,
                   1'b1, 1'b0, 5'd0, 1'b0,
                   1'b0, "WB_VALID_ONLY_UNUSED");
        drive_case(1'b0, 5'd1, 5'd2, 1'b0,
                   1'b0, 1'b0, 5'd0, 1'b0,
                   1'b0, 1'b1, 5'd0, 1'b0,
                   1'b0, "WB_WE_ONLY_UNUSED");

        for (idv_i = 0; idv_i < 2; idv_i = idv_i + 1)
            for (emv_i = 0; emv_i < 2; emv_i = emv_i + 1)
                for (load_i = 0; load_i < 2; load_i = load_i + 1)
                    for (we_i = 0; we_i < 2; we_i = we_i + 1)
                        for (nonzero_i = 0; nonzero_i < 2; nonzero_i = nonzero_i + 1)
                            for (match_i = 0; match_i < 4; match_i = match_i + 1)
                                for (muldiv_i = 0; muldiv_i < 2; muldiv_i = muldiv_i + 1)
                                    for (busy_i = 0; busy_i < 2; busy_i = busy_i + 1)
                                        for (wb_i = 0; wb_i < 2; wb_i = wb_i + 1)
                                            run_vector(idv_i[0], emv_i[0], load_i[0], we_i[0],
                                                       nonzero_i[0], match_i[1:0],
                                                       muldiv_i[0], busy_i[0], wb_i[0],
                                                       (5'd1 + vectors[4:0]), "PREDICATE_MATRIX");

        for (ridx = 1; ridx < 32; ridx = ridx + 1) begin
            drive_case(1'b1, ridx[4:0], ~ridx[4:0], 1'b0,
                       1'b1, 1'b1, ridx[4:0], 1'b1,
                       ridx[0], ridx[1], ~ridx[4:0], ridx[2],
                       ridx[3], "RD_BIT_TOGGLE_RS1");
            drive_case(1'b1, ~ridx[4:0], ridx[4:0], ridx[0],
                       1'b1, 1'b1, ridx[4:0], ridx[1],
                       ridx[2], ridx[3], ridx[4:0] ^ 5'd17, ridx[4],
                       ridx[1], "RD_BIT_TOGGLE_RS2");
        end

        if (errors == 0) begin
            $display("PASS: hazard unit %0d/%0d vectors", vectors, vectors);
            $finish;
        end else begin
            $display("FAIL: hazard unit %0d/%0d vectors failed", errors, vectors);
            $fatal(1);
        end
    end
endmodule
