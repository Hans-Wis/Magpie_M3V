// =============================================================================
// cpu_m1_fpga_top.v — Magpie_M1 FPGA subsystem (CPU -> AXI4-Lite -> BRAM)
// -----------------------------------------------------------------------------
//   cpu_m1_axil_top (M_AXI_I read-only / M_AXI_D read+write)
//     M_AXI_I -> address decode -> boot ROM (reset region [0, RAM_BASE))
//                               -> dual-port BRAM port A (RAM region)
//     M_AXI_D -> dual-port BRAM port B (RAM, read+write)
//   Memory = dual-port BRAM (FPGA block RAM). Reset stub in the boot ROM jumps
//   to RAM_BASE where the program is preloaded (INIT_HEX / JTAG). The ASIC
//   variant swaps axil_dp_bram's array for a T28 dual-port SRAM macro.
// =============================================================================
`default_nettype none

module cpu_m1_fpga_top #(
    parameter [31:0] RAM_BASE  = 32'h2000_0000,
    parameter        RAM_ADDR_W = 14,            // 16 KiB BRAM
    parameter        INIT_HEX   = "",
    parameter        BOOT_DEBUG = 1'b0,
    parameter        RV32A = 1,
    parameter        PMP_ENTRIES = 0
)(
    input  wire        clk,
    input  wire        resetn,
    input  wire        irq_external_pulse,
    output wire        trap,
    output wire [31:0] dbg_pc,
    output wire [31:0] dbg_instr,
    output wire        dbg_axi_err
);
    // ---- CPU AXI master wires ----
    wire        i_arvalid, i_arready, i_rvalid, i_rready;
    wire [31:0] i_araddr, i_rdata;  wire [2:0] i_arprot;  wire [1:0] i_rresp;
    wire        d_arvalid, d_arready, d_rvalid, d_rready;
    wire [31:0] d_araddr, d_rdata;  wire [2:0] d_arprot;  wire [1:0] d_rresp;
    wire        d_awvalid, d_awready, d_wvalid, d_wready, d_bvalid, d_bready;
    wire [31:0] d_awaddr, d_wdata;  wire [2:0] d_awprot;  wire [3:0] d_wstrb;  wire [1:0] d_bresp;

    cpu_m1_axil_top #(
        .RESET_PC(32'h0000_0000),
        .RV32A(RV32A),
        .PMP_ENTRIES(PMP_ENTRIES)
    ) u_cpu (
        .clk(clk), .resetn(resetn), .trap(trap), .irq_external_pulse(irq_external_pulse),
        .m_axi_i_arvalid(i_arvalid), .m_axi_i_arready(i_arready), .m_axi_i_araddr(i_araddr),
        .m_axi_i_arprot(i_arprot), .m_axi_i_rvalid(i_rvalid), .m_axi_i_rready(i_rready),
        .m_axi_i_rdata(i_rdata), .m_axi_i_rresp(i_rresp),
        .m_axi_d_arvalid(d_arvalid), .m_axi_d_arready(d_arready), .m_axi_d_araddr(d_araddr),
        .m_axi_d_arprot(d_arprot), .m_axi_d_rvalid(d_rvalid), .m_axi_d_rready(d_rready),
        .m_axi_d_rdata(d_rdata), .m_axi_d_rresp(d_rresp),
        .m_axi_d_awvalid(d_awvalid), .m_axi_d_awready(d_awready), .m_axi_d_awaddr(d_awaddr),
        .m_axi_d_awprot(d_awprot), .m_axi_d_wvalid(d_wvalid), .m_axi_d_wready(d_wready),
        .m_axi_d_wdata(d_wdata), .m_axi_d_wstrb(d_wstrb),
        .m_axi_d_bvalid(d_bvalid), .m_axi_d_bready(d_bready), .m_axi_d_bresp(d_bresp),
        .dbg_axi_err(dbg_axi_err), .dbg_pc(dbg_pc), .dbg_instr(dbg_instr), .dbg_state()
    );

    // ---- I-side 1->2 read decode: boot ROM ([0,RAM_BASE)) vs BRAM port A ----
    wire i_sel_ram = (i_araddr >= RAM_BASE);
    reg  i_sel_ram_q;                                 // which slave owns the in-flight R
    always @(posedge clk) if (i_arvalid && i_arready) i_sel_ram_q <= i_sel_ram;

    wire rom_arvalid, rom_arready, rom_rvalid, rom_rready; wire [31:0] rom_rdata; wire [1:0] rom_rresp;
    wire bra_arvalid, bra_arready, bra_rvalid, bra_rready; wire [31:0] bra_rdata; wire [1:0] bra_rresp;

    assign rom_arvalid = i_arvalid && !i_sel_ram;
    assign bra_arvalid = i_arvalid &&  i_sel_ram;
    assign i_arready   = i_sel_ram ? bra_arready : rom_arready;
    assign i_rvalid    = i_sel_ram_q ? bra_rvalid : rom_rvalid;
    assign i_rdata     = i_sel_ram_q ? bra_rdata  : rom_rdata;
    assign i_rresp     = i_sel_ram_q ? bra_rresp  : rom_rresp;
    assign rom_rready  = i_rready && !i_sel_ram_q;
    assign bra_rready  = i_rready &&  i_sel_ram_q;

    axil_bootrom #(.RAM_BASE(RAM_BASE), .MODE_DEBUG(BOOT_DEBUG)) u_rom (
        .clk(clk), .resetn(resetn),
        .s_arvalid(rom_arvalid), .s_arready(rom_arready), .s_araddr(i_araddr),
        .s_rready(rom_rready), .s_rvalid(rom_rvalid), .s_rdata(rom_rdata), .s_rresp(rom_rresp)
    );

    // ---- dual-port BRAM: port A = I (read), port B = D (read+write) ----
    axil_dp_bram #(.ADDR_W(RAM_ADDR_W), .INIT_HEX(INIT_HEX)) u_bram (
        .clk(clk), .resetn(resetn),
        .a_arvalid(bra_arvalid), .a_arready(bra_arready), .a_araddr(i_araddr),
        .a_rvalid(bra_rvalid), .a_rready(bra_rready), .a_rdata(bra_rdata), .a_rresp(bra_rresp),
        .b_arvalid(d_arvalid), .b_arready(d_arready), .b_araddr(d_araddr),
        .b_rvalid(d_rvalid), .b_rready(d_rready), .b_rdata(d_rdata), .b_rresp(d_rresp),
        .b_awvalid(d_awvalid), .b_awready(d_awready), .b_awaddr(d_awaddr),
        .b_wvalid(d_wvalid), .b_wready(d_wready), .b_wdata(d_wdata), .b_wstrb(d_wstrb),
        .b_bvalid(d_bvalid), .b_bready(d_bready), .b_bresp(d_bresp)
    );
endmodule
`default_nettype wire
