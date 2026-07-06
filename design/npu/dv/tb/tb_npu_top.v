// =============================================================================
// tb_npu_top.v — Phase 1 SEALED integration test of the NPU subsystem.
// Drives npu_top's AXI4-Lite slave (host side); AXI4-full master feeds a weight
// memory. Verifies: CSR access, TCM host load/readback, DMA stream into TCM,
// CSR-vs-TCM address decode, IRQ assert on completion + clear, and that the
// host-loaded TCM region is not clobbered by the DMA region. Prints NPU_TOP_PASS.
// =============================================================================
`default_nettype none
`timescale 1ns/1ps
module tb_npu_top;
    reg clk=0, resetn=0; always #5 clk=~clk;

    reg  s_awvalid=0,s_wvalid=0,s_bready=0,s_arvalid=0,s_rready=0;
    reg  [31:0] s_awaddr=0,s_wdata=0,s_araddr=0; reg [3:0] s_wstrb=0;
    wire s_awready,s_wready,s_bvalid,s_arready,s_rvalid; wire [31:0] s_rdata; wire [1:0] s_bresp,s_rresp;

    wire d_arvalid,d_arready,d_rvalid,d_rready,d_rlast; wire [31:0] d_araddr,d_rdata;
    wire [7:0] d_arlen; wire [2:0] d_arsize; wire [1:0] d_arburst,d_rresp;
    wire irq, npu_start; wire [31:0] npu_config;

    npu_top #(.TCM_WORDS(8192), .TCM_AW(13)) dut (
        .clk(clk),.resetn(resetn),
        .s_awvalid(s_awvalid),.s_awready(s_awready),.s_awaddr(s_awaddr),.s_awprot(3'b0),
        .s_wvalid(s_wvalid),.s_wready(s_wready),.s_wdata(s_wdata),.s_wstrb(s_wstrb),
        .s_bvalid(s_bvalid),.s_bready(s_bready),.s_bresp(s_bresp),
        .s_arvalid(s_arvalid),.s_arready(s_arready),.s_araddr(s_araddr),.s_arprot(3'b0),
        .s_rvalid(s_rvalid),.s_rready(s_rready),.s_rdata(s_rdata),.s_rresp(s_rresp),
        .m_arvalid(d_arvalid),.m_arready(d_arready),.m_araddr(d_araddr),.m_arlen(d_arlen),
        .m_arsize(d_arsize),.m_arburst(d_arburst),
        .m_rvalid(d_rvalid),.m_rready(d_rready),.m_rdata(d_rdata),.m_rlast(d_rlast),.m_rresp(d_rresp),
        .irq(irq),.npu_start(npu_start),.npu_config(npu_config)
    );
    axi_full_mem #(.WORDS(4096)) wmem (
        .clk(clk),.resetn(resetn),
        .arvalid(d_arvalid),.arready(d_arready),.araddr(d_araddr),.arlen(d_arlen),.arsize(d_arsize),.arburst(d_arburst),
        .rvalid(d_rvalid),.rready(d_rready),.rdata(d_rdata),.rlast(d_rlast),.rresp(d_rresp)
    );

    integer errors=0, checks=0, i; reg [31:0] rd;
    task axil_write(input [31:0] a, input [31:0] d);
        reg awd,wdn; begin
            @(negedge clk); s_awvalid=1;s_awaddr=a;s_wvalid=1;s_wdata=d;s_wstrb=4'hf;s_bready=0;awd=0;wdn=0;
            while(!(awd&&wdn)) begin @(posedge clk); if(s_awvalid&&s_awready)awd=1; if(s_wvalid&&s_wready)wdn=1;
                @(negedge clk); if(awd)s_awvalid=0; if(wdn)s_wvalid=0; end
            s_bready=1; @(posedge clk); while(!s_bvalid)@(posedge clk); @(negedge clk); s_bready=0;
        end endtask
    task axil_read(input [31:0] a, output [31:0] d); begin
            @(negedge clk); s_arvalid=1;s_araddr=a;s_rready=1;
            @(posedge clk); while(!(s_arvalid&&s_arready))@(posedge clk); @(negedge clk); s_arvalid=0;
            @(posedge clk); while(!(s_rvalid&&s_rready))@(posedge clk); d=s_rdata; @(negedge clk); s_rready=0;
        end endtask
    task chk(input [31:0] got, input [31:0] exp, input [127:0] nm); begin
            checks=checks+1;
            if(got!==exp) begin errors=errors+1; $display("  FAIL %0s got %08x exp %08x",nm,got,exp); end
            else $display("  ok   %0s = %08x",nm,got); end endtask

    localparam integer SRC_WORD=100, LEN=16;
    initial begin
        repeat(4)@(posedge clk); resetn=1; @(posedge clk);

        // CSR: ID + decode (0x3000 window)
        axil_read(32'h3000_0000, rd); chk(rd,32'h4E505530,"CSR.ID");
        // TCM host load/readback (0x3001 window, word 64) — must survive the DMA below
        axil_write(32'h3001_0100, 32'hBEEF0001);
        axil_read (32'h3001_0100, rd); chk(rd,32'hBEEF0001,"TCM.host[64]");
        // enable IRQ (CTRL bit3)
        axil_write(32'h3000_0004, 32'h0000_0008);
        chk({31'b0,irq},32'h0,"irq_before");           // nothing pending yet

        // program + launch DMA: weight mem word 100.. -> TCM word 0..15
        axil_write(32'h3000_0020, SRC_WORD*4);
        axil_write(32'h3000_0024, 32'h0);
        axil_write(32'h3000_0028, LEN);
        axil_write(32'h3000_002C, 32'h1);              // GO
        rd=0; for(i=0;i<5000 && rd[3]===1'b0;i=i+1) axil_read(32'h3000_0008,rd);
        chk({28'b0,rd[3]},32'h1,"dma_done");
        chk({31'b0,irq},32'h1,"irq_after_done");       // completion raised IRQ

        // DMA-streamed weights landed in TCM word 0..15
        for(i=0;i<LEN;i=i+1) begin
            axil_read(32'h3001_0000 + i*4, rd);
            chk(rd, 32'hC0DE0000|(SRC_WORD+i), "TCM.dma");
        end
        // host-loaded word 64 not clobbered by the DMA region
        axil_read(32'h3001_0100, rd); chk(rd,32'hBEEF0001,"TCM.host[64].intact");

        // clear IRQ (CTRL bit1) while keeping enable (bit3)
        axil_write(32'h3000_0004, 32'h0000_000A);
        chk({31'b0,irq},32'h0,"irq_cleared");

        $display("NPU_TOP: %0d checks, %0d errors",checks,errors);
        if(errors==0) $display("NPU_TOP_PASS"); else $display("NPU_TOP_FAIL");
        $finish;
    end
    initial begin #200000; $display("NPU_TOP_FAIL: timeout"); $finish; end
endmodule
`default_nettype wire
