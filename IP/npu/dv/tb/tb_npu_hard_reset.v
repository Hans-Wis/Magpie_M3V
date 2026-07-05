// =============================================================================
// tb_npu_hard_reset.v — ADR-0047 gate_54: hard vs soft reset distinction.
// S1 fault -> SOFT: evidence PERSISTS (ADR-0038 baseline). S2 same fault ->
// HARD (CTRL[3]): registers -> power-on (ERR/ring/CTRL/STATUS zero, IRQ low),
// DTCM marker PERSISTS (SRAM semantics; intentional divergence from a Coral
// IMEM-clear, recorded). S3 hard mid-4096-beat DMA drains to a burst boundary
// first; double-hard idempotent. S4 cold restart runs a full matrix batch.
// =============================================================================
`default_nettype none
`timescale 1ns/1ps

module tb_npu_hard_reset;
    reg clk = 1'b0;
    reg resetn = 1'b0;
    always #5 clk = ~clk;

    reg         s_awvalid = 1'b0, s_wvalid = 1'b0, s_bready = 1'b0;
    reg         s_arvalid = 1'b0, s_rready = 1'b0;
    reg  [31:0] s_awaddr = 32'h0, s_wdata = 32'h0, s_araddr = 32'h0;
    reg  [ 3:0] s_wstrb = 4'h0;
    wire        s_awready, s_wready, s_bvalid, s_arready, s_rvalid;
    wire [31:0] s_rdata;
    wire [ 1:0] s_bresp, s_rresp;

    wire        m_arvalid, m_arready, m_rvalid, m_rready, m_rlast;
    wire [31:0] m_araddr, m_rdata;
    wire [ 7:0] m_arlen;
    wire [ 2:0] m_arsize;
    wire [ 1:0] m_arburst, m_rresp;
    wire        m_awvalid, m_awready, m_wvalid, m_wready, m_wlast, m_bvalid, m_bready;
    wire [31:0] m_awaddr, m_wdata;
    wire [ 7:0] m_awlen;
    wire [ 2:0] m_awsize;
    wire [ 1:0] m_awburst, m_bresp;
    wire [ 3:0] m_wstrb;
    wire        irq, npu_start;
    wire [31:0] npu_config;

    npu_top #(.TCM_WORDS(8192), .TCM_AW(13)) dut (
        .clk(clk), .resetn(resetn),
        .s_awvalid(s_awvalid), .s_awready(s_awready), .s_awaddr(s_awaddr), .s_awprot(3'b0),
        .s_wvalid(s_wvalid), .s_wready(s_wready), .s_wdata(s_wdata), .s_wstrb(s_wstrb),
        .s_bvalid(s_bvalid), .s_bready(s_bready), .s_bresp(s_bresp),
        .s_arvalid(s_arvalid), .s_arready(s_arready), .s_araddr(s_araddr), .s_arprot(3'b0),
        .s_rvalid(s_rvalid), .s_rready(s_rready), .s_rdata(s_rdata), .s_rresp(s_rresp),
        .m_arvalid(m_arvalid), .m_arready(m_arready), .m_araddr(m_araddr), .m_arlen(m_arlen),
        .m_arsize(m_arsize), .m_arburst(m_arburst),
        .m_rvalid(m_rvalid), .m_rready(m_rready), .m_rdata(m_rdata), .m_rlast(m_rlast), .m_rresp(m_rresp),
        .m_awvalid(m_awvalid), .m_awready(m_awready), .m_awaddr(m_awaddr), .m_awlen(m_awlen),
        .m_awsize(m_awsize), .m_awburst(m_awburst),
        .m_wvalid(m_wvalid), .m_wready(m_wready), .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wlast(m_wlast),
        .m_bvalid(m_bvalid), .m_bready(m_bready), .m_bresp(m_bresp),
        .irq(irq), .npu_start(npu_start), .npu_config(npu_config)
    );

    axi_full_rwmem #(.WORDS(16384)) shared (
        .clk(clk), .resetn(resetn),
        .arvalid(m_arvalid), .arready(m_arready), .araddr(m_araddr),
        .arlen(m_arlen), .arsize(m_arsize), .arburst(m_arburst),
        .rvalid(m_rvalid), .rready(m_rready), .rdata(m_rdata), .rlast(m_rlast), .rresp(m_rresp),
        .awvalid(m_awvalid), .awready(m_awready), .awaddr(m_awaddr),
        .awlen(m_awlen), .awsize(m_awsize), .awburst(m_awburst),
        .wvalid(m_wvalid), .wready(m_wready), .wdata(m_wdata), .wstrb(m_wstrb), .wlast(m_wlast),
        .bvalid(m_bvalid), .bready(m_bready), .bresp(m_bresp)
    );

    localparam [31:0] A_CTRL = 32'h3000_0004, A_STATUS = 32'h3000_0008;
    localparam [31:0] A_DSRC = 32'h3000_0020, A_DDST = 32'h3000_0024, A_DLEN = 32'h3000_0028, A_DGO = 32'h3000_002C;
    localparam [31:0] A_BASE = 32'h3000_0040, A_SIZE = 32'h3000_0044, A_TAIL = 32'h3000_004C;
    localparam [31:0] A_CQCTRL = 32'h3000_0050, A_CQST = 32'h3000_0054, A_ERRC = 32'h3000_0058;
    localparam [31:0] A_ERRPC = 32'h3000_0080;

    integer errors = 0, checks = 0, i, ar_cnt_snap;
    reg [31:0] rd;
    integer ar_cnt;
    always @(posedge clk) if (m_arvalid && m_arready) ar_cnt <= ar_cnt + 1;

    task chk(input [31:0] got, input [31:0] exp, input [255:0] nm);
        begin
            checks = checks + 1;
            if (got !== exp) begin
                errors = errors + 1;
                $display("  FAIL %0s got %08x exp %08x", nm, got, exp);
            end
        end
    endtask

    task axil_write(input [31:0] a, input [31:0] d);
        reg aw_done, w_done; integer guard;
        begin
            @(negedge clk);
            s_awvalid = 1'b1; s_awaddr = a; s_wvalid = 1'b1; s_wdata = d; s_wstrb = 4'hf;
            s_bready = 1'b0; aw_done = 1'b0; w_done = 1'b0; guard = 0;
            while (!(aw_done && w_done) && guard < 1000) begin
                @(posedge clk);
                if (s_awvalid && s_awready) aw_done = 1'b1;
                if (s_wvalid && s_wready)   w_done = 1'b1;
                @(negedge clk);
                if (aw_done) s_awvalid = 1'b0;
                if (w_done)  s_wvalid = 1'b0;
                guard = guard + 1;
            end
            s_bready = 1'b1; guard = 0;
            while (!s_bvalid && guard < 1000) begin @(posedge clk); guard = guard + 1; end
            @(negedge clk); s_bready = 1'b0;
        end
    endtask

    task axil_read(input [31:0] a, output [31:0] d);
        integer guard;
        begin
            @(negedge clk);
            s_arvalid = 1'b1; s_araddr = a; s_rready = 1'b1; guard = 0;
            while (!(s_arvalid && s_arready) && guard < 1000) begin @(posedge clk); guard = guard + 1; end
            @(negedge clk); s_arvalid = 1'b0; guard = 0;
            while (!(s_rvalid && s_rready) && guard < 1000) begin @(posedge clk); guard = guard + 1; end
            d = s_rdata;
            @(negedge clk); s_rready = 1'b0;
        end
    endtask

    task wait_cond_errc_nonzero;
        integer guard;
        begin
            rd = 32'h0; guard = 0;
            while (rd == 32'h0 && guard < 6000) begin
                axil_read(A_ERRC, rd); guard = guard + 1;
            end
        end
    endtask

    task wait_status_bit_clear(input integer bitpos, input [255:0] nm);
        integer guard;
        begin
            rd = 32'hFFFF_FFFF; guard = 0;
            while (rd[bitpos] !== 1'b0 && guard < 6000) begin
                axil_read(A_STATUS, rd); guard = guard + 1;
            end
            chk({31'b0, rd[bitpos]}, 32'h0, nm);
        end
    endtask

    function [7:0] a_byte(input integer idx); a_byte = (idx * 7 - 100) & 8'hFF; endfunction
    function [7:0] b_byte(input integer idx); b_byte = (idx * 5 - 60) & 8'hFF; endfunction


    localparam [31:0] A_HEAD2 = 32'h3000_0048;
    integer ar_snap;
    integer guard2;

    task wait_bit(input [31:0] addr, input integer bitpos, input [255:0] nm);
        begin
            rd = 32'h0; guard2 = 0;
            while (rd[bitpos] !== 1'b1 && guard2 < 6000) begin
                axil_read(addr, rd); guard2 = guard2 + 1;
            end
            chk({31'b0, rd[bitpos]}, 32'h1, nm);
        end
    endtask

    task wait_status9_clear;
        begin
            rd = 32'h200; guard2 = 0;
            while (rd[9] !== 1'b0 && guard2 < 3000) begin
                axil_read(A_STATUS, rd); guard2 = guard2 + 1;
            end
            chk({31'b0, rd[9]}, 32'h0, "hard_resetting cleared");
        end
    endtask

    initial begin
        $readmemh("IP/npu/sw/cq_sequencer/trap_test.hex", dut.tcm.mem);
        $readmemh("IP/npu/sw/cq_sequencer/trap_test.hex", dut.itcm.mem);
        repeat (4) @(posedge clk);
        resetn = 1'b1;
        @(posedge clk);

        // ---- S1: fault -> SOFT -> evidence persists (baseline) ----
        axil_write(32'h3001_0100, 32'hCAFE_D00D);       // DTCM marker
        axil_write(A_CTRL, 32'h1);
        rd = 0; guard2 = 0;
        while (rd !== 32'h80000002 && guard2 < 3000) begin
            axil_read(A_ERRC, rd); guard2 = guard2 + 1;
        end
        chk(rd, 32'h80000002, "S1 fault latched");
        axil_write(A_CTRL, 32'h4);                       // SOFT
        rd = 32'h100; guard2 = 0;
        while (rd[8] !== 1'b0 && guard2 < 3000) begin
            axil_read(A_STATUS, rd); guard2 = guard2 + 1;
        end
        axil_read(A_ERRC, rd);
        chk(rd, 32'h80000002, "S1 SOFT keeps evidence (ADR-0038)");

        // ---- S2: HARD -> power-on registers, memory persists ----
        axil_write(A_BASE, 32'h0000_0400);
        axil_write(A_SIZE, 32'd8);
        axil_write(A_CTRL, 32'h10);                       // HARD
        wait_status9_clear();
        axil_read(A_ERRC, rd);   chk(rd, 32'h0, "S2 ERR_CAUSE cleared");
        axil_read(32'h3000_0080, rd); chk(rd, 32'h0, "S2 ERR_PC cleared");
        axil_read(A_BASE, rd);   chk(rd, 32'h0, "S2 RING_BASE cleared");
        axil_read(A_SIZE, rd);   chk(rd, 32'h0, "S2 RING_SIZE cleared");
        axil_read(A_HEAD2, rd);  chk(rd, 32'h0, "S2 HEAD cleared");
        axil_read(A_CTRL, rd);   chk(rd, 32'h0, "S2 CTRL cleared");
        axil_read(A_STATUS, rd); chk(rd, 32'h0, "S2 STATUS power-on");
        chk({31'b0, irq}, 32'h0, "S2 IRQ low");
        axil_read(32'h3001_0100, rd);
        chk(rd, 32'hCAFE_D00D, "S2 DTCM contents persist (SRAM semantics)");

        // ---- S3: hard mid-DMA drains first; double-hard idempotent ----
        axil_write(32'h3000_0020, 32'h8000_0000);
        axil_write(32'h3000_0024, 32'h0);
        axil_write(32'h3000_0028, 32'd4096);
        axil_write(32'h3000_002C, 32'h1);
        repeat (30) @(posedge clk);
        axil_write(A_CTRL, 32'h10);
        axil_write(A_CTRL, 32'h10);                       // double-hard
        wait_status9_clear();
        ar_snap = ar_cnt;
        repeat (100) @(posedge clk);
        chk(ar_cnt - ar_snap, 32'd0, "S3 no AR after hard reset (clean drain)");
        axil_read(A_STATUS, rd); chk(rd, 32'h0, "S3 STATUS power-on after double-hard");

        // ---- S4: cold restart runs a full matrix batch ----
        $readmemh("IP/npu/sw/cq_sequencer/firmware.hex", dut.tcm.mem);
        $readmemh("IP/npu/sw/cq_sequencer/firmware.hex", dut.itcm.mem);
        for (i = 0; i < 8; i = i + 1)
            axil_write(32'h3001_0700 + i*4, 32'h0102_0304);
        for (i = 0; i < 8; i = i + 1)
            axil_write(32'h3001_0740 + i*4, 32'h0505_0505);
        shared.mem[32'h100] = 32'h0000_0001;
        shared.mem[32'h101] = 32'h0008_0008;
        shared.mem[32'h102] = 32'd256;
        shared.mem[32'h103] = 32'h0;
        shared.mem[32'h104] = 32'h0000_0006;
        shared.mem[32'h105] = 32'h1;
        shared.mem[32'h106] = 32'h0;
        shared.mem[32'h107] = 32'h0;
        shared.mem[32'h108] = 32'h0020_0003;             // OP rpt=32 (K=256 bytes)
        shared.mem[32'h109] = 32'h0000_0700;
        shared.mem[32'h10A] = 32'h0000_0740;
        shared.mem[32'h10B] = 32'h0;
        shared.mem[32'h10C] = 32'h0000_0004;
        shared.mem[32'h10D] = 32'h4000_0000;
        shared.mem[32'h10E] = 32'h0000_0023;
        shared.mem[32'h10F] = 32'h0000_7F80;
        shared.mem[32'h110] = 32'h0000_5005;
        shared.mem[32'h111] = 32'h0000_1800;
        shared.mem[32'h112] = 32'h0000_0800;
        shared.mem[32'h113] = 32'h0000_0404;
        chk({31'b0, irq}, 32'h0, "S4 no spurious IRQ before batch");
        axil_write(A_BASE, 32'h0000_0400);
        axil_read(A_BASE, rd);   $display("DBG S4 BASE=%08x", rd);
        axil_write(A_SIZE, 32'd8);
        axil_write(A_CQCTRL, 32'h1);
        axil_write(A_CTRL, 32'h9);
        axil_read(A_CTRL, rd);   $display("DBG S4 CTRL=%08x", rd);
        axil_write(A_TAIL, 32'd5);
        axil_read(32'h3000_004C, rd); $display("DBG S4 TAIL=%08x", rd);
        $display("DBG S4 hard_pending=%b freeze=%b wbusy=%b rbusy=%b",
                 dut.hard_pending, dut.hard_freeze, dut.w_busy, dut.r_busy);
        wait_bit(A_STATUS, 1, "S4 cold-restart batch DONE");
        axil_read(A_ERRC, rd);  $display("DBG S4 ERR_CAUSE=%08x", rd);
        axil_read(A_CQST, rd);  $display("DBG S4 CQST=%08x", rd);
        axil_read(A_HEAD2, rd); $display("DBG S4 HEAD=%08x", rd);
        axil_read(A_STATUS, rd);$display("DBG S4 STATUS=%08x", rd);
        axil_read(A_CQST, rd);
        chk({31'b0, rd[3]}, 32'h0, "S4 no CQ err after cold restart");

        $display("NPU_HARDRST: %0d checks, %0d errors", checks, errors);
        if (errors == 0) $display("NPU_HARDRST_PASS");
        else             $display("NPU_HARDRST_FAIL");
        $finish;
    end

    initial begin
        #6000000;
        $display("NPU_HARDRST_FAIL: timeout");
        $finish;
    end
endmodule
`default_nettype wire
