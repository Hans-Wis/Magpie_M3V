// =============================================================================
// tb_npu_p05.v — ADR-0038 gate_47: traps-to-host + soft_reset/abort + recovery.
// S1 core trap: trap_test firmware executes an illegal instruction at pc=0x14;
//    the terminal handler reports ERR_PC=0x14 / ERR_CAUSE=0x80000002 (CORE_TRAP|
//    mcause) through the mirror; ERR IRQ fires; core spins (Kelvin io_fault shape).
// S2 soft_reset (CTRL[2]): core halts, STATUS[8] clears at quiesce; FAULT
//    EVIDENCE PERSISTS (post-mortem) until the CQ_CTRL enable-toggle ack.
// S3 abort mid-DMA: a 4096-beat read is aborted at a burst boundary — AXI stays
//    protocol-clean (no new AR after quiesce), busy/done clear, ERR_CAUSE=ABORTED(8),
//    ERR IRQ fires again.
// S4 recovery: ack, reload the real CQ firmware, run a full matrix batch
//    (CFG/ACC_CLR/OP/RESCALE/STORE|LAST) to DONE with no error.
// =============================================================================
`default_nettype none
`timescale 1ns/1ps

module tb_npu_p05;
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

    npu_top #(.TCM_WORDS(8192), .TCM_AW(13)) dut (
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

    localparam [31:0] A_CTRL = 32'h3000_0004, A_STATUS = 32'h3000_0008;
    localparam [31:0] A_DSRC = 32'h3000_0020, A_DDST = 32'h3000_0024, A_DLEN = 32'h3000_0028, A_DGO = 32'h3000_002C;
    localparam [31:0] A_BASE = 32'h3000_0040, A_SIZE = 32'h3000_0044, A_TAIL = 32'h3000_004C;
    localparam [31:0] A_CQCTRL = 32'h3000_0050, A_CQST = 32'h3000_0054, A_ERRC = 32'h3000_0058;
    localparam [31:0] A_ERRPC = 32'h3000_0080;

    integer errors = 0, checks = 0, i, ar_cnt_snap;
    reg [31:0] rd;
    integer ar_cnt;
    always @(posedge clk) if (m_arvalid && m_arready) ar_cnt <= ar_cnt + 1;

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

    task wait_cond_errc_nonzero;
        integer guard;
        begin
            rd = 32'h0; guard = 0;
            while (rd == 32'h0 && guard < 6000) begin
                axil_read(A_ERRC, rd); guard = guard + 1;
            end
        end
    endtask

    task wait_status_bit_clear(input integer bitpos, input [255:0] nm);
        integer guard;
        begin
            rd = 32'hFFFF_FFFF; guard = 0;
            while (rd[bitpos] !== 1'b0 && guard < 6000) begin
                axil_read(A_STATUS, rd); guard = guard + 1;
            end
            chk({31'b0, rd[bitpos]}, 32'h0, nm);
        end
    endtask

    function [7:0] a_byte(input integer idx); a_byte = (idx * 7 - 100) & 8'hFF; endfunction
    function [7:0] b_byte(input integer idx); b_byte = (idx * 5 - 60) & 8'hFF; endfunction

    initial begin
        ar_cnt = 0;
        repeat (4) @(posedge clk);
        resetn = 1'b1;
        @(posedge clk);

        // ================= S1: core trap -> host =================
        $readmemh("IP/npu/sw/cq_sequencer/trap_test.hex", dut.tcm.mem);
        $readmemh("IP/npu/sw/cq_sequencer/trap_test.hex", dut.itcm.mem);
        axil_write(A_CTRL, 32'h9);            // start + irq_enable
        wait_cond_errc_nonzero();
        chk(rd, 32'h8000_0002, "ERR_CAUSE = CORE_TRAP|illegal");
        axil_read(A_ERRPC, rd);
        chk(rd, 32'h0000_0014, "ERR_PC = trapping pc");
        chk({31'b0, irq}, 32'h1, "ERR IRQ raised");
        axil_write(A_CTRL, 32'hA);            // irq_clear (keep irq_enable)
        chk({31'b0, irq}, 32'h0, "IRQ cleared");

        // ================= S2: soft_reset; evidence persists =================
        axil_write(A_CTRL, 32'h4);
        wait_status_bit_clear(8, "soft_reset quiesced");
        axil_read(A_STATUS, rd);
        chk({31'b0, rd[0]}, 32'h0, "core halted (npu_busy=0)");
        axil_read(A_ERRC, rd);
        chk(rd, 32'h8000_0002, "post-mortem ERR_CAUSE persists");
        axil_read(A_ERRPC, rd);
        chk(rd, 32'h0000_0014, "post-mortem ERR_PC persists");
        // ack = CQ_CTRL enable-toggle
        axil_write(A_CQCTRL, 32'h1);
        axil_read(A_ERRC, rd);
        chk(rd, 32'h0, "ack clears ERR_CAUSE");
        axil_write(A_CQCTRL, 32'h0);

        // ================= S3: abort mid-DMA (4096 beats) =================
        axil_write(A_CTRL, 32'h8);            // irq_enable only (core stays reset)
        axil_write(A_DSRC, 32'h0);
        axil_write(A_DDST, 32'd384);
        axil_write(A_DLEN, 32'd4096);
        axil_write(A_DGO, 32'h1);
        repeat (60) @(posedge clk);           // mid-flight
        axil_read(A_STATUS, rd);
        chk({31'b0, rd[2]}, 32'h1, "DMA busy before abort");
        axil_write(A_CTRL, 32'hC);            // soft_reset + keep irq_enable
        wait_status_bit_clear(8, "abort quiesced");
        ar_cnt_snap = ar_cnt;
        repeat (100) @(posedge clk);
        chk(ar_cnt - ar_cnt_snap, 0, "no AR bursts after abort (protocol clean)");
        axil_read(A_STATUS, rd);
        chk({31'b0, rd[2]}, 32'h0, "dma_busy cleared");
        chk({31'b0, rd[3]}, 32'h0, "dma_done not set (aborted)");
        axil_read(A_ERRC, rd);
        chk(rd, 32'd8, "ERR_CAUSE = ABORTED");
        chk({31'b0, irq}, 32'h1, "ERR IRQ on abort");
        axil_write(A_CTRL, 32'hA);            // irq_clear

        // ================= S4: ack + reload CQ firmware + matrix batch ============
        axil_write(A_CQCTRL, 32'h1);          // toggle 0->1 acks
        axil_read(A_ERRC, rd);
        chk(rd, 32'h0, "abort acked");
        $readmemh("IP/npu/sw/cq_sequencer/firmware.hex", dut.tcm.mem);
        $readmemh("IP/npu/sw/cq_sequencer/firmware.hex", dut.itcm.mem);
        for (i = 0; i < 8; i = i + 1)
            axil_write(32'h3001_0700 + i*4,
                       {a_byte(i*4+3), a_byte(i*4+2), a_byte(i*4+1), a_byte(i*4)});
        for (i = 0; i < 8; i = i + 1)
            axil_write(32'h3001_0740 + i*4,
                       {b_byte(i*4+3), b_byte(i*4+2), b_byte(i*4+1), b_byte(i*4)});
        shared.mem[32'h100] = 32'h0000_0001;
        shared.mem[32'h101] = 32'h0008_0008;
        shared.mem[32'h102] = 32'd32;
        shared.mem[32'h103] = 32'h0;
        shared.mem[32'h104] = 32'h0000_0006;
        shared.mem[32'h105] = 32'h1;
        shared.mem[32'h106] = 32'h0;
        shared.mem[32'h107] = 32'h0;
        shared.mem[32'h108] = 32'h0004_0003;
        shared.mem[32'h109] = 32'h0000_0700;
        shared.mem[32'h10A] = 32'h0000_0740;
        shared.mem[32'h10B] = 32'h0;
        shared.mem[32'h10C] = 32'h0000_0004;
        shared.mem[32'h10D] = 32'h54C4_699A;
        shared.mem[32'h10E] = 32'h0000_8026;
        shared.mem[32'h10F] = 32'h0000_7F80;
        shared.mem[32'h110] = 32'h0000_5005;
        shared.mem[32'h111] = 32'h0000_1800;
        shared.mem[32'h112] = 32'h0000_0800;
        shared.mem[32'h113] = 32'h0000_0404;
        axil_write(A_BASE, 32'h0000_0400);
        axil_write(A_SIZE, 32'd8);
        axil_write(A_TAIL, 32'd5);
        axil_write(A_CTRL, 32'h9);            // re-arm
        begin : recover
            integer guard;
            rd = 32'h0; guard = 0;
            while (rd[1] !== 1'b1 && guard < 6000) begin
                axil_read(A_STATUS, rd); guard = guard + 1;
            end
            chk({31'b0, rd[1]}, 32'h1, "post-recovery batch DONE");
        end
        axil_read(A_CQST, rd);
        chk({31'b0, rd[3]}, 32'h0, "post-recovery no err");

        $display("NPU_P05: %0d checks, %0d errors", checks, errors);
        if (errors == 0) $display("NPU_P05_PASS");
        else             $display("NPU_P05_FAIL");
        $finish;
    end

    initial begin
        #4000000;
        $display("NPU_P05_FAIL: timeout");
        $finish;
    end
endmodule
`default_nettype wire
