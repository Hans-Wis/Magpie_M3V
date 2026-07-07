// =============================================================================
// npu_top.v — Magpie_M3V NPU IP subsystem (Phase 2 Step 4: core in the socket)
// -----------------------------------------------------------------------------
// One AXI4-Lite slave faces the host fabric (NPU window 0x3xxx). Internally it
// decodes on addr[16]:  0x3000_xxxx -> CSR (npu_axil_regs), 0x3001_xxxx -> TCM.
// The DMA (AXI4-full master to shared memory) is programmed via the CSR and
// streams into the TCM, or writes result data from TCM back to shared memory.
// A level IRQ is raised to the host on completion.
// ADR-0034: the stripped cpu_m1 sequencer (EN_RVC/BP/RAS=0, RESET_PC=0) lives
// here, fetching/loading through dedicated npu_tcm core ports. CTRL.start gates
// its reset (Coral cg-release shape); a store to the core-local DONE mailbox
// (0x0001_0000) sets STATUS.npu_done + IRQ. Single-outstanding throughout.
// ADR-0035 extends dbus decode: addr[17] -> core-local CSR mirror, else
// addr[16] -> DONE mailbox, else TCM.
// =============================================================================
`default_nettype none

module npu_top #(
    parameter integer TCM_WORDS  = 8192,   // DTCM 32KB (ADR-0044, Coral row 4)
    parameter integer TCM_AW     = 13,
    parameter integer ITCM_WORDS = 2048,   // ITCM 8KB
    parameter integer ITCM_AW    = 11,
    parameter integer MAT_LANES  = 4,      // ADR-0067 LANES SKU: 1/2/4 => 64/128/256 MAC
    parameter integer ML_V2_EN   = 0       // ADR-0067 v2 Phase A: 0 => firmware path (zero regression)
) (
    input  wire        clk,
    input  wire        resetn,

    // ---- AXI4-Lite slave (from host fabric) ----
    input  wire        s_awvalid, output wire s_awready, input wire [31:0] s_awaddr, input wire [2:0] s_awprot,
    input  wire        s_wvalid,  output wire s_wready,  input wire [31:0] s_wdata,  input wire [3:0] s_wstrb,
    output wire        s_bvalid,  input  wire s_bready,  output wire [1:0] s_bresp,
    input  wire        s_arvalid, output wire s_arready, input wire [31:0] s_araddr, input wire [2:0] s_arprot,
    output wire        s_rvalid,  input  wire s_rready,  output wire [31:0] s_rdata, output wire [1:0] s_rresp,

    // ---- AXI4-full read master (to shared weight memory) ----
    output wire        m_arvalid, input wire m_arready, output wire [31:0] m_araddr,
    output wire [7:0]  m_arlen,   output wire [2:0] m_arsize, output wire [1:0] m_arburst,
    input  wire        m_rvalid,  output wire m_rready, input wire [31:0] m_rdata, input wire m_rlast, input wire [1:0] m_rresp,

    // ---- AXI4-full write master (to shared result memory) ----
    output wire        m_awvalid, input wire m_awready, output wire [31:0] m_awaddr,
    output wire [7:0]  m_awlen,   output wire [2:0] m_awsize, output wire [1:0] m_awburst,
    output wire        m_wvalid,  input wire m_wready, output wire [31:0] m_wdata, output wire [3:0] m_wstrb, output wire m_wlast,
    input  wire        m_bvalid,  output wire m_bready, input wire [1:0] m_bresp,

    // ---- to host / future core ----
    output wire        irq,
    output wire        npu_start,
    output wire [31:0] npu_config,

    // ---- RVFI/RVVI-lite trace port (ADR-0045, Coral row 8) ----
    output wire        rvfi_valid,
    output wire [31:0] rvfi_pc,
    output wire        rvfi_trap,
    output wire [31:0] rvfi_trap_cause,
    output wire        rvfi_intr,
    output wire [ 4:0] rvfi_rd_addr,
    output wire [31:0] rvfi_rd_wdata,
    output wire [63:0] rvfi_order,      // commit counter (npu_top level)
    output wire        rvvi_v_valid,
    output wire [ 4:0] rvvi_v_vd,
    output wire [127:0] rvvi_v_wdata,
    output wire [31:0] rvvi_vl,
    output wire [31:0] rvvi_vtype,
    output wire [31:0] rvfi_insn,
    output wire [31:0] rvfi_trap_mtval,
    output wire [31:0] rvfi_mstatus,
    output wire        rvfi_mem_re,
    output wire        rvfi_mem_we,
    output wire [31:0] rvfi_mem_addr,
    output wire [31:0] rvfi_mem_wdata,
    output wire [ 3:0] rvfi_mem_wstrb,
    output wire        rvfi_f_valid,
    output wire [ 4:0] rvfi_f_rd,
    output wire [31:0] rvfi_f_wdata
);
    localparam [31:0] CORE_RESET_PC = 32'h0000_0000;

    // ================= internal 1->N AXI4-Lite decode (ADR-0044) =================
    // route: 0=CSR (0x3000_xxxx), 1=DTCM (0x3001_xxxx), 3=ITCM (0x3002_xxxx),
    //        2=DECERR (any other NPU-window addr). Single-outstanding.
    reg  w_busy, r_busy; reg [1:0] w_route_l, r_route_l;
    function [1:0] dec; input [31:0] a; begin
        if (a[27:18] != 10'b0)       dec = 2'd2;   // beyond the 4-page window
        else if (a[17:16] == 2'b00)  dec = 2'd0;   // 0x3000_xxxx -> CSR
        else if (a[17:16] == 2'b01)  dec = 2'd1;   // 0x3001_xxxx -> DTCM
        else if (a[17:16] == 2'b10)  dec = 2'd3;   // 0x3002_xxxx -> ITCM
        else                         dec = 2'd2;   // 0x3003_xxxx -> DECERR
    end endfunction
    wire [1:0] w_dec = dec(s_awaddr);
    wire [1:0] r_dec = dec(s_araddr);
    wire w_known = w_busy | s_awvalid;        // write route known? (W may precede AW)
    wire [1:0] w_route = w_busy ? w_route_l : w_dec;
    wire [1:0] r_route = r_busy ? r_route_l : r_dec;
    always @(posedge clk) begin
        if (!resetn) begin w_busy<=0; r_busy<=0; w_route_l<=0; r_route_l<=0; end
        else begin
            if (!w_busy && s_awvalid && s_awready) begin w_busy<=1; w_route_l<=w_dec; end
            if (s_bvalid && s_bready) w_busy<=0;
            if (!r_busy && s_arvalid && s_arready) begin r_busy<=1; r_route_l<=r_dec; end
            if (s_rvalid && s_rready) r_busy<=0;
        end
    end

    // per-target port wires: c_=CSR, t_=DTCM, d_=DECERR, i_=ITCM
    wire c_awready,c_wready,c_bvalid,c_arready,c_rvalid; wire [31:0] c_rdata; wire [1:0] c_bresp,c_rresp;
    wire t_awready,t_wready,t_bvalid,t_arready,t_rvalid; wire [31:0] t_rdata; wire [1:0] t_bresp,t_rresp;
    wire d_awready,d_wready,d_bvalid,d_arready,d_rvalid; wire [31:0] d_rdata; wire [1:0] d_bresp,d_rresp;
    wire i_awready,i_wready,i_bvalid,i_arready,i_rvalid; wire [31:0] i_rdata; wire [1:0] i_bresp,i_rresp;

    // ADR-0047: once drain completes, stop ACCEPTING new host transactions so
    // a polling host cannot starve the domain-reset pulse. Implemented by
    // deasserting the slave-side READY (never by masking a routed valid —
    // that would fake a handshake and swallow the transaction).
    wire hard_freeze;
    wire aw_ok = ~hard_freeze;                    // new AW acceptance allowed
    wire w_ok  = ~hard_freeze | w_busy;           // in-flight write may finish
    wire ar_ok = ~hard_freeze;                    // new AR acceptance allowed
    wire c_awvalid = s_awvalid & aw_ok & (w_route==2'd0);
    wire t_awvalid = s_awvalid & aw_ok & (w_route==2'd1);
    wire d_awvalid = s_awvalid & aw_ok & (w_route==2'd2);
    wire i_awvalid = s_awvalid & aw_ok & (w_route==2'd3);
    wire c_wvalid  = s_wvalid & w_ok & w_known & (w_route==2'd0);
    wire t_wvalid  = s_wvalid & w_ok & w_known & (w_route==2'd1);
    wire d_wvalid  = s_wvalid & w_ok & w_known & (w_route==2'd2);
    wire i_wvalid  = s_wvalid & w_ok & w_known & (w_route==2'd3);
    wire c_bready  = s_bready & (w_route==2'd0);
    wire t_bready  = s_bready & (w_route==2'd1);
    wire d_bready  = s_bready & (w_route==2'd2);
    wire i_bready  = s_bready & (w_route==2'd3);
    wire c_arvalid = s_arvalid & ar_ok & (r_route==2'd0);
    wire t_arvalid = s_arvalid & ar_ok & (r_route==2'd1);
    wire d_arvalid = s_arvalid & ar_ok & (r_route==2'd2);
    wire i_arvalid = s_arvalid & ar_ok & (r_route==2'd3);
    wire c_rready  = s_rready & (r_route==2'd0);
    wire t_rready  = s_rready & (r_route==2'd1);
    wire d_rready  = s_rready & (r_route==2'd2);
    wire i_rready  = s_rready & (r_route==2'd3);

    assign s_awready = aw_ok & ((w_route==2'd0)?c_awready : (w_route==2'd1)?t_awready : (w_route==2'd3)?i_awready : d_awready);
    assign s_wready  = w_ok & (w_known ? ((w_route==2'd0)?c_wready : (w_route==2'd1)?t_wready : (w_route==2'd3)?i_wready : d_wready) : 1'b0);
    assign s_bvalid  = (w_route==2'd0)?c_bvalid : (w_route==2'd1)?t_bvalid : (w_route==2'd3)?i_bvalid : d_bvalid;
    assign s_bresp   = (w_route==2'd0)?c_bresp  : (w_route==2'd1)?t_bresp  : (w_route==2'd3)?i_bresp  : d_bresp;
    assign s_arready = ar_ok & ((r_route==2'd0)?c_arready : (r_route==2'd1)?t_arready : (r_route==2'd3)?i_arready : d_arready);
    assign s_rvalid  = (r_route==2'd0)?c_rvalid : (r_route==2'd1)?t_rvalid : (r_route==2'd3)?i_rvalid : d_rvalid;
    assign s_rdata   = (r_route==2'd0)?c_rdata  : (r_route==2'd1)?t_rdata  : (r_route==2'd3)?i_rdata  : d_rdata;
    assign s_rresp   = (r_route==2'd0)?c_rresp  : (r_route==2'd1)?t_rresp  : (r_route==2'd3)?i_rresp  : d_rresp;

    // ================= CSR/DMA register wires =================
    wire [31:0] dma_src, dma_dst, wb_src, wb_dst;
    wire [16:0] dma_len, wb_len;
    wire dma_go, wb_go, dma_busy, dma_done, wb_busy, wb_done, dma_err;
    // ================= NPU scalar core =================
    wire        core_resetn = resetn & npu_start;
    wire        ibus_req, ibus_ready;
    wire [31:0] ibus_addr, ibus_rdata;
    wire        dbus_req, dbus_we, dbus_ready;
    wire [31:0] dbus_addr, dbus_wdata, dbus_rdata;
    wire [ 3:0] dbus_wstrb;
    wire        core_trap;
    wire        core_dm_hart_halted, core_debug_mode, core_dm_acc_err;
    wire [31:0] core_dm_acc_rdata, core_dbg_pc, core_dbg_instr;
    wire [ 2:0] core_dbg_state;

    wire        core_i_en;
    wire [ITCM_AW-1:0] core_i_addr;
    wire [31:0] core_i_rdata;
    wire [TCM_AW-1:0] core_d_addr;
    wire [31:0] core_d_rdata;
    wire        core_d_we, core_d_wgrant;

    wire d_is_mbox = dbus_addr[16];
    wire d_is_csr  = dbus_addr[17];
    wire d_is_tcm  = ~d_is_csr & ~d_is_mbox;
    reg  core_csr_rd_pending;
    wire core_csr_en;
    wire core_csr_we;
    wire [7:0] core_csr_addr;
    wire [31:0] core_csr_rdata;

    always @(posedge clk) begin
        if (!resetn) begin
            core_csr_rd_pending <= 1'b0;
        end else if (core_csr_rd_pending) begin
            core_csr_rd_pending <= 1'b0;
        end else if (dbus_req && d_is_csr && !dbus_we) begin
            core_csr_rd_pending <= 1'b1;
        end
    end

    assign core_csr_en   = dbus_req & d_is_csr & (dbus_we | !core_csr_rd_pending);
    assign core_csr_we   = dbus_we;
    assign core_csr_addr = dbus_addr[7:0];
    assign ibus_ready   = 1'b1;
    assign core_i_en    = ibus_req;
    assign core_i_addr  = ibus_addr[ITCM_AW+1:2];   // fetch = ITCM (ADR-0044)
    assign ibus_rdata   = core_i_rdata;
    assign core_d_addr  = dbus_addr[TCM_AW+1:2];
    assign core_d_we    = dbus_req & dbus_we & d_is_tcm;
    wire   core_d_re    = dbus_req & ~dbus_we & d_is_tcm;   // ADR-0044 checker
    assign dbus_ready   = d_is_csr ? (dbus_we ? 1'b1 : core_csr_rd_pending) :
                          (d_is_mbox ? 1'b1 : (dbus_we ? core_d_wgrant : 1'b1));
    assign dbus_rdata   = d_is_csr ? core_csr_rdata :
                          (d_is_mbox ? 32'h0000_0000 : core_d_rdata);

    reg done_latch;
    wire mbox_done_w = dbus_req & dbus_ready & dbus_we & d_is_mbox & ~d_is_csr & dbus_wstrb[0] & dbus_wdata[0];
    always @(posedge clk) begin
        if (!resetn)          done_latch <= 1'b0;
        else if (!npu_start)  done_latch <= 1'b0;
        else if (mbox_done_w) done_latch <= 1'b1;
    end

    cpu_m1_top #(
        .RESET_PC(CORE_RESET_PC),
        .EN_RVC(0),
        .EN_BP(0),
        .EN_RAS(0),
        .EN_RVV(1),
        .EN_F(1)
    ) u_npu_core (
        .clk(clk),
        .resetn(core_resetn),
        .trap(core_trap),
        .ibus_req(ibus_req),
        .ibus_addr(ibus_addr),
        .ibus_ready(ibus_ready),
        .ibus_rdata(ibus_rdata),
        .dbus_req(dbus_req),
        .dbus_addr(dbus_addr),
        .dbus_we(dbus_we),
        .dbus_wstrb(dbus_wstrb),
        .dbus_wdata(dbus_wdata),
        .dbus_ready(dbus_ready),
        .dbus_rdata(dbus_rdata),
        .irq_external_pulse(1'b0),
        .mtip(1'b0),
        .msip(1'b0),
        .meip(1'b0),
        .dm_halt_req(1'b0),
        .dm_resume_req(1'b0),
        .dm_hart_halted(core_dm_hart_halted),
        .debug_mode(core_debug_mode),
        .dm_acc_en(1'b0),
        .dm_acc_write(1'b0),
        .dm_acc_regno(16'h0000),
        .dm_acc_wdata(32'h0000_0000),
        .dm_acc_rdata(core_dm_acc_rdata),
        .dm_acc_err(core_dm_acc_err),
        .dbg_pc(core_dbg_pc),
        .dbg_instr(core_dbg_instr),
        .dbg_state(core_dbg_state),
        .rvfi_valid(rvfi_valid), .rvfi_pc(rvfi_pc),
        .rvfi_trap(rvfi_trap), .rvfi_trap_cause(rvfi_trap_cause), .rvfi_intr(rvfi_intr),
        .rvfi_rd_addr(rvfi_rd_addr), .rvfi_rd_wdata(rvfi_rd_wdata),
        .rvvi_v_valid(rvvi_v_valid), .rvvi_v_vd(rvvi_v_vd),
        .rvvi_v_wdata(rvvi_v_wdata), .rvvi_vl(rvvi_vl), .rvvi_vtype(rvvi_vtype),
        .rvfi_insn(rvfi_insn), .rvfi_trap_mtval(rvfi_trap_mtval),
        .rvfi_mstatus(rvfi_mstatus),
        .rvfi_mem_re(rvfi_mem_re), .rvfi_mem_we(rvfi_mem_we),
        .rvfi_mem_addr(rvfi_mem_addr), .rvfi_mem_wdata(rvfi_mem_wdata),
        .rvfi_mem_wstrb(rvfi_mem_wstrb),
        .rvfi_f_valid(rvfi_f_valid), .rvfi_f_rd(rvfi_f_rd),
        .rvfi_f_wdata(rvfi_f_wdata)
    );

    // ADR-0045: commit order counter (resets with the sequencer)
    reg [63:0] rvfi_order_q;
    assign rvfi_order = rvfi_order_q;
    always @(posedge clk) begin
        if (!resetn || !npu_start) rvfi_order_q <= 64'd0;
        else if (rvfi_valid || rvfi_trap)   // retire OR trap event (Grok (b))
                                   rvfi_order_q <= rvfi_order_q + 64'd1;
    end

    // ================= matrix engine (ADR-0037) =================
    wire [31:0] mat_a_addr, mat_b_addr, mat_mult, mat_rsp, mat_clamp, mat_out_base;
    wire        mat_go, mat_busy, mat_done, mat_err;
    wire        npu_abort;
    wire        hard_req;
    reg         hard_pending;
    reg  [1:0]  hard_rst_cnt;
    wire        hard_busy   = hard_pending | (hard_rst_cnt != 2'd0);
    // ADR-0047: registers-only domain reset (memories persist; core held via start=0)
    wire        domain_rstn = resetn & (hard_rst_cnt == 2'd0);
    wire [2:0]  mat_cmd;
    wire [3:0]  mat_bank;
    wire [7:0]  mat_rpt;
    wire              eng_we, eng_a_re, eng_b_re;
    wire [TCM_AW-1:0] eng_a_addr, eng_b_addr, eng_waddr;
    wire [255:0]      eng_a_rdata, eng_b_rdata;
    wire [31:0]       eng_wdata;

    mat_engine #(.TCM_AW(TCM_AW), .LANES(MAT_LANES)) u_mat (
        .clk(clk), .resetn(domain_rstn),
        .go(mat_go), .abort_i(npu_abort), .cmd(mat_cmd), .arg_bank(mat_bank), .arg_rpt(mat_rpt),
        .a_addr(mat_a_addr), .b_addr(mat_b_addr),
        .rs_mult(mat_mult), .rs_shift(mat_rsp[7:0]), .rs_zp(mat_rsp[15:8]),
        .rs_min(mat_clamp[7:0]), .rs_max(mat_clamp[15:8]), .out_base(mat_out_base),
        .busy(mat_busy), .done(mat_done), .err_param(mat_err),
        .t_a_re(eng_a_re), .t_a_addr(eng_a_addr), .t_a_rdata(eng_a_rdata),
        .t_b_re(eng_b_re), .t_b_addr(eng_b_addr), .t_b_rdata(eng_b_rdata),
        .t_we(eng_we), .t_waddr(eng_waddr), .t_wdata(eng_wdata)
    );

    // ================= hard-reset FSM (ADR-0047) =================
    wire hard_quiet = !dma_busy && !wb_busy && !mat_busy;
    assign hard_freeze = (hard_pending && hard_quiet) || (hard_rst_cnt != 2'd0);
    always @(posedge clk) begin
        if (!resetn) begin
            hard_pending <= 1'b0; hard_rst_cnt <= 2'd0;
        end else begin
            if (hard_req) hard_pending <= 1'b1;
            if (hard_rst_cnt != 2'd0) begin
                hard_rst_cnt <= hard_rst_cnt - 2'd1;
            end else if (hard_pending && hard_quiet && !w_busy && !r_busy) begin
                hard_pending <= 1'b0;
                hard_rst_cnt <= 2'd2;      // registers -> power-on; SRAM persists
            end
        end
    end

    // ================= CSR block =================
    npu_axil_regs csr (
        .clk(clk), .resetn(domain_rstn),
        .s_axi_awvalid(c_awvalid),.s_axi_awready(c_awready),.s_axi_awaddr(s_awaddr),.s_axi_awprot(s_awprot),
        .s_axi_wvalid(c_wvalid),.s_axi_wready(c_wready),.s_axi_wdata(s_wdata),.s_axi_wstrb(s_wstrb),
        .s_axi_bvalid(c_bvalid),.s_axi_bready(c_bready),.s_axi_bresp(c_bresp),
        .s_axi_arvalid(c_arvalid),.s_axi_arready(c_arready),.s_axi_araddr(s_araddr),.s_axi_arprot(s_arprot),
        .s_axi_rvalid(c_rvalid),.s_axi_rready(c_rready),.s_axi_rdata(c_rdata),.s_axi_rresp(c_rresp),
        .npu_start(npu_start),.npu_config(npu_config),.npu_busy(npu_start & ~done_latch),.npu_done(done_latch),
        .core_csr_en(core_csr_en),.core_csr_we(core_csr_we),.core_csr_addr(core_csr_addr),
        .core_csr_wdata(dbus_wdata),.core_csr_rdata(core_csr_rdata_axil),
        .mat_a_addr(mat_a_addr_csr),.mat_b_addr(mat_b_addr_csr),.mat_mult(mat_mult_csr),
        .mat_rsp(mat_rsp_csr),.mat_clamp(mat_clamp_csr),.mat_out_base(mat_out_base_csr),
        .mat_go(mat_go_csr),.mat_cmd(mat_cmd_csr),.mat_bank(mat_bank_csr),.mat_rpt(mat_rpt_csr),
        .mat_busy(mat_busy),.mat_done(mat_done),.mat_err(mat_err),
        .abort_req(npu_abort),
        .hard_req(hard_req), .hard_busy(hard_busy),
        .dma_src(dma_src_csr),.dma_dst(dma_dst_csr),.dma_len(dma_len_csr),.dma_go(dma_go_csr),
        .dma_busy(dma_busy),.dma_done(dma_done),.dma_err(dma_err),
        .wb_src(wb_src_csr),.wb_dst(wb_dst_csr),.wb_len(wb_len_csr),.wb_go(wb_go_csr),
        .wb_busy(wb_busy),.wb_done(wb_done),
        .irq(irq)
    );

    // ================= DMA (AXI4-full master) <-> TCM =================
    wire dma_we, dma_re;
    wire [TCM_AW-1:0] dma_waddr, dma_raddr;
    wire [31:0] dma_wdata, dma_rdata;
    wire [TCM_AW-1:0] dma_buf_addr, dma_buf_raddr;
    wire dma_busy_engine, dma_done_engine;
    wire dma_start_write = wb_go & ~dma_go;     // preserve read GO if both pulses collide
    wire dma_start = dma_go | wb_go;
    wire [31:0] dma_desc_addr = dma_start_write ? wb_dst : dma_src;
    wire [TCM_AW-1:0] dma_desc_word = dma_start_write ? wb_src[TCM_AW-1:0] : dma_dst[TCM_AW-1:0];
    wire [16:0] dma_desc_len  = dma_start_write ? wb_len : dma_len;
    reg dma_mode_write_l;
    assign dma_waddr = dma_buf_addr;
    assign dma_raddr = dma_buf_raddr;
    assign dma_busy = dma_busy_engine & ~dma_mode_write_l;
    assign wb_busy  = dma_busy_engine &  dma_mode_write_l;
    assign dma_done = dma_done_engine & ~dma_mode_write_l;
    assign wb_done  = dma_done_engine &  dma_mode_write_l;

    // ============ mat_engine v2 Phase A: ML control shell + mux (ADR-0067) ============
    // npu_ml_ctrl owns its CSRs (off the core-local window) and drives mat/dma/wb
    // DIRECTLY when ml_active; the mux selects the firmware path (*_csr) otherwise.
    // ML_V2_EN=0 (default) => ml_active never asserts => transparent, zero regression.
    wire [31:0] mat_a_addr_csr, mat_b_addr_csr, mat_mult_csr, mat_rsp_csr, mat_clamp_csr, mat_out_base_csr;
    wire        mat_go_csr;
    wire [2:0]  mat_cmd_csr;
    wire [3:0]  mat_bank_csr;
    wire [7:0]  mat_rpt_csr;
    wire [31:0] dma_src_csr, dma_dst_csr, wb_src_csr, wb_dst_csr;
    wire [16:0] dma_len_csr, wb_len_csr;
    wire        dma_go_csr, wb_go_csr;
    wire [31:0] core_csr_rdata_axil;
    wire [31:0] ml_mat_a_addr, ml_mat_b_addr, ml_mat_mult, ml_mat_rsp, ml_mat_clamp, ml_mat_out_base;
    wire        ml_mat_go;
    wire [2:0]  ml_mat_cmd;
    wire [3:0]  ml_mat_bank;
    wire [7:0]  ml_mat_rpt;
    wire [31:0] ml_dma_src, ml_dma_dst, ml_wb_src, ml_wb_dst;
    wire [16:0] ml_dma_len, ml_wb_len;
    wire        ml_dma_go, ml_wb_go;
    wire [31:0] ml_csr_rdata;
    wire        ml_csr_hit, ml_active, ml_irq;

    npu_ml_ctrl #(.ML_V2_EN(ML_V2_EN)) u_ml (
        .clk(clk), .resetn(domain_rstn), .abort_i(npu_abort),
        .core_csr_en(core_csr_en), .core_csr_we(core_csr_we),
        .core_csr_addr(core_csr_addr), .core_csr_wdata(dbus_wdata),
        .ml_csr_rdata(ml_csr_rdata), .ml_csr_hit(ml_csr_hit),
        .mat_busy(mat_busy), .mat_done(mat_done), .mat_err(mat_err),
        .dma_busy(dma_busy), .dma_done(dma_done), .dma_err(dma_err),
        .wb_busy(wb_busy), .wb_done(wb_done),
        .ml_mat_a_addr(ml_mat_a_addr), .ml_mat_b_addr(ml_mat_b_addr), .ml_mat_mult(ml_mat_mult),
        .ml_mat_rsp(ml_mat_rsp), .ml_mat_clamp(ml_mat_clamp), .ml_mat_out_base(ml_mat_out_base),
        .ml_mat_go(ml_mat_go), .ml_mat_cmd(ml_mat_cmd), .ml_mat_bank(ml_mat_bank), .ml_mat_rpt(ml_mat_rpt),
        .ml_dma_src(ml_dma_src), .ml_dma_dst(ml_dma_dst), .ml_dma_len(ml_dma_len), .ml_dma_go(ml_dma_go),
        .ml_wb_src(ml_wb_src), .ml_wb_dst(ml_wb_dst), .ml_wb_len(ml_wb_len), .ml_wb_go(ml_wb_go),
        .ml_active(ml_active), .ml_irq(ml_irq)
    );

    assign mat_a_addr   = ml_active ? ml_mat_a_addr   : mat_a_addr_csr;
    assign mat_b_addr   = ml_active ? ml_mat_b_addr   : mat_b_addr_csr;
    assign mat_mult     = ml_active ? ml_mat_mult     : mat_mult_csr;
    assign mat_rsp      = ml_active ? ml_mat_rsp      : mat_rsp_csr;
    assign mat_clamp    = ml_active ? ml_mat_clamp    : mat_clamp_csr;
    assign mat_out_base = ml_active ? ml_mat_out_base : mat_out_base_csr;
    assign mat_go       = ml_active ? ml_mat_go       : mat_go_csr;
    assign mat_cmd      = ml_active ? ml_mat_cmd      : mat_cmd_csr;
    assign mat_bank     = ml_active ? ml_mat_bank     : mat_bank_csr;
    assign mat_rpt      = ml_active ? ml_mat_rpt      : mat_rpt_csr;
    assign dma_src = ml_active ? ml_dma_src : dma_src_csr;
    assign dma_dst = ml_active ? ml_dma_dst : dma_dst_csr;
    assign dma_len = ml_active ? ml_dma_len : dma_len_csr;
    assign dma_go  = ml_active ? ml_dma_go  : dma_go_csr;
    assign wb_src  = ml_active ? ml_wb_src  : wb_src_csr;
    assign wb_dst  = ml_active ? ml_wb_dst  : wb_dst_csr;
    assign wb_len  = ml_active ? ml_wb_len  : wb_len_csr;
    assign wb_go   = ml_active ? ml_wb_go   : wb_go_csr;
    assign core_csr_rdata = ml_csr_hit ? ml_csr_rdata : core_csr_rdata_axil;

    always @(posedge clk) begin
        if (!resetn)
            dma_mode_write_l <= 1'b0;
        else if (!dma_busy_engine && dma_start)
            dma_mode_write_l <= dma_start_write;
    end

    npu_dma #(.BUF_AW(TCM_AW)) dma (
        .clk(clk), .resetn(domain_rstn),
        .go(dma_start), .abort_i(npu_abort), .write_mode(dma_start_write),
        .src_addr(dma_desc_addr), .dst_word(dma_desc_word), .len_beats(dma_desc_len),
        .busy(dma_busy_engine), .done(dma_done_engine),
        .m_arvalid(m_arvalid),.m_arready(m_arready),.m_araddr(m_araddr),.m_arlen(m_arlen),
        .m_arsize(m_arsize),.m_arburst(m_arburst),
        .m_rvalid(m_rvalid),.m_rready(m_rready),.m_rdata(m_rdata),.m_rlast(m_rlast),.m_rresp(m_rresp),
        .m_awvalid(m_awvalid),.m_awready(m_awready),.m_awaddr(m_awaddr),.m_awlen(m_awlen),
        .m_awsize(m_awsize),.m_awburst(m_awburst),
        .m_wvalid(m_wvalid),.m_wready(m_wready),.m_wdata(m_wdata),.m_wstrb(m_wstrb),.m_wlast(m_wlast),
        .m_bvalid(m_bvalid),.m_bready(m_bready),.m_bresp(m_bresp),
        .buf_we(dma_we),.buf_addr(dma_buf_addr),.buf_wdata(dma_wdata),
        .buf_re(dma_re),.buf_raddr(dma_buf_raddr),.buf_rdata(dma_rdata),
        .err(dma_err)
    );

    // ================= TCM =================
    npu_tcm #(.WORDS(TCM_WORDS), .AW(TCM_AW)) tcm (
        .clk(clk), .resetn(resetn),
        .s_axi_awvalid(t_awvalid),.s_axi_awready(t_awready),.s_axi_awaddr(s_awaddr),.s_axi_awprot(s_awprot),
        .s_axi_wvalid(t_wvalid),.s_axi_wready(t_wready),.s_axi_wdata(s_wdata),.s_axi_wstrb(s_wstrb),
        .s_axi_bvalid(t_bvalid),.s_axi_bready(t_bready),.s_axi_bresp(t_bresp),
        .s_axi_arvalid(t_arvalid),.s_axi_arready(t_arready),.s_axi_araddr(s_araddr),.s_axi_arprot(s_arprot),
        .s_axi_rvalid(t_rvalid),.s_axi_rready(t_rready),.s_axi_rdata(t_rdata),.s_axi_rresp(t_rresp),
        .dma_we(dma_we),.dma_waddr(dma_waddr),.dma_wdata(dma_wdata),
        .dma_re(dma_re),.dma_raddr(dma_raddr),.dma_rdata(dma_rdata),
        .core_d_re(core_d_re),
        .core_d_addr(core_d_addr),.core_d_rdata(core_d_rdata),
        .core_d_we(core_d_we),.core_d_wdata(dbus_wdata),.core_d_wstrb(dbus_wstrb),.core_d_wgrant(core_d_wgrant),
        .eng_a_re(eng_a_re),.eng_a_addr(eng_a_addr),.eng_a_rdata(eng_a_rdata),
        .eng_b_re(eng_b_re),.eng_b_addr(eng_b_addr),.eng_b_rdata(eng_b_rdata),
        .eng_we(eng_we),.eng_waddr(eng_waddr),.eng_wdata(eng_wdata)
    );

    // ================= ITCM (ADR-0044: fetch + host 0x3002 window) =================
    npu_itcm #(.WORDS(ITCM_WORDS), .AW(ITCM_AW)) itcm (
        .clk(clk), .resetn(resetn),
        .s_axi_awvalid(i_awvalid),.s_axi_awready(i_awready),.s_axi_awaddr(s_awaddr),.s_axi_awprot(s_awprot),
        .s_axi_wvalid(i_wvalid),.s_axi_wready(i_wready),.s_axi_wdata(s_wdata),.s_axi_wstrb(s_wstrb),
        .s_axi_bvalid(i_bvalid),.s_axi_bready(i_bready),.s_axi_bresp(i_bresp),
        .s_axi_arvalid(i_arvalid),.s_axi_arready(i_arready),.s_axi_araddr(s_araddr),.s_axi_arprot(s_arprot),
        .s_axi_rvalid(i_rvalid),.s_axi_rready(i_rready),.s_axi_rdata(i_rdata),.s_axi_rresp(i_rresp),
        .core_i_en(core_i_en),.core_i_addr(core_i_addr),.core_i_rdata(core_i_rdata)
    );

    // ================= DECERR hole (out-of-window NPU addresses) =================
    axil_decerr decerr (
        .clk(clk), .resetn(resetn),
        .s_awvalid(d_awvalid),.s_awready(d_awready),.s_awaddr(s_awaddr),.s_awprot(s_awprot),
        .s_wvalid(d_wvalid),.s_wready(d_wready),.s_wdata(s_wdata),.s_wstrb(s_wstrb),
        .s_bvalid(d_bvalid),.s_bready(d_bready),.s_bresp(d_bresp),
        .s_arvalid(d_arvalid),.s_arready(d_arready),.s_araddr(s_araddr),.s_arprot(s_arprot),
        .s_rvalid(d_rvalid),.s_rready(d_rready),.s_rdata(d_rdata),.s_rresp(d_rresp)
    );
endmodule
`default_nettype wire
