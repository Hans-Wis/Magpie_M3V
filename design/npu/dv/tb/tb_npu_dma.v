// =============================================================================
// tb_npu_dma.v — Phase 1 data-plane test: host programs the DMA over the AXI4-Lite
// fabric; the DMA burst-reads a block from AXI4-full shared memory into the NPU
// local buffer. Exercises multi-burst chunking (>256 beats) AND a 4 KB-boundary
// crossing. Scoreboard checks every copied word. Prints NPU_DMA_PASS.
// =============================================================================
`default_nettype none
`timescale 1ns/1ps
module tb_npu_dma;
    reg clk = 0, resetn = 0;
    always #5 clk = ~clk;

    // ---- host-driven AXI4-Lite (upstream of fabric) ----
    reg  s_awvalid=0, s_wvalid=0, s_bready=0, s_arvalid=0, s_rready=0;
    reg  [31:0] s_awaddr=0, s_wdata=0, s_araddr=0; reg [3:0] s_wstrb=0;
    wire s_awready, s_wready, s_bvalid, s_arready, s_rvalid;
    wire [31:0] s_rdata; wire [1:0] s_bresp, s_rresp;

    // ---- fabric <-> NPU CSR (m0) ----
    wire m0_awvalid,m0_awready,m0_wvalid,m0_wready,m0_bvalid,m0_bready,m0_arvalid,m0_arready,m0_rvalid,m0_rready;
    wire [31:0] m0_awaddr,m0_wdata,m0_araddr,m0_rdata; wire [2:0] m0_awprot,m0_arprot; wire [3:0] m0_wstrb; wire [1:0] m0_bresp,m0_rresp;
    // ---- fabric <-> passthrough (m1, unused here) ----
    wire m1_awvalid,m1_awready,m1_wvalid,m1_wready,m1_bvalid,m1_bready,m1_arvalid,m1_arready,m1_rvalid,m1_rready;
    wire [31:0] m1_awaddr,m1_wdata,m1_araddr,m1_rdata; wire [2:0] m1_awprot,m1_arprot; wire [3:0] m1_wstrb; wire [1:0] m1_bresp,m1_rresp;

    // ---- NPU CSR <-> DMA ----
    wire [31:0] dma_src, dma_dst; wire [16:0] dma_len; wire dma_go, dma_busy, dma_done;
    wire npu_start; wire [31:0] npu_config;

    // ---- DMA AXI4-full master <-> weight memory ----
    wire d_arvalid,d_arready,d_rvalid,d_rready,d_rlast; wire [31:0] d_araddr,d_rdata;
    wire [7:0] d_arlen; wire [2:0] d_arsize; wire [1:0] d_arburst,d_rresp;
    // ---- DMA -> local buffer ----
    wire d_buf_we; wire [11:0] d_buf_addr; wire [31:0] d_buf_wdata;

    axil_1to2 #(.NPU_HI(4'h3)) fab (
        .clk(clk),.resetn(resetn),
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
    // tie off unused passthrough slave
    assign m1_awready=1'b1; assign m1_wready=1'b1; assign m1_bvalid=1'b0; assign m1_bresp=2'b0;
    assign m1_arready=1'b1; assign m1_rvalid=1'b0; assign m1_rdata=32'b0; assign m1_rresp=2'b0;

    npu_axil_regs npu (
        .clk(clk),.resetn(resetn),
        .s_axi_awvalid(m0_awvalid),.s_axi_awready(m0_awready),.s_axi_awaddr(m0_awaddr),.s_axi_awprot(m0_awprot),
        .s_axi_wvalid(m0_wvalid),.s_axi_wready(m0_wready),.s_axi_wdata(m0_wdata),.s_axi_wstrb(m0_wstrb),
        .s_axi_bvalid(m0_bvalid),.s_axi_bready(m0_bready),.s_axi_bresp(m0_bresp),
        .s_axi_arvalid(m0_arvalid),.s_axi_arready(m0_arready),.s_axi_araddr(m0_araddr),.s_axi_arprot(m0_arprot),
        .s_axi_rvalid(m0_rvalid),.s_axi_rready(m0_rready),.s_axi_rdata(m0_rdata),.s_axi_rresp(m0_rresp),
        .npu_start(npu_start),.npu_config(npu_config),.npu_busy(1'b0),.npu_done(1'b0),
        .dma_src(dma_src),.dma_dst(dma_dst),.dma_len(dma_len),.dma_go(dma_go),
        .dma_busy(dma_busy),.dma_done(dma_done),.dma_err(1'b0)
    );

    npu_dma #(.BUF_AW(12)) dma (
        .clk(clk),.resetn(resetn),
        .go(dma_go),.abort_i(1'b0),.write_mode(1'b0),.narrow_i(1'b0),
        .src_addr(dma_src),.dst_word(dma_dst[11:0]),.len_beats(dma_len),
        .busy(dma_busy),.done(dma_done),
        .m_arvalid(d_arvalid),.m_arready(d_arready),.m_araddr(d_araddr),.m_arlen(d_arlen),
        .m_arsize(d_arsize),.m_arburst(d_arburst),
        .m_rvalid(d_rvalid),.m_rready(d_rready),.m_rdata(d_rdata),.m_rlast(d_rlast),.m_rresp(d_rresp),
        .buf_we(d_buf_we),.buf_addr(d_buf_addr),.buf_wdata(d_buf_wdata)
    );

    axi_full_mem #(.WORDS(4096)) wmem (
        .clk(clk),.resetn(resetn),
        .arvalid(d_arvalid),.arready(d_arready),.araddr(d_araddr),.arlen(d_arlen),.arsize(d_arsize),.arburst(d_arburst),
        .rvalid(d_rvalid),.rready(d_rready),.rdata(d_rdata),.rlast(d_rlast),.rresp(d_rresp)
    );

    // local buffer written by the DMA
    reg [31:0] lbuf [0:4095];
    always @(posedge clk) if (d_buf_we) lbuf[d_buf_addr] <= d_buf_wdata;

    // ---- AXI4-Lite host BFM ----
    integer errors = 0, checks = 0, i;
    reg [31:0] rd;

    task axil_write(input [31:0] a, input [31:0] d);
        reg awd, wdn; begin
            @(negedge clk);
            s_awvalid=1; s_awaddr=a; s_wvalid=1; s_wdata=d; s_wstrb=4'hf; s_bready=0; awd=0; wdn=0;
            while(!(awd && wdn)) begin
                @(posedge clk);
                if (s_awvalid && s_awready) awd=1;
                if (s_wvalid && s_wready)  wdn=1;
                @(negedge clk);
                if (awd) s_awvalid=0;
                if (wdn) s_wvalid=0;
            end
            s_bready=1; @(posedge clk); while(!s_bvalid) @(posedge clk); @(negedge clk); s_bready=0;
        end
    endtask
    task axil_read(input [31:0] a, output [31:0] d); begin
        @(negedge clk);
        s_arvalid=1; s_araddr=a; s_rready=1;
        @(posedge clk); while(!(s_arvalid && s_arready)) @(posedge clk);
        @(negedge clk); s_arvalid=0;
        @(posedge clk); while(!(s_rvalid && s_rready)) @(posedge clk);
        d = s_rdata; @(negedge clk); s_rready=0;
    end endtask

    // test parameters: src crosses a 4KB boundary (word 1024) AND len>256 -> 3 bursts
    localparam integer SRC_WORD = 1000;
    localparam integer LEN      = 300;      // words 1000..1299

    initial begin
        repeat (4) @(posedge clk); resetn = 1; @(posedge clk);

        // program the DMA descriptor over AXI4-Lite (through the fabric)
        axil_write(32'h3000_0020, SRC_WORD*4);   // DMA_SRC (byte addr)
        axil_write(32'h3000_0024, 32'h0);        // DMA_DST (local word 0)
        axil_write(32'h3000_0028, LEN);          // DMA_LEN (beats)
        // descriptor readback sanity
        axil_read (32'h3000_0020, rd); checks=checks+1; if (rd!==SRC_WORD*4) begin errors=errors+1; $display("  FAIL DMA_SRC rb=%08x",rd); end
        axil_read (32'h3000_0028, rd); checks=checks+1; if (rd!==LEN)        begin errors=errors+1; $display("  FAIL DMA_LEN rb=%08x",rd); end

        // GO
        axil_write(32'h3000_002C, 32'h1);

        // poll STATUS bit3 (dma_done)
        rd = 0;
        for (i = 0; i < 20000 && rd[3] === 1'b0; i = i + 1) axil_read(32'h3000_0008, rd);
        checks=checks+1;
        if (rd[3] !== 1'b1) begin errors=errors+1; $display("  FAIL dma_done never set (status=%08x)", rd); end
        else $display("  ok   dma_done set, status=%08x", rd);

        // verify the copied block == weight-mem pattern 0xC0DE0000|word
        for (i = 0; i < LEN; i = i + 1) begin
            checks = checks + 1;
            if (lbuf[i] !== (32'hC0DE0000 | (SRC_WORD + i))) begin
                errors = errors + 1;
                if (errors < 8) $display("  FAIL lbuf[%0d]=%08x exp %08x", i, lbuf[i], 32'hC0DE0000|(SRC_WORD+i));
            end
        end

        $display("NPU_DMA: %0d checks, %0d errors (LEN=%0d, 3 bursts, 4KB-cross)", checks, errors, LEN);
        if (errors == 0) $display("NPU_DMA_PASS"); else $display("NPU_DMA_FAIL");
        $finish;
    end
    initial begin #200000; $display("NPU_DMA_FAIL: timeout"); $finish; end
endmodule
`default_nettype wire
