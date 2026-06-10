//      // verilator_coverage annotation
        // =============================================================================
        // alu.v — Arithmetic / Logic Unit (純組合，含 barrel shifter)
        // -----------------------------------------------------------------------------
        // 12 種運算，由 4-bit alu_op 選擇 (定義在 def.vh)：
        //   ADD / SUB / AND / OR / XOR / SLL / SRL / SRA / SLT / SLTU / SEQ / COPY_B
        //
        // 對外介面：
        //   op_a, op_b : 32-bit operand
        //   alu_op     : 4-bit operation code (來自 IDU)
        //   result     : 32-bit 結果
        //   zero       : (result == 0) — branch comparator 用
        //
        // 教學說明：
        //   * 純組合電路。所有路徑長度大約 = 32-bit add (~20 LUT logic level)
        //   * Barrel shifter 用 Verilog << / >> / >>>，Vivado 會推 barrel shifter LUT
        //     (lab01 100 MHz 已驗證可收斂)
        //   * SLT/SLTU 共用比較器，結果 zero-extend 到 32-bit
        //   * BEQ/BNE 由 core.v 自己看 zero 信號判斷；ALU 不負責 branch decision
        // =============================================================================
        
        `include "def.vh"
        
        // 註：原本還有 `zero` 輸出 (result == 0)，但 core.v 用 alu_result[0] 即可判斷
        // branch / SLT，因此 zero 已移除。如需 BEQ/BNE 額外提醒，可重新加入。
        module alu (
 000120     input  [31:0] op_a,
 000089     input  [31:0] op_b,
 000135     input  [ 3:0] alu_op,
 000095     output reg [31:0] result,
            // lab08e v2: fast branch path — expose comparators directly so core.v
            // can bypass the 32-bit result case mux (saves ~2 LUT6 on branch_taken path)
 000057     output wire       cmp_eq,
 000119     output wire       cmp_lt_s,
 000076     output wire       cmp_lt_u
        );
        
            // 預先算各種候選結果，最後一個 case mux 選一個
 000138     wire [31:0] sum   = op_a + op_b;
 000122     wire [31:0] diff  = op_a - op_b;
 000119     wire        lt_s  = ($signed(op_a) < $signed(op_b));
 000076     wire        lt_u  = (op_a < op_b);
 000057     wire        eq    = (op_a == op_b);
        
            assign cmp_eq   = eq;
            assign cmp_lt_s = lt_s;
            assign cmp_lt_u = lt_u;
        
 000089     wire [ 4:0] shamt = op_b[4:0];
 000103     wire [31:0] sll_o = op_a << shamt;
 000109     wire [31:0] srl_o = op_a >> shamt;
 000136     wire [31:0] sra_o = $signed(op_a) >>> shamt;
        
 000767     always @* begin
 000767         case (alu_op)
 000079             `ALU_ADD    : result = sum;
 000014             `ALU_SUB    : result = diff;
 000014             `ALU_AND    : result = op_a & op_b;
 000014             `ALU_OR     : result = op_a | op_b;
 000078             `ALU_XOR    : result = op_a ^ op_b;
 000084             `ALU_SLL    : result = sll_o;
 000084             `ALU_SRL    : result = srl_o;
 000084             `ALU_SRA    : result = sra_o;
 000078             `ALU_SLT    : result = {31'b0, lt_s};
 000078             `ALU_SLTU   : result = {31'b0, lt_u};
 000078             `ALU_SEQ    : result = {31'b0, eq};
 000080             `ALU_COPY_B : result = op_b;
%000002             default     : result = 32'h0;
                endcase
            end
        
        endmodule
        
