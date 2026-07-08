// =============================================================================
// axi_full_arbiter_2x1.v — two AXI4-full masters to one slave, non-preemptive
// -----------------------------------------------------------------------------
// Master 0 is the host Lite-to-full bridge, master 1 is the NPU DMA. A read or
// write transaction holds its grant until RLAST or BVALID&BREADY.
// =============================================================================
`default_nettype none

module axi_full_arbiter_2x1 #(
    parameter integer DMA_DATA_W = 32
) (
    input  wire clk,
    input  wire resetn,

    input  wire        m0_arvalid, output wire m0_arready, input wire [31:0] m0_araddr,
    input  wire [7:0]  m0_arlen,   input wire [2:0]  m0_arsize, input wire [1:0] m0_arburst,
    output wire        m0_rvalid,  input  wire m0_rready,  output wire [DMA_DATA_W-1:0] m0_rdata,
    output wire        m0_rlast,   output wire [1:0] m0_rresp,
    input  wire        m0_awvalid, output wire m0_awready, input wire [31:0] m0_awaddr,
    input  wire [7:0]  m0_awlen,   input wire [2:0]  m0_awsize, input wire [1:0] m0_awburst,
    input  wire        m0_wvalid,  output wire m0_wready,  input wire [DMA_DATA_W-1:0] m0_wdata,
    input  wire [DMA_DATA_W/8-1:0] m0_wstrb, input wire m0_wlast,
    output wire        m0_bvalid,  input  wire m0_bready,  output wire [1:0] m0_bresp,

    input  wire        m1_arvalid, output wire m1_arready, input wire [31:0] m1_araddr,
    input  wire [7:0]  m1_arlen,   input wire [2:0]  m1_arsize, input wire [1:0] m1_arburst,
    output wire        m1_rvalid,  input  wire m1_rready,  output wire [DMA_DATA_W-1:0] m1_rdata,
    output wire        m1_rlast,   output wire [1:0] m1_rresp,
    input  wire        m1_awvalid, output wire m1_awready, input wire [31:0] m1_awaddr,
    input  wire [7:0]  m1_awlen,   input wire [2:0]  m1_awsize, input wire [1:0] m1_awburst,
    input  wire        m1_wvalid,  output wire m1_wready,  input wire [DMA_DATA_W-1:0] m1_wdata,
    input  wire [DMA_DATA_W/8-1:0] m1_wstrb, input wire m1_wlast,
    output wire        m1_bvalid,  input  wire m1_bready,  output wire [1:0] m1_bresp,

    output wire        s_arvalid, input  wire s_arready, output wire [31:0] s_araddr,
    output wire [7:0]  s_arlen,   output wire [2:0] s_arsize, output wire [1:0] s_arburst,
    input  wire        s_rvalid,  output wire s_rready, input wire [DMA_DATA_W-1:0] s_rdata,
    input  wire        s_rlast,   input wire [1:0] s_rresp,
    output wire        s_awvalid, input  wire s_awready, output wire [31:0] s_awaddr,
    output wire [7:0]  s_awlen,   output wire [2:0] s_awsize, output wire [1:0] s_awburst,
    output wire        s_wvalid,  input  wire s_wready, output wire [DMA_DATA_W-1:0] s_wdata,
    output wire [DMA_DATA_W/8-1:0] s_wstrb, output wire s_wlast,
    input  wire        s_bvalid,  output wire s_bready, input wire [1:0] s_bresp
);
    initial begin
        if (DMA_DATA_W != 32 && DMA_DATA_W != 64 && DMA_DATA_W != 128 && DMA_DATA_W != 256)
            $fatal(1, "axi_full_arbiter_2x1: DMA_DATA_W must be one of 32/64/128/256");
    end

    localparam R_IDLE = 2'd0, R_M0 = 2'd1, R_M1 = 2'd2;
    localparam W_IDLE = 2'd0, W_M0 = 2'd1, W_M1 = 2'd2;
    reg [1:0] rgrant, wgrant;

    always @(posedge clk) begin
        if (!resetn) rgrant <= R_IDLE;
        else begin
            case (rgrant)
                R_IDLE: begin
                    if (m1_arvalid)      rgrant <= R_M1; // NPU priority
                    else if (m0_arvalid) rgrant <= R_M0;
                end
                R_M0: if (s_rvalid && m0_rready && s_rlast) rgrant <= R_IDLE;
                R_M1: if (s_rvalid && m1_rready && s_rlast) rgrant <= R_IDLE;
                default: rgrant <= R_IDLE;
            endcase
        end
    end

    always @(posedge clk) begin
        if (!resetn) wgrant <= W_IDLE;
        else begin
            case (wgrant)
                W_IDLE: begin
                    if (m1_awvalid)      wgrant <= W_M1; // NPU priority
                    else if (m0_awvalid) wgrant <= W_M0;
                end
                W_M0: if (s_bvalid && m0_bready) wgrant <= W_IDLE;
                W_M1: if (s_bvalid && m1_bready) wgrant <= W_IDLE;
                default: wgrant <= W_IDLE;
            endcase
        end
    end

    wire rsel0 = (rgrant == R_M0) || (rgrant == R_IDLE && !m1_arvalid);
    wire rsel1 = (rgrant == R_M1) || (rgrant == R_IDLE &&  m1_arvalid);
    assign s_arvalid = rsel1 ? m1_arvalid : m0_arvalid;
    assign s_araddr  = rsel1 ? m1_araddr  : m0_araddr;
    assign s_arlen   = rsel1 ? m1_arlen   : m0_arlen;
    assign s_arsize  = rsel1 ? m1_arsize  : m0_arsize;
    assign s_arburst = rsel1 ? m1_arburst : m0_arburst;
    assign m0_arready = rsel0 ? s_arready : 1'b0;
    assign m1_arready = rsel1 ? s_arready : 1'b0;
    assign s_rready = (rgrant == R_M1) ? m1_rready : m0_rready;
    assign m0_rvalid = (rgrant == R_M0) ? s_rvalid : 1'b0;
    assign m1_rvalid = (rgrant == R_M1) ? s_rvalid : 1'b0;
    assign m0_rdata = s_rdata;
    assign m1_rdata = s_rdata;
    assign m0_rlast = s_rlast;
    assign m1_rlast = s_rlast;
    assign m0_rresp = s_rresp;
    assign m1_rresp = s_rresp;

    wire wsel0 = (wgrant == W_M0) || (wgrant == W_IDLE && !m1_awvalid);
    wire wsel1 = (wgrant == W_M1) || (wgrant == W_IDLE &&  m1_awvalid);
    assign s_awvalid = wsel1 ? m1_awvalid : m0_awvalid;
    assign s_awaddr  = wsel1 ? m1_awaddr  : m0_awaddr;
    assign s_awlen   = wsel1 ? m1_awlen   : m0_awlen;
    assign s_awsize  = wsel1 ? m1_awsize  : m0_awsize;
    assign s_awburst = wsel1 ? m1_awburst : m0_awburst;
    assign m0_awready = wsel0 ? s_awready : 1'b0;
    assign m1_awready = wsel1 ? s_awready : 1'b0;
    assign s_wvalid = (wgrant == W_M1) ? m1_wvalid : m0_wvalid;
    assign s_wdata  = (wgrant == W_M1) ? m1_wdata  : m0_wdata;
    assign s_wstrb  = (wgrant == W_M1) ? m1_wstrb  : m0_wstrb;
    assign s_wlast  = (wgrant == W_M1) ? m1_wlast  : m0_wlast;
    assign m0_wready = (wgrant == W_M0) ? s_wready : 1'b0;
    assign m1_wready = (wgrant == W_M1) ? s_wready : 1'b0;
    assign s_bready = (wgrant == W_M1) ? m1_bready : m0_bready;
    assign m0_bvalid = (wgrant == W_M0) ? s_bvalid : 1'b0;
    assign m1_bvalid = (wgrant == W_M1) ? s_bvalid : 1'b0;
    assign m0_bresp = s_bresp;
    assign m1_bresp = s_bresp;
endmodule
`default_nettype wire
