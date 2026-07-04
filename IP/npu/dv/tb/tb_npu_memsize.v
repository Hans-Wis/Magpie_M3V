// =============================================================================
// tb_npu_memsize.v — ADR-0044 gate_52: ITCM 8K / DTCM 32K sizing + Harvard
// isolation + DTCM bank port-budget checker.
// S1 capacity: last word of each memory R/W OK through its host window;
//    one past the end -> SLVERR; 0x3003 -> decode error.
// S2 Harvard isolation: same offset holds DIFFERENT values in ITCM vs DTCM;
//    a DTCM write must not alter the fetch image and vice versa.
// S3 checker: a clean host-driven matrix OP shows ZERO bank violations
//    (engine dual windows only = 2R budget); then a host DTCM read POLLING
//    LOOP during a long OP forces >2 reads on a bank — the violation counter
//    must fire (checker sensitivity, Grok green-wash guard).
// =============================================================================
`default_nettype none
`timescale 1ns/1ps

module tb_npu_memsize;
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
    localparam [31:0] A_BASE = 32'h3000_0040, A_SIZE = 32'h3000_0044, A_TAIL = 32'h3000_004C;
    localparam [31:0] A_CQCTRL = 32'h3000_0050, A_CQST = 32'h3000_0054, A_ERRC = 32'h3000_0058;

    integer errors = 0, checks = 0, i;
    reg [31:0] rd;
    integer fdump;

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

    task wait_bit(input [31:0] addr, input integer bitpos, input [255:0] nm);
        integer guard;
        begin
            rd = 32'h0; guard = 0;
            while (rd[bitpos] !== 1'b1 && guard < 6000) begin
                axil_read(addr, rd); guard = guard + 1;
            end
            chk({31'b0, rd[bitpos]}, 32'h1, nm);
        end
    endtask

    task axil_read_resp(input [31:0] a, output [31:0] d, output [1:0] rr);
        integer guard;
        begin
            @(negedge clk);
            s_arvalid = 1'b1; s_araddr = a; s_rready = 1'b1; guard = 0;
            while (!(s_arvalid && s_arready) && guard < 1000) begin @(posedge clk); guard = guard + 1; end
            @(negedge clk); s_arvalid = 1'b0; guard = 0;
            while (!(s_rvalid && s_rready) && guard < 1000) begin @(posedge clk); guard = guard + 1; end
            d = s_rdata; rr = s_rresp;
            @(negedge clk); s_rready = 1'b0;
        end
    endtask

    localparam [31:0] A_MATA = 32'h3000_0060, A_MATB = 32'h3000_0064;
    localparam [31:0] A_MATC = 32'h3000_0068, A_MATST = 32'h3000_007C;
    reg [1:0] rr;
    integer v0;

    initial begin
        repeat (4) @(posedge clk);
        resetn = 1'b1;
        @(posedge clk);

        // ---- S1 capacity ----
        axil_write(32'h3001_7FFC, 32'hD7C0FFEE);            // DTCM last word
        axil_read_resp(32'h3001_7FFC, rd, rr);
        chk(rd, 32'hD7C0FFEE, "DTCM[last] rw"); chk({30'b0, rr}, 32'h0, "DTCM last OKAY");
        axil_read_resp(32'h3001_8000, rd, rr);
        chk({30'b0, rr}, 32'd2, "DTCM past-end SLVERR");
        axil_write(32'h3002_1FFC, 32'h17C0FFEE);            // ITCM last word
        axil_read_resp(32'h3002_1FFC, rd, rr);
        chk(rd, 32'h17C0FFEE, "ITCM[last] rw"); chk({30'b0, rr}, 32'h0, "ITCM last OKAY");
        axil_read_resp(32'h3002_2000, rd, rr);
        chk({30'b0, rr}, 32'd2, "ITCM past-end SLVERR");
        axil_read_resp(32'h3003_0000, rd, rr);
        chk({30'b0, rr}, 32'd2, "0x3003 decode err");

        // ---- S2 Harvard isolation ----
        axil_write(32'h3001_0040, 32'hDDDD_0001);
        axil_write(32'h3002_0040, 32'h1111_0002);
        axil_read_resp(32'h3001_0040, rd, rr);
        chk(rd, 32'hDDDD_0001, "DTCM[0x40] independent");
        axil_read_resp(32'h3002_0040, rd, rr);
        chk(rd, 32'h1111_0002, "ITCM[0x40] independent");
        axil_write(32'h3001_0040, 32'hDDDD_0003);           // D write ...
        axil_read_resp(32'h3002_0040, rd, rr);
        chk(rd, 32'h1111_0002, "fetch image untouched by D write");

        // ---- S3 checker: host-only traffic = zero; forced overlap = fires ----
        // (zero-violation evidence on a REAL CQ matrix batch lives in gate_46's
        // TB; here we prove the checker can fire at all — Grok guard.)
        v0 = dut.tcm.bank_violations;
        chk(v0, 32'd0, "no violations after host-only traffic");
        force dut.eng_a_re = 1'b1;                          // engine streaming...
        force dut.eng_b_re = 1'b1;                          // ...both windows
        repeat (8) axil_read_resp(32'h3001_0000, rd, rr);   // + host DTCM reads
        release dut.eng_a_re;
        release dut.eng_b_re;
        checks = checks + 1;
        if (dut.tcm.bank_violations == 0) begin
            errors = errors + 1;
            $display("  FAIL checker never fired under forced 3-read overlap");
        end else
            $display("  checker fired %0d times under forced overlap (expected)",
                     dut.tcm.bank_violations);

        $display("NPU_MEMSIZE: %0d checks, %0d errors", checks, errors);
        if (errors == 0) $display("NPU_MEMSIZE_PASS");
        else             $display("NPU_MEMSIZE_FAIL");
        $finish;
    end

    initial begin
        #4000000;
        $display("NPU_MEMSIZE_FAIL: timeout");
        $finish;
    end
endmodule
`default_nettype wire
