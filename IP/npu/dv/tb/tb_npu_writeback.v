// =============================================================================
// tb_npu_writeback.v — authoritative result-writeback DMA scoreboard (ADR-0033).
// Host preloads a golden pattern into TCM (via AXI-Lite), programs WB_SRC/DST/LEN,
// pulses WB_GO; the NPU write master streams TCM->shared mem. On wb_done, compare
// shared-mem contents == TCM golden. Stimulus crosses a 4KB boundary and exceeds
// 256 beats to exercise write-side chunking. Prints NPU_WB_PASS.
// =============================================================================
`default_nettype none
`timescale 1ns/1ps
module tb_npu_writeback;
    reg clk=0, resetn=0; always #5 clk=~clk;
    reg  s_awvalid=0,s_wvalid=0,s_bready=0,s_arvalid=0,s_rready=0;
    reg  [31:0] s_awaddr=0,s_wdata=0,s_araddr=0; reg [3:0] s_wstrb=4'hf;
    wire s_awready,s_wready,s_bvalid,s_arready,s_rvalid; wire [31:0] s_rdata; wire [1:0] s_bresp,s_rresp;
    // read master (unused here) — tie off
    wire m_arvalid; wire [31:0] m_araddr; wire [7:0] m_arlen; wire [2:0] m_arsize; wire [1:0] m_arburst; wire m_rready;
    // write master -> wmem
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
    axi_full_wmem #(.WORDS(8192),.AW(13),.ERR_MODE(0)) wmem (
        .clk(clk),.resetn(resetn),
        .awvalid(m_awvalid),.awready(m_awready),.awaddr(m_awaddr),.awlen(m_awlen),.awsize(m_awsize),.awburst(m_awburst),
        .wvalid(m_wvalid),.wready(m_wready),.wdata(m_wdata),.wstrb(m_wstrb),.wlast(m_wlast),
        .bvalid(m_bvalid),.bready(m_bready),.bresp(m_bresp)
    );

    integer errors=0, checks=0, i; reg [31:0] rd;
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

    localparam integer LEN = 300;              // > 256 beats
    localparam [31:0]  WB_DST = 32'h8000_0FA0;  // byte addr -> word 1000, crosses 4KB @ word 1024
    localparam integer DST_W = 32'h0FA0 >> 2;   // = 1000 (wmem window index)

    initial begin
        repeat(4)@(posedge clk); resetn=1; @(posedge clk);
        // 1) host preloads TCM words 0..LEN-1 with golden pattern
        for (i=0;i<LEN;i=i+1) axil_write(32'h3001_0000 + i*4, 32'hB000_0000 | i);
        // 2) program writeback descriptor: TCM word 0 -> shared WB_DST, LEN beats
        axil_write(32'h3000_0030, 32'h0);        // WB_SRC (TCM word 0)
        axil_write(32'h3000_0034, WB_DST);       // WB_DST (shared byte addr)
        axil_write(32'h3000_0038, LEN);          // WB_LEN (beats)
        axil_write(32'h3000_003C, 32'h1);        // WB_GO
        // 3) poll STATUS[7]=wb_done
        rd=0; for(i=0;i<20000 && rd[7]===1'b0;i=i+1) axil_read(32'h3000_0008,rd);
        checks=checks+1;
        if(rd[7]!==1'b1) begin errors=errors+1; $display("  FAIL wb_done never set (status=%08x)",rd); end
        else $display("  ok   wb_done set, status=%08x", rd);
        checks=checks+1; if(rd[5]!==1'b0) begin errors=errors+1; $display("  FAIL spurious dma_err on clean run"); end
        // 4) scoreboard: shared mem == TCM golden
        for (i=0;i<LEN;i=i+1) begin
            checks=checks+1;
            if (wmem.mem[DST_W + i] !== (32'hB000_0000 | i)) begin
                errors=errors+1;
                if (errors<8) $display("  FAIL wmem[%0d]=%08x exp %08x", DST_W+i, wmem.mem[DST_W+i], 32'hB000_0000|i);
            end
        end
        $display("NPU_WB: %0d checks, %0d errors (LEN=%0d, 4KB-cross write)", checks, errors, LEN);
        if(errors==0) $display("NPU_WB_PASS"); else $display("NPU_WB_FAIL");
        $finish;
    end
    initial begin #400000; $display("NPU_WB_FAIL: timeout"); $finish; end
endmodule
`default_nettype wire
