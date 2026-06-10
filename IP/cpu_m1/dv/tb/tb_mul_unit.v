`timescale 1ns/1ps
`include "def.vh"

module tb_mul_unit;
    reg         clk;
    reg         resetn;
    reg         start;
    reg  [2:0]  md_op;
    reg  [31:0] op_a;
    reg  [31:0] op_b;
    wire [31:0] result;
    wire        done;

    integer vectors;
    integer errors;
    integer op_i;
    integer sign_i;
    integer mag_a_i;
    integer mag_b_i;
    integer i;
    integer j;
    integer rand_state;

    reg [2:0] op_table [0:3];
    reg [31:0] magnitude_table [0:8];

    mul dut (
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

    function [31:0] signed_value;
        input [31:0] magnitude;
        input        negative;
        begin
            signed_value = negative ? (~magnitude + 32'd1) : magnitude;
        end
    endfunction

    function [63:0] golden_product;
        input [2:0]  f_md_op;
        input [31:0] f_op_a;
        input [31:0] f_op_b;
        reg signed [63:0] a_s64;
        reg signed [63:0] b_s64;
        reg signed [63:0] p_s64;
        reg        [63:0] a_u64;
        reg        [63:0] b_u64;
        reg        [63:0] p_u64;
        begin
            a_s64 = {{32{f_op_a[31]}}, f_op_a};
            b_s64 = {{32{f_op_b[31]}}, f_op_b};
            a_u64 = {32'b0, f_op_a};
            b_u64 = {32'b0, f_op_b};

            case (f_md_op)
                `MD_MUL,
                `MD_MULH: begin
                    p_s64 = a_s64 * b_s64;
                    golden_product = p_s64[63:0];
                end
                `MD_MULHSU: begin
                    p_u64 = (f_op_a[31]) ? ((~({32'b0, (~f_op_a + 32'd1)} * b_u64)) + 64'd1) :
                                           (a_u64 * b_u64);
                    golden_product = p_u64;
                end
                `MD_MULHU: begin
                    golden_product = a_u64 * b_u64;
                end
                default: begin
                    golden_product = 64'h0000_0000_0000_0000;
                end
            endcase
        end
    endfunction

    function [31:0] golden_result;
        input [2:0]  f_md_op;
        input [31:0] f_op_a;
        input [31:0] f_op_b;
        reg [63:0] product;
        begin
            product = golden_product(f_md_op, f_op_a, f_op_b);
            golden_result = (f_md_op == `MD_MUL) ? product[31:0] : product[63:32];
        end
    endfunction

    task reset_dut;
        begin
            resetn = 1'b0;
            start  = 1'b0;
            md_op  = `MD_MUL;
            op_a   = 32'h0000_0000;
            op_b   = 32'h0000_0000;
            repeat (3) @(posedge clk);
            resetn = 1'b1;
            @(posedge clk);
        end
    endtask

    task launch_vector;
        input [2:0]  t_md_op;
        input [31:0] t_op_a;
        input [31:0] t_op_b;
        begin
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
        input [8*40-1:0] tag;
        reg [31:0] exp_result;
        integer wait_cycles;
        begin
            wait_cycles = 0;
            while (done !== 1'b1 && wait_cycles < 8) begin
                @(posedge clk);
                #1;
                wait_cycles = wait_cycles + 1;
            end
            exp_result = golden_result(t_md_op, t_op_a, t_op_b);
            vectors = vectors + 1;
            if (done !== 1'b1 || result !== exp_result) begin
                errors = errors + 1;
                $error("FAIL[%0d] %0s op=%b a=%h b=%h result=%h exp=%h done=%b wait=%0d product=%h",
                       vectors, tag, t_md_op, t_op_a, t_op_b, result, exp_result,
                       done, wait_cycles, golden_product(t_md_op, t_op_a, t_op_b));
            end
        end
    endtask

    task run_vector;
        input [2:0]  t_md_op;
        input [31:0] t_op_a;
        input [31:0] t_op_b;
        input [8*40-1:0] tag;
        begin
            launch_vector(t_md_op, t_op_a, t_op_b);
            wait_and_check(t_md_op, t_op_a, t_op_b, tag);
        end
    endtask

    task run_ignored_busy_start;
        reg [31:0] exp_result;
        begin
            @(negedge clk);
            md_op = `MD_MULH;
            op_a  = 32'h8000_0000;
            op_b  = 32'hffff_ffff;
            start = 1'b1;
            @(negedge clk);
            md_op = `MD_MULHU;
            op_a  = 32'h0000_0003;
            op_b  = 32'h0000_0007;
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;

            wait_and_check(`MD_MULH, 32'h8000_0000, 32'hffff_ffff, "BUSY_START_IGNORED");
            exp_result = golden_result(`MD_MULH, 32'h8000_0000, 32'hffff_ffff);
            if (result !== exp_result) begin
                errors = errors + 1;
                $error("FAIL busy-start overwrite check result=%h exp=%h", result, exp_result);
            end
        end
    endtask

    initial begin
        vectors    = 0;
        errors     = 0;
        rand_state = 32'h1357_9bdf;

        op_table[0] = `MD_MUL;
        op_table[1] = `MD_MULH;
        op_table[2] = `MD_MULHU;
        op_table[3] = `MD_MULHSU;

        magnitude_table[0] = 32'h0000_0000;
        magnitude_table[1] = 32'h0000_0001;
        magnitude_table[2] = 32'h0000_0002;
        magnitude_table[3] = 32'h0000_0003;
        magnitude_table[4] = 32'h0000_ffff;
        magnitude_table[5] = 32'h7fff_ffff;
        magnitude_table[6] = 32'h8000_0000;
        magnitude_table[7] = 32'hffff_ffff;
        magnitude_table[8] = 32'h5555_aaaa;

        reset_dut();

        run_ignored_busy_start();

        reset_dut();

        for (op_i = 0; op_i < 4; op_i = op_i + 1) begin
            for (sign_i = 0; sign_i < 4; sign_i = sign_i + 1) begin
                for (mag_a_i = 0; mag_a_i < 9; mag_a_i = mag_a_i + 1) begin
                    for (mag_b_i = 0; mag_b_i < 9; mag_b_i = mag_b_i + 1) begin
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
            end
        end

        for (op_i = 0; op_i < 4; op_i = op_i + 1) begin
            for (i = 0; i < 128; i = i + 1) begin
                rand_state = (rand_state * 32'd1664525) + 32'd1013904223;
                j = rand_state;
                rand_state = (rand_state * 32'd1664525) + 32'd1013904223;
                run_vector(op_table[op_i], j[31:0], rand_state[31:0], "LCG_RANDOM");
            end
        end

        @(posedge clk);
        if (errors == 0) begin
            $display("PASS: mul unit %0d/%0d vectors", vectors, vectors);
            $finish;
        end else begin
            $display("FAIL: mul unit %0d/%0d vectors failed", errors, vectors);
            $fatal(1);
        end
    end
endmodule
