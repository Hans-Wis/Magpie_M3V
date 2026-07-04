// =============================================================================
// tb_npu_cq_smoke.v - ADR-0035 command queue directed smoke.
// Build firmware before sim when missing:
//   make -C IP/npu/sw/cq_sequencer firmware.hex
// =============================================================================
`default_nettype none
`timescale 1ns/1ps

module tb_npu_cq_smoke;
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
        .m_awvalid(m_awvalid), .m_awready(m_awready), .m_awaddr(m_awaddr), .m_awlen(m_awlen),
        .m_awsize(m_awsize), .m_awburst(m_awburst),
        .m_wvalid(m_wvalid), .m_wready(m_wready), .m_wdata(m_wdata), .m_wstrb(m_wstrb), .m_wlast(m_wlast),
        .m_bvalid(m_bvalid), .m_bready(m_bready), .m_bresp(m_bresp),
        .irq(irq), .npu_start(npu_start), .npu_config(npu_config)
    );

    axi_full_rwmem #(.WORDS(16384), .AW(14)) shared (
        .clk(clk), .resetn(resetn),
        .arvalid(m_arvalid), .arready(m_arready), .araddr(m_araddr), .arlen(m_arlen), .arsize(m_arsize), .arburst(m_arburst),
        .rvalid(m_rvalid), .rready(m_rready), .rdata(m_rdata), .rlast(m_rlast), .rresp(m_rresp),
        .awvalid(m_awvalid), .awready(m_awready), .awaddr(m_awaddr), .awlen(m_awlen), .awsize(m_awsize), .awburst(m_awburst),
        .wvalid(m_wvalid), .wready(m_wready), .wdata(m_wdata), .wstrb(m_wstrb), .wlast(m_wlast),
        .bvalid(m_bvalid), .bready(m_bready), .bresp(m_bresp)
    );

    localparam [31:0] CSR_BASE = 32'h3000_0000;
    localparam [31:0] TCM_BASE = 32'h3001_0000;

    // Encoded with IP/npu/sw/cq_codec.py:
    // MAT_LOAD_W(src_addr=0x800,stride=0,rows=4,cols=4)
    localparam [31:0] D0_W0 = 32'h00000002, D0_W1 = 32'h00000800, D0_W2 = 32'h00000000, D0_W3 = 32'h00000404;
    // MAT_FENCE()
    localparam [31:0] D1_W0 = 32'h00000007, D1_W1 = 32'h00000000, D1_W2 = 32'h00000000, D1_W3 = 32'h00000000;
    // MAT_STORE(dst_addr=0x1000,stride=0,rows=4,cols=4,irq=1)
    localparam [31:0] D2_W0 = 32'h00001005, D2_W1 = 32'h00001000, D2_W2 = 32'h00000000, D2_W3 = 32'h00000404;
    // MAT_CFG(m=8,n=8,k=16,tile_flags=0,last=1)
    localparam [31:0] D3_W0 = 32'h00004001, D3_W1 = 32'h00080008, D3_W2 = 32'h00000010, D3_W3 = 32'h00000000;
    // MAT_OP() -> ENGINE_NOT_READY
    localparam [31:0] D4_W0 = 32'h00000003, D4_W1 = 32'h00000000, D4_W2 = 32'h00000000, D4_W3 = 32'h00000000;

    integer errors = 0;
    integer checks = 0;
    integer i;
    reg [31:0] rd;

    initial $readmemh("IP/npu/sw/cq_sequencer/firmware.hex", dut.tcm.mem);

    task fail_msg(input [255:0] nm);
        begin
            errors = errors + 1;
            $display("  FAIL %0s", nm);
        end
    endtask

    task chk(input [31:0] got, input [31:0] exp, input [255:0] nm);
        begin
            checks = checks + 1;
            if (got !== exp) begin
                errors = errors + 1;
                $display("  FAIL %0s got %08x exp %08x", nm, got, exp);
            end else begin
                $display("  ok   %0s = %08x", nm, got);
            end
        end
    endtask

    task chk_bit(input got, input exp, input [255:0] nm);
        begin
            checks = checks + 1;
            if (got !== exp) begin
                errors = errors + 1;
                $display("  FAIL %0s got %0b exp %0b", nm, got, exp);
            end else begin
                $display("  ok   %0s = %0b", nm, got);
            end
        end
    endtask

    task axil_write(input [31:0] a, input [31:0] d);
        reg aw_done;
        reg w_done;
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
                if (s_wvalid && s_wready) w_done = 1'b1;
                @(negedge clk);
                if (aw_done) s_awvalid = 1'b0;
                if (w_done) s_wvalid = 1'b0;
                guard = guard + 1;
            end
            if (!(aw_done && w_done)) fail_msg("AXIL write address/data timeout");
            s_bready = 1'b1;
            guard = 0;
            while (!s_bvalid && guard < 1000) begin @(posedge clk); guard = guard + 1; end
            if (!s_bvalid) fail_msg("AXIL write response timeout");
            else if (s_bresp !== 2'b00) begin
                errors = errors + 1;
                $display("  FAIL AXIL write BRESP addr %08x resp %0d", a, s_bresp);
            end
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
            if (!(s_arvalid && s_arready)) fail_msg("AXIL read address timeout");
            @(negedge clk);
            s_arvalid = 1'b0;
            guard = 0;
            while (!(s_rvalid && s_rready) && guard < 1000) begin @(posedge clk); guard = guard + 1; end
            d = s_rdata;
            if (!(s_rvalid && s_rready)) fail_msg("AXIL read data timeout");
            else if (s_rresp !== 2'b00) begin
                errors = errors + 1;
                $display("  FAIL AXIL read RRESP addr %08x resp %0d", a, s_rresp);
            end
            @(negedge clk);
            s_rready = 1'b0;
        end
    endtask

    task wait_status_bit(input [31:0] addr, input integer bitno, input [255:0] nm);
        integer guard;
        begin
            rd = 32'h0;
            for (guard = 0; guard < 5000 && rd[bitno] !== 1'b1; guard = guard + 1)
                axil_read(addr, rd);
            if (rd[bitno] !== 1'b1) fail_msg(nm);
        end
    endtask

    initial begin
        for (i = 0; i < 16384; i = i + 1)
            shared.mem[i] = 32'h0;

        for (i = 0; i < 16; i = i + 1)
            shared.mem[32'h200 + i] = 32'hA5A50000 | i[31:0];

        shared.mem[32'h100] = D0_W0; shared.mem[32'h101] = D0_W1; shared.mem[32'h102] = D0_W2; shared.mem[32'h103] = D0_W3;
        shared.mem[32'h104] = D1_W0; shared.mem[32'h105] = D1_W1; shared.mem[32'h106] = D1_W2; shared.mem[32'h107] = D1_W3;
        shared.mem[32'h108] = D2_W0; shared.mem[32'h109] = D2_W1; shared.mem[32'h10A] = D2_W2; shared.mem[32'h10B] = D2_W3;
        shared.mem[32'h10C] = D3_W0; shared.mem[32'h10D] = D3_W1; shared.mem[32'h10E] = D3_W2; shared.mem[32'h10F] = D3_W3;

        repeat (4) @(posedge clk);
        resetn = 1'b1;
        @(posedge clk);

        axil_write(CSR_BASE + 32'h40, 32'h00000400);
        axil_write(CSR_BASE + 32'h44, 32'h00000008);
        axil_write(CSR_BASE + 32'h50, 32'h00000001);
        axil_write(CSR_BASE + 32'h04, 32'h00000009);
        axil_write(CSR_BASE + 32'h4C, 32'h00000004);

        wait_status_bit(CSR_BASE + 32'h08, 1, "STATUS.npu_done timeout");

        for (i = 0; i < 16; i = i + 1) begin
            axil_read(TCM_BASE + 32'h600 + (i << 2), rd);  // weight region (ADR-0037: 0x600)
            chk(rd, 32'hA5A50000 | i[31:0], "TCM.weight");
        end
        for (i = 0; i < 16; i = i + 1)
            chk(shared.mem[32'h400 + i], 32'hA5A50000 | i[31:0], "shared.store");

        axil_read(CSR_BASE + 32'h48, rd);
        chk(rd, 32'h00000004, "CQ_HEAD.after_batch");
        chk_bit(irq, 1'b1, "irq_after_store_or_done");

        axil_write(CSR_BASE + 32'h04, 32'h0000000B);
        chk_bit(irq, 1'b0, "irq_cleared");

        shared.mem[32'h110] = D4_W0; shared.mem[32'h111] = D4_W1; shared.mem[32'h112] = D4_W2; shared.mem[32'h113] = D4_W3;
        axil_write(CSR_BASE + 32'h4C, 32'h00000005);
        wait_status_bit(CSR_BASE + 32'h54, 3, "CQ_STATUS.err timeout");

        axil_read(CSR_BASE + 32'h58, rd);
        chk(rd, 32'h00000007, "ERR_CAUSE.mat_param (ADR-0037)");
        axil_read(CSR_BASE + 32'h48, rd);
        chk(rd, 32'h00000004, "CQ_HEAD.frozen_on_err");
        chk_bit(irq, 1'b1, "irq_on_error (ADR-0038 ERR IRQ)");

        $display("NPU_CQ_SMOKE: %0d checks, %0d errors", checks, errors);
        if (errors == 0) $display("NPU_CQ_SMOKE_PASS");
        else             $display("NPU_CQ_SMOKE_FAIL");
        $finish;
    end

    initial begin
        #3000000;
        $display("NPU_CQ_SMOKE_FAIL: timeout");
        $display("NPU_CQ_SMOKE: %0d checks, %0d errors", checks, errors + 1);
        $finish;
    end
endmodule
`default_nettype wire
