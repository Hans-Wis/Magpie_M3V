// =============================================================================
// mul.v — RV32M MUL / MULH / MULHSU / MULHU (M1A pipelined, ADR-0026 A1)
// -----------------------------------------------------------------------------
// M1A rework (was: 3-cycle start/busy/done FSM that stalled the whole pipe via
// md_busy): the multiplier is now a STATELESS 2-stage pipelined unit that rides
// the instruction's own pipeline slot — "load-like result-at-WB":
//
//   issue (= the MUL advances ID/EX -> EX/MEM)  : latch sign-extended operands
//   the instruction's EX/MEM cycle              : product computed combinationally
//                                                 from the registers; `result` is
//                                                 consumed by core.v into
//                                                 ex_wb_md_result_r at the
//                                                 EX/MEM -> EX/WB boundary
//
// Latency 2 (issue -> writeback), THROUGHPUT 1 (back-to-back issue every cycle).
// No FSM: a flushed/squashed MUL simply never consumes `result` (slot-tagged by
// ex_mem_is_mul_r in core.v) — the wrong-path-stuck-FSM bug class is gone.
// Timing structure is unchanged vs the frozen M1 baseline: registered operands ->
// combinational 33x33 product -> one format mux -> a register (now core's
// ex_wb_md_result_r instead of an internal result reg).
//
// Sign extension table (unchanged):
//   md_op    op_a       op_b       result selection
//   ---------------------------------------------------
//   MUL      signed     signed     product[31:0]   (low 32)
//   MULH     signed     signed     product[63:32]  (high)
//   MULHSU   signed     unsigned   product[63:32]
//   MULHU    unsigned   unsigned   product[63:32]
// =============================================================================

`include "def.vh"

module mul (
    input             clk,
    input             resetn,
    input             issue,    // capture operands: MUL advancing ID/EX -> EX/MEM
    input      [ 2:0] md_op,
    input      [31:0] op_a,
    input      [31:0] op_b,
    output     [31:0] result    // valid during the instruction's EX/MEM cycle
);

    reg signed [32:0] opa_r, opb_r;
    reg               high_out;

    wire signed [65:0] product_w = opa_r * opb_r;

    // -------------------------------------------------------------------------
    // Sign-extension based on md_op (sampled at issue)
    //   op_a unsigned : 只有 MULHU
    //   op_b unsigned : MULHU 跟 MULHSU
    // -------------------------------------------------------------------------
    wire opa_unsigned = (md_op == `MD_MULHU);
    wire opb_unsigned = (md_op == `MD_MULHU) || (md_op == `MD_MULHSU);

    wire signed [32:0] opa_ext = opa_unsigned ? {1'b0, op_a} : {op_a[31], op_a};
    wire signed [32:0] opb_ext = opb_unsigned ? {1'b0, op_b} : {op_b[31], op_b};

    always @(posedge clk) begin
        if (!resetn) begin
            opa_r    <= 33'sd0;
            opb_r    <= 33'sd0;
            high_out <= 1'b0;
        end else if (issue) begin
            opa_r    <= opa_ext;
            opb_r    <= opb_ext;
            high_out <= (md_op != `MD_MUL);
        end
        // no issue: hold — the in-flight MUL's product stays stable through
        // core_mem_stall freezes (ADR-0005) until its EX/WB capture
    end

    assign result = high_out ? product_w[63:32] : product_w[31:0];

endmodule
