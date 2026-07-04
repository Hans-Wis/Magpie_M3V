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
    input  wire         resetn,

    // ---- EX-stage combinational query ----
    input  wire         q_valid,
    input  wire [31:0]  q_instr,
    input  wire [31:0]  q_vtype,     // effective (forwarded) vtype
    input  wire [31:0]  q_vl,        // effective vl
    input  wire [31:0]  q_vstart,    // effective vstart
    input  wire [31:0]  q_rs1,       // forwarded scalar rs1 (OPIVX)
    output wire         q_is_grp,     // S3: multi-beat register-group op (hold like vmem)
    output wire         q_grp_w,      // S3: WB commit writes a register GROUP
    output wire [2:0]   q_grp_parts,  // S3: EMUL parts (2/4) piped for the WB commit
    input  wire         w_grp,        // S3: WB commit is a group write
    input  wire [2:0]   w_parts,
    input  wire [1:0]   q_vxrm,       // S2 (ADR-0049): effective vxrm at EX
    output wire         q_vxsat,      // S2: saturation occurred (active lanes)
    output wire         q_illegal,
    output wire         q_scalar_we, // vmv.x.s -> scalar rd
    output wire [31:0]  q_scalar,
    output wire         q_vrf_we,    // vd gets written at commit
    output wire [4:0]   q_vd,
    output wire [127:0] q_wdata,

    // ---- WB-stage commit write port (driven by core.v) ----
    input  wire         w_en,
    input  wire [4:0]   w_vd,
    input  wire [127:0] w_data,

    // ---- 3C unit-stride memory FSM (assemble buffer lives HERE, MEM-side;
    //      the VRF is only written at WB commit like every other vector op).
    //      core.v starts the FSM only when the pipeline behind is DRAINED
    //      (EX/MEM and EX/WB empty), so a mid-op flush/IRQ is impossible by
    //      construction and store beats are never wrong-path. ----
    input  wire         m_start,       // accepted only in IDLE
    input  wire         m_stall,       // core mem_stall freeze (ADR-0005 wrapper)
    input  wire         m_flush,       // pc_redirect/debug (defensive; unreachable mid-op)
    input  wire         m_advance,     // instruction left EX (clear result_valid)
    input  wire [31:0]  m_rdata,       // core d_mem_rdata (wrapper d_rdata_q)
    output wire         q_is_mem,
    output wire         vm_active,
    output wire         vm_result_valid,
    output wire         vm_dvalid,
    output wire         vm_we,
    output wire [31:0]  vm_addr,
    output wire [31:0]  vm_wdata,
    output wire [3:0]   vm_wstrb
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

    wire is_opmvx = (f3 == 3'b110);

    wire op_add   = (f6 == 6'b000000) && (is_opivv || is_opivx || is_opivi);
    wire op_sub   = (f6 == 6'b000010) && (is_opivv || is_opivx);
    wire f6_merge = (f6 == 6'b010111) && (is_opivv || is_opivx || is_opivi);
    wire op_mv    = f6_merge && vm;              // vmv.v.* (vs2 field must be 0)
    wire op_merge = f6_merge && !vm;             // vmerge.v*m (mask = v0)
    wire op_mvxs  = is_opmvv && (f6 == 6'b010000) && (vs1_i == 5'd0) && vm;
    // ---- 3D (the Phase 0 kernel set) ----
    wire op_wmul  = is_opmvv && (f6 == 6'b111011) && vm;   // vwmul.vv  (s*s -> 2*SEW)
    wire op_waddw = is_opmvv && (f6 == 6'b110101) && vm;   // vwadd.wv  (wide vs2 + narrow vs1)
    wire op_redsum= is_opmvv && (f6 == 6'b000000) && vm;   // vredsum.vs (vd[0]=vs1[0]+sum vs2)
    wire op_mvsx  = is_opmvx && (f6 == 6'b010000) && (vs2_i == 5'd0) && vm; // vmv.s.x
    wire op_widen = op_wmul || op_waddw;

    // ---------------- S1 (ADR-0049): min/max, compares, mask logicals ----------------
    wire op_minu  = (f6 == 6'b000100) && (is_opivv || is_opivx);
    wire op_min   = (f6 == 6'b000101) && (is_opivv || is_opivx);
    wire op_maxu  = (f6 == 6'b000110) && (is_opivv || is_opivx);
    wire op_max   = (f6 == 6'b000111) && (is_opivv || is_opivx);
    wire op_mm    = op_minu || op_min || op_maxu || op_max;

    // integer compares -> ONE BIT per element into a mask register
    wire f6_cmp   = (f6[5:3] == 3'b011) && (is_opivv || is_opivx || is_opivi);
    wire cmp_form_ok =
        (f6[2:0] == 3'b000 || f6[2:0] == 3'b001) ? 1'b1 :                 // vmseq/vmsne
        (f6[2:0] == 3'b010 || f6[2:0] == 3'b011) ? (is_opivv || is_opivx) : // vmslt[u]
        (f6[2:0] == 3'b100 || f6[2:0] == 3'b101) ? 1'b1 :                 // vmsle[u]
                                                   (is_opivx || is_opivi); // vmsgt[u]
    wire op_cmp   = f6_cmp && cmp_form_ok;

    // mask-register logicals (bits 0..vl-1); vm bit is 1 in the encoding
    wire op_mlog  = is_opmvv && (f6[5:3] == 3'b011) && vm;

    // ---------------- S2 (ADR-0049): saturating / averaging / scaling ----------------
    wire op_saddu  = (f6 == 6'b100000) && (is_opivv || is_opivx || is_opivi);
    wire op_sadd   = (f6 == 6'b100001) && (is_opivv || is_opivx || is_opivi);
    wire op_ssubu  = (f6 == 6'b100010) && (is_opivv || is_opivx);
    wire op_ssub   = (f6 == 6'b100011) && (is_opivv || is_opivx);
    wire op_avg    = (is_opmvv || is_opmvx) && (f6[5:2] == 4'b0010);  // vaadd[u]/vasub[u]
    wire avg_sub   = f6[1];                     // 001010/001011 = vasub[u]
    wire avg_signed= f6[0];                     // 001001/001011 = signed
    wire op_ssrl   = (f6 == 6'b101010) && (is_opivv || is_opivx || is_opivi);
    wire op_ssra   = (f6 == 6'b101011) && (is_opivv || is_opivx || is_opivi);
    wire op_nclipu = (f6 == 6'b101110) && (is_opivv || is_opivx || is_opivi);
    wire op_nclip  = (f6 == 6'b101111) && (is_opivv || is_opivx || is_opivi);
    wire op_s2same = op_saddu || op_sadd || op_ssubu || op_ssub ||
                     op_avg || op_ssrl || op_ssra;
    wire op_nc     = op_nclipu || op_nclip;

    // ---------------- config legality ----------------
    wire        vill  = q_vtype[31];
    wire [2:0]  vlmul = q_vtype[2:0];
    wire [2:0]  vsew  = q_vtype[5:3];
    // S3 (ADR-0049): m2/m4 register groups execute as internal multi-beat with
    // an atomic group commit at WB; m8 stays deferred-illegal.
    wire lmul_m2   = (vlmul == 3'b001);
    wire lmul_m4   = (vlmul == 3'b010);
    wire lmul_m8   = (vlmul == 3'b011);
    wire [2:0] grp_parts = lmul_m4 ? 3'd4 : lmul_m2 ? 3'd2 : 3'd1;
    wire cfg_illegal = vill || lmul_m8;

    // ---------------- 3C unit-stride vector load/store decode ----------------
    wire is_vload  = (q_instr[6:0] == 7'b0000111);   // LOAD-FP opcode space
    wire is_vstore = (q_instr[6:0] == 7'b0100111);   // STORE-FP opcode space
    wire is_vmem   = (EN_RVV != 0) && (is_vload || is_vstore);
    assign q_is_mem = q_valid && is_vmem;
    assign q_is_grp = q_valid && is_grp && !q_illegal;    // hold/beats (incl. cmp)
    // WB group WRITE excludes mask-dest compares (single-register dest)
    assign q_grp_w  = q_valid && is_grp && !op_cmp && !q_illegal;
    assign q_grp_parts = grp_parts;
    // width field: 000=EEW8, 101=EEW16, 110=EEW32 (010 = scalar FLW/FSW: no F -> illegal)
    wire [1:0] eew_sel = (f3 == 3'b000) ? 2'd0 :
                         (f3 == 3'b101) ? 2'd1 :
                         (f3 == 3'b110) ? 2'd2 : 2'd3;
    wire mem_enc_ok = (eew_sel != 2'd3) && vm &&              // unmasked unit-stride only
                      (q_instr[28:26] == 3'b000) &&           // mew=0, mop=00 (unit-stride)
                      (q_instr[24:20] == 5'b00000) &&         // lumop/sumop = 0
                      (q_instr[31:29] == 3'b000);             // nf=0 (no segments)
    // EMUL = (EEW/SEW)*LMUL must be <= 1 here <=> vlmax elements * EEW bytes <= 16
    wire [2:0] frac_sh  = (vlmul == 3'b111) ? 3'd1 :
                          (vlmul == 3'b110) ? 3'd2 :
                          (vlmul == 3'b101) ? 3'd3 : 3'd0;
    // S3: integer LMUL multiplies vlmax — EMUL = EEW/SEW*LMUL must stay <= 1
    // (group-EMUL memory ops remain out of scope; the m2/m4 configs where the
    // EEW is narrow enough, e.g. vle8 at e16/m2, stay legal)
    wire [1:0] int_sh   = lmul_m4 ? 2'd2 : lmul_m2 ? 2'd1 : 2'd0;
    wire [6:0] vlmax_el = ({2'b0, 5'd16 >> vsew} << int_sh) >> frac_sh;
    wire [8:0] mem_span = {2'b0, vlmax_el} << eew_sel;        // bytes touched at vlmax
    wire emul_ok  = (mem_span <= 9'd16);
    // element alignment: base aligned to EEW => every element aligned (unit stride)
    wire align_ok = (eew_sel == 2'd0) ||
                    ((eew_sel == 2'd1) && !q_rs1[0]) ||
                    ((eew_sel == 2'd2) && (q_rs1[1:0] == 2'b00));
    wire mem_illegal = !mem_enc_ok || !emul_ok || !align_ok;

    // 3D widening legality: dst EEW = 2*SEW needs SEW<=16 and dst EMUL = 2*LMUL
    // <= 1 (single register group) => LMUL must be fractional. Overlap (match
    // Spike require_noover): a widening dest may not overlap a NARROWER source;
    // vwadd.wv vd==vs2 is legal (same EEW — the kernel's accumulate uses it).
    wire widen_lmul_ok = (vlmul == 3'b111) || (vlmul == 3'b110) || (vlmul == 3'b101);
    wire widen_illegal = op_widen &&
                         (!widen_lmul_ok || (vsew == 3'b010) ||
                          (vd_i == vs1_i) ||
                          (op_wmul && (vd_i == vs2_i)));

    wire known_op = op_add || op_sub || op_mv || op_merge || op_mvxs ||
                    op_wmul || op_waddw || op_redsum || op_mvsx ||
                    op_mm || op_cmp || op_mlog || op_s2same || op_nc;
    // ops that iterate register-group parts (compares read groups, write ONE
    // mask register); widening/narrowing/reductions stay <= m1 (their own
    // LMUL rules) and vmv.x.s/vmv.s.x touch element 0 only.
    wire beats_op  = op_add || op_sub || op_mv || op_merge || op_mm ||
                     op_s2same || op_cmp;
    // NOTE: memory opcodes alias the f6-based arith decodes (every other use
    // site is guarded by an is_vmem priority mux) — exclude them here too.
    wire is_grp    = (grp_parts != 3'd1) && beats_op && !is_vmem;
    wire grp_only_illegal = (grp_parts != 3'd1) &&
        (op_widen || op_redsum || op_nc ||
         !beats_op && !op_mvxs && !op_mvsx && !op_mlog && !is_vmem);
    // register-group alignment (vd for writes except mask-dest; sources)
    wire [4:0] grp_amask = lmul_m4 ? 5'd3 : lmul_m2 ? 5'd1 : 5'd0;
    wire grp_align_illegal = is_grp &&
        ((!op_cmp && ((vd_i & grp_amask[4:0]) != 5'd0)) ||
         ((vs2_i & grp_amask) != 5'd0) ||
         // .vv source includes OPMVV vector-vector forms (vaadd family) —
         // Codex S3 finding: is_opivv alone missed them
         ((is_opivv || is_opmvv) && ((vs1_i & grp_amask) != 5'd0)));
    // narrowing legality mirrors widening (source EMUL = 2*LMUL <= 1); the
    // low-part destination overlap (vd == vs2) is spec-legal for narrowing.
    wire nc_illegal = op_nc && (!widen_lmul_ok || (vsew == 3'b010));
    // vstart!=0 on arithmetic = illegal (spec-allowed choice; MATCHES SPIKE —
    // caught by gate_42 lockstep: Spike trapped where the RTL executed).
    // Loads/stores are resumable: vstart is honored (start element), not illegal.
    assign q_illegal = q_valid && ((EN_RVV == 0) || cfg_illegal ||
                       (is_vmem ? mem_illegal :
                        (!known_op ||
                         (q_vstart != 32'h0) ||
                         widen_illegal ||
                         (op_mv && (vs2_i != 5'd0)) ||
                         (op_merge && (vd_i == 5'd0)) ||
                         // S1 (Codex, Spike-confirmed): a MASKED body op may not
                         // write v0 (dest overlaps the mask); mask-DEST compares
                         // targeting v0 remain legal.
                         nc_illegal || grp_only_illegal || grp_align_illegal ||
                         ((op_add || op_sub || op_mm || op_s2same || op_nc) &&
                          !vm && (vd_i == 5'd0)))));

    // ---------------- VRF ----------------
    reg [127:0] vrf [0:31];
    // S3: during group beats the datapath sees part p of each operand; the
    // element window and v0 mask bits shift by the part base. m1 ops see p=0.
    reg  [1:0]   grp_p;
    wire [4:0]   part_off = {3'b0, grp_p};
    wire [127:0] vs1_data = vrf[vs1_i + part_off];
    wire [127:0] vs2_data = vrf[vs2_i + part_off];
    wire [127:0] v0_data  = vrf[0];
    wire [127:0] vd_old   = vrf[vd_i + part_off];
    // elements per register at the current SEW; part base in ELEMENTS
    wire [5:0]  nl_el     = (vsew == 3'b000) ? 6'd16 : (vsew == 3'b001) ? 6'd8 : 6'd4;
    wire [7:0]  elem_base = {2'b0, nl_el} * {6'b0, grp_p};
    // per-lane views: lane gi maps to architectural element (elem_base + gi)
    wire [127:0] v0_view   = v0_data >> elem_base;
    wire [31:0]  vl_view   = (q_vl > {24'b0, elem_base}) ? (q_vl - {24'b0, elem_base}) : 32'h0;
    wire [31:0]  vst_view  = (q_vstart > {24'b0, elem_base}) ? (q_vstart - {24'b0, elem_base}) : 32'h0;

    wire [127:0] cmpd_old  = vrf[vd_i];          // mask-dest reads its own reg
    wire [127:0] cmpd_view = cmpd_old >> elem_base;

    // S3 staging: computed parts await the atomic group commit at WB
    reg [127:0] grp_stage [0:3];
    reg [127:0] grp_mask_acc;      // compare-to-mask accumulation across parts
    reg         grp_sat_q;

    always @(posedge clk) begin
        if (w_en) begin
            vrf[w_vd] <= w_data;
            // atomic group commit: parts 1..N-1 from staging (part 0 rides the
            // pipeline as the architectural value; drained-start guarantees
            // staging still belongs to this instruction)
            if (w_grp) begin
                vrf[w_vd + 5'd1] <= grp_stage[1];
                if (w_parts == 3'd4) begin
                    vrf[w_vd + 5'd2] <= grp_stage[2];
                    vrf[w_vd + 5'd3] <= grp_stage[3];
                end
            end
        end
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
            wire       m = v0_view[gi];
            wire signed [7:0] as = a, bs = b;
            wire [7:0] r = op_add   ? (a + b) :
                           op_sub   ? (a - b) :
                           op_min   ? ((as < bs) ? a : b) :
                           op_minu  ? ((a < b)  ? a : b) :
                           op_max   ? ((as > bs) ? a : b) :
                           op_maxu  ? ((a > b)  ? a : b) :
                           op_merge ? (m ? b : a) :
                                      b;                   // vmv.v.*
            wire active = (gi >= vst_view) && (gi < vl_view) &&
                          (op_merge || vm || m);           // S1: masked-off = undisturbed
            assign res8[gi*8 +: 8] = active ? r : vd_old[gi*8 +: 8];
        end
        for (gi = 0; gi < 8; gi = gi + 1) begin : g_sew16
            wire [15:0] a = vs2_data[gi*16 +: 16];
            wire [15:0] b = is_opivv ? vs1_data[gi*16 +: 16] : scalar_b[15:0];
            wire        m = v0_view[gi];
            wire signed [15:0] as = a, bs = b;
            wire [15:0] r = op_add   ? (a + b) :
                            op_sub   ? (a - b) :
                            op_min   ? ((as < bs) ? a : b) :
                            op_minu  ? ((a < b)  ? a : b) :
                            op_max   ? ((as > bs) ? a : b) :
                            op_maxu  ? ((a > b)  ? a : b) :
                            op_merge ? (m ? b : a) :
                                       b;
            wire active = (gi >= vst_view) && (gi < vl_view) &&
                          (op_merge || vm || m);
            assign res16[gi*16 +: 16] = active ? r : vd_old[gi*16 +: 16];
        end
        for (gi = 0; gi < 4; gi = gi + 1) begin : g_sew32
            wire [31:0] a = vs2_data[gi*32 +: 32];
            wire [31:0] b = is_opivv ? vs1_data[gi*32 +: 32] : scalar_b;
            wire        m = v0_view[gi];
            wire signed [31:0] as = a, bs = b;
            wire [31:0] r = op_add   ? (a + b) :
                            op_sub   ? (a - b) :
                            op_min   ? ((as < bs) ? a : b) :
                            op_minu  ? ((a < b)  ? a : b) :
                            op_max   ? ((as > bs) ? a : b) :
                            op_maxu  ? ((a > b)  ? a : b) :
                            op_merge ? (m ? b : a) :
                                       b;
            wire active = (gi >= vst_view) && (gi < vl_view) &&
                          (op_merge || vm || m);
            assign res32[gi*32 +: 32] = active ? r : vd_old[gi*32 +: 32];
        end

        // ---- S1: compares -> mask bits (per SEW element count) ----
        for (gi = 0; gi < 16; gi = gi + 1) begin : g_cmp8
            wire [7:0] a = vs2_data[gi*8 +: 8];
            wire [7:0] b = is_opivv ? vs1_data[gi*8 +: 8] : scalar_b[7:0];
            wire signed [7:0] as = a, bs = b;
            wire c = (f6[2:0] == 3'b000) ? (a == b)  :
                     (f6[2:0] == 3'b001) ? (a != b)  :
                     (f6[2:0] == 3'b010) ? (a < b)   :
                     (f6[2:0] == 3'b011) ? (as < bs) :
                     (f6[2:0] == 3'b100) ? (a <= b)  :
                     (f6[2:0] == 3'b101) ? (as <= bs):
                     (f6[2:0] == 3'b110) ? (a > b)   :
                                           (as > bs);
            wire en = (gi < vl_view) && (vm || v0_view[gi]);
            assign cmp_bits8[gi] = en ? c : cmpd_view[gi];
        end
        for (gi = 0; gi < 8; gi = gi + 1) begin : g_cmp16
            wire [15:0] a = vs2_data[gi*16 +: 16];
            wire [15:0] b = is_opivv ? vs1_data[gi*16 +: 16] : scalar_b[15:0];
            wire signed [15:0] as = a, bs = b;
            wire c = (f6[2:0] == 3'b000) ? (a == b)  :
                     (f6[2:0] == 3'b001) ? (a != b)  :
                     (f6[2:0] == 3'b010) ? (a < b)   :
                     (f6[2:0] == 3'b011) ? (as < bs) :
                     (f6[2:0] == 3'b100) ? (a <= b)  :
                     (f6[2:0] == 3'b101) ? (as <= bs):
                     (f6[2:0] == 3'b110) ? (a > b)   :
                                           (as > bs);
            wire en = (gi < vl_view) && (vm || v0_view[gi]);
            assign cmp_bits16[gi] = en ? c : cmpd_view[gi];
        end
        for (gi = 0; gi < 4; gi = gi + 1) begin : g_cmp32
            wire [31:0] a = vs2_data[gi*32 +: 32];
            wire [31:0] b = is_opivv ? vs1_data[gi*32 +: 32] : scalar_b;
            wire signed [31:0] as = a, bs = b;
            wire c = (f6[2:0] == 3'b000) ? (a == b)  :
                     (f6[2:0] == 3'b001) ? (a != b)  :
                     (f6[2:0] == 3'b010) ? (a < b)   :
                     (f6[2:0] == 3'b011) ? (as < bs) :
                     (f6[2:0] == 3'b100) ? (a <= b)  :
                     (f6[2:0] == 3'b101) ? (as <= bs):
                     (f6[2:0] == 3'b110) ? (a > b)   :
                                           (as > bs);
            wire en = (gi < vl_view) && (vm || v0_view[gi]);
            assign cmp_bits32[gi] = en ? c : cmpd_view[gi];
        end
    endgenerate

    // ---------------- 3C memory FSM (2 cycles/element: ISSUE -> CAP) ----------------
    localparam [1:0] VM_IDLE = 2'd0, VM_ISSUE = 2'd1, VM_CAP = 2'd2, VM_GRP = 2'd3;
    reg [1:0]   vm_state;
    reg [4:0]   vm_idx;
    reg [127:0] vm_buf;          // assemble buffer (loads); seeded with vd_old
    reg         vm_done_r;

    wire [4:0] vm_vl     = q_vl[4:0];       // <=16 elements under EMUL<=1
    wire [4:0] vm_vstart = q_vstart[4:0];
    wire       vm_none   = (q_vstart >= q_vl);
    wire [4:0] vm_last   = vm_vl - 5'd1;

    assign vm_active       = (vm_state != VM_IDLE);
    assign vm_result_valid = vm_done_r;
    assign vm_dvalid       = (vm_state == VM_ISSUE);
    assign vm_we           = is_vstore;
    assign vm_addr         = q_rs1 + ({27'b0, vm_idx} << eew_sel);
    // store element from vs3 (= vd field) placed on its byte lane via wstrb
    wire [7:0]  st8  = vd_old[{vm_idx[3:0], 3'b000} +: 8];
    wire [15:0] st16 = vd_old[{vm_idx[2:0], 4'b0000} +: 16];
    wire [31:0] st32 = vd_old[{vm_idx[1:0], 5'b00000} +: 32];
    assign vm_wdata = (eew_sel == 2'd0) ? {4{st8}} :
                      (eew_sel == 2'd1) ? {2{st16}} : st32;
    assign vm_wstrb = (eew_sel == 2'd0) ? (4'b0001 << vm_addr[1:0]) :
                      (eew_sel == 2'd1) ? (vm_addr[1] ? 4'b1100 : 4'b0011) : 4'b1111;
    // load lane extract for the beat just captured (idx unchanged ISSUE->CAP)
    wire [7:0]  ld8  = m_rdata[{vm_addr[1:0], 3'b000} +: 8];
    wire [15:0] ld16 = vm_addr[1] ? m_rdata[31:16] : m_rdata[15:0];

    always @(posedge clk) begin
        if (!resetn || m_flush) begin
            vm_state  <= VM_IDLE;
            vm_done_r <= 1'b0;
            grp_p     <= 2'd0;
        end else if (m_advance && vm_done_r) begin
            vm_done_r <= 1'b0;                       // instruction left EX
        end else if (!m_stall) begin
            case (vm_state)
                VM_IDLE: if (m_start && !vm_done_r) begin
                    if (is_grp) begin
                        // S3: register-group beats — one part per cycle into
                        // staging; drained-start means nothing else vector is
                        // in flight until the WB group commit.
                        if (vm_none) begin
                            vm_done_r <= 1'b1;
                        end else begin
                            grp_p     <= 2'd0;
                            grp_sat_q <= 1'b0;
                            vm_state  <= VM_GRP;
                        end
                    end else if (vm_none) begin
                        vm_done_r <= 1'b1;           // vl==0 / vstart>=vl: no beats
                    end else begin
                        vm_buf   <= vd_old;          // undisturbed below-vstart + tail
                        vm_idx   <= vm_vstart;
                        vm_state <= VM_ISSUE;
                    end
                end

                VM_GRP: begin
                    grp_stage[grp_p] <= part_res;
                    grp_sat_q <= grp_sat_q | part_sat_or;
                    if (op_cmp)
                        grp_mask_acc <= (grp_mask_acc & ~(mask_nl << elem_base)) |
                                        ({112'b0, cmp_seg} << elem_base);
                    if ({1'b0, grp_p} + 3'd1 == grp_parts) begin
                        grp_p     <= 2'd0;
                        vm_state  <= VM_IDLE;
                        vm_done_r <= 1'b1;
                    end else
                        grp_p <= grp_p + 2'd1;
                end
                VM_ISSUE: vm_state <= VM_CAP;        // beat fired this cycle
                VM_CAP: begin
                    if (is_vload) begin
                        case (eew_sel)
                            2'd0: vm_buf[{vm_idx[3:0], 3'b000} +: 8]       <= ld8;
                            2'd1: vm_buf[{vm_idx[2:0], 4'b0000} +: 16]     <= ld16;
                            default: vm_buf[{vm_idx[1:0], 5'b00000} +: 32] <= m_rdata;
                        endcase
                    end
                    if (vm_idx == vm_last) begin
                        vm_state  <= VM_IDLE;
                        vm_done_r <= 1'b1;
                    end else begin
                        vm_idx   <= vm_idx + 5'd1;
                        vm_state <= VM_ISSUE;
                    end
                end
                default: vm_state <= VM_IDLE;
            endcase
        end
    end

    // ---------------- 3D widening datapaths (dst lanes are 2*SEW wide) ----------------
    // SEW=8 -> 8 x 16-bit dst lanes; SEW=16 -> 4 x 32-bit dst lanes. Active dst
    // lane i covers element i (i < vl); tail lanes undisturbed.
    wire [127:0] res_w8, res_w16;
    generate
        for (gi = 0; gi < 8; gi = gi + 1) begin : g_w8
            wire signed [7:0]  a = vs2_data[gi*8 +: 8];    // narrow src (wmul)
            wire signed [7:0]  n = vs1_data[gi*8 +: 8];    // narrow src (both)
            wire signed [15:0] w = vs2_data[gi*16 +: 16];  // wide src (wadd.wv)
            // keep each result in an ALL-SIGNED expression (a conditional with an
            // unsigned concat branch silently zero-extends: caught by lockstep)
            wire signed [15:0] prod = a * n;
            wire signed [15:0] wsum = w + {{8{n[7]}}, n};   // equal-width add: bit-exact, no implicit expand
            wire        [15:0] r    = op_wmul ? prod : wsum;
            wire active = (gi < q_vl);
            assign res_w8[gi*16 +: 16] = active ? r : vd_old[gi*16 +: 16];
        end
        for (gi = 0; gi < 4; gi = gi + 1) begin : g_w16
            wire signed [15:0] a = vs2_data[gi*16 +: 16];
            wire signed [15:0] n = vs1_data[gi*16 +: 16];
            wire signed [31:0] w = vs2_data[gi*32 +: 32];
            wire signed [31:0] prod = a * n;
            wire signed [31:0] wsum = w + {{16{n[15]}}, n};
            wire        [31:0] r    = op_wmul ? prod : wsum;
            wire active = (gi < q_vl);
            assign res_w16[gi*32 +: 32] = active ? r : vd_old[gi*32 +: 32];
        end
    endgenerate

    // ---------------- 3D vredsum.vs (vd[0] = vs1[0] + sum of active vs2) ----------------
    reg [31:0] red_sum;
    integer rk;
    always @* begin
        red_sum = (vsew == 3'b000) ? {24'b0, vs1_data[7:0]} :
                  (vsew == 3'b001) ? {16'b0, vs1_data[15:0]} : vs1_data[31:0];
        for (rk = 0; rk < 16; rk = rk + 1) begin
            if (rk < q_vl) begin
                case (vsew)
                    3'b000:  red_sum = red_sum + {24'b0, vs2_data[(rk%16)*8 +: 8]};
                    3'b001:  if (rk < 8) red_sum = red_sum + {16'b0, vs2_data[(rk%8)*16 +: 16]};
                    default: if (rk < 4) red_sum = red_sum + vs2_data[(rk%4)*32 +: 32];
                endcase
            end
        end
    end
    wire [127:0] res_red = (vsew == 3'b000) ? {vd_old[127:8],  red_sum[7:0]} :
                           (vsew == 3'b001) ? {vd_old[127:16], red_sum[15:0]} :
                                              {vd_old[127:32], red_sum[31:0]};
    // vmv.s.x: element 0 = x[rs1] truncated to SEW; tail undisturbed
    wire [127:0] res_sx = (vsew == 3'b000) ? {vd_old[127:8],  q_rs1[7:0]} :
                          (vsew == 3'b001) ? {vd_old[127:16], q_rs1[15:0]} :
                                             {vd_old[127:32], q_rs1[31:0]};

    // ---------------- S2 datapaths (sat / avg / scaling shift / nclip) --------
    // Rounding increment per vxrm (d = shift amount, x = raw bits):
    //   rnu: x[d-1] | rne: x[d-1] & (x[d-2:0]!=0 | x[d]) | rdn: 0
    //   rod: !x[d] & (x[d-1:0]!=0)
    wire [15:0] s2_sat8, s2_sat16_x;  // per-lane sat flags (padded)
    wire [3:0]  s2_sat32;
    wire [7:0]  nc_sat8;
    wire [3:0]  nc_sat16;
    wire [127:0] res_s2_8, res_s2_16, res_s2_32, res_nc8, res_nc16;

    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : g_s2_8
            wire [7:0] a = vs2_data[gi*8 +: 8];
            wire [7:0] b = (is_opivv || is_opmvv) ? vs1_data[gi*8 +: 8] : scalar_b[7:0];
            wire signed [8:0] sxs = {a[7], a} + {b[7], b};
            wire signed [8:0] sxd = {a[7], a} - {b[7], b};
            wire        [8:0] uxs = {1'b0, a} + {1'b0, b};
            wire        [8:0] uxd = {1'b0, a} - {1'b0, b};
            // signed sat: top two bits differ
            wire ss_ov  = sxs[8] != sxs[7];
            wire sd_ov  = sxd[8] != sxd[7];
            wire [7:0] r_sadd  = ss_ov ? (sxs[8] ? 8'h80 : 8'h7F) : sxs[7:0];
            wire [7:0] r_ssub  = sd_ov ? (sxd[8] ? 8'h80 : 8'h7F) : sxd[7:0];
            wire [7:0] r_saddu = uxs[8] ? 8'hFF : uxs[7:0];
            wire [7:0] r_ssubu = uxd[8] ? 8'h00 : uxd[7:0];
            // averaging: (a +/- b) >> 1 with vxrm; signed uses arithmetic shift
            wire [8:0] avg_x   = avg_sub ? (avg_signed ? sxd[8:0] : uxd)
                                         : (avg_signed ? sxs[8:0] : uxs);
            wire avg_inc = (q_vxrm == 2'd0) ?  avg_x[0] :
                           (q_vxrm == 2'd1) ? (avg_x[0] & avg_x[1]) :
                           (q_vxrm == 2'd2) ?  1'b0 :
                                              (~avg_x[1] & avg_x[0]);
            wire [7:0] r_avg = avg_x[8:1] + {7'b0, avg_inc};   // (a±b)>>1, sign in bit 8
            // scaling shifts
            wire [2:0] d8 = b[2:0];
            wire [7:0] lowm = (8'h01 << d8) - 8'h1;          // bits below d (incl d-1)
            wire b_dm1 = (d8 != 3'd0) && (((a >> (d8 - 3'd1)) & 8'h1) != 8'h0);
            wire b_d   = ((a >> d8) & 8'h1) != 8'h0;
            wire lo_nz = (a & (lowm >> 1)) != 8'h0;
            wire any_lo= (a & lowm) != 8'h0;
            wire sh_inc = (q_vxrm == 2'd0) ? b_dm1 :
                          (q_vxrm == 2'd1) ? (b_dm1 & (lo_nz | b_d)) :
                          (q_vxrm == 2'd2) ? 1'b0 :
                                             (~b_d & any_lo);
            wire signed [7:0] as8 = a;
            wire [7:0] r_ssrl = (a >> d8) + {7'b0, sh_inc};
            wire [7:0] r_ssra = $unsigned(as8 >>> d8) + {7'b0, sh_inc};
            wire [7:0] r_s2 = op_sadd  ? r_sadd  :
                              op_saddu ? r_saddu :
                              op_ssub  ? r_ssub  :
                              op_ssubu ? r_ssubu :
                              op_avg   ? r_avg   :
                              op_ssrl  ? r_ssrl  : r_ssra;
            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
            assign res_s2_8[gi*8 +: 8] = en ? r_s2 : vd_old[gi*8 +: 8];
            assign s2_sat8[gi] = en && ((op_sadd && ss_ov) || (op_ssub && sd_ov) ||
                                        (op_saddu && uxs[8]) || (op_ssubu && uxd[8]));
        end

        for (gi = 0; gi < 8; gi = gi + 1) begin : g_s2_16
            wire [15:0] a = vs2_data[gi*16 +: 16];
            wire [15:0] b = (is_opivv || is_opmvv) ? vs1_data[gi*16 +: 16] : scalar_b[15:0];
            wire signed [16:0] sxs = {a[15], a} + {b[15], b};
            wire signed [16:0] sxd = {a[15], a} - {b[15], b};
            wire        [16:0] uxs = {1'b0, a} + {1'b0, b};
            wire        [16:0] uxd = {1'b0, a} - {1'b0, b};
            wire ss_ov  = sxs[16] != sxs[15];
            wire sd_ov  = sxd[16] != sxd[15];
            wire [15:0] r_sadd  = ss_ov ? (sxs[16] ? 16'h8000 : 16'h7FFF) : sxs[15:0];
            wire [15:0] r_ssub  = sd_ov ? (sxd[16] ? 16'h8000 : 16'h7FFF) : sxd[15:0];
            wire [15:0] r_saddu = uxs[16] ? 16'hFFFF : uxs[15:0];
            wire [15:0] r_ssubu = uxd[16] ? 16'h0000 : uxd[15:0];
            wire [16:0] avg_x   = avg_sub ? (avg_signed ? sxd[16:0] : uxd)
                                          : (avg_signed ? sxs[16:0] : uxs);
            wire avg_inc = (q_vxrm == 2'd0) ?  avg_x[0] :
                           (q_vxrm == 2'd1) ? (avg_x[0] & avg_x[1]) :
                           (q_vxrm == 2'd2) ?  1'b0 :
                                              (~avg_x[1] & avg_x[0]);
            wire [15:0] r_avg = avg_x[16:1] + {15'b0, avg_inc};
            wire [3:0] d16 = b[3:0];
            wire [15:0] lowm = (16'h0001 << d16) - 16'h1;
            wire b_dm1 = (d16 != 4'd0) && (((a >> (d16 - 4'd1)) & 16'h1) != 16'h0);
            wire b_d   = ((a >> d16) & 16'h1) != 16'h0;
            wire lo_nz = (a & (lowm >> 1)) != 16'h0;
            wire any_lo= (a & lowm) != 16'h0;
            wire sh_inc = (q_vxrm == 2'd0) ? b_dm1 :
                          (q_vxrm == 2'd1) ? (b_dm1 & (lo_nz | b_d)) :
                          (q_vxrm == 2'd2) ? 1'b0 :
                                             (~b_d & any_lo);
            wire signed [15:0] as16 = a;
            wire [15:0] r_ssrl = (a >> d16) + {15'b0, sh_inc};
            wire [15:0] r_ssra = $unsigned(as16 >>> d16) + {15'b0, sh_inc};
            wire [15:0] r_s2 = op_sadd  ? r_sadd  :
                               op_saddu ? r_saddu :
                               op_ssub  ? r_ssub  :
                               op_ssubu ? r_ssubu :
                               op_avg   ? r_avg   :
                               op_ssrl  ? r_ssrl  : r_ssra;
            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
            assign res_s2_16[gi*16 +: 16] = en ? r_s2 : vd_old[gi*16 +: 16];
            assign s2_sat16_x[gi] = en && ((op_sadd && ss_ov) || (op_ssub && sd_ov) ||
                                           (op_saddu && uxs[16]) || (op_ssubu && uxd[16]));
        end

        for (gi = 0; gi < 4; gi = gi + 1) begin : g_s2_32
            wire [31:0] a = vs2_data[gi*32 +: 32];
            wire [31:0] b = (is_opivv || is_opmvv) ? vs1_data[gi*32 +: 32] : scalar_b;
            wire signed [32:0] sxs = {a[31], a} + {b[31], b};
            wire signed [32:0] sxd = {a[31], a} - {b[31], b};
            wire        [32:0] uxs = {1'b0, a} + {1'b0, b};
            wire        [32:0] uxd = {1'b0, a} - {1'b0, b};
            wire ss_ov  = sxs[32] != sxs[31];
            wire sd_ov  = sxd[32] != sxd[31];
            wire [31:0] r_sadd  = ss_ov ? (sxs[32] ? 32'h8000_0000 : 32'h7FFF_FFFF) : sxs[31:0];
            wire [31:0] r_ssub  = sd_ov ? (sxd[32] ? 32'h8000_0000 : 32'h7FFF_FFFF) : sxd[31:0];
            wire [31:0] r_saddu = uxs[32] ? 32'hFFFF_FFFF : uxs[31:0];
            wire [31:0] r_ssubu = uxd[32] ? 32'h0 : uxd[31:0];
            wire [32:0] avg_x   = avg_sub ? (avg_signed ? sxd[32:0] : uxd)
                                          : (avg_signed ? sxs[32:0] : uxs);
            wire avg_inc = (q_vxrm == 2'd0) ?  avg_x[0] :
                           (q_vxrm == 2'd1) ? (avg_x[0] & avg_x[1]) :
                           (q_vxrm == 2'd2) ?  1'b0 :
                                              (~avg_x[1] & avg_x[0]);
            wire [31:0] r_avg = avg_x[32:1] + {31'b0, avg_inc};
            wire [4:0] d32 = b[4:0];
            wire [31:0] lowm = (32'h1 << d32) - 32'h1;
            wire b_dm1 = (d32 != 5'd0) && (((a >> (d32 - 5'd1)) & 32'h1) != 32'h0);
            wire b_d   = ((a >> d32) & 32'h1) != 32'h0;
            wire lo_nz = (a & (lowm >> 1)) != 32'h0;
            wire any_lo= (a & lowm) != 32'h0;
            wire sh_inc = (q_vxrm == 2'd0) ? b_dm1 :
                          (q_vxrm == 2'd1) ? (b_dm1 & (lo_nz | b_d)) :
                          (q_vxrm == 2'd2) ? 1'b0 :
                                             (~b_d & any_lo);
            wire signed [31:0] as32 = a;
            wire [31:0] r_ssrl = (a >> d32) + {31'b0, sh_inc};
            wire [31:0] r_ssra = $unsigned(as32 >>> d32) + {31'b0, sh_inc};
            wire [31:0] r_s2 = op_sadd  ? r_sadd  :
                               op_saddu ? r_saddu :
                               op_ssub  ? r_ssub  :
                               op_ssubu ? r_ssubu :
                               op_avg   ? r_avg   :
                               op_ssrl  ? r_ssrl  : r_ssra;
            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
            assign res_s2_32[gi*32 +: 32] = en ? r_s2 : vd_old[gi*32 +: 32];
            assign s2_sat32[gi] = en && ((op_sadd && ss_ov) || (op_ssub && sd_ov) ||
                                         (op_saddu && uxs[32]) || (op_ssubu && uxd[32]));
        end

        // ---- vnclip[u]: wide 2*SEW source -> SEW dest with round + clip ----
        for (gi = 0; gi < 8; gi = gi + 1) begin : g_nc8
            wire [15:0] v = vs2_data[gi*16 +: 16];             // wide lane
            wire [7:0]  b = is_opivv ? vs1_data[gi*8 +: 8] : scalar_b[7:0];
            wire [3:0]  d = b[3:0];                            // shamt & (2*SEW-1)
            wire [15:0] lowm = (16'h0001 << d) - 16'h1;
            wire b_dm1 = (d != 4'd0) && (((v >> (d - 4'd1)) & 16'h1) != 16'h0);
            wire b_d   = ((v >> d) & 16'h1) != 16'h0;
            wire lo_nz = (v & (lowm >> 1)) != 16'h0;
            wire any_lo= (v & lowm) != 16'h0;
            wire inc = (q_vxrm == 2'd0) ? b_dm1 :
                       (q_vxrm == 2'd1) ? (b_dm1 & (lo_nz | b_d)) :
                       (q_vxrm == 2'd2) ? 1'b0 :
                                          (~b_d & any_lo);
            wire signed [15:0] vs = v;
            wire signed [16:0] rs = {vs[15], $unsigned(vs >>> d)} + {16'b0, inc};
            wire        [16:0] ru = {1'b0, v >> d} + {16'b0, inc};
            wire s_ov = (rs > 17'sd127) || (rs < -17'sd128);
            wire u_ov = (ru > 17'd255);
            wire [7:0] r = op_nclip ? (s_ov ? (rs[16] ? 8'h80 : 8'h7F) : rs[7:0])
                                    : (u_ov ? 8'hFF : ru[7:0]);
            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
            assign res_nc8[gi*8 +: 8] = en ? r : vd_old[gi*8 +: 8];
            assign nc_sat8[gi] = en && (op_nclip ? s_ov : u_ov);
        end
        for (gi = 0; gi < 4; gi = gi + 1) begin : g_nc16
            wire [31:0] v = vs2_data[gi*32 +: 32];
            wire [15:0] b = is_opivv ? vs1_data[gi*16 +: 16] : scalar_b[15:0];
            wire [4:0]  d = b[4:0];
            wire [31:0] lowm = (32'h1 << d) - 32'h1;
            wire b_dm1 = (d != 5'd0) && (((v >> (d - 5'd1)) & 32'h1) != 32'h0);
            wire b_d   = ((v >> d) & 32'h1) != 32'h0;
            wire lo_nz = (v & (lowm >> 1)) != 32'h0;
            wire any_lo= (v & lowm) != 32'h0;
            wire inc = (q_vxrm == 2'd0) ? b_dm1 :
                       (q_vxrm == 2'd1) ? (b_dm1 & (lo_nz | b_d)) :
                       (q_vxrm == 2'd2) ? 1'b0 :
                                          (~b_d & any_lo);
            wire signed [31:0] vs = v;
            wire signed [32:0] rs = {vs[31], $unsigned(vs >>> d)} + {32'b0, inc};
            wire        [32:0] ru = {1'b0, v >> d} + {32'b0, inc};
            wire s_ov = (rs > 33'sd32767) || (rs < -33'sd32768);
            wire u_ov = (ru > 33'd65535);
            wire [15:0] r = op_nclip ? (s_ov ? (rs[32] ? 16'h8000 : 16'h7FFF) : rs[15:0])
                                     : (u_ov ? 16'hFFFF : ru[15:0]);
            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
            assign res_nc16[gi*16 +: 16] = en ? r : vd_old[gi*16 +: 16];
            assign nc_sat16[gi] = en && (op_nclip ? s_ov : u_ov);
        end
    endgenerate

    // narrowing writes at most 8 (SEW8) / 4 (SEW16) dst elements under the
    // fractional-LMUL rule -> the upper half of the dst register is tail
    assign res_nc8[127:64]  = vd_old[127:64];
    assign res_nc16[127:64] = vd_old[127:64];

    wire [127:0] res_s2 = (vsew == 3'b000) ? res_s2_8 :
                          (vsew == 3'b001) ? res_s2_16 : res_s2_32;
    wire [127:0] res_nc = (vsew == 3'b000) ? res_nc8 : res_nc16;
    wire part_sat_or = (op_s2same && ((vsew == 3'b000) ? (|s2_sat8) :
                                      (vsew == 3'b001) ? (|s2_sat16_x[7:0]) :
                                                         (|s2_sat32))) ||
                       (op_nc && ((vsew == 3'b000) ? (|nc_sat8) : (|nc_sat16)));
    assign q_vxsat = q_valid && !q_illegal && (q_vstart < q_vl) &&
                     (is_grp ? grp_sat_q : part_sat_or);

    // per-part combinational result for the group beats (arith class)
    wire [127:0] part_res = op_s2same ? res_s2 :
                            (vsew == 3'b000) ? res8 :
                            (vsew == 3'b001) ? res16 : res32;
    wire [15:0] cmp_seg  = (vsew == 3'b000) ? cmp_bits8 :
                           (vsew == 3'b001) ? {8'b0, cmp_bits16} :
                                              {12'b0, cmp_bits32};
    wire [127:0] mask_nl = (vsew == 3'b000) ? 128'hFFFF :
                           (vsew == 3'b001) ? 128'hFF : 128'hF;
    // group compare: bits < vl from the accumulator, tail from the dest reg
    wire [127:0] vl_ones  = (128'h1 << q_vl[6:0]) - 128'h1;
    wire [127:0] grp_cmp_res = (cmpd_old & ~vl_ones) | (grp_mask_acc & vl_ones);

    // ---- S1 result assembly: compares + mask logicals ----
    wire [15:0] cmp_bits8;
    wire [7:0]  cmp_bits16;
    wire [3:0]  cmp_bits32;
    wire [127:0] res_cmp = (vsew == 3'b000) ? {cmpd_old[127:16], cmp_bits8}  :
                           (vsew == 3'b001) ? {cmpd_old[127:8],  cmp_bits16} :
                                              {cmpd_old[127:4],  cmp_bits32};
    wire [127:0] mlog_full =
        (f6[2:0] == 3'b000) ?  (vs2_data & ~vs1_data) :   // vmandn
        (f6[2:0] == 3'b001) ?  (vs2_data &  vs1_data) :   // vmand
        (f6[2:0] == 3'b010) ?  (vs2_data |  vs1_data) :   // vmor
        (f6[2:0] == 3'b011) ?  (vs2_data ^  vs1_data) :   // vmxor
        (f6[2:0] == 3'b100) ?  (vs2_data | ~vs1_data) :   // vmorn
        (f6[2:0] == 3'b101) ? ~(vs2_data &  vs1_data) :   // vmnand
        (f6[2:0] == 3'b110) ? ~(vs2_data |  vs1_data) :   // vmnor
                              ~(vs2_data ^  vs1_data);    // vmxnor
    wire [127:0] res_mlog;
    generate
        for (gi = 0; gi < 128; gi = gi + 1) begin : g_mlog
            assign res_mlog[gi] = (gi < q_vl) ? mlog_full[gi] : vd_old[gi];
        end
    endgenerate

    assign q_wdata = is_vmem ? vm_buf :
                     (is_grp && op_cmp) ? grp_cmp_res :
                     (is_grp) ? grp_stage[0] :
                     op_cmp  ? res_cmp :
                     op_mlog ? res_mlog :
                     op_s2same ? res_s2 :
                     op_nc  ? res_nc :
                     op_widen ? ((vsew == 3'b000) ? res_w8 : res_w16) :
                     op_redsum ? res_red :
                     op_mvsx ? res_sx :
                     (vsew == 3'b000) ? res8 :
                     (vsew == 3'b001) ? res16 : res32;
    assign q_vd    = vd_i;
    // whole-instruction no-op when vstart>=vl (includes vl==0); vmv.x.s and
    // vector STORES never write the VRF
    assign q_vrf_we = q_valid && !q_illegal && !op_mvxs && !is_vstore && (q_vstart < q_vl);

    // ---------------- vmv.x.s (executes even when vl==0) ----------------
    wire [7:0]  e0_8  = vs2_data[7:0];
    wire [15:0] e0_16 = vs2_data[15:0];
    assign q_scalar = (vsew == 3'b000) ? {{24{e0_8[7]}},  e0_8} :
                      (vsew == 3'b001) ? {{16{e0_16[15]}}, e0_16} :
                                         vs2_data[31:0];
    assign q_scalar_we = q_valid && !q_illegal && op_mvxs;

endmodule
`default_nettype wire
