// =============================================================================
// npu_tcm.v — Magpie_M3V NPU tightly-coupled memories (ADR-0044)
// -----------------------------------------------------------------------------
// npu_tcm  = DTCM, 32KB (Coral row-4 sizing): data/weights/tensor tiles.
//   Structural model: 8-way word-interleaved banks (bank = word_addr[2:0]),
//   budget 2R + 1W per bank per cycle. The 32B-aligned engine windows
//   (ADR-0040) land exactly one access per bank; a sim-only checker counts
//   every enabled read per bank per cycle and tallies budget violations —
//   e2e gates assert ZERO, gate_52 proves the checker can fire.
// npu_itcm = ITCM, 8KB: instruction fetch + host load window (0x3002_xxxx).
// Harvard contract: the SAME firmware image is loaded into both memories
// (all load-visible bytes — rodata/literals included — exist in DTCM at the
// same offsets, matching Spike's flat view); stores never alter the fetch
// stream (no self-modifying code — the random generator never emits it).
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
    localparam [1:0] OKAY = 2'b00, SLVERR = 2'b10;
    reg [31:0] mem [0:WORDS-1];
    assign dma_rdata     = mem[dma_raddr];
    assign core_d_rdata  = mem[core_d_addr];
    // ADR-0040: two 256-bit windows (8 consecutive words, index wraps in AW)
    genvar gw;
    generate
        for (gw = 0; gw < 8; gw = gw + 1) begin : g_eng_wide
            wire [AW-1:0] ia = eng_a_addr + gw[AW-1:0];
            wire [AW-1:0] ib = eng_b_addr + gw[AW-1:0];
            assign eng_a_rdata[gw*32 +: 32] = mem[ia];
            assign eng_b_rdata[gw*32 +: 32] = mem[ib];
        end
    endgenerate
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

    // ---- ADR-0044 bank port-budget checker (sim only) -----------------------
    // 8-way word interleave; every ENABLED read is charged to its bank; the
    // aligned engine windows charge one read per bank per strobe. Budget:
    // <= 2 reads per bank per cycle (2R1W banks). `bank_violations` is read
    // hierarchically by gates; e2e workloads must show 0.
    integer bank_violations;
    initial bank_violations = 0;
    /* verilator lint_off BLKSEQ */
    reg [3:0] rd_cnt;
    integer bk;
    always @(posedge clk) begin
        if (!resetn) bank_violations <= bank_violations;  // keep across soft events
        else begin
            for (bk = 0; bk < 8; bk = bk + 1) begin
                rd_cnt = 4'd0;
                if (eng_a_re)                                  rd_cnt = rd_cnt + 4'd1;
                if (eng_b_re)                                  rd_cnt = rd_cnt + 4'd1;
                if (dma_re    && (dma_raddr[2:0]    == bk[2:0])) rd_cnt = rd_cnt + 4'd1;
                if (core_d_re && (core_d_addr[2:0]  == bk[2:0])) rd_cnt = rd_cnt + 4'd1;
                if (s_axi_arvalid && s_axi_arready
                              && (s_axi_araddr[4:2] == bk[2:0])) rd_cnt = rd_cnt + 4'd1;
                if (rd_cnt > 4'd2) begin
                    bank_violations = bank_violations + 1;
                    $display("NPU_DTCM: bank %0d read budget exceeded (%0d) at %0t",
                             bk, rd_cnt, $time);
                end
            end
        end
    end
    /* verilator lint_on BLKSEQ */
endmodule

// =============================================================================
// npu_itcm — 8KB instruction TCM (ADR-0044): fetch port + host load window.
// =============================================================================
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
    localparam [1:0] OKAY = 2'b00, SLVERR = 2'b10;
    reg [31:0] mem [0:WORDS-1];
    assign core_i_rdata = mem[core_i_addr];

    function [31:0] merge; input [31:0] old; input [31:0] wd; input [3:0] strb; begin
        merge = { strb[3] ? wd[31:24] : old[31:24], strb[2] ? wd[23:16] : old[23:16],
                  strb[1] ? wd[15:8]  : old[15:8],  strb[0] ? wd[7:0]   : old[7:0] };
    end endfunction

    wire [13:0] aw_off = s_axi_awaddr[15:2];
    wire [13:0] ar_off = s_axi_araddr[15:2];
    reg aw_seen, w_seen, wa_ok;
    reg [AW-1:0] wa_q; reg [31:0] wd_q; reg [3:0] wstrb_q;
    wire host_we = aw_seen && w_seen && !s_axi_bvalid;
    assign s_axi_awready = !aw_seen && !s_axi_bvalid;
    assign s_axi_wready  = !w_seen  && !s_axi_bvalid;
    always @(posedge clk) begin
        if (!resetn) begin aw_seen<=0; w_seen<=0; s_axi_bvalid<=0; s_axi_bresp<=OKAY; end
        else begin
            if (s_axi_awvalid && s_axi_awready) begin
                aw_seen<=1; wa_q<=s_axi_awaddr[AW+1:2]; wa_ok <= ({18'd0, aw_off} < WORDS);
            end
            if (s_axi_wvalid && s_axi_wready) begin w_seen<=1; wd_q<=s_axi_wdata; wstrb_q<=s_axi_wstrb; end
            if (host_we) begin
                if (wa_ok) mem[wa_q] <= merge(mem[wa_q], wd_q, wstrb_q);
                s_axi_bvalid<=1; s_axi_bresp <= wa_ok ? OKAY : SLVERR;
                aw_seen<=0; w_seen<=0;
            end
            if (s_axi_bvalid && s_axi_bready) s_axi_bvalid<=0;
        end
    end
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
