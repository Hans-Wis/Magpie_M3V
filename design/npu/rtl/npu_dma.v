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
// Longer transfers are chunked into multiple bursts. DATA_W scales ARSIZE/AWSIZE.
// Single-outstanding (one burst in flight) — simple, correct, matches the
// single-outstanding fabric; multi-outstanding is a later throughput tuning.
// =============================================================================
`default_nettype none

module npu_dma #(
    parameter integer BUF_AW = 12,         // local buffer address width (words)
    parameter integer DMA_DATA_W = 32      // AXI data width for DMA load/store path
) (
    input  wire        clk,
    input  wire        resetn,

    // ---- descriptor / control (from npu_axil_regs) ----
    input  wire        go,                 // 1-cycle pulse: start transfer
    input  wire        abort_i,              // ADR-0038: finish the CURRENT AXI burst, then idle
    input  wire        write_mode,         // 0=AXI read -> TCM, 1=TCM -> AXI write
    input  wire        narrow_i,           // 1=single 32-bit word per AXI beat on any DMA_DATA_W
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
    input  wire [DMA_DATA_W-1:0] buf_rdata
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

    // (control assigns moved below the state/narrow_l/narrow_buf_wdata
    //  declarations so Presto/DC compiles without forward references — pure
    //  reorder, no logic change; Verilator 2-pass tolerated the original order.)

    localparam [2:0] S_IDLE=3'd0, S_AR=3'd1, S_R=3'd2, S_AW=3'd3, S_W=3'd4, S_B=3'd5, S_DONE=3'd6;
    reg [2:0]  state;
    reg [31:0] cur_addr;                   // byte address of next burst
    reg [16:0] remaining;                  // 32-bit words left to move
    reg [8:0]  beats_in_burst;             // 1..256 for the active burst
    reg [8:0]  beats_done;                 // accepted W beats in the active write burst
    reg        done_ok;                    // suppress writeback done on BRESP error
    reg        mode_write;                 // latched transfer direction
    reg        narrow_l;                   // latched transfer width policy

    function [31:0] lane_word;
        input [DMA_DATA_W-1:0] data;
        input [31:0] lane;
        integer j;
        begin
            lane_word = 32'b0;
            for (j = 0; j < WPB; j = j + 1)
                if (lane == j[31:0])
                    lane_word = data[j*32 +: 32];
        end
    endfunction

    function [DMA_DATA_W-1:0] lane_wdata;
        input [31:0] lane;
        input [31:0] word;
        integer j;
        begin
            lane_wdata = {DMA_DATA_W{1'b0}};
            for (j = 0; j < WPB; j = j + 1)
                if (lane == j[31:0])
                    lane_wdata[j*32 +: 32] = word;
        end
    endfunction

    function [DMA_DATA_W/8-1:0] lane_wstrb;
        input [31:0] lane;
        integer j;
        begin
            lane_wstrb = {(DMA_DATA_W/8){1'b0}};
            for (j = 0; j < WPB; j = j + 1)
                if (lane == j[31:0])
                    lane_wstrb[j*4 +: 4] = 4'hf;
        end
    endfunction

    wire [31:0] word_lane_w = ({2'b0, cur_addr[31:2]} % WPB);
    wire [DMA_DATA_W-1:0] narrow_buf_wdata =
        lane_wdata(32'd0, lane_word(m_rdata, word_lane_w));
    wire [DMA_DATA_W-1:0] narrow_m_wdata = lane_wdata(word_lane_w, buf_rdata[31:0]);
    wire [DMA_DATA_W/8-1:0] narrow_m_wstrb = lane_wstrb(word_lane_w);

    assign m_wdata = narrow_l ? narrow_m_wdata : buf_rdata;
    assign m_wstrb = narrow_l ? narrow_m_wstrb : {(DMA_DATA_W/8){1'b1}};

    // control assigns (moved here from above so all referenced symbols —
    // state/S_*, narrow_l, narrow_buf_wdata — are declared first; DC/Presto).
    assign m_arsize  = narrow_l ? 3'd2 : AXI_SIZE[2:0];
    assign m_arburst = 2'b01;              // INCR
    assign m_rready  = (state == S_R);
    assign buf_we    = (state == S_R) && m_rvalid;
    assign buf_wdata = narrow_l ? narrow_buf_wdata : m_rdata;

    assign m_awsize  = narrow_l ? 3'd2 : AXI_SIZE[2:0];
    assign m_awburst = 2'b01;              // INCR
    assign m_bready  = (state == S_B);
    assign buf_re    = (state == S_W);

    // Burst caps are in AXI beats. Wide transfers move WPB words per beat;
    // narrow transfers intentionally behave like DMA_DATA_W=32.
    wire [31:0] remaining_w = {15'b0, remaining};
    wire        narrow_eff = (state == S_IDLE) ? narrow_i : narrow_l;
    wire [31:0] remaining_axi_w = narrow_eff ? remaining_w : (remaining_w >> WPB_LG2);
    wire [16:0] remaining_axi_beats = remaining_axi_w[16:0];
    wire [16:0] dist4k = narrow_eff ? ((17'd4096 - {5'b0, cur_addr[11:0]}) >> 2)
                                    : ((17'd4096 - {5'b0, cur_addr[11:0]}) >> AXI_SIZE);
    wire [16:0] cap256 = (remaining_axi_beats > 17'd256) ? 17'd256 : remaining_axi_beats;
    wire [16:0] this_burst = (dist4k < cap256) ? dist4k : cap256;
    wire [8:0]  burst_m1   = this_burst[8:0] - 9'd1;   // AXI ARLEN = beats-1
    wire        final_wbeat = (beats_done == (beats_in_burst - 9'd1));
    assign      m_wlast = m_wvalid && (state == S_W) && final_wbeat;
    wire [16:0] words_in_burst = narrow_l ? {8'b0, beats_in_burst}
                                          : ({8'b0, beats_in_burst} << WPB_LG2);
    wire [31:0] bytes_in_burst = {13'b0, words_in_burst, 2'b00};
    wire [BUF_AW-1:0] buf_step = narrow_l ? {{(BUF_AW-1){1'b0}}, 1'b1} : WPB_BUF;
    wire        read_align_err = !narrow_eff && (WPB != 1) &&
                                 ((src_addr % AXI_BYTES) != 0 ||
                                  ({{(32-BUF_AW){1'b0}}, dst_word} % WPB) != 0 ||
                                  ({15'b0, len_beats} % WPB) != 0);
    wire        write_align_err = !narrow_eff && (WPB != 1) &&
                                  ((src_addr % AXI_BYTES) != 0 ||
                                   ({{(32-BUF_AW){1'b0}}, dst_word} % WPB) != 0 ||
                                   ({15'b0, len_beats} % WPB) != 0);

    always @(posedge clk) begin
        if (!resetn) begin
            state <= S_IDLE; busy <= 1'b0; done <= 1'b0; err <= 1'b0;
            m_arvalid <= 1'b0; m_awvalid <= 1'b0; m_wvalid <= 1'b0;
            narrow_l <= 1'b0;
        end else begin
            case (state)
                S_IDLE: if (abort_i) begin
                            done <= 1'b0; err <= 1'b0;   // clear stickies for soft reset
                            narrow_l <= 1'b0;
                        end else if (go) begin
                            cur_addr  <= {src_addr[31:2], 2'b00};
                            remaining <= len_beats;
                            buf_addr  <= dst_word;
                            buf_raddr <= dst_word;
                            mode_write <= write_mode;
                            narrow_l <= narrow_i;
                            done_ok <= 1'b1;
                            busy <= 1'b1; done <= 1'b0; err <= 1'b0;
                            if (len_beats == 17'd0)
                                state <= S_DONE;             // LEN=0 = no-op, no burst
                            else if ((!write_mode && read_align_err) ||
                                     ( write_mode && write_align_err)) begin
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
                            buf_addr <= buf_addr + buf_step;      // advance local write ptr
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
                                buf_raddr <= buf_raddr + buf_step;
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
                            narrow_l <= 1'b0;
                            state <= S_IDLE;
                        end
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
`default_nettype wire
