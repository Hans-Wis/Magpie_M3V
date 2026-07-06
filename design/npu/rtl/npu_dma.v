// =============================================================================
// npu_dma.v — Magpie_M3V NPU weight/activation DMA (AXI4-full master)
// -----------------------------------------------------------------------------
// Streams a contiguous block from shared memory (AXI4-full, INCR read bursts)
// into the NPU local buffer/TCM, or writes a contiguous result block back from
// TCM to shared memory. Programmed by the host over AXI4-Lite via npu_axil_regs
// (src/dst/len + go); raises done when the selected transfer completes.
// This is the bandwidth path (ADR-0031 §3): batch-1 GEMV is weight-bandwidth
// bound, so bursts (not single beats) are the point.
//
// AXI-legal bursts: each burst <= 256 beats AND never crosses a 4 KB boundary.
// Longer transfers are chunked into multiple bursts. 32-bit data (ARSIZE=4B).
// Single-outstanding (one burst in flight) — simple, correct, matches the
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
    input  wire        abort_i,              // ADR-0038: finish the CURRENT AXI burst, then idle
    input  wire        write_mode,         // 0=AXI read -> TCM, 1=TCM -> AXI write
    input  wire [31:0] src_addr,           // shared byte addr in read mode; destination byte addr in write mode
    input  wire [BUF_AW-1:0] dst_word,     // local destination in read mode; local source in write mode
    input  wire [16:0] len_beats,          // number of 32-bit words to move (0..65536; 0 = no-op)
    output reg         busy,
    output reg         done,               // sticky until next go
    output reg         err,                // sticky: read RRESP or write BRESP returned SLVERR/DECERR

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

    // ---- AXI4-full write master ----
    output reg         m_awvalid,
    input  wire        m_awready,
    output reg  [31:0] m_awaddr,
    output reg  [ 7:0] m_awlen,
    output wire [ 2:0] m_awsize,
    output wire [ 1:0] m_awburst,
    output reg         m_wvalid,
    input  wire        m_wready,
    output wire [31:0] m_wdata,
    output wire [ 3:0] m_wstrb,
    output wire        m_wlast,
    input  wire        m_bvalid,
    output wire        m_bready,
    input  wire [ 1:0] m_bresp,

    // ---- local buffer write port (AXI read mode) ----
    output wire        buf_we,
    output reg  [BUF_AW-1:0] buf_addr,
    output wire [31:0] buf_wdata,

    // ---- local buffer read port (AXI write mode) ----
    output wire        buf_re,
    output reg  [BUF_AW-1:0] buf_raddr,
    input  wire [31:0] buf_rdata
);
    assign m_arsize  = 3'b010;             // 4 bytes/beat
    assign m_arburst = 2'b01;              // INCR
    assign m_rready  = (state == S_R);
    assign buf_we    = (state == S_R) && m_rvalid;
    assign buf_wdata = m_rdata;

    assign m_awsize  = 3'b010;             // 4 bytes/beat
    assign m_awburst = 2'b01;              // INCR
    assign m_wdata   = buf_rdata;
    assign m_wstrb   = 4'hF;
    assign m_bready  = (state == S_B);
    assign buf_re    = (state == S_W);

    localparam [2:0] S_IDLE=3'd0, S_AR=3'd1, S_R=3'd2, S_AW=3'd3, S_W=3'd4, S_B=3'd5, S_DONE=3'd6;
    reg [2:0]  state;
    reg [31:0] cur_addr;                   // byte address of next burst
    reg [16:0] remaining;                  // beats left to fetch
    reg [8:0]  beats_in_burst;             // 1..256 for the active burst
    reg [8:0]  beats_done;                 // accepted W beats in the active write burst
    reg        done_ok;                    // suppress writeback done on BRESP error

    // beats until the next 4 KB boundary from cur_addr (word granularity)
    wire [10:0] dist4k = (11'd1024 - cur_addr[11:2]); // words to boundary (<=1024)
    // this burst = min(remaining, 256, dist4k)
    wire [16:0] cap256 = (remaining > 17'd256) ? 17'd256 : remaining;
    wire [16:0] this_burst = ({6'b0, dist4k} < cap256) ? {6'b0, dist4k} : cap256;
    wire [8:0]  burst_m1   = this_burst[8:0] - 9'd1;   // AXI ARLEN = beats-1
    wire        final_wbeat = (beats_done == (beats_in_burst - 9'd1));
    assign      m_wlast = m_wvalid && (state == S_W) && final_wbeat;

    always @(posedge clk) begin
        if (!resetn) begin
            state <= S_IDLE; busy <= 1'b0; done <= 1'b0; err <= 1'b0;
            m_arvalid <= 1'b0; m_awvalid <= 1'b0; m_wvalid <= 1'b0;
        end else begin
            case (state)
                S_IDLE: if (abort_i) begin
                            done <= 1'b0; err <= 1'b0;   // clear stickies for soft reset
                        end else if (go) begin
                            cur_addr  <= {src_addr[31:2], 2'b00};
                            remaining <= len_beats;
                            buf_addr  <= dst_word;
                            buf_raddr <= dst_word;
                            done_ok <= 1'b1;
                            busy <= 1'b1; done <= 1'b0; err <= 1'b0;
                            if (len_beats == 17'd0)
                                state <= S_DONE;             // LEN=0 = no-op, no burst
                            else
                                state <= write_mode ? S_AW : S_AR;
                        end
                S_AR: if (abort_i && !m_arvalid) begin
                            done_ok <= 1'b0; state <= S_DONE;   // burst not yet presented
                        end else begin
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
                                if (abort_i) begin
                                    done_ok <= 1'b0;      // burst-boundary abort_i (protocol clean)
                                    state <= S_DONE;
                                end else if ((remaining - {8'b0, beats_in_burst}) == 17'd0)
                                    state <= S_DONE;
                                else
                                    state <= S_AR;
                            end
                        end
                S_AW: if (abort_i && !m_awvalid) begin
                            done_ok <= 1'b0; state <= S_DONE;
                        end else begin
                            m_awaddr <= cur_addr;
                            m_awlen  <= burst_m1[7:0];            // AXI AWLEN = beats-1
                            beats_in_burst <= this_burst[8:0];
                            m_awvalid <= 1'b1;
                            if (m_awvalid && m_awready) begin
                                m_awvalid <= 1'b0;
                                beats_done <= 9'd0;
                                state <= S_W;
                            end
                        end
                S_W: begin
                            m_wvalid <= 1'b1;
                            if (m_wvalid && m_wready) begin
                                if (final_wbeat) begin
                                    m_wvalid <= 1'b0;
                                    state <= S_B;
                                end
                                beats_done <= beats_done + 9'd1;
                                buf_raddr <= buf_raddr + 1'b1;
                            end
                        end
                S_B: if (m_bvalid) begin
                            if (m_bresp[1]) begin
                                err <= 1'b1;                       // latch SLVERR/DECERR
                                done_ok <= 1'b0;
                                state <= S_DONE;                   // abort_i; no wb_done
                            end else begin
                                remaining <= remaining - {8'b0, beats_in_burst};
                                cur_addr  <= cur_addr + {21'b0, beats_in_burst, 2'b00};
                                if (abort_i) begin
                                    done_ok <= 1'b0;
                                    state <= S_DONE;
                                end else if ((remaining - {8'b0, beats_in_burst}) == 17'd0)
                                    state <= S_DONE;
                                else
                                    state <= S_AW;
                            end
                        end
                S_DONE: begin
                            busy <= 1'b0; done <= done_ok && !abort_i;
                            state <= S_IDLE;
                        end
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
`default_nettype wire
