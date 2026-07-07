// npu_ml_ctrl.v — mat_engine v2 Phase A: hardware GEMM tile sequencer (ADR-0067).
//
// One job kick expands a whole K<=64 single-chunk GEMM's tile loop, driving
// mat_engine + npu_dma DIRECTLY (no firmware / no scalar spin-poll between tiles),
// attacking the measured ~1,120 cyc/tile firmware orchestration tax.
//
// SCOPE (Phase A, per mat_engine_v2_phaseA_design.md §9, review-corrected):
//   * serialized FSM, ISSUE->WAIT per step (mat/dma `done` are sticky-until-next-go).
//   * NO fifo, NO dma overlap, single acc bank, single K-chunk (K<=64).
//   * Per-tile transaction stream reproduces lower_layer_v2 EXACTLY (E1 oracle):
//       LOAD_W(dma) -> LOADACC(mat) -> OP(mat) -> RESCALE_PC(mat) -> STORE(wb)
//     NOTE: MAT_CFG is a firmware-only bookkeeping op (validates OP); it drives
//     NOTHING on mat_engine, so it is NOT a transaction and has no state here.
//   * per-CHANNEL requant (RESCALE_PC, cmd=4) with param blob ptr — GEMM is NOT
//     per-tensor. ACC preload is LOADACC(cmd=3) even when fold==0 (matches firmware).
//   * The standard K=64 blob layout (SHARED_BLOB/DST, TCM_BLOB region, A_OFF, param
//     off, out_base) is FROZEN in localparams below (SSOT-derived); only n_tiles is
//     CSR-programmed. This covers q/k/v/o/gate/up_proj (all K=64). Phase A.2 promotes
//     the layout constants to CSRs for K>64 / arbitrary blobs.
//
// INTEGRATION: npu_ml_ctrl owns its CSRs (decoded off the core-local window) and
// emits ml_active + ml-driven mat_*/dma_*/wb_* which npu_top MUXes in front of the
// npu_axil_regs outputs. ML_V2_EN=0 (default) => ml_active never asserts => the mux
// always selects the firmware path => zero regression, npu_axil_regs untouched.
`default_nettype none
module npu_ml_ctrl #(
    parameter integer ML_V2_EN = 0          // 0 => module inert (zero-regression default)
)(
    input  wire        clk,
    input  wire        resetn,              // domain_rstn
    input  wire        abort_i,             // npu_abort (ADR-0038/0047)

    // ---- core-local CSR window tap (same bus npu_axil_regs sees) ----
    input  wire        core_csr_en,
    input  wire        core_csr_we,
    input  wire [7:0]  core_csr_addr,
    input  wire [31:0] core_csr_wdata,
    output reg  [31:0] ml_csr_rdata,        // STATUS readback (registered, mirrors axil timing)
    output reg         ml_csr_hit,          // registered: 1 => npu_top muxes ml_csr_rdata

    // ---- engine/dma status back (for ISSUE->WAIT handshake) ----
    input  wire        mat_busy,
    input  wire        mat_done,
    input  wire        mat_err,             // param/exec error -> abort job (no hang)
    input  wire        dma_busy,            // read-mode busy (npu_top: dma_busy)
    input  wire        dma_done,            // read-mode done
    input  wire        dma_err,             // dma read/write error -> abort job
    input  wire        wb_busy,
    input  wire        wb_done,

    // ---- ml-driven mat_engine command (muxed in npu_top when ml_active) ----
    output reg  [31:0] ml_mat_a_addr,
    output reg  [31:0] ml_mat_b_addr,
    output reg  [31:0] ml_mat_mult,
    output reg  [31:0] ml_mat_rsp,
    output reg  [31:0] ml_mat_clamp,
    output reg  [31:0] ml_mat_out_base,
    output reg         ml_mat_go,
    output reg  [2:0]  ml_mat_cmd,
    output reg  [3:0]  ml_mat_bank,
    output reg  [7:0]  ml_mat_rpt,

    // ---- ml-driven dma (read) + writeback (write) ----
    output reg  [31:0] ml_dma_src,
    output reg  [31:0] ml_dma_dst,
    output reg  [16:0] ml_dma_len,
    output reg         ml_dma_go,
    output reg  [31:0] ml_wb_src,
    output reg  [31:0] ml_wb_dst,
    output reg  [16:0] ml_wb_len,
    output reg         ml_wb_go,

    output wire        ml_active,           // 1 => npu_top selects ml_* into mat/dma
    output wire        ml_irq               // 1-cycle pulse on job done (flags.irq)
);
    // ===== mat_engine command encodings (mirror mat_engine.v localparams) =====
    localparam [2:0] CMD_OP = 3'd1, CMD_RESCALE_PC = 3'd4, CMD_LOADACC = 3'd3;

    // ===== FROZEN K=64 standard-GEMM blob layout (SSOT: lower_layer_v2) =====
    //  Byte addresses carry the AXI high bit (0x8000_0000) for shared-mem sources.
    localparam [31:0] BLOB_BASE  = 32'h8000_2000;   // SHARED_BLOB_B | AXI
    localparam [31:0] JOB_STRIDE = 32'h0000_0800;   // JOB_STRIDE_B
    localparam [31:0] LOAD_DSTW  = 32'h0000_01C0;   // TCM_WEIGHT_W = 0x700>>2
    localparam [16:0] LOAD_LEN   = 17'd400;         // K=64 blob words (25 rows * 16)
    localparam [31:0] FOLD_PTR   = 32'h0000_0700;   // TCM_BLOB (LOADACC fold, zeros)
    localparam [31:0] OP_A_ADDR  = 32'h0000_0940;   // TCM_BLOB + A_OFF
    localparam [31:0] OP_B_ADDR  = 32'h0000_0B40;   // TCM_BLOB + A_OFF + 8*K
    localparam [7:0]  OP_RPT     = 8'd64;           // K
    localparam [31:0] PARAM_PTR  = 32'h0000_0720;   // TCM_BLOB + PARAM_OFF (per-channel)
    localparam [31:0] RSP_VAL    = 32'h0000_0000;   // (out_zp<<8)|shift ; PC shift from blob
    localparam [31:0] CLAMP_VAL  = 32'h0000_7F80;   // (max=127<<8)|(min=-128)
    localparam [31:0] OUT_BASE   = 32'h0000_0800;   // MAT_OUT_B (RESCALE dst in TCM)
    localparam [31:0] STORE_SRCW = 32'h0000_0200;   // MAT_OUT_B>>2 (wb src word)
    localparam [31:0] DST_BASE   = 32'h8000_1800;   // SHARED_DST_B | AXI
    localparam [31:0] DST_STRIDE = 32'h0000_0040;   // per-tile writeback spacing
    localparam [16:0] STORE_LEN  = 17'd16;          // 64 int8 = 16 words

    // ===== B1 activation-stationary (ADR-0067 Phase B) — selected by ML_JOB_CFG[1] =====
    //  Activation (same input for all tiles in a group) is loaded ONCE to a resident
    //  TCM slot = the freed Phase-A weight window (0xB40, past MAT_OUT/weights, below
    //  scratch). Per-tile blob shrinks to [header|weights] (272w, no activation), so
    //  weights land at 0x940 and OP a/b swap: a=resident act(0xB40), b=weights(0x940).
    localparam [31:0] ACT_SRC     = 32'h8000_1C00;  // resident-activation shared src
    localparam [31:0] ACT_DSTW    = 32'h0000_02D0;  // TCM_ACT 0xB40 >> 2
    localparam [16:0] ACT_LEN     = 17'd128;         // 8 rows x 64 K int8 = 512B
    localparam [16:0] LOAD_LEN_B1 = 17'd272;         // [header 0x240 | weights 512B]
    localparam [31:0] OP_A_B1     = 32'h0000_0B40;   // resident activation (a)
    localparam [31:0] OP_B_B1     = 32'h0000_0940;   // per-tile weights (b)

    // ===== B1.1 header-trim (ADR-0067 Phase B) — ML_JOB_CFG[2], requires [1] =====
    //  Drops the A_OFF header padding: per-tile blob = [fold|param|weights] tight.
    //  The A_OFF pad existed to jump the MAT_OUT(0x800) hole, so B1.1 also RELOCATES
    //  MAT_OUT above the weights (0x960). TCM map: fold 0x700, param 0x720, weights
    //  0x760(+512B->0x95F), MAT_OUT 0x960, resident act 0xB40.
    localparam [16:0] LOAD_LEN_T  = 17'd152;         // [fold|param|pad->0x60|weights 512B]
    localparam [31:0] OP_B_T      = 32'h0000_0760;   // tight weights (b)
    localparam [31:0] OUT_BASE_T  = 32'h0000_0960;   // MAT_OUT relocated above weights
    localparam [31:0] STORE_SRCW_T= 32'h0000_0258;   // 0x960 >> 2

    // ===== CSR offsets (core_csr_addr[7:2]); 0x21+ = 0x84+ are free =====
    localparam [5:0] A_NTILES = 6'h21;  // 0x84 RW  job tile count (n_groups*n_tiles)
    localparam [5:0] A_GO     = 6'h22;  // 0x88 WO  pulse [0]=go, [1]=irq_en
    localparam [5:0] A_CFG    = 6'h23;  // 0x8C RW  [0]=legacy_bypass
    localparam [5:0] A_STATUS = 6'h24;  // 0x90 RO  {busy,done,err, tile_idx}

    // ===== job registers =====
    reg [15:0] job_ntiles;
    reg        cfg_bypass;
    reg        stationary;   // ML_JOB_CFG[1]: B1 activation-stationary mode
    reg        tight;        // ML_JOB_CFG[2]: B1.1 header-trim (requires stationary)
    reg        irq_en;
    reg        job_busy, job_done_l, job_err;
    reg [15:0] tile_i;
    reg        busy_seen;   // ISSUE->WAIT: sticky-done guard (must see busy high first)

    wire csr_wr = core_csr_en && core_csr_we;
    wire [5:0] csr_a = core_csr_addr[7:2];

    // ---- CSR readback (STATUS only; registered to mirror npu_axil_regs' core read
    //      timing: value latched on the core_csr_en cycle, consumed the next cycle) ----
    wire [31:0] status_w = {13'b0, tile_i, job_err, job_done_l, job_busy};

    // ===== FSM =====
    localparam [3:0]
        S_IDLE=4'd0, S_LDW=4'd1, S_LDW_W=4'd2, S_CLR=4'd3, S_CLR_W=4'd4,
        S_OP=4'd5, S_OP_W=4'd6, S_RSC=4'd7, S_RSC_W=4'd8, S_STO=4'd9,
        S_STO_W=4'd10, S_NEXT=4'd11, S_ABORT=4'd12, S_DONE=4'd13,
        S_LOADA=4'd14, S_LOADA_W=4'd15;   // B1: one-time activation load
    reg [3:0] state;

    // per-tile varying addresses
    wire [31:0] load_src = BLOB_BASE + {16'b0, tile_i} * JOB_STRIDE;  // job blob src
    wire [31:0] store_dst = DST_BASE + {16'b0, tile_i} * DST_STRIDE;  // writeback dst

    assign ml_active = (ML_V2_EN != 0) && job_busy && !cfg_bypass;
    assign ml_irq = (state == S_DONE) && irq_en;

    // ISSUE->WAIT handshake helpers: `done` is sticky-until-next-go, so a WAIT
    // state must first observe `busy` high (= this go accepted) before it may treat
    // `!busy` as retirement. busy_seen is cleared on entry to each ISSUE state.
    always @(posedge clk) begin
        if (!resetn) begin
            state <= S_IDLE; job_busy <= 1'b0; job_done_l <= 1'b0; job_err <= 1'b0;
            tile_i <= 16'b0; job_ntiles <= 16'b0; cfg_bypass <= 1'b0; irq_en <= 1'b0;
            stationary <= 1'b0; tight <= 1'b0;
            busy_seen <= 1'b0; ml_csr_hit <= 1'b0; ml_csr_rdata <= 32'b0;
            ml_mat_go <= 1'b0; ml_dma_go <= 1'b0; ml_wb_go <= 1'b0;
            ml_mat_cmd <= 3'b0; ml_mat_bank <= 4'b0; ml_mat_rpt <= 8'b0;
            ml_mat_a_addr <= 32'b0; ml_mat_b_addr <= 32'b0; ml_mat_mult <= 32'b0;
            ml_mat_rsp <= 32'b0; ml_mat_clamp <= 32'b0; ml_mat_out_base <= 32'b0;
            ml_dma_src <= 32'b0; ml_dma_dst <= 32'b0; ml_dma_len <= 17'b0;
            ml_wb_src <= 32'b0; ml_wb_dst <= 32'b0; ml_wb_len <= 17'b0;
        end else begin
            // default: de-assert all one-cycle go pulses every cycle
            ml_mat_go <= 1'b0; ml_dma_go <= 1'b0; ml_wb_go <= 1'b0;

            // ---- registered STATUS readback (mirrors npu_axil_regs core read: latch
            //      on the core_csr_en cycle so it is valid the next, consume, cycle) ----
            if (core_csr_en) begin
                ml_csr_hit   <= (ML_V2_EN != 0) && !core_csr_we && (csr_a == A_STATUS);
                ml_csr_rdata <= status_w;
            end

            // ---- CSR writes (always decoded; the GO effect is ML_V2_EN-gated) ----
            if (csr_wr) begin
                case (csr_a)
                    A_NTILES: job_ntiles <= core_csr_wdata[15:0];
                    A_CFG: begin cfg_bypass <= core_csr_wdata[0];
                                 stationary <= core_csr_wdata[1];       // B1
                                 tight      <= core_csr_wdata[2]; end   // B1.1
                    // start only when NOT bypassed (else mux drops ml_*_go -> hang, Codex P1)
                    A_GO: if ((ML_V2_EN != 0) && !job_busy && core_csr_wdata[0]
                              && !abort_i && !cfg_bypass) begin
                              job_busy <= 1'b1; job_done_l <= 1'b0; job_err <= 1'b0;
                              tile_i <= 16'b0; irq_en <= core_csr_wdata[1];
                              // B1: load the resident activation once before the tile loop
                              busy_seen <= 1'b0; state <= stationary ? S_LOADA : S_LDW;
                          end
                    default: ;
                endcase
            end

            if (abort_i && job_busy) begin
                // ---- abort priority: stop issuing; wait engines quiet; report ABORTED ----
                if (!mat_busy && !dma_busy && !wb_busy) begin
                    job_busy <= 1'b0; job_err <= 1'b1; state <= S_IDLE;
                end else begin
                    state <= S_ABORT;
                end
            end else begin
                case (state)
                    S_IDLE: ;   // wait for A_GO

                    // B1 activation-stationary: DMA the resident activation ONCE
                    // (per job here; per-group when n_groups>1 = B1.2) before the loop.
                    S_LOADA: begin
                        ml_dma_src <= ACT_SRC; ml_dma_dst <= ACT_DSTW; ml_dma_len <= ACT_LEN;
                        ml_dma_go <= 1'b1; busy_seen <= 1'b0; state <= S_LOADA_W;
                    end
                    S_LOADA_W: begin
                        if (dma_err) begin job_err <= 1'b1; job_busy <= 1'b0; state <= S_IDLE; end
                        else if (dma_busy) busy_seen <= 1'b1;
                        else if (busy_seen && dma_done) state <= S_LDW;
                    end

                    // ISSUE states: latch operands + pulse go, clear busy_seen.
                    S_LDW: begin
                        ml_dma_src <= load_src; ml_dma_dst <= LOAD_DSTW;
                        ml_dma_len <= tight ? LOAD_LEN_T
                                    : stationary ? LOAD_LEN_B1 : LOAD_LEN;   // B1/B1.1
                        ml_dma_go <= 1'b1; busy_seen <= 1'b0; state <= S_LDW_W;
                    end
                    S_LDW_W: begin
                        if (dma_err) begin job_err <= 1'b1; job_busy <= 1'b0; state <= S_IDLE; end
                        else if (dma_busy) busy_seen <= 1'b1;
                        else if (busy_seen && dma_done) state <= S_CLR;
                    end

                    S_CLR: begin
                        ml_mat_cmd <= CMD_LOADACC; ml_mat_bank <= 4'd0; ml_mat_rpt <= 8'd1;
                        ml_mat_a_addr <= FOLD_PTR;
                        ml_mat_go <= 1'b1; busy_seen <= 1'b0; state <= S_CLR_W;
                    end
                    S_CLR_W: begin
                        if (mat_err) begin job_err <= 1'b1; job_busy <= 1'b0; state <= S_IDLE; end
                        else if (mat_busy) busy_seen <= 1'b1;
                        else if (busy_seen && mat_done) state <= S_OP;
                    end

                    S_OP: begin
                        ml_mat_cmd <= CMD_OP; ml_mat_bank <= 4'd0; ml_mat_rpt <= OP_RPT;
                        // B1: a=resident activation(0xB40), b=per-tile weights(0x940)
                        ml_mat_a_addr <= stationary ? OP_A_B1 : OP_A_ADDR;
                        ml_mat_b_addr <= tight ? OP_B_T
                                       : stationary ? OP_B_B1 : OP_B_ADDR;
                        ml_mat_go <= 1'b1; busy_seen <= 1'b0; state <= S_OP_W;
                    end
                    S_OP_W: begin
                        if (mat_err) begin job_err <= 1'b1; job_busy <= 1'b0; state <= S_IDLE; end
                        else if (mat_busy) busy_seen <= 1'b1;
                        else if (busy_seen && mat_done) state <= S_RSC;
                    end

                    S_RSC: begin
                        ml_mat_cmd <= CMD_RESCALE_PC; ml_mat_bank <= 4'd0; ml_mat_rpt <= 8'd1;
                        ml_mat_mult <= PARAM_PTR; ml_mat_rsp <= RSP_VAL; ml_mat_clamp <= CLAMP_VAL;
                        ml_mat_out_base <= tight ? OUT_BASE_T : OUT_BASE;   // B1.1 relocates MAT_OUT
                        ml_mat_go <= 1'b1; busy_seen <= 1'b0; state <= S_RSC_W;
                    end
                    S_RSC_W: begin
                        if (mat_err) begin job_err <= 1'b1; job_busy <= 1'b0; state <= S_IDLE; end
                        else if (mat_busy) busy_seen <= 1'b1;
                        else if (busy_seen && mat_done) state <= S_STO;
                    end

                    S_STO: begin
                        ml_wb_src <= tight ? STORE_SRCW_T : STORE_SRCW;
                        ml_wb_dst <= store_dst; ml_wb_len <= STORE_LEN;
                        ml_wb_go <= 1'b1; busy_seen <= 1'b0; state <= S_STO_W;
                    end
                    S_STO_W: begin
                        if (dma_err) begin job_err <= 1'b1; job_busy <= 1'b0; state <= S_IDLE; end
                        else if (wb_busy) busy_seen <= 1'b1;
                        else if (busy_seen && wb_done) state <= S_NEXT;
                    end

                    S_NEXT: begin
                        if (tile_i + 16'd1 >= job_ntiles) state <= S_DONE;
                        else begin tile_i <= tile_i + 16'd1; state <= S_LDW; end
                    end

                    S_DONE: begin
                        job_busy <= 1'b0; job_done_l <= 1'b1; state <= S_IDLE;
                    end

                    S_ABORT: begin
                        if (!mat_busy && !dma_busy && !wb_busy) begin
                            job_busy <= 1'b0; job_err <= 1'b1; state <= S_IDLE;
                        end
                    end

                    default: state <= S_IDLE;
                endcase
            end
        end
    end
endmodule
`default_nettype wire
