// =============================================================================
// npu_dma.v — Magpie_M3V NPU weight/activation DMA (AXI4-full read master)
// -----------------------------------------------------------------------------
// Streams a contiguous block from shared memory (AXI4-full, INCR read bursts)
// into the NPU local buffer/TCM. Programmed by the host over AXI4-Lite via
// npu_axil_regs (src/dst/len + go); raises dma_done when the block has landed.
// This is the bandwidth path (ADR-0031 §3): batch-1 GEMV is weight-bandwidth
// bound, so bursts (not single beats) are the point.
//
// AXI-legal bursts: each burst <= 256 beats AND never crosses a 4 KB boundary.
// Longer transfers are chunked into multiple bursts. 32-bit data (ARSIZE=4B).
// Single-outstanding read (one burst in flight) — simple, correct, matches the
// single-outstanding fabric; multi-outstanding is a later throughput tuning.
// =============================================================================
`default_nettype none

module npu_dma #(
    parameter integer BUF_AW = 12          // local buffer address width (words)
) (
    input  wire        clk,
    input  wire        resetn,

    // ---- descriptor / control (from npu_axil_regs) ----
    input  wire        go,                 // 1-cycle pulse: start transfer
    input  wire [31:0] src_addr,           // shared-mem byte address (word-aligned)
    input  wire [BUF_AW-1:0] dst_word,     // local buffer start (word index)
    input  wire [16:0] len_beats,          // number of 32-bit words to move (0..65536; 0 = no-op)
    output reg         busy,
    output reg         done,               // sticky until next go
    output reg         err,                // sticky: any read beat returned SLVERR/DECERR

    // ---- AXI4-full read master ----
    output reg         m_arvalid,
    input  wire        m_arready,
    output reg  [31:0] m_araddr,
    output reg  [ 7:0] m_arlen,
    output wire [ 2:0] m_arsize,
    output wire [ 1:0] m_arburst,
    input  wire        m_rvalid,
    output wire        m_rready,
    input  wire [31:0] m_rdata,
    input  wire        m_rlast,
    input  wire [ 1:0] m_rresp,

    // ---- local buffer write port ----
    output wire        buf_we,
    output reg  [BUF_AW-1:0] buf_addr,
    output wire [31:0] buf_wdata
);
    assign m_arsize  = 3'b010;             // 4 bytes/beat
    assign m_arburst = 2'b01;              // INCR
    assign m_rready  = (state == S_R);
    assign buf_we    = (state == S_R) && m_rvalid;
    assign buf_wdata = m_rdata;

    localparam [1:0] S_IDLE=2'd0, S_AR=2'd1, S_R=2'd2, S_DONE=2'd3;
    reg [1:0]  state;
    reg [31:0] cur_addr;                   // byte address of next burst
    reg [16:0] remaining;                  // beats left to fetch
    reg [8:0]  beats_in_burst;             // 1..256 for the active burst

    // beats until the next 4 KB boundary from cur_addr (word granularity)
    wire [10:0] dist4k = (11'd1024 - cur_addr[11:2]); // words to boundary (<=1024)
    // this burst = min(remaining, 256, dist4k)
    wire [16:0] cap256 = (remaining > 17'd256) ? 17'd256 : remaining;
    wire [16:0] this_burst = ({6'b0, dist4k} < cap256) ? {6'b0, dist4k} : cap256;
    wire [8:0]  burst_m1   = this_burst[8:0] - 9'd1;   // AXI ARLEN = beats-1

    always @(posedge clk) begin
        if (!resetn) begin
            state <= S_IDLE; busy <= 1'b0; done <= 1'b0; err <= 1'b0;
            m_arvalid <= 1'b0;
        end else begin
            case (state)
                S_IDLE: if (go) begin
                            cur_addr  <= {src_addr[31:2], 2'b00};
                            remaining <= len_beats;
                            buf_addr  <= dst_word;
                            busy <= 1'b1; done <= 1'b0; err <= 1'b0;
                            state <= (len_beats == 17'd0) ? S_DONE : S_AR;  // LEN=0 = no-op, no burst
                        end
                S_AR: begin
                            m_araddr <= cur_addr;
                            m_arlen  <= burst_m1[7:0];            // AXI ARLEN = beats-1
                            beats_in_burst <= this_burst[8:0];
                            m_arvalid <= 1'b1;
                            if (m_arvalid && m_arready) begin
                                m_arvalid <= 1'b0;
                                state <= S_R;
                            end
                        end
                S_R: if (m_rvalid) begin
                            if (m_rresp[1]) err <= 1'b1;          // latch SLVERR/DECERR
                            buf_addr <= buf_addr + 1'b1;          // advance local write ptr
                            if (m_rlast) begin
                                remaining <= remaining - {8'b0, beats_in_burst};
                                cur_addr  <= cur_addr + {21'b0, beats_in_burst, 2'b00};
                                if ((remaining - {8'b0, beats_in_burst}) == 17'd0)
                                    state <= S_DONE;
                                else
                                    state <= S_AR;
                            end
                        end
                S_DONE: begin
                            busy <= 1'b0; done <= 1'b1;
                            state <= S_IDLE;
                        end
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
`default_nettype wire
