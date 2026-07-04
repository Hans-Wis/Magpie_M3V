// =============================================================================
// fexu.v — scalar RV32F EXU, slice F1 (ADR-0050). FLEN=32.
// -----------------------------------------------------------------------------
// Holds the F regfile (32 x 32b) and computes F1 ops in one combinational pass
// at EX ("query"); results commit at WB with the scalar kill rules (same shape
// as vexu). flw/fsw ride the EXISTING scalar LSU: fexu only decodes them,
// supplies the store data (f[rs2]) and receives the load data at commit.
//
// F1 subset (everything else in the F opcode spaces = q_illegal, honest
// deferral): flw/fsw, fmv.w.x/fmv.x.w, fsgnj/n/x.s, fmin/fmax.s (IEEE-2019
// minimumNumber: +-0 ordering, one sNaN -> other operand, NV on any sNaN,
// both NaN -> canonical 0x7FC00000), feq/flt/fle.s (feq: NV only on sNaN;
// flt/fle: NV on any NaN), fclass.s, fcvt.w/wu.s (all rm; NaN/overflow ->
// saturate + NV; NX on inexact), fcvt.s.w/wu (normalize + round, NX).
// Dynamic rm (111) resolves against the EFFECTIVE frm at execute; rm 101/110
// or dynamic-with-invalid-frm = illegal (Spike-matched).
// fadd/fsub/fmul = F2, FMA = F3, fdiv/fsqrt = F4 (deferred-illegal here).
// =============================================================================
`default_nettype none

module fexu #(
    parameter EN_F = 0
) (
    input  wire        clk,
    input  wire        resetn,

    // ---- query (instruction at EX) ----
    input  wire        q_valid,
    input  wire [31:0] q_instr,
    input  wire [31:0] q_rs1,       // x[rs1] (int source / address base)
    input  wire [2:0]  q_frm,       // effective frm
    output wire        q_hit,       // decodes into the F spaces (route to fexu)
    output wire        q_illegal,
    output wire        q_is_flw,
    output wire        q_is_fsw,
    output wire [31:0] q_fsw_data,  // f[rs2] for stores
    output wire        q_fwe,       // F-reg write (non-load ops)
    output wire [4:0]  q_fd,
    output wire [31:0] q_fdata,
    output wire        q_xwe,       // X-reg write (mv.x/cvt.w/cmp/class)
    output wire [31:0] q_xdata,
    output wire [4:0]  q_flags,     // fflags accrual {NV,DZ,OF,UF,NX}

    // ---- WB commit ----
    input  wire        w_en,
    input  wire [4:0]  w_fd,
    input  wire [31:0] w_data
);
    localparam [31:0] QNAN = 32'h7FC0_0000;

    // ---------------- decode ----------------
    wire [6:0] opc = q_instr[6:0];
    wire [2:0] f3  = q_instr[14:12];
    wire [6:0] f7  = q_instr[31:25];
    wire [4:0] f5  = f7[6:2];
    wire [4:0] rs2f = q_instr[24:20];
    wire [4:0] rs1_i = q_instr[19:15];
    wire [4:0] rd_i  = q_instr[11:7];
    wire fmt_s = (f7[1:0] == 2'b00);

    wire is_opfp = (opc == 7'b1010011);
    wire is_fma_opc = (opc == 7'b1000011) || (opc == 7'b1000111) ||
                      (opc == 7'b1001011) || (opc == 7'b1001111);
    assign q_is_flw = (opc == 7'b0000111) && (f3 == 3'b010);
    assign q_is_fsw = (opc == 7'b0100111) && (f3 == 3'b010);
    assign q_hit = (EN_F != 0) && q_valid &&
                   (is_opfp || is_fma_opc || q_is_flw || q_is_fsw);

    wire op_sgnj  = is_opfp && fmt_s && (f5 == 5'b00100) && (f3 <= 3'd2);
    wire op_mnmx  = is_opfp && fmt_s && (f5 == 5'b00101) && (f3 <= 3'd1);
    wire op_cmp   = is_opfp && fmt_s && (f5 == 5'b10100) && (f3 <= 3'd2);
    wire op_mvxw  = is_opfp && fmt_s && (f5 == 5'b11100) && (f3 == 3'd0) && (rs2f == 5'd0);
    wire op_class = is_opfp && fmt_s && (f5 == 5'b11100) && (f3 == 3'd1) && (rs2f == 5'd0);
    wire op_mvwx  = is_opfp && fmt_s && (f5 == 5'b11110) && (f3 == 3'd0) && (rs2f == 5'd0);
    wire op_cvtws = is_opfp && fmt_s && (f5 == 5'b11000) && (rs2f <= 5'd1); // w/wu <- s
    wire op_cvtsw = is_opfp && fmt_s && (f5 == 5'b11010) && (rs2f <= 5'd1); // s <- w/wu
    wire cvt_u    = rs2f[0];

    // rounding mode: only the cvt ops consume rm in F1
    wire needs_rm = op_cvtws || op_cvtsw;
    wire [2:0] rm_eff = (f3 == 3'b111) ? q_frm : f3;
    wire rm_bad = needs_rm &&
                  ((f3 == 3'b101) || (f3 == 3'b110) ||
                   ((f3 == 3'b111) && (q_frm > 3'd4)));

    wire known_op = op_sgnj || op_mnmx || op_cmp || op_mvxw || op_class ||
                    op_mvwx || op_cvtws || op_cvtsw || q_is_flw || q_is_fsw;
    assign q_illegal = q_hit && (!known_op || rm_bad);

    // ---------------- F regfile ----------------
    reg [31:0] fregs [0:31];
    wire [31:0] fa = fregs[rs1_i];
    wire [31:0] fb = fregs[rs2f];
    assign q_fsw_data = fb;         // fsw stores f[rs2]

    always @(posedge clk) begin
        if (w_en) fregs[w_fd] <= w_data;
    end

    // ---------------- classify helpers ----------------
    function [9:0] fclass_f;
        input [31:0] v;
        reg s; reg [7:0] e; reg [22:0] m;
        begin
            s = v[31]; e = v[30:23]; m = v[22:0];
            fclass_f = 10'b0;
            if (e == 8'hFF) begin
                if (m == 23'b0)      fclass_f[s ? 0 : 7] = 1'b1;   // inf
                else if (m[22])      fclass_f[9] = 1'b1;           // qNaN
                else                 fclass_f[8] = 1'b1;           // sNaN
            end else if (e == 8'h00) begin
                if (m == 23'b0)      fclass_f[s ? 3 : 4] = 1'b1;   // zero
                else                 fclass_f[s ? 2 : 5] = 1'b1;   // subnormal
            end else                 fclass_f[s ? 1 : 6] = 1'b1;   // normal
        end
    endfunction

    wire a_nan  = (fa[30:23] == 8'hFF) && (fa[22:0] != 23'b0);
    wire b_nan  = (fb[30:23] == 8'hFF) && (fb[22:0] != 23'b0);
    wire a_snan = a_nan && !fa[22];
    wire b_snan = b_nan && !fb[22];
    wire a_zero = (fa[30:0] == 31'b0);
    wire b_zero = (fb[30:0] == 31'b0);

    // ---------------- fsgnj / fmv ----------------
    wire [31:0] r_sgnj = (f3 == 3'd0) ? {fb[31],          fa[30:0]} :
                         (f3 == 3'd1) ? {~fb[31],         fa[30:0]} :
                                        {fa[31] ^ fb[31], fa[30:0]};

    // ---------------- ordered compare (no NaN) ----------------
    // a < b as reals: sign-magnitude with +-0 equal
    wire both_zero = a_zero && b_zero;
    wire mag_lt = (fa[30:0] < fb[30:0]);
    wire flt_core = both_zero ? 1'b0 :
                    (fa[31] != fb[31]) ? fa[31] :
                    (fa[31] ? (fb[30:0] < fa[30:0]) : mag_lt);
    wire feq_core = both_zero || (fa == fb);

    wire cmp_nan  = a_nan || b_nan;
    wire [31:0] r_cmp = (f3 == 3'd2) ? {31'b0, !cmp_nan && feq_core} :          // feq
                        (f3 == 3'd1) ? {31'b0, !cmp_nan && flt_core} :          // flt
                                       {31'b0, !cmp_nan && (flt_core || feq_core)}; // fle
    wire [4:0] fl_cmp = ((f3 == 3'd2) ? (a_snan || b_snan) : cmp_nan)
                        ? 5'b10000 : 5'b0;

    // ---------------- fmin / fmax (IEEE-2019 minimumNumber) ----------------
    wire want_max = (f3 == 3'd1);
    wire [31:0] mnmx_ab =
        (a_nan && b_nan) ? QNAN :
        a_nan            ? fb :
        b_nan            ? fa :
        both_zero        ? ((fa[31] ^ fb[31]) ? (want_max ? 32'h0 : 32'h8000_0000)
                                              : fa) :
        (flt_core ^ want_max) ? fa : fb;
    wire [4:0] fl_mnmx = (a_snan || b_snan) ? 5'b10000 : 5'b0;

    // ---------------- fcvt.w[u].s ----------------
    reg  [31:0] cvtws_res;
    reg  [4:0]  cvtws_fl;
    always @* begin : cvt_ws
        reg        s;
        reg signed [9:0] e;
        reg [23:0] sig;
        reg [63:0] wide;
        reg [31:0] mag;
        reg        rnd, stk, inc;
        reg [32:0] magr;
        integer    sh;
        cvtws_res = 32'h0; cvtws_fl = 5'b0;
        sig = 24'b0; e = 10'sd0; wide = 64'b0; mag = 32'b0;
        rnd = 1'b0; stk = 1'b0; inc = 1'b0; magr = 33'b0; sh = 0;
        s = fa[31];
        if (a_nan) begin
            cvtws_res = cvt_u ? 32'hFFFF_FFFF : 32'h7FFF_FFFF;
            cvtws_fl  = 5'b10000;
        end else if (fa[30:23] == 8'hFF) begin                     // infinity
            cvtws_res = cvt_u ? (s ? 32'h0 : 32'hFFFF_FFFF)
                              : (s ? 32'h8000_0000 : 32'h7FFF_FFFF);
            cvtws_fl  = 5'b10000;
        end else begin
            if (fa[30:23] == 8'h00) begin
                sig = {1'b0, fa[22:0]}; e = -10'sd126;
            end else begin
                sig = {1'b1, fa[22:0]}; e = $signed({2'b00, fa[30:23]}) - 10'sd127;
            end
            // magnitude = sig * 2^(e-23)
            if (e >= 10'sd32) begin
                cvtws_res = cvt_u ? (s ? 32'h0 : 32'hFFFF_FFFF)
                                  : (s ? 32'h8000_0000 : 32'h7FFF_FFFF);
                cvtws_fl  = 5'b10000;
            end else begin
                rnd = 1'b0; stk = 1'b0;
                if (e >= 10'sd23) begin
                    wide = {40'b0, sig} << (e - 10'sd23);
                    mag  = wide[31:0];                  // e<=31 so fits 33b; check below
                end else begin
                    sh = 23 - $signed({{22{e[9]}}, e});   // 1..149
                    if (sh > 24) begin
                        mag = 32'h0; rnd = 1'b0; stk = (sig != 24'b0);
                    end else if (sh == 24) begin
                        mag = 32'h0; rnd = sig[23]; stk = (sig[22:0] != 23'b0);
                    end else begin
                        mag = {8'b0, sig} >> sh;
                        rnd = sig[sh-1];
                        stk = ((sig & ((24'h1 << (sh-1)) - 24'h1)) != 24'b0);
                    end
                    wide = {32'b0, mag};
                end
                // round the magnitude
                inc = (rm_eff == 3'd0) ? (rnd && (stk || mag[0])) :   // RNE
                      (rm_eff == 3'd1) ? 1'b0 :                       // RTZ
                      (rm_eff == 3'd2) ? (s && (rnd || stk)) :        // RDN
                      (rm_eff == 3'd3) ? (!s && (rnd || stk)) :       // RUP
                                         rnd;                          // RMM
                magr = {1'b0, (e >= 10'sd23) ? wide[31:0] : mag} + {32'b0, inc};
                if ((e >= 10'sd23) && (wide[63:32] != 32'b0)) begin
                    cvtws_res = cvt_u ? (s ? 32'h0 : 32'hFFFF_FFFF)
                                      : (s ? 32'h8000_0000 : 32'h7FFF_FFFF);
                    cvtws_fl  = 5'b10000;
                end else if (cvt_u) begin
                    if (s && (magr != 33'b0)) begin
                        cvtws_res = 32'h0; cvtws_fl = 5'b10000;       // negative -> NV
                    end else if (magr[32]) begin
                        cvtws_res = 32'hFFFF_FFFF; cvtws_fl = 5'b10000;
                    end else begin
                        cvtws_res = magr[31:0];
                        cvtws_fl  = (rnd || stk) ? 5'b00001 : 5'b0;   // NX
                    end
                end else begin
                    if (!s && (magr > 33'h7FFF_FFFF)) begin
                        cvtws_res = 32'h7FFF_FFFF; cvtws_fl = 5'b10000;
                    end else if (s && (magr > 33'h8000_0000)) begin
                        cvtws_res = 32'h8000_0000; cvtws_fl = 5'b10000;
                    end else begin
                        cvtws_res = s ? (~magr[31:0] + 32'h1) : magr[31:0];
                        cvtws_fl  = (rnd || stk) ? 5'b00001 : 5'b0;
                    end
                end
            end
        end
    end

    // ---------------- fcvt.s.w[u] ----------------
    reg [31:0] cvtsw_res;
    reg [4:0]  cvtsw_fl;
    function [5:0] clz32;
        input [31:0] v;
        integer i;
        begin
            clz32 = 6'd32;
            for (i = 31; i >= 0; i = i - 1)
                if (v[i] && (clz32 == 6'd32)) clz32 = 6'd31 - i[5:0];
        end
    endfunction
    always @* begin : cvt_sw
        reg        s;
        reg [31:0] mag, norm;
        reg [5:0]  lz;
        reg [7:0]  ex;
        reg [23:0] man;               // 1 + 23 mantissa after round
        reg        rnd, stk, inc;
        cvtsw_res = 32'h0; cvtsw_fl = 5'b0;
        norm = 32'b0; lz = 6'b0; ex = 8'b0; man = 24'b0;
        rnd = 1'b0; stk = 1'b0; inc = 1'b0;
        s   = !cvt_u && q_rs1[31];
        mag = s ? (~q_rs1 + 32'h1) : q_rs1;
        if (mag != 32'h0) begin
            lz   = clz32(mag);
            norm = mag << lz[4:0];                       // msb at bit31
            ex   = 8'd158 - {2'b0, lz[5:0]};             // 127 + (31 - lz)
            rnd  = norm[7];
            stk  = (norm[6:0] != 7'b0);
            inc  = (rm_eff == 3'd0) ? (rnd && (stk || norm[8])) :
                   (rm_eff == 3'd1) ? 1'b0 :
                   (rm_eff == 3'd2) ? (s && (rnd || stk)) :
                   (rm_eff == 3'd3) ? (!s && (rnd || stk)) :
                                      rnd;
            man = {1'b0, norm[30:8]} + {23'b0, inc};
            if (man[23]) begin                           // mantissa overflow
                cvtsw_res = {s, ex + 8'd1, 23'b0};
            end else begin
                cvtsw_res = {s, ex, man[22:0]};
            end
            cvtsw_fl = (rnd || stk) ? 5'b00001 : 5'b0;   // NX
        end
    end

    // ---------------- result muxes ----------------
    assign q_fwe = q_hit && !q_illegal &&
                   (op_sgnj || op_mnmx || op_mvwx || op_cvtsw);
    assign q_fd  = rd_i;
    assign q_fdata = op_sgnj  ? r_sgnj :
                     op_mnmx  ? mnmx_ab :
                     op_mvwx  ? q_rs1 :
                                cvtsw_res;

    assign q_xwe = q_hit && !q_illegal &&
                   (op_cmp || op_mvxw || op_class || op_cvtws);
    assign q_xdata = op_cmp   ? r_cmp :
                     op_mvxw  ? fa :
                     op_class ? {22'b0, fclass_f(fa)} :
                                cvtws_res;

    assign q_flags = (!q_hit || q_illegal) ? 5'b0 :
                     op_cmp   ? fl_cmp :
                     op_mnmx  ? fl_mnmx :
                     op_cvtws ? cvtws_fl :
                     op_cvtsw ? cvtsw_fl : 5'b0;

endmodule
`default_nettype wire
