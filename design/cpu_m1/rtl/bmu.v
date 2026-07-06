// =============================================================================
// bmu.v — Bit-Manipulation Unit: Zba + Zbb + Zbs + Zicond (M1A A2, ADR-0026)
// -----------------------------------------------------------------------------
// Pure combinational, single-cycle at EX — pipeline behavior identical to the
// base ALU (EX/MEM forwardable, WB_SEL_ALU writeback). Kept as a SEPARATE unit
// (own 5-bit bmu_op) so the heavy logic (clz/ctz/cpop, rotate, byte-reverse)
// stays OUT of the base ALU case mux: core.v muxes
//   ex_result = id_is_bmu ? bmu_result : alu_result
// — one 2:1 mux on the EX writeback path (per-sub-phase DC smoke guards it).
//
// op_b semantics follow the ISA: register form takes rs2 (forwarded), immediate
// forms (rori/bclri/bexti/binvi/bseti) take the shamt/imm already placed on
// op_b by the IDU/operand mux; unary Zbb ops (clz/ctz/cpop/sext/zext/orc.b/
// rev8) ignore op_b.
// =============================================================================

`include "def.vh"

module bmu (
    input  [31:0] op_a,
    input  [31:0] op_b,
    input  [ 4:0] bmu_op,
    output reg [31:0] result
);

    wire [4:0] sh = op_b[4:0];

    // ---- count leading / trailing zeros, popcount ----
    // (W216 lint fix: 6-bit loop vars instead of integer part-selects)
    function [5:0] f_clz;
        input [31:0] x;
        reg [5:0] k;
        begin
            f_clz = 6'd32;
            for (k = 6'd0; k < 6'd32; k = k + 6'd1)
                if (x[5'd31 - k[4:0]] && f_clz == 6'd32)
                    f_clz = k;
        end
    endfunction

    function [5:0] f_ctz;
        input [31:0] x;
        reg [5:0] k;
        begin
            f_ctz = 6'd32;
            for (k = 6'd0; k < 6'd32; k = k + 6'd1)
                if (x[k[4:0]] && f_ctz == 6'd32)
                    f_ctz = k;
        end
    endfunction

    function [5:0] f_cpop;
        input [31:0] x;
        integer i;
        begin
            f_cpop = 6'd0;
            for (i = 0; i <= 31; i = i + 1)
                f_cpop = f_cpop + {5'b0, x[i]};
        end
    endfunction

    // ---- rotate / byte ops ----
    wire [31:0] rol_o  = (op_a << sh) | (op_a >> (6'd32 - {1'b0, sh}));
    wire [31:0] ror_o  = (op_a >> sh) | (op_a << (6'd32 - {1'b0, sh}));
    wire [31:0] rev8_o = {op_a[7:0], op_a[15:8], op_a[23:16], op_a[31:24]};
    wire [31:0] orcb_o = { {8{|op_a[31:24]}}, {8{|op_a[23:16]}},
                           {8{|op_a[15:8]}},  {8{|op_a[7:0]}} };

    // ---- comparisons (min/max share) ----
    wire lt_s = ($signed(op_a) < $signed(op_b));
    wire lt_u = (op_a < op_b);

    // ---- single-bit ops ----
    wire [31:0] bitmask = 32'h1 << sh;

    always @* begin
        case (bmu_op)
            `BMU_SH1ADD : result = (op_a << 1) + op_b;
            `BMU_SH2ADD : result = (op_a << 2) + op_b;
            `BMU_SH3ADD : result = (op_a << 3) + op_b;
            `BMU_ANDN   : result = op_a & ~op_b;
            `BMU_ORN    : result = op_a | ~op_b;
            `BMU_XNOR   : result = ~(op_a ^ op_b);
            `BMU_CLZ    : result = {26'b0, f_clz(op_a)};
            `BMU_CTZ    : result = {26'b0, f_ctz(op_a)};
            `BMU_CPOP   : result = {26'b0, f_cpop(op_a)};
            `BMU_MIN    : result = lt_s ? op_a : op_b;
            `BMU_MINU   : result = lt_u ? op_a : op_b;
            `BMU_MAX    : result = lt_s ? op_b : op_a;
            `BMU_MAXU   : result = lt_u ? op_b : op_a;
            `BMU_SEXTB  : result = {{24{op_a[7]}},  op_a[7:0]};
            `BMU_SEXTH  : result = {{16{op_a[15]}}, op_a[15:0]};
            `BMU_ZEXTH  : result = {16'b0, op_a[15:0]};
            `BMU_ROL    : result = rol_o;
            `BMU_ROR    : result = ror_o;
            `BMU_ORCB   : result = orcb_o;
            `BMU_REV8   : result = rev8_o;
            `BMU_BCLR   : result = op_a & ~bitmask;
            `BMU_BEXT   : result = {31'b0, op_a[sh]};
            `BMU_BINV   : result = op_a ^ bitmask;
            `BMU_BSET   : result = op_a | bitmask;
            `BMU_CZEQZ  : result = (op_b == 32'b0) ? 32'b0 : op_a;  // czero.eqz
            `BMU_CZNEZ  : result = (op_b != 32'b0) ? 32'b0 : op_a;  // czero.nez
            // verilator coverage_off
            default     : result = 32'h0;
            // verilator coverage_on
            // ^ CS-COV-1 exclusion: bmu_op only set to defined codes when is_bmu — coding standard CS-COV-1: defensive arm, unreachable by construction
        endcase
    end

endmodule
