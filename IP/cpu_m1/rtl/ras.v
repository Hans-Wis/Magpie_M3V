// =============================================================================
// ras.v — Lab08c Return Address Stack (8-entry circular)
// -----------------------------------------------------------------------------
// 設計：
//   - 8-entry stack (3-bit pointer)，environments register array
//   - Push value: 由 IF/EX 階段算 (= if_ex_pc + 4)，當 instruction 被偵測為 JAL ra
//     (id_is_jal && id_rd_idx == x1) 時 push
//   - Pop:  由 IF 階段 pre-decode i_mem_rdata 偵測 RET (jalr x0, ra, 0) 時 pop
//   - Predict 輸出：ras_predict_taken = 1 + ras_predict_target = top
//     (caller 用 if_is_ret 來決定要不要用此 predict — 模組本身只負責「目前 top 是什麼」)
//
// 行為：
//   - Reset：pointer = 0 (empty)
//   - Push：stack[ptr] ← push_val；ptr ← ptr+1 (saturate at 8 → 從頭覆寫 ring buffer)
//   - Pop：top = stack[ptr-1]；ptr ← ptr-1 (saturate at 0)
//   - 同 cycle push + pop：可以 (push to ptr, pop from ptr-1，dependent on order)
//     此處用 sequential semantics：先 pop 再 push (= 取代 stack top)
//     但 firmware 不會這樣 (JAL ra 跟 RET 不會 IF 同 cycle 出現)，所以邊界 case
//     不重要，priority 就是行為定義即可。
//
// firmware impact 警告：
//   目前 lab08c 的 firmware (LED counter) 只有一個 `jal ra, main` 在 startup，
//   main 永不返回 (while(1))。所以 RAS push 一次後永遠 dormant，pop 永不發生。
//   RAS 是「為未來 firmware 準備」的設計，當前 firmware 不會觸發 → IPC 無變化。
// =============================================================================

`include "def.vh"

module ras (
    input             clk,
    input             resetn,

    // ---- Predict read (combinational) ----
    output     [31:0] ras_top,         // 目前 stack top (給 caller 在 IF 用)

    // ---- Push/Pop control (synchronous) ----
    input             push,            // 1 = end of this cycle push
    input      [31:0] push_val,
    input             pop              // 1 = end of this cycle pop
);

    localparam DEPTH = 8;
    localparam PTR_BITS = 3;

    reg [31:0]         stack [0:DEPTH-1];
    reg [PTR_BITS-1:0] ptr;            // points to *next empty slot* (=stack size)

    // ras_top = stack[ptr-1]，empty 時 (ptr=0) 輸出 0
    wire [PTR_BITS-1:0] top_idx = ptr - 3'd1;
    assign ras_top = (ptr == 0) ? 32'h0 : stack[top_idx];

    integer i;
    always @(posedge clk) begin
        if (!resetn) begin
            ptr <= 3'd0;
            for (i = 0; i < DEPTH; i = i + 1) stack[i] <= 32'h0;
        end else begin
            // Same-cycle push+pop = net push (取代 top)
            // 只 push: ptr++ (wrap)，stack[ptr] <= val
            // 只 pop:  ptr--
            // Both 同時：先 pop 再 push → stack[ptr-1] <= val，ptr 不變
            //          (即「replace top」semantics)
            if (push && pop) begin
                if (ptr != 0)
                    stack[top_idx] <= push_val;
                else
                    stack[0]       <= push_val;       // empty 時就視為 push 到 slot 0
                // ptr 不變
            end else if (push) begin
                stack[ptr] <= push_val;
                ptr <= ptr + 3'd1;                    // 3-bit 加法自動 wrap (覆寫底)
            end else if (pop) begin
                if (ptr != 0) ptr <= ptr - 3'd1;
                // empty 時 pop 是 no-op (預測結果是 garbage but 會 mispredict 被 recover)
            end
        end
    end

endmodule
