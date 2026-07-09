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

    // ---- F4 multi-cycle (fdiv/fsqrt iterative engines) ----
    output wire        q_fmc_busy,  // fdiv or fsqrt iterating: hold the pipe (like md_busy)
    input  wire        q_flush,     // redirect/debug: kill in-flight fdiv/fsqrt (ERRATA-0002)
    input  wire        q_advance,   // instr leaves EX this cycle (consume held result)

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

    // ---- F2/F3/F4 (ADR-0050): arithmetic / FMA / div-sqrt ----
    wire op_fadd  = is_opfp && fmt_s && (f5 == 5'b00000);
    wire op_fsub  = is_opfp && fmt_s && (f5 == 5'b00001);
    wire op_fmul  = is_opfp && fmt_s && (f5 == 5'b00010);
    wire op_fdiv  = is_opfp && fmt_s && (f5 == 5'b00011);
    wire op_fsqrt = is_opfp && fmt_s && (f5 == 5'b01011) && (rs2f == 5'd0);
    wire op_fma   = is_fma_opc && fmt_s;
    wire fma_negp = q_instr[3];                 // fnmsub/fnmadd negate product
    wire fma_negc = q_instr[2];                 // fmsub/fnmadd negate addend

    wire needs_rm = op_cvtws || op_cvtsw || op_fadd || op_fsub || op_fmul ||
                    op_fdiv || op_fsqrt || op_fma;
    wire [2:0] rm_eff = (f3 == 3'b111) ? q_frm : f3;
    wire rm_bad = needs_rm &&
                  ((f3 == 3'b101) || (f3 == 3'b110) ||
                   ((f3 == 3'b111) && (q_frm > 3'd4)));

    wire known_op = op_sgnj || op_mnmx || op_cmp || op_mvxw || op_class ||
                    op_mvwx || op_cvtws || op_cvtsw || q_is_flw || q_is_fsw ||
                    op_fadd || op_fsub || op_fmul || op_fdiv || op_fsqrt || op_fma;
    assign q_illegal = q_hit && (!known_op || rm_bad);

    // ---------------- F regfile ----------------
    reg [31:0] fregs [0:31];
    wire [31:0] fa = fregs[rs1_i];
    wire [31:0] fb = fregs[rs2f];
    wire [31:0] fc = fregs[q_instr[31:27]];     // FMA rs3
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

    // =========================================================================
    // F2/F3/F4 — transcribed from Berkeley softfloat-3 (the same algorithms
    // Spike executes), so lockstep equivalence is by construction:
    // roundPackToF32 (tininess AFTER rounding), addMags/subMags, mul with
    // shortShiftRightJam64(·,32), mulAdd with the 64-bit aligned-sum path,
    // div via full-width quotient + remainder-jam, sqrt via integer sqrt +
    // square-check sticky. All combinational at sim level (pipelining is a
    // Phase-7 concern alongside the 256-MAC tree — recorded in ADR-0050).
    // =========================================================================
    function [63:0] srj64;                    // shiftRightJam64
        input [63:0] v; input [6:0] d;
        begin
            if (d == 7'd0) srj64 = v;
            else if (d < 7'd64)
                srj64 = (v >> d) | {63'b0, (v & ((64'h1 << d) - 64'h1)) != 64'h0};
            else srj64 = {63'b0, v != 64'h0};
        end
    endfunction

    function [5:0] clz64h;                    // count leading zeros, 64-bit
        input [63:0] v;
        integer i;
        begin
            clz64h = 6'd63;                   // (v==0 never queried)
            for (i = 63; i >= 0; i = i - 1)
                if (v[i] && (clz64h == 6'd63)) clz64h = 6'd63 - i[5:0];
            if (v == 64'h0) clz64h = 6'd63;
        end
    endfunction

    // normalize a subnormal significand: {exp10, sig23} -> exp = 1 - shift
    function [33:0] norm_sub;                 // {exp[9:0], sig[23:0]}
        input [22:0] m;
        reg [5:0] lz;
        reg [23:0] s24;
        begin
            lz  = clz32({9'b0, m}) - 6'd9;    // leading zeros within 23 bits
            s24 = {1'b0, m} << (lz + 6'd1);   // implicit-1 position (bit 23)
            norm_sub = {10'($signed(-{4'b0, lz})), s24};
        end
    endfunction

    // softfloat roundPackToF32 (tininess AFTER rounding): sig[30:7] = 24-bit
    // significand, sig[6:0] = round bits
    function [36:0] rp32;                      // {flags, f32}
        input        sign;
        input signed [9:0] exp;
        input [30:0] sig;
        reg [6:0]  rinc, rbits;
        reg [30:0] s;
        reg [31:0] s32;
        reg [63:0] srjt;                          // srj64 result before slice (portable frontends reject fn()[..])
        reg signed [9:0] e;
        reg        tiny, ovf;
        reg [4:0]  fl;
        begin
            s32 = 32'b0; srjt = 64'b0;
            fl = 5'b0; ovf = 1'b0;
            rinc = ((rm_eff == 3'd0) || (rm_eff == 3'd4)) ? 7'h40 :
                   (((rm_eff == 3'd2) && sign) || ((rm_eff == 3'd3) && !sign)) ? 7'h7F :
                   7'h00;
            e = exp; s = sig;
            if (e < 10'sd0) begin
                tiny = (e < -10'sd1) ||
                       ({1'b0, s} + {25'b0, rinc} < 32'h8000_0000);
                srjt = srj64({33'b0, s}, (-e > 10'sd63) ? 7'd63 : 7'(-e));
                s = srjt[30:0];
                e = 10'sd0;
                if (tiny && (s[6:0] != 7'b0)) fl[1] = 1'b1;           // UF
            end else if ((e > 10'sd253) ||
                         ((e == 10'sd253) &&
                          ({1'b0, s} + {25'b0, rinc} >= 32'h8000_0000))) begin
                ovf = 1'b1;
                fl[2] = 1'b1; fl[0] = 1'b1;                           // OF|NX
            end
            if (ovf) begin
                rp32 = {fl, ({sign, 8'hFF, 23'b0} - ((rinc == 7'h0) ? 32'h1 : 32'h0))};
            end else begin
                rbits = s[6:0];
                if (rbits != 7'b0) fl[0] = 1'b1;                      // NX
                s32 = ({1'b0, s} + {25'b0, rinc}) >> 7;               // 32-bit sum
                s = s32[30:0];
                if ((rm_eff == 3'd0) && (rbits == 7'h40)) s = s & ~31'h1;
                // softfloat: exp collapses only when the WHOLE significand is
                // zero; the pack is an ADD so a mantissa carry (bit 24) rolls
                // into the exponent (1.0-eps rounding back up to 1.0)
                if (s == 31'b0) e = 10'sd0;
                rp32 = {fl, {sign, 31'b0} + (32'($signed(e)) << 23) + {6'b0, s[25:0]}};
            end
        end
    endfunction

    // unpack helpers (raw fields)
    wire [7:0]  eA = fa[30:23], eB = fb[30:23], eC = fc[30:23];
    wire [22:0] mA = fa[22:0],  mB = fb[22:0],  mC = fc[22:0];
    wire sA = fa[31], sB = fb[31], sC = fc[31];
    wire c_nan  = (eC == 8'hFF) && (mC != 23'b0);
    wire c_snan = c_nan && !fc[22];
    wire a_inf = (eA == 8'hFF) && (mA == 23'b0);
    wire b_inf = (eB == 8'hFF) && (mB == 23'b0);
    wire c_inf = (eC == 8'hFF) && (mC == 23'b0);
    wire a_zeroe = (eA == 8'h0) && (mA == 23'b0);
    wire b_zeroe = (eB == 8'h0) && (mB == 23'b0);
    wire c_zeroe = (eC == 8'h0) && (mC == 23'b0);

    // normalized {exp,sig24} view (norm/subnormal)
    wire [33:0] nA = (eA == 8'h0) ? norm_sub(mA) : {2'b0, eA, 1'b1, mA};
    wire [33:0] nB = (eB == 8'h0) ? norm_sub(mB) : {2'b0, eB, 1'b1, mB};
    wire [33:0] nC = (eC == 8'h0) ? norm_sub(mC) : {2'b0, eC, 1'b1, mC};
    wire signed [9:0] enA = nA[33:24];
    wire signed [9:0] enB = nB[33:24];
    wire signed [9:0] enC = nC[33:24];
    wire [23:0] sgA = nA[23:0], sgB = nB[23:0], sgC = nC[23:0];

    // ---------------- fadd / fsub (softfloat addMags/subMags) ----------------
    reg  [31:0] fas_res;
    reg  [4:0]  fas_fl;
    always @* begin : f_addsub
        reg sEffB, signZ, sub_mode;
        reg signed [9:0] expDiff, expZ;
        reg [30:0] xA, xB;
        reg [31:0] sigZ;
        reg [63:0] srjt;                          // srj64 result before slice
        reg [23:0] sigDiff;
        reg [5:0]  shd;
        reg [36:0] rp;
        fas_res = 32'h0; fas_fl = 5'b0;
        sEffB = sB ^ op_fsub;
        signZ = sA; sub_mode = (sA != sEffB);
        expDiff = 10'($signed({2'b0, eA})) - 10'($signed({2'b0, eB}));
        xA = 31'b0; xB = 31'b0; sigZ = 32'b0; sigDiff = 24'b0; shd = 6'b0; expZ = 10'sd0;
        rp = 37'b0; srjt = 64'b0;
        if (a_nan || b_nan) begin
            fas_res = QNAN; fas_fl = (a_snan || b_snan) ? 5'b10000 : 5'b0;
        end else if (a_inf || b_inf) begin
            if (a_inf && b_inf && sub_mode) begin
                fas_res = QNAN; fas_fl = 5'b10000;                    // inf-inf
            end else
                fas_res = a_inf ? fa : {sEffB, 8'hFF, 23'b0};
        end else if (!sub_mode) begin
            // ---- addMags ----
            if (expDiff == 10'sd0) begin
                if (eA == 8'h0) begin
                    fas_res = {sA, fa[30:0] + fb[30:0]};              // subnormal+subnormal (exact)
                end else begin
                    sigZ = 32'h0100_0000 + {9'b0, mA} + {9'b0, mB};
                    if (!sigZ[0] && (eA < 8'hFE))
                        fas_res = {sA, eA + 8'h1, sigZ[23:1]};
                    else begin
                        rp = rp32(signZ, 10'($signed({2'b0, eA})), sigZ[24:0] << 6);
                        fas_fl = rp[36:32]; fas_res = rp[31:0];
                    end
                end
            end else begin
                xA = {2'b0, mA, 6'b0}; xB = {2'b0, mB, 6'b0};
                if (expDiff < 10'sd0) begin
                    expZ = 10'($signed({2'b0, eB}));
                    xA = (eA != 8'h0) ? (xA | 31'h2000_0000) : (xA << 1);
                    srjt = srj64({33'b0, xA}, (-expDiff > 10'sd63) ? 7'd63 : 7'(-expDiff)); xA = srjt[30:0];
                end else begin
                    expZ = 10'($signed({2'b0, eA}));
                    xB = (eB != 8'h0) ? (xB | 31'h2000_0000) : (xB << 1);
                    srjt = srj64({33'b0, xB}, (expDiff > 10'sd63) ? 7'd63 : 7'(expDiff)); xB = srjt[30:0];
                end
                sigZ = 32'h2000_0000 + {1'b0, xA} + {1'b0, xB};
                if (sigZ < 32'h4000_0000) begin
                    expZ = expZ - 10'sd1; sigZ = sigZ << 1;
                end
                rp = rp32(signZ, expZ, sigZ[30:0]);
                fas_fl = rp[36:32]; fas_res = rp[31:0];
            end
        end else begin
            // ---- subMags ----
            if (expDiff == 10'sd0) begin
                sigDiff = {1'b0, mA} - {1'b0, mB};
                if (mA == mB) begin
                    fas_res = {(rm_eff == 3'd2), 8'h0, 23'b0};        // ±0 (RDN -> -0)
                end else begin
                    if (sigDiff[23]) begin                            // mB > mA
                        signZ = !signZ; sigDiff = (~sigDiff) + 24'h1;
                    end
                    // softfloat subMagsF32 equal-exp path: `if (expA) --expA;`
                    // FIRST, then shiftDist = clz32(sigDiff)-8; expZ = expA-shiftDist.
                    // The additive packToF32UI lets sigDiff's leading 1 (now at bit
                    // 23 after the shift) carry INTO the exponent field — so expA
                    // must be pre-decremented or the result is one exponent too high.
                    expZ = (eA != 8'h0) ? 10'($signed({2'b0, eA})) - 10'sd1
                                        : 10'($signed({2'b0, eA}));
                    shd  = clz32({8'b0, sigDiff[23:0]}) - 6'd8;
                    expZ = expZ - 10'($signed({4'b0, shd}));
                    if (expZ < 10'sd0) begin
                        shd  = (eA == 8'h0) ? 6'd0 : (eA[5:0] - 6'd1); // softfloat: shiftDist = (decremented) expA
                        expZ = 10'sd0;
                    end
                    fas_res = {signZ, 8'b0, 23'b0} +
                              (32'($signed(expZ)) << 23) +
                              {8'b0, sigDiff << shd};
                end
            end else begin
                xA = {1'b0, mA, 7'b0}; xB = {1'b0, mB, 7'b0};
                if (expDiff < 10'sd0) begin
                    signZ = !signZ;
                    expZ = 10'($signed({2'b0, eB}));
                    xA = (eA != 8'h0) ? (xA | 31'h4000_0000) : (xA << 1);
                    srjt = srj64({33'b0, xA}, (-expDiff > 10'sd63) ? 7'd63 : 7'(-expDiff)); xA = srjt[30:0];
                    xB = xB | 31'h4000_0000;
                    sigZ = {1'b0, xB} - {1'b0, xA};
                end else begin
                    expZ = 10'($signed({2'b0, eA}));
                    xB = (eB != 8'h0) ? (xB | 31'h4000_0000) : (xB << 1);
                    srjt = srj64({33'b0, xB}, (expDiff > 10'sd63) ? 7'd63 : 7'(expDiff)); xB = srjt[30:0];
                    xA = xA | 31'h4000_0000;
                    sigZ = {1'b0, xA} - {1'b0, xB};
                end
                // normRoundPack: exp-1, normalize
                expZ = expZ - 10'sd1;
                shd = clz32(sigZ) - 6'd1;
                expZ = expZ - 10'($signed({4'b0, shd}));
                rp = rp32(signZ, expZ, sigZ[30:0] << shd);
                fas_fl = rp[36:32]; fas_res = rp[31:0];
            end
        end
    end

    // ---------------- fmul (softfloat f32_mul) ----------------
    reg  [31:0] fmul_res;
    reg  [4:0]  fmul_fl;
    always @* begin : f_mul
        reg signZ;
        reg signed [9:0] expZ;
        reg [63:0] prod;
        reg [31:0] sigZ;
        reg [36:0] rp;
        fmul_res = 32'h0; fmul_fl = 5'b0;
        signZ = sA ^ sB;
        expZ = 10'sd0; prod = 64'b0; sigZ = 32'b0; rp = 37'b0;
        if (a_nan || b_nan) begin
            fmul_res = QNAN; fmul_fl = (a_snan || b_snan) ? 5'b10000 : 5'b0;
        end else if ((a_inf && b_zeroe) || (b_inf && a_zeroe)) begin
            fmul_res = QNAN; fmul_fl = 5'b10000;
        end else if (a_inf || b_inf) begin
            fmul_res = {signZ, 8'hFF, 23'b0};
        end else if (a_zeroe || b_zeroe) begin
            fmul_res = {signZ, 31'b0};
        end else begin
            expZ = enA + enB - 10'sd127;
            prod = ({40'b0, sgA} << 7) * ({40'b0, sgB} << 8);
            sigZ = prod[63:32] | {31'b0, (prod[31:0] != 32'b0)};      // shortShiftRightJam64(·,32)
            if (sigZ < 32'h4000_0000) begin
                expZ = expZ - 10'sd1; sigZ = sigZ << 1;
            end
            rp = rp32(signZ, expZ, sigZ[30:0]);
            fmul_fl = rp[36:32]; fmul_res = rp[31:0];
        end
    end

    // ---------------- FMA (softfloat mulAddF32) ----------------
    reg  [31:0] fma_res;
    reg  [4:0]  fma_fl;
    always @* begin : f_fma
        reg spd, scc, signZ;
        reg signed [9:0] expProd, expC10, expDiff, expZ;
        reg [63:0] sigProd, sig64C, sig64Z;
        reg [31:0] sigZ, sigC32;
        reg [6:0]  shd7;
        reg signed [7:0] shd;
        reg [36:0] rp;
        fma_res = 32'h0; fma_fl = 5'b0;
        spd = sA ^ sB ^ fma_negp;
        scc = sC ^ fma_negc;
        signZ = spd;
        expProd = 10'sd0; expC10 = 10'sd0; expDiff = 10'sd0; expZ = 10'sd0;
        sigProd = 64'b0; sig64C = 64'b0; sig64Z = 64'b0;
        sigZ = 32'b0; sigC32 = 32'b0; shd = 8'sd0; shd7 = 7'b0; rp = 37'b0;
        if (a_nan || b_nan || c_nan) begin
            fma_res = QNAN;
            fma_fl = (a_snan || b_snan || c_snan ||
                      (a_inf && b_zeroe) || (b_inf && a_zeroe)) ? 5'b10000 : 5'b0;
        end else if ((a_inf && b_zeroe) || (b_inf && a_zeroe)) begin
            fma_res = QNAN; fma_fl = 5'b10000;
        end else if (a_inf || b_inf) begin
            if (c_inf && (scc != spd)) begin
                fma_res = QNAN; fma_fl = 5'b10000;                    // inf - inf
            end else
                fma_res = {spd, 8'hFF, 23'b0};
        end else if (c_inf) begin
            fma_res = {scc, 8'hFF, 23'b0};
        end else if (a_zeroe || b_zeroe) begin
            // exact product zero + C
            if (c_zeroe)
                fma_res = {(spd == scc) ? spd : (rm_eff == 3'd2), 31'b0};
            else
                fma_res = fc ^ {fma_negc, 31'b0};
        end else begin
            // F3 2-stage: the mantissa multiply (sigProd) + its exponent are
            // computed in stage 1 and registered (fma_sigProd_r/fma_expProd_r);
            // this stage-2 pass does align/add/normalize/round from the register,
            // breaking the mult->add->round combinational cone. Operand-derived
            // signals stay valid because the op is held in EX for the extra cycle.
            expProd = fma_expProd_r;
            sigProd = fma_sigProd_r;
            if (c_zeroe) begin
                expZ = expProd - 10'sd1;
                sigZ = sigProd[62:31] | {31'b0, (sigProd[30:0] != 31'b0)};
                rp = rp32(signZ, expZ, sigZ[30:0]);
                fma_fl = rp[36:32]; fma_res = rp[31:0];
            end else begin
                expC10 = enC;
                sigC32 = {2'b0, sgC, 6'b0};                           // 30-bit
                expDiff = expProd - expC10;
                if (spd == scc) begin
                    if (expDiff <= 10'sd0) begin
                        expZ = expC10;
                        sig64Z = srj64(sigProd, (10'sd32 - expDiff > 10'sd63) ? 7'd63 : 7'(10'sd32 - expDiff));
                        sigZ = sigC32 + sig64Z[31:0];
                    end else begin
                        expZ = expProd;
                        sig64Z = sigProd +
                                 srj64({sigC32, 32'b0}, (expDiff > 10'sd63) ? 7'd63 : 7'(expDiff));
                        sigZ = sig64Z[63:32] | {31'b0, (sig64Z[31:0] != 32'b0)};
                    end
                    if (sigZ < 32'h4000_0000) begin
                        expZ = expZ - 10'sd1; sigZ = sigZ << 1;
                    end
                    rp = rp32(signZ, expZ, sigZ[30:0]);
                    fma_fl = rp[36:32]; fma_res = rp[31:0];
                end else begin
                    sig64C = {sigC32, 32'b0};
                    if (expDiff < 10'sd0) begin
                        signZ = scc;
                        expZ = expC10;
                        sig64Z = sig64C -
                                 srj64(sigProd, (-expDiff > 10'sd63) ? 7'd63 : 7'(-expDiff));
                    end else if (expDiff == 10'sd0) begin
                        expZ = expProd;
                        sig64Z = sigProd - sig64C;
                        if (sig64Z == 64'b0) begin
                            sig64Z = 64'b0;
                        end else if (sig64Z[63]) begin
                            signZ = !signZ;
                            sig64Z = (~sig64Z) + 64'h1;
                        end
                    end else begin
                        expZ = expProd;
                        sig64Z = sigProd -
                                 srj64(sig64C, (expDiff > 10'sd63) ? 7'd63 : 7'(expDiff));
                    end
                    if ((expDiff == 10'sd0) && (sig64Z == 64'b0)) begin
                        fma_res = {(rm_eff == 3'd2), 31'b0};          // exact cancel
                    end else begin
                        shd = 8'($signed({2'b0, clz64h(sig64Z)})) - 8'sd1;
                        expZ = expZ - 10'($signed(shd));
                        shd = shd - 8'sd32;
                        if (shd < 8'sd0) begin
                            shd7 = 7'(-shd);
                            sigZ = sig64Z[31:0];                      // placeholder
                            sig64Z = srj64(sig64Z, shd7);
                            sigZ = sig64Z[31:0];
                        end else begin
                            sigZ = sig64Z[31:0] << shd;
                        end
                        rp = rp32(signZ, expZ, sigZ[30:0]);
                        fma_fl = rp[36:32]; fma_res = rp[31:0];
                    end
                end
            end
        end
    end

    // ---------------- fdiv (softfloat f32_div structure) ----------------
    // F4 multi-cycle: NaN/inf/zero/DZ special cases resolve in one combinational
    // cycle; the normal-case significand divide (num / sgB) is an iterative
    // radix-2 restoring divider — bit-exact to floor(num/sgB) — that removes the
    // huge combinational divide array from the EX critical path. Handshake mirrors
    // div.v (start / done-held-until-advance / flush on redirect, ERRATA-0002).
    wire fdiv_op_here   = op_fdiv && q_hit && !q_illegal;
    wire fdiv_special   = a_nan || b_nan || a_inf || b_inf || b_zeroe || a_zeroe;
    wire fdiv_needs_iter = fdiv_op_here && !fdiv_special;

    // --- special-case result (combinational, 1 cycle) ---
    reg  [31:0] fdiv_sp_res;
    reg  [4:0]  fdiv_sp_fl;
    always @* begin : f_div_special
        reg signZ;
        signZ = sA ^ sB;
        fdiv_sp_res = 32'h0; fdiv_sp_fl = 5'b0;
        if (a_nan || b_nan) begin
            fdiv_sp_res = QNAN; fdiv_sp_fl = (a_snan || b_snan) ? 5'b10000 : 5'b0;
        end else if (a_inf && b_inf) begin
            fdiv_sp_res = QNAN; fdiv_sp_fl = 5'b10000;
        end else if (a_inf) begin
            fdiv_sp_res = {signZ, 8'hFF, 23'b0};
        end else if (b_inf) begin
            fdiv_sp_res = {signZ, 31'b0};
        end else if (b_zeroe) begin
            if (a_zeroe) begin
                fdiv_sp_res = QNAN; fdiv_sp_fl = 5'b10000;            // 0/0
            end else begin
                fdiv_sp_res = {signZ, 8'hFF, 23'b0}; fdiv_sp_fl = 5'b01000; // DZ
            end
        end else if (a_zeroe) begin
            fdiv_sp_res = {signZ, 31'b0};
        end
    end

    // --- iterative radix-2 restoring divider (normal case) ---
    localparam [1:0] FD_IDLE = 2'd0, FD_WORK = 2'd1, FD_DONE = 2'd2;
    reg  [1:0]  fd_state;
    reg  [5:0]  fd_iter;               // 0..55 (56 quotient steps)
    reg  [55:0] fd_dvd;                // dividend, MSB-first consumed (sgA<<31 or <<30)
    reg  [23:0] fd_dsor;              // divisor = sgB
    reg  [24:0] fd_rem;               // partial remainder (< 2*sgB < 2^25)
    reg  [31:0] fd_quo;               // quotient[31:0] accumulator
    reg         fd_signZ;
    reg  signed [9:0] fd_expZ;
    reg         fdiv_result_valid;
    reg  [31:0] fdiv_iter_res;
    reg  [4:0]  fdiv_iter_fl;

    wire fdiv_busy_i = (EN_F != 0) && q_valid && fdiv_needs_iter && !fdiv_result_valid;
    wire fd_start = (EN_F != 0) && q_valid && fdiv_needs_iter &&
                    (fd_state == FD_IDLE) && !fdiv_result_valid && !q_flush;

    // one restoring step (combinational next-values)
    wire [24:0] fd_rem_sh = {fd_rem[23:0], fd_dvd[55]};
    wire        fd_ge     = (fd_rem_sh >= {1'b0, fd_dsor});
    wire [24:0] fd_rem_nx = fd_ge ? (fd_rem_sh - {1'b0, fd_dsor}) : fd_rem_sh;
    wire [31:0] fd_quo_nx = {fd_quo[30:0], fd_ge};

    // sticky + round-pack of the finished quotient (combinational, used in FD_DONE)
    reg  [31:0] fd_q_final;
    reg  [36:0] fd_rp;
    always @* begin : f_div_pack
        fd_q_final = fd_quo;
        if (fd_quo[5:0] == 6'b0)                    // low-6-zero: rem!=0 -> sticky
            fd_q_final = fd_quo | {31'b0, (fd_rem != 25'b0)};
        fd_rp = rp32(fd_signZ, fd_expZ, fd_q_final[30:0]);
    end

    always @(posedge clk) begin
        if (!resetn) begin
            fd_state <= FD_IDLE; fdiv_result_valid <= 1'b0;
        end else if (q_flush) begin
            fd_state <= FD_IDLE; fdiv_result_valid <= 1'b0;   // ERRATA-0002: kill wrong-path
        end else begin
            case (fd_state)
                FD_IDLE: if (fd_start) begin
                    fd_signZ <= sA ^ sB;
                    fd_expZ  <= enA - enB + 10'sd126 - (sgA < sgB ? 10'sd1 : 10'sd0);
                    fd_dvd   <= (sgA < sgB) ? {1'b0, sgA, 31'b0} : {2'b0, sgA, 30'b0};
                    fd_dsor  <= sgB;
                    fd_rem   <= 25'b0;
                    fd_quo   <= 32'b0;
                    fd_iter  <= 6'd0;
                    fd_state <= FD_WORK;
                end
                FD_WORK: begin
                    fd_rem  <= fd_rem_nx;
                    fd_quo  <= fd_quo_nx;
                    fd_dvd  <= {fd_dvd[54:0], 1'b0};
                    fd_iter <= fd_iter + 6'd1;
                    if (fd_iter == 6'd55) fd_state <= FD_DONE;
                end
                FD_DONE: begin
                    fdiv_iter_res     <= fd_rp[31:0];
                    fdiv_iter_fl      <= fd_rp[36:32];
                    fdiv_result_valid <= 1'b1;
                    fd_state          <= FD_IDLE;
                end
                default: fd_state <= FD_IDLE;
            endcase
            if (q_advance && fdiv_result_valid) fdiv_result_valid <= 1'b0;
        end
    end

    wire [31:0] fdiv_res = fdiv_special ? fdiv_sp_res : fdiv_iter_res;
    wire [4:0]  fdiv_fl  = fdiv_special ? fdiv_sp_fl  : fdiv_iter_fl;

    // ---------------- fsqrt (integer sqrt + square-check sticky) --------------
    // F4 multi-cycle: NaN/zero/neg/inf resolve in one combinational cycle; the
    // normal-case restoring integer sqrt (was a 31-iteration unrolled loop, a
    // top EX cone) is rolled into an iterative FSM — 31 cycles, 2 radicand bits
    // per step, bit-exact to the unrolled version. Same handshake as fdiv.
    wire fsqrt_op_here   = op_fsqrt && q_hit && !q_illegal;
    wire fsqrt_special   = a_nan || a_zeroe || sA || a_inf;
    wire fsqrt_needs_iter = fsqrt_op_here && !fsqrt_special;

    // --- special-case result (combinational, 1 cycle) ---
    reg  [31:0] fsq_sp_res;
    reg  [4:0]  fsq_sp_fl;
    always @* begin : f_sqrt_special
        fsq_sp_res = 32'h0; fsq_sp_fl = 5'b0;
        if (a_nan) begin
            fsq_sp_res = QNAN; fsq_sp_fl = a_snan ? 5'b10000 : 5'b0;
        end else if (a_zeroe) begin
            fsq_sp_res = fa;                                           // ±0
        end else if (sA) begin
            fsq_sp_res = QNAN; fsq_sp_fl = 5'b10000;                   // sqrt(neg)
        end else if (a_inf) begin
            fsq_sp_res = fa;
        end
    end

    // --- iterative restoring integer sqrt (normal case) ---
    localparam [1:0] FS_IDLE = 2'd0, FS_WORK = 2'd1, FS_DONE = 2'd2;
    reg  [1:0]  fs_state;
    reg  [4:0]  fs_iter;               // 0..30 (31 steps)
    reg  [61:0] fs_rad;               // radicand, top 2 bits consumed per step
    reg  [63:0] fs_rem;               // partial remainder
    reg  [31:0] fs_q;                 // running root
    reg  signed [9:0] fs_expZ;
    reg         fsqrt_result_valid;
    reg  [31:0] fsqrt_iter_res;
    reg  [4:0]  fsqrt_iter_fl;

    wire fsqrt_busy_i = (EN_F != 0) && q_valid && fsqrt_needs_iter && !fsqrt_result_valid;
    wire fs_start = (EN_F != 0) && q_valid && fsqrt_needs_iter &&
                    (fs_state == FS_IDLE) && !fsqrt_result_valid && !q_flush;

    // one restoring step (2 bits/cycle, combinational next-values)
    wire [63:0] fs_rem_sh = (fs_rem << 2) | {62'b0, fs_rad[61:60]};
    wire [63:0] fs_cmp    = {30'b0, fs_q, 2'b01};
    wire        fs_ge     = (fs_rem_sh >= fs_cmp);
    wire [63:0] fs_rem_nx = fs_ge ? (fs_rem_sh - fs_cmp) : fs_rem_sh;
    wire [31:0] fs_q_nx   = fs_ge ? ((fs_q << 1) | 32'h1) : (fs_q << 1);

    // sticky + round-pack of the finished root (combinational, used in FS_DONE)
    reg  [31:0] fs_q_final;
    reg  [36:0] fs_rp;
    always @* begin : f_sqrt_pack
        fs_q_final = fs_q;
        if (fs_q[5:0] == 6'b0)
            fs_q_final = fs_q | {31'b0, (fs_rem != 64'b0)};
        fs_rp = rp32(1'b0, fs_expZ, fs_q_final[30:0]);
    end

    always @(posedge clk) begin
        if (!resetn) begin
            fs_state <= FS_IDLE; fsqrt_result_valid <= 1'b0;
        end else if (q_flush) begin
            fs_state <= FS_IDLE; fsqrt_result_valid <= 1'b0;   // ERRATA-0002
        end else begin
            case (fs_state)
                FS_IDLE: if (fs_start) begin
                    // E = enA-127; odd E folds a x2 into the radicand.
                    fs_expZ <= ((enA - 10'sd127 - (enA[0] ? 10'sd0 : 10'sd1)) >>> 1)
                               + 10'sd126;
                    fs_rad  <= ({38'b0, sgA} << (enA[0] ? 6'd37 : 6'd38)); // 62-bit radicand
                    fs_rem  <= 64'b0;
                    fs_q    <= 32'b0;
                    fs_iter <= 5'd0;
                    fs_state <= FS_WORK;
                end
                FS_WORK: begin
                    fs_rem  <= fs_rem_nx;
                    fs_q    <= fs_q_nx;
                    fs_rad  <= {fs_rad[59:0], 2'b0};
                    fs_iter <= fs_iter + 5'd1;
                    if (fs_iter == 5'd30) fs_state <= FS_DONE;
                end
                FS_DONE: begin
                    fsqrt_iter_res     <= fs_rp[31:0];
                    fsqrt_iter_fl      <= fs_rp[36:32];
                    fsqrt_result_valid <= 1'b1;
                    fs_state           <= FS_IDLE;
                end
                default: fs_state <= FS_IDLE;
            endcase
            if (q_advance && fsqrt_result_valid) fsqrt_result_valid <= 1'b0;
        end
    end

    wire [31:0] fsq_res = fsqrt_special ? fsq_sp_res : fsqrt_iter_res;
    wire [4:0]  fsq_fl  = fsqrt_special ? fsq_sp_fl  : fsqrt_iter_fl;

    // ---------------- FMA 2-stage (F3): register the mantissa multiply ----------
    // The fused multiply-add was the tallest EX cone (mult -> align-add -> round).
    // Stage 1 computes the 48-bit mantissa product + its exponent and registers
    // them; stage 2 (the f_fma block above) does align/add/round from the register.
    // Normal FMA takes 1 extra cycle (held via q_fmc_busy); specials stay 1-cycle.
    // Operands stay valid across the hold, so only sigProd/expProd need registering.
    wire fma_op_here    = op_fma && q_hit && !q_illegal;
    wire fma_special    = a_nan || b_nan || c_nan || a_inf || b_inf || c_inf ||
                          a_zeroe || b_zeroe;
    wire fma_needs_iter = fma_op_here && !fma_special;

    wire [63:0] fma_sigProd_c0 = ({40'b0, sgA} << 7) * ({40'b0, sgB} << 7);
    wire        fma_norm_c     = (fma_sigProd_c0 < 64'h2000_0000_0000_0000);
    wire [63:0] fma_sigProd_c  = fma_norm_c ? (fma_sigProd_c0 << 1) : fma_sigProd_c0;
    wire signed [9:0] fma_expProd_c = enA + enB - 10'sd126 -
                                      (fma_norm_c ? 10'sd1 : 10'sd0);

    reg  [63:0] fma_sigProd_r;
    reg  signed [9:0] fma_expProd_r;
    reg         fma_result_valid;
    wire fma_busy_i = (EN_F != 0) && q_valid && fma_needs_iter && !fma_result_valid;

    always @(posedge clk) begin
        if (!resetn) begin
            fma_result_valid <= 1'b0;
        end else if (q_flush) begin
            fma_result_valid <= 1'b0;                       // ERRATA-0002
        end else begin
            if (fma_needs_iter && !fma_result_valid) begin  // stage 1: latch product
                fma_sigProd_r    <= fma_sigProd_c;
                fma_expProd_r    <= fma_expProd_c;
                fma_result_valid <= 1'b1;
            end
            if (q_advance && fma_result_valid) fma_result_valid <= 1'b0;
        end
    end

    // combined float multi-cycle busy (fdiv / fsqrt / fma) -> pipe stall
    assign q_fmc_busy = fdiv_busy_i || fsqrt_busy_i || fma_busy_i;

    // ---------------- result muxes ----------------
    assign q_fwe = q_hit && !q_illegal &&
                   (op_sgnj || op_mnmx || op_mvwx || op_cvtsw ||
                    op_fadd || op_fsub || op_fmul || op_fdiv || op_fsqrt || op_fma);
    assign q_fd  = rd_i;
    assign q_fdata = op_sgnj  ? r_sgnj :
                     op_mnmx  ? mnmx_ab :
                     op_mvwx  ? q_rs1 :
                     (op_fadd || op_fsub) ? fas_res :
                     op_fmul  ? fmul_res :
                     op_fma   ? fma_res :
                     op_fdiv  ? fdiv_res :
                     op_fsqrt ? fsq_res :
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
                     op_cvtsw ? cvtsw_fl :
                     (op_fadd || op_fsub) ? fas_fl :
                     op_fmul  ? fmul_fl :
                     op_fma   ? fma_fl :
                     op_fdiv  ? fdiv_fl :
                     op_fsqrt ? fsq_fl : 5'b0;

endmodule
`default_nettype wire
