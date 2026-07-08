// =============================================================================
// soc_m3v_top.v — ADR-0068 minimal-first M1 host + M3V NPU SoC
// -----------------------------------------------------------------------------
// M2 integration: the real cpu_m1 host boots from instruction memory, writes
// NPU TCM/CSR and PLIC through control AXI-Lite, and shares SRAM with npu_top
// DMA through a named AXI4-full bridge/arbiter data path.
// =============================================================================
`default_nettype none

module soc_m3v_top #(
    parameter [31:0] HOST_RESET_PC = 32'h0000_0000,
    parameter integer HOST_IMEM_WORDS = 8192,
    parameter integer HOST_IMEM_AW    = 13,
    parameter integer SHARED_WORDS    = 16384,
    parameter integer SHARED_AW       = 14,
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
    output wire npu_irq
);
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
    wire        dbg_dummy_halted;
    wire        dbg_dummy_mode;
    wire [31:0] dbg_dummy_acc_rdata;
    wire        dbg_dummy_acc_err;
    wire        plic_meip;

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
        .mtip(1'b0), .msip(1'b0),
        .meip(plic_meip),
        .dm_halt_req(1'b0),
        .dm_resume_req(1'b0),
        .dm_hart_halted(dbg_dummy_halted),
        .debug_mode(dbg_dummy_mode),
        .dm_acc_en(1'b0),
        .dm_acc_write(1'b0),
        .dm_acc_regno(16'h0),
        .dm_acc_wdata(32'h0),
        .dm_acc_rdata(dbg_dummy_acc_rdata),
        .dm_acc_err(dbg_dummy_acc_err),
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

    axil_imem #(
        .WORDS(HOST_IMEM_WORDS),
        .AW(HOST_IMEM_AW),
        .INIT_HEX(HOST_INIT_HEX)
    ) u_host_imem (
        .clk(clk),
        .resetn(resetn),
        .arvalid(hi_arvalid),
        .arready(hi_arready),
        .araddr(hi_araddr),
        .arprot(hi_arprot),
        .rvalid(hi_rvalid),
        .rready(hi_rready),
        .rdata(hi_rdata),
        .rresp(hi_rresp)
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

    wire        plic_en;
    wire [31:0] plic_addr;
    wire [31:0] plic_wdata;
    wire [ 3:0] plic_wstrb;
    wire [31:0] plic_rdata;

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
        .sources({6'b0, npu_irq}),
        .en(plic_en),
        .addr(plic_addr),
        .wdata(plic_wdata),
        .wstrb(plic_wstrb),
        .rdata(plic_rdata),
        .meip_o(plic_meip)
    );

    wire        h_arvalid, h_arready, h_rvalid, h_rready, h_rlast;
    wire [31:0] h_araddr, h_rdata;
    wire [ 7:0] h_arlen;
    wire [ 2:0] h_arsize;
    wire [ 1:0] h_arburst, h_rresp;
    wire        h_awvalid, h_awready, h_wvalid, h_wready, h_wlast, h_bvalid, h_bready;
    wire [31:0] h_awaddr, h_wdata;
    wire [ 7:0] h_awlen;
    wire [ 2:0] h_awsize;
    wire [ 1:0] h_awburst, h_bresp;
    wire [ 3:0] h_wstrb;

    axil_to_full u_host_shared_bridge (
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
    wire [31:0] n_m_araddr, n_m_rdata;
    wire [ 7:0] n_m_arlen;
    wire [ 2:0] n_m_arsize;
    wire [ 1:0] n_m_arburst, n_m_rresp;
    wire        n_m_awvalid, n_m_awready, n_m_wvalid, n_m_wready, n_m_wlast, n_m_bvalid, n_m_bready;
    wire [31:0] n_m_awaddr, n_m_wdata;
    wire [ 7:0] n_m_awlen;
    wire [ 2:0] n_m_awsize;
    wire [ 1:0] n_m_awburst, n_m_bresp;
    wire [ 3:0] n_m_wstrb;
    wire        npu_start;
    wire [31:0] npu_config;

    npu_top #(
        .TCM_WORDS(8192),
        .TCM_AW(13),
        .ITCM_WORDS(2048),
        .ITCM_AW(11),
        .MAT_LANES(4),
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
    wire [31:0] s_araddr, s_rdata;
    wire [ 7:0] s_arlen;
    wire [ 2:0] s_arsize;
    wire [ 1:0] s_arburst, s_rresp;
    wire        s_awvalid, s_awready, s_wvalid, s_wready, s_wlast, s_bvalid, s_bready;
    wire [31:0] s_awaddr, s_wdata;
    wire [ 7:0] s_awlen;
    wire [ 2:0] s_awsize;
    wire [ 1:0] s_awburst, s_bresp;
    wire [ 3:0] s_wstrb;

    axi_full_arbiter_2x1 u_shared_arb (
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

    wire unused_npu_status = |{npu_start, npu_config, dbg_dummy_halted, dbg_dummy_mode,
                               dbg_dummy_acc_rdata, dbg_dummy_acc_err};
endmodule
`default_nettype wire
