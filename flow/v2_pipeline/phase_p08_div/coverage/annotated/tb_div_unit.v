//      // verilator_coverage annotation
        `timescale 1ns/1ps
        `include "def.vh"
        
        module tb_div_unit;
 117019     reg         clk;
%000003     reg         resetn;
 003252     reg         start;
~000015     reg  [2:0]  md_op;
 000609     reg  [31:0] op_a;
 000897     reg  [31:0] op_b;
 000714     wire [31:0] result;
 003249     wire        done;
        
 003251     wire        busy = (dut.state != 2'd0) && !done;
        
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
 006500     reg [1:0] prev_state;
        
%000001     reg [2:0] op_table [0:3];
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
        
%000000     initial begin
%000000         clk = 1'b0;
~234037         forever #5 clk = ~clk;
            end
        
 117019     always @(posedge clk) begin
~117012         if (!resetn) begin
%000007             prev_state <= ST_IDLE;
 117012         end else begin
 117012             state_hits[dut.state] = state_hits[dut.state] + 1;
        
 117012             case ({prev_state, dut.state})
 003264                 {ST_IDLE,  ST_IDLE}:  arc_hits[2]  = arc_hits[2]  + 1;
 003251                 {ST_IDLE,  ST_WORK}:  begin
 003251                     arc_hits[0]  = arc_hits[0]  + 1;
 003251                     arc_hits[13] = arc_hits[13] + 1;
                        end
 100750                 {ST_WORK,  ST_WORK}:  begin
 100750                     arc_hits[3]  = arc_hits[3]  + 1;
 100750                     arc_hits[14] = arc_hits[14] + 1;
 100750                     arc_hits[15] = arc_hits[15] + 1;
                        end
 003249                 {ST_WORK,  ST_FIXUP}: arc_hits[4]  = arc_hits[4]  + 1;
 003249                 {ST_FIXUP, ST_DONE}:  arc_hits[11] = arc_hits[11] + 1;
 003249                 {ST_DONE,  ST_IDLE}:  begin
 003249                     arc_hits[9]  = arc_hits[9]  + 1;
 003249                     arc_hits[12] = arc_hits[12] + 1;
                        end
%000000                 default: ;
                    endcase
        
 113763             if (prev_state == ST_WORK && dut.state == ST_FIXUP) begin
 002900                 if (dut.divisor == 32'd1)
 000349                     arc_hits[5] = arc_hits[5] + 1;
 003072                 if (dut.orig_a == 32'd0)
 000177                     arc_hits[6] = arc_hits[6] + 1;
~003249                 if (dut.dividend <= dut.divisor)
 003249                     arc_hits[7] = arc_hits[7] + 1;
 003237                 if (dut.overflow)
 000012                     arc_hits[8] = arc_hits[8] + 1;
                    end
        
 117012             prev_state <= dut.state;
                end
            end
        
 003872     function [31:0] signed_value;
                input [31:0] magnitude;
                input        negative;
 003872         begin
 003872             signed_value = negative ? (~magnitude + 32'd1) : magnitude;
                end
            endfunction
        
 003249     function [31:0] golden_result;
                input [2:0]  f_md_op;
                input [31:0] f_op_a;
                input [31:0] f_op_b;
 003249         reg signed [31:0] a_s;
 003249         reg signed [31:0] b_s;
 003249         begin
 003249             a_s = f_op_a;
 003249             b_s = f_op_b;
        
 000180             if (f_op_b == 32'h0000_0000) begin
 000180                 golden_result = ((f_md_op == `MD_REM) || (f_md_op == `MD_REMU)) ?
 000090                                 f_op_a : 32'hffff_ffff;
 003057             end else if (((f_md_op == `MD_DIV) || (f_md_op == `MD_REM)) &&
~002898                          (f_op_a == 32'h8000_0000) && (f_op_b == 32'hffff_ffff)) begin
~000012                 golden_result = (f_md_op == `MD_REM) ? 32'h0000_0000 : 32'h8000_0000;
 003057             end else begin
 003057                 case (f_md_op)
 000763                     `MD_DIV:  golden_result = a_s / b_s;
 000774                     `MD_DIVU: golden_result = f_op_a / f_op_b;
 000760                     `MD_REM:  golden_result = a_s % b_s;
 000760                     `MD_REMU: golden_result = f_op_a % f_op_b;
%000000                     default:  golden_result = 32'h0000_0000;
                        endcase
                    end
                end
            endfunction
        
%000000     function [8*8-1:0] op_name;
                input [2:0] f_md_op;
%000000         begin
%000000             case (f_md_op)
%000000                 `MD_DIV:  op_name = "DIV";
%000000                 `MD_DIVU: op_name = "DIVU";
%000000                 `MD_REM:  op_name = "REM";
%000000                 `MD_REMU: op_name = "REMU";
%000000                 default:  op_name = "BAD";
                    endcase
                end
            endfunction
        
%000001     task reset_dut;
%000001         integer k;
%000001         begin
%000001             resetn = 1'b0;
%000001             start  = 1'b0;
%000001             md_op  = `MD_DIV;
%000001             op_a   = 32'h0000_0000;
%000001             op_b   = 32'h0000_0001;
%000004             for (k = 0; k < 4; k = k + 1) begin
%000004                 state_hits[k] = 0;
                    end
~000016             for (k = 0; k < 16; k = k + 1) begin
 000016                 arc_hits[k] = 0;
                    end
%000004             repeat (4) @(posedge clk);
%000001             resetn = 1'b1;
%000001             @(posedge clk);
                end
            endtask
        
%000002     task pulse_reset_no_clear;
%000002         begin
%000002             @(negedge clk);
%000002             start  = 1'b0;
%000002             resetn = 1'b0;
%000004             repeat (2) @(posedge clk);
%000002             @(negedge clk);
%000002             resetn = 1'b1;
%000002             @(posedge clk);
                end
            endtask
        
%000001     task idle_soak;
                input integer cycles;
%000001         begin
%000008             repeat (cycles) begin
%000008                 @(negedge clk);
%000008                 start = 1'b0;
%000008                 md_op = `MD_DIVU;
%000008                 op_a  = 32'h5555_aaaa;
%000008                 op_b  = 32'haaaa_5555;
                    end
                end
            endtask
        
 003250     task launch_vector;
                input [2:0]  t_md_op;
                input [31:0] t_op_a;
                input [31:0] t_op_b;
 003250         begin
~003250             if (busy || done) begin
                        errors = errors + 1;
                        $error("TB launch while not idle: busy=%b done=%b state=%0d", busy, done, dut.state);
                    end
 003250             @(negedge clk);
 003250             md_op = t_md_op;
 003250             op_a  = t_op_a;
 003250             op_b  = t_op_b;
 003250             start = 1'b1;
 003250             @(negedge clk);
 003250             start = 1'b0;
                end
            endtask
        
 003249     task wait_and_check;
                input [2:0]  t_md_op;
                input [31:0] t_op_a;
                input [31:0] t_op_b;
                input [8*48-1:0] tag;
 003249         reg [31:0] exp_result;
 003249         integer wait_cycles;
 003249         begin
 003249             wait_cycles = 0;
~110427             while (done !== 1'b1 && wait_cycles < 80) begin
 110427                 @(posedge clk);
 110427                 #1;
 110427                 wait_cycles = wait_cycles + 1;
                    end
        
 003249             exp_result = golden_result(t_md_op, t_op_a, t_op_b);
 003249             vectors = vectors + 1;
~003249             if (done !== 1'b1 || result !== exp_result) begin
                        errors = errors + 1;
                        $error("FAIL[%0d] %0s %0s a=%h b=%h result=%h exp=%h done=%b wait=%0d",
                               vectors, tag, op_name(t_md_op), t_op_a, t_op_b, result,
                               exp_result, done, wait_cycles);
                    end
        
 003249             @(posedge clk);
 003249             #1;
~003249             if (done !== 1'b0 || dut.state !== ST_IDLE) begin
                        errors = errors + 1;
                        $error("FAIL[%0d] post-DONE cleanup done=%b state=%0d", vectors, done, dut.state);
                    end
                end
            endtask
        
 003247     task run_vector;
                input [2:0]  t_md_op;
                input [31:0] t_op_a;
                input [31:0] t_op_b;
                input [8*48-1:0] tag;
 003247         begin
 003247             launch_vector(t_md_op, t_op_a, t_op_b);
 003247             wait_and_check(t_md_op, t_op_a, t_op_b, tag);
                end
            endtask
        
%000001     task run_busy_reject;
%000001         begin
%000001             @(negedge clk);
%000001             md_op = `MD_DIVU;
%000001             op_a  = 32'hffff_ffff;
%000001             op_b  = 32'h0001_0001;
%000001             start = 1'b1;
%000001             @(negedge clk);
%000001             md_op = `MD_DIV;
%000001             op_a  = 32'h0000_0007;
%000001             op_b  = 32'h0000_0003;
%000001             start = 1'b1;
%000005             repeat (5) @(negedge clk);
%000001             start = 1'b0;
%000001             wait_and_check(`MD_DIVU, 32'hffff_ffff, 32'h0001_0001, "BUSY_START_IGNORED");
                end
            endtask
        
%000001     task run_done_start_ignored;
%000001         begin
%000001             launch_vector(`MD_DIVU, 32'h0000_0009, 32'h0000_0003);
 000033             while (dut.state !== ST_DONE) begin
 000033                 @(posedge clk);
 000033                 #1;
                    end
%000001             @(negedge clk);
%000001             md_op = `MD_DIVU;
%000001             op_a  = 32'h0000_0010;
%000001             op_b  = 32'h0000_0002;
%000001             start = 1'b1;
%000001             @(negedge clk);
%000001             start = 1'b0;
%000001             wait_and_check(`MD_DIVU, 32'h0000_0009, 32'h0000_0003, "DONE_START_IGNORED");
                end
            endtask
        
%000001     task run_reset_from_work;
%000001         begin
%000001             launch_vector(`MD_DIVU, 32'hffff_ffff, 32'h0000_0003);
%000000             while (dut.state !== ST_WORK) begin
%000000                 @(posedge clk);
%000000                 #1;
                    end
%000001             pulse_reset_no_clear();
%000001             if (dut.state !== ST_IDLE || done !== 1'b0) begin
                        errors = errors + 1;
                        $error("FAIL reset-from-WORK state=%0d done=%b", dut.state, done);
                    end
                end
            endtask
        
%000001     task run_reset_from_fixup;
%000001         begin
%000001             launch_vector(`MD_DIVU, 32'hffff_ffff, 32'h0000_0003);
 000032             while (dut.state !== ST_FIXUP) begin
 000032                 @(posedge clk);
 000032                 #1;
                    end
%000001             pulse_reset_no_clear();
%000001             if (dut.state !== ST_IDLE || done !== 1'b0) begin
                        errors = errors + 1;
                        $error("FAIL reset-from-FIXUP state=%0d done=%b", dut.state, done);
                    end
                end
            endtask
        
%000001     task print_fsm_report;
%000001         begin
%000001             $display("FSM_STATE IDLE  covered=%0d", state_hits[ST_IDLE]);
%000001             $display("FSM_STATE WORK  covered=%0d", state_hits[ST_WORK]);
%000001             $display("FSM_STATE FIXUP covered=%0d", state_hits[ST_FIXUP]);
%000001             $display("FSM_STATE DONE  covered=%0d", state_hits[ST_DONE]);
%000001             $display("FSM_ARC A0  IDLE->WORK normal_or_zero_div=%0d", arc_hits[0]);
%000001             $display("FSM_ARC A1  IDLE->ZERODIV structural_no_such_state=0");
%000001             $display("FSM_ARC A2  IDLE->IDLE idle_soak=%0d", arc_hits[2]);
%000001             $display("FSM_ARC A3  WORK->WORK loop=%0d", arc_hits[3]);
%000001             $display("FSM_ARC A4  WORK->FIXUP loop_complete=%0d", arc_hits[4]);
%000001             $display("FSM_ARC A5  divisor_one_no_earlyout_work_to_fixup=%0d", arc_hits[5]);
%000001             $display("FSM_ARC A6  dividend_zero_no_earlyout_work_to_fixup=%0d", arc_hits[6]);
%000001             $display("FSM_ARC A7  dividend_le_divisor_no_earlyout_work_to_fixup=%0d", arc_hits[7]);
%000001             $display("FSM_ARC A8  signed_overflow_no_earlyout_work_to_fixup=%0d", arc_hits[8]);
%000001             $display("FSM_ARC A9  DONE->IDLE auto_clear=%0d", arc_hits[9]);
%000001             $display("FSM_ARC A10 DONE->WORK direct structural_start_ignored_in_DONE=0");
%000001             $display("FSM_ARC A11 FIXUP->DONE zero_div_and_all_results=%0d", arc_hits[11]);
%000001             $display("FSM_ARC A12 ZERODIV->IDLE structural_no_such_state maps_DONE_IDLE=%0d", arc_hits[12]);
%000001             $display("FSM_ARC A13 IDLE->WORK signed_unsigned_mux=%0d", arc_hits[13]);
%000001             $display("FSM_ARC A14 WORK->WORK signed_restore_internal=%0d", arc_hits[14]);
%000001             $display("FSM_ARC A15 WORK->WORK unsigned_borrow_internal=%0d", arc_hits[15]);
                end
            endtask
        
%000001     initial begin
%000001         vectors    = 0;
%000001         errors     = 0;
%000001         rand_state = 32'h2468_ace1;
        
%000001         op_table[0] = `MD_DIV;
%000001         op_table[1] = `MD_DIVU;
%000001         op_table[2] = `MD_REM;
%000001         op_table[3] = `MD_REMU;
        
%000001         magnitude_table[0]  = 32'h0000_0000;
%000001         magnitude_table[1]  = 32'h0000_0001;
%000001         magnitude_table[2]  = 32'h0000_0002;
%000001         magnitude_table[3]  = 32'h0000_0003;
%000001         magnitude_table[4]  = 32'h0000_0007;
%000001         magnitude_table[5]  = 32'h0000_ffff;
%000001         magnitude_table[6]  = 32'h0001_0001;
%000001         magnitude_table[7]  = 32'h4000_0000;
%000001         magnitude_table[8]  = 32'h7fff_ffff;
%000001         magnitude_table[9]  = 32'h8000_0000;
%000001         magnitude_table[10] = 32'hffff_ffff;
        
%000001         reset_dut();
%000001         idle_soak(8);
        
%000001         run_reset_from_work();
%000001         run_reset_from_fixup();
%000001         run_busy_reject();
%000001         run_done_start_ignored();
        
%000001         run_vector(`MD_DIV,  32'h0000_1234, 32'h0000_0000, "Z1_DIV_BY_ZERO");
%000001         run_vector(`MD_DIVU, 32'h0000_1234, 32'h0000_0000, "Z2_DIVU_BY_ZERO");
%000001         run_vector(`MD_REM,  32'h8000_0000, 32'h0000_0000, "Z3_REM_BY_ZERO");
%000001         run_vector(`MD_REMU, 32'h0000_0001, 32'h0000_0000, "Z4_REMU_BY_ZERO");
        
%000001         run_vector(`MD_DIV, 32'h8000_0000, 32'hffff_ffff, "O1_SIGNED_OVERFLOW_DIV");
%000001         run_vector(`MD_REM, 32'h8000_0000, 32'hffff_ffff, "O2_SIGNED_OVERFLOW_REM");
        
%000001         run_vector(`MD_DIV, 32'd100,        32'd7,          "S_PP_DIV");
%000001         run_vector(`MD_DIV, 32'd100,        -32'sd7,        "S_PN_DIV");
%000001         run_vector(`MD_DIV, -32'sd100,      32'd7,          "S_NP_DIV");
%000001         run_vector(`MD_DIV, -32'sd100,      -32'sd7,        "S_NN_DIV");
%000001         run_vector(`MD_REM, 32'd100,        32'd7,          "R_PP_REM");
%000001         run_vector(`MD_REM, 32'd100,        -32'sd7,        "R_PN_REM");
%000001         run_vector(`MD_REM, -32'sd100,      32'd7,          "R_NP_REM");
%000001         run_vector(`MD_REM, -32'sd100,      -32'sd7,        "R_NN_REM");
        
%000001         run_vector(`MD_DIVU, 32'hffff_ffff, 32'h0000_0001, "Q1_ALL_ONES_QUOT");
%000001         run_vector(`MD_DIVU, 32'h8000_0000, 32'h0000_0001, "Q2_MSB_QUOT");
%000001         run_vector(`MD_DIVU, 32'h0000_0001, 32'h8000_0000, "Q3_ZERO_QUOT");
%000001         run_vector(`MD_DIVU, 32'h7fff_ffff, 32'h4000_0000, "Q4_LSB_QUOT");
%000001         run_vector(`MD_DIVU, 32'haaaa_aaaa, 32'h0001_0001, "Q5_PATTERN_QUOT");
%000001         run_vector(`MD_DIV,  32'h7fff_ffff, 32'h0000_0003, "Q6_LARGE_SIGNED");
%000001         run_vector(`MD_DIVU, 32'hffff_ffff, 32'hffff_fffe, "Q7_NEAR_EQUAL");
        
%000001         run_vector(`MD_DIVU, 32'h0000_0003, 32'h0000_0009, "E0_DIVISOR_GT");
%000001         run_vector(`MD_DIV,  -32'sd3,       32'h0000_0009, "E1_SIGNED_DIVISOR_GT");
%000001         run_vector(`MD_DIVU, 32'h0000_000a, 32'h0000_000a, "E2_EQUAL");
%000001         run_vector(`MD_DIV,  32'hffff_ffff, 32'hffff_ffff, "E3_EQUAL_NEG");
%000001         run_vector(`MD_DIVU, 32'h0000_0001, 32'h0000_0002, "E4_MINIMAL");
%000001         run_vector(`MD_DIVU, 32'h0000_0000, 32'h0000_0005, "E5_ZERO_DIVIDEND");
%000001         run_vector(`MD_DIVU, 32'hc000_0000, 32'h4000_0000, "A15_UNSIGNED_BORROW");
%000001         run_vector(`MD_DIV,  -32'sd7,       32'h0000_0003, "A14_SIGNED_RESTORE");
%000001         run_vector(`MD_REM,  -32'sd7,       32'h0000_0003, "A14_SIGNED_RESTORE_REM");
%000001         run_vector(`MD_DIVU, 32'hffff_ffff, 32'h0001_0001, "H5_FULL_32_ITER");
        
%000004         for (op_i = 0; op_i < 4; op_i = op_i + 1) begin
~000016             for (sign_i = 0; sign_i < 4; sign_i = sign_i + 1) begin
 000176                 for (mag_a_i = 0; mag_a_i < 11; mag_a_i = mag_a_i + 1) begin
 001936                     for (mag_b_i = 0; mag_b_i < 11; mag_b_i = mag_b_i + 1) begin
 001936                         run_vector(op_table[op_i],
 001936                                    signed_value(magnitude_table[mag_a_i], sign_i[1]),
 001936                                    signed_value(magnitude_table[mag_b_i], sign_i[0]),
 001936                                    "OP_SIGN_MAG_MATRIX");
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
 000128                 run_vector(op_table[op_i], 32'hffff_ffff ^ (32'h0000_0001 << i),
 000128                            32'h8000_0001 ^ (32'h0000_0001 << (31 - i)), "DIAGONAL_WALK");
                    end
                end
        
%000004         for (op_i = 0; op_i < 4; op_i = op_i + 1) begin
~000640             for (i = 0; i < 160; i = i + 1) begin
 000640                 rand_state = (rand_state * 32'd1664525) + 32'd1013904223;
 000640                 op_a = rand_state;
 000640                 rand_state = (rand_state * 32'd1664525) + 32'd1013904223;
 000640                 op_b = rand_state;
 000640                 run_vector(op_table[op_i], op_a, op_b, "LCG_RANDOM");
                    end
                end
        
%000001         print_fsm_report();
%000001         @(posedge clk);
%000001         if (errors == 0) begin
%000001             $display("PASS: div unit %0d/%0d vectors", vectors, vectors);
%000001             $finish;
                end else begin
                    $display("FAIL: div unit %0d/%0d vectors failed", errors, vectors);
                    $fatal(1);
                end
            end
        endmodule
        
