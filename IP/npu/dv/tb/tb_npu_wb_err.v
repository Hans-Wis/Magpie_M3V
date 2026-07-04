// =============================================================================
// tb_npu_wb_err.v — writeback DMA must FLAG a write SLVERR and abort (ADR-0033):
// STATUS[5]=dma_err latched, STATUS[7]=wb_done NOT set, no lockup. wmem ERR_MODE=1.
// Prints NPU_WB_ERR_PASS.
// =============================================================================
`default_nettype none
`timescale 1ns/1ps
module tb_npu_wb_err;
    reg clk=0, resetn=0; always #5 clk=~clk;
    reg  s_awvalid=0,s_wvalid=0,s_bready=0,s_arvalid=0,s_rready=0;
    reg  [31:0] s_awaddr=0,s_wdata=0,s_araddr=0; reg [3:0] s_wstrb=4'hf;
    wire s_awready,s_wready,s_bvalid,s_arready,s_rvalid; wire [31:0] s_rdata; wire [1:0] s_bresp,s_rresp;
    wire m_arvalid; wire [31:0] m_araddr; wire [7:0] m_arlen; wire [2:0] m_arsize; wire [1:0] m_arburst; wire m_rready;
    wire m_awvalid,m_awready,m_wvalid,m_wready,m_wlast,m_bvalid,m_bready; wire [31:0] m_awaddr,m_wdata;
    wire [7:0] m_awlen; wire [2:0] m_awsize; wire [1:0] m_awburst,m_bresp; wire [3:0] m_wstrb;
    wire irq, npu_start; wire [31:0] npu_config;

    npu_top #(.TCM_WORDS(8192), .TCM_AW(13)) dut (
        .clk(clk),.resetn(resetn),
        .s_awvalid(s_awvalid),.s_awready(s_awready),.s_awaddr(s_awaddr),.s_awprot(3'b0),
        .s_wvalid(s_wvalid),.s_wready(s_wready),.s_wdata(s_wdata),.s_wstrb(s_wstrb),
        .s_bvalid(s_bvalid),.s_bready(s_bready),.s_bresp(s_bresp),
        .s_arvalid(s_arvalid),.s_arready(s_arready),.s_araddr(s_araddr),.s_arprot(3'b0),
        .s_rvalid(s_rvalid),.s_rready(s_rready),.s_rdata(s_rdata),.s_rresp(s_rresp),
        .m_arvalid(m_arvalid),.m_arready(1'b0),.m_araddr(m_araddr),.m_arlen(m_arlen),
        .m_arsize(m_arsize),.m_arburst(m_arburst),
        .m_rvalid(1'b0),.m_rready(m_rready),.m_rdata(32'b0),.m_rlast(1'b0),.m_rresp(2'b0),
        .m_awvalid(m_awvalid),.m_awready(m_awready),.m_awaddr(m_awaddr),.m_awlen(m_awlen),
        .m_awsize(m_awsize),.m_awburst(m_awburst),
        .m_wvalid(m_wvalid),.m_wready(m_wready),.m_wdata(m_wdata),.m_wstrb(m_wstrb),.m_wlast(m_wlast),
        .m_bvalid(m_bvalid),.m_bready(m_bready),.m_bresp(m_bresp),
        .irq(irq),.npu_start(npu_start),.npu_config(npu_config)
    );
    axi_full_wmem #(.WORDS(8192),.AW(13),.ERR_MODE(1)) errmem (
        .clk(clk),.resetn(resetn),
        .awvalid(m_awvalid),.awready(m_awready),.awaddr(m_awaddr),.awlen(m_awlen),.awsize(m_awsize),.awburst(m_awburst),
        .wvalid(m_wvalid),.wready(m_wready),.wdata(m_wdata),.wstrb(m_wstrb),.wlast(m_wlast),
        .bvalid(m_bvalid),.bready(m_bready),.bresp(m_bresp)
    );

    integer errors=0, i; reg [31:0] rd;
    task axil_write(input [31:0] a, input [31:0] d); reg awd,wdn; begin
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

    initial begin
        repeat(4)@(posedge clk); resetn=1; @(posedge clk);
        axil_write(32'h3001_0000, 32'hDEAD_0000);   // one TCM word
        axil_write(32'h3000_0030, 32'h0);           // WB_SRC
        axil_write(32'h3000_0034, 32'h8000_0000);   // WB_DST
        axil_write(32'h3000_0038, 32'h8);           // WB_LEN=8
        axil_write(32'h3000_003C, 32'h1);           // WB_GO
        // let the job run; poll STATUS until wb_busy clears or timeout
        rd=32'hFFFF; for(i=0;i<2000 && rd[6]===1'b1;i=i+1) axil_read(32'h3000_0008,rd);
        // read final status
        for(i=0;i<40;i=i+1) axil_read(32'h3000_0008,rd);
        if(rd[5]!==1'b1) begin errors=errors+1; $display("  FAIL dma_err not set on write SLVERR (status=%08x)",rd); end
        if(rd[7]===1'b1) begin errors=errors+1; $display("  FAIL wb_done set despite SLVERR (status=%08x)",rd); end
        if(rd[6]===1'b1) begin errors=errors+1; $display("  FAIL wb_busy stuck (lockup, status=%08x)",rd); end
        if(errors==0) $display("  ok   SLVERR: dma_err=1 wb_done=0 not-busy (status=%08x)", rd);
        if(errors==0) $display("NPU_WB_ERR_PASS"); else $display("NPU_WB_ERR_FAIL");
        $finish;
    end
    initial begin #200000; $display("NPU_WB_ERR_FAIL: timeout"); $finish; end
endmodule
`default_nettype wire
