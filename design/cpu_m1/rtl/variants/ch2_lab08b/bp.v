// =============================================================================
// bp.v — Lab08 Branch Predictor (16-entry BTB + 2-bit BHT)
// -----------------------------------------------------------------------------
// Direct-mapped, indexed by PC[5:2] (16 entries x 4-byte instr stride).
// 每 entry: { valid, tag(26b), target(32b), counter(2b saturating) }.
//   counter[1] == 1 -> predict taken (counter == 2 or 3)
//
// Read at IF (combinational): 給 ifu 的 next-PC mux 用。
// Write at EX (synchronous):  branch/jal/jalr 在 ID/EX 解到實際結果就更新。
//
// 設計選擇：
//   - 直接映射 16 entry：足以蓋住 firmware 的 hot loop (delay_loop)，table 容量
//     不超過 16 * (1+26+32+2) ≈ 976 bit，Vivado 會 infer 成 distributed RAM 或
//     pure LUT，不會佔 BRAM。
//   - tag = PC[31:6]：因為 index = PC[5:2]，PC[1:0] = 00 (word-aligned)。
//   - 2-bit BHT 每 entry 一個 (= local predictor)，不共享 history。對小程式足夠。
//   - Reset counter = 01 (weakly not-taken)：第一次遇到 taken 會升到 10 (weakly
//     taken) → 第二次預測就 taken。對 backward branch loop 第二輪起就 hit。
//
// Note: BTB 本身只在「實際看到 branch/jal/jalr」時寫入。所以 tag 不會被無關
// instr 污染 — 但若兩個 control instr 的 PC[5:2] 衝突，後者會踢掉前者。
// =============================================================================

`include "def.vh"

module bp (
    input             clk,
    input             resetn,

    // ---- Read port (combinational, at IF) ----
    input      [31:0] if_pc,
    output            bp_predict_taken,
    output     [31:0] bp_predict_target,

    // ---- Write port (synchronous, at EX when control instr resolves) ----
    input             upd_valid,      // 1 = 該 cycle 有 branch/jal/jalr 在 ID/EX 結束
    input      [31:0] upd_pc,         // = id_ex_pc
    input             upd_taken,      // actual outcome
    input      [31:0] upd_target      // actual target (= pc_plus_imm or jalr alu_result)
);

    localparam IDX_BITS = 4;
    localparam IDX_LSB  = 2;
    localparam TAG_LSB  = IDX_LSB + IDX_BITS;            // = 6
    localparam TAG_BITS = 32 - TAG_LSB;                  // = 26
    localparam N_ENT    = 1 << IDX_BITS;                 // = 16

    // -------------------------------------------------------------------------
    // BTB storage
    // -------------------------------------------------------------------------
    reg                 valid_arr   [0:N_ENT-1];
    reg [TAG_BITS-1:0]  tag_arr     [0:N_ENT-1];
    reg [31:0]          target_arr  [0:N_ENT-1];
    reg [1:0]           counter_arr [0:N_ENT-1];

    // -------------------------------------------------------------------------
    // Read path (combinational)
    // -------------------------------------------------------------------------
    wire [IDX_BITS-1:0] rd_idx = if_pc[IDX_LSB +: IDX_BITS];
    wire [TAG_BITS-1:0] rd_tag = if_pc[31 -: TAG_BITS];
    wire                rd_hit = valid_arr[rd_idx] && (tag_arr[rd_idx] == rd_tag);

    assign bp_predict_taken  = rd_hit && counter_arr[rd_idx][1];
    assign bp_predict_target = target_arr[rd_idx];

    // -------------------------------------------------------------------------
    // Write path (synchronous)
    // -------------------------------------------------------------------------
    wire [IDX_BITS-1:0] wr_idx = upd_pc[IDX_LSB +: IDX_BITS];
    wire [TAG_BITS-1:0] wr_tag = upd_pc[31 -: TAG_BITS];
    wire                wr_hit = valid_arr[wr_idx] && (tag_arr[wr_idx] == wr_tag);

    // Counter next-value logic
    wire [1:0] cur_cnt   = counter_arr[wr_idx];
    wire [1:0] cnt_inc   = (cur_cnt == 2'b11) ? 2'b11 : cur_cnt + 2'd1;
    wire [1:0] cnt_dec   = (cur_cnt == 2'b00) ? 2'b00 : cur_cnt - 2'd1;
    wire [1:0] cnt_next  = wr_hit ? (upd_taken ? cnt_inc : cnt_dec)
                                  : (upd_taken ? 2'b10  : 2'b01);

    integer i;
    always @(posedge clk) begin
        if (!resetn) begin
            for (i = 0; i < N_ENT; i = i + 1) begin
                valid_arr[i]   <= 1'b0;
                counter_arr[i] <= 2'b01;
                tag_arr[i]     <= {TAG_BITS{1'b0}};
                target_arr[i]  <= 32'h0;
            end
        end else if (upd_valid) begin
            // Lab08 timing fix：tag/target/valid 不再 gate by upd_taken。
            // 對 branch/JAL (BTB 只進這兩種，jalr 被 core 過濾掉) target 是
            // deterministic constant，每次 write 同值，無功能差別。但可以從
            // critical path 拿掉 upd_taken (= alu_result 衍生) → target_arr CE。
            valid_arr[wr_idx]   <= 1'b1;
            tag_arr[wr_idx]     <= wr_tag;
            target_arr[wr_idx]  <= upd_target;
            counter_arr[wr_idx] <= cnt_next;
        end
    end

endmodule
