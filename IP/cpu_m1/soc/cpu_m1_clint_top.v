// =============================================================================
// cpu_m1_clint_top.v -- native Magpie_M1 subsystem with single-hart CLINT
// -----------------------------------------------------------------------------
// Wraps cpu_m1_top and intercepts D-side accesses to 0x0200_0000..0x0200_FFFF.
// Non-CLINT I/D accesses pass through the native valid/ready buses unchanged.
// =============================================================================
`default_nettype none

module cpu_m1_clint_top #(
    parameter [31:0] RESET_PC = 32'h0000_0000,
    parameter RV32A = 0,
    parameter PMP_ENTRIES = 0
)(
    input  wire        clk,
    input  wire        resetn,

    output wire        trap,

    output wire        ibus_req,
    output wire [31:0] ibus_addr,
    input  wire        ibus_ready,
    input  wire [31:0] ibus_rdata,

    output wire        dbus_req,
    output wire [31:0] dbus_addr,
    output wire        dbus_we,
    output wire [ 3:0] dbus_wstrb,
    output wire [31:0] dbus_wdata,
    input  wire        dbus_ready,
    input  wire [31:0] dbus_rdata,

    input  wire        irq_external_pulse,

    output wire [31:0] dbg_pc,
    output wire [31:0] dbg_instr,
    output wire [ 2:0] dbg_state
);
    wire        cpu_dbus_req;
    wire [31:0] cpu_dbus_addr;
    wire        cpu_dbus_we;
    wire [ 3:0] cpu_dbus_wstrb;
    wire [31:0] cpu_dbus_wdata;
    wire        cpu_dbus_ready;
    wire [31:0] cpu_dbus_rdata;
    wire        mtip;
    wire        msip;

    wire clint_sel = cpu_dbus_req && (cpu_dbus_addr[31:16] == 16'h0200);
    wire [31:0] clint_rdata;

    assign dbus_req       = cpu_dbus_req && !clint_sel;
    assign dbus_addr      = cpu_dbus_addr;
    assign dbus_we        = cpu_dbus_we && !clint_sel;
    assign dbus_wstrb     = clint_sel ? 4'h0 : cpu_dbus_wstrb;
    assign dbus_wdata     = cpu_dbus_wdata;
    assign cpu_dbus_ready = clint_sel ? 1'b1 : dbus_ready;
    assign cpu_dbus_rdata = clint_sel ? clint_rdata : dbus_rdata;
    wire        dbg_dummy_halted;
    wire        dbg_dummy_mode;
    wire [31:0] dbg_dummy_acc_rdata;
    wire        dbg_dummy_acc_err;

    cpu_m1_top #(
        .RESET_PC(RESET_PC),
        .RV32A(RV32A),
        .PMP_ENTRIES(PMP_ENTRIES)
    ) u_cpu (
        .clk(clk),
        .resetn(resetn),
        .trap(trap),
        .ibus_req(ibus_req),
        .ibus_addr(ibus_addr),
        .ibus_ready(ibus_ready),
        .ibus_rdata(ibus_rdata),
        .dbus_req(cpu_dbus_req),
        .dbus_addr(cpu_dbus_addr),
        .dbus_we(cpu_dbus_we),
        .dbus_wstrb(cpu_dbus_wstrb),
        .dbus_wdata(cpu_dbus_wdata),
        .dbus_ready(cpu_dbus_ready),
        .dbus_rdata(cpu_dbus_rdata),
        .irq_external_pulse(irq_external_pulse),
        .mtip(mtip),
        .msip(msip),
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
        .dbg_pc(dbg_pc),
        .dbg_instr(dbg_instr),
        .dbg_state(dbg_state)
    );

    clint u_clint (
        .clk(clk),
        .resetn(resetn),
        .en(clint_sel),
        .addr(cpu_dbus_addr),
        .wstrb(cpu_dbus_wstrb),
        .wdata(cpu_dbus_wdata),
        .rdata(clint_rdata),
        .mtip(mtip),
        .msip(msip)
    );
endmodule

`default_nettype wire
