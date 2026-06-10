`timescale 1ns/1ps
`include "def.vh"

module tb_div_unit;
    reg         clk;
    reg         resetn;
    reg         start;
    reg  [2:0]  md_op;
    reg  [31:0] op_a;
    reg  [31:0] op_b;
    wire [31:0] result;
    wire        done;

    wire        busy = (dut.state != 2'd0) && !done;

    integer vectors;
    integer errors;
    integer i;
    integer op_i;
    integer sign_i;
    integer mag_a_i;
    integer mag_b_i;
    integer rand_state;

    integer state_hits [0:3];
    integer arc_hits [0:15];
    reg [1:0] prev_state;

    reg [2:0] op_table [0:3];
    reg [31:0] magnitude_table [0:10];

    localparam ST_IDLE  = 2'd0;
    localparam ST_WORK  = 2'd1;
    localparam ST_FIXUP = 2'd2;
    localparam ST_DONE  = 2'd3;

    div dut (
        .clk(clk),
        .resetn(resetn),
        .start(start),
        .md_op(md_op),
        .op_a(op_a),
        .op_b(op_b),
        .result(result),
        .done(done)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (!resetn) begin
            prev_state <= ST_IDLE;
        end else begin
            state_hits[dut.state] = state_hits[dut.state] + 1;

            case ({prev_state, dut.state})
                {ST_IDLE,  ST_IDLE}:  arc_hits[2]  = arc_hits[2]  + 1;
                {ST_IDLE,  ST_WORK}:  begin
                    arc_hits[0]  = arc_hits[0]  + 1;
                    arc_hits[13] = arc_hits[13] + 1;
                end
                {ST_WORK,  ST_WORK}:  begin
                    arc_hits[3]  = arc_hits[3]  + 1;
                    arc_hits[14] = arc_hits[14] + 1;
                    arc_hits[15] = arc_hits[15] + 1;
                end
                {ST_WORK,  ST_FIXUP}: arc_hits[4]  = arc_hits[4]  + 1;
                {ST_FIXUP, ST_DONE}:  arc_hits[11] = arc_hits[11] + 1;
                {ST_DONE,  ST_IDLE}:  begin
                    arc_hits[9]  = arc_hits[9]  + 1;
                    arc_hits[12] = arc_hits[12] + 1;
                end
                default: ;
            endcase

            if (prev_state == ST_WORK && dut.state == ST_FIXUP) begin
                if (dut.divisor == 32'd1)
                    arc_hits[5] = arc_hits[5] + 1;
                if (dut.orig_a == 32'd0)
                    arc_hits[6] = arc_hits[6] + 1;
                if (dut.dividend <= dut.divisor)
                    arc_hits[7] = arc_hits[7] + 1;
                if (dut.overflow)
                    arc_hits[8] = arc_hits[8] + 1;
            end

            prev_state <= dut.state;
        end
    end

    function [31:0] signed_value;
        input [31:0] magnitude;
        input        negative;
        begin
            signed_value = negative ? (~magnitude + 32'd1) : magnitude;
        end
    endfunction

    function [31:0] golden_result;
        input [2:0]  f_md_op;
        input [31:0] f_op_a;
        input [31:0] f_op_b;
        reg signed [31:0] a_s;
        reg signed [31:0] b_s;
        begin
            a_s = f_op_a;
            b_s = f_op_b;

            if (f_op_b == 32'h0000_0000) begin
                golden_result = ((f_md_op == `MD_REM) || (f_md_op == `MD_REMU)) ?
                                f_op_a : 32'hffff_ffff;
            end else if (((f_md_op == `MD_DIV) || (f_md_op == `MD_REM)) &&
                         (f_op_a == 32'h8000_0000) && (f_op_b == 32'hffff_ffff)) begin
                golden_result = (f_md_op == `MD_REM) ? 32'h0000_0000 : 32'h8000_0000;
            end else begin
                case (f_md_op)
                    `MD_DIV:  golden_result = a_s / b_s;
                    `MD_DIVU: golden_result = f_op_a / f_op_b;
                    `MD_REM:  golden_result = a_s % b_s;
                    `MD_REMU: golden_result = f_op_a % f_op_b;
                    default:  golden_result = 32'h0000_0000;
                endcase
            end
        end
    endfunction

    function [8*8-1:0] op_name;
        input [2:0] f_md_op;
        begin
            case (f_md_op)
                `MD_DIV:  op_name = "DIV";
                `MD_DIVU: op_name = "DIVU";
                `MD_REM:  op_name = "REM";
                `MD_REMU: op_name = "REMU";
                default:  op_name = "BAD";
            endcase
        end
    endfunction

    task reset_dut;
        integer k;
        begin
            resetn = 1'b0;
            start  = 1'b0;
            md_op  = `MD_DIV;
            op_a   = 32'h0000_0000;
            op_b   = 32'h0000_0001;
            for (k = 0; k < 4; k = k + 1) begin
                state_hits[k] = 0;
            end
            for (k = 0; k < 16; k = k + 1) begin
                arc_hits[k] = 0;
            end
            repeat (4) @(posedge clk);
            resetn = 1'b1;
            @(posedge clk);
        end
    endtask

    task pulse_reset_no_clear;
        begin
            @(negedge clk);
            start  = 1'b0;
            resetn = 1'b0;
            repeat (2) @(posedge clk);
            @(negedge clk);
            resetn = 1'b1;
            @(posedge clk);
        end
    endtask

    task idle_soak;
        input integer cycles;
        begin
            repeat (cycles) begin
                @(negedge clk);
                start = 1'b0;
                md_op = `MD_DIVU;
                op_a  = 32'h5555_aaaa;
                op_b  = 32'haaaa_5555;
            end
        end
    endtask

    task launch_vector;
        input [2:0]  t_md_op;
        input [31:0] t_op_a;
        input [31:0] t_op_b;
        begin
            if (busy || done) begin
                errors = errors + 1;
                $error("TB launch while not idle: busy=%b done=%b state=%0d", busy, done, dut.state);
            end
            @(negedge clk);
            md_op = t_md_op;
            op_a  = t_op_a;
            op_b  = t_op_b;
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
        end
    endtask

    task wait_and_check;
        input [2:0]  t_md_op;
        input [31:0] t_op_a;
        input [31:0] t_op_b;
        input [8*48-1:0] tag;
        reg [31:0] exp_result;
        integer wait_cycles;
        begin
            wait_cycles = 0;
            while (done !== 1'b1 && wait_cycles < 80) begin
                @(posedge clk);
                #1;
                wait_cycles = wait_cycles + 1;
            end

            exp_result = golden_result(t_md_op, t_op_a, t_op_b);
            vectors = vectors + 1;
            if (done !== 1'b1 || result !== exp_result) begin
                errors = errors + 1;
                $error("FAIL[%0d] %0s %0s a=%h b=%h result=%h exp=%h done=%b wait=%0d",
                       vectors, tag, op_name(t_md_op), t_op_a, t_op_b, result,
                       exp_result, done, wait_cycles);
            end

            @(posedge clk);
            #1;
            if (done !== 1'b0 || dut.state !== ST_IDLE) begin
                errors = errors + 1;
                $error("FAIL[%0d] post-DONE cleanup done=%b state=%0d", vectors, done, dut.state);
            end
        end
    endtask

    task run_vector;
        input [2:0]  t_md_op;
        input [31:0] t_op_a;
        input [31:0] t_op_b;
        input [8*48-1:0] tag;
        begin
            launch_vector(t_md_op, t_op_a, t_op_b);
            wait_and_check(t_md_op, t_op_a, t_op_b, tag);
        end
    endtask

    task run_busy_reject;
        begin
            @(negedge clk);
            md_op = `MD_DIVU;
            op_a  = 32'hffff_ffff;
            op_b  = 32'h0001_0001;
            start = 1'b1;
            @(negedge clk);
            md_op = `MD_DIV;
            op_a  = 32'h0000_0007;
            op_b  = 32'h0000_0003;
            start = 1'b1;
            repeat (5) @(negedge clk);
            start = 1'b0;
            wait_and_check(`MD_DIVU, 32'hffff_ffff, 32'h0001_0001, "BUSY_START_IGNORED");
        end
    endtask

    task run_done_start_ignored;
        begin
            launch_vector(`MD_DIVU, 32'h0000_0009, 32'h0000_0003);
            while (dut.state !== ST_DONE) begin
                @(posedge clk);
                #1;
            end
            @(negedge clk);
            md_op = `MD_DIVU;
            op_a  = 32'h0000_0010;
            op_b  = 32'h0000_0002;
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
            wait_and_check(`MD_DIVU, 32'h0000_0009, 32'h0000_0003, "DONE_START_IGNORED");
        end
    endtask

    task run_reset_from_work;
        begin
            launch_vector(`MD_DIVU, 32'hffff_ffff, 32'h0000_0003);
            while (dut.state !== ST_WORK) begin
                @(posedge clk);
                #1;
            end
            pulse_reset_no_clear();
            if (dut.state !== ST_IDLE || done !== 1'b0) begin
                errors = errors + 1;
                $error("FAIL reset-from-WORK state=%0d done=%b", dut.state, done);
            end
        end
    endtask

    task run_reset_from_fixup;
        begin
            launch_vector(`MD_DIVU, 32'hffff_ffff, 32'h0000_0003);
            while (dut.state !== ST_FIXUP) begin
                @(posedge clk);
                #1;
            end
            pulse_reset_no_clear();
            if (dut.state !== ST_IDLE || done !== 1'b0) begin
                errors = errors + 1;
                $error("FAIL reset-from-FIXUP state=%0d done=%b", dut.state, done);
            end
        end
    endtask

    task print_fsm_report;
        begin
            $display("FSM_STATE IDLE  covered=%0d", state_hits[ST_IDLE]);
            $display("FSM_STATE WORK  covered=%0d", state_hits[ST_WORK]);
            $display("FSM_STATE FIXUP covered=%0d", state_hits[ST_FIXUP]);
            $display("FSM_STATE DONE  covered=%0d", state_hits[ST_DONE]);
            $display("FSM_ARC A0  IDLE->WORK normal_or_zero_div=%0d", arc_hits[0]);
            $display("FSM_ARC A1  IDLE->ZERODIV structural_no_such_state=0");
            $display("FSM_ARC A2  IDLE->IDLE idle_soak=%0d", arc_hits[2]);
            $display("FSM_ARC A3  WORK->WORK loop=%0d", arc_hits[3]);
            $display("FSM_ARC A4  WORK->FIXUP loop_complete=%0d", arc_hits[4]);
            $display("FSM_ARC A5  divisor_one_no_earlyout_work_to_fixup=%0d", arc_hits[5]);
            $display("FSM_ARC A6  dividend_zero_no_earlyout_work_to_fixup=%0d", arc_hits[6]);
            $display("FSM_ARC A7  dividend_le_divisor_no_earlyout_work_to_fixup=%0d", arc_hits[7]);
            $display("FSM_ARC A8  signed_overflow_no_earlyout_work_to_fixup=%0d", arc_hits[8]);
            $display("FSM_ARC A9  DONE->IDLE auto_clear=%0d", arc_hits[9]);
            $display("FSM_ARC A10 DONE->WORK direct structural_start_ignored_in_DONE=0");
            $display("FSM_ARC A11 FIXUP->DONE zero_div_and_all_results=%0d", arc_hits[11]);
            $display("FSM_ARC A12 ZERODIV->IDLE structural_no_such_state maps_DONE_IDLE=%0d", arc_hits[12]);
            $display("FSM_ARC A13 IDLE->WORK signed_unsigned_mux=%0d", arc_hits[13]);
            $display("FSM_ARC A14 WORK->WORK signed_restore_internal=%0d", arc_hits[14]);
            $display("FSM_ARC A15 WORK->WORK unsigned_borrow_internal=%0d", arc_hits[15]);
        end
    endtask

    initial begin
        vectors    = 0;
        errors     = 0;
        rand_state = 32'h2468_ace1;

        op_table[0] = `MD_DIV;
        op_table[1] = `MD_DIVU;
        op_table[2] = `MD_REM;
        op_table[3] = `MD_REMU;

        magnitude_table[0]  = 32'h0000_0000;
        magnitude_table[1]  = 32'h0000_0001;
        magnitude_table[2]  = 32'h0000_0002;
        magnitude_table[3]  = 32'h0000_0003;
        magnitude_table[4]  = 32'h0000_0007;
        magnitude_table[5]  = 32'h0000_ffff;
        magnitude_table[6]  = 32'h0001_0001;
        magnitude_table[7]  = 32'h4000_0000;
        magnitude_table[8]  = 32'h7fff_ffff;
        magnitude_table[9]  = 32'h8000_0000;
        magnitude_table[10] = 32'hffff_ffff;

        reset_dut();
        idle_soak(8);

        run_reset_from_work();
        run_reset_from_fixup();
        run_busy_reject();
        run_done_start_ignored();

        run_vector(`MD_DIV,  32'h0000_1234, 32'h0000_0000, "Z1_DIV_BY_ZERO");
        run_vector(`MD_DIVU, 32'h0000_1234, 32'h0000_0000, "Z2_DIVU_BY_ZERO");
        run_vector(`MD_REM,  32'h8000_0000, 32'h0000_0000, "Z3_REM_BY_ZERO");
        run_vector(`MD_REMU, 32'h0000_0001, 32'h0000_0000, "Z4_REMU_BY_ZERO");

        run_vector(`MD_DIV, 32'h8000_0000, 32'hffff_ffff, "O1_SIGNED_OVERFLOW_DIV");
        run_vector(`MD_REM, 32'h8000_0000, 32'hffff_ffff, "O2_SIGNED_OVERFLOW_REM");

        run_vector(`MD_DIV, 32'd100,        32'd7,          "S_PP_DIV");
        run_vector(`MD_DIV, 32'd100,        -32'sd7,        "S_PN_DIV");
        run_vector(`MD_DIV, -32'sd100,      32'd7,          "S_NP_DIV");
        run_vector(`MD_DIV, -32'sd100,      -32'sd7,        "S_NN_DIV");
        run_vector(`MD_REM, 32'd100,        32'd7,          "R_PP_REM");
        run_vector(`MD_REM, 32'd100,        -32'sd7,        "R_PN_REM");
        run_vector(`MD_REM, -32'sd100,      32'd7,          "R_NP_REM");
        run_vector(`MD_REM, -32'sd100,      -32'sd7,        "R_NN_REM");

        run_vector(`MD_DIVU, 32'hffff_ffff, 32'h0000_0001, "Q1_ALL_ONES_QUOT");
        run_vector(`MD_DIVU, 32'h8000_0000, 32'h0000_0001, "Q2_MSB_QUOT");
        run_vector(`MD_DIVU, 32'h0000_0001, 32'h8000_0000, "Q3_ZERO_QUOT");
        run_vector(`MD_DIVU, 32'h7fff_ffff, 32'h4000_0000, "Q4_LSB_QUOT");
        run_vector(`MD_DIVU, 32'haaaa_aaaa, 32'h0001_0001, "Q5_PATTERN_QUOT");
        run_vector(`MD_DIV,  32'h7fff_ffff, 32'h0000_0003, "Q6_LARGE_SIGNED");
        run_vector(`MD_DIVU, 32'hffff_ffff, 32'hffff_fffe, "Q7_NEAR_EQUAL");

        run_vector(`MD_DIVU, 32'h0000_0003, 32'h0000_0009, "E0_DIVISOR_GT");
        run_vector(`MD_DIV,  -32'sd3,       32'h0000_0009, "E1_SIGNED_DIVISOR_GT");
        run_vector(`MD_DIVU, 32'h0000_000a, 32'h0000_000a, "E2_EQUAL");
        run_vector(`MD_DIV,  32'hffff_ffff, 32'hffff_ffff, "E3_EQUAL_NEG");
        run_vector(`MD_DIVU, 32'h0000_0001, 32'h0000_0002, "E4_MINIMAL");
        run_vector(`MD_DIVU, 32'h0000_0000, 32'h0000_0005, "E5_ZERO_DIVIDEND");
        run_vector(`MD_DIVU, 32'hc000_0000, 32'h4000_0000, "A15_UNSIGNED_BORROW");
        run_vector(`MD_DIV,  -32'sd7,       32'h0000_0003, "A14_SIGNED_RESTORE");
        run_vector(`MD_REM,  -32'sd7,       32'h0000_0003, "A14_SIGNED_RESTORE_REM");
        run_vector(`MD_DIVU, 32'hffff_ffff, 32'h0001_0001, "H5_FULL_32_ITER");

        for (op_i = 0; op_i < 4; op_i = op_i + 1) begin
            for (sign_i = 0; sign_i < 4; sign_i = sign_i + 1) begin
                for (mag_a_i = 0; mag_a_i < 11; mag_a_i = mag_a_i + 1) begin
                    for (mag_b_i = 0; mag_b_i < 11; mag_b_i = mag_b_i + 1) begin
                        run_vector(op_table[op_i],
                                   signed_value(magnitude_table[mag_a_i], sign_i[1]),
                                   signed_value(magnitude_table[mag_b_i], sign_i[0]),
                                   "OP_SIGN_MAG_MATRIX");
                    end
                end
            end
        end

        for (op_i = 0; op_i < 4; op_i = op_i + 1) begin
            for (i = 0; i < 32; i = i + 1) begin
                run_vector(op_table[op_i], (32'h0000_0001 << i), 32'hffff_ffff, "WALK_A_ONES_B");
                run_vector(op_table[op_i], 32'hffff_ffff, (32'h0000_0001 << i), "ONES_A_WALK_B");
                run_vector(op_table[op_i], (32'h8000_0000 >> i), (32'h0000_0001 << i), "CROSS_WALK");
                run_vector(op_table[op_i], ~(32'h0000_0001 << i), (32'h0000_0001 << i), "INV_WALK_A");
                run_vector(op_table[op_i], 32'hffff_ffff ^ (32'h0000_0001 << i),
                           32'h8000_0001 ^ (32'h0000_0001 << (31 - i)), "DIAGONAL_WALK");
            end
        end

        for (op_i = 0; op_i < 4; op_i = op_i + 1) begin
            for (i = 0; i < 160; i = i + 1) begin
                rand_state = (rand_state * 32'd1664525) + 32'd1013904223;
                op_a = rand_state;
                rand_state = (rand_state * 32'd1664525) + 32'd1013904223;
                op_b = rand_state;
                run_vector(op_table[op_i], op_a, op_b, "LCG_RANDOM");
            end
        end

        print_fsm_report();
        @(posedge clk);
        if (errors == 0) begin
            $display("PASS: div unit %0d/%0d vectors", vectors, vectors);
            $finish;
        end else begin
            $display("FAIL: div unit %0d/%0d vectors failed", errors, vectors);
            $fatal(1);
        end
    end
endmodule
