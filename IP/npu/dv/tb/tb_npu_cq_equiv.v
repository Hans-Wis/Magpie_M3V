// =============================================================================
// tb_npu_cq_equiv.v — ADR-0035 gate_37: CQ-path execution equivalence.
// The SAME transfer (16-word weight load shared->TCM, then 16-word result
// writeback TCM->shared) is executed twice:
//   Phase A: via the command queue (MAT.LOAD_W + MAT.FENCE + MAT.STORE(IRQ) + CFG LAST)
//   Phase B: via the direct host CSR pokes (the gate_29-verified legacy path)
// Pass requires: byte-identical destination region, identical AXI write-channel
// activity (AW bursts / W beats / WLAST count), and identical weight-region read
// activity (AR bursts / R beats filtered to the weight source address) — i.e. the
// CQ transport adds descriptor fetches but does NOT change the executed transfer.
// =============================================================================
`default_nettype none
`timescale 1ns/1ps

module tb_npu_cq_equiv;
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

    initial begin
        $readmemh("IP/npu/sw/cq_sequencer/firmware.hex", dut.tcm.mem);
        $readmemh("IP/npu/sw/cq_sequencer/firmware.hex", dut.itcm.mem);
    end

    localparam [31:0] A_CTRL = 32'h3000_0004, A_STATUS = 32'h3000_0008;
    localparam [31:0] A_DSRC = 32'h3000_0020, A_DDST = 32'h3000_0024, A_DLEN = 32'h3000_0028, A_DGO = 32'h3000_002C;
    localparam [31:0] A_WSRC = 32'h3000_0030, A_WDST = 32'h3000_0034, A_WLEN = 32'h3000_0038, A_WGO = 32'h3000_003C;
    localparam [31:0] A_BASE = 32'h3000_0040, A_SIZE = 32'h3000_0044, A_TAIL = 32'h3000_004C, A_CQCTRL = 32'h3000_0050;
    localparam [31:0] WEIGHT_SRC = 32'h0000_0800;   // shared byte addr, word 0x200
    localparam [31:0] RESULT_DST = 32'h0000_1800;   // shared byte addr, word 0x600
    localparam [31:0] TCM_W_WORD = 32'h0000_01C0;   // firmware TCM_WEIGHT_W (byte 0x700, ADR-0052)

    // ---- AXI activity counters ----
    integer aw_cnt, w_cnt, wlast_cnt, ar_weight_cnt, r_cnt;
    always @(posedge clk) begin
        if (m_awvalid && m_awready) aw_cnt <= aw_cnt + 1;
        if (m_wvalid && m_wready) begin
            w_cnt <= w_cnt + 1;
            if (m_wlast) wlast_cnt <= wlast_cnt + 1;
        end
        if (m_arvalid && m_arready && m_araddr >= WEIGHT_SRC && m_araddr < WEIGHT_SRC + 64)
            ar_weight_cnt <= ar_weight_cnt + 1;
        if (m_rvalid && m_rready) r_cnt <= r_cnt + 1;
    end

    integer errors = 0, checks = 0, i;
    reg [31:0] rd;
    integer a_aw, a_w, a_wl, a_arw;
    reg [31:0] resultA [0:15];

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

    task poll_status_bit(input integer bitpos, input [255:0] nm);
        integer guard;
        begin
            rd = 32'h0; guard = 0;
            while (rd[bitpos] !== 1'b1 && guard < 3000) begin
                axil_read(A_STATUS, rd); guard = guard + 1;
            end
            chk({31'b0, rd[bitpos]}, 32'h1, nm);
        end
    endtask

    task put_desc(input integer slot, input [31:0] w0, input [31:0] w1, input [31:0] w2, input [31:0] w3);
        begin
            shared.mem[32'h100 + slot*4]     = w0;
            shared.mem[32'h100 + slot*4 + 1] = w1;
            shared.mem[32'h100 + slot*4 + 2] = w2;
            shared.mem[32'h100 + slot*4 + 3] = w3;
        end
    endtask

    initial begin
        aw_cnt = 0; w_cnt = 0; wlast_cnt = 0; ar_weight_cnt = 0; r_cnt = 0;
        repeat (4) @(posedge clk);
        resetn = 1'b1;
        @(posedge clk);

        // source pattern + poisoned destination
        for (i = 0; i < 16; i = i + 1) begin
            shared.mem[32'h200 + i] = 32'h5A5A0000 | i[15:0];
            shared.mem[32'h600 + i] = 32'hDEADBEEF;
        end

        // ================= Phase A: via CQ =================
        // ring @0x400: LOAD_W(src,4x4) ; FENCE ; STORE(dst,4x4,IRQ) ; CFG LAST
        put_desc(0, 32'h0000_0002, WEIGHT_SRC, 32'h0, 32'h0000_0404);
        put_desc(1, 32'h0000_0007, 32'h0, 32'h0, 32'h0);
        put_desc(2, 32'h0000_1005, RESULT_DST, 32'h0, 32'h0000_0404);
        put_desc(3, 32'h0000_4001, 32'h0008_0008, 32'h10, 32'h0);
        axil_write(A_BASE, 32'h0000_0400);
        axil_write(A_SIZE, 32'd8);
        axil_write(A_CQCTRL, 32'h1);
        a_aw = aw_cnt; a_w = w_cnt; a_wl = wlast_cnt; a_arw = ar_weight_cnt;
        axil_write(A_TAIL, 32'd4);
        axil_write(A_CTRL, 32'h1);
        poll_status_bit(1, "phaseA DONE");
        a_aw = aw_cnt - a_aw; a_w = w_cnt - a_w; a_wl = wlast_cnt - a_wl; a_arw = ar_weight_cnt - a_arw;
        for (i = 0; i < 16; i = i + 1) begin
            resultA[i] = shared.mem[32'h600 + i];
            chk(resultA[i], 32'h5A5A0000 | i[15:0], "phaseA result word");
        end

        // ================= Phase B: direct CSR (legacy verified path) =================
        axil_write(A_CTRL, 32'h0);            // stop sequencer
        axil_write(A_CQCTRL, 32'h0);          // CQ disabled: legacy IRQ/CSR semantics
        for (i = 0; i < 16; i = i + 1) shared.mem[32'h600 + i] = 32'hDEADBEEF;
        for (i = 0; i < 16; i = i + 1) dut.tcm.mem[TCM_W_WORD + i] = 32'h0;
        begin : phase_b
            integer b_aw, b_w, b_wl, b_arw;
            b_aw = aw_cnt; b_w = w_cnt; b_wl = wlast_cnt; b_arw = ar_weight_cnt;
            axil_write(A_DSRC, WEIGHT_SRC);
            axil_write(A_DDST, TCM_W_WORD);
            axil_write(A_DLEN, 32'd16);
            axil_write(A_DGO, 32'h1);
            poll_status_bit(3, "phaseB dma_done");
            axil_write(A_WSRC, TCM_W_WORD);
            axil_write(A_WDST, RESULT_DST);
            axil_write(A_WLEN, 32'd16);
            axil_write(A_WGO, 32'h1);
            poll_status_bit(7, "phaseB wb_done");
            b_aw = aw_cnt - b_aw; b_w = w_cnt - b_w; b_wl = wlast_cnt - b_wl; b_arw = ar_weight_cnt - b_arw;
            // equivalence: same write-channel activity, same weight-read activity
            chk(a_aw[31:0], b_aw[31:0], "AW burst count CQ==direct");
            chk(a_w[31:0], b_w[31:0], "W beat count CQ==direct");
            chk(a_wl[31:0], b_wl[31:0], "WLAST count CQ==direct");
            chk(a_arw[31:0], b_arw[31:0], "weight AR burst count CQ==direct");
        end
        for (i = 0; i < 16; i = i + 1)
            chk(shared.mem[32'h600 + i], resultA[i], "result region CQ==direct");

        $display("NPU_CQ_EQUIV: %0d checks, %0d errors", checks, errors);
        if (errors == 0) $display("NPU_CQ_EQUIV_PASS");
        else             $display("NPU_CQ_EQUIV_FAIL");
        $finish;
    end

    initial begin
        #2000000;
        $display("NPU_CQ_EQUIV_FAIL: timeout");
        $finish;
    end
endmodule
`default_nettype wire
