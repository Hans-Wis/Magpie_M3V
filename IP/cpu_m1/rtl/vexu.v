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

    // ---------------- config legality ----------------
    wire        vill  = q_vtype[31];
    wire [2:0]  vlmul = q_vtype[2:0];
    wire [2:0]  vsew  = q_vtype[5:3];
    wire lmul_gt1  = (vlmul == 3'b001) || (vlmul == 3'b010) || (vlmul == 3'b011);
    wire cfg_illegal = vill || lmul_gt1;         // m2/m4/m8 = 3B deferral

    // ---------------- 3C unit-stride vector load/store decode ----------------
    wire is_vload  = (q_instr[6:0] == 7'b0000111);   // LOAD-FP opcode space
    wire is_vstore = (q_instr[6:0] == 7'b0100111);   // STORE-FP opcode space
    wire is_vmem   = (EN_RVV != 0) && (is_vload || is_vstore);
    assign q_is_mem = q_valid && is_vmem;
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
    wire [4:0] vlmax_el = (5'd16 >> vsew) >> frac_sh;
    wire [8:0] mem_span = {4'b0, vlmax_el} << eew_sel;        // bytes touched at vlmax
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
                    op_wmul || op_waddw || op_redsum || op_mvsx;
    // vstart!=0 on arithmetic = illegal (spec-allowed choice; MATCHES SPIKE —
    // caught by gate_42 lockstep: Spike trapped where the RTL executed).
    // Loads/stores are resumable: vstart is honored (start element), not illegal.
    assign q_illegal = q_valid && ((EN_RVV == 0) || cfg_illegal ||
                       (is_vmem ? mem_illegal :
                        (!known_op ||
                         (q_vstart != 32'h0) ||
                         widen_illegal ||
                         ((op_add || op_sub) && !vm) ||   // masked add/sub = 3B deferral
                         (op_mv && (vs2_i != 5'd0)) ||
                         (op_merge && (vd_i == 5'd0)))));

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

    // ---------------- 3C memory FSM (2 cycles/element: ISSUE -> CAP) ----------------
    localparam [1:0] VM_IDLE = 2'd0, VM_ISSUE = 2'd1, VM_CAP = 2'd2;
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
        end else if (m_advance && vm_done_r) begin
            vm_done_r <= 1'b0;                       // instruction left EX
        end else if (!m_stall) begin
            case (vm_state)
                VM_IDLE: if (m_start && !vm_done_r) begin
                    if (vm_none) begin
                        vm_done_r <= 1'b1;           // vl==0 / vstart>=vl: no beats
                    end else begin
                        vm_buf   <= vd_old;          // undisturbed below-vstart + tail
                        vm_idx   <= vm_vstart;
                        vm_state <= VM_ISSUE;
                    end
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

    assign q_wdata = is_vmem ? vm_buf :
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
