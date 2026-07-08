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

    wire dma_we;
    wire [7:0] dma_waddr;
    wire [DMA_DATA_W-1:0] dma_wdata;
    wire dma_re;
    wire [7:0] dma_raddr;
    wire [31:0] dma_rdata;

    npu_dma #(.BUF_AW(8), .DMA_DATA_W(DMA_DATA_W)) dut (
        .clk(clk), .resetn(resetn),
        .go(go), .abort_i(1'b0), .write_mode(1'b0),
        .src_addr(src_addr), .dst_word(dst_word), .len_beats(len_beats),
        .busy(busy), .done(done), .err(err),
        .m_arvalid(m_arvalid), .m_arready(m_arready), .m_araddr(m_araddr), .m_arlen(m_arlen),
        .m_arsize(m_arsize), .m_arburst(m_arburst),
        .m_rvalid(m_rvalid), .m_rready(m_rready), .m_rdata(m_rdata), .m_rlast(m_rlast), .m_rresp(m_rresp),
        .m_awvalid(), .m_awready(1'b0), .m_awaddr(), .m_awlen(), .m_awsize(), .m_awburst(),
        .m_wvalid(), .m_wready(1'b0), .m_wdata(), .m_wstrb(), .m_wlast(),
        .m_bvalid(1'b0), .m_bready(), .m_bresp(2'b0),
        .buf_we(dma_we), .buf_addr(dma_waddr), .buf_wdata(dma_wdata),
        .buf_re(dma_re), .buf_raddr(dma_raddr), .buf_rdata(dma_rdata)
    );

    axi_full_mem #(.WORDS(1024), .DMA_DATA_W(DMA_DATA_W)) src_mem (
        .clk(clk), .resetn(resetn),
        .arvalid(m_arvalid), .arready(m_arready), .araddr(m_araddr),
        .arlen(m_arlen), .arsize(m_arsize), .arburst(m_arburst),
        .rvalid(m_rvalid), .rready(m_rready), .rdata(m_rdata), .rlast(m_rlast), .rresp(m_rresp)
    );

    npu_tcm #(.WORDS(256), .AW(8), .DMA_DATA_W(DMA_DATA_W)) tcm (
        .clk(clk), .resetn(resetn),
        .s_axi_awvalid(1'b0), .s_axi_awready(), .s_axi_awaddr(32'b0), .s_axi_awprot(3'b0),
        .s_axi_wvalid(1'b0), .s_axi_wready(), .s_axi_wdata(32'b0), .s_axi_wstrb(4'b0),
        .s_axi_bvalid(), .s_axi_bready(1'b0), .s_axi_bresp(),
        .s_axi_arvalid(1'b0), .s_axi_arready(), .s_axi_araddr(32'b0), .s_axi_arprot(3'b0),
        .s_axi_rvalid(), .s_axi_rready(1'b0), .s_axi_rdata(), .s_axi_rresp(),
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

    always @(posedge clk) begin
        if (m_arvalid && m_arready) begin
            ar_count = ar_count + 1;
            arsize_seen = m_arsize;
        end
        if (m_rvalid && m_rready)
            rbeat_count = rbeat_count + 1;
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
