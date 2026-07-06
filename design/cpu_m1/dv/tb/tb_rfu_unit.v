`timescale 1ns/1ps
`include "def.vh"

module tb_rfu_unit;
    reg         clk;
    reg         resetn;
    reg  [ 4:0] rs1_idx;
    reg  [ 4:0] rs2_idx;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    reg         we;
    reg  [ 4:0] rd_idx;
    reg  [31:0] rd_data;

    reg [31:0] golden_regs [0:31];
    reg [31:0] patterns [0:67];

    integer vectors;
    integer errors;
    integer ridx;
    integer pidx;
    integer bitidx;
    integer i;
    reg [4:0] reg_idx;
    reg [4:0] pair_idx;

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

    always #5 clk = ~clk;

    function [31:0] golden_read;
        input [4:0] f_idx;
        begin
            golden_read = (f_idx == 5'd0) ? 32'h0000_0000 : golden_regs[f_idx];
        end
    endfunction

    task check_reads;
        input [4:0] t_rs1_idx;
        input [4:0] t_rs2_idx;
        input [8*32-1:0] tag;
        reg [31:0] exp_rs1;
        reg [31:0] exp_rs2;
        begin
            rs1_idx = t_rs1_idx;
            rs2_idx = t_rs2_idx;
            #1;
            exp_rs1 = golden_read(t_rs1_idx);
            exp_rs2 = golden_read(t_rs2_idx);
            vectors = vectors + 1;
            if (rs1_data !== exp_rs1 || rs2_data !== exp_rs2) begin
                errors = errors + 1;
                $error("FAIL[%0d] %0s rs1_idx=%0d rs2_idx=%0d rs1=%h exp_rs1=%h rs2=%h exp_rs2=%h",
                       vectors, tag, t_rs1_idx, t_rs2_idx,
                       rs1_data, exp_rs1, rs2_data, exp_rs2);
            end
        end
    endtask

    task write_reg;
        input [4:0] t_rd_idx;
        input [31:0] t_rd_data;
        input [8*32-1:0] tag;
        reg [31:0] exp_before;
        begin
            @(negedge clk);
            we      = 1'b1;
            rd_idx  = t_rd_idx;
            rd_data = t_rd_data;
            rs1_idx = t_rd_idx;
            rs2_idx = t_rd_idx;
            #1;
            exp_before = golden_read(t_rd_idx);
            vectors = vectors + 1;
            if (rs1_data !== exp_before || rs2_data !== exp_before) begin
                errors = errors + 1;
                $error("FAIL[%0d] %0s read-during-write old-value rd_idx=%0d data=%h rs1=%h rs2=%h exp=%h",
                       vectors, tag, t_rd_idx, t_rd_data, rs1_data, rs2_data, exp_before);
            end

            @(posedge clk);
            if (t_rd_idx != 5'd0)
                golden_regs[t_rd_idx] = t_rd_data;
            #1;
            vectors = vectors + 1;
            if (rs1_data !== golden_read(t_rd_idx) || rs2_data !== golden_read(t_rd_idx)) begin
                errors = errors + 1;
                $error("FAIL[%0d] %0s post-write rd_idx=%0d data=%h rs1=%h exp_rs1=%h rs2=%h exp_rs2=%h",
                       vectors, tag, t_rd_idx, t_rd_data,
                       rs1_data, golden_read(t_rd_idx),
                       rs2_data, golden_read(t_rd_idx));
            end
        end
    endtask

    task idle_read_pair;
        input [4:0] t_rs1_idx;
        input [4:0] t_rs2_idx;
        input [8*32-1:0] tag;
        begin
            @(negedge clk);
            we      = 1'b0;
            rd_idx  = t_rs1_idx ^ t_rs2_idx;
            rd_data = 32'hc001_cafe ^ {27'h0, t_rs1_idx};
            check_reads(t_rs1_idx, t_rs2_idx, tag);
            @(posedge clk);
            #1;
            check_reads(t_rs1_idx, t_rs2_idx, tag);
        end
    endtask

    initial begin
        patterns[0] = 32'h0000_0000;
        patterns[1] = 32'hffff_ffff;
        patterns[2] = 32'haaaa_aaaa;
        patterns[3] = 32'h5555_5555;

        for (bitidx = 0; bitidx < 32; bitidx = bitidx + 1) begin
            patterns[4 + bitidx] = 32'h0000_0001 << bitidx;
            patterns[36 + bitidx] = ~(32'h0000_0001 << bitidx);
        end

        vectors  = 0;
        errors   = 0;
        clk      = 1'b0;
        rs1_idx  = 5'd0;
        rs2_idx  = 5'd0;
        we       = 1'b0;
        rd_idx   = 5'd0;
        rd_data  = 32'h0000_0000;
        resetn   = 1'b0;          // assert reset to clear x0 (regs[0]) storage

        for (i = 0; i < 32; i = i + 1)
            golden_regs[i] = 32'h0000_0000;

        @(posedge clk); #1;       // one reset cycle
        resetn   = 1'b1;          // deassert
        #1;
        check_reads(5'd0, 5'd0, "RESET_X0");

        write_reg(5'd0, 32'hffff_ffff, "X0_SUPPRESS_ALL1");
        check_reads(5'd0, 5'd0, "X0_AFTER_ALL1");
        write_reg(5'd0, 32'ha5a5_5a5a, "X0_SUPPRESS_A5");
        check_reads(5'd0, 5'd0, "X0_AFTER_A5");

        for (ridx = 1; ridx < 32; ridx = ridx + 1) begin
            reg_idx = ridx[4:0];
            pair_idx = ~reg_idx + 5'd1;
            for (pidx = 0; pidx < 68; pidx = pidx + 1) begin
                write_reg(reg_idx, patterns[pidx] ^ {reg_idx, reg_idx, reg_idx, reg_idx, reg_idx, reg_idx, 2'b00},
                          "REG_PATTERN_WRITE");
                check_reads(reg_idx, pair_idx, "READBACK_PAIR");
                check_reads(5'd0, reg_idx, "X0_RS1_REG_RS2");
                check_reads(reg_idx, 5'd0, "REG_RS1_X0_RS2");
            end
        end

        idle_read_pair(5'd0, 5'd0, "IDLE_RDIDX_ZERO");

        for (ridx = 0; ridx < 32; ridx = ridx + 1) begin
            reg_idx = ridx[4:0];
            pair_idx = ~reg_idx;
            idle_read_pair(reg_idx, pair_idx, "IDLE_READ_NO_WRITE");
        end

        if (errors == 0) begin
            $display("PASS: rfu unit %0d/%0d vectors", vectors, vectors);
            $finish;
        end else begin
            $display("FAIL: rfu unit %0d/%0d vectors failed", errors, vectors);
            $fatal(1);
        end
    end
endmodule
