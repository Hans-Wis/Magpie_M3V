// =============================================================================
// vexu.v — Zve32x vector EXU, Stage 3B slice (ADR-0036). VLEN=128, ELEN=32.
// -----------------------------------------------------------------------------
// Holds the VRF (32 x 128b) and computes single-register-group vector ops in
// ONE combinational pass at EX ("query"); the 128b result is piped by core.v
// through EX/MEM and EX/WB and committed to the VRF at WB (same kill rules as
// scalar rd writeback), so a trap/IRQ that replays the instruction never sees
// half-updated architectural state (vd==vs source overlap would otherwise not
// be idempotent).
//
// 3B op subset (everything else = q_illegal, honest deferral per ADR-0036):
//   vadd.vv/vx/vi, vsub.vv/vx, vmv.v.v/x/i (vs2 must be v0-encoded 0),
//   vmerge.vvm/vxm/vim, vmv.x.s. LMUL: m1 + fractional (mf2/mf4/mf8-legal
//   configs) only — m2/m4/m8 register groups are deferred (q_illegal).
//   Masked forms (vm=0) other than vmerge do not exist in this subset.
// Tail policy: UNDISTURBED regardless of vta — matches this Spike build, which
// implements tail-agnostic as undisturbed (caught by the gate_42 VRF debug tap:
// Spike left the ta tail at its old value where an all-1s fill diverged).
// Elements below vstart are undisturbed. vstart>=vl or vl==0 -> no VRF update
// at all (core still clears vstart at commit).
// vmv.x.s ignores vl (reads element 0 even when vl==0) and never writes VRF.
// =============================================================================
`default_nettype none

module vexu #(
    parameter EN_RVV = 0
) (
    input  wire         clk,

    // ---- EX-stage combinational query ----
    input  wire         q_valid,
    input  wire [31:0]  q_instr,
    input  wire [31:0]  q_vtype,     // effective (forwarded) vtype
    input  wire [31:0]  q_vl,        // effective vl
    input  wire [31:0]  q_vstart,    // effective vstart
    input  wire [31:0]  q_rs1,       // forwarded scalar rs1 (OPIVX)
    output wire         q_illegal,
    output wire         q_scalar_we, // vmv.x.s -> scalar rd
    output wire [31:0]  q_scalar,
    output wire         q_vrf_we,    // vd gets written at commit
    output wire [4:0]   q_vd,
    output wire [127:0] q_wdata,

    // ---- WB-stage commit write port (driven by core.v) ----
    input  wire         w_en,
    input  wire [4:0]   w_vd,
    input  wire [127:0] w_data
);
    // ---------------- decode ----------------
    wire [2:0] f3    = q_instr[14:12];
    wire [5:0] f6    = q_instr[31:26];
    wire       vm    = q_instr[25];
    wire [4:0] vs2_i = q_instr[24:20];
    wire [4:0] vs1_i = q_instr[19:15];
    wire [4:0] vd_i  = q_instr[11:7];

    wire is_opivv = (f3 == 3'b000);
    wire is_opivi = (f3 == 3'b011);
    wire is_opivx = (f3 == 3'b100);
    wire is_opmvv = (f3 == 3'b010);

    wire op_add   = (f6 == 6'b000000) && (is_opivv || is_opivx || is_opivi);
    wire op_sub   = (f6 == 6'b000010) && (is_opivv || is_opivx);
    wire f6_merge = (f6 == 6'b010111) && (is_opivv || is_opivx || is_opivi);
    wire op_mv    = f6_merge && vm;              // vmv.v.* (vs2 field must be 0)
    wire op_merge = f6_merge && !vm;             // vmerge.v*m (mask = v0)
    wire op_mvxs  = is_opmvv && (f6 == 6'b010000) && (vs1_i == 5'd0) && vm;

    // ---------------- config legality ----------------
    wire        vill  = q_vtype[31];
    wire [2:0]  vlmul = q_vtype[2:0];
    wire [2:0]  vsew  = q_vtype[5:3];
    wire lmul_gt1  = (vlmul == 3'b001) || (vlmul == 3'b010) || (vlmul == 3'b011);
    wire cfg_illegal = vill || lmul_gt1;         // m2/m4/m8 = 3B deferral

    wire known_op = op_add || op_sub || op_mv || op_merge || op_mvxs;
    // vstart!=0 on arithmetic = illegal (spec-allowed choice; MATCHES SPIKE —
    // caught by gate_42 lockstep: Spike trapped where the RTL executed).
    // Vector loads/stores in 3C will honor vstart instead (they are resumable).
    assign q_illegal = q_valid && ((EN_RVV == 0) || !known_op || cfg_illegal ||
                                   (q_vstart != 32'h0) ||
                                   ((op_add || op_sub) && !vm) ||   // masked add/sub = 3B deferral
                                   (op_mv && (vs2_i != 5'd0)) ||
                                   (op_merge && (vd_i == 5'd0)));

    // ---------------- VRF ----------------
    reg [127:0] vrf [0:31];
    wire [127:0] vs1_data = vrf[vs1_i];
    wire [127:0] vs2_data = vrf[vs2_i];
    wire [127:0] v0_data  = vrf[0];
    wire [127:0] vd_old   = vrf[vd_i];

    always @(posedge clk) begin
        if (w_en) vrf[w_vd] <= w_data;
    end

    // ---------------- operand B (vector / scalar / imm broadcast) ----------------
    wire [31:0] imm_sext = {{27{q_instr[19]}}, q_instr[19:15]};
    wire [31:0] scalar_b = is_opivi ? imm_sext : q_rs1;

    // ---------------- per-SEW element datapaths ----------------
    genvar gi;
    wire [127:0] res8, res16, res32;

    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : g_sew8
            wire [7:0] a = vs2_data[gi*8 +: 8];
            wire [7:0] b = is_opivv ? vs1_data[gi*8 +: 8] : scalar_b[7:0];
            wire       m = v0_data[gi];
            wire [7:0] r = op_add   ? (a + b) :
                           op_sub   ? (a - b) :
                           op_merge ? (m ? b : a) :
                                      b;                   // vmv.v.*
            wire active = (gi >= q_vstart) && (gi < q_vl);
            assign res8[gi*8 +: 8] = active ? r : vd_old[gi*8 +: 8];
        end
        for (gi = 0; gi < 8; gi = gi + 1) begin : g_sew16
            wire [15:0] a = vs2_data[gi*16 +: 16];
            wire [15:0] b = is_opivv ? vs1_data[gi*16 +: 16] : scalar_b[15:0];
            wire        m = v0_data[gi];
            wire [15:0] r = op_add   ? (a + b) :
                            op_sub   ? (a - b) :
                            op_merge ? (m ? b : a) :
                                       b;
            wire active = (gi >= q_vstart) && (gi < q_vl);
            assign res16[gi*16 +: 16] = active ? r : vd_old[gi*16 +: 16];
        end
        for (gi = 0; gi < 4; gi = gi + 1) begin : g_sew32
            wire [31:0] a = vs2_data[gi*32 +: 32];
            wire [31:0] b = is_opivv ? vs1_data[gi*32 +: 32] : scalar_b;
            wire        m = v0_data[gi];
            wire [31:0] r = op_add   ? (a + b) :
                            op_sub   ? (a - b) :
                            op_merge ? (m ? b : a) :
                                       b;
            wire active = (gi >= q_vstart) && (gi < q_vl);
            assign res32[gi*32 +: 32] = active ? r : vd_old[gi*32 +: 32];
        end
    endgenerate

    assign q_wdata = (vsew == 3'b000) ? res8 :
                     (vsew == 3'b001) ? res16 : res32;
    assign q_vd    = vd_i;
    // whole-instruction no-op when vstart>=vl (includes vl==0); vmv.x.s never writes
    assign q_vrf_we = q_valid && !q_illegal && !op_mvxs && (q_vstart < q_vl);

    // ---------------- vmv.x.s (executes even when vl==0) ----------------
    wire [7:0]  e0_8  = vs2_data[7:0];
    wire [15:0] e0_16 = vs2_data[15:0];
    assign q_scalar = (vsew == 3'b000) ? {{24{e0_8[7]}},  e0_8} :
                      (vsew == 3'b001) ? {{16{e0_16[15]}}, e0_16} :
                                         vs2_data[31:0];
    assign q_scalar_we = q_valid && !q_illegal && op_mvxs;

endmodule
`default_nettype wire
