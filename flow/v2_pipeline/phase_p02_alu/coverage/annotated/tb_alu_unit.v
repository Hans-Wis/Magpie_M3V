//      // verilator_coverage annotation
        `timescale 1ns/1ps
        `include "def.vh"
        
        module tb_alu_unit;
 000120     reg  [31:0] op_a;
 000089     reg  [31:0] op_b;
 000135     reg  [ 3:0] alu_op;
 000095     wire [31:0] result;
 000057     wire        cmp_eq;
 000119     wire        cmp_lt_s;
 000076     wire        cmp_lt_u;
        
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
        
 000382     function [31:0] golden_result;
                input [3:0]  f_alu_op;
                input [31:0] f_op_a;
                input [31:0] f_op_b;
 000382         reg   [4:0]  f_shamt;
 000382         begin
 000382             f_shamt = f_op_b[4:0];
 000382             case (f_alu_op)
 000039                 `ALU_ADD    : golden_result = f_op_a + f_op_b;
%000007                 `ALU_SUB    : golden_result = f_op_a - f_op_b;
%000007                 `ALU_AND    : golden_result = f_op_a & f_op_b;
%000007                 `ALU_OR     : golden_result = f_op_a | f_op_b;
 000039                 `ALU_XOR    : golden_result = f_op_a ^ f_op_b;
 000042                 `ALU_SLL    : golden_result = f_op_a << f_shamt;
 000042                 `ALU_SRL    : golden_result = f_op_a >> f_shamt;
 000042                 `ALU_SRA    : golden_result = $signed(f_op_a) >>> f_shamt;
 000039                 `ALU_SLT    : golden_result = {31'b0, ($signed(f_op_a) < $signed(f_op_b))};
 000039                 `ALU_SLTU   : golden_result = {31'b0, (f_op_a < f_op_b)};
 000039                 `ALU_SEQ    : golden_result = {31'b0, (f_op_a == f_op_b)};
 000039                 `ALU_COPY_B : golden_result = f_op_b;
%000001                 default     : golden_result = 32'h0000_0000;
                    endcase
                end
            endfunction
        
 000382     task check_vector;
                input [3:0]  t_alu_op;
                input [31:0] t_op_a;
                input [31:0] t_op_b;
                input [8*24-1:0] tag;
 000382         reg [31:0] exp_result;
 000382         reg        exp_cmp_eq;
 000382         reg        exp_cmp_lt_s;
 000382         reg        exp_cmp_lt_u;
 000382         begin
 000382             alu_op = t_alu_op;
 000382             op_a   = t_op_a;
 000382             op_b   = t_op_b;
 000382             #1;
        
 000382             exp_result   = golden_result(t_alu_op, t_op_a, t_op_b);
 000382             exp_cmp_eq   = (t_op_a == t_op_b);
 000382             exp_cmp_lt_s = ($signed(t_op_a) < $signed(t_op_b));
 000382             exp_cmp_lt_u = (t_op_a < t_op_b);
        
 000382             vectors = vectors + 1;
 000382             if (result !== exp_result ||
                        cmp_eq !== exp_cmp_eq ||
~000382                 cmp_lt_s !== exp_cmp_lt_s ||
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
        
 000012     task run_corner_matrix_for_op;
                input [3:0] t_alu_op;
 000012         begin
 000012             check_vector(t_alu_op, 32'h0000_0000, 32'h0000_0000, "Z");
 000012             check_vector(t_alu_op, 32'hffff_ffff, 32'h0000_0001, "M1");
 000012             check_vector(t_alu_op, 32'h7fff_ffff, 32'h7fff_ffff, "MAX_S");
 000012             check_vector(t_alu_op, 32'h8000_0000, 32'h7fff_ffff, "MIN_S");
 000012             check_vector(t_alu_op, 32'hffff_ffff, 32'h0000_0000, "LT_S");
 000012             check_vector(t_alu_op, 32'h0000_0000, 32'h0000_0001, "LT_U");
 000012             check_vector(t_alu_op, 32'h1234_5678, 32'h1234_5678, "EQ");
                end
            endtask
        
%000003     task run_shift_sweep_for_op;
                input [3:0] t_alu_op;
%000003         begin
%000003             check_vector(t_alu_op, 32'h8000_0001, 32'h0000_0000, "SHAMT_0");
%000003             check_vector(t_alu_op, 32'h8000_0001, 32'h0000_0001, "SHAMT_1");
%000003             check_vector(t_alu_op, 32'h8000_0001, 32'h0000_001f, "SHAMT_31");
                end
            endtask
        
%000001     initial begin
%000001         vectors = 0;
%000001         errors  = 0;
%000001         alu_op  = 4'h0;
%000001         op_a    = 32'h0000_0000;
%000001         op_b    = 32'h0000_0000;
%000001         #1;
        
~000012         for (op = 0; op <= 11; op = op + 1)
 000012             run_corner_matrix_for_op(op[3:0]);
        
%000001         run_shift_sweep_for_op(`ALU_SLL);
%000001         run_shift_sweep_for_op(`ALU_SRL);
%000001         run_shift_sweep_for_op(`ALU_SRA);
        
%000001         check_vector(4'hf, 32'hdead_beef, 32'hcafe_babe, "INV_DEFAULT");
        
~000032         for (i = 0; i < 32; i = i + 1) begin
 000032             check_vector(`ALU_ADD,    (32'h0000_0001 << i), ~(32'h0000_0001 << i), "WALK_ADD_A");
 000032             check_vector(`ALU_XOR,    (32'h0000_0001 << i), (32'h8000_0000 >> i),  "WALK_XOR");
 000032             check_vector(`ALU_SLL,    32'ha5a5_5a5a ^ (32'h0000_0001 << i), i[31:0], "WALK_SLL");
 000032             check_vector(`ALU_SRL,    32'h5a5a_a5a5 ^ (32'h0000_0001 << i), i[31:0], "WALK_SRL");
 000032             check_vector(`ALU_SRA,    32'h8000_0000 ^ (32'h0000_0001 << i), i[31:0], "WALK_SRA");
 000032             check_vector(`ALU_SLT,    32'h8000_0000 ^ (32'h0000_0001 << i), 32'h7fff_ffff, "WALK_SLT");
 000032             check_vector(`ALU_SLTU,   (32'h0000_0001 << i), ~(32'h0000_0001 << i), "WALK_SLTU");
 000032             check_vector(`ALU_SEQ,    (32'h0000_0001 << i), (32'h0000_0001 << i), "WALK_SEQ");
 000032             check_vector(`ALU_COPY_B, ~(32'h0000_0001 << i), (32'h0000_0001 << i), "WALK_COPY_B");
                end
        
%000001         if (errors == 0) begin
%000001             $display("PASS: alu unit %0d/%0d vectors", vectors, vectors);
%000001             $finish;
                end else begin
                    $display("FAIL: alu unit %0d/%0d vectors failed", errors, vectors);
                    $fatal(1);
                end
            end
        endmodule
        
