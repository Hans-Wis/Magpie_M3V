`default_nettype none
`timescale 1ns/1ps

module tb_npu_dma_width;
    parameter integer DMA_DATA_W = 64;
    parameter integer LEN_WORDS = 64;
    localparam integer WPB = DMA_DATA_W / 32;
    localparam integer EXP_SIZE = $clog2(DMA_DATA_W / 8);

    reg clk = 1'b0;
    reg resetn = 1'b0;
    always #5 clk = ~clk;

    reg go = 1'b0;
    reg write_mode = 1'b0;
    reg narrow = 1'b0;
    reg [31:0] src_addr = 32'h0;
    reg [7:0] dst_word = 8'h0;
    reg [16:0] len_beats = LEN_WORDS[16:0];
    wire busy, done, err;

    wire m_arvalid, m_arready, m_rvalid, m_rready, m_rlast;
    wire [31:0] m_araddr;
    wire [7:0] m_arlen;
    wire [2:0] m_arsize;
    wire [1:0] m_arburst, m_rresp;
    wire [DMA_DATA_W-1:0] m_rdata;
    wire m_awvalid, m_awready, m_wvalid, m_wready, m_wlast, m_bvalid, m_bready;
    wire [31:0] m_awaddr;
    wire [7:0] m_awlen;
    wire [2:0] m_awsize;
    wire [1:0] m_awburst, m_bresp;
    wire [DMA_DATA_W-1:0] m_wdata;
    wire [DMA_DATA_W/8-1:0] m_wstrb;

    wire dma_we;
    wire [7:0] dma_waddr;
    wire [DMA_DATA_W-1:0] dma_wdata;
    wire dma_re;
    wire [7:0] dma_raddr;
    wire [DMA_DATA_W-1:0] dma_rdata;

    npu_dma #(.BUF_AW(8), .DMA_DATA_W(DMA_DATA_W)) dut (
        .clk(clk), .resetn(resetn),
        .go(go), .abort_i(1'b0), .write_mode(write_mode), .narrow_i(narrow),
        .src_addr(src_addr), .dst_word(dst_word), .len_beats(len_beats),
        .busy(busy), .done(done), .err(err),
        .m_arvalid(m_arvalid), .m_arready(m_arready), .m_araddr(m_araddr), .m_arlen(m_arlen),
        .m_arsize(m_arsize), .m_arburst(m_arburst),
        .m_rvalid(m_rvalid), .m_rready(m_rready), .m_rdata(m_rdata), .m_rlast(m_rlast), .m_rresp(m_rresp),
        .m_awvalid(m_awvalid), .m_awready(m_awready), .m_awaddr(m_awaddr), .m_awlen(m_awlen),
        .m_awsize(m_awsize), .m_awburst(m_awburst),
        .m_wvalid(m_wvalid), .m_wready(m_wready), .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wlast(m_wlast),
        .m_bvalid(m_bvalid), .m_bready(m_bready), .m_bresp(m_bresp),
        .buf_we(dma_we), .buf_addr(dma_waddr), .buf_wdata(dma_wdata),
        .buf_re(dma_re), .buf_raddr(dma_raddr), .buf_rdata(dma_rdata)
    );

    axi_full_mem #(.WORDS(1024), .DMA_DATA_W(DMA_DATA_W)) src_mem (
        .clk(clk), .resetn(resetn),
        .arvalid(m_arvalid), .arready(m_arready), .araddr(m_araddr),
        .arlen(m_arlen), .arsize(m_arsize), .arburst(m_arburst),
        .rvalid(m_rvalid), .rready(m_rready), .rdata(m_rdata), .rlast(m_rlast), .rresp(m_rresp)
    );
    axi_full_wmem #(.WORDS(1024), .AW(10), .DMA_DATA_W(DMA_DATA_W), .ERR_MODE(0)) dst_mem (
        .clk(clk), .resetn(resetn),
        .awvalid(m_awvalid), .awready(m_awready), .awaddr(m_awaddr),
        .awlen(m_awlen), .awsize(m_awsize), .awburst(m_awburst),
        .wvalid(m_wvalid), .wready(m_wready), .wdata(m_wdata), .wstrb(m_wstrb), .wlast(m_wlast),
        .bvalid(m_bvalid), .bready(m_bready), .bresp(m_bresp)
    );

    npu_tcm #(.WORDS(256), .AW(8), .DMA_DATA_W(DMA_DATA_W)) tcm (
        .clk(clk), .resetn(resetn),
        .s_axi_awvalid(1'b0), .s_axi_awready(), .s_axi_awaddr(32'b0), .s_axi_awprot(3'b0),
        .s_axi_wvalid(1'b0), .s_axi_wready(), .s_axi_wdata(32'b0), .s_axi_wstrb(4'b0),
        .s_axi_bvalid(), .s_axi_bready(1'b0), .s_axi_bresp(),
        .s_axi_arvalid(1'b0), .s_axi_arready(), .s_axi_araddr(32'b0), .s_axi_arprot(3'b0),
        .s_axi_rvalid(), .s_axi_rready(1'b0), .s_axi_rdata(), .s_axi_rresp(),
        .dma_narrow(narrow),
        .dma_we(dma_we), .dma_waddr(dma_waddr), .dma_wdata(dma_wdata),
        .dma_re(dma_re), .dma_raddr(dma_raddr), .dma_rdata(dma_rdata),
        .eng_a_re(1'b0), .eng_b_re(1'b0),
        .eng_a_addr(8'b0), .eng_a_rdata(),
        .eng_b_addr(8'b0), .eng_b_rdata(),
        .eng_we(1'b0), .eng_waddr(8'b0), .eng_wdata(32'b0),
        .core_d_re(1'b0), .core_d_addr(8'b0), .core_d_rdata(),
        .core_d_we(1'b0), .core_d_wdata(32'b0), .core_d_wstrb(4'b0), .core_d_wgrant()
    );

    integer errors = 0;
    integer i;
    integer guard;
    integer ar_count = 0;
    integer rbeat_count = 0;
    reg [2:0] arsize_seen = 3'b0;
    integer aw_count = 0;
    integer wbeat_count = 0;
    reg [2:0] awsize_seen = 3'b0;
    localparam [31:0] STORE_DST = 32'h0000_0100;
    localparam integer STORE_DST_W = 32'h0000_0100 >> 2;
    localparam [31:0] NARROW_SRC = 32'h0000_0004;
    localparam [31:0] NARROW_DST = 32'h0000_0104;
    localparam integer NARROW_SRC_W = 32'h0000_0004 >> 2;
    localparam integer NARROW_DST_W = 32'h0000_0104 >> 2;
    localparam integer NARROW_TCM_W = 128;
    localparam integer NARROW_LEN = LEN_WORDS - 1;
    wire [DMA_DATA_W/8-1:0] full_wstrb = {(DMA_DATA_W/8){1'b1}};
    wire [31:0] narrow_store_lane = NARROW_DST_W % WPB;
    reg check_narrow_wstrb = 1'b0;

    function [DMA_DATA_W/8-1:0] one_lane_wstrb;
        input [31:0] lane;
        integer j;
        begin
            one_lane_wstrb = {(DMA_DATA_W/8){1'b0}};
            for (j = 0; j < WPB; j = j + 1)
                if (lane == j[31:0])
                    one_lane_wstrb[j*4 +: 4] = 4'hf;
        end
    endfunction

    function [31:0] src_pattern;
        input integer word_idx;
        begin
            src_pattern = 32'hC0DE0000 | (word_idx & 32'h0000FFFF);
        end
    endfunction

    always @(posedge clk) begin
        if (m_arvalid && m_arready) begin
            ar_count = ar_count + 1;
            arsize_seen = m_arsize;
        end
        if (m_rvalid && m_rready)
            rbeat_count = rbeat_count + 1;
        if (m_awvalid && m_awready) begin
            aw_count = aw_count + 1;
            awsize_seen = m_awsize;
        end
        if (m_wvalid && m_wready) begin
            wbeat_count = wbeat_count + 1;
            if (check_narrow_wstrb && (m_wstrb !== one_lane_wstrb(narrow_store_lane))) begin
                errors = errors + 1;
                $display("WIDTH_FAIL narrow wstrb got=%0h exp=%0h",
                         m_wstrb, one_lane_wstrb(narrow_store_lane));
            end else if (!check_narrow_wstrb && (m_wstrb !== full_wstrb)) begin
                errors = errors + 1;
                $display("WIDTH_FAIL wstrb got=%0h exp=%0h", m_wstrb, full_wstrb);
            end
        end
    end

    task pulse_go;
        begin
            @(negedge clk);
            go = 1'b1;
            @(negedge clk);
            go = 1'b0;
        end
    endtask

    initial begin
        repeat (4) @(posedge clk);
        resetn = 1'b1;
        @(posedge clk);

        write_mode = 1'b0;
        narrow = 1'b0;
        src_addr = 32'h0;
        dst_word = 8'h0;
        len_beats = LEN_WORDS[16:0];
        pulse_go();

        guard = 0;
        while (!done && guard < 2000) begin
            @(posedge clk);
            guard = guard + 1;
        end
        if (!done) begin errors = errors + 1; $display("WIDTH_FAIL timeout"); end
        if (err) begin errors = errors + 1; $display("WIDTH_FAIL unexpected err"); end
        if (arsize_seen !== EXP_SIZE[2:0]) begin
            errors = errors + 1;
            $display("WIDTH_FAIL arsize got=%0d exp=%0d", arsize_seen, EXP_SIZE);
        end
        if (rbeat_count !== (LEN_WORDS / WPB)) begin
            errors = errors + 1;
            $display("WIDTH_FAIL rbeats got=%0d exp=%0d", rbeat_count, (LEN_WORDS / WPB));
        end
        for (i = 0; i < LEN_WORDS; i = i + 1) begin
            if (tcm.mem[i] !== (32'hC0DE0000 | {16'b0, i[15:0]})) begin
                errors = errors + 1;
                if (errors < 8) $display("WIDTH_FAIL tcm[%0d]=%08x", i, tcm.mem[i]);
            end
        end
        if (errors == 0)
            $display("WIDTH_ALIGNED_PASS width=%0d arsize=%0d rbeats=%0d ar_count=%0d",
                     DMA_DATA_W, arsize_seen, rbeat_count, ar_count);

        write_mode = 1'b0;
        narrow = 1'b0;
        src_addr = 32'h0;
        dst_word = 8'h0;
        len_beats = (LEN_WORDS - 1);
        ar_count = 0;
        rbeat_count = 0;
        pulse_go();
        repeat (8) @(posedge clk);
        if (!done || !err || ar_count != 0 || rbeat_count != 0) begin
            errors = errors + 1;
            $display("WIDTH_FAIL align_err done=%0b err=%0b ar=%0d r=%0d",
                     done, err, ar_count, rbeat_count);
        end else begin
            $display("WIDTH_ERR_ALIGN_PASS width=%0d", DMA_DATA_W);
        end

        write_mode = 1'b1;
        narrow = 1'b0;
        src_addr = STORE_DST;
        dst_word = 8'h0;
        len_beats = LEN_WORDS[16:0];
        aw_count = 0;
        wbeat_count = 0;
        pulse_go();

        guard = 0;
        while (!done && guard < 2000) begin
            @(posedge clk);
            guard = guard + 1;
        end
        if (!done) begin errors = errors + 1; $display("WIDTH_FAIL store timeout"); end
        if (err) begin errors = errors + 1; $display("WIDTH_FAIL unexpected store err"); end
        if (awsize_seen !== EXP_SIZE[2:0]) begin
            errors = errors + 1;
            $display("WIDTH_FAIL awsize got=%0d exp=%0d", awsize_seen, EXP_SIZE);
        end
        if (wbeat_count !== (LEN_WORDS / WPB)) begin
            errors = errors + 1;
            $display("WIDTH_FAIL wbeats got=%0d exp=%0d", wbeat_count, (LEN_WORDS / WPB));
        end
        if (aw_count !== 1) begin
            errors = errors + 1;
            $display("WIDTH_FAIL aw_count got=%0d exp=1", aw_count);
        end
        for (i = 0; i < LEN_WORDS; i = i + 1) begin
            if (dst_mem.mem[STORE_DST_W + i] !== (32'hC0DE0000 | {16'b0, i[15:0]})) begin
                errors = errors + 1;
                if (errors < 8) $display("WIDTH_FAIL store mem[%0d]=%08x",
                                          STORE_DST_W + i, dst_mem.mem[STORE_DST_W + i]);
            end
        end
        if (errors == 0)
            $display("WIDTH_STORE_PASS width=%0d awsize=%0d wbeats=%0d aw_count=%0d",
                     DMA_DATA_W, awsize_seen, wbeat_count, aw_count);

        write_mode = 1'b1;
        narrow = 1'b0;
        src_addr = STORE_DST + 32'd4;
        dst_word = 8'h0;
        len_beats = LEN_WORDS[16:0];
        aw_count = 0;
        wbeat_count = 0;
        pulse_go();
        repeat (8) @(posedge clk);
        if (WPB != 1 && (!done || !err || aw_count != 0 || wbeat_count != 0)) begin
            errors = errors + 1;
            $display("WIDTH_FAIL store_align_err done=%0b err=%0b aw=%0d w=%0d",
                     done, err, aw_count, wbeat_count);
        end else if (WPB != 1) begin
            $display("WIDTH_STORE_ERR_ALIGN_PASS width=%0d", DMA_DATA_W);
        end

        if (DMA_DATA_W == 256) begin
            write_mode = 1'b0;
            narrow = 1'b1;
            src_addr = NARROW_SRC;
            dst_word = NARROW_TCM_W[7:0];
            len_beats = NARROW_LEN[16:0];
            ar_count = 0;
            rbeat_count = 0;
            arsize_seen = 3'b0;
            pulse_go();

            guard = 0;
            while (!done && guard < 2000) begin
                @(posedge clk);
                guard = guard + 1;
            end
            if (!done) begin errors = errors + 1; $display("WIDTH_FAIL narrow read timeout"); end
            if (err) begin errors = errors + 1; $display("WIDTH_FAIL narrow read unexpected err"); end
            if (arsize_seen !== 3'd2) begin
                errors = errors + 1;
                $display("WIDTH_FAIL narrow arsize got=%0d exp=2", arsize_seen);
            end
            if (rbeat_count !== NARROW_LEN) begin
                errors = errors + 1;
                $display("WIDTH_FAIL narrow rbeats got=%0d exp=%0d", rbeat_count, NARROW_LEN);
            end
            for (i = 0; i < NARROW_LEN; i = i + 1) begin
                if (tcm.mem[NARROW_TCM_W + i] !== src_pattern(NARROW_SRC_W + i)) begin
                    errors = errors + 1;
                    if (errors < 8) $display("WIDTH_FAIL narrow tcm[%0d]=%08x exp=%08x",
                                              NARROW_TCM_W + i, tcm.mem[NARROW_TCM_W + i],
                                              src_pattern(NARROW_SRC_W + i));
                end
            end

            write_mode = 1'b1;
            narrow = 1'b1;
            src_addr = NARROW_DST;
            dst_word = NARROW_TCM_W[7:0];
            len_beats = NARROW_LEN[16:0];
            aw_count = 0;
            wbeat_count = 0;
            awsize_seen = 3'b0;
            check_narrow_wstrb = 1'b1;
            pulse_go();

            guard = 0;
            while (!done && guard < 2000) begin
                @(posedge clk);
                guard = guard + 1;
            end
            check_narrow_wstrb = 1'b0;
            if (!done) begin errors = errors + 1; $display("WIDTH_FAIL narrow store timeout"); end
            if (err) begin errors = errors + 1; $display("WIDTH_FAIL narrow store unexpected err"); end
            if (awsize_seen !== 3'd2) begin
                errors = errors + 1;
                $display("WIDTH_FAIL narrow awsize got=%0d exp=2", awsize_seen);
            end
            if (wbeat_count !== NARROW_LEN) begin
                errors = errors + 1;
                $display("WIDTH_FAIL narrow wbeats got=%0d exp=%0d", wbeat_count, NARROW_LEN);
            end
            for (i = 0; i < NARROW_LEN; i = i + 1) begin
                if (dst_mem.mem[NARROW_DST_W + i] !== tcm.mem[NARROW_TCM_W + i]) begin
                    errors = errors + 1;
                    if (errors < 8) $display("WIDTH_FAIL narrow store mem[%0d]=%08x tcm=%08x",
                                              NARROW_DST_W + i, dst_mem.mem[NARROW_DST_W + i],
                                              tcm.mem[NARROW_TCM_W + i]);
                end
            end
            if (errors == 0)
                $display("WIDTH_NARROW_PASS width=%0d arsize=%0d awsize=%0d rbeats=%0d wbeats=%0d wstrb=%0h",
                         DMA_DATA_W, arsize_seen, awsize_seen, rbeat_count, wbeat_count,
                         one_lane_wstrb(narrow_store_lane));
        end

        if (errors == 0) $display("NPU_DMA_WIDTH_PASS width=%0d", DMA_DATA_W);
        else             $display("NPU_DMA_WIDTH_FAIL width=%0d errors=%0d", DMA_DATA_W, errors);
        $finish;
    end

    initial begin
        #200000;
        $display("NPU_DMA_WIDTH_FAIL timeout width=%0d", DMA_DATA_W);
        $finish;
    end
endmodule
`default_nettype wire
