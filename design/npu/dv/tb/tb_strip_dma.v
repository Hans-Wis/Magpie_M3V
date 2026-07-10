`default_nettype none
`timescale 1ns/1ps

module tb_strip_dma;
    localparam integer DMA_DATA_W = 128;
    localparam integer AXI_BYTES  = DMA_DATA_W / 8;
    localparam integer DDR_AW     = 17;
    localparam integer DDR_WORDS  = 131072;
    localparam integer DDR_BYTES  = DDR_WORDS * 4;

    localparam [31:0] BASE_40K_C3  = 32'h0000_0000;
    localparam [31:0] BASE_4K      = 32'h0001_0000;
    localparam [31:0] BASE_6000    = 32'h0002_0000;
    localparam [31:0] BASE_ERR     = 32'h0003_0000;
    localparam [31:0] BASE_RECOVER = 32'h0004_0000;
    localparam [31:0] BASE_40K_C13 = 32'h0005_0000;

    reg clk = 1'b0;
    reg resetn = 1'b0;
    always #5 clk = ~clk;

    reg strip_start = 1'b0;
    reg [31:0] strip_addr = 32'b0;
    reg [16:0] strip_bytes = 17'b0;
    reg strip_bank = 1'b0;
    reg strip_clear = 1'b0;
    wire strip_busy;
    wire strip_done;
    wire strip_err;

    wire m_arvalid;
    wire m_arready;
    wire [31:0] m_araddr;
    wire [7:0] m_arlen;
    wire [2:0] m_arsize;
    wire [1:0] m_arburst;
    wire m_rvalid;
    wire m_rready;
    wire [DMA_DATA_W-1:0] m_rdata;
    wire m_rlast;
    wire [1:0] m_rresp;
    wire m_awvalid;
    wire m_awready;
    wire [31:0] m_awaddr;
    wire [7:0] m_awlen;
    wire [2:0] m_awsize;
    wire [1:0] m_awburst;
    wire m_wvalid;
    wire m_wready;
    wire [DMA_DATA_W-1:0] m_wdata;
    wire [DMA_DATA_W/8-1:0] m_wstrb;
    wire m_wlast;
    wire m_bvalid;
    wire m_bready;
    wire [1:0] m_bresp;

    wire legacy_busy;
    wire legacy_done;
    wire legacy_err;
    wire legacy_buf_we;
    wire [13:0] legacy_buf_addr;
    wire [DMA_DATA_W-1:0] legacy_buf_wdata;
    wire legacy_buf_re;
    wire [13:0] legacy_buf_raddr;

    wire strip_we;
    wire strip_wbank;
    wire [15:0] strip_waddr;
    wire [DMA_DATA_W-1:0] strip_wdata;
    wire [255:0] eng_b_rdata;
    wire [1:0] bank_valid;

    reg [7:0] golden [0:DDR_BYTES-1];

    npu_dma #(.BUF_AW(14), .DMA_DATA_W(DMA_DATA_W)) dut (
        .clk(clk), .resetn(resetn),
        .go(1'b0), .abort_i(1'b0), .write_mode(1'b0), .narrow_i(1'b0),
        .src_addr(32'b0), .dst_word(14'b0), .len_beats(17'b0),
        .busy(legacy_busy), .done(legacy_done), .err(legacy_err),
        .strip_start(strip_start), .strip_addr(strip_addr),
        .strip_bytes(strip_bytes), .strip_bank(strip_bank),
        .strip_busy(strip_busy), .strip_done(strip_done), .strip_err(strip_err),
        .m_arvalid(m_arvalid), .m_arready(m_arready), .m_araddr(m_araddr), .m_arlen(m_arlen),
        .m_arsize(m_arsize), .m_arburst(m_arburst),
        .m_rvalid(m_rvalid), .m_rready(m_rready), .m_rdata(m_rdata), .m_rlast(m_rlast), .m_rresp(m_rresp),
        .m_awvalid(m_awvalid), .m_awready(m_awready), .m_awaddr(m_awaddr), .m_awlen(m_awlen),
        .m_awsize(m_awsize), .m_awburst(m_awburst),
        .m_wvalid(m_wvalid), .m_wready(m_wready), .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wlast(m_wlast),
        .m_bvalid(m_bvalid), .m_bready(m_bready), .m_bresp(m_bresp),
        .buf_we(legacy_buf_we), .buf_addr(legacy_buf_addr), .buf_wdata(legacy_buf_wdata),
        .buf_re(legacy_buf_re), .buf_raddr(legacy_buf_raddr), .buf_rdata({DMA_DATA_W{1'b0}}),
        .strip_we(strip_we), .strip_wbank(strip_wbank), .strip_waddr(strip_waddr),
        .strip_wdata(strip_wdata)
    );

    npu_strip_buf #(.DMA_DATA_W(DMA_DATA_W)) strip_buf (
        .clk(clk), .resetn(resetn), .clear(strip_clear),
        .dma_we(strip_we), .dma_bank(strip_wbank), .dma_waddr(strip_waddr),
        .dma_wdata(strip_wdata), .fill_done(strip_done),
        .eng_b_re(1'b0), .eng_b_bank(strip_bank), .eng_b_addr(14'b0),
        .eng_b_rdata(eng_b_rdata), .bank_valid(bank_valid)
    );

    axi_ddr_latency_model #(
        .WORDS(DDR_WORDS), .AW(DDR_AW), .DMA_DATA_W(DMA_DATA_W),
        .T_FIRST_HIT(6), .T_FIRST_MISS(10), .COL_CYC(3)
    ) ddr (
        .clk(clk), .resetn(resetn),
        .arvalid(m_arvalid), .arready(m_arready), .araddr(m_araddr),
        .arlen(m_arlen), .arsize(m_arsize), .arburst(m_arburst),
        .rvalid(m_rvalid), .rready(m_rready), .rdata(m_rdata),
        .rlast(m_rlast), .rresp(m_rresp),
        .awvalid(m_awvalid), .awready(m_awready), .awaddr(m_awaddr),
        .awlen(m_awlen), .awsize(m_awsize), .awburst(m_awburst),
        .wvalid(m_wvalid), .wready(m_wready), .wdata(m_wdata),
        .wstrb(m_wstrb), .wlast(m_wlast),
        .bvalid(m_bvalid), .bready(m_bready), .bresp(m_bresp)
    );

    integer errors = 0;
    integer watchdog = 0;
    integer init_i;
    integer init_w;
    integer gap_waiting = 0;
    integer gap_cycles = 0;
    integer ar_gap_errors = 0;

    function [7:0] image_byte;
        input integer idx;
        reg [31:0] tmp;
        begin
            tmp = (idx * 37) + (idx / 17) + 32'h0000_005a;
            image_byte = tmp[7:0];
        end
    endfunction

    function [31:0] golden_word;
        input [31:0] byte_addr;
        begin
            golden_word = {golden[byte_addr + 32'd3], golden[byte_addr + 32'd2],
                           golden[byte_addr + 32'd1], golden[byte_addr]};
        end
    endfunction

    initial begin
        for (init_i = 0; init_i < DDR_BYTES; init_i = init_i + 1)
            golden[init_i] = image_byte(init_i);
        for (init_w = 0; init_w < DDR_WORDS; init_w = init_w + 1)
            ddr.mem[init_w] = {golden[init_w*4 + 3], golden[init_w*4 + 2],
                               golden[init_w*4 + 1], golden[init_w*4]};
    end

    always @(posedge clk) begin
        if (!resetn) begin
            gap_waiting <= 0;
            gap_cycles <= 0;
        end else begin
            if (gap_waiting != 0) begin
                if (m_arvalid) begin
                    if (gap_cycles > 2) begin
                        errors = errors + 1;
                        ar_gap_errors = ar_gap_errors + 1;
                        $display("STRIP_DMA_FAIL AR gap %0d cycles", gap_cycles);
                    end
                    gap_waiting <= 0;
                    gap_cycles <= 0;
                end else begin
                    gap_cycles <= gap_cycles + 1;
                    if (gap_cycles > 2) begin
                        errors = errors + 1;
                        ar_gap_errors = ar_gap_errors + 1;
                        $display("STRIP_DMA_FAIL ARVALID missing after RLAST gap=%0d", gap_cycles);
                        gap_waiting <= 0;
                    end
                end
            end
            if (m_rvalid && m_rready && m_rlast && strip_busy &&
                ({15'b0, dut.strip_remaining_bytes} > dut.strip_bytes_in_burst) &&
                !dut.strip_error_seen) begin
                gap_waiting <= 1;
                gap_cycles <= 0;
            end
        end
    end

    task pulse_strip;
        input [31:0] addr;
        input [16:0] bytes;
        input bank;
        begin
            @(negedge clk);
            strip_addr = addr;
            strip_bytes = bytes;
            strip_bank = bank;
            strip_start = 1'b1;
            @(negedge clk);
            strip_start = 1'b0;
        end
    endtask

    task run_strip_main;
        input [31:0] addr;
        input [16:0] bytes;
        input bank;
        input integer col_cyc;
        input expect_err;
        output integer cycles;
        output reg done_seen;
        output reg err_seen;
        integer guard;
        begin
            ddr.col_cyc_runtime = col_cyc;
            pulse_strip(addr, bytes, bank);
            cycles = 0;
            done_seen = 1'b0;
            err_seen = 1'b0;
            guard = 0;
            while (!done_seen && !err_seen && guard < 200000) begin
                @(posedge clk);
                if (strip_busy)
                    cycles = cycles + 1;
                if (strip_done)
                    done_seen = 1'b1;
                if (strip_err)
                    err_seen = 1'b1;
                guard = guard + 1;
            end
            while (strip_busy && guard < 200000) begin
                @(posedge clk);
                cycles = cycles + 1;
                guard = guard + 1;
            end
            if (guard >= 200000) begin
                errors = errors + 1;
                $display("STRIP_DMA_FAIL timeout addr=%08x bytes=%0d", addr, bytes);
            end
            if (expect_err && !err_seen) begin
                errors = errors + 1;
                $display("STRIP_DMA_FAIL expected strip_err addr=%08x", addr);
            end
            if (!expect_err && (err_seen || !done_seen)) begin
                errors = errors + 1;
                $display("STRIP_DMA_FAIL bad completion addr=%08x done=%0b err=%0b", addr, done_seen, err_seen);
            end
        end
    endtask

    task inject_one_rresp_error;
        begin
            wait (m_rvalid && m_rready);
            @(negedge clk);
            force m_rresp = 2'b10;
            @(posedge clk);
            @(negedge clk);
            release m_rresp;
        end
    endtask

    task run_strip;
        input [31:0] addr;
        input [16:0] bytes;
        input bank;
        input integer col_cyc;
        input expect_err;
        input inject_err;
        output integer cycles;
        reg done_seen;
        reg err_seen;
        begin
            if (inject_err) begin
                fork
                    run_strip_main(addr, bytes, bank, col_cyc, expect_err, cycles, done_seen, err_seen);
                    inject_one_rresp_error();
                join
            end else begin
                run_strip_main(addr, bytes, bank, col_cyc, expect_err, cycles, done_seen, err_seen);
            end
        end
    endtask

    task check_bank;
        input bank;
        input [31:0] base;
        input integer bytes;
        integer words;
        integer ci;
        reg [31:0] got;
        reg [31:0] exp;
        begin
            words = bytes / 4;
            for (ci = 0; ci < words; ci = ci + 1) begin
                if (bank)
                    got = strip_buf.bank1_mem[ci];
                else
                    got = strip_buf.bank0_mem[ci];
                exp = golden_word(base + ci*4);
                if (got !== exp) begin
                    errors = errors + 1;
                    if (errors < 12)
                        $display("STRIP_DMA_FAIL bank%0d word%0d got=%08x exp=%08x", bank, ci, got, exp);
                end
            end
            if (bank_valid[bank] !== 1'b1) begin
                errors = errors + 1;
                $display("STRIP_DMA_FAIL bank%0d valid not set", bank);
            end
        end
    endtask

    integer cyc_40k_c3;
    integer cyc_4k;
    integer cyc_6000;
    integer cyc_err;
    integer cyc_recover;
    integer cyc_unalign;
    integer cyc_40k_c13;

    initial begin
        repeat (4) @(posedge clk);
        resetn = 1'b1;
        strip_clear = 1'b1;
        @(posedge clk);
        strip_clear = 1'b0;

        run_strip(BASE_40K_C3, 17'd40960, 1'b0, 3, 1'b0, 1'b0, cyc_40k_c3);
        repeat (2) @(posedge clk);
        check_bank(1'b0, BASE_40K_C3, 40960);
        $display("STRIP_BW col_cyc=3 bytes=40960 busy_cycles=%0d bpc_x1000=%0d",
                 cyc_40k_c3, (40960 * 1000) / cyc_40k_c3);

        run_strip(BASE_4K, 17'd4096, 1'b1, 3, 1'b0, 1'b0, cyc_4k);
        repeat (2) @(posedge clk);
        check_bank(1'b1, BASE_4K, 4096);

        run_strip(BASE_6000, 17'd6000, 1'b0, 3, 1'b0, 1'b0, cyc_6000);
        repeat (2) @(posedge clk);
        check_bank(1'b0, BASE_6000, 6000);

        run_strip(BASE_ERR, 17'd4096, 1'b1, 3, 1'b1, 1'b1, cyc_err);
        repeat (4) @(posedge clk);
        if (!strip_err) begin
            errors = errors + 1;
            $display("STRIP_DMA_FAIL strip_err not sticky after injected RRESP");
        end

        run_strip(BASE_RECOVER, 17'd4096, 1'b1, 3, 1'b0, 1'b0, cyc_recover);
        repeat (2) @(posedge clk);
        check_bank(1'b1, BASE_RECOVER, 4096);

        run_strip(32'h0000_1234, 17'd4096, 1'b0, 3, 1'b1, 1'b0, cyc_unalign);

        run_strip(BASE_40K_C13, 17'd40960, 1'b1, 13, 1'b0, 1'b0, cyc_40k_c13);
        repeat (2) @(posedge clk);
        check_bank(1'b1, BASE_40K_C13, 40960);
        $display("STRIP_BW col_cyc=13 bytes=40960 busy_cycles=%0d bpc_x1000=%0d",
                 cyc_40k_c13, (40960 * 1000) / cyc_40k_c13);

        if (ar_gap_errors != 0)
            $display("STRIP_DMA_FAIL ar_gap_errors=%0d", ar_gap_errors);

        if (errors == 0)
            $display("STRIP_DMA_PASS");
        else
            $display("STRIP_DMA_FAIL errors=%0d", errors);
        $finish;
    end

    initial begin
        #5000000;
        $display("STRIP_DMA_FAIL watchdog");
        $fatal(1, "tb_strip_dma watchdog");
    end
endmodule

`default_nettype wire
