// =============================================================================
// npu_tcm.v — Magpie_M3V NPU tightly-coupled memory (ITCM/DTCM window)
// -----------------------------------------------------------------------------
// AXI4-Lite slave so the host can load the NPU's program/data (0x3001_xxxx), plus
// a DMA write port so npu_dma streams weights/activations straight into it. A
// DMA read port lets npu_dma write results back out to shared memory. The
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
    output reg         s_axi_bvalid,  input  wire s_axi_bready,  output reg  [1:0] s_axi_bresp,
    input  wire        s_axi_arvalid, output wire s_axi_arready, input wire [31:0] s_axi_araddr, input wire [2:0] s_axi_arprot,
    output reg         s_axi_rvalid,  input  wire s_axi_rready,  output reg [31:0] s_axi_rdata, output reg [1:0] s_axi_rresp,

    // ---- DMA write port (from npu_dma read-mode ingress) ----
    input  wire        dma_we,
    input  wire [AW-1:0] dma_waddr,
    input  wire [31:0] dma_wdata,

    // ---- DMA read port (to npu_dma writeback-mode egress) ----
    input  wire        dma_re,
    input  wire [AW-1:0] dma_raddr,
    output wire [31:0] dma_rdata,

    // ---- NPU core instruction fetch port (read-only, combinational) ----
    input  wire            core_i_en,
    input  wire [AW-1:0]   core_i_addr,
    output wire [31:0]     core_i_rdata,

    // ---- matrix engine ports (ADR-0037): combinational read + granted write ----
    input  wire            eng_re,
    input  wire [AW-1:0]   eng_raddr,
    output wire [31:0]     eng_rdata,
    input  wire            eng_we,
    input  wire [AW-1:0]   eng_waddr,
    input  wire [31:0]     eng_wdata,

    // ---- NPU core data port ----
    input  wire [AW-1:0]   core_d_addr,
    output wire [31:0]     core_d_rdata,
    input  wire            core_d_we,
    input  wire [31:0]     core_d_wdata,
    input  wire [ 3:0]     core_d_wstrb,
    output wire            core_d_wgrant
);
    localparam [1:0] OKAY = 2'b00, SLVERR = 2'b10;
    reg [31:0] mem [0:WORDS-1];
    assign dma_rdata     = mem[dma_raddr];
    assign core_i_rdata  = mem[core_i_addr];
    assign core_d_rdata  = mem[core_d_addr];
    assign eng_rdata     = mem[eng_raddr];
    // write priority (ADR-0037): dma > engine > core > host
    assign core_d_wgrant = core_d_we & ~dma_we & ~eng_we;

    // byte-strobe merge
    function [31:0] merge; input [31:0] old; input [31:0] wd; input [3:0] strb; begin
        merge = { strb[3] ? wd[31:24] : old[31:24], strb[2] ? wd[23:16] : old[23:16],
                  strb[1] ? wd[15:8]  : old[15:8],  strb[0] ? wd[7:0]   : old[7:0] };
    end endfunction

    // in-window word offset (0x3001_xxxx); out-of-range -> SLVERR, never wraps
    wire [13:0] aw_off = s_axi_awaddr[15:2];
    wire [13:0] ar_off = s_axi_araddr[15:2];

    // ---- host write channel (single-outstanding) ----
    reg aw_seen, w_seen, wa_ok;
    reg [AW-1:0] wa_q; reg [31:0] wd_q; reg [3:0] wstrb_q;
    wire host_we        = aw_seen && w_seen && !s_axi_bvalid;
    wire host_mem_grant = host_we && wa_ok && !dma_we && !eng_we && !core_d_we;
    wire host_resp_fire = host_we && (!wa_ok || host_mem_grant);
    assign s_axi_awready = !aw_seen && !s_axi_bvalid;
    assign s_axi_wready  = !w_seen  && !s_axi_bvalid;
    always @(posedge clk) begin
        if (!resetn) begin aw_seen<=0; w_seen<=0; s_axi_bvalid<=0; s_axi_bresp<=OKAY; end
        else begin
            if (s_axi_awvalid && s_axi_awready) begin
                aw_seen<=1; wa_q<=s_axi_awaddr[AW+1:2]; wa_ok <= ({18'd0, aw_off} < WORDS);
            end
            if (s_axi_wvalid && s_axi_wready) begin w_seen<=1; wd_q<=s_axi_wdata; wstrb_q<=s_axi_wstrb; end
            if (host_resp_fire) begin
                s_axi_bvalid<=1; s_axi_bresp <= wa_ok ? OKAY : SLVERR;
                aw_seen<=0; w_seen<=0;
            end
            if (s_axi_bvalid && s_axi_bready) s_axi_bvalid<=0;
        end
    end

    // ---- single memory-write block: dma > core data > host ----
    always @(posedge clk) begin
        if (dma_we)                    mem[dma_waddr]   <= dma_wdata;
        else if (eng_we)               mem[eng_waddr]   <= eng_wdata;
        else if (core_d_we)            mem[core_d_addr] <= merge(mem[core_d_addr], core_d_wdata, core_d_wstrb);
        else if (host_we && wa_ok)     mem[wa_q]        <= merge(mem[wa_q], wd_q, wstrb_q);
    end

    // ---- host read channel (single-outstanding) ----
    always @(posedge clk) begin
        if (!resetn) begin s_axi_rvalid<=0; s_axi_rresp<=OKAY; end
        else begin
            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rvalid<=1;
                s_axi_rdata <= ({18'd0, ar_off} < WORDS) ? mem[s_axi_araddr[AW+1:2]] : 32'b0;
                s_axi_rresp <= ({18'd0, ar_off} < WORDS) ? OKAY : SLVERR;
            end else if (s_axi_rvalid && s_axi_rready) s_axi_rvalid<=0;
        end
    end
    assign s_axi_arready = !s_axi_rvalid;
endmodule
`default_nettype wire
