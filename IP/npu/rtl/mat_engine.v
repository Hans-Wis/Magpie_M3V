// =============================================================================
// mat_engine.v — M3V matrix engine v0.1 (ADR-0037; v4 §06 SSOT semantics).
// -----------------------------------------------------------------------------
// 8x8 = 64 int8 MACs, one outer product per MAC cycle:
//   acc[r][c] += sext8(a[r]) * sext8(b[c])      (int32, wrapping)
// ACC = 4 banks x 8x8 x 32b (v4 leaves 16 tentative; 4 frozen here, ADR-0037).
// Commands (driven by the sequencer through the CSR mirror; GO is a pulse):
//   CMD_CLR     : zero the banks selected by arg_bank as a mask
//   CMD_OP      : arg_rpt serialized outer products; per rep the a/b pointers
//                 advance +8 bytes (frozen stripmine). 4 TCM word reads + 1 MAC
//                 cycle per rep. rpt==0 or bank>=4 -> err_param.
//   CMD_LOADACC : clear + preload one bank in ONE cycle: 8 int32 words at
//                 a_addr (32B-aligned) BROADCAST down the rows (acc[r][c] =
//                 word[c]) — the TFLM affine fold lands here (ADR-0039/0040).
//   CMD_RESCALE : TFLite/gemmlowp two-step requant of one bank, 64 int8 outputs
//                 packed to 16 TCM words at out_base:
//                   t = SaturatingRoundingDoublingHighMul(acc, mult_q31)
//                   q = RoundingDivideByPOT(t, shift-31)   (31 <= shift <= 62)
//                   out = clamp(q + zp, min, max)
//                 The gemmlowp bit-quirks (negative halves toward zero in SRDHM,
//                 double rounding) ARE the contract — golden = mat_golden.py.
// The engine locks itself (busy) for a whole command; GO while busy is ignored.
// done/err are sticky until the next accepted GO.
// =============================================================================
`default_nettype none

module mat_engine #(
    parameter integer TCM_AW = 10
) (
    input  wire        clk,
    input  wire        resetn,

    // ---- command port (CSR mirror) ----
    input  wire        go,
    input  wire        abort_i,        // ADR-0038: return to IDLE (no AXI side effects)
    input  wire [2:0]  cmd,          // 0=CLR 1=OP 2=RESCALE
    input  wire [3:0]  arg_bank,     // OP/RESCALE: bank id; CLR: bank mask
    input  wire [7:0]  arg_rpt,
    input  wire [31:0] a_addr,       // TCM byte addr (8-byte vector per rep)
    input  wire [31:0] b_addr,
    input  wire [31:0] rs_mult,      // Q31 multiplier
    input  wire [7:0]  rs_shift,     // total right shift, 31..62
    input  wire [7:0]  rs_zp,        // signed
    input  wire [7:0]  rs_min,       // signed clamp lo
    input  wire [7:0]  rs_max,       // signed clamp hi
    input  wire [31:0] out_base,     // TCM byte addr for 64-byte rescale output
    output wire        busy,
    output reg         done,         // sticky until next accepted go
    output reg         err_param,    // sticky until next accepted go

    // ---- TCM ports (ADR-0040: two 256-bit combinational read ports feed
    //      4 outer products per cycle; write port unchanged) ----
    output wire [TCM_AW-1:0] t_a_addr,
    input  wire [255:0]      t_a_rdata,
    output wire [TCM_AW-1:0] t_b_addr,
    input  wire [255:0]      t_b_rdata,
    output reg               t_we,
    output reg  [TCM_AW-1:0] t_waddr,
    output reg  [31:0]       t_wdata
);
    localparam [2:0] CMD_CLR = 3'd0, CMD_OP = 3'd1, CMD_RESCALE = 3'd2,
                     CMD_LOADACC = 3'd3, CMD_RESCALE_PC = 3'd4;   // ADR-0042
    localparam [3:0] S_LA = 4'd6, S_PRM = 4'd7, S_PRS = 4'd8;
    localparam [3:0] S_IDLE = 4'd0, S_RUN = 4'd1,
                     S_RSC = 4'd3, S_RSW = 4'd4, S_FIN = 4'd5;

    reg [3:0]  state;
    reg [2:0]  cmd_q;
    reg [1:0]  bank_q;
    reg [7:0]  rpt_q, rep_i;
    reg [31:0] a_ptr, b_ptr;
    reg [5:0]  el_i;                 // rescale element 0..63
    reg [31:0] pack_q;
    reg        pc_mode;                       // ADR-0042 per-channel rescale
    reg [31:0] mult_c [0:7];
    reg [7:0]  shift_c [0:7];

    assign busy = (state != S_IDLE);

    // ---- accumulators: 4 banks x 64 x int32 ----
    reg signed [31:0] acc [0:3][0:63];
    integer ci, cj;

    // ---- fused outer products (combinational, 4 lanes x 64 = 256 MACs) ----
    // Lane j = one k-step; the tail (rpt%4) masks lanes uniformly across all
    // 64 (r,c) cells. Every operand stays SIGNED end-to-end (int8 x int8 ->
    // int17 lane product, 4-lane signed sum, int32 wrap into acc).
    wire [8:0] rem = {1'b0, rpt_q} - {1'b0, rep_i};
    wire [3:0] lane_en = (rem >= 9'd4) ? 4'b1111 :
                         (rem == 9'd3) ? 4'b0111 :
                         (rem == 9'd2) ? 4'b0011 : 4'b0001;
    wire signed [31:0] psum [0:63];
    genvar gj, gr, gc;
    generate
        for (gr = 0; gr < 8; gr = gr + 1) begin : g_row
            for (gc = 0; gc < 8; gc = gc + 1) begin : g_col
                wire signed [16:0] lp [0:3];
                for (gj = 0; gj < 4; gj = gj + 1) begin : g_lane
                    wire signed [7:0] a8 = t_a_rdata[gj*64 + gr*8 +: 8];
                    wire signed [7:0] b8 = t_b_rdata[gj*64 + gc*8 +: 8];
                    assign lp[gj] = lane_en[gj] ? (a8 * b8) : 17'sd0;
                end
                assign psum[gr*8 + gc] =
                    {{15{lp[0][16]}}, lp[0]} + {{15{lp[1][16]}}, lp[1]} +
                    {{15{lp[2][16]}}, lp[2]} + {{15{lp[3][16]}}, lp[3]};
            end
        end
    endgenerate

    // ---- TFLite two-step rescale of the current element (combinational) ----
    // per-channel (ADR-0042): mult/shift selected by the column index el[2:0];
    // per-tensor path uses the CSR values unchanged
    wire [31:0]        cur_mult  = pc_mode ? mult_c[el_i[2:0]] : rs_mult;
    wire [7:0]         cur_shift = pc_mode ? shift_c[el_i[2:0]] : rs_shift;
    wire signed [31:0] acc_el = acc[bank_q][el_i];
    wire signed [63:0] ab     = acc_el * $signed(cur_mult);
    wire signed [63:0] nudge  = ab[63] ? (64'sd1 - 64'sd1073741824) : 64'sd1073741824;
    wire signed [63:0] s_sum  = ab + nudge;
    wire signed [63:0] q_tz   = s_sum[63] ? -((-s_sum) >>> 31) : (s_sum >>> 31);
    wire               sat    = (acc_el == 32'sh8000_0000) && (cur_mult == 32'h8000_0000);
    wire signed [31:0] t32    = sat ? 32'sh7FFF_FFFF : q_tz[31:0];
    // exp = shift - 31 (validated to [31,62] at GO / at param fetch)
    wire [5:0]         exp_r  = cur_shift[5:0] - 6'd31;
    wire [31:0]        rmask  = (exp_r == 6'd0) ? 32'h0 : ((32'h1 << exp_r[4:0]) - 32'h1);
    wire [31:0]        remv   = t32 & rmask;
    wire [31:0]        thr    = (rmask >> 1) + {31'b0, t32[31]};
    wire signed [31:0] q_pot  = (t32 >>> exp_r[4:0]) + ((remv > thr) ? 32'sd1 : 32'sd0);
    wire signed [31:0] withzp = q_pot + {{24{rs_zp[7]}}, rs_zp};
    wire signed [31:0] cmin_x = {{24{rs_min[7]}}, rs_min};
    wire signed [31:0] cmax_x = {{24{rs_max[7]}}, rs_max};
    wire signed [31:0] clampd = (withzp < cmin_x) ? cmin_x :
                                (withzp > cmax_x) ? cmax_x : withzp;
    wire [7:0]         out8   = clampd[7:0];

    // ---- TCM wide read addresses (word index of the 8-word window) ----
    assign t_a_addr = a_ptr[TCM_AW+1:2];
    assign t_b_addr = b_ptr[TCM_AW+1:2];

    wire param_bad =
        (cmd == CMD_OP      && ((arg_bank >= 4'd4) || (arg_rpt == 8'd0) ||
                                (a_addr[4:0] != 5'b0) || (b_addr[4:0] != 5'b0))) ||
        (cmd == CMD_RESCALE && ((arg_bank >= 4'd4) ||
                                (rs_shift < 8'd31) || (rs_shift > 8'd62) ||
                                (out_base[1:0] != 2'b00))) ||
        (cmd == CMD_LOADACC && ((arg_bank >= 4'd4) || (a_addr[4:0] != 5'b0))) ||
        (cmd == CMD_RESCALE_PC && ((arg_bank >= 4'd4) ||
                                   (rs_mult[4:0] != 5'b0) ||
                                   (out_base[1:0] != 2'b00)));

    always @(posedge clk) begin
        if (!resetn) begin
            state <= S_IDLE; done <= 1'b0; err_param <= 1'b0;
            t_we <= 1'b0; el_i <= 6'd0; rep_i <= 8'd0; pc_mode <= 1'b0;
        end else if (abort_i) begin
            state <= S_IDLE; done <= 1'b0; err_param <= 1'b0; t_we <= 1'b0;
        end else begin
            t_we <= 1'b0;
            case (state)
                S_IDLE: if (go) begin
                    done <= 1'b0; err_param <= 1'b0;
                    if (param_bad) begin
                        err_param <= 1'b1; done <= 1'b1;   // completes with error
                    end else begin
                        cmd_q  <= cmd;
                        bank_q <= arg_bank[1:0];
                        rpt_q  <= arg_rpt;
                        rep_i  <= 8'd0;
                        a_ptr  <= a_addr;
                        b_ptr  <= b_addr;
                        el_i   <= 6'd0;
                        case (cmd)
                            CMD_CLR: begin
                                for (ci = 0; ci < 4; ci = ci + 1)
                                    if (arg_bank[ci])
                                        for (cj = 0; cj < 64; cj = cj + 1)
                                            acc[ci][cj] <= 32'sd0;
                                done <= 1'b1;              // single-cycle
                            end
                            CMD_OP:      state <= S_RUN;
                            CMD_LOADACC: state <= S_LA;
                            CMD_RESCALE: begin pc_mode <= 1'b0; state <= S_RSC; end
                            CMD_RESCALE_PC: begin
                                pc_mode <= 1'b1;
                                a_ptr   <= rs_mult;        // W1 = param block ptr
                                state   <= S_PRM;
                            end
                            default:     begin err_param <= 1'b1; done <= 1'b1; end
                        endcase
                    end
                end

                S_RUN: begin        // 4 fused outer products per cycle (256 MACs)
                    for (ci = 0; ci < 64; ci = ci + 1)
                        acc[bank_q][ci] <= acc[bank_q][ci] + psum[ci];
                    a_ptr <= a_ptr + 32'd32;
                    b_ptr <= b_ptr + 32'd32;
                    if (rem <= 9'd4) begin
                        state <= S_IDLE; done <= 1'b1;
                    end else
                        rep_i <= rep_i + 8'd4;
                end

                S_RSC: begin                                // pack one byte/cycle
                    pack_q <= {out8, pack_q[31:8]};
                    if (el_i[1:0] == 2'b11) state <= S_RSW;
                    el_i <= el_i + 6'd1;
                end

                S_RSW: begin                                // write the packed word
                    t_we    <= 1'b1;
                    t_waddr <= out_base[TCM_AW+1:2] +
                               {{(TCM_AW-4){1'b0}}, el_i[5:2] - 4'd1};
                    t_wdata <= pack_q;
                    // done must trail the final write by a cycle so "done" always
                    // means "outputs visible in the TCM" (caught by gate_45: the
                    // last output word read back stale)
                    if (el_i == 6'd0) state <= S_FIN;       // wrapped past 63
                    else state <= S_RSC;
                end

                S_FIN: begin
                    state <= S_IDLE; done <= 1'b1;
                end

                S_LA: begin     // single-cycle fold preload: word c -> all rows
                    for (ci = 0; ci < 8; ci = ci + 1)
                        for (cj = 0; cj < 8; cj = cj + 1)
                            acc[bank_q][ci*8 + cj] <= t_a_rdata[cj*32 +: 32];
                    state <= S_IDLE; done <= 1'b1;
                end

                S_PRM: begin    // per-channel mults: one 256b window
                    for (ci = 0; ci < 8; ci = ci + 1)
                        mult_c[ci] <= t_a_rdata[ci*32 +: 32];
                    a_ptr <= a_ptr + 32'd32;
                    state <= S_PRS;
                end

                S_PRS: begin    // per-channel shifts: 8 bytes, validated here
                    for (ci = 0; ci < 8; ci = ci + 1)
                        shift_c[ci] <= t_a_rdata[ci*8 +: 8];
                    if ((t_a_rdata[7:0]   < 8'd31) || (t_a_rdata[7:0]   > 8'd62) ||
                        (t_a_rdata[15:8]  < 8'd31) || (t_a_rdata[15:8]  > 8'd62) ||
                        (t_a_rdata[23:16] < 8'd31) || (t_a_rdata[23:16] > 8'd62) ||
                        (t_a_rdata[31:24] < 8'd31) || (t_a_rdata[31:24] > 8'd62) ||
                        (t_a_rdata[39:32] < 8'd31) || (t_a_rdata[39:32] > 8'd62) ||
                        (t_a_rdata[47:40] < 8'd31) || (t_a_rdata[47:40] > 8'd62) ||
                        (t_a_rdata[55:48] < 8'd31) || (t_a_rdata[55:48] > 8'd62) ||
                        (t_a_rdata[63:56] < 8'd31) || (t_a_rdata[63:56] > 8'd62)) begin
                        err_param <= 1'b1; done <= 1'b1; state <= S_IDLE;
                    end else
                        state <= S_RSC;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
`default_nettype wire
