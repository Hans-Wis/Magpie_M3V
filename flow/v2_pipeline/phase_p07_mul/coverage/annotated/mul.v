//      // verilator_coverage annotation
        // =============================================================================
        // mul.v — RV32M MUL / MULH / MULHSU / MULHU
        // -----------------------------------------------------------------------------
        // 2-cycle latency from start to done：
        //   cycle 0 (start=1)         : latch op_a, op_b (sign-extend to 33 bit)
        //   cycle 1                   : compute product, latch result
        //   cycle 2                   : done=1 with stable result
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
 006972     input             clk,
%000002     input             resetn,
 002321     input             start,
%000004     input      [ 2:0] md_op,
 000532     input      [31:0] op_a,
 000668     input      [31:0] op_b,
 000450     output reg [31:0] result,
 002321     output reg        done
        );
        
 002321     reg                busy;
 002321     reg                done_pending;
 000668     reg signed [32:0]  opa_r, opb_r;
%000004     reg                high_out;
 001290     wire signed [65:0] product_w = opa_r * opb_r;
        
            // -------------------------------------------------------------------------
            // Sign-extension based on md_op
            //   op_a unsigned : 只有 MULHU
            //   op_b unsigned : MULHU 跟 MULHSU
            // -------------------------------------------------------------------------
%000004     wire opa_unsigned = (md_op == `MD_MULHU);
%000004     wire opb_unsigned = (md_op == `MD_MULHU) || (md_op == `MD_MULHSU);
        
 038341     wire signed [32:0] opa_ext = opa_unsigned ? {1'b0, op_a} : {op_a[31], op_a};
 025576     wire signed [32:0] opb_ext = opb_unsigned ? {1'b0, op_b} : {op_b[31], op_b};
        
 006972     always @(posedge clk) begin
~006968         if (!resetn) begin
%000004             busy     <= 1'b0;
%000004             done     <= 1'b0;
%000004             done_pending <= 1'b0;
%000004             high_out <= 1'b0;
 006968         end else begin
 006968             done <= 1'b0;
        
 002321             if (done_pending) begin
 002321                 done         <= 1'b1;
 002321                 done_pending <= 1'b0;
 002325             end else if (start && !busy) begin
                        // Cycle 0: latch
 002321                 opa_r    <= opa_ext;
 002321                 opb_r    <= opb_ext;
 002321                 high_out <= (md_op != `MD_MUL);
 002321                 busy     <= 1'b1;
~002321             end else if (busy) begin
                        // Cycle 1: multiply, latch result; signal done next cycle.
 002321                 result       <= high_out ? product_w[63:32] : product_w[31:0];
 002321                 done_pending <= 1'b1;
 002321                 busy         <= 1'b0;
                    end
                end
            end
        
        endmodule
        
