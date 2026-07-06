`timescale 1ns/1ps

module tb_bp_unit;
    localparam IDX_BITS = 5;
    localparam IDX_LSB  = 1;
    localparam TAG_BITS = 32 - (IDX_LSB + IDX_BITS);
    localparam N_SETS   = 1 << IDX_BITS;

    reg         clk;
    reg         resetn;
    reg  [31:0] if_pc;
    wire        bp_predict_taken;
    wire [31:0] bp_predict_target;
    reg         upd_valid;
    reg  [31:0] upd_pc;
    reg         upd_taken;
    reg  [31:0] upd_target;

    integer vectors;
    integer errors;
    integer set_i;
    integer pat_i;

    reg                 g_valid0  [0:N_SETS-1];
    reg [TAG_BITS-1:0]  g_tag0    [0:N_SETS-1];
    reg [31:0]          g_target0 [0:N_SETS-1];
    reg [1:0]           g_count0  [0:N_SETS-1];
    reg                 g_valid1  [0:N_SETS-1];
    reg [TAG_BITS-1:0]  g_tag1    [0:N_SETS-1];
    reg [31:0]          g_target1 [0:N_SETS-1];
    reg [1:0]           g_count1  [0:N_SETS-1];
    reg                 g_lru     [0:N_SETS-1];

    reg [TAG_BITS-1:0] tag_patterns [0:7];
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

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    function [31:0] make_pc;
        input [4:0] idx;
        input [TAG_BITS-1:0] tag;
        begin
            make_pc = {tag, idx, 1'b0};
        end
    endfunction

    function [4:0] pc_idx;
        input [31:0] pc;
        begin
            pc_idx = pc[IDX_LSB +: IDX_BITS];
        end
    endfunction

    function [TAG_BITS-1:0] pc_tag;
        input [31:0] pc;
        begin
            pc_tag = pc[31 -: TAG_BITS];
        end
    endfunction

    function [1:0] sat_next;
        input [1:0] cur;
        input       taken;
        begin
            if (taken) begin
                sat_next = (cur == 2'b11) ? 2'b11 : cur + 2'd1;
            end else begin
                sat_next = (cur == 2'b00) ? 2'b00 : cur - 2'd1;
            end
        end
    endfunction

    task model_reset;
        integer j;
        begin
            for (j = 0; j < N_SETS; j = j + 1) begin
                g_valid0[j]  = 1'b0;
                g_valid1[j]  = 1'b0;
                g_tag0[j]    = {TAG_BITS{1'b0}};
                g_tag1[j]    = {TAG_BITS{1'b0}};
                g_target0[j] = 32'h0000_0000;
                g_target1[j] = 32'h0000_0000;
                g_count0[j]  = 2'b01;
                g_count1[j]  = 2'b01;
                g_lru[j]     = 1'b0;
            end
        end
    endtask

    task model_update;
        input [31:0] pc;
        input        taken;
        input [31:0] target;
        reg [4:0] idx;
        reg [TAG_BITS-1:0] tag;
        reg hit0;
        reg hit1;
        reg way;
        reg hit;
        reg [1:0] cur;
        reg [1:0] nxt;
        begin
            idx = pc_idx(pc);
            tag = pc_tag(pc);
            hit0 = g_valid0[idx] && (g_tag0[idx] == tag);
            hit1 = g_valid1[idx] && (g_tag1[idx] == tag);
            way = hit1 ? 1'b1 : hit0 ? 1'b0 : g_lru[idx];
            hit = hit0 | hit1;
            cur = way ? g_count1[idx] : g_count0[idx];
            nxt = hit ? sat_next(cur, taken) : (taken ? 2'b10 : 2'b01);

            if (way) begin
                g_valid1[idx]  = 1'b1;
                g_tag1[idx]    = tag;
                g_target1[idx] = target;
                g_count1[idx]  = nxt;
            end else begin
                g_valid0[idx]  = 1'b1;
                g_tag0[idx]    = tag;
                g_target0[idx] = target;
                g_count0[idx]  = nxt;
            end
            g_lru[idx] = ~way;
        end
    endtask

    task check_predict;
        input [31:0] pc;
        input [8*96-1:0] tag_text;
        reg [4:0] idx;
        reg [TAG_BITS-1:0] tag;
        reg hit0;
        reg hit1;
        reg exp_taken;
        reg [31:0] exp_target;
        begin
            idx = pc_idx(pc);
            tag = pc_tag(pc);
            hit0 = g_valid0[idx] && (g_tag0[idx] == tag);
            hit1 = g_valid1[idx] && (g_tag1[idx] == tag);
            exp_taken = (hit0 && g_count0[idx][1]) | (hit1 && g_count1[idx][1]);
            exp_target = hit1 ? g_target1[idx] : g_target0[idx];

            if_pc = pc;
            #1;
            vectors = vectors + 1;
            if ((bp_predict_taken !== exp_taken) ||
                (bp_predict_target !== exp_target)) begin
                errors = errors + 1;
                $error("FAIL[%0d] %0s pc=%h idx=%0d got taken=%b target=%h exp taken=%b target=%h",
                       vectors, tag_text, pc, idx, bp_predict_taken,
                       bp_predict_target, exp_taken, exp_target);
            end
        end
    endtask

    task drive_update;
        input [31:0] pc;
        input        taken;
        input [31:0] target;
        input [8*96-1:0] tag_text;
        begin
            @(negedge clk);
            upd_valid  = 1'b1;
            upd_pc     = pc;
            upd_taken  = taken;
            upd_target = target;
            @(posedge clk);
            #1;
            model_update(pc, taken, target);
            upd_valid = 1'b0;
            check_predict(pc, tag_text);
        end
    endtask

    task reset_dut;
        integer j;
        begin
            @(negedge clk);
            resetn     = 1'b0;
            if_pc      = 32'h0000_0000;
            upd_valid  = 1'b0;
            upd_pc     = 32'h0000_0000;
            upd_taken  = 1'b0;
            upd_target = 32'h0000_0000;
            model_reset();
            repeat (2) @(posedge clk);
            #1;
            for (j = 0; j < N_SETS; j = j + 1) begin
                check_predict(make_pc(j[4:0], {TAG_BITS{1'b0}}), "reset valid-clear miss");
            end
            @(negedge clk);
            resetn = 1'b1;
            @(posedge clk);
            #1;
            check_predict(make_pc(5'd0, {TAG_BITS{1'b0}}), "post-reset miss");
        end
    endtask

    task train_counter_all_states;
        input [31:0] pc;
        input [31:0] target_base;
        begin
            drive_update(pc, 1'b0, target_base ^ 32'h0000_0001, "counter weak-not to strong-not");
            drive_update(pc, 1'b0, target_base ^ 32'h0000_0002, "counter strong-not saturate");
            drive_update(pc, 1'b1, target_base ^ 32'h0000_0004, "counter strong-not to weak-not");
            drive_update(pc, 1'b1, target_base ^ 32'h0000_0008, "counter weak-not to weak-taken");
            drive_update(pc, 1'b1, target_base ^ 32'h0000_0010, "counter weak-taken to strong-taken");
            drive_update(pc, 1'b1, target_base ^ 32'h0000_0020, "counter strong-taken saturate");
            drive_update(pc, 1'b0, target_base ^ 32'h0000_0040, "counter strong-taken to weak-taken");
        end
    endtask

    initial begin
        vectors = 0;
        errors = 0;
        resetn = 1'b1;
        if_pc = 32'h0000_0000;
        upd_valid = 1'b0;
        upd_pc = 32'h0000_0000;
        upd_taken = 1'b0;
        upd_target = 32'h0000_0000;

        tag_patterns[0] = {TAG_BITS{1'b0}};
        tag_patterns[1] = {TAG_BITS{1'b1}};
        tag_patterns[2] = {{(TAG_BITS-1){1'b0}}, 1'b1};
        tag_patterns[3] = {1'b1, {(TAG_BITS-1){1'b0}}};
        tag_patterns[4] = 26'h2AAAAAA;
        tag_patterns[5] = 26'h1555555;
        tag_patterns[6] = 26'h3FFFFFC;
        tag_patterns[7] = 26'h37AB6FB;

        target_patterns[0]  = 32'h0000_0000;
        target_patterns[1]  = 32'hFFFF_FFFC;
        target_patterns[2]  = 32'hDEAD_BEEF;
        target_patterns[3]  = 32'hAAAA_AAAA;
        target_patterns[4]  = 32'h5555_5555;
        target_patterns[5]  = 32'h8000_0000;
        target_patterns[6]  = 32'h7FFF_FFFC;
        target_patterns[7]  = 32'h0000_0001;
        target_patterns[8]  = 32'h0000_0002;
        target_patterns[9]  = 32'h0000_0004;
        target_patterns[10] = 32'h0000_0008;
        target_patterns[11] = 32'h0000_0010;
        target_patterns[12] = 32'h0000_0020;
        target_patterns[13] = 32'hFFFF_FFFB;

        model_reset();
        reset_dut();

        for (set_i = 0; set_i < N_SETS; set_i = set_i + 1) begin
            drive_update(make_pc(set_i[4:0], tag_patterns[0] ^ set_i[TAG_BITS-1:0]),
                         1'b1, 32'h1000_0000 ^ set_i, "cold miss fills way0 taken");
            drive_update(make_pc(set_i[4:0], tag_patterns[1] ^ set_i[TAG_BITS-1:0]),
                         1'b0, 32'h2000_0000 ^ (set_i << 8), "cold miss fills way1 not-taken");

            train_counter_all_states(make_pc(set_i[4:0], tag_patterns[0] ^ set_i[TAG_BITS-1:0]),
                                     32'h3000_0000 ^ (set_i << 4));
            train_counter_all_states(make_pc(set_i[4:0], tag_patterns[1] ^ set_i[TAG_BITS-1:0]),
                                     32'h4000_0000 ^ (set_i << 4));

            for (pat_i = 0; pat_i < 8; pat_i = pat_i + 1) begin
                drive_update(make_pc(set_i[4:0], tag_patterns[pat_i] ^ {21'h0, set_i[4:0]}),
                             pat_i[0],
                             target_patterns[pat_i] ^ {set_i[15:0], set_i[15:0]},
                             "alternate LRU miss writes full tag/target");
            end

            for (pat_i = 0; pat_i < 14; pat_i = pat_i + 1) begin
                drive_update(make_pc(set_i[4:0], tag_patterns[7] ^ {21'h0, set_i[4:0]}),
                             pat_i[0],
                             target_patterns[pat_i],
                             "hit update walks full target bits");
            end

            check_predict(make_pc(set_i[4:0], 26'h0123456),
                          "same-set tag miss returns way0 target");
        end

        // Bit 0 is ignored by the implemented index/tag slices, but it is a
        // real unit input port. Toggle it through legal predictor operations.
        drive_update(make_pc(5'd0, 26'h00FACE0) | 32'h0000_0001,
                     1'b1, 32'hCAF0_0001, "ignored update pc bit0 high");
        drive_update(make_pc(5'd0, 26'h00FACE0),
                     1'b0, 32'hCAF0_0000, "ignored update pc bit0 low");
        check_predict(make_pc(5'd1, 26'h00BAD00) | 32'h0000_0001,
                      "ignored predict pc bit0 high");
        check_predict(make_pc(5'd1, 26'h00BAD00),
                      "ignored predict pc bit0 low");

        // A final reset is the only RTL path that clears valid bits after set.
        reset_dut();

        if (errors == 0) begin
            $display("PASS: bp unit %0d/%0d vectors", vectors, vectors);
        end else begin
            $display("FAIL: bp unit %0d errors in %0d vectors", errors, vectors);
            $fatal(1);
        end
        $finish;
    end
endmodule
