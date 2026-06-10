//      // verilator_coverage annotation
        `timescale 1ns/1ps
        `include "def.vh"
        
        module tb_rfu_unit;
 002144     reg         clk;
%000001     reg         resetn;
 001120     reg  [ 4:0] rs1_idx;
 003129     reg  [ 4:0] rs2_idx;
 001224     wire [31:0] rs1_data;
 002229     wire [31:0] rs2_data;
%000001     reg         we;
~000017     reg  [ 4:0] rd_idx;
 000156     reg  [31:0] rd_data;
        
            reg [31:0] golden_regs [0:31];
            reg [31:0] patterns [0:67];
        
            integer vectors;
            integer errors;
            integer ridx;
            integer pidx;
            integer bitidx;
            integer i;
~000032     reg [4:0] reg_idx;
~000031     reg [4:0] pair_idx;
        
            rfu dut (
                .clk(clk),
                .resetn(resetn),
                .rs1_idx(rs1_idx),
                .rs1_data(rs1_data),
                .rs2_idx(rs2_idx),
                .rs2_data(rs2_data),
                .we(we),
                .rd_idx(rd_idx),
                .rd_data(rd_data)
            );
        
 004287     always #5 clk = ~clk;
        
 027556     function [31:0] golden_read;
                input [4:0] f_idx;
 027556         begin
 027556             golden_read = (f_idx == 5'd0) ? 32'h0000_0000 : golden_regs[f_idx];
                end
            endfunction
        
 006393     task check_reads;
                input [4:0] t_rs1_idx;
                input [4:0] t_rs2_idx;
                input [8*32-1:0] tag;
 006393         reg [31:0] exp_rs1;
 006393         reg [31:0] exp_rs2;
 006393         begin
 006393             rs1_idx = t_rs1_idx;
 006393             rs2_idx = t_rs2_idx;
 006393             #1;
 006393             exp_rs1 = golden_read(t_rs1_idx);
 006393             exp_rs2 = golden_read(t_rs2_idx);
 006393             vectors = vectors + 1;
~006393             if (rs1_data !== exp_rs1 || rs2_data !== exp_rs2) begin
                        errors = errors + 1;
                        $error("FAIL[%0d] %0s rs1_idx=%0d rs2_idx=%0d rs1=%h exp_rs1=%h rs2=%h exp_rs2=%h",
                               vectors, tag, t_rs1_idx, t_rs2_idx,
                               rs1_data, exp_rs1, rs2_data, exp_rs2);
                    end
                end
            endtask
        
 002110     task write_reg;
                input [4:0] t_rd_idx;
                input [31:0] t_rd_data;
                input [8*32-1:0] tag;
 002110         reg [31:0] exp_before;
 002110         begin
 002110             @(negedge clk);
 002110             we      = 1'b1;
 002110             rd_idx  = t_rd_idx;
 002110             rd_data = t_rd_data;
 002110             rs1_idx = t_rd_idx;
 002110             rs2_idx = t_rd_idx;
 002110             #1;
 002110             exp_before = golden_read(t_rd_idx);
 002110             vectors = vectors + 1;
~002110             if (rs1_data !== exp_before || rs2_data !== exp_before) begin
                        errors = errors + 1;
                        $error("FAIL[%0d] %0s read-during-write old-value rd_idx=%0d data=%h rs1=%h rs2=%h exp=%h",
                               vectors, tag, t_rd_idx, t_rd_data, rs1_data, rs2_data, exp_before);
                    end
        
 002110             @(posedge clk);
~002108             if (t_rd_idx != 5'd0)
 002108                 golden_regs[t_rd_idx] = t_rd_data;
 002110             #1;
 002110             vectors = vectors + 1;
~002110             if (rs1_data !== golden_read(t_rd_idx) || rs2_data !== golden_read(t_rd_idx)) begin
                        errors = errors + 1;
                        $error("FAIL[%0d] %0s post-write rd_idx=%0d data=%h rs1=%h exp_rs1=%h rs2=%h exp_rs2=%h",
                               vectors, tag, t_rd_idx, t_rd_data,
                               rs1_data, golden_read(t_rd_idx),
                               rs2_data, golden_read(t_rd_idx));
                    end
                end
            endtask
        
 000033     task idle_read_pair;
                input [4:0] t_rs1_idx;
                input [4:0] t_rs2_idx;
                input [8*32-1:0] tag;
 000033         begin
 000033             @(negedge clk);
 000033             we      = 1'b0;
 000033             rd_idx  = t_rs1_idx ^ t_rs2_idx;
 000033             rd_data = 32'hc001_cafe ^ {27'h0, t_rs1_idx};
 000033             check_reads(t_rs1_idx, t_rs2_idx, tag);
 000033             @(posedge clk);
 000033             #1;
 000033             check_reads(t_rs1_idx, t_rs2_idx, tag);
                end
            endtask
        
%000001     initial begin
%000001         patterns[0] = 32'h0000_0000;
%000001         patterns[1] = 32'hffff_ffff;
%000001         patterns[2] = 32'haaaa_aaaa;
%000001         patterns[3] = 32'h5555_5555;
        
~000032         for (bitidx = 0; bitidx < 32; bitidx = bitidx + 1) begin
 000032             patterns[4 + bitidx] = 32'h0000_0001 << bitidx;
 000032             patterns[36 + bitidx] = ~(32'h0000_0001 << bitidx);
                end
        
%000001         vectors  = 0;
%000001         errors   = 0;
%000001         clk      = 1'b0;
%000001         rs1_idx  = 5'd0;
%000001         rs2_idx  = 5'd0;
%000001         we       = 1'b0;
%000001         rd_idx   = 5'd0;
%000001         rd_data  = 32'h0000_0000;
%000001         resetn   = 1'b0;          // assert reset to clear x0 (regs[0]) storage
        
~000032         for (i = 0; i < 32; i = i + 1)
 000032             golden_regs[i] = 32'h0000_0000;
        
%000001         @(posedge clk); #1;       // one reset cycle
%000001         resetn   = 1'b1;          // deassert
%000001         #1;
%000001         check_reads(5'd0, 5'd0, "RESET_X0");
        
%000001         write_reg(5'd0, 32'hffff_ffff, "X0_SUPPRESS_ALL1");
%000001         check_reads(5'd0, 5'd0, "X0_AFTER_ALL1");
%000001         write_reg(5'd0, 32'ha5a5_5a5a, "X0_SUPPRESS_A5");
%000001         check_reads(5'd0, 5'd0, "X0_AFTER_A5");
        
~000031         for (ridx = 1; ridx < 32; ridx = ridx + 1) begin
 000031             reg_idx = ridx[4:0];
 000031             pair_idx = ~reg_idx + 5'd1;
 002108             for (pidx = 0; pidx < 68; pidx = pidx + 1) begin
 002108                 write_reg(reg_idx, patterns[pidx] ^ {reg_idx, reg_idx, reg_idx, reg_idx, reg_idx, reg_idx, 2'b00},
 002108                           "REG_PATTERN_WRITE");
 002108                 check_reads(reg_idx, pair_idx, "READBACK_PAIR");
 002108                 check_reads(5'd0, reg_idx, "X0_RS1_REG_RS2");
 002108                 check_reads(reg_idx, 5'd0, "REG_RS1_X0_RS2");
                    end
                end
        
%000001         idle_read_pair(5'd0, 5'd0, "IDLE_RDIDX_ZERO");
        
~000032         for (ridx = 0; ridx < 32; ridx = ridx + 1) begin
 000032             reg_idx = ridx[4:0];
 000032             pair_idx = ~reg_idx;
 000032             idle_read_pair(reg_idx, pair_idx, "IDLE_READ_NO_WRITE");
                end
        
%000001         if (errors == 0) begin
%000001             $display("PASS: rfu unit %0d/%0d vectors", vectors, vectors);
%000001             $finish;
                end else begin
                    $display("FAIL: rfu unit %0d/%0d vectors failed", errors, vectors);
                    $fatal(1);
                end
            end
        endmodule
        
