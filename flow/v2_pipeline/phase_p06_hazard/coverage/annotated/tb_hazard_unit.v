//      // verilator_coverage annotation
        `timescale 1ns/1ps
        `include "def.vh"
        
        module tb_hazard_unit;
%000002     reg         id_valid;
 000256     reg  [ 4:0] id_rs1_idx;
 000258     reg  [ 4:0] id_rs2_idx;
 000145     reg         id_is_muldiv;
%000003     reg         em_valid;
%000009     reg         em_rd_we;
 000257     reg  [ 4:0] em_rd_idx;
 000020     reg         em_is_load;
 000531     reg         wb_valid;
 000530     reg         wb_rd_we;
 000529     reg  [ 4:0] wb_rd_idx;
 000531     reg         wb_is_load;
 000273     reg         md_busy;
 000078     wire        stall;
        
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
        
 000240     reg [4:0] producer_idx;
        
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
        
 001096     function golden_stall;
                input        f_id_valid;
                input [4:0]  f_id_rs1_idx;
                input [4:0]  f_id_rs2_idx;
                input        f_id_is_muldiv;
                input        f_em_valid;
                input        f_em_rd_we;
                input [4:0]  f_em_rd_idx;
                input        f_em_is_load;
                input        f_md_busy;
 001096         reg          source_reads_pending_load;
 001096         reg          load_wait_required;
 001096         reg          muldiv_wait_required;
 001096         begin
 001096             source_reads_pending_load =
 001096                 (f_em_rd_idx != 5'd0) &&
 001096                 ((f_id_rs1_idx == f_em_rd_idx) || (f_id_rs2_idx == f_em_rd_idx));
 001096             load_wait_required =
 001096                 f_id_valid && f_em_valid && f_em_is_load && f_em_rd_we &&
 001096                 source_reads_pending_load;
 001096             muldiv_wait_required = f_id_valid && f_id_is_muldiv && f_md_busy;
 001096             golden_stall = load_wait_required || muldiv_wait_required;
                end
            endfunction
        
 001096     task check_outputs;
                input [8*48-1:0] tag;
 001096         reg exp_stall;
 001096         begin
 001096             #1;
 001096             exp_stall = golden_stall(id_valid, id_rs1_idx, id_rs2_idx, id_is_muldiv,
 001096                                      em_valid, em_rd_we, em_rd_idx, em_is_load,
 001096                                      md_busy);
 001096             vectors = vectors + 1;
 001096             if (stall !== exp_stall) begin
                        errors = errors + 1;
                        $error("FAIL[%0d] %0s id_v=%b rs1=%0d rs2=%0d muldiv=%b em_v/we/rd/load=%b/%b/%0d/%b wb_v/we/rd/load=%b/%b/%0d/%b md_busy=%b stall=%b exp=%b",
                               vectors, tag, id_valid, id_rs1_idx, id_rs2_idx, id_is_muldiv,
                               em_valid, em_rd_we, em_rd_idx, em_is_load,
                               wb_valid, wb_rd_we, wb_rd_idx, wb_is_load,
                               md_busy, stall, exp_stall);
                    end
                end
            endtask
        
 001095     task drive_case;
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
 001095         begin
 001095             id_valid    = t_id_valid;
 001095             id_rs1_idx  = t_id_rs1_idx;
 001095             id_rs2_idx  = t_id_rs2_idx;
 001095             id_is_muldiv = t_id_is_muldiv;
 001095             em_valid    = t_em_valid;
 001095             em_rd_we    = t_em_rd_we;
 001095             em_rd_idx   = t_em_rd_idx;
 001095             em_is_load  = t_em_is_load;
 001095             wb_valid    = t_wb_valid;
 001095             wb_rd_we    = t_wb_rd_we;
 001095             wb_rd_idx   = t_wb_rd_idx;
 001095             wb_is_load  = t_wb_is_load;
 001095             md_busy     = t_md_busy;
 001095             check_outputs(tag);
                end
            endtask
        
 001024     task drive_match_class;
                input [1:0] match_class;
                input [4:0] rd_idx;
 001024         output [4:0] rs1_idx;
 001024         output [4:0] rs2_idx;
 001024         begin
 001024             case (match_class)
 000256                 2'd0: begin
 000256                     rs1_idx = rd_idx + 5'd1;
 000256                     rs2_idx = rd_idx + 5'd2;
                        end
 000256                 2'd1: begin
 000256                     rs1_idx = rd_idx;
 000256                     rs2_idx = rd_idx + 5'd3;
                        end
 000256                 2'd2: begin
 000256                     rs1_idx = rd_idx + 5'd4;
 000256                     rs2_idx = rd_idx;
                        end
 000256                 default: begin
 000256                     rs1_idx = rd_idx;
 000256                     rs2_idx = rd_idx;
                        end
                    endcase
                end
            endtask
        
 001024     task run_vector;
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
 001024         reg [4:0] t_rs1_idx;
 001024         reg [4:0] t_rs2_idx;
 001024         begin
 001024             producer_idx = t_rd_nonzero ? t_seed_idx : 5'd0;
~001008             if (producer_idx == 5'd0 && t_rd_nonzero)
 000016                 producer_idx = 5'd1;
        
 001024             drive_match_class(t_match_class, producer_idx, t_rs1_idx, t_rs2_idx);
 000896             if (!t_rd_nonzero && t_match_class == 2'd0) begin
 000128                 t_rs1_idx = 5'd3;
 000128                 t_rs2_idx = 5'd5;
                    end
        
 001024             drive_case(t_id_valid, t_rs1_idx, t_rs2_idx, t_id_is_muldiv,
 001024                        t_em_valid, t_em_rd_we, producer_idx, t_em_is_load,
 001024                        t_wb_toggle, ~t_wb_toggle, t_seed_idx ^ 5'd21, ~t_wb_toggle,
 001024                        t_md_busy, tag);
                end
            endtask
        
%000001     initial begin
%000001         vectors      = 0;
%000001         errors       = 0;
%000001         id_valid     = 1'b0;
%000001         id_rs1_idx   = 5'd0;
%000001         id_rs2_idx   = 5'd0;
%000001         id_is_muldiv = 1'b0;
%000001         em_valid     = 1'b0;
%000001         em_rd_we     = 1'b0;
%000001         em_rd_idx    = 5'd0;
%000001         em_is_load   = 1'b0;
%000001         wb_valid     = 1'b0;
%000001         wb_rd_we     = 1'b0;
%000001         wb_rd_idx    = 5'd0;
%000001         wb_is_load   = 1'b0;
%000001         md_busy      = 1'b0;
        
%000001         check_outputs("DEFAULT_NO_STALL");
        
%000001         drive_case(1'b1, 5'd8, 5'd9, 1'b0,
%000001                    1'b1, 1'b1, 5'd8, 1'b1,
%000001                    1'b0, 1'b0, 5'd0, 1'b0,
%000001                    1'b0, "LOAD_USE_RS1");
%000001         drive_case(1'b1, 5'd8, 5'd9, 1'b0,
%000001                    1'b1, 1'b1, 5'd9, 1'b1,
%000001                    1'b1, 1'b0, 5'd9, 1'b1,
%000001                    1'b0, "LOAD_USE_RS2");
%000001         drive_case(1'b1, 5'd10, 5'd10, 1'b0,
%000001                    1'b1, 1'b1, 5'd10, 1'b1,
%000001                    1'b0, 1'b1, 5'd11, 1'b0,
%000001                    1'b0, "LOAD_USE_BOTH");
%000001         drive_case(1'b1, 5'd12, 5'd13, 1'b0,
%000001                    1'b1, 1'b1, 5'd14, 1'b1,
%000001                    1'b1, 1'b1, 5'd12, 1'b1,
%000001                    1'b0, "LOAD_USE_NEITHER");
%000001         drive_case(1'b1, 5'd0, 5'd0, 1'b0,
%000001                    1'b1, 1'b1, 5'd0, 1'b1,
%000001                    1'b0, 1'b0, 5'd0, 1'b0,
%000001                    1'b0, "LOAD_USE_RD_X0_SUPPRESS");
%000001         drive_case(1'b1, 5'd15, 5'd16, 1'b1,
%000001                    1'b0, 1'b0, 5'd0, 1'b0,
%000001                    1'b1, 1'b0, 5'd31, 1'b1,
%000001                    1'b1, "MULDIV_BUSY");
%000001         drive_case(1'b1, 5'd15, 5'd16, 1'b1,
%000001                    1'b0, 1'b0, 5'd0, 1'b0,
%000001                    1'b0, 1'b1, 5'd30, 1'b0,
%000001                    1'b0, "MULDIV_NOT_BUSY");
%000001         drive_case(1'b0, 5'd1, 5'd2, 1'b0,
%000001                    1'b0, 1'b0, 5'd0, 1'b0,
%000001                    1'b1, 1'b0, 5'd0, 1'b0,
%000001                    1'b0, "WB_VALID_ONLY_UNUSED");
%000001         drive_case(1'b0, 5'd1, 5'd2, 1'b0,
%000001                    1'b0, 1'b0, 5'd0, 1'b0,
%000001                    1'b0, 1'b1, 5'd0, 1'b0,
%000001                    1'b0, "WB_WE_ONLY_UNUSED");
        
%000002         for (idv_i = 0; idv_i < 2; idv_i = idv_i + 1)
%000004             for (emv_i = 0; emv_i < 2; emv_i = emv_i + 1)
%000008                 for (load_i = 0; load_i < 2; load_i = load_i + 1)
~000016                     for (we_i = 0; we_i < 2; we_i = we_i + 1)
 000032                         for (nonzero_i = 0; nonzero_i < 2; nonzero_i = nonzero_i + 1)
 000128                             for (match_i = 0; match_i < 4; match_i = match_i + 1)
 000256                                 for (muldiv_i = 0; muldiv_i < 2; muldiv_i = muldiv_i + 1)
 000512                                     for (busy_i = 0; busy_i < 2; busy_i = busy_i + 1)
 001024                                         for (wb_i = 0; wb_i < 2; wb_i = wb_i + 1)
 001024                                             run_vector(idv_i[0], emv_i[0], load_i[0], we_i[0],
 001024                                                        nonzero_i[0], match_i[1:0],
 001024                                                        muldiv_i[0], busy_i[0], wb_i[0],
 001024                                                        (5'd1 + vectors[4:0]), "PREDICATE_MATRIX");
        
~000031         for (ridx = 1; ridx < 32; ridx = ridx + 1) begin
 000031             drive_case(1'b1, ridx[4:0], ~ridx[4:0], 1'b0,
 000031                        1'b1, 1'b1, ridx[4:0], 1'b1,
 000031                        ridx[0], ridx[1], ~ridx[4:0], ridx[2],
 000031                        ridx[3], "RD_BIT_TOGGLE_RS1");
 000031             drive_case(1'b1, ~ridx[4:0], ridx[4:0], ridx[0],
 000031                        1'b1, 1'b1, ridx[4:0], ridx[1],
 000031                        ridx[2], ridx[3], ridx[4:0] ^ 5'd17, ridx[4],
 000031                        ridx[1], "RD_BIT_TOGGLE_RS2");
                end
        
%000001         if (errors == 0) begin
%000001             $display("PASS: hazard unit %0d/%0d vectors", vectors, vectors);
%000001             $finish;
                end else begin
                    $display("FAIL: hazard unit %0d/%0d vectors failed", errors, vectors);
                    $fatal(1);
                end
            end
        endmodule
        
