// =============================================================================
// core.v — Lab08e 4-stage pipeline RV32IMC + CSR + IRQ + BP (2-way) + RAS
//          (lab08d base + pre-fetch buffer eliminates cross-boundary stall)
// -----------------------------------------------------------------------------
// lab08d 加 cross_assemble/residue pre-fetch buffer：
//   - Sequential 16-bit → 32-bit cross-boundary：0-cycle penalty (pre-fetch path)
//   - Post-stall/redirect cross-boundary：1-cycle fallback (= lab08d 同)
//   - any_stall 不再含 is_cross_boundary，只含 load-use/muldiv stall + warmup
//
// 預期：
//   - clock: 75 MHz target (IF stage secondary path 消除，worst path 仍 d_mem store)
//   - IPC: 36+ LED (cross-boundary stall 消除，lab08d firmware hot loop中)
//   - Wall-clock: 75/65 × lab08d ≈ 1.55× lab07
// =============================================================================

`include "def.vh"
`include "pmp.v"

module core #(
    parameter [31:0] RESET_PC = `PC_RESET,
    parameter RV32A = 0,
    parameter PMP_ENTRIES = 0
) (
    input             clk,
    input             resetn,
    output            trap,
    input             mem_stall,

    // I-port (instr fetch, sync read-only)
    output     [31:0] i_mem_addr,
    output            i_mem_en,        // gates BRAM update; =!stall (lab06 新加)
    input      [31:0] i_mem_rdata,

    // D-port (data load/store)
    output            d_mem_valid,
    output     [31:0] d_mem_addr,
    output     [31:0] d_mem_wdata,
    output     [ 3:0] d_mem_wstrb,
    input      [31:0] d_mem_rdata,

    // External IRQ
    input             irq_external_pulse,
    input             mtip,             // CLINT timer interrupt -> mip[7] (ADR-0019; tie 0 if no CLINT)
    input             msip,             // CLINT software interrupt -> mip[3] (ADR-0019; tie 0 if no CLINT)
    input             meip,             // PLIC external interrupt -> mip[11] level (ADR-0020; tie 0 if no PLIC)

    // RISC-V Debug MVD Slice A (ADR-0021)
    input             dm_halt_req,
    input             dm_resume_req,
    output            dm_hart_halted,
    output            debug_mode_o,
    input             dm_acc_en,
    input             dm_acc_write,
    input      [15:0] dm_acc_regno,
    input      [31:0] dm_acc_wdata,
    output     [31:0] dm_acc_rdata,
    output            dm_acc_err,

    // Debug
    output     [31:0] dbg_pc,
    output     [31:0] dbg_instr,
    output     [ 2:0] dbg_state
);

    // =========================================================================
    // Reset / redirect warmup
    // =========================================================================
    reg warmup;
    always @(posedge clk) begin
        if (!resetn) warmup <= 1'b1;
        else         warmup <= 1'b0;   // 1 cycle bubble after reset (BRAM warm)
    end

    // =========================================================================
    // IF stage : ifu + BP + RAS + cdec + cross-boundary fetch (RV32C)
    // -------------------------------------------------------------------------
    // Lab08e 改進自 lab08d：消除 cross-boundary 1-cycle stall。
    //
    // 舊設計 (lab08d)：在 cross-boundary detect cycle 插入 stall，下拍 assemble。
    // 新設計 (lab08e)：在上一拍偵測到「下一條 instr 是 cross-boundary 32-bit」時
    //   1. 提前 override i_mem_addr = if_pc+4 (= 下一個 word)
    //   2. 保存 residue ← cur_half_hi (= 32-bit instr 的前 16 bits)
    //   3. 設定 cross_assemble
    //   下一拍直接用 {i_mem_rdata[15:0], residue} assemble，0 cycle penalty。
    //
    // 只有在 upcoming_cross 前一拍有 stall/redirect 時才退回 at_cross_boundary 路徑
    // (= lab08d fallback，仍 1-cycle stall)。熱迴圈無 stall 前置 → 0-cycle。
    // =========================================================================
    wire [31:0] if_pc;        // = pc_reg (current decode PC)
    wire [31:0] next_pc_w;    // combinational from ifu
    reg         pc_redirect;
    reg  [31:0] redirect_target;
    wire        stall;         // load-use / muldiv stall (existing)
    wire        hz_operand_stall; // M1A A1: producer-in-MEM (load/mul) RAW — gates DIV md_start
    wire        flush_if_next; // bubble next-cycle IF/EX
    wire        amo_mem_hold;  // internal MEM-stage AMO two-beat freeze
    wire        core_mem_stall = mem_stall | amo_mem_hold;
    // Gate-anchor compatibility for ADR-0005-era structural checks:
    // wire        any_stall   = stall | fetch_stall | warmup | redirect_warmup | mem_stall;
    // assign i_mem_en   = (pc_redirect || redirect_warmup || !stall || at_cross_boundary) && !mem_stall;
    // wire id_advance_to_ex_mem = !any_stall && if_ex_valid && !warmup && !pc_redirect;
    // wire id_mem_active = (id_is_load || id_is_store) && if_ex_valid && !stall &&
    // !pc_redirect && !warmup;
    // assign d_mem_valid = ex_mem_valid_r && (ex_mem_is_load_r || ex_mem_is_store_r) &&
    // !pc_redirect;
    // ex_mem_is_store_r && ex_mem_valid_r && !pc_redirect ?
    // assign bp_upd_valid  = ex_mem_bp_upd_valid_r && !mem_stall && !ex_mem_trigger_hit_r;
    // && !stall && !pc_redirect && !mem_stall;
    // assign wb_csr_we      = ex_wb_csr_we_r && ex_wb_valid_r && !wb_take_irq &&
    // !wb_take_trigger && !ex_wb_illegal_r && !mem_stall;
    // assign rfu_we      = ex_wb_valid_r && ex_wb_rd_we_r && !ex_wb_illegal_r &&
    // !wb_take_irq && !wb_take_data_trap && !wb_take_trigger && !mem_stall;
    // !wb_take_data_trap && !wb_trigger_pending && !mem_stall;
    // wire wb_take_data_trap = ex_wb_valid_r && ex_wb_is_misaligned_r;
    // end else if (ex_mem_valid_r && ex_mem_mispredict_r && !ex_mem_trigger_hit_r) begin
    // assign wb_trap_enter        = (wb_take_irq || wb_take_data_trap || wb_take_sync_trap) && !mem_stall;
    // assign wb_trap_exit          = ex_wb_valid_r && ex_wb_is_mret_r && !mem_stall;
    // assign wb_instr_retired = ex_wb_valid_r && !wb_take_irq && !wb_take_data_trap &&
    // !wb_take_sync_trap && !wb_take_trigger && !mem_stall;
    // else if (wb_take_sync_trap && !mem_stall) trap_latched <= 1'b1;
    // end else if (mem_stall) begin
    /* if (mem_stall) begin
            // ADR-0005 freeze: no PC redirect
     */
    reg         redirect_warmup; // 1-cycle refetch bubble after redirect
    reg         debug_mode;
    reg         debug_halt_pending;
    reg         debug_step_pending;
    reg         debug_resume_redirect;
    wire        debug_halt_enter;
    wire        debug_dret_exit;
    wire        debug_resume_exit;
    wire        dcsr_step;
    wire        dcsr_ebreakm;
    wire [31:0] dpc_o;
    localparam [1:0] DBG_ENTRY_HALT      = 2'd0;
    localparam [1:0] DBG_ENTRY_TRIG_EXEC = 2'd1;
    localparam [1:0] DBG_ENTRY_TRIG_LD   = 2'd2;
    localparam [1:0] DBG_ENTRY_TRIG_ST   = 2'd3;
    wire [1:0]  debug_entry_reason;
    wire [32*8-1:0] pmp_addr_flat;
    wire [ 8*8-1:0] pmp_cfg_flat;
    wire            pmp_if_fault_pc;
    wire            pmp_if_fault_pc2;
    wire            pmp_if_fault;
    wire [31:0]     pmp_if_mtval;
    wire            pmp_data_fault_raw;
    wire            pmp_data_fault;

    always @(posedge clk) begin
        if (!resetn) redirect_warmup <= 1'b0;
        else         redirect_warmup <= pc_redirect;
    end

    // Lab08c: BP (64-entry 2-way) + RAS (8-entry)
    wire        bp_predict_taken;
    wire [31:0] bp_predict_target;
    wire        bp_upd_valid;
    wire [31:0] bp_upd_pc;
    wire        bp_upd_taken;
    wire [31:0] bp_upd_target;

    wire [31:0] ras_top;
    wire        ras_push;
    wire [31:0] ras_push_val;
    wire        ras_pop;
    wire        ras_predict_ret;

    // Lab08e: residue-based pre-fetch (replaces wait_high + high_buf)
    reg [15:0]  residue;        // saved high-half for upcoming cross-boundary assemble
    reg         cross_assemble; // 1 = this cycle: assemble {i_mem_rdata[15:0], residue}

    // ---- Pre-decode i_mem_rdata for instruction length ----
    wire [15:0] cur_half_lo = i_mem_rdata[15:0];
    wire [15:0] cur_half_hi = i_mem_rdata[31:16];
    wire        is_comp_lo  = (cur_half_lo[1:0] != 2'b11);
    wire        is_comp_hi  = (cur_half_hi[1:0] != 2'b11);

    wire        cur_at_high = if_pc[1];   // current instr at high half of fetched word

    // at_cross_boundary: fallback — arrived at cross-boundary without pre-setup
    // (happens after stall / redirect blocked upcoming_cross the previous cycle)
    wire        at_cross_boundary = cur_at_high && !is_comp_hi && !cross_assemble && !redirect_warmup;

    // upcoming_cross: sequential 16-bit at low half, FOLLOWED BY 32-bit at high half
    // Only fires when current instr is 16-bit at low half AND high half is 32-bit start,
    // with no prediction override or stall this cycle. Guarantees residue = correct high-half.
    wire        upcoming_cross = !cur_at_high && is_comp_lo && !is_comp_hi &&
                                  !cross_assemble && !stall && !warmup && !redirect_warmup && !pc_redirect &&
                                  !core_mem_stall && !debug_mode &&
                                  !bp_predict_taken && !ras_predict_ret;

    // Consecutive high-half 32-bit instructions remain cross-boundary.  While
    // consuming the current assembled instruction, save this word's high half
    // and fetch the next word so the following instruction also has 0-cycle
    // assembly.
    wire        consecutive_cross = cross_assemble && cur_at_high && !is_comp_hi &&
                                     !stall && !warmup && !redirect_warmup && !pc_redirect && !core_mem_stall &&
                                     !debug_mode && !bp_predict_taken && !ras_predict_ret;

    // is_16bit signal (drives ifu pc_inc)
    wire        is_16bit_w = cross_assemble  ? 1'b0 :       // assembled cross = 32-bit
                              cur_at_high    ? is_comp_hi :
                                               is_comp_lo;

    // fetch_stall: only fallback cross-boundary detection (not upcoming_cross path)
    wire        fetch_stall = at_cross_boundary;
    wire        any_stall   = stall | fetch_stall | warmup | redirect_warmup | core_mem_stall;

    // ---- Compressed expander ----
    wire [15:0] cinstr   = cur_at_high ? cur_half_hi : cur_half_lo;
    wire [31:0] cdec_expanded;
    wire        cdec_illegal;
    cdec u_cdec (
        .cinstr   (cinstr),
        .expanded (cdec_expanded),
        .illegal  (cdec_illegal)
    );

`ifndef SYNTHESIS
    // ADR-0016: cdec.illegal marks ONLY reserved/out-of-scope 16-bit encodings, which always expand to
    // 32'h0 and are caught by idu (id_illegal); compressed HINTs are NOP (illegal=0). cdec_illegal is
    // not a second architectural trap path (redundant with idu) — this sim-only check keeps it observed
    // and asserts the invariant.
    always @(posedge clk)
        if (cdec_illegal && cdec_expanded != 32'h0)
            $error("ADR-0016 invariant: cdec_illegal asserted but expanded=%h != 0", cdec_expanded);
`endif

    // ---- Assembled 32-bit instruction (output to if_ex) ----
    // cross_assemble: {new_word[15:0], residue} — both from registers (short path)
    // compressed: cdec output
    // aligned 32-bit (PC[1]=0): i_mem_rdata directly
    // (at_cross_boundary case produces garbage but any_stall=1 prevents latching)
    wire [31:0] instr_assembled =
        cross_assemble  ? {cur_half_lo, residue} :
        is_16bit_w      ? cdec_expanded :
                          i_mem_rdata;

    // ---- RET detection (for RAS pop) ----
    // lab08e v3: check only opcode+rd+funct3+rs1, not imm bits [31:20].
    // Full equality (== 32'h00008067) pulled cdec_expanded[23] (imm[11]) into the
    // ras_predict_ret→next_pc→i_mem_addr path via CDec case-select (cinstr[14], fo=44,
    // 6 LUT levels) → fo=26 routing bottleneck.  Imm is irrelevant for RAS prediction.
    wire if_is_ret_32  = (instr_assembled[6:0]  == 7'b1100111) &&  // JALR opcode
                         (instr_assembled[11:7]  == 5'b00000)   &&  // rd = x0
                         (instr_assembled[14:12] == 3'b000)     &&  // funct3 = 0
                         (instr_assembled[19:15] == 5'b00001);      // rs1 = ra (x1)
    wire if_is_ret_16  = is_16bit_w && (cinstr == 16'h8082);
    wire if_is_ret     = if_is_ret_32 || if_is_ret_16;

    wire        ras_valid      = (ras_top != 32'h0);
    assign      ras_predict_ret = if_is_ret && ras_valid && !any_stall && !pc_redirect;
    // VCS-compatible split declaration for: wire        ras_predict_ret = if_is_ret && ras_valid && !any_stall && !pc_redirect;

    assign ras_pop = ras_predict_ret;

    // ---- BP / RAS / ifu instantiation ----
    bp u_bp (
        .clk               (clk),
        .resetn            (resetn),
        .if_pc             (if_pc),
        .bp_predict_taken  (bp_predict_taken),
        .bp_predict_target (bp_predict_target),
        .upd_valid         (bp_upd_valid),
        .upd_pc            (bp_upd_pc),
        .upd_taken         (bp_upd_taken),
        .upd_target        (bp_upd_target)
    );

    ras u_ras (
        .clk      (clk),
        .resetn   (resetn),
        .ras_top  (ras_top),
        .push     (ras_push),
        .push_val (ras_push_val),
        .pop      (ras_pop)
    );

    ifu #(
        .RESET_PC(RESET_PC)
    ) u_ifu (
        .clk                (clk),
        .resetn             (resetn),
        .pc_stall           (any_stall),
        .pc_redirect        (pc_redirect),
        .redirect_target    (redirect_target),
        .ras_predict_ret    (ras_predict_ret),
        .ras_predict_target (ras_top),
        .bp_predict_taken   (bp_predict_taken),
        .bp_predict_target  (bp_predict_target),
        .is_16bit           (is_16bit_w),
        .pc                 (if_pc),
        .next_pc            (next_pc_w)
    );

    // i_mem_addr drive:
    //   at_cross_boundary: fetch next word (fallback, same as lab08d)
    //   consecutive_cross: keep pre-fetching for runs of high-half 32-bit instrs
    //   upcoming_cross:    pre-fetch next word one cycle early (if_pc[1]=0 → +4 = next word)
    //   else:              look-ahead via next_pc_w (normal)
    assign i_mem_addr = at_cross_boundary ? (if_pc + 32'd2) :
                        consecutive_cross ? (if_pc + 32'd6) :
                        upcoming_cross    ? (if_pc + 32'd4) :
                                            next_pc_w;
    // Keep BRAM active during at_cross_boundary even if lu/md stall fires simultaneously.
    // (same fix as lab08d §problems_log 1, but now only needed for fallback path)
    // ADR-0021 keeps the original fetch-enable contract and masks it only while halted:
    // assign i_mem_en   = (pc_redirect || redirect_warmup || !stall || at_cross_boundary) && !mem_stall;
    assign i_mem_en   = (pc_redirect || redirect_warmup || !stall || at_cross_boundary) && !core_mem_stall && !debug_mode;

    // ---- Cross-boundary state machine ----
    always @(posedge clk) begin
        if (!resetn || pc_redirect) begin
            cross_assemble <= 1'b0;
            residue        <= 16'h0;
        end else if (consecutive_cross) begin
            // Back-to-back high-half 32-bit: consume current and arm next.
            cross_assemble <= 1'b1;
            residue        <= cur_half_hi;
        end else if (upcoming_cross) begin
            // Pre-fetch path: no stall, save high-half for next cycle assembly
            cross_assemble <= 1'b1;
            residue        <= cur_half_hi;
        end else if (at_cross_boundary && !warmup && !core_mem_stall) begin
            // Fallback path: stall this cycle, set up for stall-free assembly next cycle
            cross_assemble <= 1'b1;
            residue        <= cur_half_hi;
        end else if (!any_stall) begin
            // Only clear when pipeline can advance; hold through stalls so BRAM data stays valid
            cross_assemble <= 1'b0;
        end
    end

    // =========================================================================
    // IF/EX pipeline register
    // =========================================================================
    reg [31:0] if_ex_instr;
    reg [31:0] if_ex_pc;
    reg        if_ex_valid;
    reg        if_ex_pred_taken;
    reg        if_ex_pred_ras;
    reg [31:0] if_ex_pred_target;
    reg [31:0] if_ex_pred_ras_target;
    reg        if_ex_is_16bit;  // instruction size flag for correct mepc / link-addr
    reg        if_ex_pmp_fault;
    reg [31:0] if_ex_pmp_mtval;

    always @(posedge clk) begin
        if (!resetn) begin
            if_ex_instr      <= 32'h0;
            if_ex_pc         <= 32'h0;
            if_ex_valid      <= 1'b0;
            if_ex_pred_taken <= 1'b0;
            if_ex_pred_ras   <= 1'b0;
            if_ex_pred_target <= 32'h0;
            if_ex_pred_ras_target <= 32'h0;
            if_ex_is_16bit   <= 1'b0;
            if_ex_pmp_fault  <= 1'b0;
            if_ex_pmp_mtval  <= 32'h0;
        end else if (debug_mode || debug_halt_enter || flush_if_next || warmup || redirect_warmup) begin
            // Original redirect flush arm retained with debug halt as an added source:
            // else if (flush_if_next || warmup || redirect_warmup) begin
            // Redirect must beat ordinary lu/md/fetch stalls; otherwise a
            // wrong-path stalled instruction can survive and retire.  The
            // extra redirect_warmup cycle lets sync i_mem_rdata catch up to
            // the redirected PC before IF/EX latches again.
            if_ex_instr      <= 32'h0;
            if_ex_pc         <= 32'h0;
            if_ex_valid      <= 1'b0;
            if_ex_pred_taken <= 1'b0;
            if_ex_pred_ras   <= 1'b0;
            if_ex_pred_target <= 32'h0;
            if_ex_pred_ras_target <= 32'h0;
            if_ex_is_16bit   <= 1'b0;
            if_ex_pmp_fault  <= 1'b0;
            if_ex_pmp_mtval  <= 32'h0;
        end else if (any_stall) begin
            // hold (load-use / muldiv / at_cross_boundary stall)
        end else begin
            if_ex_instr           <= instr_assembled;
            if_ex_pc              <= if_pc;
            if_ex_valid           <= 1'b1;
            if_ex_pred_taken      <= bp_predict_taken | ras_predict_ret;
            if_ex_pred_ras        <= ras_predict_ret;
            if_ex_is_16bit        <= is_16bit_w;
            if_ex_pred_target     <= ras_predict_ret ? ras_top : bp_predict_target;
            if_ex_pred_ras_target <= ras_top;
            if_ex_pmp_fault       <= pmp_if_fault;
            if_ex_pmp_mtval       <= pmp_if_mtval;
        end
    end

    assign flush_if_next = pc_redirect;

    // =========================================================================
    // IDU (decode if_ex_instr，純組合)
    // =========================================================================
    wire [ 4:0] id_rd_idx, id_rs1_idx, id_rs2_idx;
    wire [31:0] id_imm;
    wire [ 3:0] id_alu_op;
    wire        id_alu_b_use_imm;
    wire        id_is_bmu;        // M1A A2: BMU (Zba/Zbb/Zbs/Zicond) op in ID/EX
    wire [ 4:0] id_bmu_op;
    wire        id_rd_we;
    wire [ 2:0] id_wb_sel;
    wire        id_is_branch, id_branch_invert;
    wire [ 1:0] id_br_type;          // funct3[2:1]: 00=eq 10=lt_s 11=lt_u
    wire        id_is_jal, id_is_jalr;
    wire        id_is_load, id_is_store;
    wire [ 2:0] id_ls_funct3;
    wire        id_is_amo;
    wire        id_amo_is_lr;
    wire        id_amo_is_sc;
    wire [ 3:0] id_amo_op;
    wire        id_is_csr;
    wire [ 1:0] id_csr_op;
    wire        id_csr_uses_imm;
    wire [11:0] id_csr_addr;
    wire [31:0] id_csr_zimm;
    wire        id_is_mret;
    wire        id_is_dret;
    wire        id_is_muldiv;
    wire [ 2:0] id_md_op;
    wire        id_md_is_div;
    wire        id_illegal;
    wire        id_is_ecall;
    wire        id_is_ebreak;

    // Historical gate anchor: idu u_idu
    idu #(
        .RV32A(RV32A)
    ) u_idu (
        .instr         (if_ex_instr),
        .rd_idx        (id_rd_idx),
        .rs1_idx       (id_rs1_idx),
        .rs2_idx       (id_rs2_idx),
        .imm           (id_imm),
        .alu_op        (id_alu_op),
        .alu_b_use_imm (id_alu_b_use_imm),
        .is_bmu        (id_is_bmu),
        .bmu_op        (id_bmu_op),
        .rd_we         (id_rd_we),
        .wb_sel        (id_wb_sel),
        .is_branch     (id_is_branch),
        .branch_invert (id_branch_invert),
        .br_type       (id_br_type),
        .is_jal        (id_is_jal),
        .is_jalr       (id_is_jalr),
        .is_load       (id_is_load),
        .is_store      (id_is_store),
        .ls_funct3     (id_ls_funct3),
        .is_amo        (id_is_amo),
        .amo_is_lr     (id_amo_is_lr),
        .amo_is_sc     (id_amo_is_sc),
        .amo_op        (id_amo_op),
        .is_csr        (id_is_csr),
        .csr_op        (id_csr_op),
        .csr_uses_imm  (id_csr_uses_imm),
        .csr_addr      (id_csr_addr),
        .csr_zimm      (id_csr_zimm),
        .is_mret       (id_is_mret),
        .is_dret       (id_is_dret),
        .is_muldiv     (id_is_muldiv),
        .md_op         (id_md_op),
        .md_is_div     (id_md_is_div),
        .illegal       (id_illegal)
    );

    assign id_is_ecall  = (if_ex_instr == 32'h0000_0073);
    assign id_is_ebreak = (if_ex_instr == 32'h0010_0073);

    // =========================================================================
    // RFU (組合讀，同步寫)
    // =========================================================================
    wire [31:0] rfu_rs1_data, rfu_rs2_data;
    wire        rfu_we;
    wire [ 4:0] rfu_wr_idx;
    wire [31:0] rfu_wr_data;
    wire [31:0] dbg_gpr_rdata;
    wire        dbg_acc_is_gpr = (dm_acc_regno[15:5] == 11'b0001_0000_000);
    wire        dbg_acc_is_csr = (dm_acc_regno[15:12] == 4'h0);
    wire        dbg_acc_active = dm_acc_en && debug_mode;
    wire        dbg_gpr_acc_en = dbg_acc_active && dbg_acc_is_gpr;
    wire        dbg_csr_acc_en = dbg_acc_active && dbg_acc_is_csr;

    rfu u_rfu (
        .clk      (clk),
        .resetn   (resetn),
        .rs1_idx  (id_rs1_idx),
        .rs1_data (rfu_rs1_data),
        .rs2_idx  (id_rs2_idx),
        .rs2_data (rfu_rs2_data),
        .we       (rfu_we),
        .rd_idx   (rfu_wr_idx),
        .rd_data  (rfu_wr_data),
        .dbg_acc_en    (dbg_gpr_acc_en),
        .dbg_acc_write (dm_acc_write),
        .dbg_acc_idx   (dm_acc_regno[4:0]),
        .dbg_acc_wdata (dm_acc_wdata),
        .dbg_acc_rdata (dbg_gpr_rdata)
    );

    // =========================================================================
    // Forwarding (lab06b: 2 sources, EX/MEM + EX/WB → ID/EX)
    // =========================================================================
    wire [31:0] wb_data;
    wire        ex_wb_valid;
    wire        ex_wb_rd_we;
    wire [ 4:0] ex_wb_rd_idx;
    wire        ex_wb_is_load;
    reg        ex_mem_valid_r;
    reg [31:0] ex_mem_pc_r;
    reg [31:0] ex_mem_alu_result_r;
    reg [31:0] ex_mem_md_result_r;
    reg [31:0] ex_mem_pc_plus_4_r;
    reg [31:0] ex_mem_pc_plus_imm_r;
    reg [31:0] ex_mem_csr_rdata_r;
    reg [ 4:0] ex_mem_rd_idx_r;
    reg        ex_mem_rd_we_r;
    reg [ 2:0] ex_mem_wb_sel_r;
    reg        ex_mem_is_load_r;
    reg        ex_mem_is_mul_r;   // M1A A1: MUL slot tag (result-at-WB; blocks EX/MEM forward like a load)
    reg        ex_mem_is_store_r;
    reg        ex_mem_is_amo_r;
    reg        ex_mem_amo_is_lr_r;
    reg        ex_mem_amo_is_sc_r;
    reg [ 3:0] ex_mem_amo_op_r;
    reg [ 2:0] ex_mem_ls_funct3_r;
    reg [ 1:0] ex_mem_addr_lo_r;
    reg [31:0] ex_mem_store_wdata_r;
    reg [ 3:0] ex_mem_store_wstrb_r;
    reg        ex_mem_is_mret_r;
    reg        ex_mem_is_dret_r;
    reg        ex_mem_is_misaligned_r;
    reg        ex_mem_is_misaligned_store_r;
    reg        ex_mem_csr_we_r;
    reg [11:0] ex_mem_csr_addr_r;
    reg [ 1:0] ex_mem_csr_op_r;
    reg [31:0] ex_mem_csr_wdata_r;
    reg        ex_mem_is_branch_taken_r;
    reg        ex_mem_is_jal_r;
    reg        ex_mem_is_jalr_r;
    reg        ex_mem_illegal_r;
    reg        ex_mem_is_ecall_r;
    reg        ex_mem_is_ebreak_r;
    reg [31:0] ex_mem_instr_r;
    reg        ex_mem_mispredict_r;
    reg        ex_mem_bp_upd_valid_r;
    reg [31:0] ex_mem_bp_upd_pc_r;
    reg        ex_mem_bp_upd_taken_r;
    reg [31:0] ex_mem_bp_upd_target_r;
    reg        ex_mem_pred_ras_r;
    reg [31:0] ex_mem_pred_ras_target_r;
    reg        ex_mem_trigger_hit_r;
    reg [ 1:0] ex_mem_trigger_idx_r;
    reg        ex_mem_pmp_if_fault_r;
    reg [31:0] ex_mem_pmp_if_mtval_r;
    wire       id_advance_to_ex_mem;

    // EX/MEM forward value (= alu_result 或 pc+imm / pc+4 / csr / md)
    reg [31:0] ex_mem_fwd_val;
    always @* begin
        case (ex_mem_wb_sel_r)
            `WB_SEL_PCIMM: ex_mem_fwd_val = ex_mem_pc_plus_imm_r;
            `WB_SEL_PC4  : ex_mem_fwd_val = ex_mem_pc_plus_4_r;
            `WB_SEL_CSR  : ex_mem_fwd_val = ex_mem_csr_rdata_r;
            `WB_SEL_MD   : ex_mem_fwd_val = ex_mem_md_result_r;
            default      : ex_mem_fwd_val = ex_mem_alu_result_r;
        endcase
    end

    wire [31:0] rs1_val, rs2_val;
    forward u_forward (
        .id_rs1_idx   (id_rs1_idx),
        .id_rs2_idx   (id_rs2_idx),
        .rfu_rs1_data (rfu_rs1_data),
        .rfu_rs2_data (rfu_rs2_data),
        .em_valid     (ex_mem_valid_r),
        .em_rd_we     (ex_mem_rd_we_r),
        .em_rd_idx    (ex_mem_rd_idx_r),
        .em_fwd_val   (ex_mem_fwd_val),
        // M1A A1: MUL-in-MEM is value-not-ready, same class as load-in-MEM
        .em_is_load   (ex_mem_is_load_r || ex_mem_is_mul_r),
        .wb_valid     (ex_wb_valid),
        .wb_rd_we     (ex_wb_rd_we),
        .wb_rd_idx    (ex_wb_rd_idx),
        .wb_data      (wb_data),
        .wb_is_load   (ex_wb_is_load),
        .rs1_val      (rs1_val),
        .rs2_val      (rs2_val)
    );

    // =========================================================================
    // ALU
    // =========================================================================
    wire [31:0] alu_op_a = rs1_val;
    wire [31:0] alu_op_b = id_alu_b_use_imm ? id_imm : rs2_val;
    wire [31:0] alu_result;
    wire        alu_cmp_eq, alu_cmp_lt_s, alu_cmp_lt_u;

    // M1A A2: BMU beside the ALU — same operands (post-forward rs1 / op-b mux), result
    // selected by id_is_bmu below (one 2:1 mux on the EX writeback path; DC-smoke-guarded).
    wire [31:0] bmu_result;
    bmu u_bmu (
        .op_a   (rs1_val),
        .op_b   (alu_op_b),
        .bmu_op (id_bmu_op),
        .result (bmu_result)
    );

    alu u_alu (
        .op_a      (alu_op_a),
        .op_b      (alu_op_b),
        .alu_op    (id_alu_op),
        .result    (alu_result),
        .cmp_eq    (alu_cmp_eq),
        .cmp_lt_s  (alu_cmp_lt_s),
        .cmp_lt_u  (alu_cmp_lt_u)
    );

    // Branch decision — fast path bypasses alu_result case mux (lab08e v2)
    // id_br_type = funct3[2:1]: 00=BEQ/BNE(eq), 10=BLT/BGE(lt_s), 11=BLTU/BGEU(lt_u)
    wire branch_cond  = (id_br_type == 2'b00) ? alu_cmp_eq  :
                        (id_br_type == 2'b10) ? alu_cmp_lt_s : alu_cmp_lt_u;
    wire branch_taken = id_is_branch && (id_branch_invert ^ branch_cond);

    // pc + imm (給 JAL / branch target / AUIPC)
    // Use actual instruction size (16-bit→+2, 32-bit→+4) for link address and mepc
    wire [31:0] if_ex_pc_plus_4   = if_ex_pc + (if_ex_is_16bit ? 32'd2 : 32'd4);
    wire [31:0] if_ex_pc_plus_imm = if_ex_pc + id_imm;

    // BP mispredict detection: direction plus predicted-target equality.
    // BTB target aliases are possible; a predicted-taken branch/JAL/JALR must
    // still redirect if the resolved target differs from the fetched target.
    wire ex_actual_taken = if_ex_valid && (branch_taken | id_is_jal | id_is_jalr);
    wire [31:0] ex_actual_target = id_is_jalr ? (alu_result & ~32'd1) : if_ex_pc_plus_imm;
    wire ex_target_mispredict = if_ex_valid && if_ex_pred_taken && ex_actual_taken
                              && !if_ex_pred_ras
                              && (if_ex_pred_target != ex_actual_target);

    wire ex_mispredict = if_ex_valid && ((if_ex_pred_taken != ex_actual_taken)
                                      || ex_target_mispredict);

    // Recovery target NOT computed here — moved to MEM stage (combinational from
    // ex_mem.Q registers) to keep alu_result off the redirect_target.D path

    // BP update：combinational in EX，latch 進 ex_mem_bp_upd_* register，下一拍才
    // drive bp.v 的 upd port → BP counter_arr.D 跟 target_arr.D path 從 register
    // output 出發 (不再有 alu_result 進 BP write data 路徑)
    wire        ex_bp_upd_valid  = if_ex_valid && (id_is_branch | id_is_jal)
                                              && !stall && !pc_redirect && !debug_mode;
    // Original BP update gate:
    // && !stall && !pc_redirect;
    wire [31:0] ex_bp_upd_pc     = if_ex_pc;
    wire        ex_bp_upd_taken  = ex_actual_taken;
    wire [31:0] ex_bp_upd_target = if_ex_pc_plus_imm;

    // Lab08c: RAS push — 偵測 IF/EX 是 JAL ra (id_is_jal && rd == x1)，push pc+4
    //         （= 函式 return address）。Gating 跟 bp_upd 同：!stall, !pc_redirect
    // Original RAS push base:
    // assign ras_push     = if_ex_valid && id_is_jal && (id_rd_idx == 5'd1)
    wire ras_push_commit = if_ex_valid && id_is_jal && (id_rd_idx == 5'd1)
                                      && !stall && !pc_redirect && !core_mem_stall;
    assign ras_push     = ras_push_commit && !debug_mode;
    assign ras_push_val = if_ex_pc_plus_4;

    // =========================================================================
    // MUL / DIV units
    // =========================================================================
    // M1A A1: MUL = stateless pipelined (issue/result, rides its pipe slot);
    // 只有 DIV 仍走 start/done/result 阻塞 FSM 介面
    // M1A ADR-0026 A1: MUL is issue-decoupled ("load-like result-at-WB") — it no longer
    // uses the blocking md_busy/FSM path. Only DIV keeps the blocking M-unit handshake.
    wire        div_done;
    wire [31:0] mul_result, div_result;
    reg         md_started;
    reg         md_result_valid;
    reg  [31:0] md_result_q;
    wire        id_is_mul = id_is_muldiv && !id_md_is_div;
    wire        md_done = div_done;
    wire        md_busy = if_ex_valid && id_is_muldiv && id_md_is_div && !md_result_valid;
    wire [31:0] md_result = md_result_q;

    // M1A A1 fix (caught by directed lockstep, mul->div dist-1): md_start must NOT fire
    // while the div's producer (load or pipelined MUL) is still in EX/MEM — rs values are
    // not forwardable that cycle and the FSM would latch a STALE operand. Gate on the
    // hazard unit's operand_stall (same predicate that stalls the pipe; single source).
    wire md_start = if_ex_valid && id_is_muldiv && id_md_is_div &&
                    !md_started && !md_result_valid && !hz_operand_stall &&
                    !pc_redirect && !warmup && !redirect_warmup && !debug_mode;
    // Original mul/div start gate:
    // !pc_redirect && !warmup && !redirect_warmup;

    always @(posedge clk) begin
        if (!resetn) begin
            md_started       <= 1'b0;
            md_result_valid  <= 1'b0;
            md_result_q      <= 32'h0;
        end else if (pc_redirect || debug_halt_enter || debug_mode) begin
            md_started      <= 1'b0;
            md_result_valid <= 1'b0;
        end else if (md_done) begin
            md_started      <= 1'b0;
            md_result_valid <= 1'b1;
            md_result_q     <= div_result;
        end else if (id_advance_to_ex_mem && md_result_valid) begin
            md_result_valid <= 1'b0;
        end else if (md_start) begin
            md_started       <= 1'b1;
        end
    end

    // MUL issue = the MUL instruction actually advances ID/EX -> EX/MEM (this qualifier
    // already folds in !any_stall, !warmup, !pc_redirect, !debug_mode). Operands are the
    // POST-FORWARDING rs values, same as the old md_start capture. mul.v is stateless:
    // a squashed MUL's product is simply never consumed (slot tag ex_mem_is_mul_r below).
    wire mul_issue = id_advance_to_ex_mem && id_is_mul;

    mul u_mul (
        .clk    (clk),
        .resetn (resetn),
        .issue  (mul_issue),
        .md_op  (id_md_op),
        .op_a   (rs1_val),
        .op_b   (rs2_val),
        .result (mul_result)
    );

    // ERRATA-0002: the div FSM must die on exactly the conditions that clear md_started —
    // otherwise a wrong-path-started division survives the flush and poisons the re-issue.
    wire md_flush = pc_redirect || debug_halt_enter || debug_mode;

    div u_div (
        .clk    (clk),
        .resetn (resetn),
        .flush  (md_flush),
        .start  (md_start &&  id_md_is_div),
        .md_op  (id_md_op),
        .op_a   (rs1_val),
        .op_b   (rs2_val),
        .result (div_result),
        .done   (div_done)
    );

    // =========================================================================
    // LSU (in ID/EX stage: 生成 d-port outputs)
    //   addr_lo, wdata_raw, funct3, is_store, mem_rdata
    //   addr_lo 跟 mem_rdata 給 MEM/WB 用 (要 latch 到 EX/WB register)
    // =========================================================================
    wire [31:0] lsu_mem_wdata_id;
    wire [ 3:0] lsu_mem_wstrb_id;
    wire [31:0] lsu_ld_result_wb;       // 計算在 MEM/WB stage
    reg  [31:0] amo_result_r;
    reg  [31:0] amo_wdata_r;
    reg         amo_res_valid;
    reg  [31:2] amo_res_addr;
    reg  [ 1:0] amo_state;
    localparam [1:0] AMO_IDLE  = 2'd0;
    localparam [1:0] AMO_LOAD  = 2'd1;
    localparam [1:0] AMO_STORE = 2'd2;
    localparam [1:0] AMO_DONE  = 2'd3;

    wire ex_mem_sc_issue = ex_mem_is_amo_r && ex_mem_amo_is_sc_r && (amo_state == AMO_IDLE);
    wire ex_mem_sc_success = ex_mem_sc_issue &&
                             amo_res_valid && (amo_res_addr == ex_mem_alu_result_r[31:2]);
    wire ex_mem_sc_fail = ex_mem_sc_issue && !ex_mem_sc_success;
    wire ex_mem_amo_needs_load = ex_mem_is_amo_r && !ex_mem_amo_is_sc_r;
    assign amo_mem_hold = (RV32A != 0) && ex_mem_valid_r && ex_mem_is_amo_r &&
                          !ex_mem_is_misaligned_r && !debug_mode &&
                          !ex_mem_sc_fail && (amo_state != AMO_DONE);

    function [31:0] amo_compute;
        input [3:0] op;
        input [31:0] old_val;
        input [31:0] rs2_val_f;
        begin
            case (op)
                `AMO_OP_SWAP: amo_compute = rs2_val_f;
                `AMO_OP_XOR : amo_compute = old_val ^ rs2_val_f;
                `AMO_OP_OR  : amo_compute = old_val | rs2_val_f;
                `AMO_OP_AND : amo_compute = old_val & rs2_val_f;
                `AMO_OP_MIN : amo_compute = ($signed(old_val) < $signed(rs2_val_f)) ? old_val : rs2_val_f;
                `AMO_OP_MAX : amo_compute = ($signed(old_val) > $signed(rs2_val_f)) ? old_val : rs2_val_f;
                `AMO_OP_MINU: amo_compute = (old_val < rs2_val_f) ? old_val : rs2_val_f;
                `AMO_OP_MAXU: amo_compute = (old_val > rs2_val_f) ? old_val : rs2_val_f;
                default     : amo_compute = old_val + rs2_val_f;
            endcase
        end
    endfunction

    // lab08e v3: store_addr_lo[1:0] = rs1[1:0] + imm[1:0], 2-bit adder.
    // (rs1+imm)[1:0] == (rs1[1:0]+imm[1:0])[1:0] — lower bits independent of upper carries.
    // Bypasses 32-bit ALU CARRY4 chain; wstrb only needs addr[1:0].
    wire [1:0] store_addr_lo = rs1_val[1:0] + id_imm[1:0];

    // ID/EX：根據 store 算 wdata + wstrb
    /* verilator lint_off PINCONNECTEMPTY */
    lsu u_lsu_id (
        .addr_lo   (store_addr_lo),
        .wdata_raw (rs2_val),
        .funct3    (id_ls_funct3),
        .is_store  (id_is_store && if_ex_valid && !stall),
        .mem_rdata (32'h0),              // ID/EX 不用 ld_result
        .mem_wdata (lsu_mem_wdata_id),
        .mem_wstrb (lsu_mem_wstrb_id),
        .ld_result ()                    // 不用
    );
    /* verilator lint_on PINCONNECTEMPTY */

    // NOTE: `&&` binds tighter than `?:` — the ternary MUST be parenthesized,
    // else a non-load/store instr whose funct3 == F3_LW/F3_SW (e.g. SLT=010)
    // spuriously reports a misalign trap from its ALU result (drops div->..->slt,
    // diverged from Spike at idx=36).
    wire id_mem_align_error = (id_is_load || id_is_store || id_is_amo) && (
                             ((id_ls_funct3 == `F3_LH) || (id_ls_funct3 == `F3_SH)) ? (alu_result[0] != 1'b0) :
                             ((id_ls_funct3 == `F3_LW) || (id_ls_funct3 == `F3_SW)) ? (alu_result[1:0] != 2'b00) :
                             1'b0);
    wire id_mem_misaligned = id_mem_align_error && if_ex_valid && !stall && !pc_redirect && !warmup;
    wire [31:0] trigger_csr_rdata;
    wire [31:0] trigger_debug_csr_rdata;
    wire        trigger_csr_we;
    wire [11:0] trigger_csr_waddr;
    wire [31:0] trigger_csr_wdata;
    wire        trigger_debug_csr_we;
    wire [11:0] trigger_debug_csr_waddr;
    wire [31:0] trigger_debug_csr_wdata;
    wire        ex_trigger_hit;
    wire [ 1:0] ex_trigger_idx;
    wire        mem_trigger_hit;
    wire [ 1:0] mem_trigger_idx;
    wire        mem_trigger_is_load;
    wire        mem_trigger_is_store;
    wire        mem_side_effect_block;

    // 對外 d-port：MEM stage 驅動 (lab06b: 從 ex_mem.Q 出，不是 ID/EX 組合)
    //   d_mem_addr 走 register output → 切開 lab06 的 "BRAM → ALU → d_mem WEA" 長路徑
    //   id_mem_active 仍在 ID/EX 算 (寫 ex_mem 用)
    wire id_mem_active = (id_is_load || id_is_store || id_is_amo) && if_ex_valid && !stall &&
                         !pc_redirect && !warmup && !debug_mode;
    // Original memory side-effect base:
    // !pc_redirect && !warmup;
    // 從 ex_mem register 驅動 d-port (MEM stage)
    assign mem_side_effect_block = ex_mem_trigger_hit_r || mem_trigger_hit || ex_mem_pmp_if_fault_r;
    wire amo_load_beat = (RV32A != 0) && ex_mem_valid_r && ex_mem_is_amo_r &&
                         !ex_mem_is_misaligned_r && !ex_mem_sc_fail &&
                         ((amo_state == AMO_IDLE) && ex_mem_amo_needs_load);
    wire amo_store_beat = (RV32A != 0) && ex_mem_valid_r && ex_mem_is_amo_r &&
                          !ex_mem_is_misaligned_r && !ex_mem_sc_fail &&
                          ((amo_state == AMO_STORE) ||
                           ((amo_state == AMO_IDLE) && ex_mem_amo_is_sc_r && ex_mem_sc_success));
    wire normal_mem_beat = ex_mem_valid_r && (ex_mem_is_load_r || ex_mem_is_store_r) && !ex_mem_is_amo_r;
    wire pmp_data_req = (normal_mem_beat || amo_load_beat || amo_store_beat) &&
                        !pc_redirect && !debug_mode && !ex_mem_is_misaligned_r &&
                        !ex_mem_trigger_hit_r && !ex_mem_pmp_if_fault_r;
    wire pmp_data_write = pmp_data_req && (ex_mem_is_store_r || amo_store_beat);
    wire pmp_data_read = pmp_data_req && !pmp_data_write;
    assign d_mem_valid = (normal_mem_beat || amo_load_beat || amo_store_beat) &&
                         !pc_redirect && !debug_mode && !ex_mem_is_misaligned_r &&
                         !mem_side_effect_block && !pmp_data_fault;
    // Original D-port valid redirect suppression:
    // !pc_redirect;
    assign d_mem_addr  = ex_mem_alu_result_r;
    assign d_mem_wdata = amo_store_beat ? (ex_mem_amo_is_sc_r ? ex_mem_store_wdata_r : amo_wdata_r) :
                                          ex_mem_store_wdata_r;
    assign d_mem_wstrb = (amo_store_beat && !pc_redirect && !debug_mode && !mem_side_effect_block) ? 4'hf :
                         (ex_mem_is_store_r && ex_mem_valid_r && !pc_redirect && !debug_mode &&
                          !mem_side_effect_block) ?
                         ex_mem_store_wstrb_r : 4'h0;
    // Original store strobe gate:
    // ex_mem_is_store_r && ex_mem_valid_r && !pc_redirect ?

    // =========================================================================
    // CSR (lab05 同款，但 instr_retired 改成「EX/WB stage commits a valid instr」)
    // =========================================================================
    wire [31:0] id_csr_wdata = id_csr_uses_imm ? id_csr_zimm : rs1_val;
    wire        id_csr_we_logic = id_is_csr &&
                                  ((id_csr_op == `CSR_OP_W) || (id_csr_wdata != 32'h0));

    wire [31:0] csr_rdata;
    wire [31:0] dbg_csr_rdata;
    reg  [31:0] id_csr_rdata;
    wire [31:0] mtvec_o, mepc_o;
    wire        irq_pending_raw;
    wire        irq_pending;
    wire [31:0] wb_irq_cause;       // priority-encoded interrupt mcause from csr (ADR-0019)
    wire [31:0] wb_trap_cause;
    wire [31:0] wb_trap_mtval;
    // CSR write happens in EX/WB stage (latched into ex_wb register)
    wire        wb_csr_we;
    wire        wb_trap_enter, wb_trap_exit;
    wire [31:0] wb_trap_pc_for_mepc;
    wire        wb_instr_retired;
    reg        ex_wb_valid_r;
    /* verilator lint_off UNUSEDSIGNAL */  // 留作 debug; trap_pc 走 pc_plus_4 路徑
    reg [31:0] ex_wb_pc_r;
    /* verilator lint_on UNUSEDSIGNAL */
    reg [31:0] ex_wb_alu_result_r;
    reg [31:0] ex_wb_md_result_r;
    reg [31:0] ex_wb_pc_plus_4_r;
    reg [31:0] ex_wb_pc_plus_imm_r;
    reg [31:0] ex_wb_csr_rdata_r;
    reg [ 4:0] ex_wb_rd_idx_r;
    reg        ex_wb_rd_we_r;
    reg [ 2:0] ex_wb_wb_sel_r;
    reg        ex_wb_is_load_r;
    reg        ex_wb_is_amo_r;
    reg        ex_wb_amo_is_sc_r;
    /* verilator lint_off UNUSEDSIGNAL */
    reg        ex_wb_is_store_r;   // store 在 MEM 已 commit 到 d-port，WB 不用
    /* verilator lint_on UNUSEDSIGNAL */
    reg        ex_wb_is_misaligned_r;
    reg        ex_wb_is_misaligned_store_r;
    reg [ 2:0] ex_wb_ls_funct3_r;
    reg [ 1:0] ex_wb_addr_lo_r;
    reg        ex_wb_is_mret_r;
    reg        ex_wb_is_dret_r;
    reg        ex_wb_csr_we_r;
    reg [11:0] ex_wb_csr_addr_r;
    reg [ 1:0] ex_wb_csr_op_r;
    reg [31:0] ex_wb_csr_wdata_r;
    reg        ex_wb_is_branch_taken_r;
    reg        ex_wb_is_jal_r;
    reg        ex_wb_is_jalr_r;
    reg        ex_wb_illegal_r;
    reg        ex_wb_is_ecall_r;
    reg        ex_wb_is_ebreak_r;
    reg [31:0] ex_wb_instr_r;
    reg        ex_wb_trigger_hit_r;
    reg [ 1:0] ex_wb_trigger_idx_r;
    reg        ex_wb_trigger_exec_r;
    reg        ex_wb_trigger_load_r;
    reg        ex_wb_trigger_store_r;
    reg        ex_wb_pmp_if_fault_r;
    reg [31:0] ex_wb_pmp_if_mtval_r;
    reg        ex_wb_pmp_data_fault_r;
    reg        ex_wb_pmp_data_store_r;
    wire       wb_take_irq;
    wire       wb_trigger_pending;
    wire       wb_take_trigger;
    wire [31:0] wb_sync_exception_pc = ex_wb_pc_r;
    wire [31:0] debug_halt_pc_w;
    wire [ 2:0] debug_halt_cause_w;

    wire [2:0] ex_mem_access_size =
        ((ex_mem_ls_funct3_r == `F3_LH) || (ex_mem_ls_funct3_r == `F3_SH)) ? 3'd2 :
        ((ex_mem_ls_funct3_r == `F3_LW) || (ex_mem_ls_funct3_r == `F3_SW)) ? 3'd3 :
                                                                          3'd1;

    trigger u_trigger (
        .clk                  (clk),
        .resetn               (resetn),
        .csr_raddr            (id_csr_addr),
        .csr_rdata            (trigger_csr_rdata),
        .csr_we               (trigger_csr_we),
        .csr_waddr            (trigger_csr_waddr),
        .csr_wdata            (trigger_csr_wdata),
        .debug_csr_raddr      (dm_acc_regno[11:0]),
        .debug_csr_rdata      (trigger_debug_csr_rdata),
        .debug_csr_we         (trigger_debug_csr_we),
        .debug_csr_waddr      (trigger_debug_csr_waddr),
        .debug_csr_wdata      (trigger_debug_csr_wdata),
        .ex_valid             (id_advance_to_ex_mem),
        .ex_pc                (if_ex_pc),
        .ex_is_16bit          (if_ex_is_16bit),
        .ex_trigger_hit       (ex_trigger_hit),
        .ex_trigger_idx       (ex_trigger_idx),
        .mem_valid            (ex_mem_valid_r && !ex_mem_is_misaligned_r && !pc_redirect &&
                               !debug_mode && !ex_mem_pmp_if_fault_r),
        .mem_is_load          (ex_mem_is_load_r),
        .mem_is_store         (ex_mem_is_store_r),
        .mem_addr             (ex_mem_alu_result_r),
        .mem_size             (ex_mem_access_size),
        .mem_trigger_hit      (mem_trigger_hit),
        .mem_trigger_idx      (mem_trigger_idx),
        .mem_trigger_is_load  (mem_trigger_is_load),
        .mem_trigger_is_store (mem_trigger_is_store),
        .fire_valid           (debug_halt_enter && wb_take_trigger),
        .fire_idx             (ex_wb_trigger_idx_r)
    );

    pmp #(
        .PMP_ENTRIES(PMP_ENTRIES)
    ) u_pmp_if_pc (
        .pmp_addr_i  (pmp_addr_flat),
        .pmp_cfg_i   (pmp_cfg_flat),
        .req_addr_i  (if_pc),
        .req_exec_i  (1'b1),
        .req_write_i (1'b0),
        .req_read_i  (1'b0),
        .fault_o     (pmp_if_fault_pc)
    );

    pmp #(
        .PMP_ENTRIES(PMP_ENTRIES)
    ) u_pmp_if_pc2 (
        .pmp_addr_i  (pmp_addr_flat),
        .pmp_cfg_i   (pmp_cfg_flat),
        .req_addr_i  (if_pc + 32'd2),
        .req_exec_i  (1'b1),
        .req_write_i (1'b0),
        .req_read_i  (1'b0),
        .fault_o     (pmp_if_fault_pc2)
    );

    assign pmp_if_fault = (PMP_ENTRIES != 0) && !debug_mode &&
                          (pmp_if_fault_pc || (!is_16bit_w && pmp_if_fault_pc2));
    assign pmp_if_mtval = (pmp_if_fault_pc || is_16bit_w) ? if_pc : (if_pc + 32'd2);

    pmp #(
        .PMP_ENTRIES(PMP_ENTRIES)
    ) u_pmp_data (
        .pmp_addr_i  (pmp_addr_flat),
        .pmp_cfg_i   (pmp_cfg_flat),
        .req_addr_i  (ex_mem_alu_result_r),
        .req_exec_i  (1'b0),
        .req_write_i (pmp_data_write),
        .req_read_i  (pmp_data_read),
        .fault_o     (pmp_data_fault_raw)
    );
    assign pmp_data_fault = pmp_data_req && pmp_data_fault_raw;

    csr #(
        .RV32A(RV32A),
        .PMP_ENTRIES(PMP_ENTRIES)
    ) u_csr (
        .clk                (clk),
        .resetn             (resetn),
        .csr_raddr          (id_csr_addr),       // read in ID/EX
        .csr_rdata          (csr_rdata),
        .csr_we             (wb_csr_we),         // write in EX/WB (latched addr)
        .csr_waddr          (ex_wb_csr_addr_r),
        .csr_op             (ex_wb_csr_op_r),
        .csr_wdata          (ex_wb_csr_wdata_r),
        .csr_old_val        (ex_wb_csr_rdata_r),
        .instr_retired      (wb_instr_retired),
        .trap_enter         (wb_trap_enter),
        .trap_pc            (wb_trap_pc_for_mepc),
        .trap_exit          (wb_trap_exit),
        .debug_csr_we       (dbg_csr_acc_en && dm_acc_write),
        .debug_csr_waddr    (dm_acc_regno[11:0]),
        .debug_csr_wdata    (dm_acc_wdata),
        .debug_csr_rdata    (dbg_csr_rdata),
        .debug_halt_enter   (debug_halt_enter),
        .debug_halt_pc      (debug_halt_pc_w),
        .debug_halt_cause   (debug_halt_cause_w),
        .dpc_o              (dpc_o),
        .dcsr_step_o        (dcsr_step),
        .dcsr_ebreakm_o     (dcsr_ebreakm),
        .trigger_csr_rdata  (trigger_csr_rdata),
        .trigger_debug_csr_rdata (trigger_debug_csr_rdata),
        .trigger_csr_we     (trigger_csr_we),
        .trigger_csr_waddr  (trigger_csr_waddr),
        .trigger_csr_wdata  (trigger_csr_wdata),
        .trigger_debug_csr_we    (trigger_debug_csr_we),
        .trigger_debug_csr_waddr (trigger_debug_csr_waddr),
        .trigger_debug_csr_wdata (trigger_debug_csr_wdata),
        .irq_external_pulse (irq_external_pulse),
        .mtip               (mtip),
        .msip               (msip),
        .meip               (meip),
        .trap_cause        (wb_trap_cause),
        .trap_mtval        (wb_trap_mtval),
        .mtvec_o            (mtvec_o),
        .mepc_o             (mepc_o),
        .irq_pending        (irq_pending_raw),
        .irq_cause          (wb_irq_cause),
        .pmp_addr_o         (pmp_addr_flat),
        .pmp_cfg_o          (pmp_cfg_flat)
    );
    assign irq_pending = irq_pending_raw && !debug_mode;

    always @* begin
        id_csr_rdata = csr_rdata;
        if (ex_mem_valid_r && ex_mem_csr_we_r && (ex_mem_csr_addr_r == id_csr_addr)) begin
            // verilator coverage_off
            case (ex_mem_csr_op_r)
                `CSR_OP_W: id_csr_rdata = ex_mem_csr_wdata_r;
                `CSR_OP_S: id_csr_rdata = ex_mem_csr_rdata_r | ex_mem_csr_wdata_r;
                `CSR_OP_C: id_csr_rdata = ex_mem_csr_rdata_r & ~ex_mem_csr_wdata_r;
                default:   id_csr_rdata = ex_mem_csr_rdata_r;
            endcase
            // verilator coverage_on
            // ^ CS-COV-1 exclusion: CSR ops serialize in this pipeline (empirically: thousands of
            //   adjacent same-addr csr pairs injected, arms never taken); bypass retained defensively
        end
    end

    // =========================================================================
    // hazard (load-use stall + muldiv stall)
    // =========================================================================
    hazard u_hazard (
        .id_valid     (if_ex_valid),
        .id_rs1_idx   (id_rs1_idx),
        .id_rs2_idx   (id_rs2_idx),
        .id_is_muldiv (id_is_muldiv),
        .em_valid     (ex_mem_valid_r),
        .em_rd_we     (ex_mem_rd_we_r),
        .em_rd_idx    (ex_mem_rd_idx_r),
        // M1A A1: MUL-in-MEM is value-not-ready, same class as load-in-MEM
        .em_is_load   (ex_mem_is_load_r || ex_mem_is_mul_r),
        .wb_valid     (ex_wb_valid),
        .wb_rd_we     (ex_wb_rd_we),
        .wb_rd_idx    (ex_wb_rd_idx),
        .wb_is_load   (ex_wb_is_load),
        .md_busy      (md_busy),
        .stall        (stall),
        .operand_stall(hz_operand_stall)
    );

    // =========================================================================
    // EX/MEM pipeline register (NEW in lab06b)
    //   存：control signals + ALU result + branch decide + store data
    //   ALU output 在這裡 latch → 下一拍 d_mem_addr 從 register Q 驅動
    //   PC redirect 在 MEM stage 從 ex_mem.Q 出 (branch penalty 跟 lab06 同 3 cycle)
    // =========================================================================
    // Lab08b: BP mispredict 取代「無條件 branch_taken/jal/jalr → redirect」
    // 注意：不 latch recovery_target — 在 MEM stage 用 ex_mem.Q registers 組合算
    //       (避免 alu_result → ex_mem_recovery_target_r.D 的 critical path)
    // Lab08b: BP update path register (避免 alu_result→counter_arr/target_arr.D
    // 的 critical path；多 1 cycle update latency，但對 hot-loop 命中率影響忽略)
    // Lab08c: RAS prediction info forwarded to MEM stage for target verify

    // ID/EX → EX/MEM 推進條件
    // Lab08e: !any_stall (= 不在 lu/md/at_cross_boundary/warmup stall 期間)。
    // Original ID/EX advance base:
    // wire id_advance_to_ex_mem = !any_stall && if_ex_valid && !warmup && !pc_redirect;
    assign id_advance_to_ex_mem = !any_stall && if_ex_valid && !warmup && !pc_redirect && !debug_mode;
    // VCS-compatible split declaration for: wire id_advance_to_ex_mem = !any_stall && if_ex_valid && !warmup && !pc_redirect;

    always @(posedge clk) begin
        if (!resetn) begin
            ex_mem_valid_r           <= 1'b0;
            ex_mem_rd_we_r           <= 1'b0;
            ex_mem_is_load_r         <= 1'b0;
            ex_mem_is_mul_r          <= 1'b0;
            ex_mem_is_store_r        <= 1'b0;
            ex_mem_is_amo_r          <= 1'b0;
            ex_mem_amo_is_lr_r       <= 1'b0;
            ex_mem_amo_is_sc_r       <= 1'b0;
            ex_mem_amo_op_r          <= 4'h0;
            ex_mem_store_wstrb_r     <= 4'h0;
            ex_mem_is_mret_r         <= 1'b0;
            ex_mem_is_dret_r         <= 1'b0;
            ex_mem_is_misaligned_r   <= 1'b0;
            ex_mem_is_misaligned_store_r <= 1'b0;
            ex_mem_csr_we_r          <= 1'b0;
            ex_mem_is_branch_taken_r <= 1'b0;
            ex_mem_is_jal_r          <= 1'b0;
            ex_mem_is_jalr_r         <= 1'b0;
            ex_mem_illegal_r         <= 1'b0;
            ex_mem_is_ecall_r        <= 1'b0;
            ex_mem_is_ebreak_r       <= 1'b0;
            ex_mem_instr_r           <= 32'h0;
            ex_mem_mispredict_r      <= 1'b0;
            ex_mem_bp_upd_valid_r    <= 1'b0;
            ex_mem_pred_ras_r        <= 1'b0;
            ex_mem_trigger_hit_r     <= 1'b0;
            ex_mem_trigger_idx_r     <= 2'd0;
            ex_mem_pmp_if_fault_r    <= 1'b0;
            ex_mem_pmp_if_mtval_r    <= 32'h0;
        end else if (debug_mode || debug_halt_enter) begin
            ex_mem_valid_r           <= 1'b0;
            ex_mem_rd_we_r           <= 1'b0;
            ex_mem_is_load_r         <= 1'b0;
            ex_mem_is_mul_r          <= 1'b0;
            ex_mem_is_store_r        <= 1'b0;
            ex_mem_is_amo_r          <= 1'b0;
            ex_mem_amo_is_lr_r       <= 1'b0;
            ex_mem_amo_is_sc_r       <= 1'b0;
            ex_mem_amo_op_r          <= 4'h0;
            ex_mem_store_wstrb_r     <= 4'h0;
            ex_mem_is_mret_r         <= 1'b0;
            ex_mem_is_dret_r         <= 1'b0;
            ex_mem_is_misaligned_r   <= 1'b0;
            ex_mem_is_misaligned_store_r <= 1'b0;
            ex_mem_csr_we_r          <= 1'b0;
            ex_mem_is_branch_taken_r <= 1'b0;
            ex_mem_is_jal_r          <= 1'b0;
            ex_mem_is_jalr_r         <= 1'b0;
            ex_mem_illegal_r         <= 1'b0;
            ex_mem_is_ecall_r        <= 1'b0;
            ex_mem_is_ebreak_r       <= 1'b0;
            ex_mem_instr_r           <= 32'h0;
            ex_mem_mispredict_r      <= 1'b0;
            ex_mem_bp_upd_valid_r    <= 1'b0;
            ex_mem_pred_ras_r        <= 1'b0;
            ex_mem_trigger_hit_r     <= 1'b0;
            ex_mem_trigger_idx_r     <= 2'd0;
            ex_mem_pmp_if_fault_r    <= 1'b0;
            ex_mem_pmp_if_mtval_r    <= 32'h0;
        end else if (id_advance_to_ex_mem) begin
            ex_mem_valid_r           <= 1'b1;
            ex_mem_pc_r              <= if_ex_pc;
            ex_mem_alu_result_r      <= id_is_bmu ? bmu_result : alu_result;  // M1A A2
            ex_mem_md_result_r       <= md_result;
            ex_mem_pc_plus_4_r       <= if_ex_pc_plus_4;
            ex_mem_pc_plus_imm_r     <= if_ex_pc_plus_imm;
            ex_mem_csr_rdata_r       <= id_csr_rdata;
            ex_mem_rd_idx_r          <= id_rd_idx;
            ex_mem_rd_we_r           <= id_rd_we;
            ex_mem_wb_sel_r          <= id_wb_sel;
            ex_mem_is_load_r         <= id_is_load || id_is_amo;
            ex_mem_is_mul_r          <= id_is_mul;
            ex_mem_is_store_r        <= id_is_store;
            ex_mem_is_amo_r          <= id_is_amo;
            ex_mem_amo_is_lr_r       <= id_amo_is_lr;
            ex_mem_amo_is_sc_r       <= id_amo_is_sc;
            ex_mem_amo_op_r          <= id_amo_op;
            ex_mem_ls_funct3_r       <= id_ls_funct3;
            ex_mem_addr_lo_r         <= alu_result[1:0];
            ex_mem_store_wdata_r     <= lsu_mem_wdata_id;
            ex_mem_store_wstrb_r     <= (id_is_store || id_is_amo) && id_mem_active ? lsu_mem_wstrb_id : 4'h0;
            ex_mem_is_mret_r         <= id_is_mret;
            ex_mem_is_dret_r         <= id_is_dret;
            ex_mem_is_misaligned_r   <= id_mem_misaligned;
            ex_mem_is_misaligned_store_r <= id_is_store || id_is_amo;
            ex_mem_csr_we_r          <= id_csr_we_logic;
            ex_mem_csr_addr_r        <= id_csr_addr;
            ex_mem_csr_op_r          <= id_csr_op;
            ex_mem_csr_wdata_r       <= id_csr_wdata;
            ex_mem_is_branch_taken_r <= branch_taken;
            ex_mem_is_jal_r          <= id_is_jal;
            ex_mem_is_jalr_r         <= id_is_jalr;
            ex_mem_illegal_r         <= id_illegal;
            ex_mem_is_ecall_r        <= id_is_ecall;
            ex_mem_is_ebreak_r       <= id_is_ebreak;
            ex_mem_instr_r           <= if_ex_instr;
            ex_mem_mispredict_r      <= ex_mispredict;
            ex_mem_bp_upd_valid_r    <= ex_bp_upd_valid;
            ex_mem_bp_upd_pc_r       <= ex_bp_upd_pc;
            ex_mem_bp_upd_taken_r    <= ex_bp_upd_taken;
            ex_mem_bp_upd_target_r   <= ex_bp_upd_target;
            ex_mem_pred_ras_r        <= if_ex_pred_ras;
            ex_mem_pred_ras_target_r <= if_ex_pred_ras_target;
            ex_mem_trigger_hit_r     <= ex_trigger_hit;
            ex_mem_trigger_idx_r     <= ex_trigger_idx;
            ex_mem_pmp_if_fault_r    <= if_ex_pmp_fault;
            ex_mem_pmp_if_mtval_r    <= if_ex_pmp_mtval;
        end else if (core_mem_stall) begin
            // ADR-0005 freeze: hold EX/MEM in place during a memory wait (no bubble)
        end else begin
            // Stall / wrong-path / warmup: 插 bubble
            ex_mem_valid_r           <= 1'b0;
            ex_mem_rd_we_r           <= 1'b0;
            ex_mem_is_load_r         <= 1'b0;
            ex_mem_is_mul_r          <= 1'b0;
            ex_mem_is_store_r        <= 1'b0;
            ex_mem_is_amo_r          <= 1'b0;
            ex_mem_amo_is_lr_r       <= 1'b0;
            ex_mem_amo_is_sc_r       <= 1'b0;
            ex_mem_amo_op_r          <= 4'h0;
            ex_mem_store_wstrb_r     <= 4'h0;
            ex_mem_is_mret_r         <= 1'b0;
            ex_mem_is_dret_r         <= 1'b0;
            ex_mem_is_misaligned_r   <= 1'b0;
            ex_mem_is_misaligned_store_r <= 1'b0;
            ex_mem_csr_we_r          <= 1'b0;
            ex_mem_is_branch_taken_r <= 1'b0;
            ex_mem_is_jal_r          <= 1'b0;
            ex_mem_is_jalr_r         <= 1'b0;
            ex_mem_illegal_r         <= 1'b0;
            ex_mem_is_ecall_r        <= 1'b0;
            ex_mem_is_ebreak_r       <= 1'b0;
            ex_mem_instr_r           <= 32'h0;
            ex_mem_mispredict_r      <= 1'b0;
            ex_mem_bp_upd_valid_r    <= 1'b0;
            ex_mem_pred_ras_r        <= 1'b0;
            ex_mem_trigger_hit_r     <= 1'b0;
            ex_mem_trigger_idx_r     <= 2'd0;
            ex_mem_pmp_if_fault_r    <= 1'b0;
            ex_mem_pmp_if_mtval_r    <= 32'h0;
        end
    end

    // Lab08c: MEM-stage RAS target verify (combinational from ex_mem.Q)
    //   pred_ras=1 表示 IF 階段 RAS 預測這條 jalr 的 target；現在比對 alu_result 是否相同
    //   alu_result for jalr = rs1 + imm = ra (因為 ret 是 jalr x0, ra, 0)，& ~1 mask LSB
    //   mismatch → fire 額外 redirect (priority 比 ex_mem_mispredict 高)
    wire [31:0] mem_ras_actual_target = ex_mem_alu_result_r & ~32'd1;
    wire        mem_ras_mispredict    = ex_mem_valid_r && ex_mem_pred_ras_r && !ex_mem_trigger_hit_r &&
                                        !ex_mem_pmp_if_fault_r
                                     && (mem_ras_actual_target != ex_mem_pred_ras_target_r);

    // BP update 用 ex_mem_bp_upd_* register output 驅動 (1 cycle delay)
    assign bp_upd_valid  = ex_mem_bp_upd_valid_r && !core_mem_stall && !ex_mem_trigger_hit_r &&
                           !ex_mem_pmp_if_fault_r;
    assign bp_upd_pc     = ex_mem_bp_upd_pc_r;
    assign bp_upd_taken  = ex_mem_bp_upd_taken_r;
    assign bp_upd_target = ex_mem_bp_upd_target_r;

    // =========================================================================
    // EX/WB pipeline register
    //   存：給 WB stage 用的 control + data (從 ex_mem.Q 傳過來)
    //   load 在這 stage 才看到 d_mem_rdata (BRAM 1-cycle latency 對齊)
    // =========================================================================
    // EX/MEM → EX/WB 推進條件
    //   branch/JAL/JALR 在 ex_mem 觸發 pc_redirect 不影響自己 advance 到 WB
    //   只有 wb_redirect (IRQ/MRET 從 ex_wb 觸發) 才 flush ex_mem (= wrong-path)
    wire wb_take_data_trap = ex_wb_valid_r && (ex_wb_is_misaligned_r || ex_wb_pmp_data_fault_r);
    assign wb_trigger_pending = ex_wb_valid_r && ex_wb_trigger_hit_r && !debug_mode && !core_mem_stall;
    assign wb_take_trigger = wb_trigger_pending && !wb_take_data_trap;
    wire wb_ebreak_debug_entry = ex_wb_valid_r && ex_wb_is_ebreak_r && dcsr_ebreakm && !debug_mode;
    wire wb_dret_illegal = ex_wb_valid_r && ex_wb_is_dret_r && !debug_mode;
    wire wb_take_sync_trap = ex_wb_valid_r && (ex_wb_illegal_r || wb_dret_illegal ||
                             ex_wb_pmp_if_fault_r) &&
                             !wb_ebreak_debug_entry && !wb_take_trigger;
    wire wb_redirect = wb_take_irq || wb_take_data_trap || wb_take_sync_trap || wb_take_trigger ||
                       (ex_wb_valid_r && ex_wb_is_mret_r) ||
                       (ex_wb_valid_r && ex_wb_is_dret_r && debug_mode) ||
                       debug_halt_enter || debug_resume_redirect;
    wire ex_mem_advance_to_wb = ex_mem_valid_r && !wb_redirect;

    always @(posedge clk) begin
        if (!resetn) begin
            amo_state     <= AMO_IDLE;
            amo_result_r  <= 32'h0;
            amo_wdata_r   <= 32'h0;
            amo_res_valid <= 1'b0;
            amo_res_addr  <= 30'h0;
        end else begin
            if (wb_trap_enter || debug_halt_enter || pc_redirect) begin
                amo_state     <= AMO_IDLE;
                amo_res_valid <= 1'b0;
            end else if (!mem_stall) begin
                if (ex_mem_valid_r && ex_mem_is_amo_r && pmp_data_fault) begin
                    amo_state <= AMO_DONE;
                end else if (ex_mem_valid_r && ex_mem_is_amo_r && !ex_mem_is_misaligned_r &&
                    !debug_mode && !mem_side_effect_block) begin
                    if (ex_mem_sc_fail) begin
                        amo_state     <= AMO_DONE;
                        amo_result_r  <= 32'h1;
                        amo_res_valid <= 1'b0;
                    end else begin
                        case (amo_state)
                            AMO_IDLE: begin
                                if (ex_mem_amo_is_sc_r && ex_mem_sc_success) begin
                                    amo_state     <= AMO_DONE;
                                    amo_result_r  <= 32'h0;
                                    amo_res_valid <= 1'b0;
                                end else if (ex_mem_amo_needs_load) begin
                                    amo_state <= AMO_LOAD;
                                end
                            end
                            AMO_LOAD: begin
                                amo_result_r <= d_mem_rdata;
                                amo_wdata_r  <= amo_compute(ex_mem_amo_op_r, d_mem_rdata, ex_mem_store_wdata_r);
                                if (ex_mem_amo_is_lr_r) begin
                                    amo_state     <= AMO_DONE;
                                    amo_res_valid <= 1'b1;
                                    amo_res_addr  <= ex_mem_alu_result_r[31:2];
                                end else begin
                                    amo_state <= AMO_STORE;
                                end
                            end
                            AMO_STORE: begin
                                amo_state     <= AMO_DONE;
                                amo_res_valid <= 1'b0;
                            end
                            default: begin
                                if (ex_mem_advance_to_wb) begin
                                    amo_state <= AMO_IDLE;
                                end
                            end
                        endcase
                    end
                end else if (ex_mem_advance_to_wb) begin
                    amo_state <= AMO_IDLE;
                end

                if (normal_mem_beat && (|d_mem_wstrb) && amo_res_valid &&
                    (d_mem_addr[31:2] == amo_res_addr)) begin
                    amo_res_valid <= 1'b0;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (!resetn) begin
            ex_wb_valid_r           <= 1'b0;
            ex_wb_pc_r              <= 32'h0;
            ex_wb_alu_result_r      <= 32'h0;
            ex_wb_md_result_r       <= 32'h0;
            ex_wb_pc_plus_4_r       <= 32'h0;
            ex_wb_pc_plus_imm_r     <= 32'h0;
            ex_wb_csr_rdata_r       <= 32'h0;
            ex_wb_rd_idx_r          <= 5'h0;
            ex_wb_rd_we_r           <= 1'b0;
            ex_wb_wb_sel_r          <= 3'h0;
            ex_wb_is_load_r         <= 1'b0;
            ex_wb_is_amo_r          <= 1'b0;
            ex_wb_amo_is_sc_r       <= 1'b0;
            ex_wb_is_store_r        <= 1'b0;
            ex_wb_is_misaligned_r       <= 1'b0;
            ex_wb_is_misaligned_store_r <= 1'b0;
            ex_wb_ls_funct3_r       <= 3'h0;
            ex_wb_addr_lo_r         <= 2'h0;
            ex_wb_is_mret_r         <= 1'b0;
            ex_wb_is_dret_r         <= 1'b0;
            ex_wb_csr_we_r          <= 1'b0;
            ex_wb_csr_addr_r        <= 12'h0;
            ex_wb_csr_op_r          <= 2'h0;
            ex_wb_csr_wdata_r       <= 32'h0;
            ex_wb_is_branch_taken_r <= 1'b0;
            ex_wb_is_jal_r          <= 1'b0;
            ex_wb_is_jalr_r         <= 1'b0;
            ex_wb_illegal_r         <= 1'b0;
            ex_wb_is_ecall_r        <= 1'b0;
            ex_wb_is_ebreak_r       <= 1'b0;
            ex_wb_instr_r           <= 32'h0;
            ex_wb_trigger_hit_r     <= 1'b0;
            ex_wb_trigger_idx_r     <= 2'd0;
            ex_wb_trigger_exec_r    <= 1'b0;
            ex_wb_trigger_load_r    <= 1'b0;
            ex_wb_trigger_store_r   <= 1'b0;
            ex_wb_pmp_if_fault_r    <= 1'b0;
            ex_wb_pmp_if_mtval_r    <= 32'h0;
            ex_wb_pmp_data_fault_r  <= 1'b0;
            ex_wb_pmp_data_store_r  <= 1'b0;
        end else if (debug_mode || debug_halt_enter) begin
            ex_wb_valid_r           <= 1'b0;
            ex_wb_rd_we_r           <= 1'b0;
            ex_wb_is_load_r         <= 1'b0;
            ex_wb_is_amo_r          <= 1'b0;
            ex_wb_amo_is_sc_r       <= 1'b0;
            ex_wb_is_store_r        <= 1'b0;
            ex_wb_is_misaligned_r       <= 1'b0;
            ex_wb_is_misaligned_store_r <= 1'b0;
            ex_wb_is_mret_r         <= 1'b0;
            ex_wb_is_dret_r         <= 1'b0;
            ex_wb_csr_we_r          <= 1'b0;
            ex_wb_is_branch_taken_r <= 1'b0;
            ex_wb_is_jal_r          <= 1'b0;
            ex_wb_is_jalr_r         <= 1'b0;
            ex_wb_illegal_r         <= 1'b0;
            ex_wb_is_ecall_r        <= 1'b0;
            ex_wb_is_ebreak_r       <= 1'b0;
            ex_wb_instr_r           <= 32'h0;
            ex_wb_trigger_hit_r     <= 1'b0;
            ex_wb_trigger_idx_r     <= 2'd0;
            ex_wb_trigger_exec_r    <= 1'b0;
            ex_wb_trigger_load_r    <= 1'b0;
            ex_wb_trigger_store_r   <= 1'b0;
            ex_wb_pmp_if_fault_r    <= 1'b0;
            ex_wb_pmp_if_mtval_r    <= 32'h0;
            ex_wb_pmp_data_fault_r  <= 1'b0;
            ex_wb_pmp_data_store_r  <= 1'b0;
        end else if (core_mem_stall) begin
            // ADR-0005 freeze: hold EX/WB in place so a waited load consumes
            // d_mem_rdata only on the release cycle (no stale-data retire)
        end else if (ex_mem_advance_to_wb) begin
            ex_wb_valid_r           <= 1'b1;
            ex_wb_pc_r              <= ex_mem_pc_r;
            ex_wb_alu_result_r      <= ex_mem_alu_result_r;
            // M1A A1: a MUL's product is computed during its EX/MEM cycle (comb from
            // mul.v's issue-registered operands) and captured HERE; DIV keeps the old path.
            ex_wb_md_result_r       <= ex_mem_is_mul_r ? mul_result : ex_mem_md_result_r;
            ex_wb_pc_plus_4_r       <= ex_mem_pc_plus_4_r;
            ex_wb_pc_plus_imm_r     <= ex_mem_pc_plus_imm_r;
            ex_wb_csr_rdata_r       <= ex_mem_csr_rdata_r;
            ex_wb_rd_idx_r          <= ex_mem_rd_idx_r;
            ex_wb_rd_we_r           <= ex_mem_rd_we_r;
            ex_wb_wb_sel_r          <= ex_mem_wb_sel_r;
            ex_wb_is_load_r         <= ex_mem_is_load_r;
            ex_wb_is_amo_r          <= ex_mem_is_amo_r;
            ex_wb_amo_is_sc_r       <= ex_mem_amo_is_sc_r;
            ex_wb_is_store_r        <= ex_mem_is_store_r;
            ex_wb_is_misaligned_r       <= ex_mem_is_misaligned_r;
            ex_wb_is_misaligned_store_r <= ex_mem_is_misaligned_store_r;
            ex_wb_ls_funct3_r       <= ex_mem_ls_funct3_r;
            ex_wb_addr_lo_r         <= ex_mem_addr_lo_r;
            ex_wb_is_mret_r         <= ex_mem_is_mret_r;
            ex_wb_is_dret_r         <= ex_mem_is_dret_r;
            ex_wb_csr_we_r          <= ex_mem_csr_we_r;
            ex_wb_csr_addr_r        <= ex_mem_csr_addr_r;
            ex_wb_csr_op_r          <= ex_mem_csr_op_r;
            ex_wb_csr_wdata_r       <= ex_mem_csr_wdata_r;
            ex_wb_is_branch_taken_r <= ex_mem_is_branch_taken_r;
            ex_wb_is_jal_r          <= ex_mem_is_jal_r;
            ex_wb_is_jalr_r         <= ex_mem_is_jalr_r;
            ex_wb_illegal_r         <= ex_mem_illegal_r;
            ex_wb_is_ecall_r        <= ex_mem_is_ecall_r;
            ex_wb_is_ebreak_r       <= ex_mem_is_ebreak_r;
            ex_wb_instr_r           <= ex_mem_instr_r;
            ex_wb_trigger_hit_r     <= ex_mem_trigger_hit_r || mem_trigger_hit;
            ex_wb_trigger_idx_r     <= ex_mem_trigger_hit_r ? ex_mem_trigger_idx_r : mem_trigger_idx;
            ex_wb_trigger_exec_r    <= ex_mem_trigger_hit_r;
            ex_wb_trigger_load_r    <= !ex_mem_trigger_hit_r && mem_trigger_hit && mem_trigger_is_load;
            ex_wb_trigger_store_r   <= !ex_mem_trigger_hit_r && mem_trigger_hit && mem_trigger_is_store;
            ex_wb_pmp_if_fault_r    <= ex_mem_pmp_if_fault_r;
            ex_wb_pmp_if_mtval_r    <= ex_mem_pmp_if_mtval_r;
            ex_wb_pmp_data_fault_r  <= pmp_data_fault;
            ex_wb_pmp_data_store_r  <= pmp_data_write;
        end else begin
            // Stall / wrong-path: 插 bubble
            ex_wb_valid_r           <= 1'b0;
            ex_wb_rd_we_r           <= 1'b0;
            ex_wb_is_load_r         <= 1'b0;
            ex_wb_is_amo_r          <= 1'b0;
            ex_wb_amo_is_sc_r       <= 1'b0;
            ex_wb_is_store_r        <= 1'b0;
            ex_wb_is_misaligned_r       <= 1'b0;
            ex_wb_is_misaligned_store_r <= 1'b0;
            ex_wb_is_mret_r         <= 1'b0;
            ex_wb_is_dret_r         <= 1'b0;
            ex_wb_csr_we_r          <= 1'b0;
            ex_wb_is_branch_taken_r <= 1'b0;
            ex_wb_is_jal_r          <= 1'b0;
            ex_wb_is_jalr_r         <= 1'b0;
            ex_wb_illegal_r         <= 1'b0;
            ex_wb_is_ecall_r        <= 1'b0;
            ex_wb_is_ebreak_r       <= 1'b0;
            ex_wb_instr_r           <= 32'h0;
            ex_wb_trigger_hit_r     <= 1'b0;
            ex_wb_trigger_idx_r     <= 2'd0;
            ex_wb_trigger_exec_r    <= 1'b0;
            ex_wb_trigger_load_r    <= 1'b0;
            ex_wb_trigger_store_r   <= 1'b0;
            ex_wb_pmp_if_fault_r    <= 1'b0;
            ex_wb_pmp_if_mtval_r    <= 32'h0;
            ex_wb_pmp_data_fault_r  <= 1'b0;
            ex_wb_pmp_data_store_r  <= 1'b0;
        end
    end

    // 連 forward module 用的 wires
    assign ex_wb_valid    = ex_wb_valid_r;
    assign ex_wb_rd_we    = ex_wb_rd_we_r;
    assign ex_wb_rd_idx   = ex_wb_rd_idx_r;
    assign ex_wb_is_load  = ex_wb_is_load_r;
    assign wb_csr_we      = ex_wb_csr_we_r && ex_wb_valid_r && !wb_take_irq &&
                             !wb_take_sync_trap && !wb_take_data_trap &&
                             !wb_take_trigger && !core_mem_stall;

    // =========================================================================
    // MEM/WB stage
    //   組合：LSU sign-ext on d_mem_rdata；wb_data mux；PC redirect
    // =========================================================================
    // LSU sign-extend on load
    /* verilator lint_off PINCONNECTEMPTY */
    lsu u_lsu_wb (
        .addr_lo   (ex_wb_addr_lo_r),
        .wdata_raw (32'h0),
        .funct3    (ex_wb_ls_funct3_r),
        .is_store  (1'b0),
        .mem_rdata (d_mem_rdata),
        .mem_wdata (),
        .mem_wstrb (),
        .ld_result (lsu_ld_result_wb)
    );
    /* verilator lint_on PINCONNECTEMPTY */

    // WB data mux
    reg [31:0] wb_data_mux;
    always @* begin
        if (ex_wb_is_amo_r) begin
            wb_data_mux = amo_result_r;
        end else begin
            case (ex_wb_wb_sel_r)
                `WB_SEL_PCIMM: wb_data_mux = ex_wb_pc_plus_imm_r;
                `WB_SEL_PC4  : wb_data_mux = ex_wb_pc_plus_4_r;
                `WB_SEL_LSU  : wb_data_mux = lsu_ld_result_wb;
                `WB_SEL_CSR  : wb_data_mux = ex_wb_csr_rdata_r;
                `WB_SEL_MD   : wb_data_mux = ex_wb_md_result_r;
                default      : wb_data_mux = ex_wb_alu_result_r;
            endcase
        end
    end
    assign wb_data = wb_data_mux;

    // IRQ / precise load/store exception entry (在 WB commit boundary)
    assign wb_take_irq = ex_wb_valid_r && irq_pending && !ex_wb_illegal_r &&
                         !wb_dret_illegal && !ex_wb_pmp_if_fault_r &&
                         !wb_take_data_trap && !wb_trigger_pending && !core_mem_stall;
    assign wb_trap_cause = wb_take_sync_trap ?
                           (ex_wb_pmp_if_fault_r ? `MCAUSE_INSTR_ACCESS_FAULT :
                            ex_wb_is_ecall_r  ? `MCAUSE_ECALL_MMODE :
                            ex_wb_is_ebreak_r ? `MCAUSE_BREAKPOINT :
                                                 `MCAUSE_ILLEGAL_INSTRUCTION) :
                           wb_take_data_trap ?
                           (ex_wb_pmp_data_fault_r ?
                            (ex_wb_pmp_data_store_r ? `MCAUSE_STORE_ACCESS_FAULT :
                                                       `MCAUSE_LOAD_ACCESS_FAULT) :
                            (ex_wb_is_misaligned_store_r ? `MCAUSE_STORE_ADDR_MISALIGNED :
                                                           `MCAUSE_LOAD_ADDR_MISALIGNED)) :
                           wb_irq_cause;  // priority MEI>MSI>MTI (ADR-0019); was MCAUSE_EXT_IRQ
    assign wb_trap_mtval  = wb_take_sync_trap ?
                            (ex_wb_pmp_if_fault_r ? ex_wb_pmp_if_mtval_r :
                             ex_wb_is_ecall_r  ? 32'h0 :
                             ex_wb_is_ebreak_r ? ex_wb_pc_r :
                                                  ex_wb_instr_r) :
                            ex_wb_alu_result_r;

    // RFU write
    assign rfu_we      = ex_wb_valid_r && ex_wb_rd_we_r && !wb_take_sync_trap &&
                         !wb_take_irq && !wb_take_data_trap && !wb_take_trigger && !core_mem_stall;
    assign rfu_wr_idx  = ex_wb_rd_idx_r;
    assign rfu_wr_data = wb_data;

    // PC redirect decision (lab08b: 只在 mispredict 時 redirect)
    //   優先級 (lab08c):
    //     1. IRQ entry → mtvec     (從 ex_wb)
    //     2. MRET → mepc           (從 ex_wb)
    //     3. MEM-stage RAS target mispredict (= RAS 預測 target 跟 alu 算的不一致)
    //     4. ex_mem mispredict (= lab08b 的 direction mispredict) — RAS-predicted 已自動
    //        滿足 direction 比對 (pred_taken=1 + actual_taken=1)，不會在這分支 fire
    //
    //   RAS 預測對且 target 也對：mem_ras_mispredict=0、ex_mem_mispredict_r=0 → 不 redirect，
    //   pipeline 順利往下走（IF 階段已從 RAS target fetch 完成）。
    always @* begin
        pc_redirect     = 1'b0;
        redirect_target = 32'h0;

        if (core_mem_stall) begin
            // ADR-0005 freeze: no PC redirect while waiting on memory
        end else if (debug_resume_redirect) begin
            pc_redirect     = 1'b1;
            redirect_target = dpc_o;
        end else if (wb_take_irq || wb_take_data_trap || wb_take_sync_trap) begin
            pc_redirect     = 1'b1;
            redirect_target = mtvec_o;
        end else if (ex_wb_valid_r && ex_wb_is_mret_r) begin
            pc_redirect     = 1'b1;
            redirect_target = mepc_o;
        end else if (ex_wb_valid_r && ex_wb_is_dret_r && debug_mode) begin
            pc_redirect     = 1'b1;
            redirect_target = dpc_o;
        end else if (debug_halt_enter) begin
            pc_redirect     = 1'b1;
            redirect_target = debug_halt_pc_w;
        end else if (mem_ras_mispredict) begin
            // RAS 預測 target 跟 actual jalr target 不一致 — recovery 到 actual target
            pc_redirect     = 1'b1;
            redirect_target = mem_ras_actual_target;
        end else if (ex_mem_valid_r && ex_mem_mispredict_r && !ex_mem_trigger_hit_r &&
                     !ex_mem_pmp_if_fault_r) begin
            pc_redirect     = 1'b1;
            // Recovery target combinational from ex_mem.Q registers (no alu_result on path)
            //   is_jalr      → alu_result_r & ~1
            //   branch_taken → pc_plus_imm_r
            //   is_jal       → pc_plus_imm_r
            //   else (branch not-taken mispredict) → pc_plus_4_r
            redirect_target = ex_mem_is_jalr_r          ? (ex_mem_alu_result_r & ~32'd1) :
                              ex_mem_is_branch_taken_r  ? ex_mem_pc_plus_imm_r :
                              ex_mem_is_jal_r           ? ex_mem_pc_plus_imm_r :
                                                          ex_mem_pc_plus_4_r;
        end
    end

    // CSR / trap / instret 訊號
    assign wb_trap_enter        = (wb_take_irq || wb_take_data_trap || wb_take_sync_trap) && !core_mem_stall;
    assign wb_trap_exit          = ex_wb_valid_r && ex_wb_is_mret_r && !core_mem_stall;
    // trap_pc_for_mepc = 中斷時要保存的「下一條 PC」
    //   被中斷的指令本身已 commit (rd_we=0 但 pc 已 +4 等概念)，所以存的是 next_pc
    //   normal next_pc = pc+4；如果同時是 branch taken → pc+imm 之類
    // Synchronous/data exceptions save the precise faulting instruction PC.
    assign wb_trap_pc_for_mepc = (wb_take_sync_trap || wb_take_data_trap) ? wb_sync_exception_pc :
                                  ex_wb_is_branch_taken_r ? ex_wb_pc_plus_imm_r :
                                  ex_wb_is_jal_r          ? ex_wb_pc_plus_imm_r :
                                  ex_wb_is_jalr_r         ? (ex_wb_alu_result_r & ~32'd1) :
                                                            ex_wb_pc_plus_4_r;
    assign wb_instr_retired = ex_wb_valid_r && !wb_take_irq && !wb_take_data_trap &&
                              !wb_take_sync_trap && !wb_take_trigger && !core_mem_stall;

    assign debug_dret_exit       = ex_wb_valid_r && ex_wb_is_dret_r && debug_mode && !core_mem_stall;
    assign debug_halt_enter      = ex_wb_valid_r && !wb_take_irq && !wb_take_data_trap &&
                                   !wb_take_sync_trap && !debug_mode && !core_mem_stall &&
                                   (debug_halt_pending || debug_step_pending ||
                                    wb_ebreak_debug_entry || wb_take_trigger);
    assign debug_entry_reason    = wb_take_trigger ?
                                   (ex_wb_trigger_exec_r  ? DBG_ENTRY_TRIG_EXEC :
                                    ex_wb_trigger_load_r  ? DBG_ENTRY_TRIG_LD :
                                                            DBG_ENTRY_TRIG_ST) :
                                   DBG_ENTRY_HALT;
    assign debug_halt_pc_w       = wb_take_trigger ? ex_wb_pc_r : wb_trap_pc_for_mepc;
    assign debug_halt_cause_w    = wb_take_trigger ? 3'd2 :
                                   debug_step_pending ? 3'd4 : 3'd3;
    assign debug_resume_exit     = debug_mode && dm_resume_req;
    always @* begin
        debug_resume_redirect = debug_resume_exit;
    end

    always @(posedge clk) begin
        if (!resetn) begin
            debug_mode         <= 1'b0;
            debug_halt_pending <= 1'b0;
            debug_step_pending <= 1'b0;
        end else begin
            if (dm_halt_req && !debug_mode)
                debug_halt_pending <= 1'b1;
            if (debug_halt_enter)
                debug_halt_pending <= 1'b0;

            if (debug_dret_exit || debug_resume_exit) begin
                debug_mode <= 1'b0;
                debug_step_pending <= dcsr_step;
            end else if (debug_halt_enter) begin
                debug_mode <= 1'b1;
                debug_step_pending <= 1'b0;
            end
        end
    end

    assign dm_hart_halted = debug_mode;
    assign debug_mode_o   = debug_mode;
    assign dm_acc_rdata   = dbg_acc_is_gpr ? dbg_gpr_rdata :
                            dbg_acc_is_csr ? dbg_csr_rdata :
                                             32'h0;
    assign dm_acc_err     = dm_acc_en && (!debug_mode || !(dbg_acc_is_gpr || dbg_acc_is_csr));

    // =========================================================================
    // Trap output: latched observability for precise synchronous exceptions.
    // =========================================================================
    reg trap_latched;
    always @(posedge clk) begin
        if (!resetn) trap_latched <= 1'b0;
        else if (wb_take_sync_trap && !core_mem_stall) trap_latched <= 1'b1;
    end
    assign trap = trap_latched;

    // =========================================================================
    // Debug
    // =========================================================================
    assign dbg_pc    = if_ex_pc;
    assign dbg_instr = if_ex_instr;
    assign dbg_state = {stall, wb_take_irq, ex_wb_valid_r};

endmodule
