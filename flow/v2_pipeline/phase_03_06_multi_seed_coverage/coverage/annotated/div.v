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
 001139     input             clk,
%000005     input             resetn,
%000005     input             flush,    // M1A ERRATA-0002 fix: kill an in-flight division on pipeline
                                        // flush (trap/redirect/debug). Without this, a WRONG-PATH-started
                                        // div keeps computing through the flush and its STALE result is
                                        // delivered to a re-issued div after the handler returns
                                        // (~35-cycle latency ~= handler length — measured, seed-reproducible).
 000019     input             start,
 000062     input      [ 2:0] md_op,
~000058     input      [31:0] op_a,
~000080     input      [31:0] op_b,
%000007     output reg [31:0] result,
 000019     output reg        done
        );
        
            localparam IDLE  = 2'd0;
            localparam WORK  = 2'd1;
            localparam FIXUP = 2'd2;
            localparam DONE  = 2'd3;
        
 000038     reg [ 1:0] state;
 000304     reg [ 5:0] iter;        // 0..31
        
~000036     reg [31:0] dividend;    // 持續往左 shift，bit[31] 是「下一個要吃進 remainder 的 bit」
%000005     reg [31:0] divisor;
~000027     reg [31:0] quotient;
~000044     reg [31:0] remainder;
        
            // 記住原始輸入 + 操作類型，FIXUP 階段用
%000008     reg [31:0] orig_a;
%000006     reg        ret_rem;         // 1 = 回 remainder (REM/REMU); 0 = 回 quotient
%000002     reg        sign_quot;       // 期望的 quotient sign
%000000     reg        sign_rem;        // 期望的 remainder sign
%000000     reg        div_by_zero;
%000000     reg        overflow;
        
            // -------------------------------------------------------------------------
            // 每 WORK cycle 的組合邏輯：
            //   shifted_rem = (rem << 1) | dividend[31]    (33-bit 容納 shift 暫存)
            //   sub         = shifted_rem - divisor
            //   took_step   = sub >= 0 (subtract 成功)
            // -------------------------------------------------------------------------
~000044     wire [32:0] shifted_rem = {remainder, dividend[31]};         // 33-bit
 000044     wire [32:0] sub_w       = shifted_rem - {1'b0, divisor};
 000034     wire        took_step   = !sub_w[32];                        // no borrow → fits
        
 001139     always @(posedge clk) begin
 001114         if (!resetn) begin
 000025             state <= IDLE;
 000025             done  <= 1'b0;
~001109         end else if (flush) begin
%000005             state <= IDLE;     // ERRATA-0002: discard the wrong-path computation entirely
%000005             done  <= 1'b0;
 001109         end else begin
 001109             done <= 1'b0;
        
 001109             case (state)
        
 000463                 IDLE: if (start) begin
 000019                     orig_a      <= op_a;
~000019                     ret_rem     <= (md_op == `MD_REM) || (md_op == `MD_REMU);
 000019                     div_by_zero <= (op_b == 32'h0);
 000019                     overflow    <= ((md_op == `MD_DIV) || (md_op == `MD_REM)) &&
~000019                                    (op_a == 32'h8000_0000) && (op_b == 32'hFFFF_FFFF);
        
                            // 取絕對值給迭代用
~000017                     if (((md_op == `MD_DIV) || (md_op == `MD_REM)) && op_a[31])
%000002                         dividend <= -op_a;
                            else
 000017                         dividend <= op_a;
        
~000019                     if (((md_op == `MD_DIV) || (md_op == `MD_REM)) && op_b[31])
%000000                         divisor <= -op_b;
                            else
 000019                         divisor <= op_b;
        
                            // 結果 sign：quotient 是 a/b 兩 sign 的 xor；remainder 同 a 的 sign
~000019                     sign_quot <= ((md_op == `MD_DIV)) && (op_a[31] ^ op_b[31]) && (op_b != 0);
~000019                     sign_rem  <= ((md_op == `MD_REM)) && op_a[31];
        
 000019                     quotient  <= 32'h0;
 000019                     remainder <= 32'h0;
 000019                     iter      <= 6'd0;
 000019                     state     <= WORK;
                        end
        
 000608                 WORK: begin
 000559                     if (took_step) begin
 000049                         remainder <= sub_w[31:0];
 000049                         quotient  <= {quotient[30:0], 1'b1};
 000559                     end else begin
 000559                         remainder <= shifted_rem[31:0];
 000559                         quotient  <= {quotient[30:0], 1'b0};
                            end
 000608                     dividend <= {dividend[30:0], 1'b0};
 000608                     iter     <= iter + 6'd1;
 000589                     if (iter == 6'd31)
 000019                         state <= FIXUP;
                        end
        
 000019                 FIXUP: begin
%000000                     if (div_by_zero) begin
                                // RISC-V spec: quot = -1 / 0xFFFFFFFF，rem = rs1
%000000                         result <= ret_rem ? orig_a : `DIV_BY_ZERO_QUOT;
%000000                     end else if (overflow) begin
                                // RISC-V spec: signed DIV INT_MIN/-1
                                //   quot = INT_MIN, rem = 0
%000000                         result <= ret_rem ? 32'h0 : `DIV_OVERFLOW_QUOT;
~000012                     end else if (ret_rem) begin
%000007                         result <= sign_rem ? -remainder : remainder;
 000012                     end else begin
~000012                         result <= sign_quot ? -quotient : quotient;
                            end
 000019                     state <= DONE;
                        end
        
 000019                 DONE: begin
 000019                     done  <= 1'b1;
 000019                     state <= IDLE;
                        end
        
                        // verilator coverage_off
                        default: state <= IDLE;
                        // verilator coverage_on
                        // ^ CS-COV-1 exclusion: FSM states fully enumerated — coding standard CS-COV-1: defensive arm, unreachable by construction
                    endcase
                end
            end
        
        endmodule
        
