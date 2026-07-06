// =============================================================================
// tb_axil_fabric.v — Phase 1 AXI4-Lite fabric self-checking testbench.
// Host-master BFM -> axil_1to2 router -> {NPU CSR slave (0x3xxx), mem slave (else)}.
// Scoreboard: every read must match the expected value; NPU/passthrough routing
// verified; transaction count checked. Prints AXIL_FABRIC_PASS on success.
// =============================================================================
`default_nettype none
`timescale 1ns/1ps
module tb_axil_fabric;
    reg clk = 0, resetn = 0;
    always #5 clk = ~clk;

    // ---- upstream master-driven AXI4-Lite wires ----
    reg  s_awvalid=0, s_wvalid=0, s_bready=0, s_arvalid=0, s_rready=0;
    reg  [31:0] s_awaddr=0, s_wdata=0, s_araddr=0; reg [3:0] s_wstrb=0;
    wire s_awready, s_wready, s_bvalid, s_arready, s_rvalid;
    wire [31:0] s_rdata; wire [1:0] s_bresp, s_rresp;

    // ---- router <-> slave0 (NPU) ----
    wire m0_awvalid,m0_awready,m0_wvalid,m0_wready,m0_bvalid,m0_bready,m0_arvalid,m0_arready,m0_rvalid,m0_rready;
    wire [31:0] m0_awaddr,m0_wdata,m0_araddr,m0_rdata; wire [2:0] m0_awprot,m0_arprot; wire [3:0] m0_wstrb; wire [1:0] m0_bresp,m0_rresp;
    // ---- router <-> slave1 (mem/passthrough) ----
    wire m1_awvalid,m1_awready,m1_wvalid,m1_wready,m1_bvalid,m1_bready,m1_arvalid,m1_arready,m1_rvalid,m1_rready;
    wire [31:0] m1_awaddr,m1_wdata,m1_araddr,m1_rdata; wire [2:0] m1_awprot,m1_arprot; wire [3:0] m1_wstrb; wire [1:0] m1_bresp,m1_rresp;

    wire npu_start; wire [31:0] npu_config;

    axil_1to2 #(.NPU_HI(4'h3)) fab (
        .clk(clk), .resetn(resetn),
        .s_awvalid(s_awvalid),.s_awready(s_awready),.s_awaddr(s_awaddr),.s_awprot(3'b0),
        .s_wvalid(s_wvalid),.s_wready(s_wready),.s_wdata(s_wdata),.s_wstrb(s_wstrb),
        .s_bvalid(s_bvalid),.s_bready(s_bready),.s_bresp(s_bresp),
        .s_arvalid(s_arvalid),.s_arready(s_arready),.s_araddr(s_araddr),.s_arprot(3'b0),
        .s_rvalid(s_rvalid),.s_rready(s_rready),.s_rdata(s_rdata),.s_rresp(s_rresp),
        .m0_awvalid(m0_awvalid),.m0_awready(m0_awready),.m0_awaddr(m0_awaddr),.m0_awprot(m0_awprot),
        .m0_wvalid(m0_wvalid),.m0_wready(m0_wready),.m0_wdata(m0_wdata),.m0_wstrb(m0_wstrb),
        .m0_bvalid(m0_bvalid),.m0_bready(m0_bready),.m0_bresp(m0_bresp),
        .m0_arvalid(m0_arvalid),.m0_arready(m0_arready),.m0_araddr(m0_araddr),.m0_arprot(m0_arprot),
        .m0_rvalid(m0_rvalid),.m0_rready(m0_rready),.m0_rdata(m0_rdata),.m0_rresp(m0_rresp),
        .m1_awvalid(m1_awvalid),.m1_awready(m1_awready),.m1_awaddr(m1_awaddr),.m1_awprot(m1_awprot),
        .m1_wvalid(m1_wvalid),.m1_wready(m1_wready),.m1_wdata(m1_wdata),.m1_wstrb(m1_wstrb),
        .m1_bvalid(m1_bvalid),.m1_bready(m1_bready),.m1_bresp(m1_bresp),
        .m1_arvalid(m1_arvalid),.m1_arready(m1_arready),.m1_araddr(m1_araddr),.m1_arprot(m1_arprot),
        .m1_rvalid(m1_rvalid),.m1_rready(m1_rready),.m1_rdata(m1_rdata),.m1_rresp(m1_rresp)
    );

    npu_axil_regs npu (
        .clk(clk), .resetn(resetn),
        .s_axi_awvalid(m0_awvalid),.s_axi_awready(m0_awready),.s_axi_awaddr(m0_awaddr),.s_axi_awprot(m0_awprot),
        .s_axi_wvalid(m0_wvalid),.s_axi_wready(m0_wready),.s_axi_wdata(m0_wdata),.s_axi_wstrb(m0_wstrb),
        .s_axi_bvalid(m0_bvalid),.s_axi_bready(m0_bready),.s_axi_bresp(m0_bresp),
        .s_axi_arvalid(m0_arvalid),.s_axi_arready(m0_arready),.s_axi_araddr(m0_araddr),.s_axi_arprot(m0_arprot),
        .s_axi_rvalid(m0_rvalid),.s_axi_rready(m0_rready),.s_axi_rdata(m0_rdata),.s_axi_rresp(m0_rresp),
        .npu_start(npu_start),.npu_config(npu_config),.npu_busy(1'b0),.npu_done(1'b0),
        .dma_src(),.dma_dst(),.dma_len(),.dma_go(),.dma_busy(1'b0),.dma_done(1'b0),.dma_err(1'b0)
    );

    axil_mem16 mem (
        .clk(clk), .resetn(resetn),
        .s_axi_awvalid(m1_awvalid),.s_axi_awready(m1_awready),.s_axi_awaddr(m1_awaddr),.s_axi_awprot(m1_awprot),
        .s_axi_wvalid(m1_wvalid),.s_axi_wready(m1_wready),.s_axi_wdata(m1_wdata),.s_axi_wstrb(m1_wstrb),
        .s_axi_bvalid(m1_bvalid),.s_axi_bready(m1_bready),.s_axi_bresp(m1_bresp),
        .s_axi_arvalid(m1_arvalid),.s_axi_arready(m1_arready),.s_axi_araddr(m1_araddr),.s_axi_arprot(m1_arprot),
        .s_axi_rvalid(m1_rvalid),.s_axi_rready(m1_rready),.s_axi_rdata(m1_rdata),.s_axi_rresp(m1_rresp)
    );

    integer errors = 0, checks = 0;
    reg [31:0] rd;

    task axil_write(input [31:0] a, input [31:0] d);
        reg awd, wdn;
        begin
            @(negedge clk);
            s_awvalid=1; s_awaddr=a; s_wvalid=1; s_wdata=d; s_wstrb=4'hf; s_bready=0;
            awd=0; wdn=0;
            while(!(awd && wdn)) begin
                @(posedge clk);
                if (s_awvalid && s_awready) awd=1;
                if (s_wvalid && s_wready)  wdn=1;
                @(negedge clk);
                if (awd) s_awvalid=0;
                if (wdn) s_wvalid=0;
            end
            s_bready=1;
            @(posedge clk); while(!s_bvalid) @(posedge clk);
            @(negedge clk); s_bready=0;
        end
    endtask

    task axil_read(input [31:0] a, output [31:0] d);
        begin
            @(negedge clk);
            s_arvalid=1; s_araddr=a; s_rready=1;
            @(posedge clk); while(!(s_arvalid && s_arready)) @(posedge clk);
            @(negedge clk); s_arvalid=0;
            @(posedge clk); while(!(s_rvalid && s_rready)) @(posedge clk);
            d = s_rdata;
            @(negedge clk); s_rready=0;
        end
    endtask

    task expect_eq(input [31:0] got, input [31:0] exp, input [127:0] name);
        begin
            checks = checks + 1;
            if (got !== exp) begin
                errors = errors + 1;
                $display("  FAIL %0s: got %08x exp %08x", name, got, exp);
            end else
                $display("  ok   %0s = %08x", name, got);
        end
    endtask

    initial begin
        repeat (4) @(posedge clk);
        resetn = 1;
        @(posedge clk);

        // 1) NPU present: ID reg (RO)
        axil_read(32'h3000_0000, rd);           expect_eq(rd, 32'h4E505530, "NPU.ID");
        // 2) SCRATCH round-trip (RW) via NPU slave
        axil_write(32'h3000_0010, 32'hDEAD_BEEF);
        axil_read (32'h3000_0010, rd);          expect_eq(rd, 32'hDEAD_BEEF, "NPU.SCRATCH");
        // 3) CONFIG round-trip + reaches npu_config output
        axil_write(32'h3000_000C, 32'h1234_5678);
        axil_read (32'h3000_000C, rd);          expect_eq(rd, 32'h1234_5678, "NPU.CONFIG");
        expect_eq(npu_config, 32'h1234_5678, "npu_config_out");
        // 4) CTRL start bit -> npu_start
        axil_write(32'h3000_0004, 32'h0000_0001);
        expect_eq({31'b0, npu_start}, 32'h1, "npu_start");
        // 5) STATUS RO reflects busy/done inputs (both 0 here)
        axil_read (32'h3000_0008, rd);          expect_eq(rd, 32'h0, "NPU.STATUS");
        // 6) routing: a non-NPU address hits the passthrough mem slave, not NPU
        axil_write(32'h2000_0008, 32'hCAFE_F00D);
        axil_read (32'h2000_0008, rd);          expect_eq(rd, 32'hCAFE_F00D, "PASS.mem[2]");
        // 7) NPU ID still intact after passthrough traffic (no cross-talk)
        axil_read (32'h3000_0000, rd);          expect_eq(rd, 32'h4E505530, "NPU.ID.again");

        $display("AXIL_FABRIC: %0d checks, %0d errors", checks, errors);
        if (errors == 0) $display("AXIL_FABRIC_PASS");
        else             $display("AXIL_FABRIC_FAIL");
        $finish;
    end

    initial begin
        #20000;
        $display("AXIL_FABRIC_FAIL: timeout");
        $finish;
    end
endmodule
`default_nettype wire
