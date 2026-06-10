`timescale 1ns/1ps
`include "def.vh"

module tb_alu_unit;
    reg  [31:0] op_a;
    reg  [31:0] op_b;
    reg  [ 3:0] alu_op;
    wire [31:0] result;
    wire        cmp_eq;
    wire        cmp_lt_s;
    wire        cmp_lt_u;

    integer vectors;
    integer errors;
    integer op;
    integer i;

    alu dut (
        .op_a(op_a),
        .op_b(op_b),
        .alu_op(alu_op),
        .result(result),
        .cmp_eq(cmp_eq),
        .cmp_lt_s(cmp_lt_s),
        .cmp_lt_u(cmp_lt_u)
    );

    function [31:0] golden_result;
        input [3:0]  f_alu_op;
        input [31:0] f_op_a;
        input [31:0] f_op_b;
        reg   [4:0]  f_shamt;
        begin
            f_shamt = f_op_b[4:0];
            case (f_alu_op)
                `ALU_ADD    : golden_result = f_op_a + f_op_b;
                `ALU_SUB    : golden_result = f_op_a - f_op_b;
                `ALU_AND    : golden_result = f_op_a & f_op_b;
                `ALU_OR     : golden_result = f_op_a | f_op_b;
                `ALU_XOR    : golden_result = f_op_a ^ f_op_b;
                `ALU_SLL    : golden_result = f_op_a << f_shamt;
                `ALU_SRL    : golden_result = f_op_a >> f_shamt;
                `ALU_SRA    : golden_result = $signed(f_op_a) >>> f_shamt;
                `ALU_SLT    : golden_result = {31'b0, ($signed(f_op_a) < $signed(f_op_b))};
                `ALU_SLTU   : golden_result = {31'b0, (f_op_a < f_op_b)};
                `ALU_SEQ    : golden_result = {31'b0, (f_op_a == f_op_b)};
                `ALU_COPY_B : golden_result = f_op_b;
                default     : golden_result = 32'h0000_0000;
            endcase
        end
    endfunction

    task check_vector;
        input [3:0]  t_alu_op;
        input [31:0] t_op_a;
        input [31:0] t_op_b;
        input [8*24-1:0] tag;
        reg [31:0] exp_result;
        reg        exp_cmp_eq;
        reg        exp_cmp_lt_s;
        reg        exp_cmp_lt_u;
        begin
            alu_op = t_alu_op;
            op_a   = t_op_a;
            op_b   = t_op_b;
            #1;

            exp_result   = golden_result(t_alu_op, t_op_a, t_op_b);
            exp_cmp_eq   = (t_op_a == t_op_b);
            exp_cmp_lt_s = ($signed(t_op_a) < $signed(t_op_b));
            exp_cmp_lt_u = (t_op_a < t_op_b);

            vectors = vectors + 1;
            if (result !== exp_result ||
                cmp_eq !== exp_cmp_eq ||
                cmp_lt_s !== exp_cmp_lt_s ||
                cmp_lt_u !== exp_cmp_lt_u) begin
                errors = errors + 1;
                $error("FAIL[%0d] %0s op=%h a=%h b=%h result=%h exp=%h cmp=%b%b%b exp_cmp=%b%b%b",
                       vectors, tag, t_alu_op, t_op_a, t_op_b,
                       result, exp_result,
                       cmp_eq, cmp_lt_s, cmp_lt_u,
                       exp_cmp_eq, exp_cmp_lt_s, exp_cmp_lt_u);
            end
        end
    endtask

    task run_corner_matrix_for_op;
        input [3:0] t_alu_op;
        begin
            check_vector(t_alu_op, 32'h0000_0000, 32'h0000_0000, "Z");
            check_vector(t_alu_op, 32'hffff_ffff, 32'h0000_0001, "M1");
            check_vector(t_alu_op, 32'h7fff_ffff, 32'h7fff_ffff, "MAX_S");
            check_vector(t_alu_op, 32'h8000_0000, 32'h7fff_ffff, "MIN_S");
            check_vector(t_alu_op, 32'hffff_ffff, 32'h0000_0000, "LT_S");
            check_vector(t_alu_op, 32'h0000_0000, 32'h0000_0001, "LT_U");
            check_vector(t_alu_op, 32'h1234_5678, 32'h1234_5678, "EQ");
        end
    endtask

    task run_shift_sweep_for_op;
        input [3:0] t_alu_op;
        begin
            check_vector(t_alu_op, 32'h8000_0001, 32'h0000_0000, "SHAMT_0");
            check_vector(t_alu_op, 32'h8000_0001, 32'h0000_0001, "SHAMT_1");
            check_vector(t_alu_op, 32'h8000_0001, 32'h0000_001f, "SHAMT_31");
        end
    endtask

    initial begin
        vectors = 0;
        errors  = 0;
        alu_op  = 4'h0;
        op_a    = 32'h0000_0000;
        op_b    = 32'h0000_0000;
        #1;

        for (op = 0; op <= 11; op = op + 1)
            run_corner_matrix_for_op(op[3:0]);

        run_shift_sweep_for_op(`ALU_SLL);
        run_shift_sweep_for_op(`ALU_SRL);
        run_shift_sweep_for_op(`ALU_SRA);

        check_vector(4'hf, 32'hdead_beef, 32'hcafe_babe, "INV_DEFAULT");

        for (i = 0; i < 32; i = i + 1) begin
            check_vector(`ALU_ADD,    (32'h0000_0001 << i), ~(32'h0000_0001 << i), "WALK_ADD_A");
            check_vector(`ALU_XOR,    (32'h0000_0001 << i), (32'h8000_0000 >> i),  "WALK_XOR");
            check_vector(`ALU_SLL,    32'ha5a5_5a5a ^ (32'h0000_0001 << i), i[31:0], "WALK_SLL");
            check_vector(`ALU_SRL,    32'h5a5a_a5a5 ^ (32'h0000_0001 << i), i[31:0], "WALK_SRL");
            check_vector(`ALU_SRA,    32'h8000_0000 ^ (32'h0000_0001 << i), i[31:0], "WALK_SRA");
            check_vector(`ALU_SLT,    32'h8000_0000 ^ (32'h0000_0001 << i), 32'h7fff_ffff, "WALK_SLT");
            check_vector(`ALU_SLTU,   (32'h0000_0001 << i), ~(32'h0000_0001 << i), "WALK_SLTU");
            check_vector(`ALU_SEQ,    (32'h0000_0001 << i), (32'h0000_0001 << i), "WALK_SEQ");
            check_vector(`ALU_COPY_B, ~(32'h0000_0001 << i), (32'h0000_0001 << i), "WALK_COPY_B");
        end

        if (errors == 0) begin
            $display("PASS: alu unit %0d/%0d vectors", vectors, vectors);
            $finish;
        end else begin
            $display("FAIL: alu unit %0d/%0d vectors failed", errors, vectors);
            $fatal(1);
        end
    end
endmodule
