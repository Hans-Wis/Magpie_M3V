// =============================================================================
// npu_axil_regs.v — Magpie_M3V NPU control endpoint (AXI4-Lite SLAVE)
// -----------------------------------------------------------------------------
// The host cpu_m1 (frozen) reaches this over its AXI4-Lite D master (via the
// frozen axil_bridge.v) through the M3V axil_1to2 fabric. Word-addressed CSRs:
//   0x00 ID      RO  0x4E505530 ("NPU0") — host presence check
//   0x04 CTRL    RW  [0]=start [1]=irq_clear(W1-action) [2]=soft_reset [3]=irq_enable
//   0x08 STATUS  RO  [0]=npu_busy [1]=npu_done [2]=dma_busy [3]=dma_done [4]=irq_pending [5]=dma_err
//                    [6]=wb_busy [7]=wb_done
//   0x0C CONFIG  RW  kernel/descriptor pointer (weight base, etc.)
//   0x10 SCRATCH RW  round-trip sanity register
//   0x40..0x5C CQ transport/control block (ADR-0035)
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

    // ---- core-local CSR mirror (simple synchronous register-file port) ----
    input  wire        core_csr_en,
    input  wire        core_csr_we,
    input  wire [ 7:0] core_csr_addr,
    input  wire [31:0] core_csr_wdata,
    output reg  [31:0] core_csr_rdata,

    // ---- DMA descriptor (to npu_dma) ----
    output reg  [31:0] dma_src,
    output reg  [31:0] dma_dst,
    output wire [16:0] dma_len,
    output reg         dma_go,       // 1-cycle pulse on CTRL-GO write
    input  wire        dma_busy,
    input  wire        dma_done,
    input  wire        dma_err,      // sticky DMA read/write-error (STATUS[5])

    // ---- result writeback descriptor (to npu_dma write mode) ----
    output reg  [31:0] wb_src,
    output reg  [31:0] wb_dst,
    output wire [16:0] wb_len,
    output reg         wb_go,        // 1-cycle pulse on WB_CTRL.WB_GO write
    input  wire        wb_busy,
    input  wire        wb_done,

    // ---- matrix engine command block (ADR-0037; core-mirror-writable) ----
    output reg  [31:0] mat_a_addr,
    output reg  [31:0] mat_b_addr,
    output reg  [31:0] mat_mult,
    output reg  [31:0] mat_rsp,      // {(zp<<8)|shift} per v4 W2
    output reg  [31:0] mat_clamp,    // {(max<<8)|min} per v4 W3
    output reg  [31:0] mat_out_base,
    output reg         mat_go,       // 1-cycle pulse on MAT_CTRL write
    output reg  [2:0]  mat_cmd,
    output reg  [3:0]  mat_bank,
    output reg  [7:0]  mat_rpt,
    input  wire        mat_busy,
    input  wire        mat_done,
    input  wire        mat_err,

    // ---- ADR-0038 soft_reset/abort ----
    output wire        abort_req,

    // ---- level interrupt to host (out only) ----
    output wire        irq            // = irq_pending & CTRL.irq_enable
);
    assign s_axi_bresp = 2'b00;   // OKAY
    assign s_axi_rresp = 2'b00;

    // ---------- register storage ----------
    reg [31:0] ctrl_q, config_q;
    reg        irq_pending;
    reg [31:0] dma_len_q;                 // full-word storage; DMA uses low 17 bits
    reg [31:0] wb_len_q;                  // full-word storage; DMA uses low 17 bits
    reg [31:0] cq_ring_base_q, cq_ring_size_q, cq_head_q, cq_tail_q, cq_ctrl_q, err_cause_q;
    reg [31:0] err_pc_q;
    reg        cq_busy_q, cq_err_q;
    reg        soft_rst_q;          // ADR-0038: abort in progress (drain then clear run state)
    wire       engines_quiet = !dma_busy && !wb_busy && !mat_busy;
    assign     abort_req = soft_rst_q;
    assign     dma_len = dma_len_q[16:0];
    assign     wb_len  = wb_len_q[16:0];
    //  STATUS: [0]=npu_busy [1]=npu_done [2]=dma_busy [3]=dma_done [4]=irq_pending [5]=dma_err [6]=wb_busy [7]=wb_done
    wire [31:0] status_w = {23'b0, soft_rst_q, wb_done, wb_busy, dma_err, irq_pending, dma_done, dma_busy, npu_done, npu_busy};
    wire [31:0] cq_mask_w = cq_ring_size_q - 32'd1;
    wire [31:0] cq_tail_next_w = (cq_tail_q + 32'd1) & cq_mask_w;
    wire [31:0] cq_status_w = {28'b0, cq_err_q, cq_busy_q, (cq_tail_next_w == cq_head_q), (cq_head_q == cq_tail_q)};

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
            wb_src <= 32'b0; wb_dst <= 32'b0; wb_len_q <= 32'b0; wb_go <= 1'b0;
            cq_ring_base_q <= 32'b0; cq_ring_size_q <= 32'b0; cq_head_q <= 32'b0; cq_tail_q <= 32'b0;
            cq_ctrl_q <= 32'b0; err_cause_q <= 32'b0; cq_busy_q <= 1'b0; cq_err_q <= 1'b0;
            mat_a_addr <= 32'b0; mat_b_addr <= 32'b0; mat_mult <= 32'b0;
            mat_rsp <= 32'b0; mat_clamp <= 32'b0; mat_out_base <= 32'h0000_0800;
            mat_go <= 1'b0; mat_cmd <= 3'b0; mat_bank <= 4'b0; mat_rpt <= 8'b0;
            err_pc_q <= 32'b0; soft_rst_q <= 1'b0;
        end else begin
            dma_go <= 1'b0;                    // default: pulse is 1-cycle
            wb_go <= 1'b0;                     // default: pulse is 1-cycle
            mat_go <= 1'b0;                    // default: pulse is 1-cycle
            // ADR-0038: abort completes when engines drain; run state clears,
            // FAULT evidence (ERR_CAUSE/ERR_PC/cq_err) PERSISTS for post-mortem.
            // Placed BEFORE the host-write case so a same-cycle CQ_CTRL ack wins
            // (deliberate clear beats the ABORTED latch — Codex P0-5 finding #2).
            if (soft_rst_q && engines_quiet) begin
                soft_rst_q  <= 1'b0;
                cq_busy_q   <= 1'b0;
                if (err_cause_q == 32'b0) err_cause_q <= 32'd8;   // ABORTED
                cq_err_q    <= 1'b1;
            end
            if (s_axi_awvalid && s_axi_awready) begin aw_seen <= 1'b1; wa_q <= s_axi_awaddr; end
            if (s_axi_wvalid  && s_axi_wready ) begin w_seen <= 1'b1; wd_q <= s_axi_wdata; wstrb_q <= s_axi_wstrb; end

            if (wr_fire) begin
                case (wa_q[7:2])
                    6'h01: begin                                                // 0x04 CTRL
                        // ADR-0038: bit2 = soft_reset/abort request — halts the core
                        // NOW (start cleared), engines drain, run state clears at
                        // quiesce. bit2 is momentary (not stored).
                        if (wd_q[2] && wstrb_q[0]) begin
                            soft_rst_q <= 1'b1;
                            ctrl_q     <= merge(ctrl_q, wd_q, wstrb_q) & 32'hFFFF_FFFA;
                        end else
                            ctrl_q <= merge(ctrl_q, wd_q, wstrb_q) & 32'hFFFF_FFFB;
                    end
                    6'h03: config_q <= merge(config_q, wd_q, wstrb_q);          // 0x0C CONFIG
                    // 0x10 SCRATCH written in the dedicated scratch_q block below
                    6'h08: dma_src  <= merge(dma_src,  wd_q, wstrb_q);          // 0x20 DMA_SRC
                    6'h09: dma_dst  <= merge(dma_dst,  wd_q, wstrb_q);          // 0x24 DMA_DST
                    6'h0A: dma_len_q <= merge(dma_len_q, wd_q, wstrb_q);        // 0x28 DMA_LEN
                    6'h0B: dma_go   <= wd_q[0] & wstrb_q[0] & ~soft_rst_q;      // 0x2C GO (abort-locked)
                    6'h0C: wb_src   <= merge(wb_src,   wd_q, wstrb_q);          // 0x30 WB_SRC
                    6'h0D: wb_dst   <= merge(wb_dst,   wd_q, wstrb_q);          // 0x34 WB_DST
                    6'h0E: wb_len_q <= merge(wb_len_q, wd_q, wstrb_q);          // 0x38 WB_LEN
                    6'h0F: wb_go    <= wd_q[0] & wstrb_q[0] & ~soft_rst_q;      // 0x3C WB_GO (abort-locked)
                    6'h10: cq_ring_base_q <= merge(cq_ring_base_q, wd_q, wstrb_q); // 0x40 CQ_RING_BASE
                    6'h11: cq_ring_size_q <= merge(cq_ring_size_q, wd_q, wstrb_q); // 0x44 CQ_RING_SIZE
                    6'h13: cq_tail_q <= merge(cq_tail_q, wd_q, wstrb_q);         // 0x4C CQ_TAIL
                    6'h14: begin                                                // 0x50 CQ_CTRL
                        if (!cq_ctrl_q[0] && merge(cq_ctrl_q, wd_q, wstrb_q)[0]) begin
                            err_cause_q <= 32'b0;
                            err_pc_q    <= 32'b0;   // evidence pair clears together
                            cq_err_q <= 1'b0;
                        end
                        cq_ctrl_q <= merge(cq_ctrl_q, wd_q, wstrb_q);
                    end
                    default: ;                            // RO/unmapped (ID/STATUS): ignore
                endcase
                s_axi_bvalid <= 1'b1;
                aw_seen <= 1'b0; w_seen <= 1'b0;
            end
            // ADR-0035: the core-local mirror owns CQ_HEAD/ERR_CAUSE and may
            // program DMA/WB. If host and core collide on one register, core wins.
            if (core_csr_en && core_csr_we) begin
                case (core_csr_addr[7:2])
                    6'h08: dma_src   <= core_csr_wdata;      // 0x20 DMA_SRC
                    6'h09: dma_dst   <= core_csr_wdata;      // 0x24 DMA_DST
                    6'h0A: dma_len_q <= core_csr_wdata;      // 0x28 DMA_LEN
                    6'h0B: dma_go    <= core_csr_wdata[0] & ~soft_rst_q;   // 0x2C GO (abort-locked)
                    6'h0C: wb_src    <= core_csr_wdata;      // 0x30 WB_SRC
                    6'h0D: wb_dst    <= core_csr_wdata;      // 0x34 WB_DST
                    6'h0E: wb_len_q  <= core_csr_wdata;      // 0x38 WB_LEN
                    6'h0F: wb_go     <= core_csr_wdata[0] & ~soft_rst_q;   // 0x3C WB_GO (abort-locked)
                    6'h12: cq_head_q <= core_csr_wdata;      // 0x48 CQ_HEAD
                    6'h18: mat_a_addr   <= core_csr_wdata;   // 0x60 MAT_A_ADDR
                    6'h19: mat_b_addr   <= core_csr_wdata;   // 0x64 MAT_B_ADDR
                    6'h1A: begin                             // 0x68 MAT_CTRL (GO pulse)
                        mat_cmd  <= core_csr_wdata[18:16];
                        mat_bank <= core_csr_wdata[11:8];
                        mat_rpt  <= core_csr_wdata[7:0];
                        mat_go   <= ~soft_rst_q;             // abort-locked
                    end
                    6'h1B: mat_mult     <= core_csr_wdata;   // 0x6C MAT_MULT
                    6'h1C: mat_rsp      <= core_csr_wdata;   // 0x70 MAT_RSP {(zp<<8)|shift}
                    6'h1D: mat_clamp    <= core_csr_wdata;   // 0x74 MAT_CLAMP {(max<<8)|min}
                    6'h1E: mat_out_base <= core_csr_wdata;   // 0x78 MAT_OUT_BASE
                    6'h20: if (err_cause_q == 32'b0)         // 0x80 ERR_PC (pairs with cause)
                        err_pc_q <= core_csr_wdata;
                    6'h16: if (err_cause_q == 32'b0 && core_csr_wdata != 32'b0) begin // 0x58 ERR_CAUSE
                        err_cause_q <= core_csr_wdata;
                        cq_err_q <= 1'b1;
                    end
                    6'h17: begin                            // 0x5C CQ_EVENT
                        if (core_csr_wdata[1]) cq_busy_q <= 1'b1;
                        if (core_csr_wdata[2]) cq_busy_q <= 1'b0;
                    end
                    default: ;
                endcase
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
                    6'h0C:  s_axi_rdata <= wb_src;     // 0x30 WB_SRC
                    6'h0D:  s_axi_rdata <= wb_dst;     // 0x34 WB_DST
                    6'h0E:  s_axi_rdata <= {15'b0, wb_len}; // 0x38 WB_LEN
                    6'h10:  s_axi_rdata <= cq_ring_base_q; // 0x40 CQ_RING_BASE
                    6'h11:  s_axi_rdata <= cq_ring_size_q; // 0x44 CQ_RING_SIZE
                    6'h12:  s_axi_rdata <= cq_head_q;      // 0x48 CQ_HEAD
                    6'h13:  s_axi_rdata <= cq_tail_q;      // 0x4C CQ_TAIL
                    6'h14:  s_axi_rdata <= cq_ctrl_q;      // 0x50 CQ_CTRL
                    6'h15:  s_axi_rdata <= cq_status_w;    // 0x54 CQ_STATUS
                    6'h16:  s_axi_rdata <= err_cause_q;    // 0x58 ERR_CAUSE
                    6'h1F:  s_axi_rdata <= {29'b0, mat_err, mat_done, mat_busy}; // 0x7C MAT_STATUS (debug)
                    6'h20:  s_axi_rdata <= err_pc_q;       // 0x80 ERR_PC (post-mortem)
                    default: s_axi_rdata <= 32'h0;
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end
    assign s_axi_arready = !s_axi_rvalid;

    // ---------- interrupt: set on completion edge, cleared by CTRL.irq_clear ----------
    reg dma_done_d, wb_done_d, npu_done_d, cq_err_d, dma_err_d;
    always @(posedge clk) begin
        if (!resetn) begin
            irq_pending <= 1'b0; dma_done_d <= 1'b0; wb_done_d <= 1'b0; npu_done_d <= 1'b0;
            cq_err_d <= 1'b0; dma_err_d <= 1'b0;
        end else begin
            dma_done_d <= dma_done;
            wb_done_d <= wb_done;
            npu_done_d <= npu_done;
            cq_err_d  <= cq_err_q;
            dma_err_d <= dma_err;
            if (((!cq_ctrl_q[0]) && ((dma_done & ~dma_done_d) | (wb_done & ~wb_done_d))) |
                (npu_done & ~npu_done_d) |
                (cq_err_q & ~cq_err_d) | (dma_err & ~dma_err_d) |   // ADR-0038 ERR IRQ
                (core_csr_en && core_csr_we && core_csr_addr[7:2] == 6'h17 && core_csr_wdata[0]))
                irq_pending <= 1'b1;                                  // rising edge of a completion
            else if (wr_fire && wa_q[7:2] == 6'h01 && wd_q[1] && wstrb_q[0])
                irq_pending <= 1'b0;                                  // CTRL.irq_clear (bit1)
        end
    end
    assign irq = irq_pending & ctrl_q[3];                            // CTRL.irq_enable (bit3)

    // ---------- outputs to NPU core ----------
    assign npu_start  = ctrl_q[0];
    assign npu_config = config_q;

    // ================= core-local registered read port =================
    always @(posedge clk) begin
        if (!resetn) begin
            core_csr_rdata <= 32'b0;
        end else if (core_csr_en) begin
            case (core_csr_addr[7:2])
                6'h01:  core_csr_rdata <= ctrl_q;          // 0x04 CTRL (RO to core)
                6'h02:  core_csr_rdata <= status_w;        // 0x08 STATUS
                6'h08:  core_csr_rdata <= dma_src;         // 0x20 DMA_SRC
                6'h09:  core_csr_rdata <= dma_dst;         // 0x24 DMA_DST
                6'h0A:  core_csr_rdata <= {15'b0, dma_len};
                6'h0C:  core_csr_rdata <= wb_src;          // 0x30 WB_SRC
                6'h0D:  core_csr_rdata <= wb_dst;          // 0x34 WB_DST
                6'h0E:  core_csr_rdata <= {15'b0, wb_len};
                6'h10:  core_csr_rdata <= cq_ring_base_q;  // 0x40 CQ_RING_BASE
                6'h11:  core_csr_rdata <= cq_ring_size_q;  // 0x44 CQ_RING_SIZE
                6'h12:  core_csr_rdata <= cq_head_q;       // 0x48 CQ_HEAD
                6'h13:  core_csr_rdata <= cq_tail_q;       // 0x4C CQ_TAIL
                6'h14:  core_csr_rdata <= cq_ctrl_q;       // 0x50 CQ_CTRL
                6'h15:  core_csr_rdata <= cq_status_w;     // 0x54 CQ_STATUS
                6'h16:  core_csr_rdata <= err_cause_q;     // 0x58 ERR_CAUSE
                6'h18:  core_csr_rdata <= mat_a_addr;      // 0x60
                6'h19:  core_csr_rdata <= mat_b_addr;      // 0x64
                6'h1B:  core_csr_rdata <= mat_mult;        // 0x6C
                6'h1C:  core_csr_rdata <= mat_rsp;         // 0x70
                6'h1D:  core_csr_rdata <= mat_clamp;       // 0x74
                6'h1E:  core_csr_rdata <= mat_out_base;    // 0x78
                6'h1F:  core_csr_rdata <= {29'b0, mat_err, mat_done, mat_busy}; // 0x7C MAT_STATUS
                6'h20:  core_csr_rdata <= err_pc_q;        // 0x80 ERR_PC
                default: core_csr_rdata <= 32'b0;
            endcase
        end
    end

endmodule
`default_nettype wire
