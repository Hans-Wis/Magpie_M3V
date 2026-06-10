//      // verilator_coverage annotation
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
 001315     input             clk,
%000005     input             resetn,
~000012     input             start,
~000063     input      [ 2:0] md_op,
~000059     input      [31:0] op_a,
~000080     input      [31:0] op_b,
%000003     output     [31:0] result,
~000012     output reg        done
        );
        
~000012     reg                busy;
%000005     reg signed [32:0]  opa_r, opb_r;
            /* verilator lint_off UNUSEDSIGNAL */  // 用 [63:32] 跟 [31:0]，bit 64/65 是 sign-ext 不取
%000006     reg signed [65:0]  product;
            /* verilator lint_on UNUSEDSIGNAL */
%000004     reg                high_out;
        
            // -------------------------------------------------------------------------
            // Sign-extension based on md_op
            //   op_a unsigned : 只有 MULHU
            //   op_b unsigned : MULHU 跟 MULHSU
            // -------------------------------------------------------------------------
~000019     wire opa_unsigned = (md_op == `MD_MULHU);
 000047     wire opb_unsigned = (md_op == `MD_MULHU) || (md_op == `MD_MULHSU);
        
~001286     wire signed [32:0] opa_ext = opa_unsigned ? {1'b0, op_a} : {op_a[31], op_a};
~001239     wire signed [32:0] opb_ext = opb_unsigned ? {1'b0, op_b} : {op_b[31], op_b};
        
 001315     always @(posedge clk) begin
~001290         if (!resetn) begin
~000025             busy     <= 1'b0;
~000025             done     <= 1'b0;
~000025             high_out <= 1'b0;
 001290         end else begin
 001290             done <= 1'b0;
        
~001278             if (start && !busy) begin
                        // Cycle 0: latch
~000012                 opa_r    <= opa_ext;
~000012                 opb_r    <= opb_ext;
~000012                 high_out <= (md_op != `MD_MUL);
~000012                 busy     <= 1'b1;
~001266             end else if (busy) begin
                        // Cycle 1: multiply, result available, signal done
~000012                 product <= opa_r * opb_r;
~000012                 done    <= 1'b1;
~000012                 busy    <= 1'b0;
                    end
                end
            end
        
~000727     assign result = high_out ? product[63:32] : product[31:0];
        
        endmodule
        
