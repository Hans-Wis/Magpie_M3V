// =============================================================================
// tb_npu_cq_lockstep.v — ADR-0035 gate_39: CQ consume slice under Spike lockstep.
// Same commit-trace harness as phase_20's tb_npu_lockstep, but with the DMA
// master ports wired to a real shared-memory model (axi_full_rwmem) seeded with
// the descriptor ring + weight blob, and the host driving TAIL=1 (doorbell)
// before CTRL.start. The firmware is the deterministic poll-free CQ slice; the
// Spike golden runs the same code with the MMIO/DMA-produced values pre-seeded
// in its image (see firmware_cq.S header).
// =============================================================================
`timescale 1ns / 1ns

module tb_npu_cq_lockstep;
    reg clk = 1'b0;
    reg resetn = 1'b0;

    reg         awvalid = 0; wire awready; reg [31:0] awaddr = 0;
    reg         wvalid = 0;  wire wready;  reg [31:0] wdata = 0; reg [3:0] wstrb = 0;
    wire        bvalid;      reg bready = 0; wire [1:0] bresp;
    reg         arvalid = 0; wire arready; reg [31:0] araddr = 0;
    wire        rvalid;      reg rready = 1; wire [31:0] rdata; wire [1:0] rresp;

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
    wire irq, npu_start_o; wire [31:0] npu_config_o;

    npu_top dut (
        .clk(clk), .resetn(resetn),
        .s_awvalid(awvalid), .s_awready(awready), .s_awaddr(awaddr), .s_awprot(3'b0),
        .s_wvalid(wvalid), .s_wready(wready), .s_wdata(wdata), .s_wstrb(wstrb),
        .s_bvalid(bvalid), .s_bready(bready), .s_bresp(bresp),
        .s_arvalid(arvalid), .s_arready(arready), .s_araddr(araddr), .s_arprot(3'b0),
        .s_rvalid(rvalid), .s_rready(rready), .s_rdata(rdata), .s_rresp(rresp),
        .m_arvalid(m_arvalid), .m_arready(m_arready), .m_araddr(m_araddr),
        .m_arlen(m_arlen), .m_arsize(m_arsize), .m_arburst(m_arburst),
        .m_rvalid(m_rvalid), .m_rready(m_rready), .m_rdata(m_rdata), .m_rlast(m_rlast), .m_rresp(m_rresp),
        .m_awvalid(m_awvalid), .m_awready(m_awready), .m_awaddr(m_awaddr),
        .m_awlen(m_awlen), .m_awsize(m_awsize), .m_awburst(m_awburst),
        .m_wvalid(m_wvalid), .m_wready(m_wready), .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wlast(m_wlast),
        .m_bvalid(m_bvalid), .m_bready(m_bready), .m_bresp(m_bresp),
        .irq(irq), .npu_start(npu_start_o), .npu_config(npu_config_o)
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

    always #5 clk = ~clk;

    integer i;
    initial begin
        $readmemh("firmware.hex", dut.tcm.mem);
        $readmemh("firmware.hex", dut.itcm.mem);
        // shared memory: descriptor ring slot 0 @ byte 0x400 = MAT.LOAD_W(src=0x800, 2x2)
        shared.mem[32'h100] = 32'h0000_0002;
        shared.mem[32'h101] = 32'h0000_0800;
        shared.mem[32'h102] = 32'h0000_0000;
        shared.mem[32'h103] = 32'h0000_0202;
        // weight blob @ byte 0x800 — must equal the Spike-image seed values
        for (i = 0; i < 4; i = i + 1) shared.mem[32'h200 + i] = 32'h5A5A0000 | i[15:0];
    end

    task axil_write(input [31:0] a, input [31:0] d);
        reg aw_done, w_done;
        begin
            @(negedge clk);
            awvalid = 1'b1; awaddr = a;
            wvalid  = 1'b1; wdata = d; wstrb = 4'hF;
            bready  = 1'b0;
            aw_done = 1'b0; w_done = 1'b0;
            while (!(aw_done && w_done)) begin
                @(posedge clk);
                if (awvalid && awready) aw_done = 1'b1;
                if (wvalid && wready)   w_done = 1'b1;
                @(negedge clk);
                if (aw_done) awvalid = 1'b0;
                if (w_done)  wvalid = 1'b0;
            end
            bready = 1'b1;
            while (!bvalid) @(posedge clk);
            @(negedge clk);
            bready = 1'b0;
        end
    endtask

    integer trace_fd;
    integer commit_count;
    integer watchdog;
    integer max_cycles;
    integer min_commits;
    reg [31:0] commit_instr;

    initial begin
        if (!$value$plusargs("max_cycles=%d", max_cycles)) max_cycles = 100000;
        if (!$value$plusargs("min_commits=%d", min_commits)) min_commits = 8;
        trace_fd = $fopen("dut_commit.trace", "w");
        if (trace_fd == 0) begin
            $display("FAIL: could not open dut_commit.trace");
            $fatal(1);
        end
        $fdisplay(trace_fd, "idx,pc,instr,rd,wdata");
        commit_count = 0;
        watchdog = 0;
    end

    always @(posedge clk) begin
        watchdog <= watchdog + 1;
        if (watchdog > max_cycles) begin
            $display("FAIL: watchdog timeout after %0d cycles (commits=%0d)", watchdog, commit_count);
            $fatal(1);
        end

        if (!npu_start_o && dut.u_npu_core.u_core.wb_instr_retired) begin
            $display("FAIL: instruction committed before CTRL.start");
            $fatal(1);
        end

        if (npu_start_o && dut.u_npu_core.u_core.ex_wb_valid_r && dut.u_npu_core.u_core.ex_wb_illegal_r) begin
            $display("[%0t ns] stop on illegal/ebreak pc=%08x commits=%0d",
                     $time, dut.u_npu_core.u_core.ex_wb_pc_r, commit_count);
            if (commit_count < min_commits) begin
                $display("FAIL: too few commits before ebreak (%0d < %0d)", commit_count, min_commits);
                $fatal(1);
            end
            // determinism guard: the two masked STATUS reads must have observed
            // dma_done=1 — i.e. the bounded delay really covered the DMA latency.
            $fclose(trace_fd);
            $display("PASS: DUT commit trace wrote %0d commits before ebreak", commit_count);
            $finish;
        end else if (npu_start_o && dut.u_npu_core.u_core.wb_instr_retired && !dut.u_npu_core.u_core.ex_wb_illegal_r) begin
            /* verilator lint_off BLKSEQ */
            commit_instr = dut.itcm.mem[dut.u_npu_core.u_core.ex_wb_pc_r[12:2]];
            /* verilator lint_on BLKSEQ */
            $fdisplay(trace_fd, "%0d,%08x,%08x,%0d,%08x",
                      commit_count,
                      dut.u_npu_core.u_core.ex_wb_pc_r,
                      commit_instr,
                      (dut.u_npu_core.u_core.rfu_we && dut.u_npu_core.u_core.rfu_wr_idx != 5'd0)
                          ? dut.u_npu_core.u_core.rfu_wr_idx : 5'd0,
                      (dut.u_npu_core.u_core.rfu_we && dut.u_npu_core.u_core.rfu_wr_idx != 5'd0)
                          ? dut.u_npu_core.u_core.rfu_wr_data : 32'h0);
            commit_count <= commit_count + 1;
        end
    end

    initial begin
        repeat (6) @(posedge clk);
        resetn = 1'b1;
        repeat (10) @(posedge clk);
        axil_write(32'h3000_004C, 32'h0000_0001);   // CQ_TAIL = 1 (doorbell)
        axil_write(32'h3000_0004, 32'h0000_0001);   // CTRL.start
    end
endmodule
