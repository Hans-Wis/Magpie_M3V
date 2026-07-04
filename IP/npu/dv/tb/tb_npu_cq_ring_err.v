// =============================================================================
// tb_npu_cq_ring_err.v — ADR-0035 gate_36/38: ring protocol + ERR contract.
// Scenarios (ring = 4 descriptors @ shared word 0x100, sequencer firmware in TCM):
//   S1 batch + WRAP: 3 descriptors consumed, then 3 more wrapping 3->0->1
//   S2 FULL/EMPTY advisory flags (computed from HEAD/TAIL, core held in reset)
//   S3 ERR ladder with per-round recovery (repair ring + CQ_CTRL enable-toggle):
//      BAD_OPCODE(1) -> RSVD_VIOLATION(2) -> MAT_PARAM(7, ADR-0037) -> DESC_ALIGN(6)
//      -> positive recovery run. Each ERR: CQ_STATUS.err set, ERR_CAUSE latched,
//      HEAD frozen, no DONE. (RING_OVERRUN(3)/DMA_FAULT(5) not exercised here:
//      overrun detection is deferred per ADR-0035 deviations; DMA fault path is
//      the gate_28/29-verified engine err, same firmware wait loop.)
// Tokens: NPU_CQ_RING_PASS (S1+S2) and NPU_CQ_ERR_PASS (S3).
// =============================================================================
`default_nettype none
`timescale 1ns/1ps

module tb_npu_cq_ring_err;
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

    npu_top #(.TCM_WORDS(1024), .TCM_AW(10)) dut (
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

    initial $readmemh("IP/npu/sw/cq_sequencer/firmware.hex", dut.tcm.mem);

    // host CSR addresses
    localparam [31:0] A_CTRL = 32'h3000_0004, A_STATUS = 32'h3000_0008;
    localparam [31:0] A_BASE = 32'h3000_0040, A_SIZE = 32'h3000_0044;
    localparam [31:0] A_HEAD = 32'h3000_0048, A_TAIL = 32'h3000_004C;
    localparam [31:0] A_CQCTRL = 32'h3000_0050, A_CQST = 32'h3000_0054, A_ERRC = 32'h3000_0058;
    // W0 encodings (from cq_codec SSOT): CFG=0x01, LAST bit14, MAT_OP=0x03
    localparam [31:0] W0_CFG = 32'h0000_0001, W0_CFG_LAST = 32'h0000_4001;
    localparam [31:0] W0_BAD = 32'h0000_003F, W0_RSVD = 32'h0000_8001, W0_OP = 32'h0000_0003;

    integer errors = 0, checks = 0, i;
    reg [31:0] rd;

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

    task put_desc(input [1:0] slot, input [31:0] w0);
        begin
            shared.mem[32'h100 + {28'b0, slot, 2'b00}]     = w0;
            shared.mem[32'h100 + {28'b0, slot, 2'b00} + 1] = 32'h0;
            shared.mem[32'h100 + {28'b0, slot, 2'b00} + 2] = 32'h0;
            shared.mem[32'h100 + {28'b0, slot, 2'b00} + 3] = 32'h0;
        end
    endtask

    task wait_head(input [31:0] exp_head);
        integer guard;
        begin
            rd = 32'hFFFF_FFFF; guard = 0;
            while (rd !== exp_head && guard < 3000) begin
                axil_read(A_HEAD, rd); guard = guard + 1;
            end
            chk(rd, exp_head, "CQ_HEAD reached");
        end
    endtask

    task wait_done;
        integer guard;
        begin
            rd = 32'h0; guard = 0;
            while (rd[1] !== 1'b1 && guard < 3000) begin
                axil_read(A_STATUS, rd); guard = guard + 1;
            end
            chk({31'b0, rd[1]}, 32'h1, "STATUS.done (LAST)");
        end
    endtask

    task wait_err;
        integer guard;
        begin
            rd = 32'h0; guard = 0;
            while (rd[3] !== 1'b1 && guard < 3000) begin
                axil_read(A_CQST, rd); guard = guard + 1;
            end
            chk({31'b0, rd[3]}, 32'h1, "CQ_STATUS.err set");
        end
    endtask

    // expect_err: rewrite HEAD-slot descriptor, restart, verify latched cause + frozen HEAD
    task expect_err(input [31:0] w0, input [31:0] cause, input [31:0] frozen_head);
        begin
            axil_write(A_CTRL, 32'h0);           // stop core (clears done)
            put_desc(frozen_head[1:0], w0);
            axil_write(A_CQCTRL, 32'h0);
            axil_write(A_CQCTRL, 32'h1);         // enable-toggle clears err/cause
            axil_write(A_CTRL, 32'h1);           // restart sequencer
            wait_err();
            axil_read(A_ERRC, rd);  chk(rd, cause, "ERR_CAUSE");
            axil_read(A_HEAD, rd);  chk(rd, frozen_head, "HEAD frozen on ERR");
            axil_read(A_STATUS, rd); chk({31'b0, rd[1]}, 32'h0, "no DONE on ERR");
        end
    endtask

    initial begin
        repeat (4) @(posedge clk);
        resetn = 1'b1;
        @(posedge clk);

        // ---- setup: ring of 4 @ shared byte 0x400 ----
        axil_write(A_BASE, 32'h0000_0400);
        axil_write(A_SIZE, 32'd4);
        axil_write(A_CQCTRL, 32'h1);

        // ---- S1a: batch of 3 (slots 0..2, LAST on 2) ----
        put_desc(2'd0, W0_CFG); put_desc(2'd1, W0_CFG); put_desc(2'd2, W0_CFG_LAST);
        axil_write(A_TAIL, 32'd3);
        axil_write(A_CTRL, 32'h1);           // start sequencer
        wait_head(32'd3);
        wait_done();

        // ---- S1b: WRAP batch of 3 (slots 3,0,1 -> TAIL=(3+3)&3=2) ----
        put_desc(2'd3, W0_CFG); put_desc(2'd0, W0_CFG); put_desc(2'd1, W0_CFG_LAST);
        axil_write(A_TAIL, 32'd2);
        wait_head(32'd2);

        // ---- S2: FULL/EMPTY advisory with core held in reset ----
        axil_write(A_CTRL, 32'h0);           // core off; HEAD=2 stays
        axil_write(A_TAIL, 32'd1);           // (1+1)&3 == 2 == HEAD -> full
        axil_read(A_CQST, rd);
        chk({31'b0, rd[1]}, 32'h1, "S2 FULL advisory");
        chk({31'b0, rd[0]}, 32'h0, "S2 not EMPTY");
        axil_write(A_TAIL, 32'd2);           // == HEAD -> empty
        axil_read(A_CQST, rd);
        chk({31'b0, rd[0]}, 32'h1, "S2 EMPTY");
        chk({31'b0, rd[1]}, 32'h0, "S2 not FULL");

        if (errors == 0) $display("NPU_CQ_RING_PASS");
        else             $display("NPU_CQ_RING_FAIL");

        // ---- S3: ERR ladder at HEAD=2 (TAIL=3 pending one bad descriptor) ----
        axil_write(A_TAIL, 32'd3);
        expect_err(W0_BAD,  32'd1, 32'd2);   // BAD_OPCODE
        expect_err(W0_RSVD, 32'd2, 32'd2);   // RSVD_VIOLATION
        expect_err(W0_OP,   32'd7, 32'd2);   // MAT_PARAM (ADR-0037: rpt=0 / K binding)
        // DESC_ALIGN: unaligned ring base trips before any fetch
        axil_write(A_CTRL, 32'h0);
        axil_write(A_BASE, 32'h0000_0404);
        axil_write(A_CQCTRL, 32'h0); axil_write(A_CQCTRL, 32'h1);
        axil_write(A_CTRL, 32'h1);
        wait_err();
        axil_read(A_ERRC, rd); chk(rd, 32'd6, "ERR_CAUSE align");
        axil_write(A_CTRL, 32'h0);
        axil_write(A_BASE, 32'h0000_0400);   // repair

        // recovery-positive: good CFG+LAST at slot 2 completes, err cleared by toggle
        axil_write(A_CQCTRL, 32'h0); axil_write(A_CQCTRL, 32'h1);
        put_desc(2'd2, W0_CFG_LAST);
        axil_write(A_CTRL, 32'h1);
        wait_head(32'd3);
        wait_done();
        axil_read(A_ERRC, rd);  chk(rd, 32'd0, "ERR_CAUSE cleared after toggle");
        axil_read(A_CQST, rd);  chk({31'b0, rd[3]}, 32'h0, "cq_err cleared");

        $display("NPU_CQ_RINGERR: %0d checks, %0d errors", checks, errors);
        if (errors == 0) $display("NPU_CQ_ERR_PASS");
        else             $display("NPU_CQ_ERR_FAIL");
        $finish;
    end

    initial begin
        #3000000;
        $display("NPU_CQ_ERR_FAIL: timeout");
        $finish;
    end
endmodule
`default_nettype wire
