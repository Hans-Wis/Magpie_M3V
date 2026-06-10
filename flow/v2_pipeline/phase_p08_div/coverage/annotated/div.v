//      // verilator_coverage annotation
        // =============================================================================
        // div.v — RV32M DIV / DIVU / REM / REMU
        // -----------------------------------------------------------------------------
        // 32-cycle iterative restoring division。State machine:
        //   IDLE     : 等 start
        //   WORK     : 32 cycles，每 cycle 做 shift + subtract + decide
        //   FIXUP    : 1 cycle，apply sign correction + special cases (div by 0, overflow)
        //   DONE     : 1 cycle，done=1 with stable result
        //
        // Total latency from start to done = 1 (latch) + 32 (work) + 1 (fixup) + 1 (done) = 35 cycles
        //
        // RISC-V Spec corner cases (Privileged Spec 7.2):
        //   - DIVU / REMU by 0  : quot = 2^32 - 1, rem = rs1
        //   - DIV  / REM  by 0  : quot = -1,       rem = rs1
        //   - DIV  INT_MIN/-1   : quot = INT_MIN,  rem = 0  (overflow)
        // =============================================================================
        
        `include "def.vh"
        
        module div (
 117019     input             clk,
%000003     input             resetn,
 003252     input             start,
~000015     input      [ 2:0] md_op,
 000609     input      [31:0] op_a,
 000897     input      [31:0] op_b,
 000714     output reg [31:0] result,
 003249     output reg        done
        );
        
            localparam IDLE  = 2'd0;
            localparam WORK  = 2'd1;
            localparam FIXUP = 2'd2;
            localparam DONE  = 2'd3;
        
 006500     reg [ 1:0] state;
 052001     reg [ 5:0] iter;        // 0..31
        
 008120     reg [31:0] dividend;    // 持續往左 shift，bit[31] 是「下一個要吃進 remainder 的 bit」
 000835     reg [31:0] divisor;
 003211     reg [31:0] quotient;
 009340     reg [31:0] remainder;
        
            // 記住原始輸入 + 操作類型，FIXUP 階段用
 000609     reg [31:0] orig_a;
%000007     reg        ret_rem;         // 1 = 回 remainder (REM/REMU); 0 = 回 quotient
 000150     reg        sign_quot;       // 期望的 quotient sign
 000112     reg        sign_rem;        // 期望的 remainder sign
 000177     reg        div_by_zero;
 000011     reg        overflow;
        
            // -------------------------------------------------------------------------
            // 每 WORK cycle 的組合邏輯：
            //   shifted_rem = (rem << 1) | dividend[31]    (33-bit 容納 shift 暫存)
            //   sub         = shifted_rem - divisor
            //   took_step   = sub >= 0 (subtract 成功)
            // -------------------------------------------------------------------------
 009340     wire [32:0] shifted_rem = {remainder, dividend[31]};         // 33-bit
 009931     wire [32:0] sub_w       = shifted_rem - {1'b0, divisor};
 003692     wire        took_step   = !sub_w[32];                        // no borrow → fits
        
 117019     always @(posedge clk) begin
~117012         if (!resetn) begin
%000007             state <= IDLE;
%000007             done  <= 1'b0;
 117012         end else begin
 117012             done <= 1'b0;
        
 117012             case (state)
        
 006513                 IDLE: if (start) begin
 003251                     orig_a      <= op_a;
 003251                     ret_rem     <= (md_op == `MD_REM) || (md_op == `MD_REMU);
 003251                     div_by_zero <= (op_b == 32'h0);
 003251                     overflow    <= ((md_op == `MD_DIV) || (md_op == `MD_REM)) &&
~003251                                    (op_a == 32'h8000_0000) && (op_b == 32'hFFFF_FFFF);
        
                            // 取絕對值給迭代用
 002403                     if (((md_op == `MD_DIV) || (md_op == `MD_REM)) && op_a[31])
 000848                         dividend <= -op_a;
                            else
 002403                         dividend <= op_a;
        
 002463                     if (((md_op == `MD_DIV) || (md_op == `MD_REM)) && op_b[31])
 000788                         divisor <= -op_b;
                            else
 002463                         divisor <= op_b;
        
                            // 結果 sign：quotient 是 a/b 兩 sign 的 xor；remainder 同 a 的 sign
 003251                     sign_quot <= ((md_op == `MD_DIV)) && (op_a[31] ^ op_b[31]) && (op_b != 0);
 003251                     sign_rem  <= ((md_op == `MD_REM)) && op_a[31];
        
 003251                     quotient  <= 32'h0;
 003251                     remainder <= 32'h0;
 003251                     iter      <= 6'd0;
 003251                     state     <= WORK;
                        end
        
 104001                 WORK: begin
 089724                     if (took_step) begin
 014277                         remainder <= sub_w[31:0];
 014277                         quotient  <= {quotient[30:0], 1'b1};
 089724                     end else begin
 089724                         remainder <= shifted_rem[31:0];
 089724                         quotient  <= {quotient[30:0], 1'b0};
                            end
 104001                     dividend <= {dividend[30:0], 1'b0};
 104001                     iter     <= iter + 6'd1;
 100751                     if (iter == 6'd31)
 003250                         state <= FIXUP;
                        end
        
 003249                 FIXUP: begin
 000180                     if (div_by_zero) begin
                                // RISC-V spec: quot = -1 / 0xFFFFFFFF，rem = rs1
 000180                         result <= ret_rem ? orig_a : `DIV_BY_ZERO_QUOT;
 000012                     end else if (overflow) begin
                                // RISC-V spec: signed DIV INT_MIN/-1
                                //   quot = INT_MIN, rem = 0
~000012                         result <= ret_rem ? 32'h0 : `DIV_OVERFLOW_QUOT;
 001537                     end else if (ret_rem) begin
 001520                         result <= sign_rem ? -remainder : remainder;
 001537                     end else begin
 001537                         result <= sign_quot ? -quotient : quotient;
                            end
 003249                     state <= DONE;
                        end
        
 003249                 DONE: begin
 003249                     done  <= 1'b1;
 003249                     state <= IDLE;
                        end
        
%000000                 default: state <= IDLE;
                    endcase
                end
            end
        
        endmodule
        
