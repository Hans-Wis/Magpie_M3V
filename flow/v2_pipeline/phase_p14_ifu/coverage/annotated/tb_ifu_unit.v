//      // verilator_coverage annotation
        `timescale 1ns/1ps
        
        module tb_ifu_unit;
 000130     reg         clk;
%000003     reg         resetn;
%000001     reg         pc_stall;
 000041     reg         pc_redirect;
%000009     reg  [31:0] redirect_target;
 000037     reg         ras_predict_ret;
 000035     reg  [31:0] ras_predict_target;
 000037     reg         bp_predict_taken;
~000035     reg  [31:0] bp_predict_target;
 000059     reg         is_16bit;
 000047     wire [31:0] pc;
 000050     wire [31:0] next_pc;
        
            integer vectors;
            integer errors;
            integer i;
        
 000046     reg [31:0] g_pc;
 000046     reg [31:0] exp_next;
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
        
%000000     initial begin
%000000         clk = 1'b0;
~000259         forever #5 clk = ~clk;
            end
        
 000125     function [31:0] golden_next;
                input [31:0] cur_pc;
                input        stall_i;
                input        redirect_i;
                input [31:0] redirect_tgt_i;
                input        ras_i;
                input [31:0] ras_tgt_i;
                input        bp_i;
                input [31:0] bp_tgt_i;
                input        c_i;
 000125         begin
 000125             golden_next = redirect_i ? redirect_tgt_i :
~000082                           stall_i    ? cur_pc :
 000045                           ras_i      ? ras_tgt_i :
~000037                           bp_i       ? bp_tgt_i :
%000008                                       cur_pc + (c_i ? 32'd2 : 32'd4);
                end
            endfunction
        
 000125     task check_outputs;
                input [8*120-1:0] tag;
 000125         begin
 000125             vectors = vectors + 1;
 000125             exp_next = golden_next(g_pc, pc_stall, pc_redirect, redirect_target,
 000125                                    ras_predict_ret, ras_predict_target,
 000125                                    bp_predict_taken, bp_predict_target, is_16bit);
 000125             #1;
 000125             if (pc !== g_pc) begin
                        errors = errors + 1;
                        $error("FAIL[%0d] %0s pc got=%h exp=%h",
                               vectors, tag, pc, g_pc);
                    end
 000125             if (next_pc !== exp_next) begin
                        errors = errors + 1;
                        $error("FAIL[%0d] %0s next_pc got=%h exp=%h cur=%h stall=%b redir=%b ras=%b bp=%b c=%b",
                               vectors, tag, next_pc, exp_next, g_pc, pc_stall,
                               pc_redirect, ras_predict_ret, bp_predict_taken, is_16bit);
                    end
                end
            endtask
        
 000123     task drive_cycle;
                input        stall_i;
                input        redirect_i;
                input [31:0] redirect_tgt_i;
                input        ras_i;
                input [31:0] ras_tgt_i;
                input        bp_i;
                input [31:0] bp_tgt_i;
                input        c_i;
                input [8*120-1:0] tag;
 000123         begin
 000123             @(negedge clk);
 000123             pc_stall          = stall_i;
 000123             pc_redirect       = redirect_i;
 000123             redirect_target   = redirect_tgt_i;
 000123             ras_predict_ret   = ras_i;
 000123             ras_predict_target = ras_tgt_i;
 000123             bp_predict_taken  = bp_i;
 000123             bp_predict_target = bp_tgt_i;
 000123             is_16bit          = c_i;
 000123             check_outputs(tag);
 000123             @(posedge clk);
 000123             g_pc = exp_next;
 000123             #1;
 000123             if (pc !== g_pc) begin
                        errors = errors + 1;
                        $error("FAIL[%0d] %0s registered pc got=%h exp=%h",
                               vectors, tag, pc, g_pc);
                    end
                end
            endtask
        
%000002     task reset_dut;
%000002         begin
%000002             @(negedge clk);
%000002             resetn            = 1'b0;
%000002             pc_stall          = 1'b0;
%000002             pc_redirect       = 1'b0;
%000002             redirect_target   = 32'h0000_0000;
%000002             ras_predict_ret   = 1'b0;
%000002             ras_predict_target = 32'h0000_0000;
%000002             bp_predict_taken  = 1'b0;
%000002             bp_predict_target = 32'h0000_0000;
%000002             is_16bit          = 1'b0;
%000002             g_pc              = 32'h0000_0000;
%000004             repeat (2) @(posedge clk);
%000002             #1;
%000002             check_outputs("reset holds RESET_PC and default +4 next_pc");
%000002             @(negedge clk);
%000002             resetn = 1'b1;
%000002             @(posedge clk);
%000002             g_pc = exp_next;
%000002             #1;
%000002             if (pc !== g_pc) begin
                        errors = errors + 1;
                        $error("FAIL reset release pc got=%h exp=%h", pc, g_pc);
                    end
                end
            endtask
        
%000001     initial begin
%000001         vectors = 0;
%000001         errors  = 0;
%000001         resetn  = 1'b1;
%000001         pc_stall = 1'b0;
%000001         pc_redirect = 1'b0;
%000001         redirect_target = 32'h0000_0000;
%000001         ras_predict_ret = 1'b0;
%000001         ras_predict_target = 32'h0000_0000;
%000001         bp_predict_taken = 1'b0;
%000001         bp_predict_target = 32'h0000_0000;
%000001         is_16bit = 1'b0;
%000001         g_pc = 32'h0000_0000;
        
%000001         target_patterns[0]  = 32'h0000_0000;
%000001         target_patterns[1]  = 32'hFFFF_FFFC;
%000001         target_patterns[2]  = 32'hAAAA_AAAA;
%000001         target_patterns[3]  = 32'h5555_5555;
%000001         target_patterns[4]  = 32'h8000_0000;
%000001         target_patterns[5]  = 32'h7FFF_FFFC;
%000001         target_patterns[6]  = 32'hDEAD_BEEF;
%000001         target_patterns[7]  = 32'h1234_5678;
%000001         target_patterns[8]  = 32'h8765_4320;
%000001         target_patterns[9]  = 32'h0000_0002;
%000001         target_patterns[10] = 32'h0000_0006;
%000001         target_patterns[11] = 32'h0000_000A;
%000001         target_patterns[12] = 32'h0000_000E;
~000032         for (i = 0; i < 32; i = i + 1) begin
 000032             target_patterns[i + 4] = 32'h0000_0001 << i;
                end
        
%000001         reset_dut();
        
%000001         drive_cycle(1'b0, 1'b0, 32'h1111_1111, 1'b0, 32'h2222_2222,
%000001                     1'b0, 32'h3333_3333, 1'b0, "sequential RV32I +4");
%000001         drive_cycle(1'b0, 1'b0, 32'h1111_1111, 1'b0, 32'h2222_2222,
%000001                     1'b0, 32'h3333_3333, 1'b1, "sequential RV32C +2");
        
%000001         drive_cycle(1'b0, 1'b1, 32'h0000_1002, 1'b0, 32'h2222_2222,
%000001                     1'b0, 32'h3333_3333, 1'b0, "redirect to halfword pc bit1 set");
%000001         drive_cycle(1'b0, 1'b0, 32'h1111_1111, 1'b0, 32'h2222_2222,
%000001                     1'b0, 32'h3333_3333, 1'b1, "cross-boundary residue visible as +2 from PC[1]=1");
%000001         drive_cycle(1'b0, 1'b1, 32'h0000_2002, 1'b0, 32'h2222_2222,
%000001                     1'b0, 32'h3333_3333, 1'b0, "redirect to PC[1]=1 before +4 fallback");
%000001         drive_cycle(1'b0, 1'b0, 32'h1111_1111, 1'b0, 32'h2222_2222,
%000001                     1'b0, 32'h3333_3333, 1'b0, "cross-boundary fallback visible as +4 from PC[1]=1");
        
%000001         drive_cycle(1'b1, 1'b0, 32'h1111_1111, 1'b0, 32'h2222_2222,
%000001                     1'b0, 32'h3333_3333, 1'b0, "stall holds pc");
%000001         drive_cycle(1'b1, 1'b1, 32'hFACE_CAFE, 1'b1, 32'hAAAA_AAAA,
%000001                     1'b1, 32'h5555_5555, 1'b1, "redirect priority over stall ras bp");
%000001         drive_cycle(1'b1, 1'b0, 32'h1111_1111, 1'b1, 32'hAAAA_AAAA,
%000001                     1'b1, 32'h5555_5555, 1'b1, "stall priority over ras bp");
%000001         drive_cycle(1'b0, 1'b0, 32'h1111_1111, 1'b1, 32'hAAAA_AAAA,
%000001                     1'b1, 32'h5555_5555, 1'b0, "ras priority over bp");
%000001         drive_cycle(1'b0, 1'b0, 32'h1111_1111, 1'b0, 32'h2222_2222,
%000001                     1'b1, 32'h5555_5555, 1'b1, "bp target selected");
        
~000036         for (i = 0; i < 36; i = i + 1) begin
 000036             drive_cycle(1'b0, 1'b1, target_patterns[i], 1'b0, 32'h0000_0000,
 000036                         1'b0, 32'h0000_0000, i[0], "redirect full-range target sweep");
 000036             drive_cycle(1'b0, 1'b0, 32'h0000_0000, 1'b1, ~target_patterns[i],
~000036                         1'b0, 32'h0000_0000, ~i[0], "ras full-range target sweep");
 000036             drive_cycle(1'b0, 1'b0, 32'h0000_0000, 1'b0, 32'h0000_0000,
 000036                         1'b1, target_patterns[i] ^ 32'hA5A5_5A5A, i[0],
 000036                         "bp full-range target sweep");
                end
        
%000001         drive_cycle(1'b0, 1'b1, 32'hFFFF_FFFC, 1'b0, 32'h0000_0000,
%000001                     1'b0, 32'h0000_0000, 1'b0, "near top +4 wrap setup");
%000001         drive_cycle(1'b0, 1'b0, 32'h0000_0000, 1'b0, 32'h0000_0000,
%000001                     1'b0, 32'h0000_0000, 1'b0, "near top +4 wraps to zero");
%000001         drive_cycle(1'b0, 1'b1, 32'hFFFF_FFFE, 1'b0, 32'h0000_0000,
%000001                     1'b0, 32'h0000_0000, 1'b1, "near top +2 wrap setup");
%000001         drive_cycle(1'b0, 1'b0, 32'h0000_0000, 1'b0, 32'h0000_0000,
%000001                     1'b0, 32'h0000_0000, 1'b1, "near top +2 wraps to zero");
        
%000001         reset_dut();
        
%000001         if (errors == 0) begin
%000001             $display("PASS: ifu unit %0d/%0d vectors", vectors, vectors);
                end else begin
                    $display("FAIL: ifu unit %0d errors in %0d vectors", errors, vectors);
                    $fatal(1);
                end
%000001         $finish;
            end
        endmodule
        
