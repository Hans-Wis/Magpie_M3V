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
// ADR-0073 D2 strip-streaming extension (CSR offsets in this ml_ctrl block):
//   0x94 ML_MODE        RW bit0 STRIP_EN (0 = legacy K=64 path; reset/default 0)
//   0x98 ML_W_BASE      RW DDR byte address, 4KB aligned at kick
//   0x9C ML_STRIP_BYTES RW [16:0], 1..40960 at kick
//   0xA0 ML_N_STRIPS    RW [11:0], nonzero at kick
//   0xA4 ML_K_CHUNKS    RW [7:0]=K_CHUNKS, [14:8]=K_TAIL (1..64)
//   0xA8 ML_N_TAIL      RW [6:0], 1..64 and multiple of 8 in strip mode
//   New ERR_CAUSE namespace addendum: ML_STRIP_DMA_ERR = 0x0000_0009.
//
// ADR-0073 D4 strip-local layout addendum (frozen): chunk-major then 8-col
// sub-tile. offset(c,t)=c*4096+t*512, where each 512B block is 64 k-rows x
// 8 cols, k-major [k][8], identical to the Phase-A engine B tile. Sub-tile t
// covers strip columns t*8..t*8+7. Strip-mode per-channel params live at
// STRIP_PARAM_PTR=0x1200 as consecutive 64B blocks (40B params + 24B pad) —
// keeps each block 32B-aligned so mat_engine's frozen RESCALE_PC alignment
// contract (rs_mult[4:0]==0) holds; indexed by global sub-tile
// (strip*8+t); this avoids the 0x720..0x9bf collision with OP_A_ADDR=0x940.
// STORE writes one Phase-A 8x8 output block per sub-tile at
// DST_BASE+(strip*8+t)*64.
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
    input  wire        strip_busy,
    input  wire        strip_done,
    input  wire        strip_err,

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

    // ---- ml-driven strip prefetch + strip buffer control (ADR-0073) ----
    output reg         ml_strip_start,
    output reg  [31:0] ml_strip_addr,
    output reg  [16:0] ml_strip_bytes,
    output reg         ml_strip_bank,
    output reg         ml_strip_clear,
    output wire        ml_strip_active,
    output wire        ml_strip_compute_bank,
    output wire [15:0] ml_strip_weight_base,

    // ---- synthetic core-local ERR_CAUSE write into npu_axil_regs ----
    output reg         ml_err_cause_we,
    output reg  [31:0] ml_err_cause,

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
    localparam [31:0] STRIP_A_STEP = 32'h0000_0200; // 64 K-values x 8 activation rows
    localparam [16:0] STRIP_BYTES_MAX = 17'd40960;
    localparam [31:0] STRIP_PARAM_PTR = 32'h0000_1200; // D4 strip params, 64B * global sub-tile
    localparam [31:0] ML_STRIP_DMA_ERR = 32'd9;

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
    localparam [5:0] A_MODE   = 6'h25;  // 0x94 RW  [0]=STRIP_EN
    localparam [5:0] A_WBASE  = 6'h26;  // 0x98 RW  strip DDR base byte address
    localparam [5:0] A_SBYTES = 6'h27;  // 0x9C RW  strip byte count
    localparam [5:0] A_NSTRIP = 6'h28;  // 0xA0 RW  number of strips
    localparam [5:0] A_KCHUNK = 6'h29;  // 0xA4 RW  [7:0]=chunks [14:8]=tail
    localparam [5:0] A_NTAIL  = 6'h2A;  // 0xA8 RW  final-strip output bytes

    // ===== job registers =====
    reg [15:0] job_ntiles;
    reg        cfg_bypass;
    reg        stationary;   // ML_JOB_CFG[1]: B1 activation-stationary mode
    reg        tight;        // ML_JOB_CFG[2]: B1.1 header-trim (requires stationary)
    reg        irq_en;
    reg        job_busy, job_done_l, job_err;
    reg [15:0] tile_i;
    reg        busy_seen;   // ISSUE->WAIT: sticky-done guard (must see busy high first)
    reg        mode_strip;
    reg [31:0] strip_w_base_q;
    reg [16:0] strip_bytes_q;
    reg [11:0] strip_n_strips_q;
    reg [7:0]  strip_k_chunks_q;
    reg [6:0]  strip_k_tail_q;
    reg [6:0]  strip_n_tail_q;
    reg [11:0] strip_i;
    reg [7:0]  strip_chunk_i;
    reg [2:0]  strip_subtile_i;
    reg        strip_compute_bank_q;
    reg        strip_prefetch_pending;
    reg        strip_prefetch_done_l;
    reg        strip_busy_seen;
    reg        strip_dma_fault_l;
    reg [15:0] strip_weight_base_q;
    reg [4:0]  state_d;
    reg        strip_compute_bank_d;

    wire csr_wr = core_csr_en && core_csr_we;
    wire [5:0] csr_a = core_csr_addr[7:2];

    // ---- CSR readback (STATUS only; registered to mirror npu_axil_regs' core read
    //      timing: value latched on the core_csr_en cycle, consumed the next cycle) ----
    wire [31:0] status_w = {13'b0, tile_i, job_err, job_done_l, job_busy};
    wire ml_csr_sel = (csr_a == A_STATUS) || (csr_a == A_MODE) ||
                      (csr_a == A_WBASE)  || (csr_a == A_SBYTES) ||
                      (csr_a == A_NSTRIP) || (csr_a == A_KCHUNK) ||
                      (csr_a == A_NTAIL);
    wire strip_k_tail_bad = (strip_k_tail_q == 7'd0) || (strip_k_tail_q > 7'd64);
    wire strip_n_tail_bad = (strip_n_tail_q == 7'd0) || (strip_n_tail_q > 7'd64) ||
                            (strip_n_tail_q[2:0] != 3'd0);
    wire strip_kick_illegal = mode_strip &&
                              ((strip_w_base_q[11:0] != 12'b0) ||
                               (strip_n_strips_q == 12'd0) ||
                               (strip_bytes_q == 17'd0) ||
                               (strip_bytes_q > STRIP_BYTES_MAX) ||
                               (strip_k_chunks_q == 8'd0) ||
                               strip_k_tail_bad || strip_n_tail_bad ||
                               (job_ntiles != 16'd0));
    wire [31:0] strip_idx_w = {20'b0, strip_i};
    wire [31:0] strip_next_idx_w = {20'b0, strip_i} + 32'd1;
    wire [31:0] strip_prefetch_addr_w =
        strip_w_base_q + (strip_next_idx_w * {15'b0, strip_bytes_q});
    wire [31:0] strip_global_subtile_w =
        (strip_idx_w << 3) + {29'b0, strip_subtile_i};
    wire [31:0] strip_store_dst_w = DST_BASE + (strip_global_subtile_w * DST_STRIDE);
    wire [31:0] strip_param_ptr_w = STRIP_PARAM_PTR + (strip_global_subtile_w * 32'd64);
    wire        strip_last_w = ((strip_i + 12'd1) >= strip_n_strips_q);
    wire        strip_subtile_last_w =
        strip_last_w ? (({1'b0, strip_subtile_i} + 4'd1) >= {1'b0, strip_n_tail_q[6:3]}) :
                       (strip_subtile_i == 3'd7);
    wire        strip_chunk_last_w =
        ((strip_chunk_i + 8'd1) >= strip_k_chunks_q);
    wire [7:0]  strip_op_rpt_w =
        strip_chunk_last_w ? {1'b0, strip_k_tail_q} : 8'd64;
    wire [31:0] strip_a_addr_w =
        OP_A_ADDR + ({24'b0, strip_chunk_i} * STRIP_A_STEP);
    wire [15:0] strip_weight_base_w =
        {strip_chunk_i[3:0], 12'b0} + {4'b0, strip_subtile_i, 9'b0};

    // ===== FSM =====
    localparam [4:0]
        S_IDLE=5'd0, S_LDW=5'd1, S_LDW_W=5'd2, S_CLR=5'd3, S_CLR_W=5'd4,
        S_OP=5'd5, S_OP_W=5'd6, S_RSC=5'd7, S_RSC_W=5'd8, S_STO=5'd9,
        S_STO_W=5'd10, S_NEXT=5'd11, S_ABORT=5'd12, S_DONE=5'd13,
        S_LOADA=5'd14, S_LOADA_W=5'd15,   // B1: one-time activation load
        S_STRIP_PREFILL=5'd16, S_STRIP_PREFILL_W=5'd17,
        S_STRIP_BEGIN=5'd18, S_STRIP_CLR_W=5'd19,
        S_STRIP_OP=5'd20, S_STRIP_OP_W=5'd21,
        S_STRIP_RSC=5'd22, S_STRIP_RSC_W=5'd23,
        S_STRIP_STO_WAIT=5'd24, S_STRIP_STO=5'd25, S_STRIP_STO_W=5'd26,
        S_STRIP_RV=5'd27, S_STRIP_ADV=5'd28, S_STRIP_DRAIN_ERR=5'd29,
        S_STRIP_TILE=5'd30;
    reg [4:0] state;

    // per-tile varying addresses
    wire [31:0] load_src = BLOB_BASE + {16'b0, tile_i} * JOB_STRIDE;  // job blob src
    wire [31:0] store_dst = DST_BASE + {16'b0, tile_i} * DST_STRIDE;  // writeback dst

    assign ml_active = (ML_V2_EN != 0) && job_busy && !cfg_bypass;
    assign ml_irq = (state == S_DONE) && irq_en;
    assign ml_strip_active = (ML_V2_EN != 0) && job_busy && !cfg_bypass && mode_strip;
    assign ml_strip_compute_bank = strip_compute_bank_q;
    assign ml_strip_weight_base = strip_weight_base_q;

    // ISSUE->WAIT handshake helpers: `done` is sticky-until-next-go, so a WAIT
    // state must first observe `busy` high (= this go accepted) before it may treat
    // `!busy` as retirement. busy_seen is cleared on entry to each ISSUE state.
    always @(posedge clk) begin
        if (!resetn) begin
            state <= S_IDLE; job_busy <= 1'b0; job_done_l <= 1'b0; job_err <= 1'b0;
            tile_i <= 16'b0; job_ntiles <= 16'b0; cfg_bypass <= 1'b0; irq_en <= 1'b0;
            stationary <= 1'b0; tight <= 1'b0;
            mode_strip <= 1'b0; strip_w_base_q <= 32'b0; strip_bytes_q <= 17'b0;
            strip_n_strips_q <= 12'b0; strip_k_chunks_q <= 8'b0;
            strip_k_tail_q <= 7'b0; strip_n_tail_q <= 7'b0;
            strip_i <= 12'b0; strip_chunk_i <= 8'b0; strip_subtile_i <= 3'b0;
            strip_compute_bank_q <= 1'b0;
            strip_prefetch_pending <= 1'b0; strip_prefetch_done_l <= 1'b0;
            strip_busy_seen <= 1'b0; strip_dma_fault_l <= 1'b0;
            strip_weight_base_q <= 16'b0;
            busy_seen <= 1'b0; ml_csr_hit <= 1'b0; ml_csr_rdata <= 32'b0;
            ml_mat_go <= 1'b0; ml_dma_go <= 1'b0; ml_wb_go <= 1'b0;
            ml_strip_start <= 1'b0; ml_strip_addr <= 32'b0; ml_strip_bytes <= 17'b0;
            ml_strip_bank <= 1'b0; ml_strip_clear <= 1'b0;
            ml_err_cause_we <= 1'b0; ml_err_cause <= 32'b0;
            ml_mat_cmd <= 3'b0; ml_mat_bank <= 4'b0; ml_mat_rpt <= 8'b0;
            ml_mat_a_addr <= 32'b0; ml_mat_b_addr <= 32'b0; ml_mat_mult <= 32'b0;
            ml_mat_rsp <= 32'b0; ml_mat_clamp <= 32'b0; ml_mat_out_base <= 32'b0;
            ml_dma_src <= 32'b0; ml_dma_dst <= 32'b0; ml_dma_len <= 17'b0;
            ml_wb_src <= 32'b0; ml_wb_dst <= 32'b0; ml_wb_len <= 17'b0;
        end else begin
            // default: de-assert all one-cycle go pulses every cycle
            ml_mat_go <= 1'b0; ml_dma_go <= 1'b0; ml_wb_go <= 1'b0;
            ml_strip_start <= 1'b0; ml_strip_clear <= 1'b0;
            ml_err_cause_we <= 1'b0;

            if (strip_prefetch_pending) begin
                if (strip_busy)
                    strip_busy_seen <= 1'b1;
                if (strip_busy_seen && strip_done) begin
                    strip_prefetch_done_l <= 1'b1;
                    strip_prefetch_pending <= 1'b0;
                end
                if (strip_err)
                    strip_dma_fault_l <= 1'b1;
            end

            // ---- registered STATUS readback (mirrors npu_axil_regs core read: latch
            //      on the core_csr_en cycle so it is valid the next, consume, cycle) ----
            if (core_csr_en) begin
                ml_csr_hit <= (ML_V2_EN != 0) && !core_csr_we && ml_csr_sel;
                case (csr_a)
                    A_STATUS: ml_csr_rdata <= status_w;
                    A_MODE:   ml_csr_rdata <= {31'b0, mode_strip};
                    A_WBASE:  ml_csr_rdata <= strip_w_base_q;
                    A_SBYTES: ml_csr_rdata <= {15'b0, strip_bytes_q};
                    A_NSTRIP: ml_csr_rdata <= {20'b0, strip_n_strips_q};
                    A_KCHUNK: ml_csr_rdata <= {17'b0, strip_k_tail_q, strip_k_chunks_q};
                    A_NTAIL:  ml_csr_rdata <= {25'b0, strip_n_tail_q};
                    default:  ml_csr_rdata <= 32'b0;
                endcase
            end

            // ---- CSR writes (always decoded; the GO effect is ML_V2_EN-gated) ----
            if (csr_wr) begin
                case (csr_a)
                    A_NTILES: job_ntiles <= core_csr_wdata[15:0];
                    A_CFG: begin cfg_bypass <= core_csr_wdata[0];
                                 stationary <= core_csr_wdata[1];       // B1
                                 tight      <= core_csr_wdata[2]; end   // B1.1
                    A_MODE:   mode_strip <= core_csr_wdata[0];
                    A_WBASE:  strip_w_base_q <= core_csr_wdata;
                    A_SBYTES: strip_bytes_q <= core_csr_wdata[16:0];
                    A_NSTRIP: strip_n_strips_q <= core_csr_wdata[11:0];
                    A_KCHUNK: begin
                                  strip_k_chunks_q <= core_csr_wdata[7:0];
                                  strip_k_tail_q <= core_csr_wdata[14:8];
                              end
                    A_NTAIL:  strip_n_tail_q <= core_csr_wdata[6:0];
                    // start only when NOT bypassed (else mux drops ml_*_go -> hang, Codex P1)
                    A_GO: if ((ML_V2_EN != 0) && !job_busy && core_csr_wdata[0]
                              && !abort_i && !cfg_bypass) begin
                              job_done_l <= 1'b0; irq_en <= core_csr_wdata[1];
                              tile_i <= 16'b0; strip_i <= 12'b0; strip_chunk_i <= 8'b0;
                              strip_subtile_i <= 3'b0;
                              strip_compute_bank_q <= 1'b0; strip_prefetch_pending <= 1'b0;
                              strip_prefetch_done_l <= 1'b0; strip_busy_seen <= 1'b0;
                              strip_dma_fault_l <= 1'b0; strip_weight_base_q <= 16'b0;
                              ml_strip_clear <= 1'b1;
                              if (strip_kick_illegal) begin
                                  job_busy <= 1'b0; job_err <= 1'b1; state <= S_IDLE;
                              end else begin
                                  job_busy <= 1'b1; job_err <= 1'b0; busy_seen <= 1'b0;
                                  // B1: load the resident activation once before the tile loop
                                  state <= mode_strip ? S_STRIP_PREFILL :
                                           (stationary ? S_LOADA : S_LDW);
                              end
                          end
                    default: ;
                endcase
            end

            if (abort_i && job_busy) begin
                // ---- abort priority: stop issuing; wait engines quiet; report ABORTED ----
                ml_strip_clear <= 1'b1;
                strip_prefetch_pending <= 1'b0; strip_prefetch_done_l <= 1'b0;
                strip_busy_seen <= 1'b0; strip_dma_fault_l <= 1'b0;
                if (!mat_busy && !dma_busy && !wb_busy && !strip_busy) begin
                    job_busy <= 1'b0; job_err <= 1'b1; state <= S_IDLE;
                end else begin
                    state <= S_ABORT;
                end
            end else begin
                if (mode_strip && strip_dma_fault_l && (state != S_STRIP_DRAIN_ERR)) begin
                    state <= S_STRIP_DRAIN_ERR;
                end else case (state)
                    S_IDLE: ;   // wait for A_GO

                    // ADR-0073 cold-start: synchronously prefill bank0 before compute.
                    S_STRIP_PREFILL: begin
                        ml_strip_addr <= strip_w_base_q;
                        ml_strip_bytes <= strip_bytes_q;
                        ml_strip_bank <= 1'b0;
                        ml_strip_start <= 1'b1;
                        strip_busy_seen <= 1'b0;
                        strip_prefetch_pending <= 1'b1;
                        strip_prefetch_done_l <= 1'b0;
                        state <= S_STRIP_PREFILL_W;
                    end
                    S_STRIP_PREFILL_W: begin
                        if (strip_err) begin
                            strip_dma_fault_l <= 1'b1;
                            state <= S_STRIP_DRAIN_ERR;
                        end else if (strip_busy) begin
                            strip_busy_seen <= 1'b1;
                        end else if (strip_busy_seen && strip_done) begin
                            strip_prefetch_pending <= 1'b0;
                            strip_prefetch_done_l <= 1'b1;
                            strip_busy_seen <= 1'b0;
                            state <= S_STRIP_BEGIN;
                        end
                    end

                    // Start next-bank prefetch at the strip boundary.
                    S_STRIP_BEGIN: begin
                        if (!strip_last_w) begin
                            ml_strip_addr <= strip_prefetch_addr_w;
                            ml_strip_bytes <= strip_bytes_q;
                            ml_strip_bank <= ~strip_compute_bank_q;
                            ml_strip_start <= 1'b1;
                            strip_prefetch_pending <= 1'b1;
                            strip_prefetch_done_l <= 1'b0;
                            strip_busy_seen <= 1'b0;
                        end else begin
                            strip_prefetch_pending <= 1'b0;
                            strip_prefetch_done_l <= 1'b1;
                            strip_busy_seen <= 1'b0;
                        end
                        strip_subtile_i <= 3'd0;
                        state <= S_STRIP_TILE;
                    end

                    S_STRIP_TILE: begin
                        ml_mat_cmd <= CMD_LOADACC; ml_mat_bank <= 4'd0; ml_mat_rpt <= 8'd1;
                        ml_mat_a_addr <= FOLD_PTR;
                        ml_mat_go <= 1'b1; busy_seen <= 1'b0;
                        strip_chunk_i <= 8'd0;
                        state <= S_STRIP_CLR_W;
                    end
                    S_STRIP_CLR_W: begin
                        if (mat_err) begin job_err <= 1'b1; job_busy <= 1'b0; state <= S_IDLE; end
                        else if (mat_busy) busy_seen <= 1'b1;
                        else if (busy_seen && mat_done) state <= S_STRIP_OP;
                    end

                    S_STRIP_OP: begin
                        ml_mat_cmd <= CMD_OP; ml_mat_bank <= 4'd0; ml_mat_rpt <= strip_op_rpt_w;
                        ml_mat_a_addr <= strip_a_addr_w;
                        ml_mat_b_addr <= 32'b0;
                        strip_weight_base_q <= strip_weight_base_w;
                        ml_mat_go <= 1'b1; busy_seen <= 1'b0; state <= S_STRIP_OP_W;
                    end
                    S_STRIP_OP_W: begin
                        if (mat_err) begin job_err <= 1'b1; job_busy <= 1'b0; state <= S_IDLE; end
                        else if (mat_busy) busy_seen <= 1'b1;
                        else if (busy_seen && mat_done) begin
                            if (strip_chunk_last_w) state <= S_STRIP_RSC;
                            else begin strip_chunk_i <= strip_chunk_i + 8'd1; state <= S_STRIP_OP; end
                        end
                    end

                    S_STRIP_RSC: begin
                        ml_mat_cmd <= CMD_RESCALE_PC; ml_mat_bank <= 4'd0; ml_mat_rpt <= 8'd1;
                        ml_mat_mult <= strip_param_ptr_w; ml_mat_rsp <= RSP_VAL; ml_mat_clamp <= CLAMP_VAL;
                        ml_mat_out_base <= OUT_BASE;
                        ml_mat_go <= 1'b1; busy_seen <= 1'b0; state <= S_STRIP_RSC_W;
                    end
                    S_STRIP_RSC_W: begin
                        if (mat_err) begin job_err <= 1'b1; job_busy <= 1'b0; state <= S_IDLE; end
                        else if (mat_busy) busy_seen <= 1'b1;
                        else if (busy_seen && mat_done) state <= S_STRIP_STO_WAIT;
                    end

                    // npu_dma is a single engine. Do not drop STORE while the
                    // next-strip read chain is still occupying it.
                    S_STRIP_STO_WAIT: begin
                        if (strip_prefetch_done_l) state <= S_STRIP_STO;
                    end
                    S_STRIP_STO: begin
                        ml_wb_src <= STORE_SRCW;
                        ml_wb_dst <= strip_store_dst_w;
                        ml_wb_len <= STORE_LEN;
                        ml_wb_go <= 1'b1; busy_seen <= 1'b0; state <= S_STRIP_STO_W;
                    end
                    S_STRIP_STO_W: begin
                        if (dma_err) begin job_err <= 1'b1; job_busy <= 1'b0; state <= S_IDLE; end
                        else if (wb_busy) busy_seen <= 1'b1;
                        else if (busy_seen && wb_done) begin
                            if (strip_subtile_last_w) state <= S_STRIP_RV;
                            else begin
                                strip_subtile_i <= strip_subtile_i + 3'd1;
                                state <= S_STRIP_TILE;
                            end
                        end
                    end

                    S_STRIP_RV: begin
                        if (strip_prefetch_done_l) begin
                            if (strip_last_w) state <= S_DONE;
                            else state <= S_STRIP_ADV;
                        end
                    end
                    S_STRIP_ADV: begin
                        strip_i <= strip_i + 12'd1;
                        strip_compute_bank_q <= ~strip_compute_bank_q;
                        strip_prefetch_done_l <= 1'b0;
                        strip_prefetch_pending <= 1'b0;
                        strip_busy_seen <= 1'b0;
                        state <= S_STRIP_BEGIN;
                    end

                    S_STRIP_DRAIN_ERR: begin
                        if (!mat_busy) begin
                            ml_strip_clear <= 1'b1;
                            ml_err_cause_we <= 1'b1;
                            ml_err_cause <= ML_STRIP_DMA_ERR;
                            job_busy <= 1'b0;
                            job_err <= 1'b1;
                            strip_prefetch_pending <= 1'b0;
                            strip_prefetch_done_l <= 1'b0;
                            strip_busy_seen <= 1'b0;
                            strip_dma_fault_l <= 1'b0;
                            state <= S_IDLE;
                        end
                    end

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
                        if (!mat_busy && !dma_busy && !wb_busy && !strip_busy) begin
                            job_busy <= 1'b0; job_err <= 1'b1; state <= S_IDLE;
                        end
                    end

                    default: state <= S_IDLE;
                endcase
            end
        end
    end

    always @(posedge clk) begin
        if (!resetn) begin
            state_d <= S_IDLE;
            strip_compute_bank_d <= 1'b0;
        end else begin
            if ((strip_compute_bank_q != strip_compute_bank_d) &&
                (state_d != S_STRIP_ADV))
                $fatal(1, "npu_ml_ctrl: strip bank swapped outside rendezvous");
            state_d <= state;
            strip_compute_bank_d <= strip_compute_bank_q;
        end
    end
endmodule
`default_nettype wire
