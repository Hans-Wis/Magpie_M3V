// Auto-generated black-box stubs for DC full-npu_top synth (TCM = SRAM macro).
// Ports only, empty body -> DC treats as black box (mem not synthesized as flops).
`default_nettype none

module npu_tcm #(
    parameter integer WORDS = 1024,       // sim size; real ITCM 8KB + DTCM 32KB
    parameter integer AW    = 10,         // word-address width (log2 WORDS)
    parameter integer DMA_DATA_W = 32
) (
    input  wire        clk,
    input  wire        resetn,

    // ---- AXI4-Lite slave (host load/inspect) ----
    input  wire        s_axi_awvalid, output wire s_axi_awready, input wire [31:0] s_axi_awaddr, input wire [2:0] s_axi_awprot,
    input  wire        s_axi_wvalid,  output wire s_axi_wready,  input wire [31:0] s_axi_wdata,  input wire [3:0] s_axi_wstrb,
    output reg         s_axi_bvalid,  input  wire s_axi_bready,  output reg  [1:0] s_axi_bresp,
    input  wire        s_axi_arvalid, output wire s_axi_arready, input wire [31:0] s_axi_araddr, input wire [2:0] s_axi_arprot,
    output reg         s_axi_rvalid,  input  wire s_axi_rready,  output reg [31:0] s_axi_rdata, output reg [1:0] s_axi_rresp,

    // ---- DMA write port (from npu_dma read-mode ingress) ----
    input  wire        dma_narrow,
    input  wire        dma_we,
    input  wire [AW-1:0] dma_waddr,
    input  wire [DMA_DATA_W-1:0] dma_wdata,

    // ---- DMA read port (to npu_dma writeback-mode egress) ----
    input  wire        dma_re,
    input  wire [AW-1:0] dma_raddr,
    output wire [DMA_DATA_W-1:0] dma_rdata,

    // ---- matrix engine ports (ADR-0037): combinational read + granted write ----
    input  wire            eng_a_re,     // ADR-0044: window-consume strobes
    input  wire            eng_b_re,
    input  wire [AW-1:0]   eng_a_addr,
    output wire [255:0]    eng_a_rdata,
    input  wire [AW-1:0]   eng_b_addr,
    output wire [255:0]    eng_b_rdata,
    input  wire            eng_we,
    input  wire [AW-1:0]   eng_waddr,
    input  wire [31:0]     eng_wdata,

    // ---- NPU core data port ----
    input  wire            core_d_re,    // ADR-0044: read strobe for the checker
    input  wire [AW-1:0]   core_d_addr,
    output wire [31:0]     core_d_rdata,
    input  wire            core_d_we,
    input  wire [31:0]     core_d_wdata,
    input  wire [ 3:0]     core_d_wstrb,
    output wire            core_d_wgrant
);
endmodule

module npu_itcm #(
    parameter integer WORDS = 2048,
    parameter integer AW    = 11
) (
    input  wire        clk,
    input  wire        resetn,

    input  wire        s_axi_awvalid, output wire s_axi_awready, input wire [31:0] s_axi_awaddr, input wire [2:0] s_axi_awprot,
    input  wire        s_axi_wvalid,  output wire s_axi_wready,  input wire [31:0] s_axi_wdata,  input wire [3:0] s_axi_wstrb,
    output reg         s_axi_bvalid,  input  wire s_axi_bready,  output reg  [1:0] s_axi_bresp,
    input  wire        s_axi_arvalid, output wire s_axi_arready, input wire [31:0] s_axi_araddr, input wire [2:0] s_axi_arprot,
    output reg         s_axi_rvalid,  input  wire s_axi_rready,  output reg [31:0] s_axi_rdata, output reg [1:0] s_axi_rresp,

    input  wire            core_i_en,
    input  wire [AW-1:0]   core_i_addr,
    output wire [31:0]     core_i_rdata
);
endmodule
`default_nettype wire
