// =============================================================================
// bp.v — Lab08c Branch Predictor (64-entry 2-way set-associative + 2-bit BHT)
// -----------------------------------------------------------------------------
// 升級自 lab08b 的 16-entry direct-mapped → 64-entry 2-way (32 sets × 2 ways)
// 對 firmware 來說 16 entry 已經夠 (control instr 不到 5 個)，larger BTB 是
// 教學/scaling 用途。Set-associative 比 direct-mapped 多了 LRU bit 跟 way mux。
//
// 結構：
//   - 32 sets indexed by PC[6:2] (5-bit set index)
//   - 每 set 2 ways
//   - 每 way: { valid (1), tag PC[31:7] (25-bit), target (32-bit), counter (2-bit) }
//   - 每 set 一個 LRU bit (0 = way 0 是 LRU, 1 = way 1 是 LRU)
//
// Read at IF (combinational):
//   並聯比對兩個 way 的 tag → hit_way0 / hit_way1 → predict_taken / target mux
//
// Write at update (from MEM stage, value 已 latch 1 拍 → 沿用 lab08b 設計):
//   - hit → update 對應 way 的 counter (+target invariant for branch/JAL)，LRU 設 *對方*
//   - miss → replace LRU way (全部欄位寫入)，LRU 反轉
//
// Lab08 三個 timing fix 全部沿用:
//   1. tag/target/valid 不 gate on upd_taken (CE 不依賴 alu_result)
//   2. counter 走 sat-up/down logic（同 lab08b）
//   3. caller (core.v) 已經 ensure JALR 不會 update 進來
// =============================================================================

`include "def.vh"

module bp (
    input             clk,
    input             resetn,

    // ---- Read port (combinational, at IF) ----
    input      [31:0] if_pc,
    output            bp_predict_taken,
    output     [31:0] bp_predict_target,

    // ---- Write port (synchronous, BP update from MEM stage) ----
    input             upd_valid,
    input      [31:0] upd_pc,
    input             upd_taken,
    input      [31:0] upd_target
);

    localparam IDX_BITS = 5;                             // 32 sets → 5-bit index
    localparam IDX_LSB  = 1;                             // Lab08d: PC[1] can be 1 with RV32C
    localparam TAG_LSB  = IDX_LSB + IDX_BITS;            // = 7
    localparam TAG_BITS = 32 - TAG_LSB;                  // = 25
    localparam N_SETS   = 1 << IDX_BITS;                 // = 32

    // -------------------------------------------------------------------------
    // BTB storage (per way arrays)
    // -------------------------------------------------------------------------
    reg                 valid0   [0:N_SETS-1];
    reg [TAG_BITS-1:0]  tag0     [0:N_SETS-1];
    reg [31:0]          target0  [0:N_SETS-1];
    reg [1:0]           counter0 [0:N_SETS-1];

    reg                 valid1   [0:N_SETS-1];
    reg [TAG_BITS-1:0]  tag1     [0:N_SETS-1];
    reg [31:0]          target1  [0:N_SETS-1];
    reg [1:0]           counter1 [0:N_SETS-1];

    reg                 lru      [0:N_SETS-1];           // 0 = way0 是 LRU；1 = way1 是 LRU

    // -------------------------------------------------------------------------
    // Read path
    // -------------------------------------------------------------------------
    wire [IDX_BITS-1:0] rd_idx = if_pc[IDX_LSB +: IDX_BITS];
    wire [TAG_BITS-1:0] rd_tag = if_pc[31 -: TAG_BITS];

    wire rd_hit0 = valid0[rd_idx] && (tag0[rd_idx] == rd_tag);
    wire rd_hit1 = valid1[rd_idx] && (tag1[rd_idx] == rd_tag);

    // predict_taken: 只看 hit 那個 way 的 counter[1]
    //   2 way 同時 hit 不會發生 (因為 tag 唯一)，所以可以 OR 起來
    wire predict_from_way0 = rd_hit0 && counter0[rd_idx][1];
    wire predict_from_way1 = rd_hit1 && counter1[rd_idx][1];
    assign bp_predict_taken  = predict_from_way0 | predict_from_way1;
    assign bp_predict_target = rd_hit1 ? target1[rd_idx] : target0[rd_idx];

    // -------------------------------------------------------------------------
    // Write path (sync)
    // -------------------------------------------------------------------------
    wire [IDX_BITS-1:0] wr_idx = upd_pc[IDX_LSB +: IDX_BITS];
    wire [TAG_BITS-1:0] wr_tag = upd_pc[31 -: TAG_BITS];

    wire wr_hit0 = valid0[wr_idx] && (tag0[wr_idx] == wr_tag);
    wire wr_hit1 = valid1[wr_idx] && (tag1[wr_idx] == wr_tag);

    // 寫哪個 way:
    //   - hit way0 → write way0
    //   - hit way1 → write way1
    //   - miss → LRU way
    wire wr_way = wr_hit1 ? 1'b1 :
                  wr_hit0 ? 1'b0 :
                            lru[wr_idx];
    wire wr_hit = wr_hit0 | wr_hit1;

    // Counter next-value (per way, only target way actually updated)
    wire [1:0] cur_cnt = wr_way ? counter1[wr_idx] : counter0[wr_idx];
    wire [1:0] cnt_inc = (cur_cnt == 2'b11) ? 2'b11 : cur_cnt + 2'd1;
    wire [1:0] cnt_dec = (cur_cnt == 2'b00) ? 2'b00 : cur_cnt - 2'd1;
    wire [1:0] cnt_next  = wr_hit ? (upd_taken ? cnt_inc : cnt_dec)
                                  : (upd_taken ? 2'b10  : 2'b01);

    // LRU update：寫了 way 0 → way 1 變 LRU；寫了 way 1 → way 0 變 LRU
    wire lru_next = ~wr_way;

    integer i;
    always @(posedge clk) begin
        if (!resetn) begin
            for (i = 0; i < N_SETS; i = i + 1) begin
                valid0[i]   <= 1'b0;
                valid1[i]   <= 1'b0;
                counter0[i] <= 2'b01;
                counter1[i] <= 2'b01;
                tag0[i]     <= {TAG_BITS{1'b0}};
                tag1[i]     <= {TAG_BITS{1'b0}};
                target0[i]  <= 32'h0;
                target1[i]  <= 32'h0;
                lru[i]      <= 1'b0;
            end
        end else if (upd_valid) begin
            // 沿用 lab08 設計：tag/target/valid 不 gate on upd_taken
            if (wr_way == 1'b1) begin
                valid1[wr_idx]   <= 1'b1;
                tag1[wr_idx]     <= wr_tag;
                target1[wr_idx]  <= upd_target;
                counter1[wr_idx] <= cnt_next;
            end else begin
                valid0[wr_idx]   <= 1'b1;
                tag0[wr_idx]     <= wr_tag;
                target0[wr_idx]  <= upd_target;
                counter0[wr_idx] <= cnt_next;
            end
            lru[wr_idx] <= lru_next;
        end
    end

endmodule
