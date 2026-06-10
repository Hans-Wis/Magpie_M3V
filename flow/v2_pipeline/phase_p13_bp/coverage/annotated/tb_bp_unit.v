//      // verilator_coverage annotation
        `timescale 1ns/1ps
        
        module tb_bp_unit;
            localparam IDX_BITS = 5;
            localparam IDX_LSB  = 1;
            localparam TAG_BITS = 32 - (IDX_LSB + IDX_BITS);
            localparam N_SETS   = 1 << IDX_BITS;
        
 001231     reg         clk;
%000003     reg         resetn;
~000161     reg  [31:0] if_pc;
 000449     wire        bp_predict_taken;
 000360     wire [31:0] bp_predict_target;
 001218     reg         upd_valid;
~000161     reg  [31:0] upd_pc;
 000417     reg         upd_taken;
 000344     reg  [31:0] upd_target;
        
            integer vectors;
            integer errors;
            integer set_i;
            integer pat_i;
        
%000001     reg                 g_valid0  [0:N_SETS-1];
            reg [TAG_BITS-1:0]  g_tag0    [0:N_SETS-1];
            reg [31:0]          g_target0 [0:N_SETS-1];
%000006     reg [1:0]           g_count0  [0:N_SETS-1];
%000001     reg                 g_valid1  [0:N_SETS-1];
            reg [TAG_BITS-1:0]  g_tag1    [0:N_SETS-1];
            reg [31:0]          g_target1 [0:N_SETS-1];
~000012     reg [1:0]           g_count1  [0:N_SETS-1];
%000007     reg                 g_lru     [0:N_SETS-1];
        
%000001     reg [TAG_BITS-1:0] tag_patterns [0:7];
            reg [31:0]         target_patterns [0:13];
        
            bp dut (
                .clk(clk),
                .resetn(resetn),
                .if_pc(if_pc),
                .bp_predict_taken(bp_predict_taken),
                .bp_predict_target(bp_predict_target),
                .upd_valid(upd_valid),
                .upd_pc(upd_pc),
                .upd_taken(upd_taken),
                .upd_target(upd_target)
            );
        
%000000     initial begin
%000000         clk = 1'b0;
~002461         forever #5 clk = ~clk;
            end
        
 000934     function [31:0] make_pc;
                input [4:0] idx;
                input [TAG_BITS-1:0] tag;
 000934         begin
 000934             make_pc = {tag, idx, 1'b0};
                end
            endfunction
        
 002536     function [4:0] pc_idx;
                input [31:0] pc;
 002536         begin
 002536             pc_idx = pc[IDX_LSB +: IDX_BITS];
                end
            endfunction
        
 002536     function [TAG_BITS-1:0] pc_tag;
                input [31:0] pc;
 002536         begin
 002536             pc_tag = pc[31 -: TAG_BITS];
                end
            endfunction
        
 000961     function [1:0] sat_next;
                input [1:0] cur;
                input       taken;
 000961         begin
 000512             if (taken) begin
 000512                 sat_next = (cur == 2'b11) ? 2'b11 : cur + 2'd1;
 000449             end else begin
 000449                 sat_next = (cur == 2'b00) ? 2'b00 : cur - 2'd1;
                    end
                end
            endfunction
        
%000003     task model_reset;
%000003         integer j;
%000003         begin
~000096             for (j = 0; j < N_SETS; j = j + 1) begin
 000096                 g_valid0[j]  = 1'b0;
 000096                 g_valid1[j]  = 1'b0;
 000096                 g_tag0[j]    = {TAG_BITS{1'b0}};
 000096                 g_tag1[j]    = {TAG_BITS{1'b0}};
 000096                 g_target0[j] = 32'h0000_0000;
 000096                 g_target1[j] = 32'h0000_0000;
 000096                 g_count0[j]  = 2'b01;
 000096                 g_count1[j]  = 2'b01;
 000096                 g_lru[j]     = 1'b0;
                    end
                end
            endtask
        
 001218     task model_update;
                input [31:0] pc;
                input        taken;
                input [31:0] target;
 001218         reg [4:0] idx;
 001218         reg [TAG_BITS-1:0] tag;
 001218         reg hit0;
 001218         reg hit1;
 001218         reg way;
 001218         reg hit;
 001218         reg [1:0] cur;
 001218         reg [1:0] nxt;
 001218         begin
 001218             idx = pc_idx(pc);
 001218             tag = pc_tag(pc);
~001218             hit0 = g_valid0[idx] && (g_tag0[idx] == tag);
 001218             hit1 = g_valid1[idx] && (g_tag1[idx] == tag);
 001218             way = hit1 ? 1'b1 : hit0 ? 1'b0 : g_lru[idx];
 001218             hit = hit0 | hit1;
 001218             cur = way ? g_count1[idx] : g_count0[idx];
 001218             nxt = hit ? sat_next(cur, taken) : (taken ? 2'b10 : 2'b01);
        
 000832             if (way) begin
 000832                 g_valid1[idx]  = 1'b1;
 000832                 g_tag1[idx]    = tag;
 000832                 g_target1[idx] = target;
 000832                 g_count1[idx]  = nxt;
 000386             end else begin
 000386                 g_valid0[idx]  = 1'b1;
 000386                 g_tag0[idx]    = tag;
 000386                 g_target0[idx] = target;
 000386                 g_count0[idx]  = nxt;
                    end
 001218             g_lru[idx] = ~way;
                end
            endtask
        
 001318     task check_predict;
                input [31:0] pc;
                input [8*96-1:0] tag_text;
 001318         reg [4:0] idx;
 001318         reg [TAG_BITS-1:0] tag;
 001318         reg hit0;
 001318         reg hit1;
 001318         reg exp_taken;
 001318         reg [31:0] exp_target;
 001318         begin
 001318             idx = pc_idx(pc);
 001318             tag = pc_tag(pc);
 001318             hit0 = g_valid0[idx] && (g_tag0[idx] == tag);
 001318             hit1 = g_valid1[idx] && (g_tag1[idx] == tag);
 001318             exp_taken = (hit0 && g_count0[idx][1]) | (hit1 && g_count1[idx][1]);
 001318             exp_target = hit1 ? g_target1[idx] : g_target0[idx];
        
 001318             if_pc = pc;
 001318             #1;
 001318             vectors = vectors + 1;
~001318             if ((bp_predict_taken !== exp_taken) ||
                        (bp_predict_target !== exp_target)) begin
                        errors = errors + 1;
                        $error("FAIL[%0d] %0s pc=%h idx=%0d got taken=%b target=%h exp taken=%b target=%h",
                               vectors, tag_text, pc, idx, bp_predict_taken,
                               bp_predict_target, exp_taken, exp_target);
                    end
                end
            endtask
        
 001218     task drive_update;
                input [31:0] pc;
                input        taken;
                input [31:0] target;
                input [8*96-1:0] tag_text;
 001218         begin
 001218             @(negedge clk);
 001218             upd_valid  = 1'b1;
 001218             upd_pc     = pc;
 001218             upd_taken  = taken;
 001218             upd_target = target;
 001218             @(posedge clk);
 001218             #1;
 001218             model_update(pc, taken, target);
 001218             upd_valid = 1'b0;
 001218             check_predict(pc, tag_text);
                end
            endtask
        
%000002     task reset_dut;
%000002         integer j;
%000002         begin
%000002             @(negedge clk);
%000002             resetn     = 1'b0;
%000002             if_pc      = 32'h0000_0000;
%000002             upd_valid  = 1'b0;
%000002             upd_pc     = 32'h0000_0000;
%000002             upd_taken  = 1'b0;
%000002             upd_target = 32'h0000_0000;
%000002             model_reset();
%000004             repeat (2) @(posedge clk);
%000002             #1;
~000064             for (j = 0; j < N_SETS; j = j + 1) begin
 000064                 check_predict(make_pc(j[4:0], {TAG_BITS{1'b0}}), "reset valid-clear miss");
                    end
%000002             @(negedge clk);
%000002             resetn = 1'b1;
%000002             @(posedge clk);
%000002             #1;
%000002             check_predict(make_pc(5'd0, {TAG_BITS{1'b0}}), "post-reset miss");
                end
            endtask
        
 000064     task train_counter_all_states;
                input [31:0] pc;
                input [31:0] target_base;
 000064         begin
 000064             drive_update(pc, 1'b0, target_base ^ 32'h0000_0001, "counter weak-not to strong-not");
 000064             drive_update(pc, 1'b0, target_base ^ 32'h0000_0002, "counter strong-not saturate");
 000064             drive_update(pc, 1'b1, target_base ^ 32'h0000_0004, "counter strong-not to weak-not");
 000064             drive_update(pc, 1'b1, target_base ^ 32'h0000_0008, "counter weak-not to weak-taken");
 000064             drive_update(pc, 1'b1, target_base ^ 32'h0000_0010, "counter weak-taken to strong-taken");
 000064             drive_update(pc, 1'b1, target_base ^ 32'h0000_0020, "counter strong-taken saturate");
 000064             drive_update(pc, 1'b0, target_base ^ 32'h0000_0040, "counter strong-taken to weak-taken");
                end
            endtask
        
%000001     initial begin
%000001         vectors = 0;
%000001         errors = 0;
%000001         resetn = 1'b1;
%000001         if_pc = 32'h0000_0000;
%000001         upd_valid = 1'b0;
%000001         upd_pc = 32'h0000_0000;
%000001         upd_taken = 1'b0;
%000001         upd_target = 32'h0000_0000;
        
%000001         tag_patterns[0] = {TAG_BITS{1'b0}};
%000001         tag_patterns[1] = {TAG_BITS{1'b1}};
%000001         tag_patterns[2] = {{(TAG_BITS-1){1'b0}}, 1'b1};
%000001         tag_patterns[3] = {1'b1, {(TAG_BITS-1){1'b0}}};
%000001         tag_patterns[4] = 26'h2AAAAAA;
%000001         tag_patterns[5] = 26'h1555555;
%000001         tag_patterns[6] = 26'h3FFFFFC;
%000001         tag_patterns[7] = 26'h37AB6FB;
        
%000001         target_patterns[0]  = 32'h0000_0000;
%000001         target_patterns[1]  = 32'hFFFF_FFFC;
%000001         target_patterns[2]  = 32'hDEAD_BEEF;
%000001         target_patterns[3]  = 32'hAAAA_AAAA;
%000001         target_patterns[4]  = 32'h5555_5555;
%000001         target_patterns[5]  = 32'h8000_0000;
%000001         target_patterns[6]  = 32'h7FFF_FFFC;
%000001         target_patterns[7]  = 32'h0000_0001;
%000001         target_patterns[8]  = 32'h0000_0002;
%000001         target_patterns[9]  = 32'h0000_0004;
%000001         target_patterns[10] = 32'h0000_0008;
%000001         target_patterns[11] = 32'h0000_0010;
%000001         target_patterns[12] = 32'h0000_0020;
%000001         target_patterns[13] = 32'hFFFF_FFFB;
        
%000001         model_reset();
%000001         reset_dut();
        
~000032         for (set_i = 0; set_i < N_SETS; set_i = set_i + 1) begin
 000032             drive_update(make_pc(set_i[4:0], tag_patterns[0] ^ set_i[TAG_BITS-1:0]),
 000032                          1'b1, 32'h1000_0000 ^ set_i, "cold miss fills way0 taken");
 000032             drive_update(make_pc(set_i[4:0], tag_patterns[1] ^ set_i[TAG_BITS-1:0]),
 000032                          1'b0, 32'h2000_0000 ^ (set_i << 8), "cold miss fills way1 not-taken");
        
 000032             train_counter_all_states(make_pc(set_i[4:0], tag_patterns[0] ^ set_i[TAG_BITS-1:0]),
 000032                                      32'h3000_0000 ^ (set_i << 4));
 000032             train_counter_all_states(make_pc(set_i[4:0], tag_patterns[1] ^ set_i[TAG_BITS-1:0]),
 000032                                      32'h4000_0000 ^ (set_i << 4));
        
 000256             for (pat_i = 0; pat_i < 8; pat_i = pat_i + 1) begin
 000256                 drive_update(make_pc(set_i[4:0], tag_patterns[pat_i] ^ {21'h0, set_i[4:0]}),
 000256                              pat_i[0],
 000256                              target_patterns[pat_i] ^ {set_i[15:0], set_i[15:0]},
 000256                              "alternate LRU miss writes full tag/target");
                    end
        
 000448             for (pat_i = 0; pat_i < 14; pat_i = pat_i + 1) begin
 000448                 drive_update(make_pc(set_i[4:0], tag_patterns[7] ^ {21'h0, set_i[4:0]}),
 000448                              pat_i[0],
 000448                              target_patterns[pat_i],
 000448                              "hit update walks full target bits");
                    end
        
 000032             check_predict(make_pc(set_i[4:0], 26'h0123456),
 000032                           "same-set tag miss returns way0 target");
                end
        
                // Bit 0 is ignored by the implemented index/tag slices, but it is a
                // real unit input port. Toggle it through legal predictor operations.
%000001         drive_update(make_pc(5'd0, 26'h00FACE0) | 32'h0000_0001,
%000001                      1'b1, 32'hCAF0_0001, "ignored update pc bit0 high");
%000001         drive_update(make_pc(5'd0, 26'h00FACE0),
%000001                      1'b0, 32'hCAF0_0000, "ignored update pc bit0 low");
%000001         check_predict(make_pc(5'd1, 26'h00BAD00) | 32'h0000_0001,
%000001                       "ignored predict pc bit0 high");
%000001         check_predict(make_pc(5'd1, 26'h00BAD00),
%000001                       "ignored predict pc bit0 low");
        
                // A final reset is the only RTL path that clears valid bits after set.
%000001         reset_dut();
        
%000001         if (errors == 0) begin
%000001             $display("PASS: bp unit %0d/%0d vectors", vectors, vectors);
                end else begin
                    $display("FAIL: bp unit %0d errors in %0d vectors", errors, vectors);
                    $fatal(1);
                end
%000001         $finish;
            end
        endmodule
        
