// =============================================================================
// hazard.v — Lab06b 4-stage pipeline hazard detection
// -----------------------------------------------------------------------------
// 偵測兩種需要 stall 的 hazard：
//   1. **load-use** (1 cycle, 跟 lab06 一樣)
//      lab06b 4-stage 下 load 路徑：
//        ID/EX (N+1): ALU 算 addr
//        EX/MEM (N+2): drive d_mem_addr, BRAM read (addr 已 register)
//        EX/WB (N+3): d_mem_rdata 有效, lsu sign-ext → wb_data
//      Consumer 在 ID/EX cycle N+2 找 load 結果：
//        - load 在 EX/MEM (= ex_mem_is_load_r=1) → STALL (alu_result = addr 不是 value)
//        - load 在 EX/WB (= ex_wb_is_load_r=1) → forward OK via wb_data
//      所以只需要在「load 在 EX/MEM」時 stall 1 cycle
//   2. **muldiv stall**: ID/EX stage 有 muldiv，但 M-unit 還在算
// =============================================================================

`include "def.vh"

module hazard (
    // ID/EX stage 狀態
    input         id_valid,
    input  [ 4:0] id_rs1_idx,
    input  [ 4:0] id_rs2_idx,
    input         id_is_muldiv,

    // EX/MEM stage (新加，lab06b 4-stage 用)
    input         em_valid,
    input         em_rd_we,
    input  [ 4:0] em_rd_idx,
    input         em_is_load,

    // EX/WB stage (lab06 同款，但 load forward OK 不用 stall)
    input         wb_valid,
    input         wb_rd_we,
    input  [ 4:0] wb_rd_idx,
    input         wb_is_load,

    // M-unit 狀態
    input         md_busy,

    output        stall,
    // M1A A1: the producer-in-MEM-not-ready RAW component alone — core.v gates the DIV
    // M-unit operand capture (md_start) on this, so a div never latches a stale operand
    // while its producer (load OR pipelined mul) is still in EX/MEM. Single source of
    // truth: same expression that drives the stall (no duplicated hazard logic).
    output        operand_stall
);

    // ---- Load-use (M1A: 含 pipelined MUL — em_is_load port 由 caller OR 進 is_mul):
    //      只 stall「value-not-ready producer 在 EX/MEM」這拍 (1 cycle stall) ----
    // load 走到 EX/WB 後 wb_data mux 已包含 lsu_ld_result，可 forward
    wire load_use_match_em = (id_rs1_idx == em_rd_idx) || (id_rs2_idx == em_rd_idx);
    wire load_use_stall = id_valid && em_valid && em_is_load && em_rd_we &&
                          (em_rd_idx != 5'd0) && load_use_match_em;

    /* verilator lint_off UNUSEDSIGNAL */
    wire _unused_wb_signals = wb_valid | wb_rd_we | (|wb_rd_idx) | wb_is_load;
    /* verilator lint_on UNUSEDSIGNAL */

    // ---- Muldiv ----
    wire muldiv_stall = id_valid && id_is_muldiv && md_busy;

    assign stall = load_use_stall | muldiv_stall;
    assign operand_stall = load_use_stall;

endmodule
