`timescale 1ns/1ps

module tb_ras_unit;
    reg         clk;
    reg         resetn;
    wire [31:0] ras_top;
    reg         push;
    reg  [31:0] push_val;
    reg         pop;

    integer vectors;
    integer errors;
    integer i;

    reg [31:0] g_stack [0:7];
    reg [2:0]  g_ptr;

    reg [31:0] addr_memmap [0:15];
    reg [31:0] full_range_patterns [0:5];

    ras dut (
        .clk(clk),
        .resetn(resetn),
        .ras_top(ras_top),
        .push(push),
        .push_val(push_val),
        .pop(pop)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    function [31:0] golden_top;
        begin
            golden_top = (g_ptr == 3'd0) ? 32'h0000_0000 : g_stack[g_ptr - 3'd1];
        end
    endfunction

    task check_top;
        input [8*80-1:0] tag;
        begin
            vectors = vectors + 1;
            if (ras_top !== golden_top()) begin
                errors = errors + 1;
                $error("FAIL[%0d] %0s ras_top got=%h exp=%h ptr=%0d",
                       vectors, tag, ras_top, golden_top(), g_ptr);
            end
        end
    endtask

    task model_step;
        input        do_push;
        input [31:0] val;
        input        do_pop;
        reg [2:0] top_idx;
        begin
            top_idx = g_ptr - 3'd1;
            if (do_push && do_pop) begin
                if (g_ptr != 3'd0) begin
                    g_stack[top_idx] = val;
                end else begin
                    g_stack[0] = val;
                end
            end else if (do_push) begin
                g_stack[g_ptr] = val;
                g_ptr = g_ptr + 3'd1;
            end else if (do_pop) begin
                if (g_ptr != 3'd0) begin
                    g_ptr = g_ptr - 3'd1;
                end
            end
        end
    endtask

    task drive_cycle;
        input        do_push;
        input [31:0] val;
        input        do_pop;
        input [8*80-1:0] tag;
        begin
            @(negedge clk);
            push     = do_push;
            push_val = val;
            pop      = do_pop;
            model_step(do_push, val, do_pop);
            @(posedge clk);
            #1;
            push = 1'b0;
            pop  = 1'b0;
            check_top(tag);
        end
    endtask

    task reset_dut;
        begin
            @(negedge clk);
            resetn   = 1'b0;
            push     = 1'b0;
            push_val = 32'h0000_0000;
            pop      = 1'b0;
            g_ptr    = 3'd0;
            for (i = 0; i < 8; i = i + 1) begin
                g_stack[i] = 32'h0000_0000;
            end
            repeat (2) @(posedge clk);
            #1;
            check_top("reset top is zero");
            @(negedge clk);
            resetn = 1'b1;
            @(posedge clk);
            #1;
            check_top("post reset top is zero");
        end
    endtask

    initial begin
        vectors = 0;
        errors  = 0;
        resetn  = 1'b1;
        push    = 1'b0;
        pop     = 1'b0;
        push_val = 32'h0000_0000;

        addr_memmap[0]  = 32'h0000_0004;
        addr_memmap[1]  = 32'h0000_0018;
        addr_memmap[2]  = 32'h0000_003C;
        addr_memmap[3]  = 32'h0000_00F0;
        addr_memmap[4]  = 32'h0000_0554;
        addr_memmap[5]  = 32'h0000_0AA8;
        addr_memmap[6]  = 32'h0000_155C;
        addr_memmap[7]  = 32'h0000_2AB0;
        addr_memmap[8]  = 32'h0000_3FFC;
        addr_memmap[9]  = 32'h0000_0008;
        addr_memmap[10] = 32'h0000_0014;
        addr_memmap[11] = 32'h0000_0028;
        addr_memmap[12] = 32'h0000_007C;
        addr_memmap[13] = 32'h0000_01F4;
        addr_memmap[14] = 32'h0000_0FEC;
        addr_memmap[15] = 32'h0000_3550;

        full_range_patterns[0] = 32'hFFFF_FFFC;
        full_range_patterns[1] = 32'hDEAD_BEEF;
        full_range_patterns[2] = 32'hAAAA_AAAA;
        full_range_patterns[3] = 32'h5555_5555;
        full_range_patterns[4] = 32'h8000_0000;
        full_range_patterns[5] = 32'h7FFF_FFFC;

        for (i = 0; i < 8; i = i + 1) begin
            g_stack[i] = 32'h0000_0000;
        end
        g_ptr = 3'd0;

        reset_dut();

        // Unit-level push_val is unconstrained: drive all 32 address bits into
        // every physical slot and onto ras_top before behavioral sweeps.
        for (i = 0; i < 8; i = i + 1) begin
            drive_cycle(1'b1, 32'hFFFF_FFFF, 1'b0,
                        "full-width all-ones payload per slot");
        end
        for (i = 0; i < 8; i = i + 1) begin
            drive_cycle(1'b1, 32'h0000_0000, 1'b0,
                        "full-width all-zeroes payload per slot");
        end
        for (i = 0; i < 32; i = i + 1) begin
            drive_cycle(1'b1, (32'h0000_0001 << i), 1'b0,
                        "walking-1 full-width push payload");
        end
        for (i = 0; i < 32; i = i + 1) begin
            drive_cycle(1'b1, ~((32'h0000_0001 << i)), 1'b0,
                        "walking-1 complement full-width push payload");
        end
        for (i = 0; i < 6; i = i + 1) begin
            drive_cycle(1'b1, full_range_patterns[i], 1'b0,
                        "fixed full-range push payload");
        end

        // Fill all eight storage slots. The implemented 3-bit pointer wraps to
        // zero on the eighth push, so ras_top reflects the RTL's empty encoding.
        for (i = 0; i < 8; i = i + 1) begin
            drive_cycle(1'b1, addr_memmap[i], 1'b0, "depth-8 fill / pointer wrap");
        end

        // Empty pop is a no-op and keeps ras_top at zero.
        drive_cycle(1'b0, 32'h0000_0000, 1'b1, "empty pop no-op after wrap");

        // Push and pop seven visible entries to verify LIFO behavior while ptr
        // is non-zero, covering every non-empty top index.
        for (i = 0; i < 7; i = i + 1) begin
            drive_cycle(1'b1, addr_memmap[8 + i], 1'b0, "visible push for LIFO sweep");
        end
        for (i = 0; i < 7; i = i + 1) begin
            drive_cycle(1'b0, 32'h0000_0000, 1'b1, "visible pop for LIFO sweep");
        end

        // Wrap/overwrite: push through slot 7 and then back to slot 0/1.
        for (i = 0; i < 10; i = i + 1) begin
            drive_cycle(1'b1, addr_memmap[(i * 3) & 4'hf], 1'b0,
                        "push 9-10 circular overwrite sweep");
        end

        // Same-cycle push+pop replaces the current top when non-empty.
        drive_cycle(1'b1, 32'h0000_2A54, 1'b1, "same-cycle replace non-empty top");

        // Pop back to zero, then same-cycle push+pop from empty covers slot 0
        // write with ptr unchanged and visible top still zero.
        for (i = 0; i < 2; i = i + 1) begin
            drive_cycle(1'b0, 32'h0000_0000, 1'b1, "pop toward empty before empty both");
        end
        drive_cycle(1'b1, 32'h0000_15A8, 1'b1, "same-cycle push-pop empty");
        drive_cycle(1'b0, 32'h0000_0000, 1'b1, "empty pop final");

        if (errors == 0) begin
            $display("PASS: ras unit %0d/%0d vectors", vectors, vectors);
        end else begin
            $display("FAIL: ras unit %0d errors in %0d vectors", errors, vectors);
            $fatal(1);
        end
        $finish;
    end
endmodule
