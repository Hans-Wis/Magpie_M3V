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
    input  [31:0] op_a,
    input  [31:0] op_b,
    input  [ 3:0] alu_op,
    output reg [31:0] result,
    // lab08e v2: fast branch path — expose comparators directly so core.v
    // can bypass the 32-bit result case mux (saves ~2 LUT6 on branch_taken path)
    output wire       cmp_eq,
    output wire       cmp_lt_s,
    output wire       cmp_lt_u
);

    // 預先算各種候選結果，最後一個 case mux 選一個
    wire [31:0] sum   = op_a + op_b;
    wire [31:0] diff  = op_a - op_b;
    wire        lt_s  = ($signed(op_a) < $signed(op_b));
    wire        lt_u  = (op_a < op_b);
    wire        eq    = (op_a == op_b);

    assign cmp_eq   = eq;
    assign cmp_lt_s = lt_s;
    assign cmp_lt_u = lt_u;

    wire [ 4:0] shamt = op_b[4:0];
    wire [31:0] sll_o = op_a << shamt;
    wire [31:0] srl_o = op_a >> shamt;
    wire [31:0] sra_o = $signed(op_a) >>> shamt;

    always @* begin
        case (alu_op)
            `ALU_ADD    : result = sum;
            `ALU_SUB    : result = diff;
            `ALU_AND    : result = op_a & op_b;
            `ALU_OR     : result = op_a | op_b;
            `ALU_XOR    : result = op_a ^ op_b;
            `ALU_SLL    : result = sll_o;
            `ALU_SRL    : result = srl_o;
            `ALU_SRA    : result = sra_o;
            `ALU_SLT    : result = {31'b0, lt_s};
            `ALU_SLTU   : result = {31'b0, lt_u};
            `ALU_SEQ    : result = {31'b0, eq};
            `ALU_COPY_B : result = op_b;
            // verilator coverage_off
            default     : result = 32'h0;
            // verilator coverage_on
            // ^ CS-COV-1 exclusion: alu_op is always a decoded legal code — coding standard CS-COV-1: defensive arm, unreachable by construction
        endcase
    end

endmodule
