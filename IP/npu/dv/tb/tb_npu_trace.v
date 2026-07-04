// =============================================================================
// tb_npu_trace.v — ADR-0045 gate_53: RVFI/RVVI-lite trap visibility + order.
// trap_test firmware (deterministic illegal at pc=0x14): the trace port must
// show exactly 5 scalar retires before a single rvfi_trap pulse with
// rvfi_pc==0x14; rvfi_order counts retire+trap events; the scalar-only
// firmware keeps rvvi_v_valid silent; the handler then reports
// ERR_CAUSE=0x80000002 (ADR-0038 contract unchanged, observed via CSR).
// =============================================================================
`default_nettype none
`timescale 1ns/1ps

module tb_npu_trace;
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

    initial begin
        $readmemh("IP/npu/sw/cq_sequencer/trap_test.hex", dut.tcm.mem);
        $readmemh("IP/npu/sw/cq_sequencer/trap_test.hex", dut.itcm.mem);
    end

    integer retires = 0, traps = 0, vex_events = 0;
    reg [31:0] trap_pc = 32'hFFFF_FFFF;
    reg [31:0] trap_insn = 32'h0, trap_mtval = 32'h0, trap_cause = 32'h0;
    reg [31:0] retires_at_trap = 32'hFFFF_FFFF;
    integer mem_wr_cnt = 0;
    reg [31:0] last_st_addr = 32'h0, last_st_data = 32'h0;
    always @(posedge clk) begin
        if (dut.rvfi_valid)   retires = retires + 1;
        if (dut.rvvi_v_valid) vex_events = vex_events + 1;
        if (dut.rvfi_trap) begin
            traps = traps + 1;
            trap_pc = dut.rvfi_pc;
            trap_insn = dut.rvfi_insn;
            trap_mtval = dut.rvfi_trap_mtval;
            trap_cause = dut.rvfi_trap_cause;
            if (traps == 1) retires_at_trap = retires;
        end
        // ADR-0048 mem trace: count the handler's ERR_PC/ERR_CAUSE stores
        if (dut.rvfi_mem_we) begin
            mem_wr_cnt = mem_wr_cnt + 1;
            last_st_addr = dut.rvfi_mem_addr;
            last_st_data = dut.rvfi_mem_wdata;
        end
    end

    localparam [31:0] A_ERRC2 = 32'h3000_0058;
    integer guard;
    initial begin
        repeat (4) @(posedge clk);
        resetn = 1'b1;
        @(posedge clk);
        axil_write(32'h3000_0004, 32'h1);      // CTRL.start
        rd = 32'h0; guard = 0;
        while (rd !== 32'h80000002 && guard < 3000) begin
            axil_read(A_ERRC2, rd); guard = guard + 1;
        end
        chk(rd, 32'h80000002, "handler reported CORE_TRAP|illegal");
        chk(traps, 32'd1, "exactly one rvfi_trap pulse");
        chk(trap_pc, 32'h0000_0014, "rvfi_pc at trap == 0x14");
        chk(retires_at_trap, 32'd5, "5 retires before the trap");
        chk(vex_events, 32'd0, "rvvi silent on scalar firmware");
        // ---- trace v1 (ADR-0048) ----
        chk(trap_insn, 32'hFFFF_FFFF, "rvfi_insn at trap == the illegal word");
        chk(trap_cause, 32'd2, "rvfi_trap_cause == illegal");
        chk(trap_mtval, 32'hFFFF_FFFF, "rvfi_trap_mtval == faulting instr bits");
        // handler stores ERR_PC (0x80(t1)) then ERR_CAUSE (0x58(t1)), t1=0x20000
        chk(mem_wr_cnt, 32'd2, "mem trace saw the handler's two stores");
        chk(last_st_addr, 32'h0002_0058, "last store addr == ERR_CAUSE mirror");
        chk(last_st_data, 32'h8000_0002, "last store data == CORE_TRAP|illegal");
        // order counts retire + trap events (handler retires keep it moving)
        checks = checks + 1;
        if (dut.rvfi_order != {32'b0, retires} + {32'b0, traps}) begin
            errors = errors + 1;
            $display("  FAIL order=%0d != retires+traps=%0d",
                     dut.rvfi_order, retires + traps);
        end

        $display("NPU_TRACE: %0d checks, %0d errors", checks, errors);
        if (errors == 0) $display("NPU_TRACE_PASS");
        else             $display("NPU_TRACE_FAIL");
        $finish;
    end

    initial begin
        #2000000;
        $display("NPU_TRACE_FAIL: timeout");
        $finish;
    end
endmodule
`default_nettype wire
