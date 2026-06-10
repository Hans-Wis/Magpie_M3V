// =============================================================================
// mul.v — RV32M MUL / MULH / MULHSU / MULHU
// -----------------------------------------------------------------------------
// 2-cycle latency from start to done：
//   cycle 0 (start=1)         : latch op_a, op_b (sign-extend to 33 bit)
//   cycle 1                   : compute product, latch result, done=1
//   cycle 2                   : done=0, ready for next start
//
// Sign extension table:
//   md_op    op_a       op_b       result selection
//   ---------------------------------------------------
//   MUL      signed     signed     product[31:0]   (low 32)
//   MULH     signed     signed     product[63:32]  (high)
//   MULHSU   signed     unsigned   product[63:32]
//   MULHU    unsigned   unsigned   product[63:32]
//
// Vivado 會把 33×33 → 66 bit multiply 推到 DSP48 slice (xc7z020 有 220 個 DSP)
// =============================================================================

`include "def.vh"

module mul (
    input             clk,
    input             resetn,
    input             start,
    input      [ 2:0] md_op,
    input      [31:0] op_a,
    input      [31:0] op_b,
    output     [31:0] result,
    output reg        done
);

    reg                busy;
    reg signed [32:0]  opa_r, opb_r;
    /* verilator lint_off UNUSEDSIGNAL */  // 用 [63:32] 跟 [31:0]，bit 64/65 是 sign-ext 不取
    reg signed [65:0]  product;
    /* verilator lint_on UNUSEDSIGNAL */
    reg                high_out;

    // -------------------------------------------------------------------------
    // Sign-extension based on md_op
    //   op_a unsigned : 只有 MULHU
    //   op_b unsigned : MULHU 跟 MULHSU
    // -------------------------------------------------------------------------
    wire opa_unsigned = (md_op == `MD_MULHU);
    wire opb_unsigned = (md_op == `MD_MULHU) || (md_op == `MD_MULHSU);

    wire signed [32:0] opa_ext = opa_unsigned ? {1'b0, op_a} : {op_a[31], op_a};
    wire signed [32:0] opb_ext = opb_unsigned ? {1'b0, op_b} : {op_b[31], op_b};

    always @(posedge clk) begin
        if (!resetn) begin
            busy     <= 1'b0;
            done     <= 1'b0;
            high_out <= 1'b0;
        end else begin
            done <= 1'b0;

            if (start && !busy) begin
                // Cycle 0: latch
                opa_r    <= opa_ext;
                opb_r    <= opb_ext;
                high_out <= (md_op != `MD_MUL);
                busy     <= 1'b1;
            end else if (busy) begin
                // Cycle 1: multiply, result available, signal done
                product <= opa_r * opb_r;
                done    <= 1'b1;
                busy    <= 1'b0;
            end
        end
    end

    assign result = high_out ? product[63:32] : product[31:0];

endmodule
