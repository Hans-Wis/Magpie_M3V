// =============================================================================
// tb_npu_core_arb.v — ADR-0034 gate_33: DMA-vs-core TCM arbitration under overlap.
// The core runs a 300-iteration load/store loop out of the TCM while the DMA
// streams a 256-beat burst into a disjoint TCM region. Pass requires:
//   - real overlap observed (core retires instructions while the DMA engine is busy)
//   - both complete (STATUS.npu_done and STATUS.dma_done), no dma_err
//   - DMA region == source pattern, core result correct, program region intact
// This is the directed catch for ADR-0034 risk R3 (write-arbitration data loss).
// =============================================================================
`default_nettype none
`timescale 1ns/1ps

module tb_npu_core_arb;
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
    wire        m_awvalid, m_wvalid, m_wlast, m_bready;
    wire [31:0] m_awaddr, m_wdata;
    wire [ 7:0] m_awlen;
    wire [ 2:0] m_awsize;
    wire [ 1:0] m_awburst;
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
        .m_awvalid(m_awvalid), .m_awready(1'b1), .m_awaddr(m_awaddr), .m_awlen(m_awlen),
        .m_awsize(m_awsize), .m_awburst(m_awburst),
        .m_wvalid(m_wvalid), .m_wready(1'b1), .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wlast(m_wlast),
        .m_bvalid(1'b0), .m_bready(m_bready), .m_bresp(2'b00),
        .irq(irq), .npu_start(npu_start), .npu_config(npu_config)
    );

    axi_full_mem #(.WORDS(4096)) wmem (
        .clk(clk), .resetn(resetn),
        .arvalid(m_arvalid), .arready(m_arready), .araddr(m_araddr),
        .arlen(m_arlen), .arsize(m_arsize), .arburst(m_arburst),
        .rvalid(m_rvalid), .rready(m_rready), .rdata(m_rdata),
        .rlast(m_rlast), .rresp(m_rresp)
    );

    integer errors = 0;
    integer checks = 0;
    integer i;
    reg [31:0] rd;
    reg overlap_seen;
    reg done_seen, dma_done_seen;

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
        reg aw_done, w_done;
        integer guard;
        begin
            @(negedge clk);
            s_awvalid = 1'b1; s_awaddr = a;
            s_wvalid = 1'b1; s_wdata = d; s_wstrb = 4'hf;
            s_bready = 1'b0;
            aw_done = 1'b0; w_done = 1'b0; guard = 0;
            while (!(aw_done && w_done) && guard < 1000) begin
                @(posedge clk);
                if (s_awvalid && s_awready) aw_done = 1'b1;
                if (s_wvalid && s_wready)   w_done = 1'b1;
                @(negedge clk);
                if (aw_done) s_awvalid = 1'b0;
                if (w_done)  s_wvalid = 1'b0;
                guard = guard + 1;
            end
            if (!(aw_done && w_done)) begin errors = errors + 1; $display("  FAIL axil_write timeout"); end
            s_bready = 1'b1;
            guard = 0;
            while (!s_bvalid && guard < 1000) begin @(posedge clk); guard = guard + 1; end
            if (!s_bvalid) begin errors = errors + 1; $display("  FAIL axil_write B timeout"); end
            @(negedge clk);
            s_bready = 1'b0;
        end
    endtask

    task axil_read(input [31:0] a, output [31:0] d);
        integer guard;
        begin
            @(negedge clk);
            s_arvalid = 1'b1; s_araddr = a; s_rready = 1'b1;
            guard = 0;
            while (!(s_arvalid && s_arready) && guard < 1000) begin @(posedge clk); guard = guard + 1; end
            @(negedge clk);
            s_arvalid = 1'b0;
            guard = 0;
            while (!(s_rvalid && s_rready) && guard < 1000) begin @(posedge clk); guard = guard + 1; end
            d = s_rdata;
            @(negedge clk);
            s_rready = 1'b0;
        end
    endtask

    // overlap evidence: the core retired an instruction on a cycle the DMA engine was busy
    always @(posedge clk) begin
        if (!resetn) overlap_seen <= 1'b0;
        else if (dut.dma_busy_engine && dut.u_npu_core.u_core.wb_instr_retired) overlap_seen <= 1'b1;
    end

    initial begin
        repeat (4) @(posedge clk);
        resetn = 1'b1;
        @(posedge clk);

        // core program: 300-iteration store/load/increment loop at TCM word 64,
        // then DONE mailbox store, then spin. All hand-assembled rv32im.
        axil_write(32'h3001_0000, 32'h000100B7);  // lui  x1, 0x10   (mailbox base)
        axil_write(32'h3001_0004, 32'h00000293);  // addi x5, x0, 0
        axil_write(32'h3001_0008, 32'h12C00313);  // addi x6, x0, 300
        axil_write(32'h3001_000C, 32'h10502023);  // loop: sw x5, 0x100(x0)
        axil_write(32'h3001_0010, 32'h10002383);  //       lw x7, 0x100(x0)
        axil_write(32'h3001_0014, 32'h00138293);  //       addi x5, x7, 1
        axil_write(32'h3001_0018, 32'hFFF30313);  //       addi x6, x6, -1
        axil_write(32'h3001_001C, 32'hFE0318E3);  //       bne x6, x0, loop
        axil_write(32'h3001_0020, 32'h00100413);  // addi x8, x0, 1
        axil_write(32'h3001_0024, 32'h0080A023);  // sw x8, 0(x1)    (DONE)
        axil_write(32'h3001_0028, 32'h0000006F);  // jal x0, 0

        // release the core, then immediately stream a 256-beat DMA burst into
        // TCM words 512..767 (disjoint from program @0..10 and data @64)
        axil_write(32'h3000_0004, 32'h0000_0001);           // CTRL.start
        axil_write(32'h3000_0020, 32'd400);                 // DMA_SRC byte addr (word 100)
        axil_write(32'h3000_0024, 32'd512);                 // DMA_DST TCM word index
        axil_write(32'h3000_0028, 32'd256);                 // DMA_LEN beats
        axil_write(32'h3000_002C, 32'h0000_0001);           // DMA GO

        // wait for both completions
        done_seen = 1'b0; dma_done_seen = 1'b0;
        for (i = 0; i < 3000 && !(done_seen && dma_done_seen); i = i + 1) begin
            axil_read(32'h3000_0008, rd);
            if (rd[1]) done_seen = 1'b1;
            if (rd[3]) dma_done_seen = 1'b1;
        end
        chk({31'b0, done_seen}, 32'h1, "npu_done");
        chk({31'b0, dma_done_seen}, 32'h1, "dma_done");
        axil_read(32'h3000_0008, rd);
        chk({31'b0, rd[5]}, 32'h0, "no_dma_err");
        chk({31'b0, overlap_seen}, 32'h1, "true_overlap_core_retire_during_dma");

        // DMA region intact: TCM words 512..767 == source pattern words 100..355
        for (i = 0; i < 256; i = i + 1) begin
            axil_read(32'h3001_0000 + ((512 + i) * 4), rd);
            chk(rd, 32'hC0DE0000 | (100 + i), "TCM.dma_region");
        end
        // core result: 300 iterations leave mem[word64] = 299
        axil_read(32'h3001_0100, rd);
        chk(rd, 32'd299, "TCM.core_result");
        // program region untouched by DMA/core
        axil_read(32'h3001_0000, rd);
        chk(rd, 32'h000100B7, "TCM.program_word0");

        $display("NPU_CORE_ARB: %0d checks, %0d errors", checks, errors);
        if (errors == 0) $display("NPU_CORE_ARB_PASS");
        else             $display("NPU_CORE_ARB_FAIL");
        $finish;
    end

    initial begin
        #2000000;
        $display("NPU_CORE_ARB_FAIL: timeout");
        $finish;
    end
endmodule
`default_nettype wire
