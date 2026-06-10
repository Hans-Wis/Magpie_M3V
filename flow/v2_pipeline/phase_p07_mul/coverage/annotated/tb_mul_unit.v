//      // verilator_coverage annotation
        `timescale 1ns/1ps
        `include "def.vh"
        
        module tb_mul_unit;
 006972     reg         clk;
%000002     reg         resetn;
 002321     reg         start;
%000004     reg  [2:0]  md_op;
 000532     reg  [31:0] op_a;
 000668     reg  [31:0] op_b;
 000450     wire [31:0] result;
 002321     wire        done;
        
            integer vectors;
            integer errors;
            integer op_i;
            integer sign_i;
            integer mag_a_i;
            integer mag_b_i;
            integer i;
            integer j;
            integer rand_state;
        
%000001     reg [2:0] op_table [0:3];
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
        
%000000     initial begin
%000000         clk = 1'b0;
~013943         forever #5 clk = ~clk;
            end
        
 002592     function [31:0] signed_value;
                input [31:0] magnitude;
                input        negative;
 002592         begin
 002592             signed_value = negative ? (~magnitude + 32'd1) : magnitude;
                end
            endfunction
        
 002322     function [63:0] golden_product;
                input [2:0]  f_md_op;
                input [31:0] f_op_a;
                input [31:0] f_op_b;
 002322         reg signed [63:0] a_s64;
 002322         reg signed [63:0] b_s64;
 002322         reg signed [63:0] p_s64;
 002322         reg        [63:0] a_u64;
 002322         reg        [63:0] b_u64;
 002322         reg        [63:0] p_u64;
 002322         begin
 002322             a_s64 = {{32{f_op_a[31]}}, f_op_a};
 002322             b_s64 = {{32{f_op_b[31]}}, f_op_b};
 002322             a_u64 = {32'b0, f_op_a};
 002322             b_u64 = {32'b0, f_op_b};
        
 002322             case (f_md_op)
                        `MD_MUL,
 001162                 `MD_MULH: begin
 001162                     p_s64 = a_s64 * b_s64;
 001162                     golden_product = p_s64[63:0];
                        end
 000580                 `MD_MULHSU: begin
 001176                     p_u64 = (f_op_a[31]) ? ((~({32'b0, (~f_op_a + 32'd1)} * b_u64)) + 64'd1) :
 000285                                            (a_u64 * b_u64);
 000580                     golden_product = p_u64;
                        end
 000580                 `MD_MULHU: begin
 000580                     golden_product = a_u64 * b_u64;
                        end
%000000                 default: begin
%000000                     golden_product = 64'h0000_0000_0000_0000;
                        end
                    endcase
                end
            endfunction
        
 002322     function [31:0] golden_result;
                input [2:0]  f_md_op;
                input [31:0] f_op_a;
                input [31:0] f_op_b;
 002322         reg [63:0] product;
 002322         begin
 002322             product = golden_product(f_md_op, f_op_a, f_op_b);
 002322             golden_result = (f_md_op == `MD_MUL) ? product[31:0] : product[63:32];
                end
            endfunction
        
%000002     task reset_dut;
%000002         begin
%000002             resetn = 1'b0;
%000002             start  = 1'b0;
%000002             md_op  = `MD_MUL;
%000002             op_a   = 32'h0000_0000;
%000002             op_b   = 32'h0000_0000;
%000006             repeat (3) @(posedge clk);
%000002             resetn = 1'b1;
%000002             @(posedge clk);
                end
            endtask
        
 002320     task launch_vector;
                input [2:0]  t_md_op;
                input [31:0] t_op_a;
                input [31:0] t_op_b;
 002320         begin
 002320             @(negedge clk);
 002320             md_op = t_md_op;
 002320             op_a  = t_op_a;
 002320             op_b  = t_op_b;
 002320             start = 1'b1;
 002320             @(negedge clk);
 002320             start = 1'b0;
                end
            endtask
        
 002321     task wait_and_check;
                input [2:0]  t_md_op;
                input [31:0] t_op_a;
                input [31:0] t_op_b;
                input [8*40-1:0] tag;
 002321         reg [31:0] exp_result;
 002321         integer wait_cycles;
 002321         begin
 002321             wait_cycles = 0;
~004641             while (done !== 1'b1 && wait_cycles < 8) begin
 004641                 @(posedge clk);
 004641                 #1;
 004641                 wait_cycles = wait_cycles + 1;
                    end
 002321             exp_result = golden_result(t_md_op, t_op_a, t_op_b);
 002321             vectors = vectors + 1;
~002321             if (done !== 1'b1 || result !== exp_result) begin
                        errors = errors + 1;
                        $error("FAIL[%0d] %0s op=%b a=%h b=%h result=%h exp=%h done=%b wait=%0d product=%h",
                               vectors, tag, t_md_op, t_op_a, t_op_b, result, exp_result,
                               done, wait_cycles, golden_product(t_md_op, t_op_a, t_op_b));
                    end
                end
            endtask
        
 002320     task run_vector;
                input [2:0]  t_md_op;
                input [31:0] t_op_a;
                input [31:0] t_op_b;
                input [8*40-1:0] tag;
 002320         begin
 002320             launch_vector(t_md_op, t_op_a, t_op_b);
 002320             wait_and_check(t_md_op, t_op_a, t_op_b, tag);
                end
            endtask
        
%000001     task run_ignored_busy_start;
%000001         reg [31:0] exp_result;
%000001         begin
%000001             @(negedge clk);
%000001             md_op = `MD_MULH;
%000001             op_a  = 32'h8000_0000;
%000001             op_b  = 32'hffff_ffff;
%000001             start = 1'b1;
%000001             @(negedge clk);
%000001             md_op = `MD_MULHU;
%000001             op_a  = 32'h0000_0003;
%000001             op_b  = 32'h0000_0007;
%000001             start = 1'b1;
%000001             @(negedge clk);
%000001             start = 1'b0;
        
%000001             wait_and_check(`MD_MULH, 32'h8000_0000, 32'hffff_ffff, "BUSY_START_IGNORED");
%000001             exp_result = golden_result(`MD_MULH, 32'h8000_0000, 32'hffff_ffff);
%000001             if (result !== exp_result) begin
                        errors = errors + 1;
                        $error("FAIL busy-start overwrite check result=%h exp=%h", result, exp_result);
                    end
                end
            endtask
        
%000001     initial begin
%000001         vectors    = 0;
%000001         errors     = 0;
%000001         rand_state = 32'h1357_9bdf;
        
%000001         op_table[0] = `MD_MUL;
%000001         op_table[1] = `MD_MULH;
%000001         op_table[2] = `MD_MULHU;
%000001         op_table[3] = `MD_MULHSU;
        
%000001         magnitude_table[0] = 32'h0000_0000;
%000001         magnitude_table[1] = 32'h0000_0001;
%000001         magnitude_table[2] = 32'h0000_0002;
%000001         magnitude_table[3] = 32'h0000_0003;
%000001         magnitude_table[4] = 32'h0000_ffff;
%000001         magnitude_table[5] = 32'h7fff_ffff;
%000001         magnitude_table[6] = 32'h8000_0000;
%000001         magnitude_table[7] = 32'hffff_ffff;
%000001         magnitude_table[8] = 32'h5555_aaaa;
        
%000001         reset_dut();
        
%000001         run_ignored_busy_start();
        
%000001         reset_dut();
        
%000004         for (op_i = 0; op_i < 4; op_i = op_i + 1) begin
~000016             for (sign_i = 0; sign_i < 4; sign_i = sign_i + 1) begin
 000144                 for (mag_a_i = 0; mag_a_i < 9; mag_a_i = mag_a_i + 1) begin
 001296                     for (mag_b_i = 0; mag_b_i < 9; mag_b_i = mag_b_i + 1) begin
 001296                         run_vector(op_table[op_i],
 001296                                    signed_value(magnitude_table[mag_a_i], sign_i[1]),
 001296                                    signed_value(magnitude_table[mag_b_i], sign_i[0]),
 001296                                    "OP_SIGN_MAG_MATRIX");
                            end
                        end
                    end
                end
        
%000004         for (op_i = 0; op_i < 4; op_i = op_i + 1) begin
~000128             for (i = 0; i < 32; i = i + 1) begin
 000128                 run_vector(op_table[op_i], (32'h0000_0001 << i), 32'hffff_ffff, "WALK_A_ONES_B");
 000128                 run_vector(op_table[op_i], 32'hffff_ffff, (32'h0000_0001 << i), "ONES_A_WALK_B");
 000128                 run_vector(op_table[op_i], (32'h8000_0000 >> i), (32'h0000_0001 << i), "CROSS_WALK");
 000128                 run_vector(op_table[op_i], ~(32'h0000_0001 << i), (32'h0000_0001 << i), "INV_WALK_A");
                    end
                end
        
%000004         for (op_i = 0; op_i < 4; op_i = op_i + 1) begin
~000512             for (i = 0; i < 128; i = i + 1) begin
 000512                 rand_state = (rand_state * 32'd1664525) + 32'd1013904223;
 000512                 j = rand_state;
 000512                 rand_state = (rand_state * 32'd1664525) + 32'd1013904223;
 000512                 run_vector(op_table[op_i], j[31:0], rand_state[31:0], "LCG_RANDOM");
                    end
                end
        
%000001         @(posedge clk);
%000001         if (errors == 0) begin
%000001             $display("PASS: mul unit %0d/%0d vectors", vectors, vectors);
%000001             $finish;
                end else begin
                    $display("FAIL: mul unit %0d/%0d vectors failed", errors, vectors);
                    $fatal(1);
                end
            end
        endmodule
        
