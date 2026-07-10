// =============================================================================
// npu_strip_buf.v -- v2 weight strip ping-pong buffer (ADR-0073)
// -----------------------------------------------------------------------------
// Two 40KB banks.  DMA writes full AXI beats into a selected bank using
// strip-local byte addresses; the matrix side sees the same combinational
// 256-bit weight-read window shape as npu_tcm.eng_b_*.
// =============================================================================
`default_nettype none

module npu_strip_buf #(
    parameter integer DMA_DATA_W  = 128,
    parameter integer STRIP_BYTES = 40960,
    parameter integer STRIP_AW    = 14
) (
    input  wire                    clk,
    input  wire                    resetn,
    input  wire                    clear,

    // ---- DMA write port: full-beat writes, strip-local byte address ----
    input  wire                    dma_we,
    input  wire                    dma_bank,
    input  wire [15:0]             dma_waddr,
    input  wire [DMA_DATA_W-1:0]   dma_wdata,
    input  wire                    fill_done,

    // ---- matrix engine weight-read port: mirrors npu_tcm eng_b_* ----
    input  wire                    eng_b_re,
    input  wire                    eng_b_bank,
    input  wire [STRIP_AW-1:0]     eng_b_addr,
    output wire [255:0]            eng_b_rdata,

    output reg  [1:0]              bank_valid
);
    localparam integer WPB          = DMA_DATA_W / 32;
    localparam integer STRIP_WORDS  = STRIP_BYTES / 4;
    localparam [31:0] AXI_BYTES_W   = DMA_DATA_W / 8;
    localparam [31:0] STRIP_BYTES_W = STRIP_BYTES;

    reg [31:0] bank0_mem [0:STRIP_WORDS-1];
    reg [31:0] bank1_mem [0:STRIP_WORDS-1];

    wire [STRIP_AW-1:0] dma_word_base;
    wire [31:0] dma_waddr_w;

    assign dma_word_base = dma_waddr[STRIP_AW+1:2];
    assign dma_waddr_w = {16'b0, dma_waddr};

    initial begin
        if (DMA_DATA_W != 32 && DMA_DATA_W != 64 &&
            DMA_DATA_W != 128 && DMA_DATA_W != 256)
            $fatal(1, "npu_strip_buf: DMA_DATA_W must be one of 32/64/128/256");
        if (STRIP_BYTES != 40960)
            $fatal(1, "npu_strip_buf: STRIP_BYTES must be 40960");
        if ((STRIP_BYTES % 4) != 0)
            $fatal(1, "npu_strip_buf: STRIP_BYTES must be word aligned");
        if (STRIP_AW < 14)
            $fatal(1, "npu_strip_buf: STRIP_AW must cover 40KB");
    end

    genvar gw;
    generate
        for (gw = 0; gw < 8; gw = gw + 1) begin : g_eng_b_wide
            wire [STRIP_AW-1:0] ib;
            assign ib = eng_b_addr + gw[STRIP_AW-1:0];
            assign eng_b_rdata[gw*32 +: 32] =
                eng_b_bank ? bank1_mem[ib] : bank0_mem[ib];
        end
    endgenerate

    integer dma_i;
    always @(posedge clk) begin
        if (!resetn) begin
            bank_valid <= 2'b00;
        end else begin
            if (clear)
                bank_valid <= 2'b00;
            else if (fill_done)
                bank_valid[dma_bank] <= 1'b1;

            if (dma_we) begin
                if ((dma_waddr_w % AXI_BYTES_W) != 0)
                    $fatal(1, "npu_strip_buf: unaligned DMA write addr=%0d", dma_waddr);
                if ((dma_waddr_w + AXI_BYTES_W) > STRIP_BYTES_W)
                    $fatal(1, "npu_strip_buf: DMA write out of strip addr=%0d", dma_waddr);
                for (dma_i = 0; dma_i < WPB; dma_i = dma_i + 1) begin
                    if (dma_bank)
                        bank1_mem[dma_word_base + dma_i[STRIP_AW-1:0]] <= dma_wdata[dma_i*32 +: 32];
                    else
                        bank0_mem[dma_word_base + dma_i[STRIP_AW-1:0]] <= dma_wdata[dma_i*32 +: 32];
                end
            end

            if (dma_we && eng_b_re && (dma_bank == eng_b_bank))
                $fatal(1, "npu_strip_buf: DMA write/read bank collision bank=%0d", dma_bank);
        end
    end
endmodule

`default_nettype wire
