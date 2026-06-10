//      // verilator_coverage annotation
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
        
        module core (
 001315     input             clk,
%000005     input             resetn,
%000005     output            trap,
        
            // I-port (instr fetch, sync read-only)
~000213     output     [31:0] i_mem_addr,
~000036     output            i_mem_en,        // gates BRAM update; =!stall (lab06 新加)
~000134     input      [31:0] i_mem_rdata,
        
            // D-port (data load/store)
 000050     output            d_mem_valid,
~000102     output     [31:0] d_mem_addr,
~000080     output     [31:0] d_mem_wdata,
 000020     output     [ 3:0] d_mem_wstrb,
~000021     input      [31:0] d_mem_rdata,
        
            // External IRQ
%000001     input             irq_external_pulse,
        
            // Debug
~000200     output     [31:0] dbg_pc,
~000136     output     [31:0] dbg_instr,
~000195     output     [ 2:0] dbg_state
        );
        
            // =========================================================================
            // Reset / warmup
            // =========================================================================
%000005     reg warmup;
 001315     always @(posedge clk) begin
~001290         if (!resetn) warmup <= 1'b1;
 001290         else         warmup <= 1'b0;   // 1 cycle bubble after reset (BRAM warm)
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
~000205     wire [31:0] if_pc;        // = pc_reg (current decode PC)
~000205     wire [31:0] next_pc_w;    // combinational from ifu
%000003     reg         pc_redirect;
%000002     reg  [31:0] redirect_target;
~000031     wire        stall;         // load-use / muldiv stall (existing)
%000003     wire        flush_if_next; // bubble next-cycle IF/EX
        
            // Lab08c: BP (64-entry 2-way) + RAS (8-entry)
%000001     wire        bp_predict_taken;
%000001     wire [31:0] bp_predict_target;
%000002     wire        bp_upd_valid;
~000200     wire [31:0] bp_upd_pc;
%000001     wire        bp_upd_taken;
~000121     wire [31:0] bp_upd_target;
        
%000000     wire [31:0] ras_top;
%000000     wire        ras_push;
~000205     wire [31:0] ras_push_val;
%000000     wire        ras_pop;
        
            // Lab08e: residue-based pre-fetch (replaces wait_high + high_buf)
~000077     reg [15:0]  residue;        // saved high-half for upcoming cross-boundary assemble
~000176     reg         cross_assemble; // 1 = this cycle: assemble {i_mem_rdata[15:0], residue}
        
            // ---- Pre-decode i_mem_rdata for instruction length ----
~000109     wire [15:0] cur_half_lo = i_mem_rdata[15:0];
~000134     wire [15:0] cur_half_hi = i_mem_rdata[31:16];
~000027     wire        is_comp_lo  = (cur_half_lo[1:0] != 2'b11);
~000063     wire        is_comp_hi  = (cur_half_hi[1:0] != 2'b11);
        
~000020     wire        cur_at_high = if_pc[1];   // current instr at high half of fetched word
        
            // at_cross_boundary: fallback — arrived at cross-boundary without pre-setup
            // (happens after stall / redirect blocked upcoming_cross the previous cycle)
~000167     wire        at_cross_boundary = cur_at_high && !is_comp_hi && !cross_assemble;
        
            // upcoming_cross: sequential 16-bit at low half, FOLLOWED BY 32-bit at high half
            // Only fires when current instr is 16-bit at low half AND high half is 32-bit start,
            // with no prediction override or stall this cycle. Guarantees residue = correct high-half.
%000009     wire        upcoming_cross = !cur_at_high && is_comp_lo && !is_comp_hi &&
                                          !cross_assemble && !stall && !warmup && !pc_redirect &&
                                          !bp_predict_taken && !ras_predict_ret;
        
            // is_16bit signal (drives ifu pc_inc)
~001064     wire        is_16bit_w = cross_assemble  ? 1'b0 :       // assembled cross = 32-bit
 000877                               cur_at_high    ? is_comp_hi :
 000877                                                is_comp_lo;
        
            // fetch_stall: only fallback cross-boundary detection (not upcoming_cross path)
~000167     wire        fetch_stall = at_cross_boundary;
~000195     wire        any_stall   = stall | fetch_stall | warmup;
        
            // ---- Compressed expander ----
~000877     wire [15:0] cinstr   = cur_at_high ? cur_half_hi : cur_half_lo;
~000020     wire [31:0] cdec_expanded;
 000023     wire        cdec_illegal;
            cdec u_cdec (
                .cinstr   (cinstr),
                .expanded (cdec_expanded),
                .illegal  (cdec_illegal)
            );
        
            // ---- Assembled 32-bit instruction (output to if_ex) ----
            // cross_assemble: {new_word[15:0], residue} — both from registers (short path)
            // compressed: cdec output
            // aligned 32-bit (PC[1]=0): i_mem_rdata directly
            // (at_cross_boundary case produces garbage but any_stall=1 prevents latching)
~000198     wire [31:0] instr_assembled =
~001064         cross_assemble  ? {cur_half_lo, residue} :
 001019         is_16bit_w      ? cdec_expanded :
 001019                           i_mem_rdata;
        
            // ---- RET detection (for RAS pop) ----
            // lab08e v3: check only opcode+rd+funct3+rs1, not imm bits [31:20].
            // Full equality (== 32'h00008067) pulled cdec_expanded[23] (imm[11]) into the
            // ras_predict_ret→next_pc→i_mem_addr path via CDec case-select (cinstr[14], fo=44,
            // 6 LUT levels) → fo=26 routing bottleneck.  Imm is irrelevant for RAS prediction.
%000000     wire if_is_ret_32  = (instr_assembled[6:0]  == 7'b1100111) &&  // JALR opcode
                                 (instr_assembled[11:7]  == 5'b00000)   &&  // rd = x0
                                 (instr_assembled[14:12] == 3'b000)     &&  // funct3 = 0
                                 (instr_assembled[19:15] == 5'b00001);      // rs1 = ra (x1)
%000000     wire if_is_ret_16  = is_16bit_w && (cinstr == 16'h8082);
%000000     wire if_is_ret     = if_is_ret_32 || if_is_ret_16;
        
%000000     wire        ras_valid      = (ras_top != 32'h0);
%000000     wire        ras_predict_ret = if_is_ret && ras_valid && !any_stall && !pc_redirect;
        
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
        
            ifu u_ifu (
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
            //   upcoming_cross:    pre-fetch next word one cycle early (if_pc[1]=0 → +4 = next word)
            //   else:              look-ahead via next_pc_w (normal)
~001153     assign i_mem_addr = at_cross_boundary ? (if_pc + 32'd2) :
~001144                         upcoming_cross    ? (if_pc + 32'd4) :
 001144                                             next_pc_w;
            // Keep BRAM active during at_cross_boundary even if lu/md stall fires simultaneously.
            // (same fix as lab08d §problems_log 1, but now only needed for fallback path)
            assign i_mem_en   = !stall || at_cross_boundary;
        
            // ---- Cross-boundary state machine ----
 001315     always @(posedge clk) begin
~001290         if (!resetn || pc_redirect) begin
~000025             cross_assemble <= 1'b0;
~000025             residue        <= 16'h0;
%000009         end else if (upcoming_cross) begin
                    // Pre-fetch path: no stall, save high-half for next cycle assembly
%000009             cross_assemble <= 1'b1;
%000009             residue        <= cur_half_hi;
~001114         end else if (at_cross_boundary && !warmup) begin
                    // Fallback path: stall this cycle, set up for stall-free assembly next cycle
~000167             cross_assemble <= 1'b1;
~000167             residue        <= cur_half_hi;
~000698         end else if (!any_stall) begin
                    // Only clear when pipeline can advance; hold through stalls so BRAM data stays valid
 000416             cross_assemble <= 1'b0;
                end
            end
        
            // =========================================================================
            // IF/EX pipeline register
            // =========================================================================
~000136     reg [31:0] if_ex_instr;
~000200     reg [31:0] if_ex_pc;
%000005     reg        if_ex_valid;
%000001     reg        if_ex_pred_taken;
%000000     reg        if_ex_pred_ras;
%000000     reg [31:0] if_ex_pred_ras_target;
~000018     reg        if_ex_is_16bit;  // instruction size flag for correct mepc / link-addr
        
 001315     always @(posedge clk) begin
~001290         if (!resetn) begin
~000025             if_ex_instr      <= 32'h0;
~000025             if_ex_pc         <= 32'h0;
~000025             if_ex_valid      <= 1'b0;
~000025             if_ex_pred_taken <= 1'b0;
~000025             if_ex_pred_ras   <= 1'b0;
~000025             if_ex_is_16bit   <= 1'b0;
~000865         end else if (any_stall) begin
                    // hold (load-use / muldiv / at_cross_boundary stall)
~000425         end else if (flush_if_next || warmup) begin
%000003             if_ex_instr      <= 32'h0;
%000003             if_ex_pc         <= 32'h0;
%000003             if_ex_valid      <= 1'b0;
%000003             if_ex_pred_taken <= 1'b0;
%000003             if_ex_pred_ras   <= 1'b0;
%000003             if_ex_is_16bit   <= 1'b0;
 000425         end else begin
 000425             if_ex_instr           <= instr_assembled;
 000425             if_ex_pc              <= if_pc;
 000425             if_ex_valid           <= 1'b1;
~000425             if_ex_pred_taken      <= bp_predict_taken | ras_predict_ret;
 000425             if_ex_pred_ras        <= ras_predict_ret;
 000425             if_ex_is_16bit        <= is_16bit_w;
 000425             if_ex_pred_ras_target <= ras_top;
                end
            end
        
            assign flush_if_next = pc_redirect;
        
            // =========================================================================
            // IDU (decode if_ex_instr，純組合)
            // =========================================================================
~000136     wire [ 4:0] id_rd_idx, id_rs1_idx, id_rs2_idx;
~000091     wire [31:0] id_imm;
~000058     wire [ 3:0] id_alu_op;
 000070     wire        id_alu_b_use_imm;
 000038     wire        id_rd_we;
~000053     wire [ 2:0] id_wb_sel;
%000000     wire        id_is_branch, id_branch_invert;
~000062     wire [ 1:0] id_br_type;          // funct3[2:1]: 00=eq 10=lt_s 11=lt_u
%000003     wire        id_is_jal, id_is_jalr;
~000029     wire        id_is_load, id_is_store;
~000063     wire [ 2:0] id_ls_funct3;
~000014     wire        id_is_csr;
~000063     wire [ 1:0] id_csr_op;
~000062     wire        id_csr_uses_imm;
~000106     wire [11:0] id_csr_addr;
~000074     wire [31:0] id_csr_zimm;
%000001     wire        id_is_mret;
~000025     wire        id_is_muldiv;
~000063     wire [ 2:0] id_md_op;
~000062     wire        id_md_is_div;
~000013     wire        id_illegal;
        
            idu u_idu (
                .instr         (if_ex_instr),
                .rd_idx        (id_rd_idx),
                .rs1_idx       (id_rs1_idx),
                .rs2_idx       (id_rs2_idx),
                .imm           (id_imm),
                .alu_op        (id_alu_op),
                .alu_b_use_imm (id_alu_b_use_imm),
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
                .is_csr        (id_is_csr),
                .csr_op        (id_csr_op),
                .csr_uses_imm  (id_csr_uses_imm),
                .csr_addr      (id_csr_addr),
                .csr_zimm      (id_csr_zimm),
                .is_mret       (id_is_mret),
                .is_muldiv     (id_is_muldiv),
                .md_op         (id_md_op),
                .md_is_div     (id_md_is_div),
                .illegal       (id_illegal)
            );
        
            // =========================================================================
            // RFU (組合讀，同步寫)
            // =========================================================================
~000077     wire [31:0] rfu_rs1_data, rfu_rs2_data;
 000214     wire        rfu_we;
~000133     wire [ 4:0] rfu_wr_idx;
~000094     wire [31:0] rfu_wr_data;
        
            rfu u_rfu (
                .clk      (clk),
                .rs1_idx  (id_rs1_idx),
                .rs1_data (rfu_rs1_data),
                .rs2_idx  (id_rs2_idx),
                .rs2_data (rfu_rs2_data),
                .we       (rfu_we),
                .rd_idx   (rfu_wr_idx),
                .rd_data  (rfu_wr_data)
            );
        
            // =========================================================================
            // Forwarding (lab06b: 2 sources, EX/MEM + EX/WB → ID/EX)
            // =========================================================================
~000094     wire [31:0] wb_data;
~000195     wire        ex_wb_valid;
 000214     wire        ex_wb_rd_we;
~000133     wire [ 4:0] ex_wb_rd_idx;
~000031     wire        ex_wb_is_load;
        
            // EX/MEM forward value (= alu_result 或 pc+imm / pc+4 / csr / md)
~000096     reg [31:0] ex_mem_fwd_val;
 001320     always @* begin
 001320         case (ex_mem_wb_sel_r)
%000005             `WB_SEL_PCIMM: ex_mem_fwd_val = ex_mem_pc_plus_imm_r;
~000287             `WB_SEL_PC4  : ex_mem_fwd_val = ex_mem_pc_plus_4_r;
~000014             `WB_SEL_CSR  : ex_mem_fwd_val = ex_mem_csr_rdata_r;
~000181             `WB_SEL_MD   : ex_mem_fwd_val = ex_mem_md_result_r;
 001134             default      : ex_mem_fwd_val = ex_mem_alu_result_r;
                endcase
            end
        
~000080     wire [31:0] rs1_val, rs2_val;
            forward u_forward (
                .id_rs1_idx   (id_rs1_idx),
                .id_rs2_idx   (id_rs2_idx),
                .rfu_rs1_data (rfu_rs1_data),
                .rfu_rs2_data (rfu_rs2_data),
                .em_valid     (ex_mem_valid_r),
                .em_rd_we     (ex_mem_rd_we_r),
                .em_rd_idx    (ex_mem_rd_idx_r),
                .em_fwd_val   (ex_mem_fwd_val),
                .em_is_load   (ex_mem_is_load_r),
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
~000059     wire [31:0] alu_op_a = rs1_val;
~000864     wire [31:0] alu_op_b = id_alu_b_use_imm ? id_imm : rs2_val;
~000103     wire [31:0] alu_result;
 000065     wire        alu_cmp_eq, alu_cmp_lt_s, alu_cmp_lt_u;
        
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
~000867     wire branch_cond  = (id_br_type == 2'b00) ? alu_cmp_eq  :
~000498                         (id_br_type == 2'b10) ? alu_cmp_lt_s : alu_cmp_lt_u;
%000000     wire branch_taken = id_is_branch && (id_branch_invert ^ branch_cond);
        
            // pc + imm (給 JAL / branch target / AUIPC)
            // Use actual instruction size (16-bit→+2, 32-bit→+4) for link address and mepc
~000205     wire [31:0] if_ex_pc_plus_4   = if_ex_pc + (if_ex_is_16bit ? 32'd2 : 32'd4);
~000121     wire [31:0] if_ex_pc_plus_imm = if_ex_pc + id_imm;
        
            // ---- Lab08b: BP mispredict detection (direction-only, JALR excluded) ----
            //
            // 跟 lab08 同設計：BTB 只存 branch/JAL (target = pc+imm 是 deterministic)
            // 所以不 verify target；JALR 不進 BTB → 永遠 predict not-taken → 永遠 1
            // mispredict 但 ≈ lab06b baseline (lab06b JALR 也是 normal 3-cycle penalty)。
%000003     wire ex_actual_taken = if_ex_valid && (branch_taken | id_is_jal | id_is_jalr);
        
            // 只比 direction (1-bit XOR)：pred_taken=1 + actual=1 (any target) → no flush
%000002     wire ex_mispredict = if_ex_valid && (if_ex_pred_taken != ex_actual_taken);
        
            // Recovery target NOT computed here — moved to MEM stage (combinational from
            // ex_mem.Q registers) to keep alu_result off the redirect_target.D path
        
            // BP update：combinational in EX，latch 進 ex_mem_bp_upd_* register，下一拍才
            // drive bp.v 的 upd port → BP counter_arr.D 跟 target_arr.D path 從 register
            // output 出發 (不再有 alu_result 進 BP write data 路徑)
%000002     wire        ex_bp_upd_valid  = if_ex_valid && (id_is_branch | id_is_jal)
                                                      && !stall && !pc_redirect;
~000200     wire [31:0] ex_bp_upd_pc     = if_ex_pc;
%000003     wire        ex_bp_upd_taken  = ex_actual_taken;
~000121     wire [31:0] ex_bp_upd_target = if_ex_pc_plus_imm;
        
            // Lab08c: RAS push — 偵測 IF/EX 是 JAL ra (id_is_jal && rd == x1)，push pc+4
            //         （= 函式 return address）。Gating 跟 bp_upd 同：!stall, !pc_redirect
            assign ras_push     = if_ex_valid && id_is_jal && (id_rd_idx == 5'd1)
                                              && !stall && !pc_redirect;
            assign ras_push_val = if_ex_pc_plus_4;
        
            // =========================================================================
            // MUL / DIV units
            // =========================================================================
            // 兩個共用一條 start / done / result 介面 (透過 md_is_div 路由)
~000019     wire        mul_done, div_done;
%000007     wire [31:0] mul_result, div_result;
~000031     reg         md_started;
%000007     reg         md_active_is_div;
~000031     reg         md_result_valid;
%000009     reg  [31:0] md_result_q;
~000809     wire        md_done = md_active_is_div ? div_done : mul_done;
~000031     wire        md_busy = if_ex_valid && id_is_muldiv && !md_result_valid;
%000009     wire [31:0] md_result = md_result_q;
        
~000031     wire md_start = if_ex_valid && id_is_muldiv && !md_started && !md_result_valid;
        
 001315     always @(posedge clk) begin
~001290         if (!resetn) begin
~000025             md_started       <= 1'b0;
~000025             md_active_is_div <= 1'b0;
~000025             md_result_valid  <= 1'b0;
~000025             md_result_q      <= 32'h0;
~000031         end else if (md_done) begin
~000031             md_started      <= 1'b0;
~000031             md_result_valid <= 1'b1;
~000031             md_result_q     <= md_active_is_div ? div_result : mul_result;
~001228         end else if (id_advance_to_ex_mem && md_result_valid) begin
~000031             md_result_valid <= 1'b0;
~001197         end else if (md_start) begin
~000031             md_started       <= 1'b1;
~000031             md_active_is_div <= id_md_is_div;
                end
            end
        
            mul u_mul (
                .clk    (clk),
                .resetn (resetn),
                .start  (md_start && !id_md_is_div),
                .md_op  (id_md_op),
                .op_a   (rs1_val),
                .op_b   (rs2_val),
                .result (mul_result),
                .done   (mul_done)
            );
        
            div u_div (
                .clk    (clk),
                .resetn (resetn),
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
~000080     wire [31:0] lsu_mem_wdata_id;
 000019     wire [ 3:0] lsu_mem_wstrb_id;
~000055     wire [31:0] lsu_ld_result_wb;       // 計算在 MEM/WB stage
        
            // lab08e v3: store_addr_lo[1:0] = rs1[1:0] + imm[1:0], 2-bit adder.
            // (rs1+imm)[1:0] == (rs1[1:0]+imm[1:0])[1:0] — lower bits independent of upper carries.
            // Bypasses 32-bit ALU CARRY4 chain; wstrb only needs addr[1:0].
~000103     wire [1:0] store_addr_lo = rs1_val[1:0] + id_imm[1:0];
        
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
        
            // 對外 d-port：MEM stage 驅動 (lab06b: 從 ex_mem.Q 出，不是 ID/EX 組合)
            //   d_mem_addr 走 register output → 切開 lab06 的 "BRAM → ALU → d_mem WEA" 長路徑
            //   id_mem_active 仍在 ID/EX 算 (寫 ex_mem 用)
 000045     wire id_mem_active = (id_is_load || id_is_store) && if_ex_valid && !stall &&
                                 !pc_redirect && !warmup;
            // 從 ex_mem register 驅動 d-port (MEM stage)
            assign d_mem_valid = ex_mem_valid_r && (ex_mem_is_load_r || ex_mem_is_store_r) &&
                                 !pc_redirect;
            assign d_mem_addr  = ex_mem_alu_result_r;
            assign d_mem_wdata = ex_mem_store_wdata_r;
 000033     assign d_mem_wstrb = ex_mem_is_store_r && ex_mem_valid_r && !pc_redirect ?
 001287                          ex_mem_store_wstrb_r : 4'h0;
        
            // =========================================================================
            // CSR (lab05 同款，但 instr_retired 改成「EX/WB stage commits a valid instr」)
            // =========================================================================
~000786     wire [31:0] id_csr_wdata = id_csr_uses_imm ? id_csr_zimm : rs1_val;
%000006     wire        id_csr_we_logic = id_is_csr &&
                                          ((id_csr_op == `CSR_OP_W) || (id_csr_wdata != 32'h0));
        
%000006     wire [31:0] csr_rdata;
%000001     wire [31:0] mtvec_o, mepc_o;
%000001     wire        irq_pending;
        
            // CSR write happens in EX/WB stage (latched into ex_wb register)
%000006     wire        wb_csr_we;
%000001     wire        wb_trap_enter, wb_trap_exit;
~000200     wire [31:0] wb_trap_pc_for_mepc;
~000195     wire        wb_instr_retired;
        
            csr u_csr (
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
                .irq_external_pulse (irq_external_pulse),
                .mtvec_o            (mtvec_o),
                .mepc_o             (mepc_o),
                .irq_pending        (irq_pending)
            );
        
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
                .em_is_load   (ex_mem_is_load_r),
                .wb_valid     (ex_wb_valid),
                .wb_rd_we     (ex_wb_rd_we),
                .wb_rd_idx    (ex_wb_rd_idx),
                .wb_is_load   (ex_wb_is_load),
                .md_busy      (md_busy),
                .stall        (stall)
            );
        
            // =========================================================================
            // EX/MEM pipeline register (NEW in lab06b)
            //   存：control signals + ALU result + branch decide + store data
            //   ALU output 在這裡 latch → 下一拍 d_mem_addr 從 register Q 驅動
            //   PC redirect 在 MEM stage 從 ex_mem.Q 出 (branch penalty 跟 lab06 同 3 cycle)
            // =========================================================================
~000195     reg        ex_mem_valid_r;
~000200     reg [31:0] ex_mem_pc_r;
~000102     reg [31:0] ex_mem_alu_result_r;
%000009     reg [31:0] ex_mem_md_result_r;
~000200     reg [31:0] ex_mem_pc_plus_4_r;
~000121     reg [31:0] ex_mem_pc_plus_imm_r;
%000006     reg [31:0] ex_mem_csr_rdata_r;
~000134     reg [ 4:0] ex_mem_rd_idx_r;
 000215     reg        ex_mem_rd_we_r;
~000053     reg [ 2:0] ex_mem_wb_sel_r;
~000031     reg        ex_mem_is_load_r;
 000029     reg        ex_mem_is_store_r;
~000062     reg [ 2:0] ex_mem_ls_funct3_r;
~000090     reg [ 1:0] ex_mem_addr_lo_r;
~000080     reg [31:0] ex_mem_store_wdata_r;       // wstrb 一起 register
 000020     reg [ 3:0] ex_mem_store_wstrb_r;
%000001     reg        ex_mem_is_mret_r;
%000006     reg        ex_mem_csr_we_r;
~000104     reg [11:0] ex_mem_csr_addr_r;
~000062     reg [ 1:0] ex_mem_csr_op_r;
~000066     reg [31:0] ex_mem_csr_wdata_r;
%000000     reg        ex_mem_is_branch_taken_r;
%000002     reg        ex_mem_is_jal_r;
%000000     reg        ex_mem_is_jalr_r;
%000008     reg        ex_mem_illegal_r;
            // Lab08b: BP mispredict 取代「無條件 branch_taken/jal/jalr → redirect」
            // 注意：不 latch recovery_target — 在 MEM stage 用 ex_mem.Q registers 組合算
            //       (避免 alu_result → ex_mem_recovery_target_r.D 的 critical path)
%000001     reg        ex_mem_mispredict_r;
            // Lab08b: BP update path register (避免 alu_result→counter_arr/target_arr.D
            // 的 critical path；多 1 cycle update latency，但對 hot-loop 命中率影響忽略)
%000002     reg        ex_mem_bp_upd_valid_r;
~000200     reg [31:0] ex_mem_bp_upd_pc_r;
%000001     reg        ex_mem_bp_upd_taken_r;
~000121     reg [31:0] ex_mem_bp_upd_target_r;
            // Lab08c: RAS prediction info forwarded to MEM stage for target verify
%000000     reg        ex_mem_pred_ras_r;
%000000     reg [31:0] ex_mem_pred_ras_target_r;
        
            // ID/EX → EX/MEM 推進條件
            // Lab08e: !any_stall (= 不在 lu/md/at_cross_boundary/warmup stall 期間)。
~000195     wire id_advance_to_ex_mem = !any_stall && if_ex_valid && !warmup && !pc_redirect;
        
 001315     always @(posedge clk) begin
~001290         if (!resetn) begin
~000025             ex_mem_valid_r           <= 1'b0;
~000025             ex_mem_rd_we_r           <= 1'b0;
~000025             ex_mem_is_load_r         <= 1'b0;
~000025             ex_mem_is_store_r        <= 1'b0;
~000025             ex_mem_store_wstrb_r     <= 4'h0;
~000025             ex_mem_is_mret_r         <= 1'b0;
~000025             ex_mem_csr_we_r          <= 1'b0;
~000025             ex_mem_is_branch_taken_r <= 1'b0;
~000025             ex_mem_is_jal_r          <= 1'b0;
~000025             ex_mem_is_jalr_r         <= 1'b0;
~000025             ex_mem_illegal_r         <= 1'b0;
~000025             ex_mem_mispredict_r      <= 1'b0;
~000025             ex_mem_bp_upd_valid_r    <= 1'b0;
~000025             ex_mem_pred_ras_r        <= 1'b0;
 000870         end else if (id_advance_to_ex_mem) begin
 000420             ex_mem_valid_r           <= 1'b1;
 000420             ex_mem_pc_r              <= if_ex_pc;
 000420             ex_mem_alu_result_r      <= alu_result;
 000420             ex_mem_md_result_r       <= md_result;
 000420             ex_mem_pc_plus_4_r       <= if_ex_pc_plus_4;
 000420             ex_mem_pc_plus_imm_r     <= if_ex_pc_plus_imm;
 000420             ex_mem_csr_rdata_r       <= csr_rdata;
 000420             ex_mem_rd_idx_r          <= id_rd_idx;
 000420             ex_mem_rd_we_r           <= id_rd_we;
 000420             ex_mem_wb_sel_r          <= id_wb_sel;
 000420             ex_mem_is_load_r         <= id_is_load;
 000420             ex_mem_is_store_r        <= id_is_store;
 000420             ex_mem_ls_funct3_r       <= id_ls_funct3;
 000420             ex_mem_addr_lo_r         <= alu_result[1:0];
 000420             ex_mem_store_wdata_r     <= lsu_mem_wdata_id;
 000420             ex_mem_store_wstrb_r     <= id_is_store && id_mem_active ? lsu_mem_wstrb_id : 4'h0;
 000420             ex_mem_is_mret_r         <= id_is_mret;
 000420             ex_mem_csr_we_r          <= id_csr_we_logic;
 000420             ex_mem_csr_addr_r        <= id_csr_addr;
 000420             ex_mem_csr_op_r          <= id_csr_op;
 000420             ex_mem_csr_wdata_r       <= id_csr_wdata;
 000420             ex_mem_is_branch_taken_r <= branch_taken;
 000420             ex_mem_is_jal_r          <= id_is_jal;
 000420             ex_mem_is_jalr_r         <= id_is_jalr;
 000420             ex_mem_illegal_r         <= id_illegal;
 000420             ex_mem_mispredict_r      <= ex_mispredict;
 000420             ex_mem_bp_upd_valid_r    <= ex_bp_upd_valid;
 000420             ex_mem_bp_upd_pc_r       <= ex_bp_upd_pc;
 000420             ex_mem_bp_upd_taken_r    <= ex_bp_upd_taken;
 000420             ex_mem_bp_upd_target_r   <= ex_bp_upd_target;
 000420             ex_mem_pred_ras_r        <= if_ex_pred_ras;
 000420             ex_mem_pred_ras_target_r <= if_ex_pred_ras_target;
 000870         end else begin
                    // Stall / wrong-path / warmup: 插 bubble
 000870             ex_mem_valid_r           <= 1'b0;
 000870             ex_mem_rd_we_r           <= 1'b0;
 000870             ex_mem_is_load_r         <= 1'b0;
 000870             ex_mem_is_store_r        <= 1'b0;
 000870             ex_mem_store_wstrb_r     <= 4'h0;
 000870             ex_mem_is_mret_r         <= 1'b0;
 000870             ex_mem_csr_we_r          <= 1'b0;
 000870             ex_mem_is_branch_taken_r <= 1'b0;
 000870             ex_mem_is_jal_r          <= 1'b0;
 000870             ex_mem_is_jalr_r         <= 1'b0;
 000870             ex_mem_illegal_r         <= 1'b0;
 000870             ex_mem_mispredict_r      <= 1'b0;
 000870             ex_mem_bp_upd_valid_r    <= 1'b0;
 000870             ex_mem_pred_ras_r        <= 1'b0;
                end
            end
        
            // Lab08c: MEM-stage RAS target verify (combinational from ex_mem.Q)
            //   pred_ras=1 表示 IF 階段 RAS 預測這條 jalr 的 target；現在比對 alu_result 是否相同
            //   alu_result for jalr = rs1 + imm = ra (因為 ret 是 jalr x0, ra, 0)，& ~1 mask LSB
            //   mismatch → fire 額外 redirect (priority 比 ex_mem_mispredict 高)
~000102     wire [31:0] mem_ras_actual_target = ex_mem_alu_result_r & ~32'd1;
%000000     wire        mem_ras_mispredict    = ex_mem_valid_r && ex_mem_pred_ras_r
                                             && (mem_ras_actual_target != ex_mem_pred_ras_target_r);
        
            // BP update 用 ex_mem_bp_upd_* register output 驅動 (1 cycle delay)
            assign bp_upd_valid  = ex_mem_bp_upd_valid_r;
            assign bp_upd_pc     = ex_mem_bp_upd_pc_r;
            assign bp_upd_taken  = ex_mem_bp_upd_taken_r;
            assign bp_upd_target = ex_mem_bp_upd_target_r;
        
            // =========================================================================
            // EX/WB pipeline register
            //   存：給 WB stage 用的 control + data (從 ex_mem.Q 傳過來)
            //   load 在這 stage 才看到 d_mem_rdata (BRAM 1-cycle latency 對齊)
            // =========================================================================
~000195     reg        ex_wb_valid_r;
            /* verilator lint_off UNUSEDSIGNAL */  // 留作 debug; trap_pc 走 pc_plus_4 路徑
~000200     reg [31:0] ex_wb_pc_r;
            /* verilator lint_on UNUSEDSIGNAL */
~000101     reg [31:0] ex_wb_alu_result_r;
%000009     reg [31:0] ex_wb_md_result_r;
~000200     reg [31:0] ex_wb_pc_plus_4_r;
~000121     reg [31:0] ex_wb_pc_plus_imm_r;
%000006     reg [31:0] ex_wb_csr_rdata_r;
~000133     reg [ 4:0] ex_wb_rd_idx_r;
 000214     reg        ex_wb_rd_we_r;
~000053     reg [ 2:0] ex_wb_wb_sel_r;
~000031     reg        ex_wb_is_load_r;
            /* verilator lint_off UNUSEDSIGNAL */
 000029     reg        ex_wb_is_store_r;   // store 在 MEM 已 commit 到 d-port，WB 不用
            /* verilator lint_on UNUSEDSIGNAL */
~000062     reg [ 2:0] ex_wb_ls_funct3_r;
~000090     reg [ 1:0] ex_wb_addr_lo_r;
%000001     reg        ex_wb_is_mret_r;
%000006     reg        ex_wb_csr_we_r;
~000104     reg [11:0] ex_wb_csr_addr_r;
~000062     reg [ 1:0] ex_wb_csr_op_r;
~000066     reg [31:0] ex_wb_csr_wdata_r;
%000000     reg        ex_wb_is_branch_taken_r;
%000002     reg        ex_wb_is_jal_r;
%000000     reg        ex_wb_is_jalr_r;
%000005     reg        ex_wb_illegal_r;
        
            // EX/MEM → EX/WB 推進條件
            //   branch/JAL/JALR 在 ex_mem 觸發 pc_redirect 不影響自己 advance 到 WB
            //   只有 wb_redirect (IRQ/MRET 從 ex_wb 觸發) 才 flush ex_mem (= wrong-path)
%000001     wire wb_take_irq;                          // forward-declare (定義在後面)
%000002     wire wb_redirect = wb_take_irq || (ex_wb_valid_r && ex_wb_is_mret_r);
~000195     wire ex_mem_advance_to_wb = ex_mem_valid_r && !wb_redirect;
        
 001315     always @(posedge clk) begin
~001290         if (!resetn) begin
~000025             ex_wb_valid_r           <= 1'b0;
~000025             ex_wb_pc_r              <= 32'h0;
~000025             ex_wb_alu_result_r      <= 32'h0;
~000025             ex_wb_md_result_r       <= 32'h0;
~000025             ex_wb_pc_plus_4_r       <= 32'h0;
~000025             ex_wb_pc_plus_imm_r     <= 32'h0;
~000025             ex_wb_csr_rdata_r       <= 32'h0;
~000025             ex_wb_rd_idx_r          <= 5'h0;
~000025             ex_wb_rd_we_r           <= 1'b0;
~000025             ex_wb_wb_sel_r          <= 3'h0;
~000025             ex_wb_is_load_r         <= 1'b0;
~000025             ex_wb_is_store_r        <= 1'b0;
~000025             ex_wb_ls_funct3_r       <= 3'h0;
~000025             ex_wb_addr_lo_r         <= 2'h0;
~000025             ex_wb_is_mret_r         <= 1'b0;
~000025             ex_wb_csr_we_r          <= 1'b0;
~000025             ex_wb_csr_addr_r        <= 12'h0;
~000025             ex_wb_csr_op_r          <= 2'h0;
~000025             ex_wb_csr_wdata_r       <= 32'h0;
~000025             ex_wb_is_branch_taken_r <= 1'b0;
~000025             ex_wb_is_jal_r          <= 1'b0;
~000025             ex_wb_is_jalr_r         <= 1'b0;
~000025             ex_wb_illegal_r         <= 1'b0;
 000875         end else if (ex_mem_advance_to_wb) begin
 000415             ex_wb_valid_r           <= 1'b1;
 000415             ex_wb_pc_r              <= ex_mem_pc_r;
 000415             ex_wb_alu_result_r      <= ex_mem_alu_result_r;
 000415             ex_wb_md_result_r       <= ex_mem_md_result_r;
 000415             ex_wb_pc_plus_4_r       <= ex_mem_pc_plus_4_r;
 000415             ex_wb_pc_plus_imm_r     <= ex_mem_pc_plus_imm_r;
 000415             ex_wb_csr_rdata_r       <= ex_mem_csr_rdata_r;
 000415             ex_wb_rd_idx_r          <= ex_mem_rd_idx_r;
 000415             ex_wb_rd_we_r           <= ex_mem_rd_we_r;
 000415             ex_wb_wb_sel_r          <= ex_mem_wb_sel_r;
 000415             ex_wb_is_load_r         <= ex_mem_is_load_r;
 000415             ex_wb_is_store_r        <= ex_mem_is_store_r;
 000415             ex_wb_ls_funct3_r       <= ex_mem_ls_funct3_r;
 000415             ex_wb_addr_lo_r         <= ex_mem_addr_lo_r;
 000415             ex_wb_is_mret_r         <= ex_mem_is_mret_r;
 000415             ex_wb_csr_we_r          <= ex_mem_csr_we_r;
 000415             ex_wb_csr_addr_r        <= ex_mem_csr_addr_r;
 000415             ex_wb_csr_op_r          <= ex_mem_csr_op_r;
 000415             ex_wb_csr_wdata_r       <= ex_mem_csr_wdata_r;
 000415             ex_wb_is_branch_taken_r <= ex_mem_is_branch_taken_r;
 000415             ex_wb_is_jal_r          <= ex_mem_is_jal_r;
 000415             ex_wb_is_jalr_r         <= ex_mem_is_jalr_r;
 000415             ex_wb_illegal_r         <= ex_mem_illegal_r;
 000875         end else begin
                    // Stall / wrong-path: 插 bubble
 000875             ex_wb_valid_r           <= 1'b0;
 000875             ex_wb_rd_we_r           <= 1'b0;
 000875             ex_wb_is_load_r         <= 1'b0;
 000875             ex_wb_is_store_r        <= 1'b0;
 000875             ex_wb_is_mret_r         <= 1'b0;
 000875             ex_wb_csr_we_r          <= 1'b0;
 000875             ex_wb_is_branch_taken_r <= 1'b0;
 000875             ex_wb_is_jal_r          <= 1'b0;
 000875             ex_wb_is_jalr_r         <= 1'b0;
 000875             ex_wb_illegal_r         <= 1'b0;
                end
            end
        
            // 連 forward module 用的 wires
            assign ex_wb_valid    = ex_wb_valid_r;
            assign ex_wb_rd_we    = ex_wb_rd_we_r;
            assign ex_wb_rd_idx   = ex_wb_rd_idx_r;
            assign ex_wb_is_load  = ex_wb_is_load_r;
            assign wb_csr_we      = ex_wb_csr_we_r && ex_wb_valid_r && !wb_take_irq;
        
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
~000094     reg [31:0] wb_data_mux;
 001320     always @* begin
 001320         case (ex_wb_wb_sel_r)
%000005             `WB_SEL_PCIMM: wb_data_mux = ex_wb_pc_plus_imm_r;
~000286             `WB_SEL_PC4  : wb_data_mux = ex_wb_pc_plus_4_r;
~000121             `WB_SEL_LSU  : wb_data_mux = lsu_ld_result_wb;
~000014             `WB_SEL_CSR  : wb_data_mux = ex_wb_csr_rdata_r;
~000181             `WB_SEL_MD   : wb_data_mux = ex_wb_md_result_r;
 001013             default      : wb_data_mux = ex_wb_alu_result_r;
                endcase
            end
            assign wb_data = wb_data_mux;
        
            // IRQ entry / MRET decision (在 WB commit boundary) — wb_take_irq forward-declared 上面
            assign wb_take_irq = ex_wb_valid_r && irq_pending && !ex_wb_illegal_r;
        
            // RFU write
            assign rfu_we      = ex_wb_valid_r && ex_wb_rd_we_r && !ex_wb_illegal_r && !wb_take_irq;
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
 001320     always @* begin
 001320         pc_redirect     = 1'b0;
 001320         redirect_target = 32'h0;
        
%000001         if (wb_take_irq) begin
%000001             pc_redirect     = 1'b1;
%000001             redirect_target = mtvec_o;
~001320         end else if (ex_wb_valid_r && ex_wb_is_mret_r) begin
%000001             pc_redirect     = 1'b1;
%000001             redirect_target = mepc_o;
%000000         end else if (mem_ras_mispredict) begin
                    // RAS 預測 target 跟 actual jalr target 不一致 — recovery 到 actual target
%000000             pc_redirect     = 1'b1;
%000000             redirect_target = mem_ras_actual_target;
~001320         end else if (ex_mem_valid_r && ex_mem_mispredict_r) begin
%000001             pc_redirect     = 1'b1;
                    // Recovery target combinational from ex_mem.Q registers (no alu_result on path)
                    //   is_jalr      → alu_result_r & ~1
                    //   branch_taken → pc_plus_imm_r
                    //   is_jal       → pc_plus_imm_r
                    //   else (branch not-taken mispredict) → pc_plus_4_r
%000001             redirect_target = ex_mem_is_jalr_r          ? (ex_mem_alu_result_r & ~32'd1) :
%000001                               ex_mem_is_branch_taken_r  ? ex_mem_pc_plus_imm_r :
%000001                               ex_mem_is_jal_r           ? ex_mem_pc_plus_imm_r :
%000000                                                           ex_mem_pc_plus_4_r;
                end
            end
        
            // CSR / trap / instret 訊號
            assign wb_trap_enter        = wb_take_irq;
            assign wb_trap_exit          = ex_wb_valid_r && ex_wb_is_mret_r;
            // trap_pc_for_mepc = 中斷時要保存的「下一條 PC」
            //   被中斷的指令本身已 commit (rd_we=0 但 pc 已 +4 等概念)，所以存的是 next_pc
            //   normal next_pc = pc+4；如果同時是 branch taken → pc+imm 之類
~001320     assign wb_trap_pc_for_mepc = ex_wb_is_branch_taken_r ? ex_wb_pc_plus_imm_r :
~001320                                   ex_wb_is_jal_r          ? ex_wb_pc_plus_imm_r :
~001320                                   ex_wb_is_jalr_r         ? (ex_wb_alu_result_r & ~32'd1) :
 001320                                                             ex_wb_pc_plus_4_r;
            assign wb_instr_retired = ex_wb_valid_r && !wb_take_irq;
        
            // =========================================================================
            // Trap output (illegal 進 TRAP 簡化版：直接卡死，不像 lab05 那麼正式)
            // 為了維持 ebreak 行為，遇到 illegal 時 PC 永遠 redirect 到 PC（自鎖）
            // =========================================================================
%000005     reg trap_latched;
 001315     always @(posedge clk) begin
~001290         if (!resetn) trap_latched <= 1'b0;
~001285         else if (ex_wb_valid_r && ex_wb_illegal_r) trap_latched <= 1'b1;
            end
            assign trap = trap_latched;
        
            // =========================================================================
            // Debug
            // =========================================================================
            assign dbg_pc    = if_ex_pc;
            assign dbg_instr = if_ex_instr;
            assign dbg_state = {stall, wb_take_irq, ex_wb_valid_r};
        
        endmodule
        
