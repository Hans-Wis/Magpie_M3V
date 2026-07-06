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
    input             clk,
    input             resetn,
    input             flush,    // M1A ERRATA-0002 fix: kill an in-flight division on pipeline
                                // flush (trap/redirect/debug). Without this, a WRONG-PATH-started
                                // div keeps computing through the flush and its STALE result is
                                // delivered to a re-issued div after the handler returns
                                // (~35-cycle latency ~= handler length — measured, seed-reproducible).
    input             start,
    input      [ 2:0] md_op,
    input      [31:0] op_a,
    input      [31:0] op_b,
    output reg [31:0] result,
    output reg        done
);

    localparam IDLE  = 2'd0;
    localparam WORK  = 2'd1;
    localparam FIXUP = 2'd2;
    localparam DONE  = 2'd3;

    reg [ 1:0] state;
    reg [ 5:0] iter;        // 0..31

    reg [31:0] dividend;    // 持續往左 shift，bit[31] 是「下一個要吃進 remainder 的 bit」
    reg [31:0] divisor;
    reg [31:0] quotient;
    reg [31:0] remainder;

    // 記住原始輸入 + 操作類型，FIXUP 階段用
    reg [31:0] orig_a;
    reg        ret_rem;         // 1 = 回 remainder (REM/REMU); 0 = 回 quotient
    reg        sign_quot;       // 期望的 quotient sign
    reg        sign_rem;        // 期望的 remainder sign
    reg        div_by_zero;
    reg        overflow;

    // -------------------------------------------------------------------------
    // 每 WORK cycle 的組合邏輯：
    //   shifted_rem = (rem << 1) | dividend[31]    (33-bit 容納 shift 暫存)
    //   sub         = shifted_rem - divisor
    //   took_step   = sub >= 0 (subtract 成功)
    // -------------------------------------------------------------------------
    wire [32:0] shifted_rem = {remainder, dividend[31]};         // 33-bit
    wire [32:0] sub_w       = shifted_rem - {1'b0, divisor};
    wire        took_step   = !sub_w[32];                        // no borrow → fits

    always @(posedge clk) begin
        if (!resetn) begin
            state <= IDLE;
            done  <= 1'b0;
        end else if (flush) begin
            state <= IDLE;     // ERRATA-0002: discard the wrong-path computation entirely
            done  <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state)

                IDLE: if (start) begin
                    orig_a      <= op_a;
                    ret_rem     <= (md_op == `MD_REM) || (md_op == `MD_REMU);
                    div_by_zero <= (op_b == 32'h0);
                    overflow    <= ((md_op == `MD_DIV) || (md_op == `MD_REM)) &&
                                   (op_a == 32'h8000_0000) && (op_b == 32'hFFFF_FFFF);

                    // 取絕對值給迭代用
                    if (((md_op == `MD_DIV) || (md_op == `MD_REM)) && op_a[31])
                        dividend <= -op_a;
                    else
                        dividend <= op_a;

                    if (((md_op == `MD_DIV) || (md_op == `MD_REM)) && op_b[31])
                        divisor <= -op_b;
                    else
                        divisor <= op_b;

                    // 結果 sign：quotient 是 a/b 兩 sign 的 xor；remainder 同 a 的 sign
                    sign_quot <= ((md_op == `MD_DIV)) && (op_a[31] ^ op_b[31]) && (op_b != 0);
                    sign_rem  <= ((md_op == `MD_REM)) && op_a[31];

                    quotient  <= 32'h0;
                    remainder <= 32'h0;
                    iter      <= 6'd0;
                    state     <= WORK;
                end

                WORK: begin
                    if (took_step) begin
                        remainder <= sub_w[31:0];
                        quotient  <= {quotient[30:0], 1'b1};
                    end else begin
                        remainder <= shifted_rem[31:0];
                        quotient  <= {quotient[30:0], 1'b0};
                    end
                    dividend <= {dividend[30:0], 1'b0};
                    iter     <= iter + 6'd1;
                    if (iter == 6'd31)
                        state <= FIXUP;
                end

                FIXUP: begin
                    if (div_by_zero) begin
                        // RISC-V spec: quot = -1 / 0xFFFFFFFF，rem = rs1
                        result <= ret_rem ? orig_a : `DIV_BY_ZERO_QUOT;
                    end else if (overflow) begin
                        // RISC-V spec: signed DIV INT_MIN/-1
                        //   quot = INT_MIN, rem = 0
                        result <= ret_rem ? 32'h0 : `DIV_OVERFLOW_QUOT;
                    end else if (ret_rem) begin
                        result <= sign_rem ? -remainder : remainder;
                    end else begin
                        result <= sign_quot ? -quotient : quotient;
                    end
                    state <= DONE;
                end

                DONE: begin
                    done  <= 1'b1;
                    state <= IDLE;
                end

                // verilator coverage_off
                default: state <= IDLE;
                // verilator coverage_on
                // ^ CS-COV-1 exclusion: FSM states fully enumerated — coding standard CS-COV-1: defensive arm, unreachable by construction
            endcase
        end
    end

endmodule
