// =============================================================================
// soc_m3v_top.v — ADR-0068 minimal-first M1 host + M3V NPU SoC
// -----------------------------------------------------------------------------
// M2 integration: the real cpu_m1 host boots from instruction memory, writes
// NPU TCM/CSR and PLIC through control AXI-Lite, and shares SRAM with npu_top
// DMA through a named AXI4-full bridge/arbiter data path.
// -----------------------------------------------------------------------------
// M3b-3 two-bus formalization (ADR-0068 §2.5):
//   CONTROL AXI (32-bit, always): host M_AXI_D -> soc_axil_decode ->
//       {CLINT 0x0200, PLIC 0x0c00, UART 0x1000, NPU CSR/TCM 0x3000,
//        GPIO 0x1100, XIP 0x4000_0000 16MB RO, SRAM host-bridge 0x8000}.
//        DECERR off-map.
//   DATA AXI (DMA_DATA_W = 64*MAT_LANES): npu_dma master + host bridge (axil_to_full,
//       narrow-beat-on-wide-bus) -> axi_full_arbiter_2x1 -> axi_full_sram @0x8000.
//   BRIDGE: axil_to_full crosses control->data for host weight/CQ writes.
//   Region protection (see npu_dma_m3b_design §7): npu_top DECERR + npu_tcm SLVERR
//       (no-wrap) + npu_dma dma_err + cq_sequencer firmware bounds + 4KB burst cap
//       (all tested, gate_28/29). Limitation: axi_full_sram aliases out-of-range
//       (no SLVERR) -> intra-SRAM region guard is firmware-level; HW SLVERR +
//       region-boundary CSRs deferred to M3b-3-full.
// =============================================================================
`default_nettype none

module soc_m3v_top #(
    parameter [31:0] HOST_RESET_PC = 32'h0000_0000,
    parameter integer HOST_IMEM_WORDS = 8192,
    parameter integer HOST_IMEM_AW    = 13,
    parameter integer SHARED_WORDS    = 16384,
    parameter integer SHARED_AW       = 14,
    parameter integer DMA_DATA_W      = 32,
    parameter [1023:0] HOST_INIT_HEX  = "",
    parameter [1023:0] SHARED_INIT_HEX = ""
) (
    input  wire clk,
    input  wire resetn,
    output wire host_trap,
    output wire host_axi_err,
    output wire [31:0] host_dbg_pc,
    output wire [31:0] host_dbg_instr,
    output wire [ 2:0] host_dbg_state,
    output wire npu_irq,
    output wire uart_tx_strobe,
    output wire [ 7:0] uart_tx_byte,
    output wire qspi_sclk,
    output wire qspi_cs_n,
    output wire [3:0] qspi_io_o,
    output wire [3:0] qspi_io_oe,
    input  wire [3:0] qspi_io_i,
    output wire [15:0] gpio_out,
    output wire [15:0] gpio_oe,
    input  wire [15:0] gpio_in,
    input  wire jtag_tck,
    input  wire jtag_tms,
    input  wire jtag_tdi,
    output wire jtag_tdo,
    output wire dm_ndmreset
);
    initial begin
        if (DMA_DATA_W != 32 && DMA_DATA_W != 64 && DMA_DATA_W != 128 && DMA_DATA_W != 256)
            $fatal(1, "soc_m3v_top: DMA_DATA_W must be one of 32/64/128/256");
    end

    wire        hi_arvalid, hi_arready, hi_rvalid, hi_rready;
    wire [31:0] hi_araddr, hi_rdata;
    wire [ 2:0] hi_arprot;
    wire [ 1:0] hi_rresp;

    wire        hd_arvalid, hd_arready, hd_rvalid, hd_rready;
    wire [31:0] hd_araddr, hd_rdata;
    wire [ 2:0] hd_arprot;
    wire [ 1:0] hd_rresp;
    wire        hd_awvalid, hd_awready, hd_wvalid, hd_wready, hd_bvalid, hd_bready;
    wire [31:0] hd_awaddr, hd_wdata;
    wire [ 2:0] hd_awprot;
    wire [ 3:0] hd_wstrb;
    wire [ 1:0] hd_bresp;

    wire        host_ibus_req, host_ibus_ready;
    wire [31:0] host_ibus_addr, host_ibus_rdata;
    wire        host_dbus_req, host_dbus_we, host_dbus_ready;
    wire [31:0] host_dbus_addr, host_dbus_wdata, host_dbus_rdata;
    wire [ 3:0] host_dbus_wstrb;
    wire        dbg_halt_req;
    wire        dbg_resume_req;
    wire        dbg_hart_halted;
    wire        dbg_mode;
    wire        dbg_acc_en;
    wire        dbg_acc_write;
    wire [15:0] dbg_acc_regno;
    wire [31:0] dbg_acc_wdata;
    wire [31:0] dbg_acc_rdata;
    wire        dbg_acc_err;
    wire [63:0] dbg_dmi_reads;
    wire [63:0] dbg_dmi_writes;
    wire        plic_meip;
    wire        clint_mtip;
    wire        clint_msip;

    cpu_m1_top #(
        .RESET_PC(HOST_RESET_PC),
        .RV32A(0),
        .PMP_ENTRIES(0)
    ) u_host_core (
        .clk(clk), .resetn(resetn), .trap(host_trap),
        .ibus_req(host_ibus_req), .ibus_addr(host_ibus_addr),
        .ibus_ready(host_ibus_ready), .ibus_rdata(host_ibus_rdata),
        .dbus_req(host_dbus_req), .dbus_addr(host_dbus_addr), .dbus_we(host_dbus_we),
        .dbus_wstrb(host_dbus_wstrb), .dbus_wdata(host_dbus_wdata),
        .dbus_ready(host_dbus_ready), .dbus_rdata(host_dbus_rdata),
        .irq_external_pulse(1'b0),
        .mtip(clint_mtip), .msip(clint_msip),
        .meip(plic_meip),
        .dm_halt_req(dbg_halt_req),
        .dm_resume_req(dbg_resume_req),
        .dm_hart_halted(dbg_hart_halted),
        .debug_mode(dbg_mode),
        .dm_acc_en(dbg_acc_en),
        .dm_acc_write(dbg_acc_write),
        .dm_acc_regno(dbg_acc_regno),
        .dm_acc_wdata(dbg_acc_wdata),
        .dm_acc_rdata(dbg_acc_rdata),
        .dm_acc_err(dbg_acc_err),
        .dbg_pc(host_dbg_pc), .dbg_instr(host_dbg_instr), .dbg_state(host_dbg_state),
        /* verilator lint_off PINCONNECTEMPTY */
        .rvfi_valid(), .rvfi_pc(), .rvfi_trap(), .rvfi_trap_cause(), .rvfi_intr(),
        .rvfi_rd_addr(), .rvfi_rd_wdata(),
        .rvvi_v_valid(), .rvvi_v_vd(), .rvvi_v_wdata(), .rvvi_vl(), .rvvi_vtype(),
        .rvfi_insn(), .rvfi_trap_mtval(), .rvfi_mstatus(),
        .rvfi_mem_re(), .rvfi_mem_we(), .rvfi_mem_addr(), .rvfi_mem_wdata(), .rvfi_mem_wstrb(),
        .rvfi_f_valid(), .rvfi_f_rd(), .rvfi_f_wdata()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    dtm u_dtm (
        .clk(clk),
        .rst(~resetn),
        .tck(jtag_tck),
        .tms(jtag_tms),
        .tdi(jtag_tdi),
        .tdo(jtag_tdo),
        .halt_req(dbg_halt_req),
        .resume_req(dbg_resume_req),
        .ndmreset(dm_ndmreset),
        .hart_halted(dbg_hart_halted),
        .hart_havereset(!resetn),
        .acc_en(dbg_acc_en),
        .acc_write(dbg_acc_write),
        .acc_regno(dbg_acc_regno),
        .acc_wdata(dbg_acc_wdata),
        .acc_rdata(dbg_acc_rdata),
        .acc_err(dbg_acc_err),
        .dmi_reads(dbg_dmi_reads),
        .dmi_writes(dbg_dmi_writes)
    );

    axil_bridge u_host_axil (
        .clk(clk), .resetn(resetn),
        .ibus_req(host_ibus_req), .ibus_addr(host_ibus_addr),
        .ibus_ready(host_ibus_ready), .ibus_rdata(host_ibus_rdata),
        .dbus_req(host_dbus_req), .dbus_addr(host_dbus_addr), .dbus_we(host_dbus_we),
        .dbus_wstrb(host_dbus_wstrb), .dbus_wdata(host_dbus_wdata),
        .dbus_ready(host_dbus_ready), .dbus_rdata(host_dbus_rdata),
        .m_axi_i_arvalid(hi_arvalid), .m_axi_i_arready(hi_arready),
        .m_axi_i_araddr(hi_araddr), .m_axi_i_arprot(hi_arprot),
        .m_axi_i_rvalid(hi_rvalid), .m_axi_i_rready(hi_rready),
        .m_axi_i_rdata(hi_rdata), .m_axi_i_rresp(hi_rresp),
        .m_axi_d_arvalid(hd_arvalid), .m_axi_d_arready(hd_arready),
        .m_axi_d_araddr(hd_araddr), .m_axi_d_arprot(hd_arprot),
        .m_axi_d_rvalid(hd_rvalid), .m_axi_d_rready(hd_rready),
        .m_axi_d_rdata(hd_rdata), .m_axi_d_rresp(hd_rresp),
        .m_axi_d_awvalid(hd_awvalid), .m_axi_d_awready(hd_awready),
        .m_axi_d_awaddr(hd_awaddr), .m_axi_d_awprot(hd_awprot),
        .m_axi_d_wvalid(hd_wvalid), .m_axi_d_wready(hd_wready),
        .m_axi_d_wdata(hd_wdata), .m_axi_d_wstrb(hd_wstrb),
        .m_axi_d_bvalid(hd_bvalid), .m_axi_d_bready(hd_bready),
        .m_axi_d_bresp(hd_bresp),
        .dbg_axi_err(host_axi_err)
    );

    wire        im_arvalid, im_arready, im_rvalid, im_rready;
    wire [31:0] im_araddr, im_rdata;
    wire [ 2:0] im_arprot;
    wire [ 1:0] im_rresp;
    wire        x_i_arvalid, x_i_arready, x_i_rvalid, x_i_rready;
    wire [31:0] x_i_araddr, x_i_rdata;
    wire [ 1:0] x_i_rresp;
    reg         i_route_busy;
    reg         i_route_xip_q;
    wire        i_route_xip = i_route_busy ? i_route_xip_q : (hi_araddr[31:24] == 8'h40);

    assign im_arvalid = hi_arvalid && !i_route_xip;
    assign x_i_arvalid = hi_arvalid && i_route_xip;
    assign im_araddr = hi_araddr;
    assign x_i_araddr = hi_araddr;
    assign im_arprot = hi_arprot;
    assign hi_arready = i_route_xip ? x_i_arready : im_arready;
    assign im_rready = hi_rready && !i_route_xip;
    assign x_i_rready = hi_rready && i_route_xip;
    assign hi_rvalid = i_route_xip ? x_i_rvalid : im_rvalid;
    assign hi_rdata = i_route_xip ? x_i_rdata : im_rdata;
    assign hi_rresp = i_route_xip ? x_i_rresp : im_rresp;

    always @(posedge clk) begin
        if (!resetn) begin
            i_route_busy <= 1'b0;
            i_route_xip_q <= 1'b0;
        end else begin
            if (!i_route_busy && hi_arvalid && hi_arready) begin
                i_route_busy <= 1'b1;
                i_route_xip_q <= (hi_araddr[31:24] == 8'h40);
            end
            if (hi_rvalid && hi_rready)
                i_route_busy <= 1'b0;
        end
    end

    axil_imem #(
        .WORDS(HOST_IMEM_WORDS),
        .AW(HOST_IMEM_AW),
        .INIT_HEX(HOST_INIT_HEX)
    ) u_host_imem (
        .clk(clk),
        .resetn(resetn),
        .arvalid(im_arvalid),
        .arready(im_arready),
        .araddr(im_araddr),
        .arprot(im_arprot),
        .rvalid(im_rvalid),
        .rready(im_rready),
        .rdata(im_rdata),
        .rresp(im_rresp)
    );

    wire        n_s_awvalid, n_s_awready, n_s_wvalid, n_s_wready, n_s_bvalid, n_s_bready;
    wire [31:0] n_s_awaddr, n_s_wdata;
    wire [ 2:0] n_s_awprot;
    wire [ 3:0] n_s_wstrb;
    wire [ 1:0] n_s_bresp;
    wire        n_s_arvalid, n_s_arready, n_s_rvalid, n_s_rready;
    wire [31:0] n_s_araddr, n_s_rdata;
    wire [ 2:0] n_s_arprot;
    wire [ 1:0] n_s_rresp;

    wire        hm_awvalid, hm_awready, hm_wvalid, hm_wready, hm_bvalid, hm_bready;
    wire [31:0] hm_awaddr, hm_wdata;
    wire [ 2:0] hm_awprot;
    wire [ 3:0] hm_wstrb;
    wire [ 1:0] hm_bresp;
    wire        hm_arvalid, hm_arready, hm_rvalid, hm_rready;
    wire [31:0] hm_araddr, hm_rdata;
    wire [ 2:0] hm_arprot;
    wire [ 1:0] hm_rresp;

    wire        p_s_awvalid, p_s_awready, p_s_wvalid, p_s_wready, p_s_bvalid, p_s_bready;
    wire [31:0] p_s_awaddr, p_s_wdata;
    wire [ 2:0] p_s_awprot;
    wire [ 3:0] p_s_wstrb;
    wire [ 1:0] p_s_bresp;
    wire        p_s_arvalid, p_s_arready, p_s_rvalid, p_s_rready;
    wire [31:0] p_s_araddr, p_s_rdata;
    wire [ 2:0] p_s_arprot;
    wire [ 1:0] p_s_rresp;

    wire        u_s_awvalid, u_s_awready, u_s_wvalid, u_s_wready, u_s_bvalid, u_s_bready;
    wire [31:0] u_s_awaddr, u_s_wdata;
    wire [ 2:0] u_s_awprot;
    wire [ 3:0] u_s_wstrb;
    wire [ 1:0] u_s_bresp;
    wire        u_s_arvalid, u_s_arready, u_s_rvalid, u_s_rready;
    wire [31:0] u_s_araddr, u_s_rdata;
    wire [ 2:0] u_s_arprot;
    wire [ 1:0] u_s_rresp;

    wire        c_s_awvalid, c_s_awready, c_s_wvalid, c_s_wready, c_s_bvalid, c_s_bready;
    wire [31:0] c_s_awaddr, c_s_wdata;
    wire [ 2:0] c_s_awprot;
    wire [ 3:0] c_s_wstrb;
    wire [ 1:0] c_s_bresp;
    wire        c_s_arvalid, c_s_arready, c_s_rvalid, c_s_rready;
    wire [31:0] c_s_araddr, c_s_rdata;
    wire [ 2:0] c_s_arprot;
    wire [ 1:0] c_s_rresp;

    wire        g_s_awvalid, g_s_awready, g_s_wvalid, g_s_wready, g_s_bvalid, g_s_bready;
    wire [31:0] g_s_awaddr, g_s_wdata;
    wire [ 2:0] g_s_awprot;
    wire [ 3:0] g_s_wstrb;
    wire [ 1:0] g_s_bresp;
    wire        g_s_arvalid, g_s_arready, g_s_rvalid, g_s_rready;
    wire [31:0] g_s_araddr, g_s_rdata;
    wire [ 2:0] g_s_arprot;
    wire [ 1:0] g_s_rresp;

    wire        x_s_awvalid, x_s_awready, x_s_wvalid, x_s_wready, x_s_bvalid, x_s_bready;
    wire [31:0] x_s_awaddr, x_s_wdata;
    wire [ 2:0] x_s_awprot;
    wire [ 3:0] x_s_wstrb;
    wire [ 1:0] x_s_bresp;
    wire        x_s_arvalid, x_s_arready, x_s_rvalid, x_s_rready;
    wire [31:0] x_s_araddr, x_s_rdata;
    wire [ 2:0] x_s_arprot;
    wire [ 1:0] x_s_rresp;

    wire        q_s_awvalid, q_s_awready, q_s_wvalid, q_s_wready, q_s_bvalid, q_s_bready;
    wire [31:0] q_s_awaddr, q_s_wdata;
    wire [ 2:0] q_s_awprot;
    wire [ 3:0] q_s_wstrb;
    wire [ 1:0] q_s_bresp;
    wire        q_s_arvalid, q_s_arready, q_s_rvalid, q_s_rready;
    wire [31:0] q_s_araddr, q_s_rdata;
    wire [ 2:0] q_s_arprot;
    wire [ 1:0] q_s_rresp;

    wire [31:0] qspi_cold_reads;
    wire [31:0] qspi_warm_reads;
    wire [31:0] qspi_quad_cold_reads;
    wire [31:0] qspi_quad_warm_reads;
    wire        qspi_mode_quad;
    wire        qspi_prog_start;
    wire [ 1:0] qspi_prog_op;
    wire [31:0] qspi_prog_addr;
    wire [ 8:0] qspi_prog_len;
    wire        qspi_prog_busy;
    wire        qspi_prog_done;
    wire [ 7:0] qspi_prog_rdsr;
    wire [ 8:0] qspi_wbuf_addr;
    wire [ 7:0] qspi_wbuf_data;

    wire        plic_en;
    wire [31:0] plic_addr;
    wire [31:0] plic_wdata;
    wire [ 3:0] plic_wstrb;
    wire [31:0] plic_rdata;
    wire        uart_en;
    wire [31:0] uart_addr;
    wire [31:0] uart_wdata;
    wire [ 3:0] uart_wstrb;
    wire [31:0] uart_rdata;
    wire        uart_tx_irq_o;
    wire        clint_en;
    wire [31:0] clint_addr;
    wire [31:0] clint_wdata;
    wire [ 3:0] clint_wstrb;
    wire [31:0] clint_rdata;
    wire        gpio_en;
    wire [31:0] gpio_addr;
    wire [31:0] gpio_wdata;
    wire [ 3:0] gpio_wstrb;
    wire [31:0] gpio_rdata;
    wire        qspi_csr_en;
    wire [31:0] qspi_csr_addr;
    wire [31:0] qspi_csr_wdata;
    wire [ 3:0] qspi_csr_wstrb;
    wire [31:0] qspi_csr_rdata;

    soc_axil_decode u_d_decode (
        .clk(clk),
        .resetn(resetn),
        .s_awvalid(hd_awvalid), .s_awready(hd_awready), .s_awaddr(hd_awaddr), .s_awprot(hd_awprot),
        .s_wvalid(hd_wvalid), .s_wready(hd_wready), .s_wdata(hd_wdata), .s_wstrb(hd_wstrb),
        .s_bvalid(hd_bvalid), .s_bready(hd_bready), .s_bresp(hd_bresp),
        .s_arvalid(hd_arvalid), .s_arready(hd_arready), .s_araddr(hd_araddr), .s_arprot(hd_arprot),
        .s_rvalid(hd_rvalid), .s_rready(hd_rready), .s_rdata(hd_rdata), .s_rresp(hd_rresp),
        .n_awvalid(n_s_awvalid), .n_awready(n_s_awready), .n_awaddr(n_s_awaddr), .n_awprot(n_s_awprot),
        .n_wvalid(n_s_wvalid), .n_wready(n_s_wready), .n_wdata(n_s_wdata), .n_wstrb(n_s_wstrb),
        .n_bvalid(n_s_bvalid), .n_bready(n_s_bready), .n_bresp(n_s_bresp),
        .n_arvalid(n_s_arvalid), .n_arready(n_s_arready), .n_araddr(n_s_araddr), .n_arprot(n_s_arprot),
        .n_rvalid(n_s_rvalid), .n_rready(n_s_rready), .n_rdata(n_s_rdata), .n_rresp(n_s_rresp),
        .p_awvalid(p_s_awvalid), .p_awready(p_s_awready), .p_awaddr(p_s_awaddr), .p_awprot(p_s_awprot),
        .p_wvalid(p_s_wvalid), .p_wready(p_s_wready), .p_wdata(p_s_wdata), .p_wstrb(p_s_wstrb),
        .p_bvalid(p_s_bvalid), .p_bready(p_s_bready), .p_bresp(p_s_bresp),
        .p_arvalid(p_s_arvalid), .p_arready(p_s_arready), .p_araddr(p_s_araddr), .p_arprot(p_s_arprot),
        .p_rvalid(p_s_rvalid), .p_rready(p_s_rready), .p_rdata(p_s_rdata), .p_rresp(p_s_rresp),
        .u_awvalid(u_s_awvalid), .u_awready(u_s_awready), .u_awaddr(u_s_awaddr), .u_awprot(u_s_awprot),
        .u_wvalid(u_s_wvalid), .u_wready(u_s_wready), .u_wdata(u_s_wdata), .u_wstrb(u_s_wstrb),
        .u_bvalid(u_s_bvalid), .u_bready(u_s_bready), .u_bresp(u_s_bresp),
        .u_arvalid(u_s_arvalid), .u_arready(u_s_arready), .u_araddr(u_s_araddr), .u_arprot(u_s_arprot),
        .u_rvalid(u_s_rvalid), .u_rready(u_s_rready), .u_rdata(u_s_rdata), .u_rresp(u_s_rresp),
        .c_awvalid(c_s_awvalid), .c_awready(c_s_awready), .c_awaddr(c_s_awaddr), .c_awprot(c_s_awprot),
        .c_wvalid(c_s_wvalid), .c_wready(c_s_wready), .c_wdata(c_s_wdata), .c_wstrb(c_s_wstrb),
        .c_bvalid(c_s_bvalid), .c_bready(c_s_bready), .c_bresp(c_s_bresp),
        .c_arvalid(c_s_arvalid), .c_arready(c_s_arready), .c_araddr(c_s_araddr), .c_arprot(c_s_arprot),
        .c_rvalid(c_s_rvalid), .c_rready(c_s_rready), .c_rdata(c_s_rdata), .c_rresp(c_s_rresp),
        .g_awvalid(g_s_awvalid), .g_awready(g_s_awready), .g_awaddr(g_s_awaddr), .g_awprot(g_s_awprot),
        .g_wvalid(g_s_wvalid), .g_wready(g_s_wready), .g_wdata(g_s_wdata), .g_wstrb(g_s_wstrb),
        .g_bvalid(g_s_bvalid), .g_bready(g_s_bready), .g_bresp(g_s_bresp),
        .g_arvalid(g_s_arvalid), .g_arready(g_s_arready), .g_araddr(g_s_araddr), .g_arprot(g_s_arprot),
        .g_rvalid(g_s_rvalid), .g_rready(g_s_rready), .g_rdata(g_s_rdata), .g_rresp(g_s_rresp),
        .x_awvalid(x_s_awvalid), .x_awready(x_s_awready), .x_awaddr(x_s_awaddr), .x_awprot(x_s_awprot),
        .x_wvalid(x_s_wvalid), .x_wready(x_s_wready), .x_wdata(x_s_wdata), .x_wstrb(x_s_wstrb),
        .x_bvalid(x_s_bvalid), .x_bready(x_s_bready), .x_bresp(x_s_bresp),
        .x_arvalid(x_s_arvalid), .x_arready(x_s_arready), .x_araddr(x_s_araddr), .x_arprot(x_s_arprot),
        .x_rvalid(x_s_rvalid), .x_rready(x_s_rready), .x_rdata(x_s_rdata), .x_rresp(x_s_rresp),
        .q_awvalid(q_s_awvalid), .q_awready(q_s_awready), .q_awaddr(q_s_awaddr), .q_awprot(q_s_awprot),
        .q_wvalid(q_s_wvalid), .q_wready(q_s_wready), .q_wdata(q_s_wdata), .q_wstrb(q_s_wstrb),
        .q_bvalid(q_s_bvalid), .q_bready(q_s_bready), .q_bresp(q_s_bresp),
        .q_arvalid(q_s_arvalid), .q_arready(q_s_arready), .q_araddr(q_s_araddr), .q_arprot(q_s_arprot),
        .q_rvalid(q_s_rvalid), .q_rready(q_s_rready), .q_rdata(q_s_rdata), .q_rresp(q_s_rresp),
        .m_awvalid(hm_awvalid), .m_awready(hm_awready), .m_awaddr(hm_awaddr), .m_awprot(hm_awprot),
        .m_wvalid(hm_wvalid), .m_wready(hm_wready), .m_wdata(hm_wdata), .m_wstrb(hm_wstrb),
        .m_bvalid(hm_bvalid), .m_bready(hm_bready), .m_bresp(hm_bresp),
        .m_arvalid(hm_arvalid), .m_arready(hm_arready), .m_araddr(hm_araddr), .m_arprot(hm_arprot),
        .m_rvalid(hm_rvalid), .m_rready(hm_rready), .m_rdata(hm_rdata), .m_rresp(hm_rresp)
    );

    plic_axil_shim u_plic_axil (
        .clk(clk),
        .resetn(resetn),
        .s_awvalid(p_s_awvalid), .s_awready(p_s_awready), .s_awaddr(p_s_awaddr), .s_awprot(p_s_awprot),
        .s_wvalid(p_s_wvalid), .s_wready(p_s_wready), .s_wdata(p_s_wdata), .s_wstrb(p_s_wstrb),
        .s_bvalid(p_s_bvalid), .s_bready(p_s_bready), .s_bresp(p_s_bresp),
        .s_arvalid(p_s_arvalid), .s_arready(p_s_arready), .s_araddr(p_s_araddr), .s_arprot(p_s_arprot),
        .s_rvalid(p_s_rvalid), .s_rready(p_s_rready), .s_rdata(p_s_rdata), .s_rresp(p_s_rresp),
        .plic_en(plic_en),
        .plic_addr(plic_addr),
        .plic_wdata(plic_wdata),
        .plic_wstrb(plic_wstrb),
        .plic_rdata(plic_rdata)
    );

    plic u_plic (
        .clk(clk),
        .rst(~resetn),
        // sources[i] = PLIC ID i+1: NPU keeps ID 1 (M2 contract, host_producer_irq
        // claims id==1); UART THRE = ID 2 (ADR-0069 as amended).
        .sources({5'b0, uart_tx_irq_o, npu_irq}),
        .en(plic_en),
        .addr(plic_addr),
        .wdata(plic_wdata),
        .wstrb(plic_wstrb),
        .rdata(plic_rdata),
        .meip_o(plic_meip)
    );

    periph_axil_shim u_uart_axil (
        .clk(clk),
        .resetn(resetn),
        .s_awvalid(u_s_awvalid), .s_awready(u_s_awready), .s_awaddr(u_s_awaddr), .s_awprot(u_s_awprot),
        .s_wvalid(u_s_wvalid), .s_wready(u_s_wready), .s_wdata(u_s_wdata), .s_wstrb(u_s_wstrb),
        .s_bvalid(u_s_bvalid), .s_bready(u_s_bready), .s_bresp(u_s_bresp),
        .s_arvalid(u_s_arvalid), .s_arready(u_s_arready), .s_araddr(u_s_araddr), .s_arprot(u_s_arprot),
        .s_rvalid(u_s_rvalid), .s_rready(u_s_rready), .s_rdata(u_s_rdata), .s_rresp(u_s_rresp),
        .periph_en(uart_en),
        .periph_addr(uart_addr),
        .periph_wdata(uart_wdata),
        .periph_wstrb(uart_wstrb),
        .periph_rdata(uart_rdata)
    );

    uart u_uart (
        .clk(clk),
        .rst(~resetn),
        .en(uart_en),
        .addr(uart_addr),
        .wdata(uart_wdata),
        .wstrb(uart_wstrb),
        .rdata(uart_rdata),
        .tx_strobe_o(uart_tx_strobe),
        .tx_byte_o(uart_tx_byte),
        .tx_irq_o(uart_tx_irq_o)
    );

    periph_axil_shim u_clint_axil (
        .clk(clk),
        .resetn(resetn),
        .s_awvalid(c_s_awvalid), .s_awready(c_s_awready), .s_awaddr(c_s_awaddr), .s_awprot(c_s_awprot),
        .s_wvalid(c_s_wvalid), .s_wready(c_s_wready), .s_wdata(c_s_wdata), .s_wstrb(c_s_wstrb),
        .s_bvalid(c_s_bvalid), .s_bready(c_s_bready), .s_bresp(c_s_bresp),
        .s_arvalid(c_s_arvalid), .s_arready(c_s_arready), .s_araddr(c_s_araddr), .s_arprot(c_s_arprot),
        .s_rvalid(c_s_rvalid), .s_rready(c_s_rready), .s_rdata(c_s_rdata), .s_rresp(c_s_rresp),
        .periph_en(clint_en),
        .periph_addr(clint_addr),
        .periph_wdata(clint_wdata),
        .periph_wstrb(clint_wstrb),
        .periph_rdata(clint_rdata)
    );

    clint u_clint (
        .clk(clk),
        .resetn(resetn),
        .en(clint_en),
        .addr(clint_addr),
        .wstrb(clint_wstrb),
        .wdata(clint_wdata),
        .rdata(clint_rdata),
        .mtip(clint_mtip),
        .msip(clint_msip)
    );

    periph_axil_shim u_gpio_axil (
        .clk(clk),
        .resetn(resetn),
        .s_awvalid(g_s_awvalid), .s_awready(g_s_awready), .s_awaddr(g_s_awaddr), .s_awprot(g_s_awprot),
        .s_wvalid(g_s_wvalid), .s_wready(g_s_wready), .s_wdata(g_s_wdata), .s_wstrb(g_s_wstrb),
        .s_bvalid(g_s_bvalid), .s_bready(g_s_bready), .s_bresp(g_s_bresp),
        .s_arvalid(g_s_arvalid), .s_arready(g_s_arready), .s_araddr(g_s_araddr), .s_arprot(g_s_arprot),
        .s_rvalid(g_s_rvalid), .s_rready(g_s_rready), .s_rdata(g_s_rdata), .s_rresp(g_s_rresp),
        .periph_en(gpio_en),
        .periph_addr(gpio_addr),
        .periph_wdata(gpio_wdata),
        .periph_wstrb(gpio_wstrb),
        .periph_rdata(gpio_rdata)
    );

    gpio #(
        .N(16)
    ) u_gpio (
        .clk(clk),
        .rst(~resetn),
        .en(gpio_en),
        .addr(gpio_addr),
        .wdata(gpio_wdata),
        .wstrb(gpio_wstrb),
        .rdata(gpio_rdata),
        .gpio_out(gpio_out),
        .gpio_oe(gpio_oe),
        .gpio_in(gpio_in)
    );

    periph_axil_shim u_qspi_csr_axil (
        .clk(clk),
        .resetn(resetn),
        .s_awvalid(q_s_awvalid), .s_awready(q_s_awready), .s_awaddr(q_s_awaddr), .s_awprot(q_s_awprot),
        .s_wvalid(q_s_wvalid), .s_wready(q_s_wready), .s_wdata(q_s_wdata), .s_wstrb(q_s_wstrb),
        .s_bvalid(q_s_bvalid), .s_bready(q_s_bready), .s_bresp(q_s_bresp),
        .s_arvalid(q_s_arvalid), .s_arready(q_s_arready), .s_araddr(q_s_araddr), .s_arprot(q_s_arprot),
        .s_rvalid(q_s_rvalid), .s_rready(q_s_rready), .s_rdata(q_s_rdata), .s_rresp(q_s_rresp),
        .periph_en(qspi_csr_en),
        .periph_addr(qspi_csr_addr),
        .periph_wdata(qspi_csr_wdata),
        .periph_wstrb(qspi_csr_wstrb),
        .periph_rdata(qspi_csr_rdata)
    );

    qspi_csr u_qspi_csr (
        .clk(clk),
        .rst(~resetn),
        .en(qspi_csr_en),
        .addr(qspi_csr_addr),
        .wdata(qspi_csr_wdata),
        .wstrb(qspi_csr_wstrb),
        .rdata(qspi_csr_rdata),
        .mode_quad_o(qspi_mode_quad),
        .start_o(qspi_prog_start),
        .op_o(qspi_prog_op),
        .prog_addr_o(qspi_prog_addr),
        .prog_len_o(qspi_prog_len),
        .busy_i(qspi_prog_busy),
        .done_i(qspi_prog_done),
        .rdsr_i(qspi_prog_rdsr),
        .wr_addr_i(qspi_wbuf_addr),
        .wr_data_o(qspi_wbuf_data)
    );

    qspi_axil_front u_qspi_xip (
        .clk(clk),
        .resetn(resetn),
        .mode_quad_i(qspi_mode_quad),
        .prog_start_i(qspi_prog_start),
        .prog_op_i(qspi_prog_op),
        .prog_addr_i(qspi_prog_addr),
        .prog_len_i(qspi_prog_len),
        .prog_busy_o(qspi_prog_busy),
        .prog_done_o(qspi_prog_done),
        .prog_rdsr_o(qspi_prog_rdsr),
        .wbuf_addr_o(qspi_wbuf_addr),
        .wbuf_data_i(qspi_wbuf_data),
        .i_arvalid(x_i_arvalid),
        .i_arready(x_i_arready),
        .i_araddr(x_i_araddr),
        .i_arprot(hi_arprot),
        .i_rvalid(x_i_rvalid),
        .i_rready(x_i_rready),
        .i_rdata(x_i_rdata),
        .i_rresp(x_i_rresp),
        .d_awvalid(x_s_awvalid),
        .d_awready(x_s_awready),
        .d_awaddr(x_s_awaddr),
        .d_awprot(x_s_awprot),
        .d_wvalid(x_s_wvalid),
        .d_wready(x_s_wready),
        .d_wdata(x_s_wdata),
        .d_wstrb(x_s_wstrb),
        .d_bvalid(x_s_bvalid),
        .d_bready(x_s_bready),
        .d_bresp(x_s_bresp),
        .d_arvalid(x_s_arvalid),
        .d_arready(x_s_arready),
        .d_araddr(x_s_araddr),
        .d_arprot(x_s_arprot),
        .d_rvalid(x_s_rvalid),
        .d_rready(x_s_rready),
        .d_rdata(x_s_rdata),
        .d_rresp(x_s_rresp),
        .o_sclk(qspi_sclk),
        .o_cs_n(qspi_cs_n),
        .io_o(qspi_io_o),
        .io_oe(qspi_io_oe),
        .io_i(qspi_io_i),
        .cold_reads(qspi_cold_reads),
        .warm_reads(qspi_warm_reads),
        .quad_cold_reads(qspi_quad_cold_reads),
        .quad_warm_reads(qspi_quad_warm_reads)
    );

    wire        h_arvalid, h_arready, h_rvalid, h_rready, h_rlast;
    wire [31:0] h_araddr;
    wire [DMA_DATA_W-1:0] h_rdata;
    wire [ 7:0] h_arlen;
    wire [ 2:0] h_arsize;
    wire [ 1:0] h_arburst, h_rresp;
    wire        h_awvalid, h_awready, h_wvalid, h_wready, h_wlast, h_bvalid, h_bready;
    wire [31:0] h_awaddr;
    wire [DMA_DATA_W-1:0] h_wdata;
    wire [ 7:0] h_awlen;
    wire [ 2:0] h_awsize;
    wire [ 1:0] h_awburst, h_bresp;
    wire [DMA_DATA_W/8-1:0] h_wstrb;

    axil_to_full #(.DMA_DATA_W(DMA_DATA_W)) u_host_shared_bridge (
        .clk(clk), .resetn(resetn),
        .s_awvalid(hm_awvalid), .s_awready(hm_awready), .s_awaddr(hm_awaddr), .s_awprot(hm_awprot),
        .s_wvalid(hm_wvalid), .s_wready(hm_wready), .s_wdata(hm_wdata), .s_wstrb(hm_wstrb),
        .s_bvalid(hm_bvalid), .s_bready(hm_bready), .s_bresp(hm_bresp),
        .s_arvalid(hm_arvalid), .s_arready(hm_arready), .s_araddr(hm_araddr), .s_arprot(hm_arprot),
        .s_rvalid(hm_rvalid), .s_rready(hm_rready), .s_rdata(hm_rdata), .s_rresp(hm_rresp),
        .m_arvalid(h_arvalid), .m_arready(h_arready), .m_araddr(h_araddr), .m_arlen(h_arlen),
        .m_arsize(h_arsize), .m_arburst(h_arburst),
        .m_rvalid(h_rvalid), .m_rready(h_rready), .m_rdata(h_rdata), .m_rlast(h_rlast), .m_rresp(h_rresp),
        .m_awvalid(h_awvalid), .m_awready(h_awready), .m_awaddr(h_awaddr), .m_awlen(h_awlen),
        .m_awsize(h_awsize), .m_awburst(h_awburst),
        .m_wvalid(h_wvalid), .m_wready(h_wready), .m_wdata(h_wdata), .m_wstrb(h_wstrb), .m_wlast(h_wlast),
        .m_bvalid(h_bvalid), .m_bready(h_bready), .m_bresp(h_bresp)
    );

    wire        n_m_arvalid, n_m_arready, n_m_rvalid, n_m_rready, n_m_rlast;
    wire [31:0] n_m_araddr;
    wire [DMA_DATA_W-1:0] n_m_rdata;
    wire [ 7:0] n_m_arlen;
    wire [ 2:0] n_m_arsize;
    wire [ 1:0] n_m_arburst, n_m_rresp;
    wire        n_m_awvalid, n_m_awready, n_m_wvalid, n_m_wready, n_m_wlast, n_m_bvalid, n_m_bready;
    wire [31:0] n_m_awaddr;
    wire [DMA_DATA_W-1:0] n_m_wdata;
    wire [ 7:0] n_m_awlen;
    wire [ 2:0] n_m_awsize;
    wire [ 1:0] n_m_awburst, n_m_bresp;
    wire [DMA_DATA_W/8-1:0] n_m_wstrb;
    wire        npu_start;
    wire [31:0] npu_config;

    npu_top #(
        .TCM_WORDS(8192),
        .TCM_AW(13),
        .ITCM_WORDS(2048),
        .ITCM_AW(11),
        .MAT_LANES(4),
        .DMA_DATA_W(DMA_DATA_W),
        .ML_V2_EN(0)
    ) u_npu (
        .clk(clk),
        .resetn(resetn),
        .s_awvalid(n_s_awvalid), .s_awready(n_s_awready), .s_awaddr(n_s_awaddr), .s_awprot(n_s_awprot),
        .s_wvalid(n_s_wvalid), .s_wready(n_s_wready), .s_wdata(n_s_wdata), .s_wstrb(n_s_wstrb),
        .s_bvalid(n_s_bvalid), .s_bready(n_s_bready), .s_bresp(n_s_bresp),
        .s_arvalid(n_s_arvalid), .s_arready(n_s_arready), .s_araddr(n_s_araddr), .s_arprot(n_s_arprot),
        .s_rvalid(n_s_rvalid), .s_rready(n_s_rready), .s_rdata(n_s_rdata), .s_rresp(n_s_rresp),
        .m_arvalid(n_m_arvalid), .m_arready(n_m_arready), .m_araddr(n_m_araddr), .m_arlen(n_m_arlen),
        .m_arsize(n_m_arsize), .m_arburst(n_m_arburst),
        .m_rvalid(n_m_rvalid), .m_rready(n_m_rready), .m_rdata(n_m_rdata), .m_rlast(n_m_rlast), .m_rresp(n_m_rresp),
        .m_awvalid(n_m_awvalid), .m_awready(n_m_awready), .m_awaddr(n_m_awaddr), .m_awlen(n_m_awlen),
        .m_awsize(n_m_awsize), .m_awburst(n_m_awburst),
        .m_wvalid(n_m_wvalid), .m_wready(n_m_wready), .m_wdata(n_m_wdata), .m_wstrb(n_m_wstrb), .m_wlast(n_m_wlast),
        .m_bvalid(n_m_bvalid), .m_bready(n_m_bready), .m_bresp(n_m_bresp),
        .irq(npu_irq),
        .npu_start(npu_start),
        .npu_config(npu_config),
        /* verilator lint_off PINCONNECTEMPTY */
        .rvfi_valid(), .rvfi_pc(), .rvfi_trap(), .rvfi_trap_cause(), .rvfi_intr(),
        .rvfi_rd_addr(), .rvfi_rd_wdata(), .rvfi_order(),
        .rvvi_v_valid(), .rvvi_v_vd(), .rvvi_v_wdata(), .rvvi_vl(), .rvvi_vtype(),
        .rvfi_insn(), .rvfi_trap_mtval(), .rvfi_mstatus(),
        .rvfi_mem_re(), .rvfi_mem_we(), .rvfi_mem_addr(), .rvfi_mem_wdata(), .rvfi_mem_wstrb(),
        .rvfi_f_valid(), .rvfi_f_rd(), .rvfi_f_wdata()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    wire        s_arvalid, s_arready, s_rvalid, s_rready, s_rlast;
    wire [31:0] s_araddr;
    wire [DMA_DATA_W-1:0] s_rdata;
    wire [ 7:0] s_arlen;
    wire [ 2:0] s_arsize;
    wire [ 1:0] s_arburst, s_rresp;
    wire        s_awvalid, s_awready, s_wvalid, s_wready, s_wlast, s_bvalid, s_bready;
    wire [31:0] s_awaddr;
    wire [DMA_DATA_W-1:0] s_wdata;
    wire [ 7:0] s_awlen;
    wire [ 2:0] s_awsize;
    wire [ 1:0] s_awburst, s_bresp;
    wire [DMA_DATA_W/8-1:0] s_wstrb;

    axi_full_arbiter_2x1 #(.DMA_DATA_W(DMA_DATA_W)) u_shared_arb (
        .clk(clk), .resetn(resetn),
        .m0_arvalid(h_arvalid), .m0_arready(h_arready), .m0_araddr(h_araddr), .m0_arlen(h_arlen),
        .m0_arsize(h_arsize), .m0_arburst(h_arburst),
        .m0_rvalid(h_rvalid), .m0_rready(h_rready), .m0_rdata(h_rdata), .m0_rlast(h_rlast), .m0_rresp(h_rresp),
        .m0_awvalid(h_awvalid), .m0_awready(h_awready), .m0_awaddr(h_awaddr), .m0_awlen(h_awlen),
        .m0_awsize(h_awsize), .m0_awburst(h_awburst),
        .m0_wvalid(h_wvalid), .m0_wready(h_wready), .m0_wdata(h_wdata), .m0_wstrb(h_wstrb), .m0_wlast(h_wlast),
        .m0_bvalid(h_bvalid), .m0_bready(h_bready), .m0_bresp(h_bresp),
        .m1_arvalid(n_m_arvalid), .m1_arready(n_m_arready), .m1_araddr(n_m_araddr), .m1_arlen(n_m_arlen),
        .m1_arsize(n_m_arsize), .m1_arburst(n_m_arburst),
        .m1_rvalid(n_m_rvalid), .m1_rready(n_m_rready), .m1_rdata(n_m_rdata), .m1_rlast(n_m_rlast), .m1_rresp(n_m_rresp),
        .m1_awvalid(n_m_awvalid), .m1_awready(n_m_awready), .m1_awaddr(n_m_awaddr), .m1_awlen(n_m_awlen),
        .m1_awsize(n_m_awsize), .m1_awburst(n_m_awburst),
        .m1_wvalid(n_m_wvalid), .m1_wready(n_m_wready), .m1_wdata(n_m_wdata), .m1_wstrb(n_m_wstrb), .m1_wlast(n_m_wlast),
        .m1_bvalid(n_m_bvalid), .m1_bready(n_m_bready), .m1_bresp(n_m_bresp),
        .s_arvalid(s_arvalid), .s_arready(s_arready), .s_araddr(s_araddr), .s_arlen(s_arlen),
        .s_arsize(s_arsize), .s_arburst(s_arburst),
        .s_rvalid(s_rvalid), .s_rready(s_rready), .s_rdata(s_rdata), .s_rlast(s_rlast), .s_rresp(s_rresp),
        .s_awvalid(s_awvalid), .s_awready(s_awready), .s_awaddr(s_awaddr), .s_awlen(s_awlen),
        .s_awsize(s_awsize), .s_awburst(s_awburst),
        .s_wvalid(s_wvalid), .s_wready(s_wready), .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wlast(s_wlast),
        .s_bvalid(s_bvalid), .s_bready(s_bready), .s_bresp(s_bresp)
    );

    axi_full_sram #(
        .WORDS(SHARED_WORDS),
        .AW(SHARED_AW),
        .DMA_DATA_W(DMA_DATA_W),
        .INIT_HEX(SHARED_INIT_HEX)
    ) u_shared_sram (
        .clk(clk), .resetn(resetn),
        .arvalid(s_arvalid), .arready(s_arready), .araddr(s_araddr), .arlen(s_arlen),
        .arsize(s_arsize), .arburst(s_arburst),
        .rvalid(s_rvalid), .rready(s_rready), .rdata(s_rdata), .rlast(s_rlast), .rresp(s_rresp),
        .awvalid(s_awvalid), .awready(s_awready), .awaddr(s_awaddr), .awlen(s_awlen),
        .awsize(s_awsize), .awburst(s_awburst),
        .wvalid(s_wvalid), .wready(s_wready), .wdata(s_wdata), .wstrb(s_wstrb), .wlast(s_wlast),
        .bvalid(s_bvalid), .bready(s_bready), .bresp(s_bresp)
    );

    wire unused_npu_status = |{npu_start, npu_config, dbg_dmi_reads, dbg_dmi_writes,
                               qspi_cold_reads, qspi_warm_reads,
                               qspi_quad_cold_reads, qspi_quad_warm_reads};
endmodule
`default_nettype wire
