// =============================================================================
// tb_dma_err.v — Phase 1.5: DMA must flag SLVERR reads (Codex #8), not silently
// write bad data and report success. Weight mem returns SLVERR (ERR_MODE=1).
// Prints DMA_ERR_PASS if the DMA raises `err` and still terminates (`done`).
// =============================================================================
`default_nettype none
`timescale 1ns/1ps
module tb_dma_err;
    reg clk=0, resetn=0; always #5 clk=~clk;
    reg go=0; reg [31:0] src=0; reg [9:0] dst=0; reg [16:0] len=0;
    wire busy, done, err;
    wire arvalid,arready,rvalid,rready,rlast; wire [31:0] araddr,rdata;
    wire [7:0] arlen; wire [2:0] arsize; wire [1:0] arburst,rresp;
    wire buf_we; wire [11:0] buf_addr; wire [31:0] buf_wdata;

    npu_dma #(.BUF_AW(12)) dma (
        .clk(clk),.resetn(resetn),.go(go),.src_addr(src),.dst_word(dst),.len_beats(len),
        .busy(busy),.done(done),.err(err),
        .m_arvalid(arvalid),.m_arready(arready),.m_araddr(araddr),.m_arlen(arlen),
        .m_arsize(arsize),.m_arburst(arburst),
        .m_rvalid(rvalid),.m_rready(rready),.m_rdata(rdata),.m_rlast(rlast),.m_rresp(rresp),
        .buf_we(buf_we),.buf_addr(buf_addr),.buf_wdata(buf_wdata)
    );
    axi_full_mem #(.WORDS(4096), .ERR_MODE(1)) errmem (
        .clk(clk),.resetn(resetn),
        .arvalid(arvalid),.arready(arready),.araddr(araddr),.arlen(arlen),.arsize(arsize),.arburst(arburst),
        .rvalid(rvalid),.rready(rready),.rdata(rdata),.rlast(rlast),.rresp(rresp)
    );

    integer i, errors=0;
    initial begin
        repeat(4)@(posedge clk); resetn=1; @(posedge clk);
        @(negedge clk); src=32'h40; dst=0; len=17'd8; go=1;
        @(negedge clk); go=0;
        for(i=0;i<2000 && !done;i=i+1) @(posedge clk);
        if(!done)      begin errors=errors+1; $display("  FAIL dma never done"); end
        if(err!==1'b1) begin errors=errors+1; $display("  FAIL err not set on SLVERR (err=%b)",err); end
        else $display("  ok   SLVERR flagged: done=%b err=%b", done, err);
        if(errors==0) $display("DMA_ERR_PASS"); else $display("DMA_ERR_FAIL");
        $finish;
    end
    initial begin #100000; $display("DMA_ERR_FAIL: timeout"); $finish; end
endmodule
`default_nettype wire
