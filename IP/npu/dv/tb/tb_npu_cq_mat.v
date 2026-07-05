// =============================================================================
// tb_npu_cq_mat.v — ADR-0037 gate_46: the full Coral-shaped matrix offload.
// Host: writes a/b int8 blocks into the TCM, then a 5-descriptor CQ batch:
//   MAT.CFG(M=8,N=8,K=32) -> MAT.ACC_CLR(bank0) -> MAT.OP(a,b,RPT=4,W3=0)
//   -> MAT.RESCALE(v4 worked-example params) -> MAT.STORE(dst=shared, W2=MAT_OUT,
//      IRQ|LAST)
// The sequencer firmware consumes the ring and drives the engine; the requantized
// 8x8 int8 tile lands in shared memory. The TB dumps it to mat_result.dump —
// gate_46 (python) compares against mat_golden.py bit-exactly.
// Also: MAT.OP with W3!=0 must halt with ERR_CAUSE=MAT_PARAM (frozen W3==0 rule).
// =============================================================================
`default_nettype none
`timescale 1ns/1ps

module tb_npu_cq_mat;
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

    initial begin
        $readmemh("IP/npu/sw/cq_sequencer/firmware.hex", dut.tcm.mem);
        $readmemh("IP/npu/sw/cq_sequencer/firmware.hex", dut.itcm.mem);
    end

    localparam [31:0] A_CTRL = 32'h3000_0004, A_STATUS = 32'h3000_0008;
    localparam [31:0] A_BASE = 32'h3000_0040, A_SIZE = 32'h3000_0044, A_TAIL = 32'h3000_004C;
    localparam [31:0] A_CQCTRL = 32'h3000_0050, A_CQST = 32'h3000_0054, A_ERRC = 32'h3000_0058;

    integer errors = 0, checks = 0, i;
    reg [31:0] rd;
    integer fdump;

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

    task wait_bit(input [31:0] addr, input integer bitpos, input [255:0] nm);
        integer guard;
        begin
            rd = 32'h0; guard = 0;
            while (rd[bitpos] !== 1'b1 && guard < 6000) begin
                axil_read(addr, rd); guard = guard + 1;
            end
            chk({31'b0, rd[bitpos]}, 32'h1, nm);
        end
    endtask

    // deterministic int8 blocks (same formulas in gate_46's golden run)
    function [7:0] a_byte(input integer idx);
        a_byte = (idx * 7 - 100) & 8'hFF;
    endfunction
    function [7:0] b_byte(input integer idx);
        b_byte = (idx * 5 - 60) & 8'hFF;
    endfunction

    initial begin
        repeat (4) @(posedge clk);
        resetn = 1'b1;
        @(posedge clk);

        // a @ TCM 0x700, b @ TCM 0x740 (32 bytes each), via the host AXI window (ADR-0052)
        for (i = 0; i < 8; i = i + 1)
            axil_write(32'h3001_0700 + i*4,
                       {a_byte(i*4+3), a_byte(i*4+2), a_byte(i*4+1), a_byte(i*4)});
        for (i = 0; i < 8; i = i + 1)
            axil_write(32'h3001_0740 + i*4,
                       {b_byte(i*4+3), b_byte(i*4+2), b_byte(i*4+1), b_byte(i*4)});

        // ring @ shared word 0x100: CFG, ACC_CLR, OP, RESCALE, STORE(LAST|IRQ)
        shared.mem[32'h100] = 32'h0000_0001;  // MAT_CFG
        shared.mem[32'h101] = 32'h0008_0008;  // M=8 N=8
        shared.mem[32'h102] = 32'd32;         // K=32 -> RPT=4
        shared.mem[32'h103] = 32'h0;
        shared.mem[32'h104] = 32'h0000_0006;  // MAT_ACC_CLR
        shared.mem[32'h105] = 32'h1;          // bank0
        shared.mem[32'h106] = 32'h0;
        shared.mem[32'h107] = 32'h0;
        shared.mem[32'h108] = 32'h0004_0003;  // MAT_OP RPT=4
        shared.mem[32'h109] = 32'h0000_0700;  // a (TCM byte)
        shared.mem[32'h10A] = 32'h0000_0740;  // b
        shared.mem[32'h10B] = 32'h0;          // W3 must be 0
        shared.mem[32'h10C] = 32'h0000_0004;  // MAT_RESCALE
        shared.mem[32'h10D] = 32'h54C4_699A;  // mult (v4 worked example)
        shared.mem[32'h10E] = 32'h0000_8026;  // (zp=-128)<<8 | shift=38
        shared.mem[32'h10F] = 32'h0000_7F80;  // clamp [ -128, 127 ]
        shared.mem[32'h110] = 32'h0000_5005;  // MAT_STORE + IRQ + LAST
        shared.mem[32'h111] = 32'h0000_1800;  // dst (shared byte)
        shared.mem[32'h112] = 32'h0000_0800;  // src = MAT_OUT region (ADR-0037 W2)
        shared.mem[32'h113] = 32'h0000_0404;  // rows=4 cols=4 -> 16 words

        axil_write(A_BASE, 32'h0000_0400);
        axil_write(A_SIZE, 32'd8);
        axil_write(A_CQCTRL, 32'h1);
        axil_write(A_CTRL, 32'h9);            // start + irq_enable
        axil_write(A_TAIL, 32'd5);

        wait_bit(A_STATUS, 1, "matrix batch DONE");
        chk({31'b0, irq}, 32'h1, "IRQ on STORE");
        axil_read(A_CQST, rd);
        chk({31'b0, rd[3]}, 32'h0, "no CQ err");

        // dump the requantized tile for the golden compare (gate_46)
        fdump = $fopen("mat_result.dump", "w");
        for (i = 0; i < 16; i = i + 1)
            $fdisplay(fdump, "%08x", shared.mem[32'h600 + i]);
        $fclose(fdump);

        // ---- MAT_PARAM: OP with W3 != 0 must halt with cause 7 ----
        axil_write(A_CTRL, 32'h0);
        axil_write(A_CQCTRL, 32'h0);
        axil_write(A_CQCTRL, 32'h1);
        shared.mem[32'h114] = 32'h0004_0003;  // MAT_OP
        shared.mem[32'h115] = 32'h0000_0700;
        shared.mem[32'h116] = 32'h0000_0740;
        shared.mem[32'h117] = 32'h0000_0011;  // W3 != 0 -> MAT_PARAM
        axil_write(A_TAIL, 32'd6);
        axil_write(A_CTRL, 32'h1);
        wait_bit(A_CQST, 3, "MAT_PARAM err raised");
        axil_read(A_ERRC, rd);
        chk(rd, 32'd7, "ERR_CAUSE == MAT_PARAM");

        // ---- MAT_PARAM: DTYPE != i8 rejected (int8-only engine) ----
        axil_write(A_CTRL, 32'h0);
        axil_write(A_CQCTRL, 32'h0);
        axil_write(A_CQCTRL, 32'h1);
        shared.mem[32'h118] = 32'h0004_0043;  // MAT_OP, DTYPE=i16 (bit6)
        shared.mem[32'h119] = 32'h0000_0700;
        shared.mem[32'h11A] = 32'h0000_0740;
        shared.mem[32'h11B] = 32'h0;
        axil_write(A_TAIL, 32'd7);
        axil_write(A_CTRL, 32'h1);
        wait_bit(A_CQST, 3, "DTYPE err raised");
        axil_read(A_ERRC, rd);
        chk(rd, 32'd7, "ERR_CAUSE == MAT_PARAM (dtype)");

        // ADR-0044: the whole real offload batch must fit the bank budget
        checks = checks + 1;
        if (dut.tcm.bank_violations != 0) begin
            errors = errors + 1;
            $display("  FAIL bank budget violated %0d times during CQ batch",
                     dut.tcm.bank_violations);
        end

        $display("NPU_CQ_MAT: %0d checks, %0d errors", checks, errors);
        if (errors == 0) $display("NPU_CQ_MAT_PASS");
        else             $display("NPU_CQ_MAT_FAIL");
        $finish;
    end

    initial begin
        #4000000;
        $display("NPU_CQ_MAT_FAIL: timeout");
        $finish;
    end
endmodule
`default_nettype wire
