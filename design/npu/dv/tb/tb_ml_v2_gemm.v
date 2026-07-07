`default_nettype none
`timescale 1ns/1ps

module tb_ml_v2_gemm;
    parameter integer MAT_LANES = 4;
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

    npu_top #(.TCM_WORDS(8192), .TCM_AW(13), .MAT_LANES(MAT_LANES), .ML_V2_EN(1)) dut (
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
        $readmemh("design/npu/sw/ml_job_driver/ml_job_driver.hex", dut.tcm.mem);
        $readmemh("design/npu/sw/ml_job_driver/ml_job_driver.hex", dut.itcm.mem);
        $readmemh("sim/work/ml_v2_gemm/ml_v2_shared.hex", shared.mem);
    end

    localparam [31:0] A_CTRL = 32'h3000_0004, A_STATUS = 32'h3000_0008;

    integer errors = 0, checks = 0, i;
    reg [31:0] rd;
    integer fdump;
    reg [31:0] meta [0:1];
    integer ml_v2_cycles = 0;
    integer ml_mat_busy = 0, ml_dma_busy = 0;   // component breakdown vs firmware profile
    reg cycle_on = 1'b0;

    initial begin
        $readmemh("sim/work/ml_v2_gemm/ml_v2_meta.hex", meta);
    end

    always @(posedge clk) begin
        if (cycle_on) begin
            ml_v2_cycles = ml_v2_cycles + 1;
            if (dut.mat_busy)         ml_mat_busy = ml_mat_busy + 1;
            if (dut.dma_busy_engine)  ml_dma_busy = ml_dma_busy + 1;
        end
    end

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

    task wait_done;
        integer guard;
        begin
            rd = 32'h0; guard = 0;
            while (rd[1] !== 1'b1 && guard < 200000) begin
                axil_read(A_STATUS, rd);
                guard = guard + 1;
            end
            chk({31'b0, rd[1]}, 32'h1, "ML firmware DONE mailbox");
        end
    endtask

    initial begin
        repeat (4) @(posedge clk);
        resetn = 1'b1;
        @(posedge clk);

        cycle_on = 1'b1;
        axil_write(A_CTRL, 32'h1);
        wait_done();
        cycle_on = 1'b0;

        fdump = $fopen("sim/work/ml_v2_gemm/result.dump", "w");
        for (i = 0; i < meta[1]; i = i + 1)
            $fdisplay(fdump, "%08x", shared.mem[32'h600 + i]);
        $fclose(fdump);

        $display("ML_V2_CYCLES=%0d", ml_v2_cycles);
        $display("ML_V2_BREAKDOWN mat_busy=%0d dma_busy=%0d other=%0d",
                 ml_mat_busy, ml_dma_busy, ml_v2_cycles - ml_mat_busy - ml_dma_busy);
        $display("ML_V2_GEMM: %0d checks, %0d errors", checks, errors);
        if (errors == 0) $display("ML_V2_GEMM_PASS");
        else             $display("ML_V2_GEMM_FAIL");
        $finish;
    end

    initial begin
        #12000000;
        $display("ML_V2_GEMM_FAIL: timeout");
        $finish;
    end
endmodule
`default_nettype wire
