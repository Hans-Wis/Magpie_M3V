//      // verilator_coverage annotation
        // =============================================================================
        // ifu.v — Lab08d PC management for 4-stage pipeline + BP + RAS + RV32C
        // -----------------------------------------------------------------------------
        // 跟 lab08c 比的差別：
        //   1. PC sequential 增量改成 +2 (16-bit compressed) 或 +4 (32-bit) — is_16bit input
        //   2. 輸出 next_pc combinational — core.v 用來驅動 i_mem_addr (look-ahead BRAM fetch)
        //
        // pc_reg 語意：current decode PC（= 當前被 decode 的 instr 的 PC）。BRAM 1-cycle
        // latency 由 i_mem_addr = next_pc (combinational) 補償 — BRAM 這拍 fetch 下拍要 decode
        // 的那個 word。
        //
        // PC mux priority (= 計算 next_pc):
        //   1. pc_redirect       (MEM/WB redirect)
        //   2. pc_stall          (凍結；load-use / muldiv / cross-boundary fetch)
        //   3. ras_predict_ret   (RAS top)
        //   4. bp_predict_taken  (BTB target)
        //   5. default           (pc + 2 or pc + 4 by is_16bit)
        //
        // PC 現在可以 PC[1] = 1 (RV32C 准許 2-byte aligned PC)。PC[0] 必須 = 0。
        // =============================================================================
        
        `include "def.vh"
        
        module ifu #(
            parameter [31:0] RESET_PC = `PC_RESET
        ) (
 001139     input             clk,
%000005     input             resetn,
        
 000029     input             pc_stall,        // 1 = hold pc_reg
%000005     input             pc_redirect,
%000000     input      [31:0] redirect_target,
        
%000000     input             ras_predict_ret,
%000000     input      [31:0] ras_predict_target,
        
%000000     input             bp_predict_taken,
%000000     input      [31:0] bp_predict_target,
        
            // Lab08d: PC 增量由 instr length 決定
 000023     input             is_16bit,
        
~000200     output     [31:0] pc,               // pc_reg = current decode PC
~000200     output     [31:0] next_pc            // combinational, = pc_reg next-cycle value
        );
        
~000200     reg [31:0] pc_reg;
            assign pc = pc_reg;
        
~001101     wire [31:0] pc_inc = is_16bit ? 32'd2 : 32'd4;
        
~001139     assign next_pc = pc_redirect          ? redirect_target :
 000714                      pc_stall             ? pc_reg :
~000425                      ras_predict_ret      ? ras_predict_target :
~000425                      bp_predict_taken     ? bp_predict_target :
 000425                                             pc_reg + pc_inc;
        
 001139     always @(posedge clk) begin
 001114         if (!resetn) pc_reg <= RESET_PC;
 001114         else         pc_reg <= next_pc;
            end
        
        endmodule
        
