// =============================================================================
// tb_qspi_xip_readback.v - directed QSPI XIP front-end readback checks
// =============================================================================
`default_nettype none
`timescale 1ns/1ps

module tb_qspi_xip_readback;
    localparam [31:0] XIP_BASE = 32'h4000_0000;
    localparam integer IMG_BYTES = 65536;
    localparam integer WATCHDOG_CYCLES = 2000000;

    reg clk = 1'b0;
    reg resetn = 1'b0;
    always #5 clk = ~clk;

    reg         i_arvalid;
    wire        i_arready;
    reg  [31:0] i_araddr;
    wire        i_rvalid;
    reg         i_rready;
    wire [31:0] i_rdata;
    wire [ 1:0] i_rresp;

    reg         d_awvalid;
    wire        d_awready;
    reg  [31:0] d_awaddr;
    reg         d_wvalid;
    wire        d_wready;
    reg  [31:0] d_wdata;
    reg  [ 3:0] d_wstrb;
    wire        d_bvalid;
    reg         d_bready;
    wire [ 1:0] d_bresp;
    reg         d_arvalid;
    wire        d_arready;
    reg  [31:0] d_araddr;
    wire        d_rvalid;
    reg         d_rready;
    wire [31:0] d_rdata;
    wire [ 1:0] d_rresp;

    reg  mode_quad;
    wire qspi_sclk;
    wire qspi_cs_n;
    wire [3:0] qspi_io_o;
    wire [3:0] qspi_io_oe;
    wire [3:0] qspi_io_i;
    wire [31:0] cold_reads;
    wire [31:0] warm_reads;
    wire [31:0] quad_cold_reads;
    wire [31:0] quad_warm_reads;

    reg [7:0] golden [0:IMG_BYTES-1];
    reg [1023:0] flash_hex;
    integer init_i;

    qspi_axil_front dut (
        .clk(clk),
        .resetn(resetn),
        .mode_quad_i(mode_quad),
        .i_arvalid(i_arvalid),
        .i_arready(i_arready),
        .i_araddr(i_araddr),
        .i_arprot(3'b000),
        .i_rvalid(i_rvalid),
        .i_rready(i_rready),
        .i_rdata(i_rdata),
        .i_rresp(i_rresp),
        .d_awvalid(d_awvalid),
        .d_awready(d_awready),
        .d_awaddr(d_awaddr),
        .d_awprot(3'b000),
        .d_wvalid(d_wvalid),
        .d_wready(d_wready),
        .d_wdata(d_wdata),
        .d_wstrb(d_wstrb),
        .d_bvalid(d_bvalid),
        .d_bready(d_bready),
        .d_bresp(d_bresp),
        .d_arvalid(d_arvalid),
        .d_arready(d_arready),
        .d_araddr(d_araddr),
        .d_arprot(3'b000),
        .d_rvalid(d_rvalid),
        .d_rready(d_rready),
        .d_rdata(d_rdata),
        .d_rresp(d_rresp),
        .o_sclk(qspi_sclk),
        .o_cs_n(qspi_cs_n),
        .io_o(qspi_io_o),
        .io_oe(qspi_io_oe),
        .io_i(qspi_io_i),
        .cold_reads(cold_reads),
        .warm_reads(warm_reads),
        .quad_cold_reads(quad_cold_reads),
        .quad_warm_reads(quad_warm_reads)
    );

    spi_nor_model #(
        .IMG_BYTES(IMG_BYTES)
    ) flash (
        .sclk(qspi_sclk),
        .cs_n(qspi_cs_n),
        .io_i(qspi_io_o),
        .io_o(qspi_io_i),
        .io_oe_i(qspi_io_oe)
    );

    always @(posedge qspi_sclk or negedge qspi_sclk) begin
        if (!qspi_cs_n && ((qspi_io_oe & flash.driving_lanes) != 4'b0000)) begin
            $display("QSPI_OE_OVERLAP controller=%b flash=%b",
                     qspi_io_oe, flash.driving_lanes);
            $fatal(1, "QSPI_OE_OVERLAP");
        end
    end

    function [7:0] golden_byte;
        input [31:0] off;
        begin
            if (off < IMG_BYTES)
                golden_byte = golden[off];
            else
                golden_byte = 8'hff;
        end
    endfunction

    function [31:0] golden_word;
        input [31:0] addr;
        reg [31:0] off;
        begin
            off = addr - XIP_BASE;
            // TRUE little-endian semantics: byte@off is the word's LSB. This
            // golden intentionally differs from the raw MSB-first shift order
            // so an endianness bug in the datapath cannot self-consistently pass.
            golden_word = {golden_byte(off + 32'd3), golden_byte(off + 32'd2),
                           golden_byte(off + 32'd1), golden_byte(off)};
        end
    endfunction

    task check_word;
        input [255:0] name;
        input [31:0] got;
        input [31:0] exp;
        input [ 1:0] resp;
        begin
            if (resp !== 2'b00 || got !== exp) begin
                $display("QSPI_CHECK_FAIL %0s got=%08x exp=%08x resp=%0b",
                         name, got, exp, resp);
                $fatal(1, "QSPI_CHECK_FAIL");
            end
        end
    endtask

    task i_read_word;
        input [31:0] addr;
        output [31:0] data;
        output [ 1:0] resp;
        integer t;
        begin
            @(negedge clk);
            i_araddr = addr;
            i_arvalid = 1'b1;
            #1;
            for (t = 0; t < 100000 && !i_arready; t = t + 1)
                @(negedge clk);
            if (!i_arready) begin
                $display("I_AR_DIAG read_busy=%0b grant=%0d write_active=%0b selected_arready=%0b mode=%0b resetn=%0b",
                         dut.read_busy, dut.read_grant_q, dut.write_active,
                         dut.selected_arready, dut.mode_quad_q, resetn);
                $fatal(1, "I AR timeout addr=%08x", addr);
            end
            #1;
            @(posedge clk);
            #1;
            i_arvalid = 1'b0;
            for (t = 0; t < 100000 && !i_rvalid; t = t + 1)
                @(negedge clk);
            if (!i_rvalid) begin
                $display("I_R_DIAG read_busy=%0b grant=%0d xip_rvalid=%0b xip_rready=%0b mode=%0b single_state=%0d quad_state=%0d cs_n=%0b sclk=%0b cold=%0d warm=%0d qcold=%0d qwarm=%0d xip_rdata=%08x",
                         dut.read_busy, dut.read_grant_q, dut.xip_rvalid,
                         dut.xip_rready, dut.mode_quad_q, dut.u_xip_single.st,
                         dut.u_xip_quad.st, qspi_cs_n, qspi_sclk, cold_reads,
                         warm_reads, quad_cold_reads, quad_warm_reads, dut.xip_rdata);
                $fatal(1, "I R timeout addr=%08x", addr);
            end
            data = i_rdata;
            resp = i_rresp;
            i_rready = 1'b1;
            @(posedge clk);
            #1;
            i_rready = 1'b0;
        end
    endtask

    task d_read_word;
        input [31:0] addr;
        output [31:0] data;
        output [ 1:0] resp;
        integer t;
        begin
            @(negedge clk);
            d_araddr = addr;
            d_arvalid = 1'b1;
            #1;
            for (t = 0; t < 100000 && !d_arready; t = t + 1)
                @(negedge clk);
            if (!d_arready)
                $fatal(1, "D AR timeout addr=%08x", addr);
            @(posedge clk);
            #1;
            d_arvalid = 1'b0;
            for (t = 0; t < 100000 && !d_rvalid; t = t + 1)
                @(negedge clk);
            if (!d_rvalid)
                $fatal(1, "D R timeout addr=%08x", addr);
            data = d_rdata;
            resp = d_rresp;
            d_rready = 1'b1;
            @(posedge clk);
            #1;
            d_rready = 1'b0;
        end
    endtask

    task d_write_word;
        input [31:0] addr;
        input [31:0] data;
        output [ 1:0] resp;
        integer t;
        reg aw_done;
        reg w_done;
        begin
            @(negedge clk);
            d_awaddr = addr;
            d_wdata = data;
            d_wstrb = 4'hf;
            d_awvalid = 1'b1;
            d_wvalid = 1'b1;
            #1;
            aw_done = 1'b0;
            w_done = 1'b0;
            for (t = 0; t < 100000 && !(aw_done && w_done); t = t + 1) begin
                #1;
                if (d_awvalid && d_awready)
                    aw_done = 1'b1;
                if (d_wvalid && d_wready)
                    w_done = 1'b1;
                if (aw_done && w_done) begin
                    @(posedge clk);
                    #1;
                    d_awvalid = 1'b0;
                    d_wvalid = 1'b0;
                end else begin
                    @(negedge clk);
                end
            end
            if (!(aw_done && w_done))
                $fatal(1, "D write accept timeout addr=%08x", addr);
            d_bready = 1'b1;
            for (t = 0; t < 100000 && !d_bvalid; t = t + 1)
                @(negedge clk);
            if (!d_bvalid)
                $fatal(1, "D B timeout addr=%08x", addr);
            resp = d_bresp;
            @(posedge clk);
            #1;
            d_bready = 1'b0;
        end
    endtask

    task simultaneous_i_d_reads;
        input [31:0] i_addr;
        input [31:0] d_addr;
        integer t;
        reg i_addr_done;
        reg d_addr_done;
        reg first_seen;
        reg d_seen;
        reg [31:0] i_data_q;
        reg [31:0] d_data_q;
        reg [1:0] i_resp_q;
        reg [1:0] d_resp_q;
        begin
            @(negedge clk);
            i_araddr = i_addr;
            d_araddr = d_addr;
            i_arvalid = 1'b1;
            d_arvalid = 1'b1;
            i_rready = 1'b0;
            d_rready = 1'b0;
            #1;
            i_addr_done = 1'b0;
            d_addr_done = 1'b0;
            first_seen = 1'b0;
            d_seen = 1'b0;
            i_data_q = 32'h0;
            d_data_q = 32'h0;
            i_resp_q = 2'b00;
            d_resp_q = 2'b00;

            if (!i_arready)
                $fatal(1, "simultaneous I was not granted from idle");
            if (d_arready)
                $fatal(1, "simultaneous D accepted in same idle cycle as I");
            i_addr_done = 1'b1;
            @(posedge clk);
            #1;
            i_arvalid = 1'b0;

            for (t = 0; t < 200000 && !first_seen; t = t + 1) begin
                @(negedge clk);
                if (d_arvalid && d_arready)
                    d_addr_done = 1'b1;
                if (d_rvalid)
                    $fatal(1, "D response beat I response under simultaneous request");
                if (i_rvalid) begin
                    first_seen = 1'b1;
                    i_data_q = i_rdata;
                    i_resp_q = i_rresp;
                end
                @(posedge clk);
                #1;
                if (d_addr_done)
                    d_arvalid = 1'b0;
            end
            if (!first_seen || !i_addr_done)
                $fatal(1, "simultaneous I read timeout");
            i_rready = 1'b1;
            @(posedge clk);
            #1;
            i_rready = 1'b0;

            for (t = 0; t < 200000 && !d_seen; t = t + 1) begin
                @(negedge clk);
                if (d_arvalid && d_arready)
                    d_addr_done = 1'b1;
                if (d_rvalid) begin
                    d_seen = 1'b1;
                    d_data_q = d_rdata;
                    d_resp_q = d_rresp;
                end
                @(posedge clk);
                #1;
                if (d_addr_done)
                    d_arvalid = 1'b0;
            end
            if (!d_seen || !d_addr_done)
                $fatal(1, "simultaneous D read timeout");
            d_rready = 1'b1;
            @(posedge clk);
            #1;
            d_rready = 1'b0;
            i_rready = 1'b0;
            d_rready = 1'b0;
            check_word("simultaneous_i_first", i_data_q, golden_word(i_addr), i_resp_q);
            check_word("simultaneous_d_second", d_data_q, golden_word(d_addr), d_resp_q);
        end
    endtask

    task set_mode;
        input desired_quad;
        integer t;
        begin
            @(negedge clk);
            mode_quad = desired_quad;
            #1;
            for (t = 0; t < 100000 &&
                        !(dut.mode_quad_q == desired_quad && !dut.reset_xip_q && qspi_cs_n);
                 t = t + 1)
                @(negedge clk);
            if (!(dut.mode_quad_q == desired_quad && !dut.reset_xip_q && qspi_cs_n))
                $fatal(1, "mode switch timeout desired_quad=%0b", desired_quad);
        end
    endtask

    task run_readback_battery;
        input [255:0] phase;
        input expect_quad;
        reg [31:0] cold_before;
        reg [31:0] warm_before;
        begin
            cold_before = expect_quad ? quad_cold_reads : cold_reads;
            warm_before = expect_quad ? quad_warm_reads : warm_reads;

            $display("%0s CHECK_A_COLD_I_WORD0", phase);
            i_read_word(XIP_BASE + 32'h0000_0000, rd, resp);
            check_word("cold_i_word0", rd, golden_word(XIP_BASE), resp);
            if ((expect_quad ? quad_cold_reads : cold_reads) == cold_before)
                $fatal(1, "cold counter did not increment phase=%0s", phase);

            $display("%0s CHECK_B_WARM_I_WORD1_TO_WORD8", phase);
            for (k = 1; k <= 8; k = k + 1) begin
                i_read_word(XIP_BASE + (k << 2), rd, resp);
                check_word("warm_i_seq", rd, golden_word(XIP_BASE + (k << 2)), resp);
            end
            if ((expect_quad ? quad_warm_reads : warm_reads) == warm_before)
                $fatal(1, "warm counter did not increment phase=%0s", phase);

            $display("%0s CHECK_C_D_FAR_THEN_I_RESEEK", phase);
            d_read_word(XIP_BASE + 32'h0000_3000, rd, resp);
            check_word("d_far", rd, golden_word(XIP_BASE + 32'h0000_3000), resp);
            i_read_word(XIP_BASE + 32'h0000_0004, rd, resp);
            check_word("i_after_d_reseek", rd, golden_word(XIP_BASE + 32'h0000_0004), resp);

            $display("%0s CHECK_D_ALTERNATE_I_D_UNRELATED_X8", phase);
            for (k = 0; k < 8; k = k + 1) begin
                i_read_word(XIP_BASE + 32'h0000_0100 + (k << 8), rd, resp);
                check_word("alt_i", rd, golden_word(XIP_BASE + 32'h0000_0100 + (k << 8)), resp);
                d_read_word(XIP_BASE + 32'h0000_0180 + (k << 8), rd, resp);
                check_word("alt_d", rd, golden_word(XIP_BASE + 32'h0000_0180 + (k << 8)), resp);
            end

            $display("%0s CHECK_E_D_WRITE_SLVERR_AND_NO_MUTATION", phase);
            d_read_word(XIP_BASE + 32'h0000_0200, rd, resp);
            check_word("pre_write_read", rd, golden_word(XIP_BASE + 32'h0000_0200), resp);
            d_write_word(XIP_BASE + 32'h0000_0200, 32'h1234_5678, resp);
            if (resp !== 2'b10)
                $fatal(1, "D write bresp expected SLVERR got %0b", resp);
            d_read_word(XIP_BASE + 32'h0000_0200, rd2, resp);
            check_word("post_write_read", rd2, rd, resp);

            $display("%0s CHECK_F_READ_BEYOND_IMG_RETURNS_FF", phase);
            d_read_word(XIP_BASE + IMG_BYTES[31:0] + 32'h0000_0100, rd, resp);
            check_word("beyond_img", rd, 32'hffff_ffff, resp);

            $display("%0s CHECK_G_SIMULTANEOUS_I_D_I_PRIORITY", phase);
            simultaneous_i_d_reads(XIP_BASE + 32'h0000_0020, XIP_BASE + 32'h0000_0400);
        end
    endtask

    task quad_to_single_midstream_flip_check;
        reg [31:0] single_cold_before;
        reg [31:0] quad_cold_before;
        reg [31:0] quad_warm_before;
        begin
            $display("QUAD CHECK_H_MODE_FLIP_CLOSES_OPEN_STREAM");
            i_read_word(XIP_BASE + 32'h0000_5000, rd, resp);
            check_word("quad_flip_cold", rd, golden_word(XIP_BASE + 32'h0000_5000), resp);
            quad_warm_before = quad_warm_reads;
            i_read_word(XIP_BASE + 32'h0000_5004, rd, resp);
            check_word("quad_flip_warm0", rd, golden_word(XIP_BASE + 32'h0000_5004), resp);
            i_read_word(XIP_BASE + 32'h0000_5008, rd, resp);
            check_word("quad_flip_warm1", rd, golden_word(XIP_BASE + 32'h0000_5008), resp);
            if (quad_warm_reads == quad_warm_before)
                $fatal(1, "quad warm stream did not open before mode flip");

            single_cold_before = cold_reads;
            quad_cold_before = quad_cold_reads;
            @(negedge clk);
            mode_quad = 1'b0;
            #1;
            i_read_word(XIP_BASE + 32'h0000_500c, rd, resp);
            check_word("mode_flip_next_read", rd, golden_word(XIP_BASE + 32'h0000_500c), resp);
            if (cold_reads == single_cold_before && quad_cold_reads == quad_cold_before)
                $fatal(1, "mode flip next read did not reopen cold");
        end
    endtask

    reg [31:0] rd;
    reg [31:0] rd2;
    reg [ 1:0] resp;
    integer k;

    initial begin
        for (init_i = 0; init_i < IMG_BYTES; init_i = init_i + 1)
            golden[init_i] = 8'hff;
        flash_hex = "design/npu/dv/tb/xip_img_smoke.hex";
        if ($value$plusargs("FLASH_HEX=%s", flash_hex))
            $display("QSPI_TB_FLASH_HEX %0s", flash_hex);
        $readmemh(flash_hex, golden);

        mode_quad = 1'b0;
        i_arvalid = 1'b0;
        i_araddr = 32'h0;
        i_rready = 1'b0;
        d_awvalid = 1'b0;
        d_awaddr = 32'h0;
        d_wvalid = 1'b0;
        d_wdata = 32'h0;
        d_wstrb = 4'h0;
        d_bready = 1'b0;
        d_arvalid = 1'b0;
        d_araddr = 32'h0;
        d_rready = 1'b0;

        repeat (8) @(posedge clk);
        resetn = 1'b1;
        repeat (4) @(posedge clk);

        run_readback_battery("SINGLE", 1'b0);
        $display("QSPI_READBACK_PASS cold=%0d warm=%0d", cold_reads, warm_reads);

        set_mode(1'b1);
        run_readback_battery("QUAD", 1'b1);
        quad_to_single_midstream_flip_check();
        $display("QSPI_QUAD_READBACK_PASS cold=%0d warm=%0d quad_cold=%0d quad_warm=%0d",
                 cold_reads, warm_reads, quad_cold_reads, quad_warm_reads);
        $finish;
    end

    initial begin
        repeat (WATCHDOG_CYCLES) @(posedge clk);
        $fatal(1, "QSPI readback watchdog");
    end
endmodule
`default_nettype wire
