// =============================================================================
// core.v — Lab08b 4-stage pipeline RV32IM + CSR + IRQ + Branch Predictor
//          (lab06b base + 16-entry BTB + 2-bit BHT)
// -----------------------------------------------------------------------------
// 在 lab06b (4-stage with ex_mem register barrier) 之上加 branch predictor。
// 設計選擇沿用 lab08：
//   1. IF stage 加 BP-predicted next PC (ifu PC mux 多一條路徑)
//   2. pred_taken 跟著 pc_q 同步進 IF/EX register
//   3. ID/EX 階段 (lab06b 合一) compute mispredict (direction-only — BTB stored
//      target 對 branch/JAL 永遠對，所以不 verify target；JALR 不更新 BTB)
//   4. 把 lab06b 原來「無條件 ex_mem_is_branch_taken/jal/jalr 觸發 pc_redirect」
//      改成「只在 ex_mem_mispredict 時 redirect」→ 正確預測 0 penalty
//   5. BP update 只 gate on branch/JAL (排除 JALR，避免 alu_result 進 BTB write
//      data path — lab08 結論)
//
// 預期：
//   - clock: 85 MHz (= lab06b 不變，因為 lab06b critical path 在 d_mem store path
//                    不在 branch path，BP 不直接競爭)
//   - IPC: 26 → ~35 LED (BP 命中率與 lab08 同 → IPC 加成同)
//   - Wall-clock: 85 × 35 / (70 × 25) = 1.70× lab07 → 預期超越 lab08 (1.60×)
//
// lab06b critical path 不會被切短：BP 不碰 d_mem load forward → ALU → store_wstrb
// 那條 chain。BP overhead 主要在 EX 階段加 1 LUT level (pred vs actual XOR)，
// 但不在 lab06b critical 上。
// =============================================================================

`include "def.vh"

module core (
    input             clk,
    input             resetn,
    output            trap,

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

    // Debug
    output     [31:0] dbg_pc,
    output     [31:0] dbg_instr,
    output     [ 2:0] dbg_state
);

    // =========================================================================
    // Reset / warmup
    // =========================================================================
    reg warmup;
    always @(posedge clk) begin
        if (!resetn) warmup <= 1'b1;
        else         warmup <= 1'b0;   // 1 cycle bubble after reset (BRAM warm)
    end

    // =========================================================================
    // IF stage : ifu + pc_q (tracks "PC of instr that's in i_mem_rdata") + BP
    // =========================================================================
    wire [31:0] if_pc;
    reg         pc_redirect;
    reg  [31:0] redirect_target;
    wire        stall;
    wire        flush_if_next;        // bubble next-cycle IF/EX

    // Lab08b: BP combinational lookup at IF
    wire        bp_predict_taken;
    wire [31:0] bp_predict_target;
    wire        bp_upd_valid;
    wire [31:0] bp_upd_pc;
    wire        bp_upd_taken;
    wire [31:0] bp_upd_target;

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

    ifu u_ifu (
        .clk               (clk),
        .resetn            (resetn),
        .pc_stall          (stall),
        .pc_redirect       (pc_redirect),
        .redirect_target   (redirect_target),
        .bp_predict_taken  (bp_predict_taken),
        .bp_predict_target (bp_predict_target),
        .pc                (if_pc)
    );

    assign i_mem_addr = if_pc;
    assign i_mem_en   = !stall;        // BRAM 在 stall 期間 freeze，避免丟掉 mem_rdata

    // pc_q : 1-cycle delayed if_pc。在 cycle N+1 時 pc_q = if_pc from cycle N，
    // 也就是「mem_rdata 現在這拍對應的 PC」。
    //
    // 重要：pc_q 必須跟 i_mem_rdata 同步！i_mem_en 在 stall 時凍住 BRAM，
    // 所以 pc_q 也必須在 stall 時凍住，否則 stall 一次累積一個錯位
    // → IF/EX 收到 (pc=新, instr=舊) 不一致組合 → mepc 計算錯誤
    //
    // Lab08b: pred_taken_q 跟 pc_q 同步 latch (target 不 carry，BTB 保證 deterministic)
    reg [31:0] pc_q;
    reg        pred_taken_q;
    always @(posedge clk) begin
        if (!resetn) begin
            pc_q         <= 32'h0;
            pred_taken_q <= 1'b0;
        end else if (!stall) begin
            pc_q         <= if_pc;
            pred_taken_q <= bp_predict_taken;
        end
    end

    // =========================================================================
    // IF/EX pipeline register
    // =========================================================================
    reg [31:0] if_ex_instr;
    reg [31:0] if_ex_pc;
    reg        if_ex_valid;
    // Lab08b: 帶 BP direction prediction 進 pipeline (target 由 BTB invariance 保證)
    reg        if_ex_pred_taken;

    always @(posedge clk) begin
        if (!resetn) begin
            if_ex_instr      <= 32'h0;
            if_ex_pc         <= 32'h0;
            if_ex_valid      <= 1'b0;
            if_ex_pred_taken <= 1'b0;
        end else if (stall) begin
            // hold (load-use stall / muldiv stall 期間 ID/EX 重複處理同一條)
        end else if (flush_if_next || warmup) begin
            if_ex_instr      <= 32'h0;
            if_ex_pc         <= 32'h0;
            if_ex_valid      <= 1'b0;
            if_ex_pred_taken <= 1'b0;
        end else begin
            if_ex_instr      <= i_mem_rdata;
            if_ex_pc         <= pc_q;
            if_ex_valid      <= 1'b1;
            if_ex_pred_taken <= pred_taken_q;
        end
    end

    // Flush IF/EX 連 2 cycles：當 pc_redirect=1 時 (cycle N)：
    //   - cycle N 結尾要 bubble IF/EX (因為 ID/EX 此時是 wrong-path 的 instr)
    //   - cycle N+1 結尾也要 bubble (因為 BRAM 1-cycle latency 還會吐出一拍
    //     wrong-path 的 mem_rdata)
    //   - cycle N+2 才能 latch 正確的 target instr
    reg redirect_d1;
    always @(posedge clk) begin
        if (!resetn) redirect_d1 <= 1'b0;
        else         redirect_d1 <= pc_redirect;
    end
    assign flush_if_next = pc_redirect | redirect_d1;

    // =========================================================================
    // IDU (decode if_ex_instr，純組合)
    // =========================================================================
    wire [ 4:0] id_rd_idx, id_rs1_idx, id_rs2_idx;
    wire [31:0] id_imm;
    wire [ 3:0] id_alu_op;
    wire        id_alu_b_use_imm;
    wire        id_rd_we;
    wire [ 2:0] id_wb_sel;
    wire        id_is_branch, id_branch_invert;
    wire        id_is_jal, id_is_jalr;
    wire        id_is_load, id_is_store;
    wire [ 2:0] id_ls_funct3;
    wire        id_is_csr;
    wire [ 1:0] id_csr_op;
    wire        id_csr_uses_imm;
    wire [11:0] id_csr_addr;
    wire [31:0] id_csr_zimm;
    wire        id_is_mret;
    wire        id_is_muldiv;
    wire [ 2:0] id_md_op;
    wire        id_md_is_div;
    wire        id_illegal;

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
    wire [31:0] rfu_rs1_data, rfu_rs2_data;
    wire        rfu_we;
    wire [ 4:0] rfu_wr_idx;
    wire [31:0] rfu_wr_data;

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
    wire [31:0] wb_data;
    wire        ex_wb_valid;
    wire        ex_wb_rd_we;
    wire [ 4:0] ex_wb_rd_idx;
    wire        ex_wb_is_load;

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
    wire [31:0] alu_op_a = rs1_val;
    wire [31:0] alu_op_b = id_alu_b_use_imm ? id_imm : rs2_val;
    wire [31:0] alu_result;

    alu u_alu (
        .op_a   (alu_op_a),
        .op_b   (alu_op_b),
        .alu_op (id_alu_op),
        .result (alu_result)
    );

    // Branch decision (組合，同 ID/EX cycle 算)
    wire branch_taken = id_is_branch && (id_branch_invert ^ alu_result[0]);

    // pc + imm (給 JAL / branch target / AUIPC)
    wire [31:0] if_ex_pc_plus_4   = if_ex_pc + 32'd4;
    wire [31:0] if_ex_pc_plus_imm = if_ex_pc + id_imm;

    // ---- Lab08b: BP mispredict detection (direction-only, JALR excluded) ----
    //
    // 跟 lab08 同設計：BTB 只存 branch/JAL (target = pc+imm 是 deterministic)
    // 所以不 verify target；JALR 不進 BTB → 永遠 predict not-taken → 永遠 1
    // mispredict 但 ≈ lab06b baseline (lab06b JALR 也是 normal 3-cycle penalty)。
    wire ex_actual_taken = if_ex_valid && (branch_taken | id_is_jal | id_is_jalr);

    // 只比 direction (1-bit XOR)：pred_taken=1 + actual=1 (any target) → no flush
    wire ex_mispredict = if_ex_valid && (if_ex_pred_taken != ex_actual_taken);

    // Recovery target NOT computed here — moved to MEM stage (combinational from
    // ex_mem.Q registers) to keep alu_result off the redirect_target.D path

    // BP update：combinational in EX，latch 進 ex_mem_bp_upd_* register，下一拍才
    // drive bp.v 的 upd port → BP counter_arr.D 跟 target_arr.D path 從 register
    // output 出發 (不再有 alu_result 進 BP write data 路徑)
    wire        ex_bp_upd_valid  = if_ex_valid && (id_is_branch | id_is_jal)
                                              && !stall && !pc_redirect;
    wire [31:0] ex_bp_upd_pc     = if_ex_pc;
    wire        ex_bp_upd_taken  = ex_actual_taken;
    wire [31:0] ex_bp_upd_target = if_ex_pc_plus_imm;

    // =========================================================================
    // MUL / DIV units
    // =========================================================================
    // 兩個共用一條 start / done / result 介面 (透過 md_is_div 路由)
    wire        mul_done, div_done;
    wire [31:0] mul_result, div_result;
    reg         md_started;
    wire        md_busy = md_started && !(mul_done | div_done);
    wire        md_done = mul_done | div_done;
    wire [31:0] md_result = id_md_is_div ? div_result : mul_result;

    wire md_start = if_ex_valid && id_is_muldiv && !md_started;

    always @(posedge clk) begin
        if (!resetn)            md_started <= 1'b0;
        else if (md_done)       md_started <= 1'b0;
        else if (md_start)      md_started <= 1'b1;
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
    wire [31:0] lsu_mem_wdata_id;
    wire [ 3:0] lsu_mem_wstrb_id;
    wire [31:0] lsu_ld_result_wb;       // 計算在 MEM/WB stage

    // ID/EX：根據 store 算 wdata + wstrb
    /* verilator lint_off PINCONNECTEMPTY */
    lsu u_lsu_id (
        .addr_lo   (alu_result[1:0]),
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
    wire id_mem_active = (id_is_load || id_is_store) && if_ex_valid && !stall &&
                         !pc_redirect && !warmup;
    // 從 ex_mem register 驅動 d-port (MEM stage)
    assign d_mem_valid = ex_mem_valid_r && (ex_mem_is_load_r || ex_mem_is_store_r) &&
                         !pc_redirect;
    assign d_mem_addr  = ex_mem_alu_result_r;
    assign d_mem_wdata = ex_mem_store_wdata_r;
    assign d_mem_wstrb = ex_mem_is_store_r && ex_mem_valid_r && !pc_redirect ?
                         ex_mem_store_wstrb_r : 4'h0;

    // =========================================================================
    // CSR (lab05 同款，但 instr_retired 改成「EX/WB stage commits a valid instr」)
    // =========================================================================
    wire [31:0] id_csr_wdata = id_csr_uses_imm ? id_csr_zimm : rs1_val;
    wire        id_csr_we_logic = id_is_csr &&
                                  ((id_csr_op == `CSR_OP_W) || (id_csr_wdata != 32'h0));

    wire [31:0] csr_rdata;
    wire [31:0] mtvec_o, mepc_o;
    wire        irq_pending;

    // CSR write happens in EX/WB stage (latched into ex_wb register)
    wire        wb_csr_we;
    wire        wb_trap_enter, wb_trap_exit;
    wire [31:0] wb_trap_pc_for_mepc;
    wire        wb_instr_retired;

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
    reg        ex_mem_is_store_r;
    reg [ 2:0] ex_mem_ls_funct3_r;
    reg [ 1:0] ex_mem_addr_lo_r;
    reg [31:0] ex_mem_store_wdata_r;       // wstrb 一起 register
    reg [ 3:0] ex_mem_store_wstrb_r;
    reg        ex_mem_is_mret_r;
    reg        ex_mem_csr_we_r;
    reg [11:0] ex_mem_csr_addr_r;
    reg [ 1:0] ex_mem_csr_op_r;
    reg [31:0] ex_mem_csr_wdata_r;
    reg        ex_mem_is_branch_taken_r;
    reg        ex_mem_is_jal_r;
    reg        ex_mem_is_jalr_r;
    reg        ex_mem_illegal_r;
    // Lab08b: BP mispredict 取代「無條件 branch_taken/jal/jalr → redirect」
    // 注意：不 latch recovery_target — 在 MEM stage 用 ex_mem.Q registers 組合算
    //       (避免 alu_result → ex_mem_recovery_target_r.D 的 critical path)
    reg        ex_mem_mispredict_r;
    // Lab08b: BP update path register (避免 alu_result→counter_arr/target_arr.D
    // 的 critical path；多 1 cycle update latency，但對 hot-loop 命中率影響忽略)
    reg        ex_mem_bp_upd_valid_r;
    reg [31:0] ex_mem_bp_upd_pc_r;
    reg        ex_mem_bp_upd_taken_r;
    reg [31:0] ex_mem_bp_upd_target_r;

    // ID/EX → EX/MEM 推進條件
    wire id_advance_to_ex_mem = !stall && if_ex_valid && !warmup && !pc_redirect;

    always @(posedge clk) begin
        if (!resetn) begin
            ex_mem_valid_r           <= 1'b0;
            ex_mem_rd_we_r           <= 1'b0;
            ex_mem_is_load_r         <= 1'b0;
            ex_mem_is_store_r        <= 1'b0;
            ex_mem_store_wstrb_r     <= 4'h0;
            ex_mem_is_mret_r         <= 1'b0;
            ex_mem_csr_we_r          <= 1'b0;
            ex_mem_is_branch_taken_r <= 1'b0;
            ex_mem_is_jal_r          <= 1'b0;
            ex_mem_is_jalr_r         <= 1'b0;
            ex_mem_illegal_r         <= 1'b0;
            ex_mem_mispredict_r      <= 1'b0;
            ex_mem_bp_upd_valid_r    <= 1'b0;
        end else if (id_advance_to_ex_mem) begin
            ex_mem_valid_r           <= 1'b1;
            ex_mem_pc_r              <= if_ex_pc;
            ex_mem_alu_result_r      <= alu_result;
            ex_mem_md_result_r       <= md_result;
            ex_mem_pc_plus_4_r       <= if_ex_pc_plus_4;
            ex_mem_pc_plus_imm_r     <= if_ex_pc_plus_imm;
            ex_mem_csr_rdata_r       <= csr_rdata;
            ex_mem_rd_idx_r          <= id_rd_idx;
            ex_mem_rd_we_r           <= id_rd_we;
            ex_mem_wb_sel_r          <= id_wb_sel;
            ex_mem_is_load_r         <= id_is_load;
            ex_mem_is_store_r        <= id_is_store;
            ex_mem_ls_funct3_r       <= id_ls_funct3;
            ex_mem_addr_lo_r         <= alu_result[1:0];
            ex_mem_store_wdata_r     <= lsu_mem_wdata_id;
            ex_mem_store_wstrb_r     <= id_is_store && id_mem_active ? lsu_mem_wstrb_id : 4'h0;
            ex_mem_is_mret_r         <= id_is_mret;
            ex_mem_csr_we_r          <= id_csr_we_logic;
            ex_mem_csr_addr_r        <= id_csr_addr;
            ex_mem_csr_op_r          <= id_csr_op;
            ex_mem_csr_wdata_r       <= id_csr_wdata;
            ex_mem_is_branch_taken_r <= branch_taken;
            ex_mem_is_jal_r          <= id_is_jal;
            ex_mem_is_jalr_r         <= id_is_jalr;
            ex_mem_illegal_r         <= id_illegal;
            ex_mem_mispredict_r      <= ex_mispredict;
            ex_mem_bp_upd_valid_r    <= ex_bp_upd_valid;
            ex_mem_bp_upd_pc_r       <= ex_bp_upd_pc;
            ex_mem_bp_upd_taken_r    <= ex_bp_upd_taken;
            ex_mem_bp_upd_target_r   <= ex_bp_upd_target;
        end else begin
            // Stall / wrong-path / warmup: 插 bubble
            ex_mem_valid_r           <= 1'b0;
            ex_mem_rd_we_r           <= 1'b0;
            ex_mem_is_load_r         <= 1'b0;
            ex_mem_is_store_r        <= 1'b0;
            ex_mem_store_wstrb_r     <= 4'h0;
            ex_mem_is_mret_r         <= 1'b0;
            ex_mem_csr_we_r          <= 1'b0;
            ex_mem_is_branch_taken_r <= 1'b0;
            ex_mem_is_jal_r          <= 1'b0;
            ex_mem_is_jalr_r         <= 1'b0;
            ex_mem_illegal_r         <= 1'b0;
            ex_mem_mispredict_r      <= 1'b0;
            ex_mem_bp_upd_valid_r    <= 1'b0;
        end
    end

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
    /* verilator lint_off UNUSEDSIGNAL */
    reg        ex_wb_is_store_r;   // store 在 MEM 已 commit 到 d-port，WB 不用
    /* verilator lint_on UNUSEDSIGNAL */
    reg [ 2:0] ex_wb_ls_funct3_r;
    reg [ 1:0] ex_wb_addr_lo_r;
    reg        ex_wb_is_mret_r;
    reg        ex_wb_csr_we_r;
    reg [11:0] ex_wb_csr_addr_r;
    reg [ 1:0] ex_wb_csr_op_r;
    reg [31:0] ex_wb_csr_wdata_r;
    reg        ex_wb_is_branch_taken_r;
    reg        ex_wb_is_jal_r;
    reg        ex_wb_is_jalr_r;
    reg        ex_wb_illegal_r;

    // EX/MEM → EX/WB 推進條件
    //   branch/JAL/JALR 在 ex_mem 觸發 pc_redirect 不影響自己 advance 到 WB
    //   只有 wb_redirect (IRQ/MRET 從 ex_wb 觸發) 才 flush ex_mem (= wrong-path)
    wire wb_take_irq;                          // forward-declare (定義在後面)
    wire wb_redirect = wb_take_irq || (ex_wb_valid_r && ex_wb_is_mret_r);
    wire ex_mem_advance_to_wb = ex_mem_valid_r && !wb_redirect;

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
            ex_wb_is_store_r        <= 1'b0;
            ex_wb_ls_funct3_r       <= 3'h0;
            ex_wb_addr_lo_r         <= 2'h0;
            ex_wb_is_mret_r         <= 1'b0;
            ex_wb_csr_we_r          <= 1'b0;
            ex_wb_csr_addr_r        <= 12'h0;
            ex_wb_csr_op_r          <= 2'h0;
            ex_wb_csr_wdata_r       <= 32'h0;
            ex_wb_is_branch_taken_r <= 1'b0;
            ex_wb_is_jal_r          <= 1'b0;
            ex_wb_is_jalr_r         <= 1'b0;
            ex_wb_illegal_r         <= 1'b0;
        end else if (ex_mem_advance_to_wb) begin
            ex_wb_valid_r           <= 1'b1;
            ex_wb_pc_r              <= ex_mem_pc_r;
            ex_wb_alu_result_r      <= ex_mem_alu_result_r;
            ex_wb_md_result_r       <= ex_mem_md_result_r;
            ex_wb_pc_plus_4_r       <= ex_mem_pc_plus_4_r;
            ex_wb_pc_plus_imm_r     <= ex_mem_pc_plus_imm_r;
            ex_wb_csr_rdata_r       <= ex_mem_csr_rdata_r;
            ex_wb_rd_idx_r          <= ex_mem_rd_idx_r;
            ex_wb_rd_we_r           <= ex_mem_rd_we_r;
            ex_wb_wb_sel_r          <= ex_mem_wb_sel_r;
            ex_wb_is_load_r         <= ex_mem_is_load_r;
            ex_wb_is_store_r        <= ex_mem_is_store_r;
            ex_wb_ls_funct3_r       <= ex_mem_ls_funct3_r;
            ex_wb_addr_lo_r         <= ex_mem_addr_lo_r;
            ex_wb_is_mret_r         <= ex_mem_is_mret_r;
            ex_wb_csr_we_r          <= ex_mem_csr_we_r;
            ex_wb_csr_addr_r        <= ex_mem_csr_addr_r;
            ex_wb_csr_op_r          <= ex_mem_csr_op_r;
            ex_wb_csr_wdata_r       <= ex_mem_csr_wdata_r;
            ex_wb_is_branch_taken_r <= ex_mem_is_branch_taken_r;
            ex_wb_is_jal_r          <= ex_mem_is_jal_r;
            ex_wb_is_jalr_r         <= ex_mem_is_jalr_r;
            ex_wb_illegal_r         <= ex_mem_illegal_r;
        end else begin
            // Stall / wrong-path: 插 bubble
            ex_wb_valid_r           <= 1'b0;
            ex_wb_rd_we_r           <= 1'b0;
            ex_wb_is_load_r         <= 1'b0;
            ex_wb_is_store_r        <= 1'b0;
            ex_wb_is_mret_r         <= 1'b0;
            ex_wb_csr_we_r          <= 1'b0;
            ex_wb_is_branch_taken_r <= 1'b0;
            ex_wb_is_jal_r          <= 1'b0;
            ex_wb_is_jalr_r         <= 1'b0;
            ex_wb_illegal_r         <= 1'b0;
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
    reg [31:0] wb_data_mux;
    always @* begin
        case (ex_wb_wb_sel_r)
            `WB_SEL_PCIMM: wb_data_mux = ex_wb_pc_plus_imm_r;
            `WB_SEL_PC4  : wb_data_mux = ex_wb_pc_plus_4_r;
            `WB_SEL_LSU  : wb_data_mux = lsu_ld_result_wb;
            `WB_SEL_CSR  : wb_data_mux = ex_wb_csr_rdata_r;
            `WB_SEL_MD   : wb_data_mux = ex_wb_md_result_r;
            default      : wb_data_mux = ex_wb_alu_result_r;
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
    //   優先級：
    //     1. IRQ entry → mtvec     (從 ex_wb)
    //     2. MRET → mepc           (從 ex_wb)
    //     3. ex_mem mispredict → ex_mem_recovery_target_r (從 ex_mem.Q)
    //
    //   跟 lab06b 的差別：原本任何 branch_taken/jal/jalr 都 fire redirect (= 每個
    //   taken control instr 3-cycle penalty)。lab08b 改成「只在 BP 預測錯時 fire」。
    //   BP 預測對的時候 IF 已經從正確的 path fetch → 0 penalty。
    //
    //   recovery_target 已經在 EX stage 算好 (actual_taken ? actual_target : pc+4)
    //   latch 進 ex_mem_recovery_target_r，所以這裡只是 mux + register output。
    always @* begin
        pc_redirect     = 1'b0;
        redirect_target = 32'h0;

        if (wb_take_irq) begin
            pc_redirect     = 1'b1;
            redirect_target = mtvec_o;
        end else if (ex_wb_valid_r && ex_wb_is_mret_r) begin
            pc_redirect     = 1'b1;
            redirect_target = mepc_o;
        end else if (ex_mem_valid_r && ex_mem_mispredict_r) begin
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
    assign wb_trap_enter        = wb_take_irq;
    assign wb_trap_exit          = ex_wb_valid_r && ex_wb_is_mret_r;
    // trap_pc_for_mepc = 中斷時要保存的「下一條 PC」
    //   被中斷的指令本身已 commit (rd_we=0 但 pc 已 +4 等概念)，所以存的是 next_pc
    //   normal next_pc = pc+4；如果同時是 branch taken → pc+imm 之類
    assign wb_trap_pc_for_mepc = ex_wb_is_branch_taken_r ? ex_wb_pc_plus_imm_r :
                                  ex_wb_is_jal_r          ? ex_wb_pc_plus_imm_r :
                                  ex_wb_is_jalr_r         ? (ex_wb_alu_result_r & ~32'd1) :
                                                            ex_wb_pc_plus_4_r;
    assign wb_instr_retired = ex_wb_valid_r && !wb_take_irq;

    // =========================================================================
    // Trap output (illegal 進 TRAP 簡化版：直接卡死，不像 lab05 那麼正式)
    // 為了維持 ebreak 行為，遇到 illegal 時 PC 永遠 redirect 到 PC（自鎖）
    // =========================================================================
    reg trap_latched;
    always @(posedge clk) begin
        if (!resetn) trap_latched <= 1'b0;
        else if (ex_wb_valid_r && ex_wb_illegal_r) trap_latched <= 1'b1;
    end
    assign trap = trap_latched;

    // =========================================================================
    // Debug
    // =========================================================================
    assign dbg_pc    = if_ex_pc;
    assign dbg_instr = if_ex_instr;
    assign dbg_state = {stall, wb_take_irq, ex_wb_valid_r};

endmodule
