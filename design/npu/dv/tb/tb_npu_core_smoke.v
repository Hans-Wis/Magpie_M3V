// =============================================================================
// tb_npu_core_smoke.v — Phase 2 NPU scalar-core smoke test.
// Loads a tiny RV32I program into npu_top's TCM over AXI4-Lite, releases the
// embedded cpu_m1 core, and verifies DONE mailbox + core-written TCM data.
// =============================================================================
`default_nettype none
`timescale 1ns/1ps

module tb_npu_core_smoke;
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

    wire        m_arvalid, m_rready;
    wire [31:0] m_araddr;
    wire [ 7:0] m_arlen;
    wire [ 2:0] m_arsize;
    wire [ 1:0] m_arburst;
    wire        m_awvalid, m_wvalid, m_wlast, m_bready;
    wire [31:0] m_awaddr, m_wdata;
    wire [ 7:0] m_awlen;
    wire [ 2:0] m_awsize;
    wire [ 1:0] m_awburst;
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
        .m_arvalid(m_arvalid), .m_arready(1'b1), .m_araddr(m_araddr), .m_arlen(m_arlen),
        .m_arsize(m_arsize), .m_arburst(m_arburst),
        .m_rvalid(1'b0), .m_rready(m_rready), .m_rdata(32'h0), .m_rlast(1'b0), .m_rresp(2'b00),
        .m_awvalid(m_awvalid), .m_awready(1'b1), .m_awaddr(m_awaddr), .m_awlen(m_awlen),
        .m_awsize(m_awsize), .m_awburst(m_awburst),
        .m_wvalid(m_wvalid), .m_wready(1'b1), .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wlast(m_wlast),
        .m_bvalid(1'b0), .m_bready(m_bready), .m_bresp(2'b00),
        .irq(irq), .npu_start(npu_start), .npu_config(npu_config)
    );

    integer errors = 0;
    integer checks = 0;
    integer i;
    integer busy_seen;
    reg [31:0] rd;

    task fail_msg(input [255:0] nm);
        begin
            errors = errors + 1;
            $display("  FAIL %0s", nm);
        end
    endtask

    task chk(input [31:0] got, input [31:0] exp, input [255:0] nm);
        begin
            checks = checks + 1;
            if (got !== exp) begin
                errors = errors + 1;
                $display("  FAIL %0s got %08x exp %08x", nm, got, exp);
            end else begin
                $display("  ok   %0s = %08x", nm, got);
            end
        end
    endtask

    task chk_bit(input got, input exp, input [255:0] nm);
        begin
            checks = checks + 1;
            if (got !== exp) begin
                errors = errors + 1;
                $display("  FAIL %0s got %0b exp %0b", nm, got, exp);
            end else begin
                $display("  ok   %0s = %0b", nm, got);
            end
        end
    endtask

    task axil_write(input [31:0] a, input [31:0] d);
        reg aw_done;
        reg w_done;
        integer guard;
        begin
            @(negedge clk);
            s_awvalid = 1'b1;
            s_awaddr  = a;
            s_wvalid  = 1'b1;
            s_wdata   = d;
            s_wstrb   = 4'hf;
            s_bready  = 1'b0;
            aw_done = 1'b0;
            w_done = 1'b0;
            guard = 0;
            while (!(aw_done && w_done) && guard < 1000) begin
                @(posedge clk);
                if (s_awvalid && s_awready) aw_done = 1'b1;
                if (s_wvalid && s_wready)   w_done = 1'b1;
                @(negedge clk);
                if (aw_done) s_awvalid = 1'b0;
                if (w_done)  s_wvalid = 1'b0;
                guard = guard + 1;
            end
            if (!(aw_done && w_done)) fail_msg("AXIL write address/data timeout");
            s_bready = 1'b1;
            guard = 0;
            while (!s_bvalid && guard < 1000) begin
                @(posedge clk);
                guard = guard + 1;
            end
            if (!s_bvalid) fail_msg("AXIL write response timeout");
            else if (s_bresp !== 2'b00) begin
                errors = errors + 1;
                $display("  FAIL AXIL write BRESP addr %08x resp %0d", a, s_bresp);
            end
            @(negedge clk);
            s_bready = 1'b0;
        end
    endtask

    task axil_read(input [31:0] a, output [31:0] d);
        integer guard;
        begin
            @(negedge clk);
            s_arvalid = 1'b1;
            s_araddr  = a;
            s_rready  = 1'b1;
            guard = 0;
            while (!(s_arvalid && s_arready) && guard < 1000) begin
                @(posedge clk);
                guard = guard + 1;
            end
            if (!(s_arvalid && s_arready)) fail_msg("AXIL read address timeout");
            @(negedge clk);
            s_arvalid = 1'b0;
            guard = 0;
            while (!(s_rvalid && s_rready) && guard < 1000) begin
                @(posedge clk);
                guard = guard + 1;
            end
            d = s_rdata;
            if (!(s_rvalid && s_rready)) fail_msg("AXIL read data timeout");
            else if (s_rresp !== 2'b00) begin
                errors = errors + 1;
                $display("  FAIL AXIL read RRESP addr %08x resp %0d", a, s_rresp);
            end
            @(negedge clk);
            s_rready = 1'b0;
        end
    endtask

    task load_program(input [31:0] word1);
        begin
            axil_write(32'h3002_0000, 32'h000100B7);
            axil_write(32'h3002_0004, word1);
            axil_write(32'h3002_0008, 32'h10202023);
            axil_write(32'h3002_000C, 32'h00100213);
            axil_write(32'h3002_0010, 32'h0040A023);
            axil_write(32'h3002_0014, 32'h0000006F);
        end
    endtask

    task wait_done;
        begin
            busy_seen = 0;
            rd = 32'h0;
            for (i = 0; i < 2000 && rd[1] !== 1'b1; i = i + 1) begin
                axil_read(32'h3000_0008, rd);
                if (rd[0]) busy_seen = 1;
            end
            if (rd[1] !== 1'b1) fail_msg("STATUS.done timeout");
            chk({31'b0, busy_seen[0]}, 32'h0000_0001, "STATUS.busy_seen");
        end
    endtask

    initial begin
        repeat (4) @(posedge clk);
        resetn = 1'b1;
        @(posedge clk);

        load_program(32'h02A00113);

        axil_read(32'h3000_0008, rd);
        chk({30'b0, rd[1:0]}, 32'h0000_0000, "STATUS.before_start");
        chk_bit(dut.core_resetn, 1'b0, "core_resetn.before_start");

        axil_write(32'h3000_0004, 32'h0000_0009);
        wait_done();

        axil_read(32'h3001_0100, rd);
        chk(rd, 32'd42, "TCM.core_store.42");
        chk_bit(irq, 1'b1, "irq_after_done");

        axil_write(32'h3000_0004, 32'h0000_000B);
        chk_bit(irq, 1'b0, "irq_cleared");
        axil_read(32'h3000_0008, rd);
        chk({30'b0, rd[1:0]}, 32'h0000_0002, "STATUS.after_done");

        axil_write(32'h3000_0004, 32'h0000_0000);
        axil_read(32'h3000_0008, rd);
        chk({30'b0, rd[1:0]}, 32'h0000_0000, "STATUS.done_cleared");

        axil_write(32'h3002_0004, 32'h03700113);
        axil_write(32'h3000_0004, 32'h0000_0009);
        wait_done();
        axil_read(32'h3001_0100, rd);
        chk(rd, 32'd55, "TCM.core_store.55");

        $display("NPU_CORE_SMOKE: %0d checks, %0d errors", checks, errors);
        if (errors == 0) $display("NPU_CORE_SMOKE_PASS");
        else             $display("NPU_CORE_SMOKE_FAIL");
        $finish;
    end

    initial begin
        #300000;
        $display("NPU_CORE_SMOKE_FAIL: timeout");
        $display("NPU_CORE_SMOKE: %0d checks, %0d errors", checks, errors + 1);
        $finish;
    end
endmodule
`default_nettype wire
