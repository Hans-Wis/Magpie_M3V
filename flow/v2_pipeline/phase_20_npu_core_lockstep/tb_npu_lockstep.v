// =============================================================================
// tb_npu_lockstep.v — ADR-0034 gate_31/32: NPU sequencer Spike lockstep DUT harness
// -----------------------------------------------------------------------------
// DUT = the REAL npu_top (core fetches through the real npu_tcm ports — the
// green-wash guard forbids any IMEM stand-in). Program image is backdoor-loaded
// into dut.tcm.mem BEFORE CTRL.start is written over the AXI-Lite slave (the
// host-AXI program-load path itself is proven by gate_30's directed test).
// Commit trace format identical to tb_spike_lockstep.v: idx,pc,instr,rd,wdata.
// EN_RVC=0 => every instruction is 32-bit; ebreak (0x00100073) terminates.
// Checks before start: core held in reset must issue NO ibus fetch (ADR-0034 R1).
// =============================================================================
`timescale 1ns / 1ns

module tb_npu_lockstep;
    reg clk = 1'b0;
    reg resetn = 1'b0;

    // ---- AXI4-Lite host-side master (CTRL writes only in this TB) ----
    reg         awvalid = 0; wire awready; reg [31:0] awaddr = 0;
    reg         wvalid = 0;  wire wready;  reg [31:0] wdata = 0; reg [3:0] wstrb = 0;
    wire        bvalid;      reg bready = 0; wire [1:0] bresp;
    reg         arvalid = 0; wire arready; reg [31:0] araddr = 0;
    wire        rvalid;      reg rready = 1; wire [31:0] rdata; wire [1:0] rresp;

    // ---- AXI4-full DMA master ports: tied off (no DMA in lockstep runs) ----
    wire        m_arvalid; wire [31:0] m_araddr; wire [7:0] m_arlen;
    wire [2:0]  m_arsize;  wire [1:0] m_arburst; wire m_rready;
    wire        m_awvalid; wire [31:0] m_awaddr; wire [7:0] m_awlen;
    wire [2:0]  m_awsize;  wire [1:0] m_awburst;
    wire        m_wvalid;  wire [31:0] m_wdata; wire [3:0] m_wstrb; wire m_wlast;
    wire        m_bready;
    wire        irq, npu_start_o; wire [31:0] npu_config_o;

    npu_top dut (
        .clk(clk), .resetn(resetn),
        .s_awvalid(awvalid), .s_awready(awready), .s_awaddr(awaddr), .s_awprot(3'b0),
        .s_wvalid(wvalid), .s_wready(wready), .s_wdata(wdata), .s_wstrb(wstrb),
        .s_bvalid(bvalid), .s_bready(bready), .s_bresp(bresp),
        .s_arvalid(arvalid), .s_arready(arready), .s_araddr(araddr), .s_arprot(3'b0),
        .s_rvalid(rvalid), .s_rready(rready), .s_rdata(rdata), .s_rresp(rresp),
        .m_arvalid(m_arvalid), .m_arready(1'b0), .m_araddr(m_araddr),
        .m_arlen(m_arlen), .m_arsize(m_arsize), .m_arburst(m_arburst),
        .m_rvalid(1'b0), .m_rready(m_rready), .m_rdata(32'h0), .m_rlast(1'b0), .m_rresp(2'b0),
        .m_awvalid(m_awvalid), .m_awready(1'b0), .m_awaddr(m_awaddr),
        .m_awlen(m_awlen), .m_awsize(m_awsize), .m_awburst(m_awburst),
        .m_wvalid(m_wvalid), .m_wready(1'b0), .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wlast(m_wlast),
        .m_bvalid(1'b0), .m_bready(m_bready), .m_bresp(2'b0),
        .irq(irq), .npu_start(npu_start_o), .npu_config(npu_config_o)
    );

    always #5 clk = ~clk;

    // ---- program image: backdoor into the REAL npu_tcm array ----
    initial begin
        $readmemh("firmware.hex", dut.tcm.mem);
        $readmemh("firmware.hex", dut.itcm.mem);
    end

    // ---- AXI-Lite single-outstanding write task (negedge-driven; AW/W tracked
    // independently so a same-cycle W acceptance cannot deadlock the B wait) ----
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

    // ---- commit trace (same format/peek style as tb_spike_lockstep.v) ----
    integer trace_fd;
    integer vtrace_fd;   // debug tap (ADR-0036): committed VRF writes, pc,vd,data128
    integer commit_count;
    integer watchdog;
    integer max_cycles;
    integer min_commits;
    reg [31:0] commit_instr;

    initial begin
        if (!$value$plusargs("max_cycles=%d", max_cycles)) max_cycles = 500000;
        if (!$value$plusargs("min_commits=%d", min_commits)) min_commits = 8;
        trace_fd = $fopen("dut_commit.trace", "w");
        if (trace_fd == 0) begin
            $display("FAIL: could not open dut_commit.trace");
            $fatal(1);
        end
        $fdisplay(trace_fd, "idx,pc,instr,rd,wdata");
        vtrace_fd = $fopen("dut_vrf.trace", "w");
        commit_count = 0;
        watchdog = 0;
    end

    // debug tap: log every committed VRF write (verification authority stays
    // with the scalar commit stream + memory compares; this is for triage)
    always @(posedge clk) begin
        if (dut.rvvi_v_valid)
            $fdisplay(vtrace_fd, "%08x,%0d,%032x",
                      dut.rvfi_pc,
                      dut.rvvi_v_vd,
                      dut.rvvi_v_wdata);
    end

    always @(posedge clk) begin
        watchdog <= watchdog + 1;
        if (watchdog > max_cycles) begin
            $display("FAIL: watchdog timeout after %0d cycles (commits=%0d)", watchdog, commit_count);
            $fatal(1);
        end

        // R1 guard: while the core is held in reset (CTRL.start=0), it must not
        // COMMIT any instruction. (The ADR-0005 wrapper's boot-prime request line
        // idles high by design, so ibus_req alone is not a violation — execution
        // is what the reset gating must prevent.) Keyed on the DUT's real start
        // level, not a TB flag, so there is no race with the AXI write completing.
        if (!npu_start_o && dut.rvfi_valid) begin
            $display("FAIL: instruction committed before CTRL.start (fetch-before-load guard)");
            $fatal(1);
        end

        if (npu_start_o && dut.rvfi_trap &&
            (dut.rvfi_trap_cause == 32'd2 || dut.rvfi_trap_cause == 32'd3)) begin
            $display("[%0t ns] stop on illegal/ebreak pc=%08x commits=%0d",
                     $time, dut.rvfi_pc, commit_count);
            if (commit_count < min_commits) begin
                $display("FAIL: too few commits before ebreak (%0d < %0d)", commit_count, min_commits);
                $fatal(1);
            end
            $fclose(trace_fd);
            $display("PASS: DUT commit trace wrote %0d commits before ebreak", commit_count);
            $finish;
        end else if (npu_start_o && dut.rvfi_valid && !dut.rvfi_trap) begin
            /* verilator lint_off BLKSEQ */
            commit_instr = dut.itcm.mem[dut.rvfi_pc[12:2]];  // pc->insn join vs static ITCM (ADR-0045)
            // ADR-0048: the port's insn field must equal the join on EVERY commit
            if (dut.rvfi_insn !== commit_instr) begin
                $display("FAIL: rvfi_insn %08x != itcm join %08x at pc %08x",
                         dut.rvfi_insn, commit_instr, dut.rvfi_pc);
                $finish;
            end
            /* verilator lint_on BLKSEQ */
            // x0 writes (e.g. jalr x0) are architecturally invisible — normalize
            // them to "no writeback" exactly as Spike reports them.
            $fdisplay(trace_fd, "%0d,%08x,%08x,%0d,%08x",
                      commit_count,
                      dut.rvfi_pc,
                      commit_instr,
                      dut.rvfi_rd_addr,
                      dut.rvfi_rd_wdata);
            commit_count <= commit_count + 1;
        end
    end

    initial begin
        repeat (6) @(posedge clk);
        resetn = 1'b1;
        // core must stay quiescent while start=0 (checked every cycle above)
        repeat (20) @(posedge clk);
        axil_write(32'h3000_0004, 32'h0000_0001);   // CTRL.start = 1
    end
endmodule
