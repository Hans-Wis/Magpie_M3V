// =============================================================================
// npu_top.v — Magpie_M3V NPU IP subsystem (Phase 1 sealed integration)
// -----------------------------------------------------------------------------
// One AXI4-Lite slave faces the host fabric (NPU window 0x3xxx). Internally it
// decodes on addr[16]:  0x3000_xxxx -> CSR (npu_axil_regs), 0x3001_xxxx -> TCM.
// The DMA (AXI4-full master to shared memory) is programmed via the CSR and
// streams into the TCM. A level IRQ is raised to the host on completion.
// Phase 2 drops the cpu_m1-derived NPU core in beside the TCM/CSR — this wrapper
// is the stable socket for it. Single-outstanding throughout (matches the host).
// =============================================================================
`default_nettype none

module npu_top #(
    parameter integer TCM_WORDS = 1024,
    parameter integer TCM_AW    = 10
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

    // ---- to host / future core ----
    output wire        irq,
    output wire        npu_start,
    output wire [31:0] npu_config
);
    // ================= internal 1->2 AXI4-Lite decode (CSR vs TCM) =================
    // sel 0 = CSR (addr[16]==0), sel 1 = TCM (addr[16]==1). Single-outstanding.
    // route: 0=CSR (0x3000_xxxx), 1=TCM (0x3001_xxxx), 2=DECERR (any other NPU-window addr).
    // Guards decode aliasing: an out-of-window address gets SLVERR, not a real register.
    reg  w_busy, r_busy; reg [1:0] w_route_l, r_route_l;
    function [1:0] dec; input [31:0] a; begin
        if (a[27:17] != 11'b0)  dec = 2'd2;   // outside 0x3000/0x3001 -> DECERR
        else if (a[16] == 1'b0) dec = 2'd0;   // 0x3000_xxxx -> CSR
        else                    dec = 2'd1;   // 0x3001_xxxx -> TCM
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

    // per-target port wires: c_=CSR, t_=TCM, d_=DECERR
    wire c_awready,c_wready,c_bvalid,c_arready,c_rvalid; wire [31:0] c_rdata; wire [1:0] c_bresp,c_rresp;
    wire t_awready,t_wready,t_bvalid,t_arready,t_rvalid; wire [31:0] t_rdata; wire [1:0] t_bresp,t_rresp;
    wire d_awready,d_wready,d_bvalid,d_arready,d_rvalid; wire [31:0] d_rdata; wire [1:0] d_bresp,d_rresp;

    wire c_awvalid = s_awvalid & (w_route==2'd0);
    wire t_awvalid = s_awvalid & (w_route==2'd1);
    wire d_awvalid = s_awvalid & (w_route==2'd2);
    wire c_wvalid  = s_wvalid & w_known & (w_route==2'd0);
    wire t_wvalid  = s_wvalid & w_known & (w_route==2'd1);
    wire d_wvalid  = s_wvalid & w_known & (w_route==2'd2);
    wire c_bready  = s_bready & (w_route==2'd0);
    wire t_bready  = s_bready & (w_route==2'd1);
    wire d_bready  = s_bready & (w_route==2'd2);
    wire c_arvalid = s_arvalid & (r_route==2'd0);
    wire t_arvalid = s_arvalid & (r_route==2'd1);
    wire d_arvalid = s_arvalid & (r_route==2'd2);
    wire c_rready  = s_rready & (r_route==2'd0);
    wire t_rready  = s_rready & (r_route==2'd1);
    wire d_rready  = s_rready & (r_route==2'd2);

    assign s_awready = (w_route==2'd0)?c_awready : (w_route==2'd1)?t_awready : d_awready;
    assign s_wready  = w_known ? ((w_route==2'd0)?c_wready : (w_route==2'd1)?t_wready : d_wready) : 1'b0;
    assign s_bvalid  = (w_route==2'd0)?c_bvalid : (w_route==2'd1)?t_bvalid : d_bvalid;
    assign s_bresp   = (w_route==2'd0)?c_bresp  : (w_route==2'd1)?t_bresp  : d_bresp;
    assign s_arready = (r_route==2'd0)?c_arready : (r_route==2'd1)?t_arready : d_arready;
    assign s_rvalid  = (r_route==2'd0)?c_rvalid : (r_route==2'd1)?t_rvalid : d_rvalid;
    assign s_rdata   = (r_route==2'd0)?c_rdata  : (r_route==2'd1)?t_rdata  : d_rdata;
    assign s_rresp   = (r_route==2'd0)?c_rresp  : (r_route==2'd1)?t_rresp  : d_rresp;

    // ================= CSR block =================
    wire [31:0] dma_src, dma_dst; wire [16:0] dma_len; wire dma_go, dma_busy, dma_done, dma_err;
    npu_axil_regs csr (
        .clk(clk), .resetn(resetn),
        .s_axi_awvalid(c_awvalid),.s_axi_awready(c_awready),.s_axi_awaddr(s_awaddr),.s_axi_awprot(s_awprot),
        .s_axi_wvalid(c_wvalid),.s_axi_wready(c_wready),.s_axi_wdata(s_wdata),.s_axi_wstrb(s_wstrb),
        .s_axi_bvalid(c_bvalid),.s_axi_bready(c_bready),.s_axi_bresp(c_bresp),
        .s_axi_arvalid(c_arvalid),.s_axi_arready(c_arready),.s_axi_araddr(s_araddr),.s_axi_arprot(s_arprot),
        .s_axi_rvalid(c_rvalid),.s_axi_rready(c_rready),.s_axi_rdata(c_rdata),.s_axi_rresp(c_rresp),
        .npu_start(npu_start),.npu_config(npu_config),.npu_busy(1'b0),.npu_done(1'b0),
        .dma_src(dma_src),.dma_dst(dma_dst),.dma_len(dma_len),.dma_go(dma_go),
        .dma_busy(dma_busy),.dma_done(dma_done),.dma_err(dma_err),.irq(irq)
    );

    // ================= DMA (AXI4-full master) -> TCM =================
    wire dma_we; wire [TCM_AW-1:0] dma_waddr; wire [31:0] dma_wdata;
    wire [11:0] dma_buf_addr;
    assign dma_waddr = dma_buf_addr[TCM_AW-1:0];
    npu_dma #(.BUF_AW(12)) dma (
        .clk(clk), .resetn(resetn),
        .go(dma_go), .src_addr(dma_src), .dst_word(dma_dst[11:0]), .len_beats(dma_len),
        .busy(dma_busy), .done(dma_done),
        .m_arvalid(m_arvalid),.m_arready(m_arready),.m_araddr(m_araddr),.m_arlen(m_arlen),
        .m_arsize(m_arsize),.m_arburst(m_arburst),
        .m_rvalid(m_rvalid),.m_rready(m_rready),.m_rdata(m_rdata),.m_rlast(m_rlast),.m_rresp(m_rresp),
        .buf_we(dma_we),.buf_addr(dma_buf_addr),.buf_wdata(dma_wdata),.err(dma_err)
    );

    // ================= TCM =================
    npu_tcm #(.WORDS(TCM_WORDS), .AW(TCM_AW)) tcm (
        .clk(clk), .resetn(resetn),
        .s_axi_awvalid(t_awvalid),.s_axi_awready(t_awready),.s_axi_awaddr(s_awaddr),.s_axi_awprot(s_awprot),
        .s_axi_wvalid(t_wvalid),.s_axi_wready(t_wready),.s_axi_wdata(s_wdata),.s_axi_wstrb(s_wstrb),
        .s_axi_bvalid(t_bvalid),.s_axi_bready(t_bready),.s_axi_bresp(t_bresp),
        .s_axi_arvalid(t_arvalid),.s_axi_arready(t_arready),.s_axi_araddr(s_araddr),.s_axi_arprot(s_arprot),
        .s_axi_rvalid(t_rvalid),.s_axi_rready(t_rready),.s_axi_rdata(t_rdata),.s_axi_rresp(t_rresp),
        .dma_we(dma_we),.dma_waddr(dma_waddr),.dma_wdata(dma_wdata)
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
