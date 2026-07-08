// =============================================================================
// axil_to_full.v — AXI4-Lite slave to single-beat AXI4-full master
// =============================================================================
`default_nettype none

module axil_to_full #(
    parameter integer DMA_DATA_W = 32
) (
    input  wire        clk,
    input  wire        resetn,

    input  wire        s_awvalid,
    output wire        s_awready,
    input  wire [31:0] s_awaddr,
    input  wire [ 2:0] s_awprot,
    input  wire        s_wvalid,
    output wire        s_wready,
    input  wire [31:0] s_wdata,
    input  wire [ 3:0] s_wstrb,
    output wire        s_bvalid,
    input  wire        s_bready,
    output wire [ 1:0] s_bresp,
    input  wire        s_arvalid,
    output wire        s_arready,
    input  wire [31:0] s_araddr,
    input  wire [ 2:0] s_arprot,
    output wire        s_rvalid,
    input  wire        s_rready,
    output wire [31:0] s_rdata,
    output wire [ 1:0] s_rresp,

    output wire        m_arvalid,
    input  wire        m_arready,
    output wire [31:0] m_araddr,
    output wire [ 7:0] m_arlen,
    output wire [ 2:0] m_arsize,
    output wire [ 1:0] m_arburst,
    input  wire        m_rvalid,
    output wire        m_rready,
    input  wire [DMA_DATA_W-1:0] m_rdata,
    input  wire        m_rlast,
    input  wire [ 1:0] m_rresp,

    output wire        m_awvalid,
    input  wire        m_awready,
    output wire [31:0] m_awaddr,
    output wire [ 7:0] m_awlen,
    output wire [ 2:0] m_awsize,
    output wire [ 1:0] m_awburst,
    output wire        m_wvalid,
    input  wire        m_wready,
    output wire [DMA_DATA_W-1:0] m_wdata,
    output wire [DMA_DATA_W/8-1:0] m_wstrb,
    output wire        m_wlast,
    input  wire        m_bvalid,
    output wire        m_bready,
    input  wire [ 1:0] m_bresp
);
    localparam integer WPB = DMA_DATA_W / 32;
    initial begin
        if (DMA_DATA_W != 32 && DMA_DATA_W != 64 && DMA_DATA_W != 128 && DMA_DATA_W != 256)
            $fatal(1, "axil_to_full: DMA_DATA_W must be one of 32/64/128/256");
    end

    wire [31:0] ar_lane_w = ({2'b0, s_araddr[31:2]} % WPB);
    wire [31:0] aw_lane_w = ({2'b0, s_awaddr[31:2]} % WPB);
    wire [2:0] ar_lane = ar_lane_w[2:0];
    wire [2:0] aw_lane = aw_lane_w[2:0];
    reg [DMA_DATA_W-1:0] wdata_wide;
    reg [DMA_DATA_W/8-1:0] wstrb_wide;
    always @* begin
        wdata_wide = {DMA_DATA_W{1'b0}};
        wstrb_wide = {(DMA_DATA_W/8){1'b0}};
        wdata_wide[aw_lane*32 +: 32] = s_wdata;
        wstrb_wide[aw_lane*4  +: 4]  = s_wstrb;
    end

    assign m_arvalid = s_arvalid;
    assign s_arready = m_arready;
    assign m_araddr  = s_araddr;
    assign m_arlen   = 8'd0;
    assign m_arsize  = 3'd2;
    assign m_arburst = 2'b01;
    assign s_rvalid  = m_rvalid;
    assign m_rready  = s_rready;
    assign s_rdata   = m_rdata[ar_lane*32 +: 32];
    assign s_rresp   = m_rresp;

    assign m_awvalid = s_awvalid;
    assign s_awready = m_awready;
    assign m_awaddr  = s_awaddr;
    assign m_awlen   = 8'd0;
    assign m_awsize  = 3'd2;
    assign m_awburst = 2'b01;
    assign m_wvalid  = s_wvalid;
    assign s_wready  = m_wready;
    assign m_wdata   = wdata_wide;
    assign m_wstrb   = wstrb_wide;
    assign m_wlast   = 1'b1;
    assign s_bvalid  = m_bvalid;
    assign m_bready  = s_bready;
    assign s_bresp   = m_bresp;

    wire unused = |{clk, resetn, s_awprot, s_arprot, m_rlast};
endmodule
`default_nettype wire
