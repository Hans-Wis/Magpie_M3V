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
    output wire [3:0]   q_grp_parts,  // S3/F: EMUL parts (2/4/8) piped for the WB commit
    input  wire         w_grp,        // S3: WB commit is a group write
    input  wire [3:0]   w_parts,
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
    // Phase-C C4b (ADR-0056): widening multiply family — full 2*SEW product (no
    // low/high select). f6=111000 vwmulu (u*u), 111010 vwmulsu (signed vs2 *
    // unsigned vs1/rs1), 111011 vwmul (s*s). OPMVV/OPMVX (vwmul.vv was the Phase-0
    // kernel op; .vx and the u/su variants are new). Golden-probed vs2=-128 vs1=255:
    // vwmul 128 / vwmulu 32640 / vwmulsu -32640.
    wire op_wmul   = (f6 == 6'b111011) && (is_opmvv || is_opmvx) && vm;
    wire op_wmulu  = (f6 == 6'b111000) && (is_opmvv || is_opmvx) && vm;
    wire op_wmulsu = (f6 == 6'b111010) && (is_opmvv || is_opmvx) && vm;
    wire op_wmulany = op_wmul || op_wmulu || op_wmulsu;
    // Phase-C C4c (ADR-0056): widening MAC — vd (2*SEW) += product. f6=111100 vwmaccu
    // (u*u), 111101 vwmacc (s*s), 111111 vwmaccsu (signed VS1 * unsigned VS2),
    // 111110 vwmaccus (unsigned RS1 * signed VS2, .vx only). NOTE the su/us sign roles
    // are on vs1/vs2 and are SWAPPED vs vwmulsu (Spike-probed: vs2=-128 vs1=255 vd=0 ->
    // maccu 32640 / macc 128 / maccsu -128 / maccus -32640). vd is the wide accumulator.
    wire op_vwmaccu  = (f6 == 6'b111100) && (is_opmvv || is_opmvx) && vm;
    wire op_vwmacc   = (f6 == 6'b111101) && (is_opmvv || is_opmvx) && vm;
    wire op_vwmaccus = (f6 == 6'b111110) && is_opmvx && vm;   // .vx only
    wire op_vwmaccsu = (f6 == 6'b111111) && (is_opmvv || is_opmvx) && vm;
    wire op_wmaccany = op_vwmaccu || op_vwmacc || op_vwmaccus || op_vwmaccsu;
    // Phase-C C4d (ADR-0056): widening integer sum reduction — OPIVV (NOT OPMVV).
    // f6=110000 vwredsumu (zext), 110001 vwredsum (sext). vd[0] (2*SEW) = ext(vs1[0])
    // + sum of ext(vs2[0..vl-1]); vs1[0] is already 2*SEW. m1/fractional-LMUL, SEW<=16,
    // vm=1. Golden-probed seed=3 vs2={5,-1,127,-128}: vwredsum 6 / vwredsumu 518.
    wire op_wredu = is_opivv && (f6 == 6'b110000) && vm;
    wire op_wreds = is_opivv && (f6 == 6'b110001) && vm;
    wire op_wred  = op_wredu || op_wreds;
    // Phase-C C4a (ADR-0056): full widening add/sub — OPMVV/OPMVX f6=110xxx, vm=1.
    // f6[2]=wide-vs2 (.wv/.wx, vs2 already 2*SEW), f6[1]=subtract, f6[0]=signed.
    // dest 2*SEW = op_a +/- ext(vs1|rs1); narrows sign/zero-extend per f6[0].
    // vwadd.wv (f6=110101, the kernel accumulate with vd==vs2) is the .wv/signed/add
    // member. Golden-probed vs2=0xFF vs1=1: vwaddu 256 / vwadd 0 / vwsubu 254 /
    // vwsub -2 / vwaddu.wv 257 / vwsub.wv 255.
    wire op_waddsub = (f6[5:3] == 3'b110) && (is_opmvv || is_opmvx) && vm;
    wire ws_wide    = f6[2];
    wire ws_sub     = f6[1];
    wire ws_signed  = f6[0];
    // Phase-C C3 (ADR-0056): vred{sum,and,or,xor,minu,min,maxu,max}.vs — OPMVV
    // f6=000xxx, f6[2:0] picks the combine (min/max 101/111 signed, minu/maxu
    // 100/110 unsigned). vd[0]=vs1[0] OP reduce(vs2[0..vl-1]); tail undisturbed;
    // vm=1 only (masked reductions deferred, same scope as the original vredsum);
    // m1-only (group reductions stay grp_only_illegal). f6=000000 = the old vredsum.
    wire op_red = is_opmvv && (f6[5:3] == 3'b000) && vm;
    wire op_mvsx  = is_opmvx && (f6 == 6'b010000) && (vs2_i == 5'd0) && vm; // vmv.s.x
    // Phase-D D1a (ADR-0057): mask-scan simple set. OPMVV; vs1 field selects the op.
    // VWXUNARY0 (f6=010000): vcpop.m (vs1=10000 -> scalar rd = popcount of active
    // vs2 mask bits), vfirst.m (vs1=10001 -> scalar rd = first active set index, else
    // -1). VMUNARY0 (f6=010100): vid.v (vs1=10001 -> vd[i]=i, vs2 ignored). Maskable;
    // vstart!=0 illegal (Spike-probed: vcpop TRAPS at vstart!=0 — Grok's "exempt" flag
    // was wrong). m1-only (m2/m4 grp_only_illegal). Golden: mask {2,3,6} -> vcpop 3,
    // vfirst 2, vid [0..7]; masked by v0={3,6,7} -> vcpop 2, vfirst 3.
    wire op_vcpop  = is_opmvv && (f6 == 6'b010000) && (vs1_i == 5'b10000);
    wire op_vfirst = is_opmvv && (f6 == 6'b010000) && (vs1_i == 5'b10001);
    wire op_vid    = is_opmvv && (f6 == 6'b010100) && (vs1_i == 5'b10001);
    // Phase-D D1b (ADR-0057): mask-scan set + prefix. VMUNARY0 f6=010100. Let
    // F = first ACTIVE set bit in vs2 (active = vm||v0[i]) over [0,vl).
    //   vmsbf.m (vs1=00001): vd[i]=1 iff i<F                (mask dest)
    //   vmsof.m (vs1=00010): vd[i]=1 iff i==F               (mask dest)
    //   vmsif.m (vs1=00011): vd[i]=1 iff i<=F               (mask dest)
    //   viota.m (vs1=10000): vd[i]=# active set bits in [0,i)  (vector dest)
    // Maskable (masked: inactive vd undisturbed); m1-only; vstart!=0 illegal. vms*
    // vd==v0 legal (Spike-probed, like compares). Golden mask {2,3,6}: vmsbf 0x03,
    // vmsif 0x07, vmsof 0x04, viota [0,0,0,1,2,2,2,3].
    wire op_vmsbf = is_opmvv && (f6 == 6'b010100) && (vs1_i == 5'b00001);
    wire op_vmsof = is_opmvv && (f6 == 6'b010100) && (vs1_i == 5'b00010);
    wire op_vmsif = is_opmvv && (f6 == 6'b010100) && (vs1_i == 5'b00011);
    wire op_vms   = op_vmsbf || op_vmsof || op_vmsif;
    wire op_viota = is_opmvv && (f6 == 6'b010100) && (vs1_i == 5'b10000);
    // Phase-D D2a/D2b (ADR-0057): slides. f6=001110 (up) / 001111 (down). OPIVX/OPIVI
    // = vslideup/vslidedown (off = rs1 unsigned / uimm zext). OPMVX = vslide1up/down
    // (off=1; inject scalar rs1[SEW-1:0] at the boundary). Spike-probed legality
    // (Grok WRONG on both): vstart!=0 illegal (NOT honored) -> the global rule matches;
    // slideup-family vd==vs2 illegal (require_noover), slidedown vd==vs2 legal. m1-only.
    // Golden src[10..17]: slideup2=[.,.,10,11..15], slidedown2=[12..17,0,0], slide1up
    // inject@[0], slide1down inject@[vl-1].
    wire op_vslideup  = (f6 == 6'b001110) && (is_opivx || is_opivi);
    wire op_vslidedn  = (f6 == 6'b001111) && (is_opivx || is_opivi);
    wire op_vslide1up = (f6 == 6'b001110) && is_opmvx;
    wire op_vslide1dn = (f6 == 6'b001111) && is_opmvx;
    wire op_slideup   = op_vslideup || op_vslide1up;
    wire op_slidedn   = op_vslidedn || op_vslide1dn;
    wire op_slide     = op_slideup || op_slidedn;
    wire op_vslide1   = op_vslide1up || op_vslide1dn;
    // Phase-E E3 (ADR-0058): vrgather.vv/.vx/.vi — vd[i] = vs2[index], index = vs1[i]
    // (SEW) / rs1 / uimm; out-of-range index (>=vlmax) -> 0. OPIVV/OPIVX/OPIVI f6=001100.
    // require_noover: vd may not overlap vs2 or vs1 (Spike-probed illegal). vstart!=0
    // illegal (global). m1-only. Combinational crossbar. vrgatherei16 (f6=001110 OPIVV)
    // deferred (16-bit index -> EMUL>1 index register group). Golden src[10..17]
    // idx[3,0,7,2,9,1,5,4] -> [13,10,17,12,0,11,15,14]; .vx/.vi broadcast vs2[idx].
    wire op_vrgather = (f6 == 6'b001100) && (is_opivv || is_opivx || is_opivi);
    wire vrg_illegal = op_vrgather && ((vd_i == vs2_i) || (is_opivv && (vd_i == vs1_i)));
    // Phase-E tail (ADR-0060): vcompress.vm vd,vs2,vs1 — pack active vs2 elements
    // (mask = BIT i of the explicit vs1 operand, NOT v0) into contiguous low vd
    // lanes. OPMVV f6=010111, vm=1 in the encoding (v0 unused; mask is vs1).
    // m1-only (LMUL>1 auto-illegal via grp_only_illegal, non-beats_op); vstart=0
    // (global rule); tail UNDISTURBED. Spike-probed: mask 0x4D over [10..17] ->
    // [10,12,13,16]; empty mask keeps vd. require_noover: vd not overlap vs2/vs1.
    wire op_vcompress = (f6 == 6'b010111) && is_opmvv && vm;
    wire compress_illegal = op_vcompress && ((vd_i == vs2_i) || (vd_i == vs1_i));
    wire op_widen = op_wmulany || op_wmaccany || op_waddsub;

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

    // ---------------- Phase-B B1 (ADR-0055): bitwise / shift / vrsub ----------------
    // same-shape element-wise ALU: join the per-SEW mux + beats_op (m2/m4 groups).
    wire op_and   = (f6 == 6'b001001) && (is_opivv || is_opivx || is_opivi);
    wire op_or    = (f6 == 6'b001010) && (is_opivv || is_opivx || is_opivi);
    wire op_xor   = (f6 == 6'b001011) && (is_opivv || is_opivx || is_opivi);
    wire op_rsub  = (f6 == 6'b000011) && (is_opivx || is_opivi);   // vrsub: b - a (no vv)
    wire op_sll   = (f6 == 6'b100101) && (is_opivv || is_opivx || is_opivi);
    wire op_srl   = (f6 == 6'b101000) && (is_opivv || is_opivx || is_opivi);
    wire op_sra   = (f6 == 6'b101001) && (is_opivv || is_opivx || is_opivi);
    wire op_b1    = op_and || op_or || op_xor || op_rsub ||
                    op_sll || op_srl || op_sra;

    // ---------------- Phase-B B2a (ADR-0055): narrowing shift (vnsrl/vnsra) ----
    // wide 2*SEW source >> shamt -> SEW dest (low bits). Reuses the vnclip wide
    // datapath minus round/clip. Only SEW8/16 (2*SEW=16/32) — SEW32 narrowing
    // needs a 64-bit source, absent in Zve32x (same rule as vnclip).
    wire op_nsrl  = (f6 == 6'b101100) && (is_opivv || is_opivx || is_opivi);
    wire op_nsra  = (f6 == 6'b101101) && (is_opivv || is_opivx || is_opivi);
    wire op_nsr   = op_nsrl || op_nsra;

    // ---------------- Phase-B B2b (ADR-0055): vzext/vsext.vf2/vf4 ----------------
    // OPMVV f6=010010 (gated by f3 -> disjoint from OPIVV vsbc, which shares f6).
    // vs1 selects variant: [2:1]=11 vf2 / 10 vf4 / 01 vf8; [0]=1 sign, 0 zero.
    // Zve32x: no e64 source -> vf8 always illegal; vf4 needs SEW32 (src8), vf2
    // needs SEW>=16 (src SEW/2). Extends the low SEW/2 (or SEW/4) source lane.
    wire ext_enc  = is_opmvv && (f6 == 6'b010010) && (vs1_i[4:3] == 2'b00);
    wire ext_vf2  = (vs1_i[2:1] == 2'b11);
    wire ext_vf4  = (vs1_i[2:1] == 2'b10);
    wire ext_sext = vs1_i[0];
    wire op_vext  = ext_enc &&
                    ((ext_vf2 && ((vsew == 3'b001) || (vsew == 3'b010))) ||
                     (ext_vf4 &&  (vsew == 3'b010)));

    // ---------------- Phase-B B3 (ADR-0055): carry/borrow ----------------
    // vadc/vsbc  -> vector vd  = a +/- b +/- carry(v0[i]); v0 is a carry OPERAND
    //               (NOT a predicate), so body is force-active; vm=1 illegal.
    // vmadc/vmsbc -> mask  vd  = carry/borrow-OUT bit; vm selects carry-in presence.
    // OPI* f6 space. vsbc's f6=010010 aliases OPMVV ext_enc (vzext/vsext) but is
    // disjoint by f3 (OPIVV/X here vs OPMVV there). vstart!=0 caught globally.
    // vsbc/vmsbc have NO OPIVI form (subtract-with-borrow has no imm encoding).
    wire op_adc   = (f6 == 6'b010000) && (is_opivv || is_opivx || is_opivi);
    wire op_madc  = (f6 == 6'b010001) && (is_opivv || is_opivx || is_opivi);
    wire op_sbc   = (f6 == 6'b010010) && (is_opivv || is_opivx);
    wire op_msbc  = (f6 == 6'b010011) && (is_opivv || is_opivx);
    wire op_adcsbc = op_adc  || op_sbc;    // vector-dest carry add/sub (beats_op class)
    wire op_madcb  = op_madc || op_msbc;   // mask-dest carry/borrow-out (op_cmp class)
    // unified mask-dest predicate: single-register dest, group-source, WB writes one reg
    wire mask_dest = op_cmp || op_madcb || op_vms;  // D1b: vms* single-mask-reg dest

    // ---------------- Phase-B B4 (ADR-0055): whole-register move vmv<nr>r.v ----
    // OPIVI f6=100111, vm=1; simm5 (vs1 field) = nr-1, legal {0,1,3,7} -> nr{1,2,4,8}.
    // Copies nr WHOLE registers vd+p <- vs2+p, INDEPENDENT of vtype LMUL/SEW/vl
    // (Spike-probed: executes even under m8 vtype; illegal only on vill). vstart!=0
    // -> illegal for THIS Spike build, so the global known_op vstart rule already
    // matches (no carve-out — Grok's partial-copy flag was empirically wrong here).
    // nr-aligned groups are equal-or-disjoint => the copy has no overlap hazard, so
    // it streams one register/cycle through the vexu-local FSM (no group staging,
    // no core WB write). nr=8 exceeds the 4-part group path — that is WHY it uses
    // its own copy loop rather than beats_op.
    wire op_vmvr = (f6 == 6'b100111) && is_opivi && vm;
    wire [3:0] vmvr_nr = (vs1_i == 5'd0) ? 4'd1 :
                         (vs1_i == 5'd1) ? 4'd2 :
                         (vs1_i == 5'd3) ? 4'd4 :
                         (vs1_i == 5'd7) ? 4'd8 : 4'd0;   // 0 = reserved simm -> illegal
    wire [4:0] vmvr_amask = {1'b0, vmvr_nr} - 5'd1;       // nr-aligned mask 0/1/3/7
    wire vmvr_illegal = op_vmvr && ((vmvr_nr == 4'd0) ||
                        ((vd_i  & vmvr_amask) != 5'd0) ||
                        ((vs2_i & vmvr_amask) != 5'd0));

    // ---------------- Phase-C C1 (ADR-0056): same-width integer multiply ----------
    // OPMVV/OPMVX. f6: mul=100101 mulh=100111 mulhu=100100 mulhsu=100110. vmul keeps
    // the low SEW bits (sign-agnostic); the high variants take the upper SEW bits of
    // the 2*SEW product with the per-variant sign (ss/uu/su). f3 keeps these disjoint
    // from vsll (OPIV*, f6=100101) and vmv<nr>r (OPIVI, f6=100111). OPMVX operand =
    // rs1 truncated to SEW (Spike-probed golden: -2^31*2 -> mul 0, mulh/mulhsu -1,
    // mulhu 1). Same-shape body op: joins beats_op for m2/m4 groups.
    wire op_mul    = (f6 == 6'b100101) && (is_opmvv || is_opmvx);
    wire op_mulh   = (f6 == 6'b100111) && (is_opmvv || is_opmvx);
    wire op_mulhu  = (f6 == 6'b100100) && (is_opmvv || is_opmvx);
    wire op_mulhsu = (f6 == 6'b100110) && (is_opmvv || is_opmvx);
    wire op_muls   = op_mul || op_mulh || op_mulhu || op_mulhsu;

    // ---------------- Phase-E E1 (ADR-0058): integer divide / remainder ----------
    // OPMVV/OPMVX f6 100000/100001/100010/100011 = vdivu/vdiv/vremu/vrem (f3 disjoint
    // from vsaddu/vsadd/vssubu/vssub OPIV*, same f6). RISC-V special cases (Spike-
    // probed): unsigned /0 -> all-1s, %0 -> dividend; signed /0 -> -1, %0 -> dividend;
    // signed overflow MIN/-1 -> quotient MIN, rem 0; signed div truncates toward zero.
    // Combinational per-element divide (functional lockstep; real HW would sequence it
    // -- documented timing deviation, same class as fexu F4). Joins beats_op.
    wire op_vdivu = (f6 == 6'b100000) && (is_opmvv || is_opmvx);
    wire op_vdiv  = (f6 == 6'b100001) && (is_opmvv || is_opmvx);
    wire op_vremu = (f6 == 6'b100010) && (is_opmvv || is_opmvx);
    wire op_vrem  = (f6 == 6'b100011) && (is_opmvv || is_opmvx);
    wire op_vdivr = op_vdivu || op_vdiv || op_vremu || op_vrem;

    // ---------------- Phase-C C2 (ADR-0056): integer multiply-accumulate ----------
    // OPMVV/OPMVX, SEW low bits (sign-agnostic). vd is the ACCUMULATOR (old vd read;
    // vd-overlap with vs1/vs2 is spec-legal — no generic overlap illegality here).
    //   vmacc  101101 : vd += vs1*vs2      vnmsac 101111 : vd -= vs1*vs2
    //   vmadd  101001 : vd  = vs1*vd + vs2  vnmsub 101011 : vd  = vs2 - vs1*vd
    // f3 keeps these disjoint from vsra/vnsra/vssra/vnclip (OPIV*, same f6). scalar
    // (rs1) replaces vs1 in the .vx forms. Golden-probed vd=10,vs1=3,vs2=5 ->
    // macc 25 / nmsac -5 / madd 35 / nmsub -25. Joins beats_op for m2/m4 groups.
    wire op_vmacc  = (f6 == 6'b101101) && (is_opmvv || is_opmvx);
    wire op_vnmsac = (f6 == 6'b101111) && (is_opmvv || is_opmvx);
    wire op_vmadd  = (f6 == 6'b101001) && (is_opmvv || is_opmvx);
    wire op_vnmsub = (f6 == 6'b101011) && (is_opmvv || is_opmvx);
    wire op_mac    = op_vmacc || op_vnmsac || op_vmadd || op_vnmsub;

    // ---------------- Phase-C C5 (ADR-0056): vsmul (signed fractional mul) ----------
    // OPIVV/OPIVX f6=100111 (f3 disjoint from vmulh OPMV* and vmv<nr>r OPIVI, same f6).
    // vd = sat(round((vs2*vs1) >> (SEW-1))) with vxrm rounding; the only overflow is
    // (-2^(SEW-1))^2 -> +2^(SEW-1) -> saturates to max, setting vxsat. SEW8 legal
    // (Spike-probed). Golden (rnu): 64*64>>7=32, -128*-128->127(vxsat), 64*3>>7 rounds
    // 1->2. Maskable body op; joins beats_op.
    wire op_vsmul = (f6 == 6'b100111) && (is_opivv || is_opivx);

    // ---------------- config legality ----------------
    wire        vill  = q_vtype[31];
    wire [2:0]  vlmul = q_vtype[2:0];
    wire [2:0]  vsew  = q_vtype[5:3];
    // S3 (ADR-0049): m2/m4 register groups execute as internal multi-beat with
    // an atomic group commit at WB; m8 stays deferred-illegal.
    wire lmul_m2   = (vlmul == 3'b001);
    wire lmul_m4   = (vlmul == 3'b010);
    wire lmul_m8   = (vlmul == 3'b011);
    // Phase-F: m8 = 8-register group (Spike-probed vlmax e8=128/e16=64/e32=32). Enabled
    // for the same-width beats_op ops via the VM_GRP 8-beat path; widening/reductions/
    // mask-scan stay m8-illegal (below). vmv<nr>r ignores LMUL (nr from simm).
    wire [3:0] grp_parts = lmul_m8 ? 4'd8 : lmul_m4 ? 4'd4 : lmul_m2 ? 4'd2 : 4'd1;
    // m8 legal ONLY for non-memory beats_op (the VM_GRP 8-beat arith path) + vmvr.
    // Memory opcodes alias beats_op via f6/f3 (vle8 f3=000 => op_add), and m8 group-
    // EMUL memory is out-of-scope (int_sh omits m8 => mem_illegal would see an m1 span
    // and silently execute a truncated load). Gate with (beats_op && !is_vmem) so m8
    // memory stays illegal (DUT stricter, honest scope-cut) — Codex Phase-F review.
    wire cfg_illegal = vill || (lmul_m8 && !op_vmvr && !(beats_op && !is_vmem));

    // ---------------- 3C unit-stride vector load/store decode ----------------
    wire is_vload  = (q_instr[6:0] == 7'b0000111);   // LOAD-FP opcode space
    wire is_vstore = (q_instr[6:0] == 7'b0100111);   // STORE-FP opcode space
    wire is_vmem   = (EN_RVV != 0) && (is_vload || is_vstore);
    assign q_is_mem = q_valid && is_vmem;
    assign q_is_grp = q_valid && (is_grp || op_vmvr) && !q_illegal; // hold/beats (incl. cmp, vmvr copy loop)
    // WB group WRITE excludes mask-dest ops (compares + vmadc/vmsbc: single-reg dest)
    assign q_grp_w  = q_valid && is_grp && !mask_dest && !q_illegal;
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
    // Phase-E E2 (ADR-0058): segment load/store vlseg<nf>/vsseg<nf>. Scope: nf=2..8,
    // EEW=SEW, LMUL m1/m2/m4 (EMUL register groups, nf*L<=8, vd L-aligned), unmasked,
    // vstart=0, unit-stride. element-major/field-minor: mem beat k = element(k/nf),
    // field(k%nf). Field f = L-register group; loads write nf*L regs vd..vd+nf*L-1,
    // stores read the same group. Out of scope (kept illegal, DUT stricter than Spike):
    // EEW!=SEW, masked, m8, unaligned vd, vstart!=0. Golden-probed vlseg2/3 + m2/m4.
    wire [2:0] seg_nf_m1 = q_instr[31:29];             // nf-1
    wire [3:0] seg_nf    = {1'b0, seg_nf_m1} + 4'd1;   // 1..8
    wire       is_seg    = is_vmem && (seg_nf_m1 != 3'b000);
    // LMUL registers per field (L) and total register group nf*L (<=8). m1/m2/m4 only.
    wire [3:0] seg_L     = (vlmul == 3'b010) ? 4'd4 : (vlmul == 3'b001) ? 4'd2 : 4'd1;
    wire [1:0] seg_lg2L  = vlmul[1:0];                 // log2(L): m1=0 m2=1 m4=2
    wire [6:0] seg_tot   = seg_nf * {3'b0, seg_L};     // nf*L registers
    wire seg_ok = (eew_sel != 2'd3) && vm &&
                  (q_instr[28:26] == 3'b000) &&                 // mew=0, unit-stride
                  (q_instr[24:20] == 5'b00000) &&               // lumop/sumop=0
                  !vlmul[2] && (vlmul != 3'b011) &&             // LMUL m1/m2/m4 (no m8/frac)
                  ({1'b0, eew_sel} == vsew) &&                  // EEW == SEW
                  (q_vstart == 32'h0) &&                        // vstart=0
                  (seg_tot <= 7'd8) &&                          // nf*L <= 8 register budget
                  (({1'b0, vd_i} + seg_tot[5:0]) <= 6'd32) &&   // group in range
                  ((vd_i & ({1'b0, seg_L[3:0]} - 5'd1)) == 5'd0) && // vd L-aligned (Codex)
                  align_ok;
    wire mem_illegal = is_seg ? !seg_ok :
                       (!mem_enc_ok || !emul_ok || !align_ok);

    // 3D widening legality: dst EEW = 2*SEW needs SEW<=16 and dst EMUL = 2*LMUL
    // <= 1 (single register group) => LMUL must be fractional. Overlap (match
    // Spike require_noover): a widening dest may not overlap a NARROWER source;
    // vwadd.wv vd==vs2 is legal (same EEW — the kernel's accumulate uses it).
    wire widen_lmul_ok = (vlmul == 3'b111) || (vlmul == 3'b110) || (vlmul == 3'b101);
    // vs2 is narrow (dest must not overlap it) for vwmul and the .vv/.vx add/sub;
    // for .wv/.wx vs2 is already 2*SEW so vd==vs2 is legal. vs1 is a narrow VECTOR
    // only in the OPMVV forms (in OPMVX the vs1 field is rs1, no register overlap).
    wire widen_narrow_vs2 = op_wmulany || op_wmaccany || (op_waddsub && !ws_wide);
    wire widen_illegal = op_widen &&
                         (!widen_lmul_ok || (vsew == 3'b010) ||
                          (is_opmvv && (vd_i == vs1_i)) ||
                          (widen_narrow_vs2 && (vd_i == vs2_i)));

    // B2b (Grok review): vext is widening-class for register layout — the wider
    // dest may not overlap the NARROWER source (Spike require_noover; narrowing's
    // vd==vs2 allowance does NOT apply). Scoped to dst LMUL=m1 (grp_only_illegal),
    // so the simple same-register overlap check suffices.
    wire vext_illegal = op_vext && (vd_i == vs2_i);
    // D2: slideup/vslide1up dest may not overlap the source (require_noover, Spike-
    // probed illegal); slidedown vd==vs2 is legal (reads ahead).
    wire slide_illegal = op_slideup && (vd_i == vs2_i);

    wire known_op = op_add || op_sub || op_mv || op_merge || op_mvxs ||
                    op_wmulany || op_wmaccany || op_waddsub || op_red || op_wred || op_mvsx ||
                    op_mm || op_cmp || op_mlog || op_s2same || op_nc || op_b1 ||
                    op_nsr || op_vext || op_adcsbc || op_madcb || op_vmvr ||
                    op_muls || op_mac || op_vsmul || op_vdivr ||
                    op_vcpop || op_vfirst || op_vid || op_vms || op_viota || op_slide || op_vrgather ||
                    op_vcompress;
    // ops that iterate register-group parts (compares read groups, write ONE
    // mask register); widening/narrowing/reductions stay <= m1 (their own
    // LMUL rules) and vmv.x.s/vmv.s.x touch element 0 only.
    wire beats_op  = op_add || op_sub || op_mv || op_merge || op_mm ||
                     op_s2same || op_cmp || op_b1 || op_adcsbc || op_madcb ||
                     op_muls || op_mac || op_vsmul || op_vdivr;
    // NOTE: memory opcodes alias the f6-based arith decodes (every other use
    // site is guarded by an is_vmem priority mux) — exclude them here too.
    wire is_grp    = (grp_parts != 4'd1) && beats_op && !is_vmem;
    wire grp_only_illegal = (grp_parts != 4'd1) && !op_vmvr &&
        (op_widen || op_red || op_wred || op_nc || op_nsr || op_vext ||
         !beats_op && !op_mvxs && !op_mvsx && !op_mlog && !is_vmem);
    // register-group alignment (vd for writes except mask-dest; sources)
    wire [4:0] grp_amask = lmul_m8 ? 5'd7 : lmul_m4 ? 5'd3 : lmul_m2 ? 5'd1 : 5'd0;
    wire grp_align_illegal = is_grp &&
        ((!mask_dest && ((vd_i & grp_amask[4:0]) != 5'd0)) ||
         ((vs2_i & grp_amask) != 5'd0) ||
         // .vv source includes OPMVV vector-vector forms (vaadd family) —
         // Codex S3 finding: is_opivv alone missed them
         ((is_opivv || is_opmvv) && ((vs1_i & grp_amask) != 5'd0)));
    // narrowing legality mirrors widening (source EMUL = 2*LMUL <= 1); the
    // low-part destination overlap (vd == vs2) is spec-legal for narrowing.
    wire nc_illegal = (op_nc || op_nsr) && (!widen_lmul_ok || (vsew == 3'b010));
    // C4d: widening reduction has a 2*SEW accumulator -> SEW32 (2*SEW=64) illegal.
    wire wred_illegal = op_wred && (vsew == 3'b010);
    // vstart!=0 on arithmetic = illegal (spec-allowed choice; MATCHES SPIKE —
    // caught by gate_42 lockstep: Spike trapped where the RTL executed).
    // Loads/stores are resumable: vstart is honored (start element), not illegal.
    assign q_illegal = q_valid && ((EN_RVV == 0) || cfg_illegal ||
                       (is_vmem ? mem_illegal :
                        (!known_op ||
                         (q_vstart != 32'h0) ||
                         widen_illegal || vext_illegal || slide_illegal || vrg_illegal ||
                         compress_illegal ||
                         (op_mv && (vs2_i != 5'd0)) ||
                         (op_merge && (vd_i == 5'd0)) ||
                         // S1 (Codex, Spike-confirmed): a MASKED body op may not
                         // write v0 (dest overlaps the mask); mask-DEST compares
                         // targeting v0 remain legal.
                         nc_illegal || wred_illegal || grp_only_illegal || grp_align_illegal ||
                         vmvr_illegal ||   // B4: bad simm nr / vd|vs2 not nr-aligned
                         // B3: vadc/vsbc read v0 as carry => vm=1 illegal, vd==0
                         // always illegal (dest would overlap carry operand v0).
                         (op_adcsbc && (vm || (vd_i == 5'd0))) ||
                         // B3: vmadc/vmsbc write mask; with vm=0 they also READ v0
                         // as carry-in, so vd==0 illegal only in that carry-in form.
                         (op_madcb && !vm && (vd_i == 5'd0)) ||
                         ((op_add || op_sub || op_mm || op_s2same || op_nc ||
                           op_b1 || op_nsr || op_vext || op_muls || op_mac || op_vsmul || op_vdivr ||
                           op_vid || op_viota || op_slide || op_vrgather) &&
                          !vm && (vd_i == 5'd0)))));

    // ---------------- VRF ----------------
    reg [127:0] vrf [0:31];
    // S3: during group beats the datapath sees part p of each operand; the
    // element window and v0 mask bits shift by the part base. m1 ops see p=0.
    reg  [2:0]   grp_p;                 // Phase-F: 0..7 for m8
    wire [4:0]   part_off = {2'b0, grp_p};
    wire [127:0] vs1_data = vrf[vs1_i + part_off];
    wire [127:0] vs2_data = vrf[vs2_i + part_off];
    wire [127:0] v0_data  = vrf[0];
    wire [127:0] vd_old   = vrf[vd_i + part_off];
    // elements per register at the current SEW; part base in ELEMENTS
    wire [5:0]  nl_el     = (vsew == 3'b000) ? 6'd16 : (vsew == 3'b001) ? 6'd8 : 6'd4;
    wire [7:0]  elem_base = {2'b0, nl_el} * {5'b0, grp_p};
    // per-lane views: lane gi maps to architectural element (elem_base + gi)
    wire [127:0] v0_view   = v0_data >> elem_base;
    wire [31:0]  vl_view   = (q_vl > {24'b0, elem_base}) ? (q_vl - {24'b0, elem_base}) : 32'h0;
    wire [31:0]  vst_view  = (q_vstart > {24'b0, elem_base}) ? (q_vstart - {24'b0, elem_base}) : 32'h0;

    wire [127:0] cmpd_old  = vrf[vd_i];          // mask-dest reads its own reg
    wire [127:0] cmpd_view = cmpd_old >> elem_base;

    // S3 staging: computed parts await the atomic group commit at WB
    reg [127:0] grp_stage [0:7];    // Phase-F: up to 8 parts (m8)
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
                if (w_parts >= 4'd4) begin
                    vrf[w_vd + 5'd2] <= grp_stage[2];
                    vrf[w_vd + 5'd3] <= grp_stage[3];
                end
                if (w_parts == 4'd8) begin
                    vrf[w_vd + 5'd4] <= grp_stage[4];
                    vrf[w_vd + 5'd5] <= grp_stage[5];
                    vrf[w_vd + 5'd6] <= grp_stage[6];
                    vrf[w_vd + 5'd7] <= grp_stage[7];
                end
            end
        end
        // B4: vmv<nr>r.v register-at-a-time copy. Drained-start guarantees w_en
        // targets no vrf entry this cycle (nothing else vector is in flight), so
        // this stays the SOLE vrf writer. Aligned groups are equal-or-disjoint so
        // src!=dst (or a harmless self-copy) — no read/write hazard. !m_stall keeps
        // the write in lockstep with the FSM's own (stall-gated) vmvr_p advance —
        // otherwise a stall would idempotently re-write the same reg (power waste).
        if ((vm_state == VM_VMVR) && !m_stall)
            vrf[vd_i + {2'b0, vmvr_p}] <= vrf[vs2_i + {2'b0, vmvr_p}];
        // E2: segment load drain — one field register per cycle (single writer; the
        // core WB port is idle for segment since q_vrf_we is forced 0).
        if ((vm_state == VM_SEGWR) && !m_stall)
            vrf[vd_i + {2'b0, vmvr_p}] <= seg_drain;   // tail lanes kept undisturbed
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
            wire signed [7:0] sra_r = as >>> b[2:0];   // self-determined signed -> arithmetic
            wire [7:0] r = op_add   ? (a + b) :
                           op_sub   ? (a - b) :
                           op_adc   ? (a + b + {7'b0, m}) : // B3: vadc, carry-in v0[i]
                           op_sbc   ? (a - b - {7'b0, m}) : // B3: vsbc, borrow-in v0[i]
                           op_rsub  ? (b - a) :             // B1: vrsub
                           op_and   ? (a & b) :
                           op_or    ? (a | b) :
                           op_xor   ? (a ^ b) :
                           op_sll   ? (a << b[2:0]) :
                           op_srl   ? (a >> b[2:0]) :
                           op_sra   ? sra_r :          
                           op_min   ? ((as < bs) ? a : b) :
                           op_minu  ? ((a < b)  ? a : b) :
                           op_max   ? ((as > bs) ? a : b) :
                           op_maxu  ? ((a > b)  ? a : b) :
                           op_merge ? (m ? b : a) :
                                      b;                   // vmv.v.*
            wire active = (gi >= vst_view) && (gi < vl_view) &&
                          (op_merge || op_adcsbc || vm || m); // S1 masked-off=undist; B3 v0=carry not mask
            assign res8[gi*8 +: 8] = active ? r : vd_old[gi*8 +: 8];
        end
        for (gi = 0; gi < 8; gi = gi + 1) begin : g_sew16
            wire [15:0] a = vs2_data[gi*16 +: 16];
            wire [15:0] b = is_opivv ? vs1_data[gi*16 +: 16] : scalar_b[15:0];
            wire        m = v0_view[gi];
            wire signed [15:0] as = a, bs = b;
            wire signed [15:0] sra_r = as >>> b[3:0];
            wire [15:0] r = op_add   ? (a + b) :
                            op_sub   ? (a - b) :
                            op_adc   ? (a + b + {15'b0, m}) : // B3: vadc
                            op_sbc   ? (a - b - {15'b0, m}) : // B3: vsbc
                            op_rsub  ? (b - a) :
                            op_and   ? (a & b) :
                            op_or    ? (a | b) :
                            op_xor   ? (a ^ b) :
                            op_sll   ? (a << b[3:0]) :
                            op_srl   ? (a >> b[3:0]) :
                            op_sra   ? sra_r :          
                            op_min   ? ((as < bs) ? a : b) :
                            op_minu  ? ((a < b)  ? a : b) :
                            op_max   ? ((as > bs) ? a : b) :
                            op_maxu  ? ((a > b)  ? a : b) :
                            op_merge ? (m ? b : a) :
                                       b;
            wire active = (gi >= vst_view) && (gi < vl_view) &&
                          (op_merge || op_adcsbc || vm || m); // B3: v0=carry, force active
            assign res16[gi*16 +: 16] = active ? r : vd_old[gi*16 +: 16];
        end
        for (gi = 0; gi < 4; gi = gi + 1) begin : g_sew32
            wire [31:0] a = vs2_data[gi*32 +: 32];
            wire [31:0] b = is_opivv ? vs1_data[gi*32 +: 32] : scalar_b;
            wire        m = v0_view[gi];
            wire signed [31:0] as = a, bs = b;
            wire signed [31:0] sra_r = as >>> b[4:0];
            wire [31:0] r = op_add   ? (a + b) :
                            op_sub   ? (a - b) :
                            op_adc   ? (a + b + {31'b0, m}) : // B3: vadc
                            op_sbc   ? (a - b - {31'b0, m}) : // B3: vsbc
                            op_rsub  ? (b - a) :
                            op_and   ? (a & b) :
                            op_or    ? (a | b) :
                            op_xor   ? (a ^ b) :
                            op_sll   ? (a << b[4:0]) :
                            op_srl   ? (a >> b[4:0]) :
                            op_sra   ? sra_r :          
                            op_min   ? ((as < bs) ? a : b) :
                            op_minu  ? ((a < b)  ? a : b) :
                            op_max   ? ((as > bs) ? a : b) :
                            op_maxu  ? ((a > b)  ? a : b) :
                            op_merge ? (m ? b : a) :
                                       b;
            wire active = (gi >= vst_view) && (gi < vl_view) &&
                          (op_merge || op_adcsbc || vm || m); // B3: v0=carry, force active
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

        // ---- B3: vmadc/vmsbc carry/borrow-OUT -> mask bits (SEW+1 wide) ----
        // cin = 0 when vm=1 (no carry-in form), else v0[i]. Unsigned only:
        // vmadc bit = carry-out of (a+b+cin); vmsbc bit = borrow = (a < b+bin).
        for (gi = 0; gi < 16; gi = gi + 1) begin : g_madc8
            wire [7:0] a = vs2_data[gi*8 +: 8];
            wire [7:0] b = is_opivv ? vs1_data[gi*8 +: 8] : scalar_b[7:0];
            wire       cin = vm ? 1'b0 : v0_view[gi];
            wire [8:0] sum = {1'b0, a} + {1'b0, b} + {8'b0, cin};
            wire [8:0] dif = {1'b0, a} - {1'b0, b} - {8'b0, cin};
            wire       c   = op_msbc ? dif[8] : sum[8];
            assign madc_bits8[gi] = (gi < vl_view) ? c : cmpd_view[gi];
        end
        for (gi = 0; gi < 8; gi = gi + 1) begin : g_madc16
            wire [15:0] a = vs2_data[gi*16 +: 16];
            wire [15:0] b = is_opivv ? vs1_data[gi*16 +: 16] : scalar_b[15:0];
            wire        cin = vm ? 1'b0 : v0_view[gi];
            wire [16:0] sum = {1'b0, a} + {1'b0, b} + {16'b0, cin};
            wire [16:0] dif = {1'b0, a} - {1'b0, b} - {16'b0, cin};
            wire        c   = op_msbc ? dif[16] : sum[16];
            assign madc_bits16[gi] = (gi < vl_view) ? c : cmpd_view[gi];
        end
        for (gi = 0; gi < 4; gi = gi + 1) begin : g_madc32
            wire [31:0] a = vs2_data[gi*32 +: 32];
            wire [31:0] b = is_opivv ? vs1_data[gi*32 +: 32] : scalar_b;
            wire        cin = vm ? 1'b0 : v0_view[gi];
            wire [32:0] sum = {1'b0, a} + {1'b0, b} + {32'b0, cin};
            wire [32:0] dif = {1'b0, a} - {1'b0, b} - {32'b0, cin};
            wire        c   = op_msbc ? dif[32] : sum[32];
            assign madc_bits32[gi] = (gi < vl_view) ? c : cmpd_view[gi];
        end
    endgenerate

    // ---- C1: same-width integer multiply -> low SEW / high SEW of 2*SEW product ----
    // ss/uu/su products kept in self-determined signed/unsigned wires (avoids the
    // signed-in-ternary zero-extend trap). Body op: masked-off / <vstart / >=vl kept.
    wire [127:0] res_mul8, res_mul16, res_mul32;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : g_mul8
            wire [7:0] a = vs2_data[gi*8 +: 8];
            wire [7:0] b = is_opmvv ? vs1_data[gi*8 +: 8] : scalar_b[7:0];
            wire signed [7:0]  as = a, bs = b;
            wire signed [15:0] p_ss = as * bs;                    // signed*signed
            wire        [15:0] p_uu = a * b;                      // unsigned*unsigned
            wire signed [15:0] p_su = as * $signed({1'b0, b});    // signed*unsigned
            wire [7:0] r = op_mul   ? p_ss[7:0]  :   // low bits: sign-agnostic
                           op_mulh  ? p_ss[15:8] :
                           op_mulhu ? p_uu[15:8] :
                                      p_su[15:8];    // mulhsu
            wire m = v0_view[gi];
            wire active = (gi >= vst_view) && (gi < vl_view) && (vm || m);
            assign res_mul8[gi*8 +: 8] = active ? r : vd_old[gi*8 +: 8];
        end
        for (gi = 0; gi < 8; gi = gi + 1) begin : g_mul16
            wire [15:0] a = vs2_data[gi*16 +: 16];
            wire [15:0] b = is_opmvv ? vs1_data[gi*16 +: 16] : scalar_b[15:0];
            wire signed [15:0] as = a, bs = b;
            wire signed [31:0] p_ss = as * bs;
            wire        [31:0] p_uu = a * b;
            wire signed [31:0] p_su = as * $signed({1'b0, b});
            wire [15:0] r = op_mul   ? p_ss[15:0]  :
                            op_mulh  ? p_ss[31:16] :
                            op_mulhu ? p_uu[31:16] :
                                       p_su[31:16];
            wire m = v0_view[gi];
            wire active = (gi >= vst_view) && (gi < vl_view) && (vm || m);
            assign res_mul16[gi*16 +: 16] = active ? r : vd_old[gi*16 +: 16];
        end
        for (gi = 0; gi < 4; gi = gi + 1) begin : g_mul32
            wire [31:0] a = vs2_data[gi*32 +: 32];
            wire [31:0] b = is_opmvv ? vs1_data[gi*32 +: 32] : scalar_b;
            wire signed [31:0] as = a, bs = b;
            wire signed [63:0] p_ss = as * bs;
            wire        [63:0] p_uu = a * b;
            wire signed [63:0] p_su = as * $signed({1'b0, b});
            wire [31:0] r = op_mul   ? p_ss[31:0]  :
                            op_mulh  ? p_ss[63:32] :
                            op_mulhu ? p_uu[63:32] :
                                       p_su[63:32];
            wire m = v0_view[gi];
            wire active = (gi >= vst_view) && (gi < vl_view) && (vm || m);
            assign res_mul32[gi*32 +: 32] = active ? r : vd_old[gi*32 +: 32];
        end
    endgenerate
    wire [127:0] res_mul = (vsew == 3'b000) ? res_mul8 :
                           (vsew == 3'b001) ? res_mul16 : res_mul32;

    // ---- E1: integer divide/remainder (combinational per element). Special cases
    // per RISC-V: /0 -> all-1s (u) / -1 (s), %0 -> dividend; signed MIN/-1 -> MIN, 0. ----
    wire [127:0] res_vdiv8, res_vdiv16, res_vdiv32;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : g_div8
            wire [7:0] a = vs2_data[gi*8 +: 8];
            wire [7:0] b = is_opmvv ? vs1_data[gi*8 +: 8] : scalar_b[7:0];
            wire signed [7:0] as = a, bs = b;
            wire bz  = (b == 8'h00);
            wire sov = (a == 8'h80) && (b == 8'hFF);         // MIN / -1
            wire [7:0] udiv = bz ? 8'hFF : a / b;
            wire [7:0] urem = bz ? a     : a % b;
            wire [7:0] sdiv = bz ? 8'hFF : sov ? 8'h80 : $unsigned(as / bs);
            wire [7:0] srem = bz ? a     : sov ? 8'h00 : $unsigned(as % bs);
            wire [7:0] r = op_vdivu ? udiv : op_vdiv ? sdiv : op_vremu ? urem : srem;
            wire m = v0_view[gi];
            wire active = (gi >= vst_view) && (gi < vl_view) && (vm || m);
            assign res_vdiv8[gi*8 +: 8] = active ? r : vd_old[gi*8 +: 8];
        end
        for (gi = 0; gi < 8; gi = gi + 1) begin : g_div16
            wire [15:0] a = vs2_data[gi*16 +: 16];
            wire [15:0] b = is_opmvv ? vs1_data[gi*16 +: 16] : scalar_b[15:0];
            wire signed [15:0] as = a, bs = b;
            wire bz  = (b == 16'h0);
            wire sov = (a == 16'h8000) && (b == 16'hFFFF);
            wire [15:0] udiv = bz ? 16'hFFFF : a / b;
            wire [15:0] urem = bz ? a        : a % b;
            wire [15:0] sdiv = bz ? 16'hFFFF : sov ? 16'h8000 : $unsigned(as / bs);
            wire [15:0] srem = bz ? a        : sov ? 16'h0000 : $unsigned(as % bs);
            wire [15:0] r = op_vdivu ? udiv : op_vdiv ? sdiv : op_vremu ? urem : srem;
            wire m = v0_view[gi];
            wire active = (gi >= vst_view) && (gi < vl_view) && (vm || m);
            assign res_vdiv16[gi*16 +: 16] = active ? r : vd_old[gi*16 +: 16];
        end
        for (gi = 0; gi < 4; gi = gi + 1) begin : g_div32
            wire [31:0] a = vs2_data[gi*32 +: 32];
            wire [31:0] b = is_opmvv ? vs1_data[gi*32 +: 32] : scalar_b;
            wire signed [31:0] as = a, bs = b;
            wire bz  = (b == 32'h0);
            wire sov = (a == 32'h80000000) && (b == 32'hFFFFFFFF);
            wire [31:0] udiv = bz ? 32'hFFFFFFFF : a / b;
            wire [31:0] urem = bz ? a            : a % b;
            wire [31:0] sdiv = bz ? 32'hFFFFFFFF : sov ? 32'h80000000 : $unsigned(as / bs);
            wire [31:0] srem = bz ? a            : sov ? 32'h00000000 : $unsigned(as % bs);
            wire [31:0] r = op_vdivu ? udiv : op_vdiv ? sdiv : op_vremu ? urem : srem;
            wire m = v0_view[gi];
            wire active = (gi >= vst_view) && (gi < vl_view) && (vm || m);
            assign res_vdiv32[gi*32 +: 32] = active ? r : vd_old[gi*32 +: 32];
        end
    endgenerate
    wire [127:0] res_vdiv = (vsew == 3'b000) ? res_vdiv8 :
                            (vsew == 3'b001) ? res_vdiv16 : res_vdiv32;

    // ---- C2: integer MAC (low SEW bits, sign-agnostic). vd_old = accumulator ----
    // prod_ab = vs1*vs2 (macc/nmsac); prod_db = vs1*vd (madd/nmsub). All truncated
    // to SEW; add/sub mod 2^SEW. Masked-off / <vstart / >=vl -> vd undisturbed.
    wire [127:0] res_mac8, res_mac16, res_mac32;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : g_mac8
            wire [7:0] a = vs2_data[gi*8 +: 8];
            wire [7:0] b = is_opmvv ? vs1_data[gi*8 +: 8] : scalar_b[7:0];
            wire [7:0] d = vd_old[gi*8 +: 8];
            wire [7:0] prod_ab = a * b;          // vs1*vs2
            wire [7:0] prod_db = d * b;          // vs1*vd
            wire [7:0] r = op_vmacc  ? (d + prod_ab) :
                           op_vnmsac ? (d - prod_ab) :
                           op_vmadd  ? (prod_db + a) :
                                       (a - prod_db);   // vnmsub
            wire m = v0_view[gi];
            wire active = (gi >= vst_view) && (gi < vl_view) && (vm || m);
            assign res_mac8[gi*8 +: 8] = active ? r : d;
        end
        for (gi = 0; gi < 8; gi = gi + 1) begin : g_mac16
            wire [15:0] a = vs2_data[gi*16 +: 16];
            wire [15:0] b = is_opmvv ? vs1_data[gi*16 +: 16] : scalar_b[15:0];
            wire [15:0] d = vd_old[gi*16 +: 16];
            wire [15:0] prod_ab = a * b;
            wire [15:0] prod_db = d * b;
            wire [15:0] r = op_vmacc  ? (d + prod_ab) :
                            op_vnmsac ? (d - prod_ab) :
                            op_vmadd  ? (prod_db + a) :
                                        (a - prod_db);
            wire m = v0_view[gi];
            wire active = (gi >= vst_view) && (gi < vl_view) && (vm || m);
            assign res_mac16[gi*16 +: 16] = active ? r : d;
        end
        for (gi = 0; gi < 4; gi = gi + 1) begin : g_mac32
            wire [31:0] a = vs2_data[gi*32 +: 32];
            wire [31:0] b = is_opmvv ? vs1_data[gi*32 +: 32] : scalar_b;
            wire [31:0] d = vd_old[gi*32 +: 32];
            wire [31:0] prod_ab = a * b;
            wire [31:0] prod_db = d * b;
            wire [31:0] r = op_vmacc  ? (d + prod_ab) :
                            op_vnmsac ? (d - prod_ab) :
                            op_vmadd  ? (prod_db + a) :
                                        (a - prod_db);
            wire m = v0_view[gi];
            wire active = (gi >= vst_view) && (gi < vl_view) && (vm || m);
            assign res_mac32[gi*32 +: 32] = active ? r : d;
        end
    endgenerate
    wire [127:0] res_mac = (vsew == 3'b000) ? res_mac8 :
                           (vsew == 3'b001) ? res_mac16 : res_mac32;

    // ---- C5: vsmul = sat(round((vs2*vs1) >> (SEW-1))) with vxrm. Only overflow is
    // (-2^(SEW-1))^2 -> saturates to +max, setting vxsat. Rounding increment matches
    // the S2 scaling-shift pattern (b_dm1=P[d-1], b_d=P[d], lo/any = shifted-out bits).
    wire [127:0] res_smul8, res_smul16, res_smul32;
    wire [15:0]  smul_sat8;
    wire [7:0]   smul_sat16;
    wire [3:0]   smul_sat32;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : g_smul8
            wire signed [7:0]  as = vs2_data[gi*8 +: 8];
            wire signed [7:0]  bs = is_opivv ? vs1_data[gi*8 +: 8] : scalar_b[7:0];
            wire signed [15:0] p  = as * bs;
            wire inc = (q_vxrm == 2'd0) ?  p[6] :
                       (q_vxrm == 2'd1) ? (p[6] & ((|p[5:0]) | p[7])) :
                       (q_vxrm == 2'd2) ?  1'b0 :
                                          (~p[7] & (|p[6:0]));
            wire signed [15:0] sh  = p >>> 7;   // self-determined signed => arithmetic
            wire signed [15:0] rnd = sh + {15'b0, inc};
            wire ov_hi = rnd > 16'sd127;
            wire ov_lo = rnd < -16'sd128;
            wire [7:0] r = ov_hi ? 8'h7F : ov_lo ? 8'h80 : rnd[7:0];
            wire m = v0_view[gi];
            wire active = (gi >= vst_view) && (gi < vl_view) && (vm || m);
            assign res_smul8[gi*8 +: 8] = active ? r : vd_old[gi*8 +: 8];
            assign smul_sat8[gi] = active && (ov_hi | ov_lo);
        end
        for (gi = 0; gi < 8; gi = gi + 1) begin : g_smul16
            wire signed [15:0] as = vs2_data[gi*16 +: 16];
            wire signed [15:0] bs = is_opivv ? vs1_data[gi*16 +: 16] : scalar_b[15:0];
            wire signed [31:0] p  = as * bs;
            wire inc = (q_vxrm == 2'd0) ?  p[14] :
                       (q_vxrm == 2'd1) ? (p[14] & ((|p[13:0]) | p[15])) :
                       (q_vxrm == 2'd2) ?  1'b0 :
                                          (~p[15] & (|p[14:0]));
            wire signed [31:0] sh  = p >>> 15;
            wire signed [31:0] rnd = sh + {31'b0, inc};
            wire ov_hi = rnd > 32'sd32767;
            wire ov_lo = rnd < -32'sd32768;
            wire [15:0] r = ov_hi ? 16'h7FFF : ov_lo ? 16'h8000 : rnd[15:0];
            wire m = v0_view[gi];
            wire active = (gi >= vst_view) && (gi < vl_view) && (vm || m);
            assign res_smul16[gi*16 +: 16] = active ? r : vd_old[gi*16 +: 16];
            assign smul_sat16[gi] = active && (ov_hi | ov_lo);
        end
        for (gi = 0; gi < 4; gi = gi + 1) begin : g_smul32
            wire signed [31:0] as = vs2_data[gi*32 +: 32];
            wire signed [31:0] bs = is_opivv ? vs1_data[gi*32 +: 32] : scalar_b;
            wire signed [63:0] p  = as * bs;
            wire inc = (q_vxrm == 2'd0) ?  p[30] :
                       (q_vxrm == 2'd1) ? (p[30] & ((|p[29:0]) | p[31])) :
                       (q_vxrm == 2'd2) ?  1'b0 :
                                          (~p[31] & (|p[30:0]));
            wire signed [63:0] sh  = p >>> 31;
            wire signed [63:0] rnd = sh + {63'b0, inc};
            wire ov_hi = rnd > 64'sd2147483647;
            wire ov_lo = rnd < -64'sd2147483648;
            wire [31:0] r = ov_hi ? 32'h7FFFFFFF : ov_lo ? 32'h80000000 : rnd[31:0];
            wire m = v0_view[gi];
            wire active = (gi >= vst_view) && (gi < vl_view) && (vm || m);
            assign res_smul32[gi*32 +: 32] = active ? r : vd_old[gi*32 +: 32];
            assign smul_sat32[gi] = active && (ov_hi | ov_lo);
        end
    endgenerate
    wire [127:0] res_smul = (vsew == 3'b000) ? res_smul8 :
                            (vsew == 3'b001) ? res_smul16 : res_smul32;

    // ---- D1a vid.v: vd[i] = i (element index, SEW-wide). vs2 ignored. m1-only. ----
    wire [127:0] res_vid8, res_vid16, res_vid32;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : g_vid8
            wire active = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
            assign res_vid8[gi*8 +: 8] = active ? gi[7:0] : vd_old[gi*8 +: 8];
        end
        for (gi = 0; gi < 8; gi = gi + 1) begin : g_vid16
            wire active = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
            assign res_vid16[gi*16 +: 16] = active ? {12'b0, gi[3:0]} : vd_old[gi*16 +: 16];
        end
        for (gi = 0; gi < 4; gi = gi + 1) begin : g_vid32
            wire active = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
            assign res_vid32[gi*32 +: 32] = active ? {30'b0, gi[1:0]} : vd_old[gi*32 +: 32];
        end
    endgenerate
    wire [127:0] res_vid = (vsew == 3'b000) ? res_vid8 :
                           (vsew == 3'b001) ? res_vid16 : res_vid32;

    // ---- D1b vmsbf/vmsof/vmsif (mask) + viota (vector). One scan over the mask ----
    // mbits[i] = active set bit; preset/run track "any set / count set" in [0,i).
    // vms_raw = per-op mask bit assuming active; viota_pk = per-element prefix count.
    reg  [15:0] mbits;
    reg  [15:0] vms_raw;
    reg  [127:0] viota_pk;
    reg  [4:0]  run;
    reg         preset;
    integer     di;
    always @* begin
        for (di = 0; di < 16; di = di + 1)
            mbits[di] = (di < q_vl) && vs2_data[di] && (vm || v0_data[di]);
        run = 5'd0; preset = 1'b0;
        for (di = 0; di < 16; di = di + 1) begin
            viota_pk[di*8 +: 8] = {3'b0, run};       // count of set bits in [0,di)
            vms_raw[di] = op_vmsbf ? ~(preset | mbits[di]) :  // i<F
                          op_vmsif ? ~preset :                // i<=F
                                     (~preset & mbits[di]);   // vmsof: i==F
            if (mbits[di]) begin run = run + 5'd1; preset = 1'b1; end
        end
    end
    // vms mask output: active lanes get vms_raw, inactive/tail keep the old mask reg.
    wire [15:0] vms_bits;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : g_vms
            wire en = (gi < q_vl) && (vm || v0_data[gi]);
            assign vms_bits[gi] = en ? vms_raw[gi] : cmpd_old[gi];
        end
    endgenerate
    // viota vector output (count fits SEW; masked-off / tail undisturbed).
    wire [127:0] res_viota8, res_viota16, res_viota32;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : g_viota8
            wire en = (gi < q_vl) && (vm || v0_data[gi]);
            assign res_viota8[gi*8 +: 8] = en ? viota_pk[gi*8 +: 8] : vd_old[gi*8 +: 8];
        end
        for (gi = 0; gi < 8; gi = gi + 1) begin : g_viota16
            wire en = (gi < q_vl) && (vm || v0_data[gi]);
            assign res_viota16[gi*16 +: 16] = en ? {8'b0, viota_pk[gi*8 +: 8]} : vd_old[gi*16 +: 16];
        end
        for (gi = 0; gi < 4; gi = gi + 1) begin : g_viota32
            wire en = (gi < q_vl) && (vm || v0_data[gi]);
            assign res_viota32[gi*32 +: 32] = en ? {24'b0, viota_pk[gi*8 +: 8]} : vd_old[gi*32 +: 32];
        end
    endgenerate
    wire [127:0] res_viota = (vsew == 3'b000) ? res_viota8 :
                             (vsew == 3'b001) ? res_viota16 : res_viota32;

    // ---- D2 slides (m1). Barrel-shift vs2 by off elements; blend with vd_old for
    // undisturbed lanes; slidedown zero-fills the top; slide1 injects rs1 at the
    // boundary. vstart!=0 is illegal so the body always starts at element 0. ----
    wire [31:0] slide_off_raw = op_vslide1 ? 32'd1 :
                                is_opivi   ? {27'b0, vs1_i} : q_rs1;
    wire [5:0]  off_c  = (slide_off_raw > 32'd16) ? 6'd16 : slide_off_raw[5:0];
    wire [9:0]  shamt  = {4'b0, off_c} << (vsew + 3'd3);   // element offset -> bit shift
    wire [127:0] vs2_up = vs2_data << shamt;               // toward higher elements
    wire [127:0] vs2_dn = vs2_data >> shamt;               // toward lower (zero-fill top)
    wire [31:0]  last_idx = vl_view - 32'd1;               // vslide1down inject index
    wire [127:0] res_slide8, res_slide16, res_slide32;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : g_sl8
            wire active = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
            wire [7:0] up_v = (op_vslide1up && gi == 0) ? q_rs1[7:0] :
                              ({26'b0, gi[4:0]} >= {26'b0, off_c[4:0]}) ? vs2_up[gi*8 +: 8] : vd_old[gi*8 +: 8];
            wire [6:0] dn_idx8 = {2'b0, gi[4:0]} + {1'b0, off_c};   // Codex: zero-fill uses the
            wire       dn_ok8  = dn_idx8 < vlmax_el;                 // FRACTIONAL vlmax, not 16
            wire [7:0] dn_v = (op_vslide1dn && ({27'b0, gi[4:0]} == last_idx)) ? q_rs1[7:0] :
                              dn_ok8 ? vs2_dn[gi*8 +: 8] : 8'b0;
            wire [7:0] sv = op_slideup ? up_v : dn_v;
            assign res_slide8[gi*8 +: 8] = active ? sv : vd_old[gi*8 +: 8];
        end
        for (gi = 0; gi < 8; gi = gi + 1) begin : g_sl16
            wire active = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
            wire [15:0] up_v = (op_vslide1up && gi == 0) ? q_rs1[15:0] :
                               ({26'b0, gi[4:0]} >= {26'b0, off_c[4:0]}) ? vs2_up[gi*16 +: 16] : vd_old[gi*16 +: 16];
            wire [6:0]  dn_idx16 = {2'b0, gi[4:0]} + {1'b0, off_c};
            wire        dn_ok16  = dn_idx16 < vlmax_el;
            wire [15:0] dn_v = (op_vslide1dn && ({27'b0, gi[4:0]} == last_idx)) ? q_rs1[15:0] :
                               dn_ok16 ? vs2_dn[gi*16 +: 16] : 16'b0;
            wire [15:0] sv = op_slideup ? up_v : dn_v;
            assign res_slide16[gi*16 +: 16] = active ? sv : vd_old[gi*16 +: 16];
        end
        for (gi = 0; gi < 4; gi = gi + 1) begin : g_sl32
            wire active = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
            wire [31:0] up_v = (op_vslide1up && gi == 0) ? q_rs1 :
                               ({26'b0, gi[4:0]} >= {26'b0, off_c[4:0]}) ? vs2_up[gi*32 +: 32] : vd_old[gi*32 +: 32];
            wire [6:0]  dn_idx32 = {2'b0, gi[4:0]} + {1'b0, off_c};
            wire        dn_ok32  = dn_idx32 < vlmax_el;
            wire [31:0] dn_v = (op_vslide1dn && ({27'b0, gi[4:0]} == last_idx)) ? q_rs1 :
                               dn_ok32 ? vs2_dn[gi*32 +: 32] : 32'b0;
            wire [31:0] sv = op_slideup ? up_v : dn_v;
            assign res_slide32[gi*32 +: 32] = active ? sv : vd_old[gi*32 +: 32];
        end
    endgenerate
    wire [127:0] res_slide = (vsew == 3'b000) ? res_slide8 :
                             (vsew == 3'b001) ? res_slide16 : res_slide32;

    // ---- E3 vrgather: vd[i] = (index >= vlmax) ? 0 : vs2[index] (combinational
    // crossbar, m1). index = vs1[i] (.vv) / rs1 (.vx) / uimm (.vi). ----
    wire [127:0] res_rg8, res_rg16, res_rg32;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : g_rg8
            wire [31:0] idx = is_opivv ? {24'b0, vs1_data[gi*8 +: 8]} :
                              is_opivi ? {27'b0, vs1_i} : q_rs1;
            wire oor = (idx >= {25'b0, vlmax_el});
            wire [7:0] gval = oor ? 8'b0 : vs2_data[idx[3:0]*8 +: 8];
            wire active = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
            assign res_rg8[gi*8 +: 8] = active ? gval : vd_old[gi*8 +: 8];
        end
        for (gi = 0; gi < 8; gi = gi + 1) begin : g_rg16
            wire [31:0] idx = is_opivv ? {16'b0, vs1_data[gi*16 +: 16]} :
                              is_opivi ? {27'b0, vs1_i} : q_rs1;
            wire oor = (idx >= {25'b0, vlmax_el});
            wire [15:0] gval = oor ? 16'b0 : vs2_data[idx[2:0]*16 +: 16];
            wire active = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
            assign res_rg16[gi*16 +: 16] = active ? gval : vd_old[gi*16 +: 16];
        end
        for (gi = 0; gi < 4; gi = gi + 1) begin : g_rg32
            wire [31:0] idx = is_opivv ? vs1_data[gi*32 +: 32] :
                              is_opivi ? {27'b0, vs1_i} : q_rs1;
            wire oor = (idx >= {25'b0, vlmax_el});
            wire [31:0] gval = oor ? 32'b0 : vs2_data[idx[1:0]*32 +: 32];
            wire active = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
            assign res_rg32[gi*32 +: 32] = active ? gval : vd_old[gi*32 +: 32];
        end
    endgenerate
    wire [127:0] res_rg = (vsew == 3'b000) ? res_rg8 :
                          (vsew == 3'b001) ? res_rg16 : res_rg32;

    // ---- Phase-E tail vcompress: j=0; for i in [0,vl): if vs1 mask bit i set,
    // vd[j++] = vs2[i]; positions [j,vl) and [vl,vlmax) undisturbed. m1 (<=16
    // lanes), vstart=0 (global). Variable-base part-select realizes the running
    // write index combinationally (unrolled per SEW). ----
    reg [127:0] res_compress;
    integer     cpi;
    reg [4:0]   cpwj;
    always @* begin
        res_compress = vd_old;               // tail / inactive undisturbed
        cpwj = 5'd0;
        if (vsew == 3'b000) begin
            for (cpi = 0; cpi < 16; cpi = cpi + 1)
                if (({27'b0, cpwj} < 32'd16) && (cpi < q_vl) && vs1_data[cpi[6:0]]) begin
                    res_compress[cpwj*8 +: 8] = vs2_data[cpi*8 +: 8];
                    cpwj = cpwj + 5'd1;
                end
        end else if (vsew == 3'b001) begin
            for (cpi = 0; cpi < 8; cpi = cpi + 1)
                if ((cpi < q_vl) && vs1_data[cpi[6:0]]) begin
                    res_compress[cpwj*16 +: 16] = vs2_data[cpi*16 +: 16];
                    cpwj = cpwj + 5'd1;
                end
        end else begin
            for (cpi = 0; cpi < 4; cpi = cpi + 1)
                if ((cpi < q_vl) && vs1_data[cpi[6:0]]) begin
                    res_compress[cpwj*32 +: 32] = vs2_data[cpi*32 +: 32];
                    cpwj = cpwj + 5'd1;
                end
        end
    end

    // ---------------- 3C memory FSM (2 cycles/element: ISSUE -> CAP) ----------------
    localparam [2:0] VM_IDLE = 3'd0, VM_ISSUE = 3'd1, VM_CAP = 3'd2, VM_GRP = 3'd3,
                     VM_VMVR = 3'd4, VM_SEGWR = 3'd5;    // B4 copy loop / E2 segment drain
    reg [2:0]   vm_state;
    reg [5:0]   vm_idx;          // element (up to 63 for segment e8 m4)
    reg [2:0]   vmvr_p;          // B4: register index within the nr-register group
    reg [127:0] vm_buf;          // assemble buffer (loads); seeded with vd_old
    reg         vm_done_r;
    // E2 segment (stub): per-field assemble buffers + field counter + byte-offset accum.
    reg [127:0] seg_buf [0:7];
    reg [2:0]   seg_fld;
    reg [8:0]   seg_off;         // running byte offset from rs1
    wire        seg_last = (seg_fld + 3'd1 == seg_nf[2:0]);
    // physical register offset from vd for element vm_idx, field seg_fld: f*L + (i/epr).
    wire [5:0]  seg_regsh = vm_idx >> (3'd4 - {1'b0, vsew[1:0]});   // i / epr (reg-in-group)
    wire [3:0]  seg_bufi4 = ({1'b0, seg_fld} << seg_lg2L) + seg_regsh[3:0];
    wire [2:0]  seg_bufi  = seg_bufi4[2:0];                         // <=7 (nf*L<=8)
    wire [127:0] seg_src  = vrf[vd_i + {2'b0, seg_bufi}];           // store source (vs3 group)
    // E2 (Codex finding): drain keeps tail lanes (element >= vl) undisturbed. For LMUL>1
    // each register p holds field-local elements [r*epr, (r+1)*epr); active bytes in it =
    // clamp(vl - r*epr, 0, epr) * EEW, blended byte-wise with the old register.
    wire [2:0]  seg_r     = vmvr_p & (seg_L[2:0] - 3'd1);   // reg-in-group of drain reg
    wire [4:0]  seg_epr   = 5'd16 >> vsew;                          // elements per register
    wire [6:0]  seg_rbase = {2'b0, seg_r} * {2'b0, seg_epr};        // r * epr
    wire [6:0]  seg_actel = (q_vl[6:0] > seg_rbase) ? (q_vl[6:0] - seg_rbase) : 7'd0;
    wire [4:0]  seg_actc  = (seg_actel > {2'b0, seg_epr}) ? seg_epr : seg_actel[4:0];
    wire [5:0]  seg_act_bytes = {1'b0, seg_actc} << eew_sel;
    wire [127:0] seg_old_p = vrf[vd_i + {2'b0, vmvr_p}];            // old (vd+p) for the tail
    wire [127:0] seg_drain;
    genvar sgb;
    generate
        for (sgb = 0; sgb < 16; sgb = sgb + 1) begin : g_segdrain
            assign seg_drain[sgb*8 +: 8] = ({2'b0, sgb[3:0]} < seg_act_bytes)
                                           ? seg_buf[vmvr_p][sgb*8 +: 8]
                                           : seg_old_p[sgb*8 +: 8];
        end
    endgenerate
    wire [5:0]  seg_last_el = q_vl[5:0] - 6'd1;   // last element index (vl up to 64)

    wire [4:0] vm_vl     = q_vl[4:0];       // <=16 elements under EMUL<=1
    wire [4:0] vm_vstart = q_vstart[4:0];
    wire       vm_none   = (q_vstart >= q_vl);
    wire [4:0] vm_last   = vm_vl - 5'd1;

    assign vm_active       = (vm_state != VM_IDLE);
    assign vm_result_valid = vm_done_r;
    assign vm_dvalid       = (vm_state == VM_ISSUE);
    assign vm_we           = is_vstore;
    // segment beats walk a contiguous byte offset; scalar path is element*eew.
    assign vm_addr         = is_seg ? (q_rs1 + {23'b0, seg_off})
                                    : (q_rs1 + ({26'b0, vm_idx} << eew_sel));
    // store element from vs3 (= vd field) placed on its byte lane via wstrb. For
    // segment the source is the current field register (vs3+seg_fld) at element vm_idx.
    wire [127:0] st_src = is_seg ? seg_src : vd_old;
    wire [7:0]  st8  = st_src[{vm_idx[3:0], 3'b000} +: 8];
    wire [15:0] st16 = st_src[{vm_idx[2:0], 4'b0000} +: 16];
    wire [31:0] st32 = st_src[{vm_idx[1:0], 5'b00000} +: 32];
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
            grp_p     <= 3'd0;
            vmvr_p    <= 3'd0;
        end else if (m_advance && vm_done_r) begin
            vm_done_r <= 1'b0;                       // instruction left EX
        end else if (!m_stall) begin
            case (vm_state)
                VM_IDLE: if (m_start && !vm_done_r) begin
                    if (op_vmvr) begin
                        // B4: copy nr whole registers, one per cycle (vstart!=0 is
                        // illegal upstream, so this always starts at register 0).
                        vmvr_p   <= 3'd0;
                        vm_state <= VM_VMVR;
                    end else if (is_seg) begin
                        // E2: segment beats walk element-major/field-minor from rs1.
                        if (vm_none) begin
                            vm_done_r <= 1'b1;          // vl==0
                        end else begin
                            seg_fld  <= 3'd0;
                            seg_off  <= 9'd0;
                            vm_idx   <= 6'd0;           // vstart=0
                            vm_state <= VM_ISSUE;
                        end
                    end else if (is_grp) begin
                        // S3: register-group beats — one part per cycle into
                        // staging; drained-start means nothing else vector is
                        // in flight until the WB group commit.
                        if (vm_none) begin
                            vm_done_r <= 1'b1;
                        end else begin
                            grp_p     <= 3'd0;
                            grp_sat_q <= 1'b0;
                            vm_state  <= VM_GRP;
                        end
                    end else if (vm_none) begin
                        vm_done_r <= 1'b1;           // vl==0 / vstart>=vl: no beats
                    end else begin
                        vm_buf   <= vd_old;          // undisturbed below-vstart + tail
                        vm_idx   <= {1'b0, vm_vstart};
                        vm_state <= VM_ISSUE;
                    end
                end

                VM_GRP: begin
                    grp_stage[grp_p] <= part_res;
                    grp_sat_q <= grp_sat_q | part_sat_or;
                    if (mask_dest)
                        grp_mask_acc <= (grp_mask_acc & ~(mask_nl << elem_base)) |
                                        ({112'b0, cmp_seg} << elem_base);
                    if ({1'b0, grp_p} + 4'd1 == grp_parts) begin
                        grp_p     <= 3'd0;
                        vm_state  <= VM_IDLE;
                        vm_done_r <= 1'b1;
                    end else
                        grp_p <= grp_p + 3'd1;
                end
                VM_VMVR: begin
                    // the vrf copy for register vmvr_p lands in the write block this
                    // cycle; advance until all nr registers are done.
                    // >= (not ==) so a malformed nr can never hang the FSM (the
                    // illegal path already blocks entry; this is belt-and-braces).
                    if (({1'b0, vmvr_p} + 4'd1) >= vmvr_nr) begin
                        vm_state  <= VM_IDLE;
                        vm_done_r <= 1'b1;
                    end else
                        vmvr_p <= vmvr_p + 3'd1;
                end
                VM_ISSUE: vm_state <= VM_CAP;        // beat fired this cycle
                VM_CAP: if (is_seg) begin
                    // E2: capture the loaded element into field seg_fld; walk (field,
                    // element) and the contiguous byte offset. On the last beat a load
                    // drains its nf field buffers to vd..vd+nf-1 (VM_SEGWR); a store is
                    // done (memory already written beat-by-beat).
                    if (is_vload) begin
                        case (eew_sel)
                            2'd0: seg_buf[seg_bufi][{vm_idx[3:0], 3'b000} +: 8]   <= ld8;
                            2'd1: seg_buf[seg_bufi][{vm_idx[2:0], 4'b0000} +: 16] <= ld16;
                            default: seg_buf[seg_bufi][{vm_idx[1:0], 5'b00000} +: 32] <= m_rdata;
                        endcase
                    end
                    seg_off <= seg_off + (9'd1 << eew_sel);
                    if (seg_last) begin
                        seg_fld <= 3'd0;
                        if (vm_idx == seg_last_el) begin
                            if (is_vload) begin vmvr_p <= 3'd0; vm_state <= VM_SEGWR; end
                            else          begin vm_done_r <= 1'b1; vm_state <= VM_IDLE; end
                        end else begin
                            vm_idx   <= vm_idx + 6'd1;
                            vm_state <= VM_ISSUE;
                        end
                    end else begin
                        seg_fld  <= seg_fld + 3'd1;
                        vm_state <= VM_ISSUE;
                    end
                end else begin
                    if (is_vload) begin
                        case (eew_sel)
                            2'd0: vm_buf[{vm_idx[3:0], 3'b000} +: 8]       <= ld8;
                            2'd1: vm_buf[{vm_idx[2:0], 4'b0000} +: 16]     <= ld16;
                            default: vm_buf[{vm_idx[1:0], 5'b00000} +: 32] <= m_rdata;
                        endcase
                    end
                    if (vm_idx == {1'b0, vm_last}) begin
                        vm_state  <= VM_IDLE;
                        vm_done_r <= 1'b1;
                    end else begin
                        vm_idx   <= vm_idx + 6'd1;
                        vm_state <= VM_ISSUE;
                    end
                end
                VM_SEGWR: begin
                    // vrf[vd+vmvr_p] <= seg_drain lands in the write block; drain all
                    // nf*L field-group registers, then retire.
                    if (({1'b0, vmvr_p} + 4'd1) >= seg_tot[3:0]) begin
                        vm_state  <= VM_IDLE;
                        vm_done_r <= 1'b1;
                    end else
                        vmvr_p <= vmvr_p + 3'd1;
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
            wire [7:0]  na = vs2_data[gi*8 +: 8];          // narrow vs2
            wire [7:0]  nb = is_opmvv ? vs1_data[gi*8 +: 8] : scalar_b[7:0]; // narrow vs1/rs1
            // C4b widening mul: full 2*SEW product, sign per variant (ss/uu/su).
            wire signed [7:0]  nas = na, nbs = nb;
            wire signed [15:0] p_ss = nas * nbs;                   // vwmul
            wire        [15:0] p_uu = na * nb;                     // vwmulu
            wire signed [15:0] p_su = nas * $signed({1'b0, nb});   // vwmulsu (vs2 signed)
            wire [15:0] prod = op_wmulu ? p_uu : op_wmulsu ? p_su : p_ss;
            // C4c widening MAC: vd (2*SEW) += product; su/us sign roles swapped vs mul.
            wire signed [15:0] p_maccsu = nbs * $signed({1'b0, na});  // signed vs1 * unsigned vs2
            wire [15:0] mac_prod = op_vwmaccu  ? p_uu :
                                   op_vwmacc   ? p_ss :
                                   op_vwmaccsu ? p_maccsu :
                                                 p_su;   // vwmaccus = unsigned rs1 * signed vs2
            wire [15:0] macc_res = mac_prod + vd_old[gi*16 +: 16];
            // C4a add/sub: op_a (wide vs2 or ext narrow vs2) +/- ext(vs1|rs1).
            wire [15:0] wa = vs2_data[gi*16 +: 16];        // wide vs2 (.wv/.wx)
            wire [15:0] na_x = ws_signed ? {{8{na[7]}}, na} : {8'b0, na};
            wire [15:0] nb_x = ws_signed ? {{8{nb[7]}}, nb} : {8'b0, nb};
            wire [15:0] wopa = ws_wide ? wa : na_x;
            wire [15:0] ws_res = ws_sub ? (wopa - nb_x) : (wopa + nb_x);
            wire [15:0] r = op_wmaccany ? macc_res : op_wmulany ? prod : ws_res;
            wire active = (gi < q_vl);
            assign res_w8[gi*16 +: 16] = active ? r : vd_old[gi*16 +: 16];
        end
        for (gi = 0; gi < 4; gi = gi + 1) begin : g_w16
            wire [15:0] na = vs2_data[gi*16 +: 16];
            wire [15:0] nb = is_opmvv ? vs1_data[gi*16 +: 16] : scalar_b[15:0];
            wire signed [15:0] nas = na, nbs = nb;
            wire signed [31:0] p_ss = nas * nbs;
            wire        [31:0] p_uu = na * nb;
            wire signed [31:0] p_su = nas * $signed({1'b0, nb});
            wire [31:0] prod = op_wmulu ? p_uu : op_wmulsu ? p_su : p_ss;
            wire signed [31:0] p_maccsu = nbs * $signed({1'b0, na});
            wire [31:0] mac_prod = op_vwmaccu  ? p_uu :
                                   op_vwmacc   ? p_ss :
                                   op_vwmaccsu ? p_maccsu :
                                                 p_su;
            wire [31:0] macc_res = mac_prod + vd_old[gi*32 +: 32];
            wire [31:0] wa = vs2_data[gi*32 +: 32];
            wire [31:0] na_x = ws_signed ? {{16{na[15]}}, na} : {16'b0, na};
            wire [31:0] nb_x = ws_signed ? {{16{nb[15]}}, nb} : {16'b0, nb};
            wire [31:0] wopa = ws_wide ? wa : na_x;
            wire [31:0] ws_res = ws_sub ? (wopa - nb_x) : (wopa + nb_x);
            wire [31:0] r = op_wmaccany ? macc_res : op_wmulany ? prod : ws_res;
            wire active = (gi < q_vl);
            assign res_w16[gi*32 +: 32] = active ? r : vd_old[gi*32 +: 32];
        end
    endgenerate

    // ---------------- C3 reductions: vd[0] = vs1[0] OP reduce(active vs2) ----------
    // One 128-bit source register (m1). f6[2:0] picks the combine. min/max sign-
    // extend seed+elements to 32b for a correct signed compare; all others zero-
    // extend (only red_acc[SEW-1:0] is committed, so upper bits are don't-care for
    // sum/and/or/xor and hold the sign-extended winner for min/max). vl==0 => the
    // loop is empty AND q_vrf_we is 0 (vstart<vl false) => no write, matching Spike.
    wire red_signed = op_red && f6[2] && f6[0];    // vredmin(101) / vredmax(111)
    reg [31:0] red_acc;
    reg [31:0] red_el;
    integer rk;
    always @* begin
        case (vsew)
            3'b000:  red_acc = red_signed ? {{24{vs1_data[7]}},  vs1_data[7:0]}  : {24'b0, vs1_data[7:0]};
            3'b001:  red_acc = red_signed ? {{16{vs1_data[15]}}, vs1_data[15:0]} : {16'b0, vs1_data[15:0]};
            default: red_acc = vs1_data[31:0];
        endcase
        red_el = 32'b0;
        for (rk = 0; rk < 16; rk = rk + 1) begin
            if ((rk < q_vl) &&
                ((vsew == 3'b000) || (vsew == 3'b001 && rk < 8) || (vsew == 3'b010 && rk < 4))) begin
                case (vsew)
                    3'b000:  red_el = red_signed ? {{24{vs2_data[(rk%16)*8+7]}},  vs2_data[(rk%16)*8 +: 8]}  : {24'b0, vs2_data[(rk%16)*8 +: 8]};
                    3'b001:  red_el = red_signed ? {{16{vs2_data[(rk%8)*16+15]}}, vs2_data[(rk%8)*16 +: 16]} : {16'b0, vs2_data[(rk%8)*16 +: 16]};
                    default: red_el = vs2_data[(rk%4)*32 +: 32];
                endcase
                case (f6[2:0])
                    3'b000:  red_acc = red_acc + red_el;                                       // vredsum
                    3'b001:  red_acc = red_acc & red_el;                                       // vredand
                    3'b010:  red_acc = red_acc | red_el;                                       // vredor
                    3'b011:  red_acc = red_acc ^ red_el;                                       // vredxor
                    3'b100:  red_acc = (red_acc < red_el) ? red_acc : red_el;                  // vredminu
                    3'b101:  red_acc = ($signed(red_acc) < $signed(red_el)) ? red_acc : red_el;// vredmin
                    3'b110:  red_acc = (red_acc > red_el) ? red_acc : red_el;                  // vredmaxu
                    default: red_acc = ($signed(red_acc) > $signed(red_el)) ? red_acc : red_el;// vredmax
                endcase
            end
        end
    end
    wire [127:0] res_red = (vsew == 3'b000) ? {vd_old[127:8],  red_acc[7:0]} :
                           (vsew == 3'b001) ? {vd_old[127:16], red_acc[15:0]} :
                                              {vd_old[127:32], red_acc[31:0]};

    // ---- C4d widening reduction: vd[0] (2*SEW) = ext(vs1[0]) + sum ext(vs2) ----
    // vs1[0] is already 2*SEW; vs2 elements (SEW) sign/zero-extend to 32. Only
    // wred_acc[2*SEW-1:0] commits. SEW8 -> 16-bit dst; SEW16 -> 32-bit dst (SEW32
    // is wred_illegal). vl==0 -> no write (q_vrf_we=0), matching Spike.
    wire wred_signed = op_wreds;
    reg [31:0] wred_acc;
    reg [31:0] wred_el;
    integer wk;
    always @* begin
        case (vsew)
            3'b000:  wred_acc = wred_signed ? {{16{vs1_data[15]}}, vs1_data[15:0]} : {16'b0, vs1_data[15:0]};
            default: wred_acc = vs1_data[31:0];   // SEW16: 2*SEW=32, vs1[0] fills the acc
        endcase
        wred_el = 32'b0;
        for (wk = 0; wk < 16; wk = wk + 1) begin
            if ((wk < q_vl) && ((vsew == 3'b000) || (vsew == 3'b001 && wk < 8))) begin
                case (vsew)
                    3'b000:  wred_el = wred_signed ? {{24{vs2_data[wk*8+7]}},   vs2_data[wk*8 +: 8]}   : {24'b0, vs2_data[wk*8 +: 8]};
                    default: wred_el = wred_signed ? {{16{vs2_data[wk*16+15]}}, vs2_data[wk*16 +: 16]} : {16'b0, vs2_data[wk*16 +: 16]};
                endcase
                wred_acc = wred_acc + wred_el;
            end
        end
    end
    wire [127:0] res_wred = (vsew == 3'b000) ? {vd_old[127:16], wred_acc[15:0]} :
                                               {vd_old[127:32], wred_acc[31:0]};
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
    wire [127:0] res_ext16, res_ext32;   // B2b vzext/vsext

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
            wire        [15:0] nsrl_w = v >> d;            // B2a vnsrl: logical
            wire signed [15:0] nsra_w = vs >>> d;          // B2a vnsra: arithmetic (self-det signed)
            wire signed [16:0] rs = {vs[15], $unsigned(vs >>> d)} + {16'b0, inc};
            wire        [16:0] ru = {1'b0, v >> d} + {16'b0, inc};
            wire s_ov = (rs > 17'sd127) || (rs < -17'sd128);
            wire u_ov = (ru > 17'd255);
            wire [7:0] r = op_nsrl  ? nsrl_w[7:0] :
                           op_nsra  ? nsra_w[7:0] :
                           op_nclip ? (s_ov ? (rs[16] ? 8'h80 : 8'h7F) : rs[7:0])
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
            wire        [31:0] nsrl_w = v >> d;
            wire signed [31:0] nsra_w = vs >>> d;
            wire signed [32:0] rs = {vs[31], $unsigned(vs >>> d)} + {32'b0, inc};
            wire        [32:0] ru = {1'b0, v >> d} + {32'b0, inc};
            wire s_ov = (rs > 33'sd32767) || (rs < -33'sd32768);
            wire u_ov = (ru > 33'd65535);
            wire [15:0] r = op_nsrl  ? nsrl_w[15:0] :
                            op_nsra  ? nsra_w[15:0] :
                            op_nclip ? (s_ov ? (rs[32] ? 16'h8000 : 16'h7FFF) : rs[15:0])
                                     : (u_ov ? 16'hFFFF : ru[15:0]);
            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
            assign res_nc16[gi*16 +: 16] = en ? r : vd_old[gi*16 +: 16];
            assign nc_sat16[gi] = en && (op_nclip ? s_ov : u_ov);
        end

        // ---- B2b vzext/vsext: SEW/2 (vf2) or SEW/4 (vf4) source -> SEW dest ----
        for (gi = 0; gi < 8; gi = gi + 1) begin : g_ext16   // dst e16, vf2 (src 8b)
            wire [7:0]  s = vs2_data[gi*8 +: 8];
            wire [15:0] e = ext_sext ? {{8{s[7]}}, s} : {8'b0, s};
            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
            assign res_ext16[gi*16 +: 16] = en ? e : vd_old[gi*16 +: 16];
        end
        for (gi = 0; gi < 4; gi = gi + 1) begin : g_ext32   // dst e32, vf2 (src 16b) / vf4 (src 8b)
            wire [15:0] s2 = vs2_data[gi*16 +: 16];
            wire [7:0]  s4 = vs2_data[gi*8 +: 8];
            wire [31:0] e2 = ext_sext ? {{16{s2[15]}}, s2} : {16'b0, s2};
            wire [31:0] e4 = ext_sext ? {{24{s4[7]}},  s4} : {24'b0, s4};
            wire [31:0] e  = ext_vf4 ? e4 : e2;
            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
            assign res_ext32[gi*32 +: 32] = en ? e : vd_old[gi*32 +: 32];
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
                       (op_nc && ((vsew == 3'b000) ? (|nc_sat8) : (|nc_sat16))) ||
                       (op_vsmul && ((vsew == 3'b000) ? (|smul_sat8) :
                                     (vsew == 3'b001) ? (|smul_sat16) : (|smul_sat32)));
    assign q_vxsat = q_valid && !q_illegal && (q_vstart < q_vl) &&
                     (is_grp ? grp_sat_q : part_sat_or);

    // per-part combinational result for the group beats (arith class)
    wire [127:0] part_res = op_muls ? res_mul :
                            op_vdivr ? res_vdiv :
                            op_mac ? res_mac :
                            op_vsmul ? res_smul :
                            op_s2same ? res_s2 :
                            (vsew == 3'b000) ? res8 :
                            (vsew == 3'b001) ? res16 : res32;
    wire [15:0] cmp_seg  = (vsew == 3'b000) ? seg8 :
                           (vsew == 3'b001) ? {8'b0, seg16} :
                                              {12'b0, seg32};
    wire [127:0] mask_nl = (vsew == 3'b000) ? 128'hFFFF :
                           (vsew == 3'b001) ? 128'hFF : 128'hF;
    // group compare: bits < vl from the accumulator, tail from the dest reg
    // Phase-F: q_vl reaches 128 (m8 e8); use [7:0] so vl==128 shifts by 128
    // (>= width => 0) and the -1 fills all 128 mask bits. [6:0] would alias 128->0.
    wire [127:0] vl_ones  = (128'h1 << q_vl[7:0]) - 128'h1;
    wire [127:0] grp_cmp_res = (cmpd_old & ~vl_ones) | (grp_mask_acc & vl_ones);

    // ---- S1 result assembly: compares + mask logicals ----
    wire [15:0] cmp_bits8;
    wire [7:0]  cmp_bits16;
    wire [3:0]  cmp_bits32;
    wire [15:0] madc_bits8;
    wire [7:0]  madc_bits16;
    wire [3:0]  madc_bits32;
    // B3: vmadc/vmsbc reuse the compare mask-write path (res_cmp / cmp_seg /
    // grp_mask_acc) — pick the carry/borrow bits when op_madcb.
    wire [15:0] seg8  = op_vms ? vms_bits       : op_madcb ? madc_bits8  : cmp_bits8;
    wire [7:0]  seg16 = op_vms ? vms_bits[7:0]  : op_madcb ? madc_bits16 : cmp_bits16;
    wire [3:0]  seg32 = op_vms ? vms_bits[3:0]  : op_madcb ? madc_bits32 : cmp_bits32;
    wire [127:0] res_cmp = (vsew == 3'b000) ? {cmpd_old[127:16], seg8}  :
                           (vsew == 3'b001) ? {cmpd_old[127:8],  seg16} :
                                              {cmpd_old[127:4],  seg32};
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
                     (is_grp && mask_dest) ? grp_cmp_res :
                     (is_grp) ? grp_stage[0] :
                     mask_dest ? res_cmp :
                     op_muls ? res_mul :
                     op_vdivr ? res_vdiv :
                     op_mac ? res_mac :
                     op_vsmul ? res_smul :
                     op_mlog ? res_mlog :
                     op_s2same ? res_s2 :
                     (op_nc || op_nsr) ? res_nc :
                     op_vext ? ((vsew == 3'b001) ? res_ext16 : res_ext32) :
                     op_widen ? ((vsew == 3'b000) ? res_w8 : res_w16) :
                     op_red ? res_red :
                     op_wred ? res_wred :
                     op_vid ? res_vid :
                     op_viota ? res_viota :
                     op_slide ? res_slide :
                     op_vrgather ? res_rg :
                     op_vcompress ? res_compress :
                     op_mvsx ? res_sx :
                     (vsew == 3'b000) ? res8 :
                     (vsew == 3'b001) ? res16 : res32;
    assign q_vd    = vd_i;
    // whole-instruction no-op when vstart>=vl (includes vl==0); vmv.x.s and
    // vector STORES never write the VRF
    // vmvr writes its nr registers from the FSM copy loop, never via the WB port.
    assign q_vrf_we = q_valid && !q_illegal && !op_mvxs && !is_vstore && !op_vmvr &&
                      !op_vcpop && !op_vfirst &&   // D1a: scalar-dest, no VRF write
                      !is_seg &&                   // E2: segment load drains via the FSM
                      (q_vstart < q_vl);

    // ---------------- vmv.x.s (executes even when vl==0) ----------------
    wire [7:0]  e0_8  = vs2_data[7:0];
    wire [15:0] e0_16 = vs2_data[15:0];
    wire [31:0] mvxs_res = (vsew == 3'b000) ? {{24{e0_8[7]}},  e0_8} :
                           (vsew == 3'b001) ? {{16{e0_16[15]}}, e0_16} :
                                              vs2_data[31:0];

    // ---------------- D1a vcpop.m / vfirst.m (scalar mask scan, m1) ----------------
    // count / first-index over active vs2 mask bits in [0,vl); active = vm||v0[i].
    // m1-only (vl<=16), so 16-wide scan. vfirst none -> -1 (XLEN all ones).
    reg  [4:0] cpop_cnt;
    reg  [4:0] vfirst_idx;
    reg        vfirst_hit;
    integer    mk;
    always @* begin
        cpop_cnt   = 5'b0;
        vfirst_idx = 5'b0;
        vfirst_hit = 1'b0;
        for (mk = 0; mk < 16; mk = mk + 1) begin
            if ((mk < q_vl) && vs2_data[mk] && (vm || v0_data[mk])) begin
                cpop_cnt = cpop_cnt + 5'd1;
                if (!vfirst_hit) begin
                    vfirst_idx = mk[4:0];
                    vfirst_hit = 1'b1;
                end
            end
        end
    end
    wire [31:0] vfirst_res = vfirst_hit ? {27'b0, vfirst_idx} : 32'hFFFFFFFF;

    assign q_scalar = op_vcpop  ? {27'b0, cpop_cnt} :
                      op_vfirst ? vfirst_res :
                                  mvxs_res;   // vmv.x.s
    // vcpop/vfirst write rd even when vl==0 (count 0 / first -1), like vmv.x.s.
    assign q_scalar_we = q_valid && !q_illegal && (op_mvxs || op_vcpop || op_vfirst);

endmodule
`default_nettype wire
