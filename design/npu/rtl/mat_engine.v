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
    parameter integer TCM_AW = 10,
    parameter integer LANES = 4
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
    output wire              t_a_re,    // ADR-0044: window-consume strobes
    output wire [TCM_AW-1:0] t_a_addr,
    input  wire [255:0]      t_a_rdata,
    output wire              t_b_re,
    output wire [TCM_AW-1:0] t_b_addr,
    input  wire [255:0]      t_b_rdata,
    output reg               t_we,
    output reg  [TCM_AW-1:0] t_waddr,
    output reg  [31:0]       t_wdata
);
    localparam [2:0] CMD_CLR = 3'd0, CMD_OP = 3'd1, CMD_RESCALE = 3'd2,
                     CMD_LOADACC = 3'd3, CMD_RESCALE_PC = 3'd4,   // ADR-0042
                     CMD_LOADVEC = 3'd5;                          // ADR-0066
    localparam [3:0] S_LA = 4'd6, S_PRM = 4'd7, S_PRS = 4'd8, S_LV = 4'd9;
    localparam [3:0] S_IDLE = 4'd0, S_RUN = 4'd1,
                     S_RSC = 4'd3, S_FIN = 4'd5;   // S_RSW (4'd4) retired: ADR-0053 inline write

    reg [3:0]  state;
    reg [2:0]  cmd_q;
    reg [1:0]  bank_q;
    reg [7:0]  rpt_q, rep_i;
    reg [31:0] a_ptr, b_ptr;
    reg [2:0]  el_grp;               // LOADVEC 8x 256b windows -> acc[0..63]
    reg [5:0]  el_iss;               // rescale STAGE-1 issue index 0..63 (ADR-0053)
    reg [5:0]  el_pack;              // rescale STAGE-2 pack/write index (= el_iss delayed 1)
    reg        rq_v;                 // STAGE-2 valid (0 on the fill bubble)
    reg signed [63:0] rq_ab;         // pipelined 32x32 product (cut after the multiply)
    reg        rq_sat;               // pipelined SRDHM saturate flag
    reg [5:0]  rq_exp;               // pipelined (shift-31) for RoundingDivideByPOT
    reg [31:0] pack_q;
    reg        pc_mode;                       // ADR-0042 per-channel rescale
    reg [31:0] mult_c [0:7];
    reg [7:0]  shift_c [0:7];

    assign busy = (state != S_IDLE);

    // ---- accumulators: 4 banks x 64 x int32 ----
    reg signed [31:0] acc [0:3][0:63];
    integer ci, cj;

    // ---- fused outer products (combinational, LANES x 64 MACs) ----
    // Lane j = one k-step; the tail (rpt%LANES) masks lanes uniformly across all
    // 64 (r,c) cells. Every operand stays SIGNED end-to-end (int8 x int8 ->
    // int17 lane product, LANES-lane signed sum, int32 wrap into acc).
    localparam [7:0] LANES_8 = LANES[7:0];
    localparam [8:0] LANES_9 = LANES[8:0];
    localparam [31:0] LANES_BYTES = LANES * 32'd8;
    wire [8:0] rem = {1'b0, rpt_q} - {1'b0, rep_i};
    wire [LANES-1:0] lane_en;
    wire signed [16:0] lane_prod [0:63][0:LANES-1];
    reg signed [31:0] psum_r [0:63];
    integer pi, pj;
    genvar gj, gr, gc;
    generate
        for (gj = 0; gj < LANES; gj = gj + 1) begin : g_lane_en
            assign lane_en[gj] = (rem > gj);
        end
        for (gr = 0; gr < 8; gr = gr + 1) begin : g_row
            for (gc = 0; gc < 8; gc = gc + 1) begin : g_col
                for (gj = 0; gj < 4; gj = gj + 1) begin : g_lane
                    if (gj < LANES) begin : g_active_lane
                        wire signed [7:0] a8 = t_a_rdata[gj*64 + gr*8 +: 8];
                        wire signed [7:0] b8 = t_b_rdata[gj*64 + gc*8 +: 8];
                        assign lane_prod[gr*8 + gc][gj] = lane_en[gj] ? (a8 * b8) : 17'sd0;
                    end
                end
            end
        end
    endgenerate

    always @* begin
        for (pi = 0; pi < 64; pi = pi + 1) begin
            psum_r[pi] = 32'sd0;
            for (pj = 0; pj < LANES; pj = pj + 1)
                psum_r[pi] = psum_r[pi] + {{15{lane_prod[pi][pj][16]}}, lane_prod[pi][pj]};
        end
    end

    // ---- requant STAGE 1 (combinational from el_iss): the 32x32 multiply and
    //      per-element control capture — the DC-measured critical sub-path lives
    //      here, isolated behind the rq_* registers (ADR-0053). per-channel
    //      (ADR-0042): mult/shift selected by the column index el_iss[2:0].
    wire [31:0]        cur_mult  = pc_mode ? mult_c[el_iss[2:0]] : rs_mult;
    wire [7:0]         cur_shift = pc_mode ? shift_c[el_iss[2:0]] : rs_shift;
    wire signed [31:0] acc_el = acc[bank_q][el_iss];
    wire signed [63:0] ab     = acc_el * $signed(cur_mult);
    wire               sat_s1 = (acc_el == 32'sh8000_0000) && (cur_mult == 32'h8000_0000);
    // exp = shift - 31 (validated to [31,62] at GO / at param fetch)
    wire [5:0]         exp_s1 = cur_shift[5:0] - 6'd31;

    // ---- requant STAGE 2 (combinational from the registered rq_*): SRDHM +
    //      RoundingDivideByPOT + zero-point + clamp. Same gemmlowp bit-quirks;
    //      only the register boundary is new (ADR-0053). ----
    wire signed [63:0] nudge  = rq_ab[63] ? (64'sd1 - 64'sd1073741824) : 64'sd1073741824;
    wire signed [63:0] s_sum  = rq_ab + nudge;
    wire signed [63:0] q_tz   = s_sum[63] ? -((-s_sum) >>> 31) : (s_sum >>> 31);
    wire signed [31:0] t32    = rq_sat ? 32'sh7FFF_FFFF : q_tz[31:0];
    wire [31:0]        rmask  = (rq_exp == 6'd0) ? 32'h0 : ((32'h1 << rq_exp[4:0]) - 32'h1);
    wire [31:0]        remv   = t32 & rmask;
    wire [31:0]        thr    = (rmask >> 1) + {31'b0, t32[31]};
    wire signed [31:0] q_pot  = (t32 >>> rq_exp[4:0]) + ((remv > thr) ? 32'sd1 : 32'sd0);
    wire signed [31:0] withzp = q_pot + {{24{rs_zp[7]}}, rs_zp};
    wire signed [31:0] cmin_x = {{24{rs_min[7]}}, rs_min};
    wire signed [31:0] cmax_x = {{24{rs_max[7]}}, rs_max};
    wire signed [31:0] clampd = (withzp < cmin_x) ? cmin_x :
                                (withzp > cmax_x) ? cmax_x : withzp;
    wire [7:0]         out8   = clampd[7:0];
    wire [31:0]        pack_next = {out8, pack_q[31:8]};

    // ---- TCM wide read addresses (word index of the 8-word window) ----
    assign t_a_addr = a_ptr[TCM_AW+1:2];
    assign t_b_addr = b_ptr[TCM_AW+1:2];
    assign t_a_re   = (state == S_RUN) || (state == S_LA) || (state == S_LV) ||
                      (state == S_PRM) || (state == S_PRS);
    assign t_b_re   = (state == S_RUN);

    wire param_bad =
        (cmd == CMD_OP      && ((arg_bank >= 4'd4) || (arg_rpt == 8'd0) ||
                                (a_addr[4:0] != 5'b0) || (b_addr[4:0] != 5'b0))) ||
        (cmd == CMD_RESCALE && ((arg_bank >= 4'd4) ||
                                (rs_shift < 8'd31) || (rs_shift > 8'd62) ||
                                (out_base[1:0] != 2'b00))) ||
        (cmd == CMD_LOADACC && ((arg_bank >= 4'd4) || (a_addr[4:0] != 5'b0))) ||
        (cmd == CMD_LOADVEC && ((arg_bank >= 4'd4) || (a_addr[4:0] != 5'b0))) ||
        (cmd == CMD_RESCALE_PC && ((arg_bank >= 4'd4) ||
                                   (rs_mult[4:0] != 5'b0) ||
                                   (out_base[1:0] != 2'b00)));

    always @(posedge clk) begin
        if (!resetn) begin
            state <= S_IDLE; done <= 1'b0; err_param <= 1'b0;
            t_we <= 1'b0; el_iss <= 6'd0; rep_i <= 8'd0; pc_mode <= 1'b0;
            rq_v <= 1'b0; el_pack <= 6'd0; el_grp <= 3'd0;
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
                        el_grp <= 3'd0;
                        el_iss <= 6'd0;
                        rq_v   <= 1'b0;   // ADR-0053: STAGE-2 starts on the fill bubble
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
                            CMD_LOADVEC: state <= S_LV;
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

                S_RUN: begin        // LANES fused outer products per cycle
                    for (ci = 0; ci < 64; ci = ci + 1)
                        acc[bank_q][ci] <= acc[bank_q][ci] + psum_r[ci];
                    a_ptr <= a_ptr + LANES_BYTES;
                    b_ptr <= b_ptr + LANES_BYTES;
                    if (rem <= LANES_9) begin
                        state <= S_IDLE; done <= 1'b1;
                    end else
                        rep_i <= rep_i + LANES_8;
                end

                S_RSC: begin  // ADR-0053: 2-stage requant pipe, inline word write
                    // STAGE 1: capture the 32x32 product + per-element control for
                    // el_iss into the rq_* registers (isolates the DC critical path)
                    rq_ab   <= ab;
                    rq_sat  <= sat_s1;
                    rq_exp  <= exp_s1;
                    el_pack <= el_iss;
                    rq_v    <= 1'b1;
                    if (el_iss != 6'd63) el_iss <= el_iss + 6'd1;   // then hold for drain
                    // STAGE 2: requant el_pack from the registered rq_* and pack it;
                    // write the 32b word inline when the group of 4 completes (no
                    // S_RSW bubble). Byte order + word address are bit-identical to
                    // the old flow (el_pack = el_iss-1 preserves the mapping).
                    if (rq_v) begin
                        pack_q <= pack_next;
                        if (el_pack[1:0] == 2'b11) begin
                            t_we    <= 1'b1;
                            t_waddr <= out_base[TCM_AW+1:2] +
                                       {{(TCM_AW-4){1'b0}}, el_pack[5:2]};
                            t_wdata <= pack_next;
                        end
                        // done trails the final (word 15) write by one cycle so
                        // "done" always means "outputs visible in the TCM"
                        // (gate_45 catches a stale last word)
                        if (el_pack == 6'd63) state <= S_FIN;
                    end
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

                S_LV: begin     // ADR-0066: 64 distinct int32 words, linear order
                    for (ci = 0; ci < 8; ci = ci + 1)
                        acc[bank_q][{el_grp, ci[2:0]}] <= t_a_rdata[ci*32 +: 32];
                    a_ptr <= a_ptr + 32'd32;
                    if (el_grp == 3'd7) begin
                        state <= S_IDLE; done <= 1'b1;
                    end else
                        el_grp <= el_grp + 3'd1;
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
