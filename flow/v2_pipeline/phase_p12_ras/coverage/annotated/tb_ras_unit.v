//      // verilator_coverage annotation
        `timescale 1ns/1ps
        
        module tb_ras_unit;
 000128     reg         clk;
%000002     reg         resetn;
~000021     wire [31:0] ras_top;
 000113     reg         push;
~000018     reg  [31:0] push_val;
 000013     reg         pop;
        
            integer vectors;
            integer errors;
            integer i;
        
%000006     reg [31:0] g_stack [0:7];
 000059     reg [2:0]  g_ptr;
        
            reg [31:0] addr_memmap [0:15];
%000001     reg [31:0] full_range_patterns [0:5];
        
            ras dut (
                .clk(clk),
                .resetn(resetn),
                .ras_top(ras_top),
                .push(push),
                .push_val(push_val),
                .pop(pop)
            );
        
%000000     initial begin
%000000         clk = 1'b0;
~000255         forever #5 clk = ~clk;
            end
        
 000126     function [31:0] golden_top;
 000126         begin
 000126             golden_top = (g_ptr == 3'd0) ? 32'h0000_0000 : g_stack[g_ptr - 3'd1];
                end
            endfunction
        
 000126     task check_top;
                input [8*80-1:0] tag;
 000126         begin
 000126             vectors = vectors + 1;
 000126             if (ras_top !== golden_top()) begin
                        errors = errors + 1;
                        $error("FAIL[%0d] %0s ras_top got=%h exp=%h ptr=%0d",
                               vectors, tag, ras_top, golden_top(), g_ptr);
                    end
                end
            endtask
        
 000124     task model_step;
                input        do_push;
                input [31:0] val;
                input        do_pop;
 000124         reg [2:0] top_idx;
 000124         begin
 000124             top_idx = g_ptr - 3'd1;
~000111             if (do_push && do_pop) begin
%000001                 if (g_ptr != 3'd0) begin
%000001                     g_stack[top_idx] = val;
%000001                 end else begin
%000001                     g_stack[0] = val;
                        end
 000111             end else if (do_push) begin
 000111                 g_stack[g_ptr] = val;
 000111                 g_ptr = g_ptr + 3'd1;
~000011             end else if (do_pop) begin
%000007                 if (g_ptr != 3'd0) begin
%000007                     g_ptr = g_ptr - 3'd1;
                        end
                    end
                end
            endtask
        
 000124     task drive_cycle;
                input        do_push;
                input [31:0] val;
                input        do_pop;
                input [8*80-1:0] tag;
 000124         begin
 000124             @(negedge clk);
 000124             push     = do_push;
 000124             push_val = val;
 000124             pop      = do_pop;
 000124             model_step(do_push, val, do_pop);
 000124             @(posedge clk);
 000124             #1;
 000124             push = 1'b0;
 000124             pop  = 1'b0;
 000124             check_top(tag);
                end
            endtask
        
%000001     task reset_dut;
%000001         begin
%000001             @(negedge clk);
%000001             resetn   = 1'b0;
%000001             push     = 1'b0;
%000001             push_val = 32'h0000_0000;
%000001             pop      = 1'b0;
%000001             g_ptr    = 3'd0;
%000008             for (i = 0; i < 8; i = i + 1) begin
%000008                 g_stack[i] = 32'h0000_0000;
                    end
%000002             repeat (2) @(posedge clk);
%000001             #1;
%000001             check_top("reset top is zero");
%000001             @(negedge clk);
%000001             resetn = 1'b1;
%000001             @(posedge clk);
%000001             #1;
%000001             check_top("post reset top is zero");
                end
            endtask
        
%000001     initial begin
%000001         vectors = 0;
%000001         errors  = 0;
%000001         resetn  = 1'b1;
%000001         push    = 1'b0;
%000001         pop     = 1'b0;
%000001         push_val = 32'h0000_0000;
        
%000001         addr_memmap[0]  = 32'h0000_0004;
%000001         addr_memmap[1]  = 32'h0000_0018;
%000001         addr_memmap[2]  = 32'h0000_003C;
%000001         addr_memmap[3]  = 32'h0000_00F0;
%000001         addr_memmap[4]  = 32'h0000_0554;
%000001         addr_memmap[5]  = 32'h0000_0AA8;
%000001         addr_memmap[6]  = 32'h0000_155C;
%000001         addr_memmap[7]  = 32'h0000_2AB0;
%000001         addr_memmap[8]  = 32'h0000_3FFC;
%000001         addr_memmap[9]  = 32'h0000_0008;
%000001         addr_memmap[10] = 32'h0000_0014;
%000001         addr_memmap[11] = 32'h0000_0028;
%000001         addr_memmap[12] = 32'h0000_007C;
%000001         addr_memmap[13] = 32'h0000_01F4;
%000001         addr_memmap[14] = 32'h0000_0FEC;
%000001         addr_memmap[15] = 32'h0000_3550;
        
%000001         full_range_patterns[0] = 32'hFFFF_FFFC;
%000001         full_range_patterns[1] = 32'hDEAD_BEEF;
%000001         full_range_patterns[2] = 32'hAAAA_AAAA;
%000001         full_range_patterns[3] = 32'h5555_5555;
%000001         full_range_patterns[4] = 32'h8000_0000;
%000001         full_range_patterns[5] = 32'h7FFF_FFFC;
        
%000008         for (i = 0; i < 8; i = i + 1) begin
%000008             g_stack[i] = 32'h0000_0000;
                end
%000001         g_ptr = 3'd0;
        
%000001         reset_dut();
        
                // Unit-level push_val is unconstrained: drive all 32 address bits into
                // every physical slot and onto ras_top before behavioral sweeps.
%000008         for (i = 0; i < 8; i = i + 1) begin
%000008             drive_cycle(1'b1, 32'hFFFF_FFFF, 1'b0,
%000008                         "full-width all-ones payload per slot");
                end
%000008         for (i = 0; i < 8; i = i + 1) begin
%000008             drive_cycle(1'b1, 32'h0000_0000, 1'b0,
%000008                         "full-width all-zeroes payload per slot");
                end
~000032         for (i = 0; i < 32; i = i + 1) begin
 000032             drive_cycle(1'b1, (32'h0000_0001 << i), 1'b0,
 000032                         "walking-1 full-width push payload");
                end
~000032         for (i = 0; i < 32; i = i + 1) begin
 000032             drive_cycle(1'b1, ~((32'h0000_0001 << i)), 1'b0,
 000032                         "walking-1 complement full-width push payload");
                end
%000006         for (i = 0; i < 6; i = i + 1) begin
%000006             drive_cycle(1'b1, full_range_patterns[i], 1'b0,
%000006                         "fixed full-range push payload");
                end
        
                // Fill all eight storage slots. The implemented 3-bit pointer wraps to
                // zero on the eighth push, so ras_top reflects the RTL's empty encoding.
%000008         for (i = 0; i < 8; i = i + 1) begin
%000008             drive_cycle(1'b1, addr_memmap[i], 1'b0, "depth-8 fill / pointer wrap");
                end
        
                // Empty pop is a no-op and keeps ras_top at zero.
%000001         drive_cycle(1'b0, 32'h0000_0000, 1'b1, "empty pop no-op after wrap");
        
                // Push and pop seven visible entries to verify LIFO behavior while ptr
                // is non-zero, covering every non-empty top index.
%000007         for (i = 0; i < 7; i = i + 1) begin
%000007             drive_cycle(1'b1, addr_memmap[8 + i], 1'b0, "visible push for LIFO sweep");
                end
%000007         for (i = 0; i < 7; i = i + 1) begin
%000007             drive_cycle(1'b0, 32'h0000_0000, 1'b1, "visible pop for LIFO sweep");
                end
        
                // Wrap/overwrite: push through slot 7 and then back to slot 0/1.
~000010         for (i = 0; i < 10; i = i + 1) begin
 000010             drive_cycle(1'b1, addr_memmap[(i * 3) & 4'hf], 1'b0,
 000010                         "push 9-10 circular overwrite sweep");
                end
        
                // Same-cycle push+pop replaces the current top when non-empty.
%000001         drive_cycle(1'b1, 32'h0000_2A54, 1'b1, "same-cycle replace non-empty top");
        
                // Pop back to zero, then same-cycle push+pop from empty covers slot 0
                // write with ptr unchanged and visible top still zero.
%000002         for (i = 0; i < 2; i = i + 1) begin
%000002             drive_cycle(1'b0, 32'h0000_0000, 1'b1, "pop toward empty before empty both");
                end
%000001         drive_cycle(1'b1, 32'h0000_15A8, 1'b1, "same-cycle push-pop empty");
%000001         drive_cycle(1'b0, 32'h0000_0000, 1'b1, "empty pop final");
        
%000001         if (errors == 0) begin
%000001             $display("PASS: ras unit %0d/%0d vectors", vectors, vectors);
                end else begin
                    $display("FAIL: ras unit %0d errors in %0d vectors", errors, vectors);
                    $fatal(1);
                end
%000001         $finish;
            end
        endmodule
        
