// =============================================================================
// ifu.v — Lab08b PC management for 4-stage pipeline + BP
// -----------------------------------------------------------------------------
// 跟 lab06b 的差別：加 BP-predicted next PC 路徑（同 lab08 ifu 的設計）
// PC mux priority：
//   1. pc_redirect       (MEM stage mispredict / WB stage IRQ / MRET)
//   2. pc_stall          (凍結)
//   3. bp_predict_taken  (BP 預測 taken → 用 bp_predict_target)
//   4. default           (pc + 4)
//
// pc_redirect 永遠最高優先，因為 mispredict / trap recovery 不可違背。
// =============================================================================

`include "def.vh"

module ifu (
    input             clk,
    input             resetn,

    input             pc_stall,        // 1 = 凍結 (load-use / muldiv)
    input             pc_redirect,     // 1 = MEM/WB redirect (mispredict / IRQ / MRET)
    input      [31:0] redirect_target,

    // Lab08b: BP-predicted next PC
    input             bp_predict_taken,
    input      [31:0] bp_predict_target,

    output     [31:0] pc                // 當前 fetch PC，驅動 i_mem_addr
);

    reg [31:0] pc_reg;
    assign pc = pc_reg;

    always @(posedge clk) begin
        if (!resetn)
            pc_reg <= `PC_RESET;
        else if (pc_redirect)
            pc_reg <= redirect_target;
        else if (!pc_stall) begin
            if (bp_predict_taken)
                pc_reg <= bp_predict_target;
            else
                pc_reg <= pc_reg + 32'd4;
        end
    end

endmodule
