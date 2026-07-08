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
    parameter integer BUF_AW = 12,         // local buffer address width (words)
    parameter integer DMA_DATA_W = 32      // AXI data width for weight-load path
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
    input  wire [DMA_DATA_W-1:0] m_rdata,
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
    output wire [DMA_DATA_W-1:0] m_wdata,
    output wire [DMA_DATA_W/8-1:0] m_wstrb,
    output wire        m_wlast,
    input  wire        m_bvalid,
    output wire        m_bready,
    input  wire [ 1:0] m_bresp,

    // ---- local buffer write port (AXI read mode) ----
    output wire        buf_we,
    output reg  [BUF_AW-1:0] buf_addr,
    output wire [DMA_DATA_W-1:0] buf_wdata,

    // ---- local buffer read port (AXI write mode) ----
    output wire        buf_re,
    output reg  [BUF_AW-1:0] buf_raddr,
    input  wire [31:0] buf_rdata
);
    localparam integer WPB       = DMA_DATA_W / 32;
    localparam integer AXI_BYTES = DMA_DATA_W / 8;
    localparam integer AXI_SIZE  = $clog2(AXI_BYTES);
    localparam integer WPB_LG2   = $clog2(WPB);
    localparam integer ERR_ALIGN = 1;
    localparam [3:0] WPB_4 = (DMA_DATA_W == 256) ? 4'd8 :
                             (DMA_DATA_W == 128) ? 4'd4 :
                             (DMA_DATA_W == 64)  ? 4'd2 : 4'd1;
    localparam [BUF_AW-1:0] WPB_BUF = {{(BUF_AW-4){1'b0}}, WPB_4};

    initial begin
        if (DMA_DATA_W != 32 && DMA_DATA_W != 64 && DMA_DATA_W != 128 && DMA_DATA_W != 256)
            $fatal(1, "npu_dma: DMA_DATA_W must be one of 32/64/128/256");
    end

    assign m_arsize  = AXI_SIZE[2:0];      // wide weight-load beats
    assign m_arburst = 2'b01;              // INCR
    assign m_rready  = (state == S_R);
    assign buf_we    = (state == S_R) && m_rvalid;
    assign buf_wdata = m_rdata;

    assign m_awsize  = 3'b010;             // M3a writeback remains 4 bytes/beat
    assign m_awburst = 2'b01;              // INCR
    assign m_bready  = (state == S_B);
    assign buf_re    = (state == S_W);

    localparam [2:0] S_IDLE=3'd0, S_AR=3'd1, S_R=3'd2, S_AW=3'd3, S_W=3'd4, S_B=3'd5, S_DONE=3'd6;
    reg [2:0]  state;
    reg [31:0] cur_addr;                   // byte address of next burst
    reg [16:0] remaining;                  // beats left to fetch
    reg [8:0]  beats_in_burst;             // 1..256 for the active burst
    reg [8:0]  beats_done;                 // accepted W beats in the active write burst
    reg        done_ok;                    // suppress writeback done on BRESP error
    reg        mode_write;                 // latched transfer direction

    function [2:0] word_lane;
        input [31:0] byte_addr;
        input [8:0]  beat_idx;
        reg [31:0] word_index;
        reg [31:0] lane_mod;
        begin
            word_index = {2'b0, byte_addr[31:2]} + {23'b0, beat_idx};
            lane_mod = word_index % WPB;
            word_lane = lane_mod[2:0];
        end
    endfunction

    reg [DMA_DATA_W-1:0] wdata_mux;
    reg [DMA_DATA_W/8-1:0] wstrb_mux;
    always @* begin
        wdata_mux = {DMA_DATA_W{1'b0}};
        wstrb_mux = {(DMA_DATA_W/8){1'b0}};
        wdata_mux[word_lane(cur_addr, beats_done) * 32 +: 32] = buf_rdata;
        wstrb_mux[word_lane(cur_addr, beats_done) * 4  +: 4]  = 4'hF;
    end
    assign m_wdata = wdata_mux;
    assign m_wstrb = wstrb_mux;

    // Burst caps are in AXI beats. LOAD beats are wide; STORE beats remain 32-bit.
    wire [31:0] remaining_w = {15'b0, remaining};
    wire [31:0] remaining_read_axi_w = (remaining_w + (WPB - 1)) >> WPB_LG2;
    wire [16:0] remaining_axi_beats =
        mode_write ? remaining : remaining_read_axi_w[16:0];
    wire [16:0] dist4k_read  = (17'd4096 - {5'b0, cur_addr[11:0]}) >> AXI_SIZE;
    wire [16:0] dist4k_write = {6'b0, (11'd1024 - cur_addr[11:2])};
    wire [16:0] dist4k = mode_write ? dist4k_write : dist4k_read;
    wire [16:0] cap256 = (remaining_axi_beats > 17'd256) ? 17'd256 : remaining_axi_beats;
    wire [16:0] this_burst = (dist4k < cap256) ? dist4k : cap256;
    wire [8:0]  burst_m1   = this_burst[8:0] - 9'd1;   // AXI ARLEN = beats-1
    wire        final_wbeat = (beats_done == (beats_in_burst - 9'd1));
    assign      m_wlast = m_wvalid && (state == S_W) && final_wbeat;
    wire [16:0] words_in_burst = mode_write ? {8'b0, beats_in_burst}
                                             : ({8'b0, beats_in_burst} << WPB_LG2);
    wire [31:0] bytes_in_burst = {13'b0, words_in_burst, 2'b00};
    wire        read_align_err = (WPB != 1) &&
                                 ((src_addr % AXI_BYTES) != 0 ||
                                  ({{(32-BUF_AW){1'b0}}, dst_word} % WPB) != 0 ||
                                  ({15'b0, len_beats} % WPB) != 0);

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
                            mode_write <= write_mode;
                            done_ok <= 1'b1;
                            busy <= 1'b1; done <= 1'b0; err <= 1'b0;
                            if (len_beats == 17'd0)
                                state <= S_DONE;             // LEN=0 = no-op, no burst
                            else if (!write_mode && read_align_err) begin
                                err <= ERR_ALIGN[0];
                                state <= S_DONE;
                            end
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
                            buf_addr <= buf_addr + WPB_BUF;       // advance local write ptr
                            if (m_rlast) begin
                                remaining <= remaining - words_in_burst;
                                cur_addr  <= cur_addr + bytes_in_burst;
                                if (abort_i) begin
                                    done_ok <= 1'b0;      // burst-boundary abort_i (protocol clean)
                                    state <= S_DONE;
                                end else if ((remaining - words_in_burst) == 17'd0)
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
                                remaining <= remaining - words_in_burst;
                                cur_addr  <= cur_addr + bytes_in_burst;
                                if (abort_i) begin
                                    done_ok <= 1'b0;
                                    state <= S_DONE;
                                end else if ((remaining - words_in_burst) == 17'd0)
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
