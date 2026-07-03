// =============================================================================
// npu_axil_regs.v — Magpie_M3V NPU control endpoint (AXI4-Lite SLAVE)
// -----------------------------------------------------------------------------
// The host cpu_m1 (frozen) reaches this over its AXI4-Lite D master (via the
// frozen axil_bridge.v) through the M3V axil_1to2 fabric. Word-addressed CSRs:
//   0x00 ID      RO  0x4E505530 ("NPU0") — host presence check
//   0x04 CTRL    RW  [0]=start [1]=irq_clear(W1-action) [2]=soft_reset [3]=irq_enable
//   0x08 STATUS  RO  [0]=npu_busy [1]=npu_done [2]=dma_busy [3]=dma_done [4]=irq_pending [5]=dma_err
//   0x0C CONFIG  RW  kernel/descriptor pointer (weight base, etc.)
//   0x10 SCRATCH RW  round-trip sanity register
// Single-outstanding AXI4-Lite (matches the host bridge). 32-bit data, no burst.
// =============================================================================
`default_nettype none

module npu_axil_regs #(
    parameter [31:0] ID_MAGIC = 32'h4E505530
) (
    input  wire        clk,
    input  wire        resetn,

    // ---- AXI4-Lite slave ----
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    input  wire [31:0] s_axi_awaddr,
    input  wire [ 2:0] s_axi_awprot,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    input  wire [31:0] s_axi_wdata,
    input  wire [ 3:0] s_axi_wstrb,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    output wire [ 1:0] s_axi_bresp,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    input  wire [31:0] s_axi_araddr,
    input  wire [ 2:0] s_axi_arprot,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    output reg  [31:0] s_axi_rdata,
    output wire [ 1:0] s_axi_rresp,

    // ---- to/from the NPU core (stubbed until Phase 2) ----
    output wire        npu_start,
    output wire [31:0] npu_config,
    input  wire        npu_busy,
    input  wire        npu_done,

    // ---- DMA descriptor (to npu_dma) ----
    output reg  [31:0] dma_src,
    output reg  [31:0] dma_dst,
    output wire [16:0] dma_len,
    output reg         dma_go,       // 1-cycle pulse on CTRL-GO write
    input  wire        dma_busy,
    input  wire        dma_done,
    input  wire        dma_err,      // sticky DMA read-error (STATUS[5])

    // ---- level interrupt to host (out only) ----
    output wire        irq            // = irq_pending & CTRL.irq_enable
);
    assign s_axi_bresp = 2'b00;   // OKAY
    assign s_axi_rresp = 2'b00;

    // ---------- register storage ----------
    reg [31:0] ctrl_q, config_q;
    reg        irq_pending;
    reg [31:0] dma_len_q;                 // full-word storage; DMA uses low 17 bits
    assign     dma_len = dma_len_q[16:0];
    //  STATUS: [0]=npu_busy [1]=npu_done [2]=dma_busy [3]=dma_done [4]=irq_pending [5]=dma_err
    wire [31:0] status_w = {26'b0, dma_err, irq_pending, dma_done, dma_busy, npu_done, npu_busy};

    // ================= WRITE channel (single-outstanding) =================
    // Accept AW and W together, then emit B. Fits the host bridge that issues
    // AW+W and waits for B.
    reg aw_seen, w_seen;
    reg [31:0] wa_q, wd_q;
    reg [3:0]  wstrb_q;
    wire wr_fire = aw_seen && w_seen && !s_axi_bvalid;

    // byte-strobe merge: keep old bytes where WSTRB=0
    function [31:0] merge; input [31:0] old; input [31:0] wd; input [3:0] strb; begin
        merge = { strb[3] ? wd[31:24] : old[31:24], strb[2] ? wd[23:16] : old[23:16],
                  strb[1] ? wd[15:8]  : old[15:8],  strb[0] ? wd[7:0]   : old[7:0] };
    end endfunction

    assign s_axi_awready = !aw_seen && !s_axi_bvalid;
    assign s_axi_wready  = !w_seen  && !s_axi_bvalid;

    always @(posedge clk) begin
        if (!resetn) begin
            aw_seen <= 1'b0; w_seen <= 1'b0; s_axi_bvalid <= 1'b0;
            ctrl_q <= 32'b0; config_q <= 32'b0;
            dma_src <= 32'b0; dma_dst <= 32'b0; dma_len_q <= 32'b0; dma_go <= 1'b0;
        end else begin
            dma_go <= 1'b0;                    // default: pulse is 1-cycle
            if (s_axi_awvalid && s_axi_awready) begin aw_seen <= 1'b1; wa_q <= s_axi_awaddr; end
            if (s_axi_wvalid  && s_axi_wready ) begin w_seen <= 1'b1; wd_q <= s_axi_wdata; wstrb_q <= s_axi_wstrb; end

            if (wr_fire) begin
                case (wa_q[7:2])
                    6'h01: ctrl_q   <= merge(ctrl_q,   wd_q, wstrb_q);          // 0x04 CTRL
                    6'h03: config_q <= merge(config_q, wd_q, wstrb_q);          // 0x0C CONFIG
                    // 0x10 SCRATCH written in the dedicated scratch_q block below
                    6'h08: dma_src  <= merge(dma_src,  wd_q, wstrb_q);          // 0x20 DMA_SRC
                    6'h09: dma_dst  <= merge(dma_dst,  wd_q, wstrb_q);          // 0x24 DMA_DST
                    6'h0A: dma_len_q <= merge(dma_len_q, wd_q, wstrb_q);        // 0x28 DMA_LEN
                    6'h0B: dma_go   <= wd_q[0] & wstrb_q[0];                    // 0x2C GO (1-cyc pulse)
                    default: ;                            // RO/unmapped (ID/STATUS): ignore
                endcase
                s_axi_bvalid <= 1'b1;
                aw_seen <= 1'b0; w_seen <= 1'b0;
            end
            if (s_axi_bvalid && s_axi_bready) s_axi_bvalid <= 1'b0;
        end
    end

    // dedicated SCRATCH register (0x10) for the fabric round-trip test
    reg [31:0] scratch_q;
    always @(posedge clk) begin
        if (!resetn) scratch_q <= 32'b0;
        else if (wr_fire && wa_q[7:2] == 6'h04) scratch_q <= merge(scratch_q, wd_q, wstrb_q);
    end

    // ================= READ channel (single-outstanding) =================
    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_rvalid <= 1'b0; s_axi_rdata <= 32'b0;
        end else begin
            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rvalid <= 1'b1;
                case (s_axi_araddr[7:2])
                    6'h00:  s_axi_rdata <= ID_MAGIC;   // 0x00 ID
                    6'h01:  s_axi_rdata <= ctrl_q;     // 0x04 CTRL
                    6'h02:  s_axi_rdata <= status_w;   // 0x08 STATUS
                    6'h03:  s_axi_rdata <= config_q;   // 0x0C CONFIG
                    6'h04:  s_axi_rdata <= scratch_q;  // 0x10 SCRATCH
                    6'h08:  s_axi_rdata <= dma_src;    // 0x20 DMA_SRC
                    6'h09:  s_axi_rdata <= dma_dst;    // 0x24 DMA_DST
                    6'h0A:  s_axi_rdata <= {15'b0, dma_len}; // 0x28 DMA_LEN
                    default: s_axi_rdata <= 32'h0;
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end
    assign s_axi_arready = !s_axi_rvalid;

    // ---------- interrupt: set on completion edge, cleared by CTRL.irq_clear ----------
    reg dma_done_d, npu_done_d;
    always @(posedge clk) begin
        if (!resetn) begin
            irq_pending <= 1'b0; dma_done_d <= 1'b0; npu_done_d <= 1'b0;
        end else begin
            dma_done_d <= dma_done;
            npu_done_d <= npu_done;
            if ((dma_done & ~dma_done_d) | (npu_done & ~npu_done_d))
                irq_pending <= 1'b1;                                  // rising edge of a completion
            else if (wr_fire && wa_q[7:2] == 6'h01 && wd_q[1] && wstrb_q[0])
                irq_pending <= 1'b0;                                  // CTRL.irq_clear (bit1)
        end
    end
    assign irq = irq_pending & ctrl_q[3];                            // CTRL.irq_enable (bit3)

    // ---------- outputs to NPU core ----------
    assign npu_start  = ctrl_q[0];
    assign npu_config = config_q;

endmodule
`default_nettype wire
