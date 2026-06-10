// =============================================================================
// cpu_m1_soc_top.v -- Magpie_M1 native subsystem with CLINT, PLIC, and UART
// -----------------------------------------------------------------------------
// ADR-0020 memory map:
//   RAM   0x2000_0000  external native valid/ready D-bus
//   CLINT 0x0200_0000  internal clint.v
//   PLIC  0x0c00_0000  internal plic.v
//   UART  0x1000_0000  internal uart.v
// =============================================================================
`default_nettype none

module cpu_m1_soc_top #(
    parameter [31:0] RESET_PC = 32'h2000_0000,
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
    input  wire [ 6:0] plic_sources,

    input  wire        dmi_req_en,
    input  wire [ 6:0] dmi_req_addr,
    input  wire        dmi_req_write,
    input  wire [31:0] dmi_req_data,
    output wire [31:0] dmi_resp_data,
    output wire [ 1:0] dmi_resp_op,
    output wire        dm_ndmreset,

    output wire        uart_tx_strobe,
    output wire [ 7:0] uart_tx_byte,

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

    wire sel_ram;
    wire sel_clint;
    wire sel_plic;
    wire sel_uart;
    wire d_in_range;

    wire [31:0] clint_rdata;
    wire [31:0] plic_rdata;
    wire [31:0] uart_rdata;
    wire        mtip;
    wire        msip;
    wire        meip;
    wire        uart_tx_irq;
    wire        dm_halt_req;
    wire        dm_resume_req;
    wire        dm_hart_halted;
    wire        debug_mode;
    wire        dm_acc_en;
    wire        dm_acc_write;
    wire [15:0] dm_acc_regno;
    wire [31:0] dm_acc_wdata;
    wire [31:0] dm_acc_rdata;
    wire        dm_acc_err;
    wire [63:0] dm_dmi_reads;
    wire [63:0] dm_dmi_writes;

    addr_decoder u_d_decode (
        .addr_i(cpu_dbus_addr),
        .sel_ram_o(sel_ram),
        .sel_clint_o(sel_clint),
        .sel_plic_o(sel_plic),
        .sel_uart_o(sel_uart),
        .d_in_range_o(d_in_range)
    );

    assign dbus_req       = cpu_dbus_req && sel_ram;
    assign dbus_addr      = cpu_dbus_addr;
    assign dbus_we        = cpu_dbus_we && sel_ram;
    assign dbus_wstrb     = sel_ram ? cpu_dbus_wstrb : 4'h0;
    assign dbus_wdata     = cpu_dbus_wdata;

    assign cpu_dbus_ready = (cpu_dbus_req && (sel_clint | sel_plic | sel_uart | !d_in_range)) ? 1'b1 :
                            (sel_ram ? dbus_ready : 1'b0);
    assign cpu_dbus_rdata = sel_clint ? clint_rdata :
                            sel_plic  ? plic_rdata  :
                            sel_uart  ? uart_rdata  :
                            sel_ram   ? dbus_rdata  :
                                        32'h0000_0000;

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
        .meip(meip),
        .dm_halt_req(dm_halt_req),
        .dm_resume_req(dm_resume_req),
        .dm_hart_halted(dm_hart_halted),
        .debug_mode(debug_mode),
        .dm_acc_en(dm_acc_en),
        .dm_acc_write(dm_acc_write),
        .dm_acc_regno(dm_acc_regno),
        .dm_acc_wdata(dm_acc_wdata),
        .dm_acc_rdata(dm_acc_rdata),
        .dm_acc_err(dm_acc_err),
        .dbg_pc(dbg_pc),
        .dbg_instr(dbg_instr),
        .dbg_state(dbg_state)
    );

    dm u_dm (
        .clk(clk),
        .rst(!resetn),
        .dmi_req_en(dmi_req_en),
        .dmi_req_addr(dmi_req_addr),
        .dmi_req_write(dmi_req_write),
        .dmi_req_data(dmi_req_data),
        .dmi_resp_data(dmi_resp_data),
        .dmi_resp_op(dmi_resp_op),
        .halt_req(dm_halt_req),
        .resume_req(dm_resume_req),
        .ndmreset(dm_ndmreset),
        .hart_halted(dm_hart_halted),
        .hart_havereset(!resetn),
        .acc_en(dm_acc_en),
        .acc_write(dm_acc_write),
        .acc_regno(dm_acc_regno),
        .acc_wdata(dm_acc_wdata),
        .acc_rdata(dm_acc_rdata),
        .acc_err(dm_acc_err),
        .dmi_reads(dm_dmi_reads),
        .dmi_writes(dm_dmi_writes)
    );

    clint u_clint (
        .clk(clk),
        .resetn(resetn),
        .en(cpu_dbus_req && sel_clint),
        .addr(cpu_dbus_addr),
        .wstrb(cpu_dbus_wstrb),
        .wdata(cpu_dbus_wdata),
        .rdata(clint_rdata),
        .mtip(mtip),
        .msip(msip)
    );

    plic u_plic (
        .clk(clk),
        .rst(!resetn),
        .sources(plic_sources | {5'b0, uart_tx_irq, 1'b0}),
        .en(cpu_dbus_req && sel_plic),
        .addr(cpu_dbus_addr),
        .wdata(cpu_dbus_wdata),
        .wstrb(cpu_dbus_wstrb),
        .rdata(plic_rdata),
        .meip_o(meip)
    );

    uart u_uart (
        .clk(clk),
        .rst(!resetn),
        .en(cpu_dbus_req && sel_uart),
        .addr(cpu_dbus_addr),
        .wdata(cpu_dbus_wdata),
        .wstrb(cpu_dbus_wstrb),
        .rdata(uart_rdata),
        .tx_strobe_o(uart_tx_strobe),
        .tx_byte_o(uart_tx_byte),
        .tx_irq_o(uart_tx_irq)
    );
endmodule

`default_nettype wire
