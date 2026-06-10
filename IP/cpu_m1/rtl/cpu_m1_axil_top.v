// =============================================================================
// cpu_m1_axil_top.v — Magpie_M1 CPU with AXI4-Lite master interfaces
// -----------------------------------------------------------------------------
// Wraps cpu_m1_top + axil_bridge to present standard AXI4-Lite masters:
//   M_AXI_I : instruction fetch (read-only)
//   M_AXI_D : data load/store   (read + write)
// Drop-in for AXI-based SoC interconnect. Behaviour is bit-identical to the
// native cpu_m1_top across any AXI4-Lite slave that returns the same data
// (verified by lockstep against the native wrapper). See integration guide.
// =============================================================================
`default_nettype none

module cpu_m1_axil_top #(
    parameter [31:0] RESET_PC = 32'h0000_0000,
    parameter RV32A = 0,
    parameter PMP_ENTRIES = 0
)(
    input  wire        clk,
    input  wire        resetn,

    output wire        trap,
    input  wire        irq_external_pulse,

    // ---- M_AXI_I : AXI4-Lite read-only (instruction) ----
    output wire        m_axi_i_arvalid,
    input  wire        m_axi_i_arready,
    output wire [31:0] m_axi_i_araddr,
    output wire [ 2:0] m_axi_i_arprot,
    input  wire        m_axi_i_rvalid,
    output wire        m_axi_i_rready,
    input  wire [31:0] m_axi_i_rdata,
    input  wire [ 1:0] m_axi_i_rresp,

    // ---- M_AXI_D : AXI4-Lite read+write (data) ----
    output wire        m_axi_d_arvalid,
    input  wire        m_axi_d_arready,
    output wire [31:0] m_axi_d_araddr,
    output wire [ 2:0] m_axi_d_arprot,
    input  wire        m_axi_d_rvalid,
    output wire        m_axi_d_rready,
    input  wire [31:0] m_axi_d_rdata,
    input  wire [ 1:0] m_axi_d_rresp,
    output wire        m_axi_d_awvalid,
    input  wire        m_axi_d_awready,
    output wire [31:0] m_axi_d_awaddr,
    output wire [ 2:0] m_axi_d_awprot,
    output wire        m_axi_d_wvalid,
    input  wire        m_axi_d_wready,
    output wire [31:0] m_axi_d_wdata,
    output wire [ 3:0] m_axi_d_wstrb,
    input  wire        m_axi_d_bvalid,
    output wire        m_axi_d_bready,
    input  wire [ 1:0] m_axi_d_bresp,

    output wire        dbg_axi_err,
    output wire [31:0] dbg_pc,
    output wire [31:0] dbg_instr,
    output wire [ 2:0] dbg_state
);
    // native bus between core and bridge
    wire        ibus_req, ibus_ready;
    wire [31:0] ibus_addr, ibus_rdata;
    wire        dbus_req, dbus_we, dbus_ready;
    wire [31:0] dbus_addr, dbus_wdata, dbus_rdata;
    wire [ 3:0] dbus_wstrb;
    wire        dbg_dummy_halted;
    wire        dbg_dummy_mode;
    wire [31:0] dbg_dummy_acc_rdata;
    wire        dbg_dummy_acc_err;

    cpu_m1_top #(
        .RESET_PC(RESET_PC),
        .RV32A(RV32A),
        .PMP_ENTRIES(PMP_ENTRIES)
    ) u_cpu (
        .clk(clk), .resetn(resetn), .trap(trap),
        .ibus_req(ibus_req), .ibus_addr(ibus_addr),
        .ibus_ready(ibus_ready), .ibus_rdata(ibus_rdata),
        .dbus_req(dbus_req), .dbus_addr(dbus_addr), .dbus_we(dbus_we),
        .dbus_wstrb(dbus_wstrb), .dbus_wdata(dbus_wdata),
        .dbus_ready(dbus_ready), .dbus_rdata(dbus_rdata),
        .irq_external_pulse(irq_external_pulse),
        .mtip(1'b0), .msip(1'b0),
        .meip               (1'b0),
        .dm_halt_req        (1'b0),
        .dm_resume_req      (1'b0),
        .dm_hart_halted     (dbg_dummy_halted),
        .debug_mode         (dbg_dummy_mode),
        .dm_acc_en          (1'b0),
        .dm_acc_write       (1'b0),
        .dm_acc_regno       (16'h0),
        .dm_acc_wdata       (32'h0),
        .dm_acc_rdata       (dbg_dummy_acc_rdata),
        .dm_acc_err         (dbg_dummy_acc_err),
        .dbg_pc(dbg_pc), .dbg_instr(dbg_instr), .dbg_state(dbg_state)
    );

    axil_bridge u_axil (
        .clk(clk), .resetn(resetn),
        .ibus_req(ibus_req), .ibus_addr(ibus_addr),
        .ibus_ready(ibus_ready), .ibus_rdata(ibus_rdata),
        .dbus_req(dbus_req), .dbus_addr(dbus_addr), .dbus_we(dbus_we),
        .dbus_wstrb(dbus_wstrb), .dbus_wdata(dbus_wdata),
        .dbus_ready(dbus_ready), .dbus_rdata(dbus_rdata),
        .m_axi_i_arvalid(m_axi_i_arvalid), .m_axi_i_arready(m_axi_i_arready),
        .m_axi_i_araddr(m_axi_i_araddr), .m_axi_i_arprot(m_axi_i_arprot),
        .m_axi_i_rvalid(m_axi_i_rvalid), .m_axi_i_rready(m_axi_i_rready),
        .m_axi_i_rdata(m_axi_i_rdata), .m_axi_i_rresp(m_axi_i_rresp),
        .m_axi_d_arvalid(m_axi_d_arvalid), .m_axi_d_arready(m_axi_d_arready),
        .m_axi_d_araddr(m_axi_d_araddr), .m_axi_d_arprot(m_axi_d_arprot),
        .m_axi_d_rvalid(m_axi_d_rvalid), .m_axi_d_rready(m_axi_d_rready),
        .m_axi_d_rdata(m_axi_d_rdata), .m_axi_d_rresp(m_axi_d_rresp),
        .m_axi_d_awvalid(m_axi_d_awvalid), .m_axi_d_awready(m_axi_d_awready),
        .m_axi_d_awaddr(m_axi_d_awaddr), .m_axi_d_awprot(m_axi_d_awprot),
        .m_axi_d_wvalid(m_axi_d_wvalid), .m_axi_d_wready(m_axi_d_wready),
        .m_axi_d_wdata(m_axi_d_wdata), .m_axi_d_wstrb(m_axi_d_wstrb),
        .m_axi_d_bvalid(m_axi_d_bvalid), .m_axi_d_bready(m_axi_d_bready),
        .m_axi_d_bresp(m_axi_d_bresp),
        .dbg_axi_err(dbg_axi_err)
    );
endmodule
`default_nettype wire
