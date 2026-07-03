// =============================================================================
// npu_tcm.v — Magpie_M3V NPU tightly-coupled memory (ITCM/DTCM window)
// -----------------------------------------------------------------------------
// AXI4-Lite slave so the host can load the NPU's program/data (0x3001_xxxx), plus
// a DMA write port so npu_dma streams weights/activations straight into it. The
// (future, Phase 2) NPU core reads this memory. Single-outstanding AXI4-Lite.
// DMA writes take priority over host writes (streaming must not stall); in
// practice the host loads before/after a transfer, so they do not collide.
// =============================================================================
`default_nettype none

module npu_tcm #(
    parameter integer WORDS = 1024,       // sim size; real ITCM 8KB + DTCM 32KB
    parameter integer AW    = 10          // word-address width (log2 WORDS)
) (
    input  wire        clk,
    input  wire        resetn,

    // ---- AXI4-Lite slave (host load/inspect) ----
    input  wire        s_axi_awvalid, output wire s_axi_awready, input wire [31:0] s_axi_awaddr, input wire [2:0] s_axi_awprot,
    input  wire        s_axi_wvalid,  output wire s_axi_wready,  input wire [31:0] s_axi_wdata,  input wire [3:0] s_axi_wstrb,
    output reg         s_axi_bvalid,  input  wire s_axi_bready,  output wire [1:0] s_axi_bresp,
    input  wire        s_axi_arvalid, output wire s_axi_arready, input wire [31:0] s_axi_araddr, input wire [2:0] s_axi_arprot,
    output reg         s_axi_rvalid,  input  wire s_axi_rready,  output reg [31:0] s_axi_rdata, output wire [1:0] s_axi_rresp,

    // ---- DMA write port (from npu_dma) ----
    input  wire        dma_we,
    input  wire [AW-1:0] dma_waddr,
    input  wire [31:0] dma_wdata
);
    assign s_axi_bresp = 2'b00;
    assign s_axi_rresp = 2'b00;
    reg [31:0] mem [0:WORDS-1];

    // ---- host write channel (single-outstanding) ----
    reg aw_seen, w_seen;
    reg [AW-1:0] wa_q; reg [31:0] wd_q;
    wire host_we = aw_seen && w_seen && !s_axi_bvalid;
    assign s_axi_awready = !aw_seen && !s_axi_bvalid;
    assign s_axi_wready  = !w_seen  && !s_axi_bvalid;
    always @(posedge clk) begin
        if (!resetn) begin aw_seen<=0; w_seen<=0; s_axi_bvalid<=0; end
        else begin
            if (s_axi_awvalid && s_axi_awready) begin aw_seen<=1; wa_q<=s_axi_awaddr[AW+1:2]; end
            if (s_axi_wvalid  && s_axi_wready ) begin w_seen<=1;  wd_q<=s_axi_wdata; end
            if (host_we) begin s_axi_bvalid<=1; aw_seen<=0; w_seen<=0; end
            if (s_axi_bvalid && s_axi_bready) s_axi_bvalid<=0;
        end
    end

    // ---- single memory-write block: DMA priority over host ----
    always @(posedge clk) begin
        if (dma_we)        mem[dma_waddr] <= dma_wdata;
        else if (host_we)  mem[wa_q]      <= wd_q;
    end

    // ---- host read channel (single-outstanding) ----
    always @(posedge clk) begin
        if (!resetn) s_axi_rvalid<=0;
        else begin
            if (s_axi_arvalid && s_axi_arready) begin s_axi_rvalid<=1; s_axi_rdata<=mem[s_axi_araddr[AW+1:2]]; end
            else if (s_axi_rvalid && s_axi_rready) s_axi_rvalid<=0;
        end
    end
    assign s_axi_arready = !s_axi_rvalid;
endmodule
`default_nettype wire
