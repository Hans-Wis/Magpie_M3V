`timescale 1ns/1ps

module tb_ifu_unit;
    reg         clk;
    reg         resetn;
    reg         pc_stall;
    reg         pc_redirect;
    reg  [31:0] redirect_target;
    reg         ras_predict_ret;
    reg  [31:0] ras_predict_target;
    reg         bp_predict_taken;
    reg  [31:0] bp_predict_target;
    reg         is_16bit;
    wire [31:0] pc;
    wire [31:0] next_pc;

    integer vectors;
    integer errors;
    integer i;

    reg [31:0] g_pc;
    reg [31:0] exp_next;
    reg [31:0] target_patterns [0:35];

    ifu dut (
        .clk(clk),
        .resetn(resetn),
        .pc_stall(pc_stall),
        .pc_redirect(pc_redirect),
        .redirect_target(redirect_target),
        .ras_predict_ret(ras_predict_ret),
        .ras_predict_target(ras_predict_target),
        .bp_predict_taken(bp_predict_taken),
        .bp_predict_target(bp_predict_target),
        .is_16bit(is_16bit),
        .pc(pc),
        .next_pc(next_pc)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    function [31:0] golden_next;
        input [31:0] cur_pc;
        input        stall_i;
        input        redirect_i;
        input [31:0] redirect_tgt_i;
        input        ras_i;
        input [31:0] ras_tgt_i;
        input        bp_i;
        input [31:0] bp_tgt_i;
        input        c_i;
        begin
            golden_next = redirect_i ? redirect_tgt_i :
                          stall_i    ? cur_pc :
                          ras_i      ? ras_tgt_i :
                          bp_i       ? bp_tgt_i :
                                      cur_pc + (c_i ? 32'd2 : 32'd4);
        end
    endfunction

    task check_outputs;
        input [8*120-1:0] tag;
        begin
            vectors = vectors + 1;
            exp_next = golden_next(g_pc, pc_stall, pc_redirect, redirect_target,
                                   ras_predict_ret, ras_predict_target,
                                   bp_predict_taken, bp_predict_target, is_16bit);
            #1;
            if (pc !== g_pc) begin
                errors = errors + 1;
                $error("FAIL[%0d] %0s pc got=%h exp=%h",
                       vectors, tag, pc, g_pc);
            end
            if (next_pc !== exp_next) begin
                errors = errors + 1;
                $error("FAIL[%0d] %0s next_pc got=%h exp=%h cur=%h stall=%b redir=%b ras=%b bp=%b c=%b",
                       vectors, tag, next_pc, exp_next, g_pc, pc_stall,
                       pc_redirect, ras_predict_ret, bp_predict_taken, is_16bit);
            end
        end
    endtask

    task drive_cycle;
        input        stall_i;
        input        redirect_i;
        input [31:0] redirect_tgt_i;
        input        ras_i;
        input [31:0] ras_tgt_i;
        input        bp_i;
        input [31:0] bp_tgt_i;
        input        c_i;
        input [8*120-1:0] tag;
        begin
            @(negedge clk);
            pc_stall          = stall_i;
            pc_redirect       = redirect_i;
            redirect_target   = redirect_tgt_i;
            ras_predict_ret   = ras_i;
            ras_predict_target = ras_tgt_i;
            bp_predict_taken  = bp_i;
            bp_predict_target = bp_tgt_i;
            is_16bit          = c_i;
            check_outputs(tag);
            @(posedge clk);
            g_pc = exp_next;
            #1;
            if (pc !== g_pc) begin
                errors = errors + 1;
                $error("FAIL[%0d] %0s registered pc got=%h exp=%h",
                       vectors, tag, pc, g_pc);
            end
        end
    endtask

    task reset_dut;
        begin
            @(negedge clk);
            resetn            = 1'b0;
            pc_stall          = 1'b0;
            pc_redirect       = 1'b0;
            redirect_target   = 32'h0000_0000;
            ras_predict_ret   = 1'b0;
            ras_predict_target = 32'h0000_0000;
            bp_predict_taken  = 1'b0;
            bp_predict_target = 32'h0000_0000;
            is_16bit          = 1'b0;
            g_pc              = 32'h0000_0000;
            repeat (2) @(posedge clk);
            #1;
            check_outputs("reset holds RESET_PC and default +4 next_pc");
            @(negedge clk);
            resetn = 1'b1;
            @(posedge clk);
            g_pc = exp_next;
            #1;
            if (pc !== g_pc) begin
                errors = errors + 1;
                $error("FAIL reset release pc got=%h exp=%h", pc, g_pc);
            end
        end
    endtask

    initial begin
        vectors = 0;
        errors  = 0;
        resetn  = 1'b1;
        pc_stall = 1'b0;
        pc_redirect = 1'b0;
        redirect_target = 32'h0000_0000;
        ras_predict_ret = 1'b0;
        ras_predict_target = 32'h0000_0000;
        bp_predict_taken = 1'b0;
        bp_predict_target = 32'h0000_0000;
        is_16bit = 1'b0;
        g_pc = 32'h0000_0000;

        target_patterns[0]  = 32'h0000_0000;
        target_patterns[1]  = 32'hFFFF_FFFC;
        target_patterns[2]  = 32'hAAAA_AAAA;
        target_patterns[3]  = 32'h5555_5555;
        target_patterns[4]  = 32'h8000_0000;
        target_patterns[5]  = 32'h7FFF_FFFC;
        target_patterns[6]  = 32'hDEAD_BEEF;
        target_patterns[7]  = 32'h1234_5678;
        target_patterns[8]  = 32'h8765_4320;
        target_patterns[9]  = 32'h0000_0002;
        target_patterns[10] = 32'h0000_0006;
        target_patterns[11] = 32'h0000_000A;
        target_patterns[12] = 32'h0000_000E;
        for (i = 0; i < 32; i = i + 1) begin
            target_patterns[i + 4] = 32'h0000_0001 << i;
        end

        reset_dut();

        drive_cycle(1'b0, 1'b0, 32'h1111_1111, 1'b0, 32'h2222_2222,
                    1'b0, 32'h3333_3333, 1'b0, "sequential RV32I +4");
        drive_cycle(1'b0, 1'b0, 32'h1111_1111, 1'b0, 32'h2222_2222,
                    1'b0, 32'h3333_3333, 1'b1, "sequential RV32C +2");

        drive_cycle(1'b0, 1'b1, 32'h0000_1002, 1'b0, 32'h2222_2222,
                    1'b0, 32'h3333_3333, 1'b0, "redirect to halfword pc bit1 set");
        drive_cycle(1'b0, 1'b0, 32'h1111_1111, 1'b0, 32'h2222_2222,
                    1'b0, 32'h3333_3333, 1'b1, "cross-boundary residue visible as +2 from PC[1]=1");
        drive_cycle(1'b0, 1'b1, 32'h0000_2002, 1'b0, 32'h2222_2222,
                    1'b0, 32'h3333_3333, 1'b0, "redirect to PC[1]=1 before +4 fallback");
        drive_cycle(1'b0, 1'b0, 32'h1111_1111, 1'b0, 32'h2222_2222,
                    1'b0, 32'h3333_3333, 1'b0, "cross-boundary fallback visible as +4 from PC[1]=1");

        drive_cycle(1'b1, 1'b0, 32'h1111_1111, 1'b0, 32'h2222_2222,
                    1'b0, 32'h3333_3333, 1'b0, "stall holds pc");
        drive_cycle(1'b1, 1'b1, 32'hFACE_CAFE, 1'b1, 32'hAAAA_AAAA,
                    1'b1, 32'h5555_5555, 1'b1, "redirect priority over stall ras bp");
        drive_cycle(1'b1, 1'b0, 32'h1111_1111, 1'b1, 32'hAAAA_AAAA,
                    1'b1, 32'h5555_5555, 1'b1, "stall priority over ras bp");
        drive_cycle(1'b0, 1'b0, 32'h1111_1111, 1'b1, 32'hAAAA_AAAA,
                    1'b1, 32'h5555_5555, 1'b0, "ras priority over bp");
        drive_cycle(1'b0, 1'b0, 32'h1111_1111, 1'b0, 32'h2222_2222,
                    1'b1, 32'h5555_5555, 1'b1, "bp target selected");

        for (i = 0; i < 36; i = i + 1) begin
            drive_cycle(1'b0, 1'b1, target_patterns[i], 1'b0, 32'h0000_0000,
                        1'b0, 32'h0000_0000, i[0], "redirect full-range target sweep");
            drive_cycle(1'b0, 1'b0, 32'h0000_0000, 1'b1, ~target_patterns[i],
                        1'b0, 32'h0000_0000, ~i[0], "ras full-range target sweep");
            drive_cycle(1'b0, 1'b0, 32'h0000_0000, 1'b0, 32'h0000_0000,
                        1'b1, target_patterns[i] ^ 32'hA5A5_5A5A, i[0],
                        "bp full-range target sweep");
        end

        drive_cycle(1'b0, 1'b1, 32'hFFFF_FFFC, 1'b0, 32'h0000_0000,
                    1'b0, 32'h0000_0000, 1'b0, "near top +4 wrap setup");
        drive_cycle(1'b0, 1'b0, 32'h0000_0000, 1'b0, 32'h0000_0000,
                    1'b0, 32'h0000_0000, 1'b0, "near top +4 wraps to zero");
        drive_cycle(1'b0, 1'b1, 32'hFFFF_FFFE, 1'b0, 32'h0000_0000,
                    1'b0, 32'h0000_0000, 1'b1, "near top +2 wrap setup");
        drive_cycle(1'b0, 1'b0, 32'h0000_0000, 1'b0, 32'h0000_0000,
                    1'b0, 32'h0000_0000, 1'b1, "near top +2 wraps to zero");

        reset_dut();

        if (errors == 0) begin
            $display("PASS: ifu unit %0d/%0d vectors", vectors, vectors);
        end else begin
            $display("FAIL: ifu unit %0d errors in %0d vectors", errors, vectors);
            $fatal(1);
        end
        $finish;
    end
endmodule
