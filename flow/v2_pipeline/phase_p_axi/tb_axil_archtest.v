`timescale 1ns / 1ns

module tb_axil_archtest;
    localparam integer MEM_WORDS = 524288;
    localparam [31:0]  ELF_BASE  = 32'h0000_1000;

    reg clk = 1'b0;
    reg resetn = 1'b0;
    always #5 clk = ~clk;

    reg [1023:0] firmware_hex;
    reg [1023:0] signature_path;
    integer max_cycles;
    integer wait_states;
    integer watchdog;
    reg [31:0] stop_addr;
    reg [31:0] sig_begin;
    reg [31:0] sig_end;

    wire trap;
    wire i_arvalid;
    wire i_arready;
    wire [31:0] i_araddr;
    wire [2:0] i_arprot;
    wire i_rvalid;
    wire i_rready;
    wire [31:0] i_rdata;
    wire [1:0] i_rresp;
    wire d_arvalid;
    wire d_arready;
    wire [31:0] d_araddr;
    wire [2:0] d_arprot;
    wire d_rvalid;
    wire d_rready;
    wire [31:0] d_rdata;
    wire [1:0] d_rresp;
    wire d_awvalid;
    wire d_awready;
    wire [31:0] d_awaddr;
    wire [2:0] d_awprot;
    wire d_wvalid;
    wire d_wready;
    wire [31:0] d_wdata;
    wire [3:0] d_wstrb;
    wire d_bvalid;
    wire d_bready;
    wire [1:0] d_bresp;
    wire dbg_axi_err;
    wire [31:0] dbg_pc;
    wire [31:0] dbg_instr;
    wire [2:0] dbg_state;
    wire unused_i_awready;
    wire unused_i_wready;
    wire unused_i_bvalid;
    wire [1:0] unused_i_bresp;

    cpu_m1_axil_top #(.RESET_PC(ELF_BASE)) dut (
        .clk(clk),
        .resetn(resetn),
        .trap(trap),
        .irq_external_pulse(1'b0),
        .m_axi_i_arvalid(i_arvalid),
        .m_axi_i_arready(i_arready),
        .m_axi_i_araddr(i_araddr),
        .m_axi_i_arprot(i_arprot),
        .m_axi_i_rvalid(i_rvalid),
        .m_axi_i_rready(i_rready),
        .m_axi_i_rdata(i_rdata),
        .m_axi_i_rresp(i_rresp),
        .m_axi_d_arvalid(d_arvalid),
        .m_axi_d_arready(d_arready),
        .m_axi_d_araddr(d_araddr),
        .m_axi_d_arprot(d_arprot),
        .m_axi_d_rvalid(d_rvalid),
        .m_axi_d_rready(d_rready),
        .m_axi_d_rdata(d_rdata),
        .m_axi_d_rresp(d_rresp),
        .m_axi_d_awvalid(d_awvalid),
        .m_axi_d_awready(d_awready),
        .m_axi_d_awaddr(d_awaddr),
        .m_axi_d_awprot(d_awprot),
        .m_axi_d_wvalid(d_wvalid),
        .m_axi_d_wready(d_wready),
        .m_axi_d_wdata(d_wdata),
        .m_axi_d_wstrb(d_wstrb),
        .m_axi_d_bvalid(d_bvalid),
        .m_axi_d_bready(d_bready),
        .m_axi_d_bresp(d_bresp),
        .dbg_axi_err(dbg_axi_err),
        .dbg_pc(dbg_pc),
        .dbg_instr(dbg_instr),
        .dbg_state(dbg_state)
    );

    axil_lite_mem_bfm #(.MEM_WORDS(MEM_WORDS), .ELF_BASE(ELF_BASE)) i_mem (
        .clk(clk),
        .resetn(resetn),
        .wait_states(wait_states),
        .s_axi_arvalid(i_arvalid),
        .s_axi_arready(i_arready),
        .s_axi_araddr(i_araddr),
        .s_axi_arprot(i_arprot),
        .s_axi_rvalid(i_rvalid),
        .s_axi_rready(i_rready),
        .s_axi_rdata(i_rdata),
        .s_axi_rresp(i_rresp),
        .s_axi_awvalid(1'b0),
        .s_axi_awready(unused_i_awready),
        .s_axi_awaddr(32'h0),
        .s_axi_awprot(3'b0),
        .s_axi_wvalid(1'b0),
        .s_axi_wready(unused_i_wready),
        .s_axi_wdata(32'h0),
        .s_axi_wstrb(4'h0),
        .s_axi_bvalid(unused_i_bvalid),
        .s_axi_bready(1'b0),
        .s_axi_bresp(unused_i_bresp)
    );

    axil_lite_mem_bfm #(.MEM_WORDS(MEM_WORDS), .ELF_BASE(ELF_BASE)) d_mem (
        .clk(clk),
        .resetn(resetn),
        .wait_states(wait_states),
        .s_axi_arvalid(d_arvalid),
        .s_axi_arready(d_arready),
        .s_axi_araddr(d_araddr),
        .s_axi_arprot(d_arprot),
        .s_axi_rvalid(d_rvalid),
        .s_axi_rready(d_rready),
        .s_axi_rdata(d_rdata),
        .s_axi_rresp(d_rresp),
        .s_axi_awvalid(d_awvalid),
        .s_axi_awready(d_awready),
        .s_axi_awaddr(d_awaddr),
        .s_axi_awprot(d_awprot),
        .s_axi_wvalid(d_wvalid),
        .s_axi_wready(d_wready),
        .s_axi_wdata(d_wdata),
        .s_axi_wstrb(d_wstrb),
        .s_axi_bvalid(d_bvalid),
        .s_axi_bready(d_bready),
        .s_axi_bresp(d_bresp)
    );

    initial begin
        if (!$value$plusargs("HEX=%s", firmware_hex)) firmware_hex = "firmware.hex";
        if (!$value$plusargs("SIGNATURE=%s", signature_path)) signature_path = "dut.signature";
        if (!$value$plusargs("MAX_CYCLES=%d", max_cycles)) max_cycles = 5000000;
        if (!$value$plusargs("WAIT=%d", wait_states)) wait_states = 0;
        if (!$value$plusargs("STOP_ADDR=%h", stop_addr)) stop_addr = 32'hffff_ffff;
        if (!$value$plusargs("SIG_BEGIN=%h", sig_begin)) sig_begin = 32'h0;
        if (!$value$plusargs("SIG_END=%h", sig_end)) sig_end = 32'h0;

        i_mem.load_hex(firmware_hex);
        d_mem.load_hex(firmware_hex);

        repeat (6) @(posedge clk);
        resetn = 1'b1;
    end

    always @(posedge clk) begin
        if (resetn) begin
            watchdog <= watchdog + 1;
            if (watchdog > max_cycles) begin
                $display("FAIL: watchdog timeout pc=%08x wait=%0d", dbg_pc, wait_states);
                $fatal(1);
            end
            if (dbg_axi_err) begin
                $display("FAIL: dbg_axi_err asserted");
                $fatal(1);
            end
            if (d_awvalid && d_awready && d_awaddr == stop_addr && d_wdata != 32'h0) begin
                d_mem.dump_signature(signature_path, sig_begin, sig_end);
                $display("PASS: AXI arch-test signature dumped wait=%0d", wait_states);
                $finish;
            end
        end else begin
            watchdog <= 0;
        end
    end

    wire _unused = ^{trap, dbg_instr, dbg_state, unused_i_awready, unused_i_wready,
                     unused_i_bvalid, unused_i_bresp};
endmodule
