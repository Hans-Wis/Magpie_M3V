# B2 three-way review (2026-07-05) — Codex / Gemini / Grok

## Codex
Reading additional input from stdin...
OpenAI Codex v0.142.5
--------
workdir: /home/edauser/project/SOC/Magpie_M3V
model: gpt-5.5
provider: openai
approval: never
sandbox: workspace-write [workdir, /tmp, $TMPDIR]
reasoning effort: high
reasoning summaries: none
session id: 019f310a-9aa8-79c3-8fce-e9f7302d3e8d
--------
user
Surgical review (no edits; numbered findings). Magpie_M3V vexu.v ADR-0055 Phase-B B2: narrowing shift vnsrl/vnsra (f6 101100/101101, .wv/.wx/.wi) reusing the vnclip wide bus minus round/clip (result = low SEW bits of vs2(2*SEW) >> d, d=b[3:0]@SEW8 / b[4:0]@SEW16; SEW32 narrowing absent=Zve32x no 64b src); and vzext/vsext.vf2/vf4 (OPMVV f6=010010, vs1[2:1]=11 vf2/10 vf4, vs1[0]=sext; vf2 needs SEW>=16, vf4 needs SEW32, vf8 illegal). Both added to known_op, grp_only_illegal (stay <=m1), and the masked vd==v0 illegal check. vnsra uses a self-determined signed wire (nsra_w). Verified: Spike lockstep zve32x 92 commits. Look for LATENT bugs the directed lockstep may miss: (1) narrowing shamt mask width per SEW correct (log2(2*SEW))? (2) vnsra arithmetic sign in BOTH g_nc8/g_nc16? (3) nc_sat set for op_nsr but only aggregated into vxsat under op_nc — confirm op_nsr can't wrongly set vxsat. (4) vext source-lane extraction (vf2 e16 reads vs2[gi*8+:8]; vf2 e32 reads [gi*16+:16]; vf4 e32 reads [gi*8+:8]) — correct low-lane packing & sign/zero extend? (5) vext legality complete (vf8 illegal, vf4@SEW16 illegal, vf2@SEW8 illegal)? (6) decode: vext OPMVV f6=010010 — any collision with existing OPMVV ops at that f6, or with future vsbc (OPIVV same f6)? (7) does vext/nsr need to be OUT of beats_op (they are — confirm they don't accidentally enter is_grp)? Read /tmp/claude-1000/-home-edauser-project-SOC-Magpie-M3V/4fbea76a-d14b-44c4-be15-55488b94edcb/scratchpad/b2_diff.txt and design/cpu_m1/rtl/vexu.v. Report defects with line refs or say none.
codex
I’ll do this as a review only: read the provided diff and the current `vexu.v`, then trace the decode, lane extraction, shift, saturation, and grouping paths against your seven risk points.
exec
/bin/bash -lc "nl -ba design/cpu_m1/rtl/vexu.v | sed -n '1,260p'" in /home/edauser/project/SOC/Magpie_M3V
 succeeded in 0ms:
     1	// =============================================================================
     2	// vexu.v — Zve32x vector EXU, Stage 3B slice (ADR-0036). VLEN=128, ELEN=32.
     3	// -----------------------------------------------------------------------------
     4	// Holds the VRF (32 x 128b) and computes single-register-group vector ops in
     5	// ONE combinational pass at EX ("query"); the 128b result is piped by core.v
     6	// through EX/MEM and EX/WB and committed to the VRF at WB (same kill rules as
     7	// scalar rd writeback), so a trap/IRQ that replays the instruction never sees
     8	// half-updated architectural state (vd==vs source overlap would otherwise not
     9	// be idempotent).
    10	//
    11	// 3B op subset (everything else = q_illegal, honest deferral per ADR-0036):
    12	//   vadd.vv/vx/vi, vsub.vv/vx, vmv.v.v/x/i (vs2 must be v0-encoded 0),
    13	//   vmerge.vvm/vxm/vim, vmv.x.s. LMUL: m1 + fractional (mf2/mf4/mf8-legal
    14	//   configs) only — m2/m4/m8 register groups are deferred (q_illegal).
    15	//   Masked forms (vm=0) other than vmerge do not exist in this subset.
    16	// Tail policy: UNDISTURBED regardless of vta — matches this Spike build, which
    17	// implements tail-agnostic as undisturbed (caught by the gate_42 VRF debug tap:
    18	// Spike left the ta tail at its old value where an all-1s fill diverged).
    19	// Elements below vstart are undisturbed. vstart>=vl or vl==0 -> no VRF update
    20	// at all (core still clears vstart at commit).
    21	// vmv.x.s ignores vl (reads element 0 even when vl==0) and never writes VRF.
    22	// =============================================================================
    23	`default_nettype none
    24	
    25	module vexu #(
    26	    parameter EN_RVV = 0
    27	) (
    28	    input  wire         clk,
    29	    input  wire         resetn,
    30	
    31	    // ---- EX-stage combinational query ----
    32	    input  wire         q_valid,
    33	    input  wire [31:0]  q_instr,
    34	    input  wire [31:0]  q_vtype,     // effective (forwarded) vtype
    35	    input  wire [31:0]  q_vl,        // effective vl
    36	    input  wire [31:0]  q_vstart,    // effective vstart
    37	    input  wire [31:0]  q_rs1,       // forwarded scalar rs1 (OPIVX)
    38	    output wire         q_is_grp,     // S3: multi-beat register-group op (hold like vmem)
    39	    output wire         q_grp_w,      // S3: WB commit writes a register GROUP
    40	    output wire [2:0]   q_grp_parts,  // S3: EMUL parts (2/4) piped for the WB commit
    41	    input  wire         w_grp,        // S3: WB commit is a group write
    42	    input  wire [2:0]   w_parts,
    43	    input  wire [1:0]   q_vxrm,       // S2 (ADR-0049): effective vxrm at EX
    44	    output wire         q_vxsat,      // S2: saturation occurred (active lanes)
    45	    output wire         q_illegal,
    46	    output wire         q_scalar_we, // vmv.x.s -> scalar rd
    47	    output wire [31:0]  q_scalar,
    48	    output wire         q_vrf_we,    // vd gets written at commit
    49	    output wire [4:0]   q_vd,
    50	    output wire [127:0] q_wdata,
    51	
    52	    // ---- WB-stage commit write port (driven by core.v) ----
    53	    input  wire         w_en,
    54	    input  wire [4:0]   w_vd,
    55	    input  wire [127:0] w_data,
    56	
    57	    // ---- 3C unit-stride memory FSM (assemble buffer lives HERE, MEM-side;
    58	    //      the VRF is only written at WB commit like every other vector op).
    59	    //      core.v starts the FSM only when the pipeline behind is DRAINED
    60	    //      (EX/MEM and EX/WB empty), so a mid-op flush/IRQ is impossible by
    61	    //      construction and store beats are never wrong-path. ----
    62	    input  wire         m_start,       // accepted only in IDLE
    63	    input  wire         m_stall,       // core mem_stall freeze (ADR-0005 wrapper)
    64	    input  wire         m_flush,       // pc_redirect/debug (defensive; unreachable mid-op)
    65	    input  wire         m_advance,     // instruction left EX (clear result_valid)
    66	    input  wire [31:0]  m_rdata,       // core d_mem_rdata (wrapper d_rdata_q)
    67	    output wire         q_is_mem,
    68	    output wire         vm_active,
    69	    output wire         vm_result_valid,
    70	    output wire         vm_dvalid,
    71	    output wire         vm_we,
    72	    output wire [31:0]  vm_addr,
    73	    output wire [31:0]  vm_wdata,
    74	    output wire [3:0]   vm_wstrb
    75	);
    76	    // ---------------- decode ----------------
    77	    wire [2:0] f3    = q_instr[14:12];
    78	    wire [5:0] f6    = q_instr[31:26];
    79	    wire       vm    = q_instr[25];
    80	    wire [4:0] vs2_i = q_instr[24:20];
    81	    wire [4:0] vs1_i = q_instr[19:15];
    82	    wire [4:0] vd_i  = q_instr[11:7];
    83	
    84	    wire is_opivv = (f3 == 3'b000);
    85	    wire is_opivi = (f3 == 3'b011);
    86	    wire is_opivx = (f3 == 3'b100);
    87	    wire is_opmvv = (f3 == 3'b010);
    88	
    89	    wire is_opmvx = (f3 == 3'b110);
    90	
    91	    wire op_add   = (f6 == 6'b000000) && (is_opivv || is_opivx || is_opivi);
    92	    wire op_sub   = (f6 == 6'b000010) && (is_opivv || is_opivx);
    93	    wire f6_merge = (f6 == 6'b010111) && (is_opivv || is_opivx || is_opivi);
    94	    wire op_mv    = f6_merge && vm;              // vmv.v.* (vs2 field must be 0)
    95	    wire op_merge = f6_merge && !vm;             // vmerge.v*m (mask = v0)
    96	    wire op_mvxs  = is_opmvv && (f6 == 6'b010000) && (vs1_i == 5'd0) && vm;
    97	    // ---- 3D (the Phase 0 kernel set) ----
    98	    wire op_wmul  = is_opmvv && (f6 == 6'b111011) && vm;   // vwmul.vv  (s*s -> 2*SEW)
    99	    wire op_waddw = is_opmvv && (f6 == 6'b110101) && vm;   // vwadd.wv  (wide vs2 + narrow vs1)
   100	    wire op_redsum= is_opmvv && (f6 == 6'b000000) && vm;   // vredsum.vs (vd[0]=vs1[0]+sum vs2)
   101	    wire op_mvsx  = is_opmvx && (f6 == 6'b010000) && (vs2_i == 5'd0) && vm; // vmv.s.x
   102	    wire op_widen = op_wmul || op_waddw;
   103	
   104	    // ---------------- S1 (ADR-0049): min/max, compares, mask logicals ----------------
   105	    wire op_minu  = (f6 == 6'b000100) && (is_opivv || is_opivx);
   106	    wire op_min   = (f6 == 6'b000101) && (is_opivv || is_opivx);
   107	    wire op_maxu  = (f6 == 6'b000110) && (is_opivv || is_opivx);
   108	    wire op_max   = (f6 == 6'b000111) && (is_opivv || is_opivx);
   109	    wire op_mm    = op_minu || op_min || op_maxu || op_max;
   110	
   111	    // integer compares -> ONE BIT per element into a mask register
   112	    wire f6_cmp   = (f6[5:3] == 3'b011) && (is_opivv || is_opivx || is_opivi);
   113	    wire cmp_form_ok =
   114	        (f6[2:0] == 3'b000 || f6[2:0] == 3'b001) ? 1'b1 :                 // vmseq/vmsne
   115	        (f6[2:0] == 3'b010 || f6[2:0] == 3'b011) ? (is_opivv || is_opivx) : // vmslt[u]
   116	        (f6[2:0] == 3'b100 || f6[2:0] == 3'b101) ? 1'b1 :                 // vmsle[u]
   117	                                                   (is_opivx || is_opivi); // vmsgt[u]
   118	    wire op_cmp   = f6_cmp && cmp_form_ok;
   119	
   120	    // mask-register logicals (bits 0..vl-1); vm bit is 1 in the encoding
   121	    wire op_mlog  = is_opmvv && (f6[5:3] == 3'b011) && vm;
   122	
   123	    // ---------------- S2 (ADR-0049): saturating / averaging / scaling ----------------
   124	    wire op_saddu  = (f6 == 6'b100000) && (is_opivv || is_opivx || is_opivi);
   125	    wire op_sadd   = (f6 == 6'b100001) && (is_opivv || is_opivx || is_opivi);
   126	    wire op_ssubu  = (f6 == 6'b100010) && (is_opivv || is_opivx);
   127	    wire op_ssub   = (f6 == 6'b100011) && (is_opivv || is_opivx);
   128	    wire op_avg    = (is_opmvv || is_opmvx) && (f6[5:2] == 4'b0010);  // vaadd[u]/vasub[u]
   129	    wire avg_sub   = f6[1];                     // 001010/001011 = vasub[u]
   130	    wire avg_signed= f6[0];                     // 001001/001011 = signed
   131	    wire op_ssrl   = (f6 == 6'b101010) && (is_opivv || is_opivx || is_opivi);
   132	    wire op_ssra   = (f6 == 6'b101011) && (is_opivv || is_opivx || is_opivi);
   133	    wire op_nclipu = (f6 == 6'b101110) && (is_opivv || is_opivx || is_opivi);
   134	    wire op_nclip  = (f6 == 6'b101111) && (is_opivv || is_opivx || is_opivi);
   135	    wire op_s2same = op_saddu || op_sadd || op_ssubu || op_ssub ||
   136	                     op_avg || op_ssrl || op_ssra;
   137	    wire op_nc     = op_nclipu || op_nclip;
   138	
   139	    // ---------------- Phase-B B1 (ADR-0055): bitwise / shift / vrsub ----------------
   140	    // same-shape element-wise ALU: join the per-SEW mux + beats_op (m2/m4 groups).
   141	    wire op_and   = (f6 == 6'b001001) && (is_opivv || is_opivx || is_opivi);
   142	    wire op_or    = (f6 == 6'b001010) && (is_opivv || is_opivx || is_opivi);
   143	    wire op_xor   = (f6 == 6'b001011) && (is_opivv || is_opivx || is_opivi);
   144	    wire op_rsub  = (f6 == 6'b000011) && (is_opivx || is_opivi);   // vrsub: b - a (no vv)
   145	    wire op_sll   = (f6 == 6'b100101) && (is_opivv || is_opivx || is_opivi);
   146	    wire op_srl   = (f6 == 6'b101000) && (is_opivv || is_opivx || is_opivi);
   147	    wire op_sra   = (f6 == 6'b101001) && (is_opivv || is_opivx || is_opivi);
   148	    wire op_b1    = op_and || op_or || op_xor || op_rsub ||
   149	                    op_sll || op_srl || op_sra;
   150	
   151	    // ---------------- Phase-B B2a (ADR-0055): narrowing shift (vnsrl/vnsra) ----
   152	    // wide 2*SEW source >> shamt -> SEW dest (low bits). Reuses the vnclip wide
   153	    // datapath minus round/clip. Only SEW8/16 (2*SEW=16/32) — SEW32 narrowing
   154	    // needs a 64-bit source, absent in Zve32x (same rule as vnclip).
   155	    wire op_nsrl  = (f6 == 6'b101100) && (is_opivv || is_opivx || is_opivi);
   156	    wire op_nsra  = (f6 == 6'b101101) && (is_opivv || is_opivx || is_opivi);
   157	    wire op_nsr   = op_nsrl || op_nsra;
   158	
   159	    // ---------------- Phase-B B2b (ADR-0055): vzext/vsext.vf2/vf4 ----------------
   160	    // OPMVV f6=010010 (gated by f3 -> disjoint from OPIVV vsbc, which shares f6).
   161	    // vs1 selects variant: [2:1]=11 vf2 / 10 vf4 / 01 vf8; [0]=1 sign, 0 zero.
   162	    // Zve32x: no e64 source -> vf8 always illegal; vf4 needs SEW32 (src8), vf2
   163	    // needs SEW>=16 (src SEW/2). Extends the low SEW/2 (or SEW/4) source lane.
   164	    wire ext_enc  = is_opmvv && (f6 == 6'b010010) && (vs1_i[4:3] == 2'b00);
   165	    wire ext_vf2  = (vs1_i[2:1] == 2'b11);
   166	    wire ext_vf4  = (vs1_i[2:1] == 2'b10);
   167	    wire ext_sext = vs1_i[0];
   168	    wire op_vext  = ext_enc &&
   169	                    ((ext_vf2 && ((vsew == 3'b001) || (vsew == 3'b010))) ||
   170	                     (ext_vf4 &&  (vsew == 3'b010)));
   171	
   172	    // ---------------- config legality ----------------
   173	    wire        vill  = q_vtype[31];
   174	    wire [2:0]  vlmul = q_vtype[2:0];
   175	    wire [2:0]  vsew  = q_vtype[5:3];
   176	    // S3 (ADR-0049): m2/m4 register groups execute as internal multi-beat with
   177	    // an atomic group commit at WB; m8 stays deferred-illegal.
   178	    wire lmul_m2   = (vlmul == 3'b001);
   179	    wire lmul_m4   = (vlmul == 3'b010);
   180	    wire lmul_m8   = (vlmul == 3'b011);
   181	    wire [2:0] grp_parts = lmul_m4 ? 3'd4 : lmul_m2 ? 3'd2 : 3'd1;
   182	    wire cfg_illegal = vill || lmul_m8;
   183	
   184	    // ---------------- 3C unit-stride vector load/store decode ----------------
   185	    wire is_vload  = (q_instr[6:0] == 7'b0000111);   // LOAD-FP opcode space
   186	    wire is_vstore = (q_instr[6:0] == 7'b0100111);   // STORE-FP opcode space
   187	    wire is_vmem   = (EN_RVV != 0) && (is_vload || is_vstore);
   188	    assign q_is_mem = q_valid && is_vmem;
   189	    assign q_is_grp = q_valid && is_grp && !q_illegal;    // hold/beats (incl. cmp)
   190	    // WB group WRITE excludes mask-dest compares (single-register dest)
   191	    assign q_grp_w  = q_valid && is_grp && !op_cmp && !q_illegal;
   192	    assign q_grp_parts = grp_parts;
   193	    // width field: 000=EEW8, 101=EEW16, 110=EEW32 (010 = scalar FLW/FSW: no F -> illegal)
   194	    wire [1:0] eew_sel = (f3 == 3'b000) ? 2'd0 :
   195	                         (f3 == 3'b101) ? 2'd1 :
   196	                         (f3 == 3'b110) ? 2'd2 : 2'd3;
   197	    wire mem_enc_ok = (eew_sel != 2'd3) && vm &&              // unmasked unit-stride only
   198	                      (q_instr[28:26] == 3'b000) &&           // mew=0, mop=00 (unit-stride)
   199	                      (q_instr[24:20] == 5'b00000) &&         // lumop/sumop = 0
   200	                      (q_instr[31:29] == 3'b000);             // nf=0 (no segments)
   201	    // EMUL = (EEW/SEW)*LMUL must be <= 1 here <=> vlmax elements * EEW bytes <= 16
   202	    wire [2:0] frac_sh  = (vlmul == 3'b111) ? 3'd1 :
   203	                          (vlmul == 3'b110) ? 3'd2 :
   204	                          (vlmul == 3'b101) ? 3'd3 : 3'd0;
   205	    // S3: integer LMUL multiplies vlmax — EMUL = EEW/SEW*LMUL must stay <= 1
   206	    // (group-EMUL memory ops remain out of scope; the m2/m4 configs where the
   207	    // EEW is narrow enough, e.g. vle8 at e16/m2, stay legal)
   208	    wire [1:0] int_sh   = lmul_m4 ? 2'd2 : lmul_m2 ? 2'd1 : 2'd0;
   209	    wire [6:0] vlmax_el = ({2'b0, 5'd16 >> vsew} << int_sh) >> frac_sh;
   210	    wire [8:0] mem_span = {2'b0, vlmax_el} << eew_sel;        // bytes touched at vlmax
   211	    wire emul_ok  = (mem_span <= 9'd16);
   212	    // element alignment: base aligned to EEW => every element aligned (unit stride)
   213	    wire align_ok = (eew_sel == 2'd0) ||
   214	                    ((eew_sel == 2'd1) && !q_rs1[0]) ||
   215	                    ((eew_sel == 2'd2) && (q_rs1[1:0] == 2'b00));
   216	    wire mem_illegal = !mem_enc_ok || !emul_ok || !align_ok;
   217	
   218	    // 3D widening legality: dst EEW = 2*SEW needs SEW<=16 and dst EMUL = 2*LMUL
   219	    // <= 1 (single register group) => LMUL must be fractional. Overlap (match
   220	    // Spike require_noover): a widening dest may not overlap a NARROWER source;
   221	    // vwadd.wv vd==vs2 is legal (same EEW — the kernel's accumulate uses it).
   222	    wire widen_lmul_ok = (vlmul == 3'b111) || (vlmul == 3'b110) || (vlmul == 3'b101);
   223	    wire widen_illegal = op_widen &&
   224	                         (!widen_lmul_ok || (vsew == 3'b010) ||
   225	                          (vd_i == vs1_i) ||
   226	                          (op_wmul && (vd_i == vs2_i)));
   227	
   228	    wire known_op = op_add || op_sub || op_mv || op_merge || op_mvxs ||
   229	                    op_wmul || op_waddw || op_redsum || op_mvsx ||
   230	                    op_mm || op_cmp || op_mlog || op_s2same || op_nc || op_b1 ||
   231	                    op_nsr || op_vext;
   232	    // ops that iterate register-group parts (compares read groups, write ONE
   233	    // mask register); widening/narrowing/reductions stay <= m1 (their own
   234	    // LMUL rules) and vmv.x.s/vmv.s.x touch element 0 only.
   235	    wire beats_op  = op_add || op_sub || op_mv || op_merge || op_mm ||
   236	                     op_s2same || op_cmp || op_b1;
   237	    // NOTE: memory opcodes alias the f6-based arith decodes (every other use
   238	    // site is guarded by an is_vmem priority mux) — exclude them here too.
   239	    wire is_grp    = (grp_parts != 3'd1) && beats_op && !is_vmem;
   240	    wire grp_only_illegal = (grp_parts != 3'd1) &&
   241	        (op_widen || op_redsum || op_nc || op_nsr || op_vext ||
   242	         !beats_op && !op_mvxs && !op_mvsx && !op_mlog && !is_vmem);
   243	    // register-group alignment (vd for writes except mask-dest; sources)
   244	    wire [4:0] grp_amask = lmul_m4 ? 5'd3 : lmul_m2 ? 5'd1 : 5'd0;
   245	    wire grp_align_illegal = is_grp &&
   246	        ((!op_cmp && ((vd_i & grp_amask[4:0]) != 5'd0)) ||
   247	         ((vs2_i & grp_amask) != 5'd0) ||
   248	         // .vv source includes OPMVV vector-vector forms (vaadd family) —
   249	         // Codex S3 finding: is_opivv alone missed them
   250	         ((is_opivv || is_opmvv) && ((vs1_i & grp_amask) != 5'd0)));
   251	    // narrowing legality mirrors widening (source EMUL = 2*LMUL <= 1); the
   252	    // low-part destination overlap (vd == vs2) is spec-legal for narrowing.
   253	    wire nc_illegal = (op_nc || op_nsr) && (!widen_lmul_ok || (vsew == 3'b010));
   254	    // vstart!=0 on arithmetic = illegal (spec-allowed choice; MATCHES SPIKE —
   255	    // caught by gate_42 lockstep: Spike trapped where the RTL executed).
   256	    // Loads/stores are resumable: vstart is honored (start element), not illegal.
   257	    assign q_illegal = q_valid && ((EN_RVV == 0) || cfg_illegal ||
   258	                       (is_vmem ? mem_illegal :
   259	                        (!known_op ||
   260	                         (q_vstart != 32'h0) ||

exec
/bin/bash -lc "sed -n '1,260p' /tmp/claude-1000/-home-edauser-project-SOC-Magpie-M3V/4fbea76a-d14b-44c4-be15-55488b94edcb/scratchpad/b2_diff.txt" in /home/edauser/project/SOC/Magpie_M3V
 succeeded in 0ms:
diff --git a/design/cpu_m1/rtl/vexu.v b/design/cpu_m1/rtl/vexu.v
index e0f4240..767bb8b 100644
--- a/design/cpu_m1/rtl/vexu.v
+++ b/design/cpu_m1/rtl/vexu.v
@@ -148,6 +148,27 @@ module vexu #(
     wire op_b1    = op_and || op_or || op_xor || op_rsub ||
                     op_sll || op_srl || op_sra;
 
+    // ---------------- Phase-B B2a (ADR-0055): narrowing shift (vnsrl/vnsra) ----
+    // wide 2*SEW source >> shamt -> SEW dest (low bits). Reuses the vnclip wide
+    // datapath minus round/clip. Only SEW8/16 (2*SEW=16/32) — SEW32 narrowing
+    // needs a 64-bit source, absent in Zve32x (same rule as vnclip).
+    wire op_nsrl  = (f6 == 6'b101100) && (is_opivv || is_opivx || is_opivi);
+    wire op_nsra  = (f6 == 6'b101101) && (is_opivv || is_opivx || is_opivi);
+    wire op_nsr   = op_nsrl || op_nsra;
+
+    // ---------------- Phase-B B2b (ADR-0055): vzext/vsext.vf2/vf4 ----------------
+    // OPMVV f6=010010 (gated by f3 -> disjoint from OPIVV vsbc, which shares f6).
+    // vs1 selects variant: [2:1]=11 vf2 / 10 vf4 / 01 vf8; [0]=1 sign, 0 zero.
+    // Zve32x: no e64 source -> vf8 always illegal; vf4 needs SEW32 (src8), vf2
+    // needs SEW>=16 (src SEW/2). Extends the low SEW/2 (or SEW/4) source lane.
+    wire ext_enc  = is_opmvv && (f6 == 6'b010010) && (vs1_i[4:3] == 2'b00);
+    wire ext_vf2  = (vs1_i[2:1] == 2'b11);
+    wire ext_vf4  = (vs1_i[2:1] == 2'b10);
+    wire ext_sext = vs1_i[0];
+    wire op_vext  = ext_enc &&
+                    ((ext_vf2 && ((vsew == 3'b001) || (vsew == 3'b010))) ||
+                     (ext_vf4 &&  (vsew == 3'b010)));
+
     // ---------------- config legality ----------------
     wire        vill  = q_vtype[31];
     wire [2:0]  vlmul = q_vtype[2:0];
@@ -206,7 +227,8 @@ module vexu #(
 
     wire known_op = op_add || op_sub || op_mv || op_merge || op_mvxs ||
                     op_wmul || op_waddw || op_redsum || op_mvsx ||
-                    op_mm || op_cmp || op_mlog || op_s2same || op_nc || op_b1;
+                    op_mm || op_cmp || op_mlog || op_s2same || op_nc || op_b1 ||
+                    op_nsr || op_vext;
     // ops that iterate register-group parts (compares read groups, write ONE
     // mask register); widening/narrowing/reductions stay <= m1 (their own
     // LMUL rules) and vmv.x.s/vmv.s.x touch element 0 only.
@@ -216,7 +238,7 @@ module vexu #(
     // site is guarded by an is_vmem priority mux) — exclude them here too.
     wire is_grp    = (grp_parts != 3'd1) && beats_op && !is_vmem;
     wire grp_only_illegal = (grp_parts != 3'd1) &&
-        (op_widen || op_redsum || op_nc ||
+        (op_widen || op_redsum || op_nc || op_nsr || op_vext ||
          !beats_op && !op_mvxs && !op_mvsx && !op_mlog && !is_vmem);
     // register-group alignment (vd for writes except mask-dest; sources)
     wire [4:0] grp_amask = lmul_m4 ? 5'd3 : lmul_m2 ? 5'd1 : 5'd0;
@@ -228,7 +250,7 @@ module vexu #(
          ((is_opivv || is_opmvv) && ((vs1_i & grp_amask) != 5'd0)));
     // narrowing legality mirrors widening (source EMUL = 2*LMUL <= 1); the
     // low-part destination overlap (vd == vs2) is spec-legal for narrowing.
-    wire nc_illegal = op_nc && (!widen_lmul_ok || (vsew == 3'b010));
+    wire nc_illegal = (op_nc || op_nsr) && (!widen_lmul_ok || (vsew == 3'b010));
     // vstart!=0 on arithmetic = illegal (spec-allowed choice; MATCHES SPIKE —
     // caught by gate_42 lockstep: Spike trapped where the RTL executed).
     // Loads/stores are resumable: vstart is honored (start element), not illegal.
@@ -244,7 +266,7 @@ module vexu #(
                          // targeting v0 remain legal.
                          nc_illegal || grp_only_illegal || grp_align_illegal ||
                          ((op_add || op_sub || op_mm || op_s2same || op_nc ||
-                           op_b1) &&
+                           op_b1 || op_nsr || op_vext) &&
                           !vm && (vd_i == 5'd0)))));
 
     // ---------------- VRF ----------------
@@ -578,6 +600,7 @@ module vexu #(
     wire [7:0]  nc_sat8;
     wire [3:0]  nc_sat16;
     wire [127:0] res_s2_8, res_s2_16, res_s2_32, res_nc8, res_nc16;
+    wire [127:0] res_ext16, res_ext32;   // B2b vzext/vsext
 
     generate
         for (gi = 0; gi < 16; gi = gi + 1) begin : g_s2_8
@@ -733,11 +756,15 @@ module vexu #(
                        (q_vxrm == 2'd2) ? 1'b0 :
                                           (~b_d & any_lo);
             wire signed [15:0] vs = v;
+            wire        [15:0] nsrl_w = v >> d;            // B2a vnsrl: logical
+            wire signed [15:0] nsra_w = vs >>> d;          // B2a vnsra: arithmetic (self-det signed)
             wire signed [16:0] rs = {vs[15], $unsigned(vs >>> d)} + {16'b0, inc};
             wire        [16:0] ru = {1'b0, v >> d} + {16'b0, inc};
             wire s_ov = (rs > 17'sd127) || (rs < -17'sd128);
             wire u_ov = (ru > 17'd255);
-            wire [7:0] r = op_nclip ? (s_ov ? (rs[16] ? 8'h80 : 8'h7F) : rs[7:0])
+            wire [7:0] r = op_nsrl  ? nsrl_w[7:0] :
+                           op_nsra  ? nsra_w[7:0] :
+                           op_nclip ? (s_ov ? (rs[16] ? 8'h80 : 8'h7F) : rs[7:0])
                                     : (u_ov ? 8'hFF : ru[7:0]);
             wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
             assign res_nc8[gi*8 +: 8] = en ? r : vd_old[gi*8 +: 8];
@@ -757,16 +784,37 @@ module vexu #(
                        (q_vxrm == 2'd2) ? 1'b0 :
                                           (~b_d & any_lo);
             wire signed [31:0] vs = v;
+            wire        [31:0] nsrl_w = v >> d;
+            wire signed [31:0] nsra_w = vs >>> d;
             wire signed [32:0] rs = {vs[31], $unsigned(vs >>> d)} + {32'b0, inc};
             wire        [32:0] ru = {1'b0, v >> d} + {32'b0, inc};
             wire s_ov = (rs > 33'sd32767) || (rs < -33'sd32768);
             wire u_ov = (ru > 33'd65535);
-            wire [15:0] r = op_nclip ? (s_ov ? (rs[32] ? 16'h8000 : 16'h7FFF) : rs[15:0])
+            wire [15:0] r = op_nsrl  ? nsrl_w[15:0] :
+                            op_nsra  ? nsra_w[15:0] :
+                            op_nclip ? (s_ov ? (rs[32] ? 16'h8000 : 16'h7FFF) : rs[15:0])
                                      : (u_ov ? 16'hFFFF : ru[15:0]);
             wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
             assign res_nc16[gi*16 +: 16] = en ? r : vd_old[gi*16 +: 16];
             assign nc_sat16[gi] = en && (op_nclip ? s_ov : u_ov);
         end
+
+        // ---- B2b vzext/vsext: SEW/2 (vf2) or SEW/4 (vf4) source -> SEW dest ----
+        for (gi = 0; gi < 8; gi = gi + 1) begin : g_ext16   // dst e16, vf2 (src 8b)
+            wire [7:0]  s = vs2_data[gi*8 +: 8];
+            wire [15:0] e = ext_sext ? {{8{s[7]}}, s} : {8'b0, s};
+            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
+            assign res_ext16[gi*16 +: 16] = en ? e : vd_old[gi*16 +: 16];
+        end
+        for (gi = 0; gi < 4; gi = gi + 1) begin : g_ext32   // dst e32, vf2 (src 16b) / vf4 (src 8b)
+            wire [15:0] s2 = vs2_data[gi*16 +: 16];
+            wire [7:0]  s4 = vs2_data[gi*8 +: 8];
+            wire [31:0] e2 = ext_sext ? {{16{s2[15]}}, s2} : {16'b0, s2};
+            wire [31:0] e4 = ext_sext ? {{24{s4[7]}},  s4} : {24'b0, s4};
+            wire [31:0] e  = ext_vf4 ? e4 : e2;
+            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
+            assign res_ext32[gi*32 +: 32] = en ? e : vd_old[gi*32 +: 32];
+        end
     endgenerate
 
     // narrowing writes at most 8 (SEW8) / 4 (SEW16) dst elements under the
@@ -826,7 +874,8 @@ module vexu #(
                      op_cmp  ? res_cmp :
                      op_mlog ? res_mlog :
                      op_s2same ? res_s2 :
-                     op_nc  ? res_nc :
+                     (op_nc || op_nsr) ? res_nc :
+                     op_vext ? ((vsew == 3'b001) ? res_ext16 : res_ext32) :
                      op_widen ? ((vsew == 3'b000) ? res_w8 : res_w16) :
                      op_redsum ? res_red :
                      op_mvsx ? res_sx :

exec
/bin/bash -lc "nl -ba design/cpu_m1/rtl/vexu.v | sed -n '260,620p'" in /home/edauser/project/SOC/Magpie_M3V
 succeeded in 0ms:
   260	                         (q_vstart != 32'h0) ||
   261	                         widen_illegal ||
   262	                         (op_mv && (vs2_i != 5'd0)) ||
   263	                         (op_merge && (vd_i == 5'd0)) ||
   264	                         // S1 (Codex, Spike-confirmed): a MASKED body op may not
   265	                         // write v0 (dest overlaps the mask); mask-DEST compares
   266	                         // targeting v0 remain legal.
   267	                         nc_illegal || grp_only_illegal || grp_align_illegal ||
   268	                         ((op_add || op_sub || op_mm || op_s2same || op_nc ||
   269	                           op_b1 || op_nsr || op_vext) &&
   270	                          !vm && (vd_i == 5'd0)))));
   271	
   272	    // ---------------- VRF ----------------
   273	    reg [127:0] vrf [0:31];
   274	    // S3: during group beats the datapath sees part p of each operand; the
   275	    // element window and v0 mask bits shift by the part base. m1 ops see p=0.
   276	    reg  [1:0]   grp_p;
   277	    wire [4:0]   part_off = {3'b0, grp_p};
   278	    wire [127:0] vs1_data = vrf[vs1_i + part_off];
   279	    wire [127:0] vs2_data = vrf[vs2_i + part_off];
   280	    wire [127:0] v0_data  = vrf[0];
   281	    wire [127:0] vd_old   = vrf[vd_i + part_off];
   282	    // elements per register at the current SEW; part base in ELEMENTS
   283	    wire [5:0]  nl_el     = (vsew == 3'b000) ? 6'd16 : (vsew == 3'b001) ? 6'd8 : 6'd4;
   284	    wire [7:0]  elem_base = {2'b0, nl_el} * {6'b0, grp_p};
   285	    // per-lane views: lane gi maps to architectural element (elem_base + gi)
   286	    wire [127:0] v0_view   = v0_data >> elem_base;
   287	    wire [31:0]  vl_view   = (q_vl > {24'b0, elem_base}) ? (q_vl - {24'b0, elem_base}) : 32'h0;
   288	    wire [31:0]  vst_view  = (q_vstart > {24'b0, elem_base}) ? (q_vstart - {24'b0, elem_base}) : 32'h0;
   289	
   290	    wire [127:0] cmpd_old  = vrf[vd_i];          // mask-dest reads its own reg
   291	    wire [127:0] cmpd_view = cmpd_old >> elem_base;
   292	
   293	    // S3 staging: computed parts await the atomic group commit at WB
   294	    reg [127:0] grp_stage [0:3];
   295	    reg [127:0] grp_mask_acc;      // compare-to-mask accumulation across parts
   296	    reg         grp_sat_q;
   297	
   298	    always @(posedge clk) begin
   299	        if (w_en) begin
   300	            vrf[w_vd] <= w_data;
   301	            // atomic group commit: parts 1..N-1 from staging (part 0 rides the
   302	            // pipeline as the architectural value; drained-start guarantees
   303	            // staging still belongs to this instruction)
   304	            if (w_grp) begin
   305	                vrf[w_vd + 5'd1] <= grp_stage[1];
   306	                if (w_parts == 3'd4) begin
   307	                    vrf[w_vd + 5'd2] <= grp_stage[2];
   308	                    vrf[w_vd + 5'd3] <= grp_stage[3];
   309	                end
   310	            end
   311	        end
   312	    end
   313	
   314	    // ---------------- operand B (vector / scalar / imm broadcast) ----------------
   315	    wire [31:0] imm_sext = {{27{q_instr[19]}}, q_instr[19:15]};
   316	    wire [31:0] scalar_b = is_opivi ? imm_sext : q_rs1;
   317	
   318	    // ---------------- per-SEW element datapaths ----------------
   319	    genvar gi;
   320	    wire [127:0] res8, res16, res32;
   321	
   322	    generate
   323	        for (gi = 0; gi < 16; gi = gi + 1) begin : g_sew8
   324	            wire [7:0] a = vs2_data[gi*8 +: 8];
   325	            wire [7:0] b = is_opivv ? vs1_data[gi*8 +: 8] : scalar_b[7:0];
   326	            wire       m = v0_view[gi];
   327	            wire signed [7:0] as = a, bs = b;
   328	            wire signed [7:0] sra_r = as >>> b[2:0];   // self-determined signed -> arithmetic
   329	            wire [7:0] r = op_add   ? (a + b) :
   330	                           op_sub   ? (a - b) :
   331	                           op_rsub  ? (b - a) :             // B1: vrsub
   332	                           op_and   ? (a & b) :
   333	                           op_or    ? (a | b) :
   334	                           op_xor   ? (a ^ b) :
   335	                           op_sll   ? (a << b[2:0]) :
   336	                           op_srl   ? (a >> b[2:0]) :
   337	                           op_sra   ? sra_r :          
   338	                           op_min   ? ((as < bs) ? a : b) :
   339	                           op_minu  ? ((a < b)  ? a : b) :
   340	                           op_max   ? ((as > bs) ? a : b) :
   341	                           op_maxu  ? ((a > b)  ? a : b) :
   342	                           op_merge ? (m ? b : a) :
   343	                                      b;                   // vmv.v.*
   344	            wire active = (gi >= vst_view) && (gi < vl_view) &&
   345	                          (op_merge || vm || m);           // S1: masked-off = undisturbed
   346	            assign res8[gi*8 +: 8] = active ? r : vd_old[gi*8 +: 8];
   347	        end
   348	        for (gi = 0; gi < 8; gi = gi + 1) begin : g_sew16
   349	            wire [15:0] a = vs2_data[gi*16 +: 16];
   350	            wire [15:0] b = is_opivv ? vs1_data[gi*16 +: 16] : scalar_b[15:0];
   351	            wire        m = v0_view[gi];
   352	            wire signed [15:0] as = a, bs = b;
   353	            wire signed [15:0] sra_r = as >>> b[3:0];
   354	            wire [15:0] r = op_add   ? (a + b) :
   355	                            op_sub   ? (a - b) :
   356	                            op_rsub  ? (b - a) :
   357	                            op_and   ? (a & b) :
   358	                            op_or    ? (a | b) :
   359	                            op_xor   ? (a ^ b) :
   360	                            op_sll   ? (a << b[3:0]) :
   361	                            op_srl   ? (a >> b[3:0]) :
   362	                            op_sra   ? sra_r :          
   363	                            op_min   ? ((as < bs) ? a : b) :
   364	                            op_minu  ? ((a < b)  ? a : b) :
   365	                            op_max   ? ((as > bs) ? a : b) :
   366	                            op_maxu  ? ((a > b)  ? a : b) :
   367	                            op_merge ? (m ? b : a) :
   368	                                       b;
   369	            wire active = (gi >= vst_view) && (gi < vl_view) &&
   370	                          (op_merge || vm || m);
   371	            assign res16[gi*16 +: 16] = active ? r : vd_old[gi*16 +: 16];
   372	        end
   373	        for (gi = 0; gi < 4; gi = gi + 1) begin : g_sew32
   374	            wire [31:0] a = vs2_data[gi*32 +: 32];
   375	            wire [31:0] b = is_opivv ? vs1_data[gi*32 +: 32] : scalar_b;
   376	            wire        m = v0_view[gi];
   377	            wire signed [31:0] as = a, bs = b;
   378	            wire signed [31:0] sra_r = as >>> b[4:0];
   379	            wire [31:0] r = op_add   ? (a + b) :
   380	                            op_sub   ? (a - b) :
   381	                            op_rsub  ? (b - a) :
   382	                            op_and   ? (a & b) :
   383	                            op_or    ? (a | b) :
   384	                            op_xor   ? (a ^ b) :
   385	                            op_sll   ? (a << b[4:0]) :
   386	                            op_srl   ? (a >> b[4:0]) :
   387	                            op_sra   ? sra_r :          
   388	                            op_min   ? ((as < bs) ? a : b) :
   389	                            op_minu  ? ((a < b)  ? a : b) :
   390	                            op_max   ? ((as > bs) ? a : b) :
   391	                            op_maxu  ? ((a > b)  ? a : b) :
   392	                            op_merge ? (m ? b : a) :
   393	                                       b;
   394	            wire active = (gi >= vst_view) && (gi < vl_view) &&
   395	                          (op_merge || vm || m);
   396	            assign res32[gi*32 +: 32] = active ? r : vd_old[gi*32 +: 32];
   397	        end
   398	
   399	        // ---- S1: compares -> mask bits (per SEW element count) ----
   400	        for (gi = 0; gi < 16; gi = gi + 1) begin : g_cmp8
   401	            wire [7:0] a = vs2_data[gi*8 +: 8];
   402	            wire [7:0] b = is_opivv ? vs1_data[gi*8 +: 8] : scalar_b[7:0];
   403	            wire signed [7:0] as = a, bs = b;
   404	            wire c = (f6[2:0] == 3'b000) ? (a == b)  :
   405	                     (f6[2:0] == 3'b001) ? (a != b)  :
   406	                     (f6[2:0] == 3'b010) ? (a < b)   :
   407	                     (f6[2:0] == 3'b011) ? (as < bs) :
   408	                     (f6[2:0] == 3'b100) ? (a <= b)  :
   409	                     (f6[2:0] == 3'b101) ? (as <= bs):
   410	                     (f6[2:0] == 3'b110) ? (a > b)   :
   411	                                           (as > bs);
   412	            wire en = (gi < vl_view) && (vm || v0_view[gi]);
   413	            assign cmp_bits8[gi] = en ? c : cmpd_view[gi];
   414	        end
   415	        for (gi = 0; gi < 8; gi = gi + 1) begin : g_cmp16
   416	            wire [15:0] a = vs2_data[gi*16 +: 16];
   417	            wire [15:0] b = is_opivv ? vs1_data[gi*16 +: 16] : scalar_b[15:0];
   418	            wire signed [15:0] as = a, bs = b;
   419	            wire c = (f6[2:0] == 3'b000) ? (a == b)  :
   420	                     (f6[2:0] == 3'b001) ? (a != b)  :
   421	                     (f6[2:0] == 3'b010) ? (a < b)   :
   422	                     (f6[2:0] == 3'b011) ? (as < bs) :
   423	                     (f6[2:0] == 3'b100) ? (a <= b)  :
   424	                     (f6[2:0] == 3'b101) ? (as <= bs):
   425	                     (f6[2:0] == 3'b110) ? (a > b)   :
   426	                                           (as > bs);
   427	            wire en = (gi < vl_view) && (vm || v0_view[gi]);
   428	            assign cmp_bits16[gi] = en ? c : cmpd_view[gi];
   429	        end
   430	        for (gi = 0; gi < 4; gi = gi + 1) begin : g_cmp32
   431	            wire [31:0] a = vs2_data[gi*32 +: 32];
   432	            wire [31:0] b = is_opivv ? vs1_data[gi*32 +: 32] : scalar_b;
   433	            wire signed [31:0] as = a, bs = b;
   434	            wire c = (f6[2:0] == 3'b000) ? (a == b)  :
   435	                     (f6[2:0] == 3'b001) ? (a != b)  :
   436	                     (f6[2:0] == 3'b010) ? (a < b)   :
   437	                     (f6[2:0] == 3'b011) ? (as < bs) :
   438	                     (f6[2:0] == 3'b100) ? (a <= b)  :
   439	                     (f6[2:0] == 3'b101) ? (as <= bs):
   440	                     (f6[2:0] == 3'b110) ? (a > b)   :
   441	                                           (as > bs);
   442	            wire en = (gi < vl_view) && (vm || v0_view[gi]);
   443	            assign cmp_bits32[gi] = en ? c : cmpd_view[gi];
   444	        end
   445	    endgenerate
   446	
   447	    // ---------------- 3C memory FSM (2 cycles/element: ISSUE -> CAP) ----------------
   448	    localparam [1:0] VM_IDLE = 2'd0, VM_ISSUE = 2'd1, VM_CAP = 2'd2, VM_GRP = 2'd3;
   449	    reg [1:0]   vm_state;
   450	    reg [4:0]   vm_idx;
   451	    reg [127:0] vm_buf;          // assemble buffer (loads); seeded with vd_old
   452	    reg         vm_done_r;
   453	
   454	    wire [4:0] vm_vl     = q_vl[4:0];       // <=16 elements under EMUL<=1
   455	    wire [4:0] vm_vstart = q_vstart[4:0];
   456	    wire       vm_none   = (q_vstart >= q_vl);
   457	    wire [4:0] vm_last   = vm_vl - 5'd1;
   458	
   459	    assign vm_active       = (vm_state != VM_IDLE);
   460	    assign vm_result_valid = vm_done_r;
   461	    assign vm_dvalid       = (vm_state == VM_ISSUE);
   462	    assign vm_we           = is_vstore;
   463	    assign vm_addr         = q_rs1 + ({27'b0, vm_idx} << eew_sel);
   464	    // store element from vs3 (= vd field) placed on its byte lane via wstrb
   465	    wire [7:0]  st8  = vd_old[{vm_idx[3:0], 3'b000} +: 8];
   466	    wire [15:0] st16 = vd_old[{vm_idx[2:0], 4'b0000} +: 16];
   467	    wire [31:0] st32 = vd_old[{vm_idx[1:0], 5'b00000} +: 32];
   468	    assign vm_wdata = (eew_sel == 2'd0) ? {4{st8}} :
   469	                      (eew_sel == 2'd1) ? {2{st16}} : st32;
   470	    assign vm_wstrb = (eew_sel == 2'd0) ? (4'b0001 << vm_addr[1:0]) :
   471	                      (eew_sel == 2'd1) ? (vm_addr[1] ? 4'b1100 : 4'b0011) : 4'b1111;
   472	    // load lane extract for the beat just captured (idx unchanged ISSUE->CAP)
   473	    wire [7:0]  ld8  = m_rdata[{vm_addr[1:0], 3'b000} +: 8];
   474	    wire [15:0] ld16 = vm_addr[1] ? m_rdata[31:16] : m_rdata[15:0];
   475	
   476	    always @(posedge clk) begin
   477	        if (!resetn || m_flush) begin
   478	            vm_state  <= VM_IDLE;
   479	            vm_done_r <= 1'b0;
   480	            grp_p     <= 2'd0;
   481	        end else if (m_advance && vm_done_r) begin
   482	            vm_done_r <= 1'b0;                       // instruction left EX
   483	        end else if (!m_stall) begin
   484	            case (vm_state)
   485	                VM_IDLE: if (m_start && !vm_done_r) begin
   486	                    if (is_grp) begin
   487	                        // S3: register-group beats — one part per cycle into
   488	                        // staging; drained-start means nothing else vector is
   489	                        // in flight until the WB group commit.
   490	                        if (vm_none) begin
   491	                            vm_done_r <= 1'b1;
   492	                        end else begin
   493	                            grp_p     <= 2'd0;
   494	                            grp_sat_q <= 1'b0;
   495	                            vm_state  <= VM_GRP;
   496	                        end
   497	                    end else if (vm_none) begin
   498	                        vm_done_r <= 1'b1;           // vl==0 / vstart>=vl: no beats
   499	                    end else begin
   500	                        vm_buf   <= vd_old;          // undisturbed below-vstart + tail
   501	                        vm_idx   <= vm_vstart;
   502	                        vm_state <= VM_ISSUE;
   503	                    end
   504	                end
   505	
   506	                VM_GRP: begin
   507	                    grp_stage[grp_p] <= part_res;
   508	                    grp_sat_q <= grp_sat_q | part_sat_or;
   509	                    if (op_cmp)
   510	                        grp_mask_acc <= (grp_mask_acc & ~(mask_nl << elem_base)) |
   511	                                        ({112'b0, cmp_seg} << elem_base);
   512	                    if ({1'b0, grp_p} + 3'd1 == grp_parts) begin
   513	                        grp_p     <= 2'd0;
   514	                        vm_state  <= VM_IDLE;
   515	                        vm_done_r <= 1'b1;
   516	                    end else
   517	                        grp_p <= grp_p + 2'd1;
   518	                end
   519	                VM_ISSUE: vm_state <= VM_CAP;        // beat fired this cycle
   520	                VM_CAP: begin
   521	                    if (is_vload) begin
   522	                        case (eew_sel)
   523	                            2'd0: vm_buf[{vm_idx[3:0], 3'b000} +: 8]       <= ld8;
   524	                            2'd1: vm_buf[{vm_idx[2:0], 4'b0000} +: 16]     <= ld16;
   525	                            default: vm_buf[{vm_idx[1:0], 5'b00000} +: 32] <= m_rdata;
   526	                        endcase
   527	                    end
   528	                    if (vm_idx == vm_last) begin
   529	                        vm_state  <= VM_IDLE;
   530	                        vm_done_r <= 1'b1;
   531	                    end else begin
   532	                        vm_idx   <= vm_idx + 5'd1;
   533	                        vm_state <= VM_ISSUE;
   534	                    end
   535	                end
   536	                default: vm_state <= VM_IDLE;
   537	            endcase
   538	        end
   539	    end
   540	
   541	    // ---------------- 3D widening datapaths (dst lanes are 2*SEW wide) ----------------
   542	    // SEW=8 -> 8 x 16-bit dst lanes; SEW=16 -> 4 x 32-bit dst lanes. Active dst
   543	    // lane i covers element i (i < vl); tail lanes undisturbed.
   544	    wire [127:0] res_w8, res_w16;
   545	    generate
   546	        for (gi = 0; gi < 8; gi = gi + 1) begin : g_w8
   547	            wire signed [7:0]  a = vs2_data[gi*8 +: 8];    // narrow src (wmul)
   548	            wire signed [7:0]  n = vs1_data[gi*8 +: 8];    // narrow src (both)
   549	            wire signed [15:0] w = vs2_data[gi*16 +: 16];  // wide src (wadd.wv)
   550	            // keep each result in an ALL-SIGNED expression (a conditional with an
   551	            // unsigned concat branch silently zero-extends: caught by lockstep)
   552	            wire signed [15:0] prod = a * n;
   553	            wire signed [15:0] wsum = w + {{8{n[7]}}, n};   // equal-width add: bit-exact, no implicit expand
   554	            wire        [15:0] r    = op_wmul ? prod : wsum;
   555	            wire active = (gi < q_vl);
   556	            assign res_w8[gi*16 +: 16] = active ? r : vd_old[gi*16 +: 16];
   557	        end
   558	        for (gi = 0; gi < 4; gi = gi + 1) begin : g_w16
   559	            wire signed [15:0] a = vs2_data[gi*16 +: 16];
   560	            wire signed [15:0] n = vs1_data[gi*16 +: 16];
   561	            wire signed [31:0] w = vs2_data[gi*32 +: 32];
   562	            wire signed [31:0] prod = a * n;
   563	            wire signed [31:0] wsum = w + {{16{n[15]}}, n};
   564	            wire        [31:0] r    = op_wmul ? prod : wsum;
   565	            wire active = (gi < q_vl);
   566	            assign res_w16[gi*32 +: 32] = active ? r : vd_old[gi*32 +: 32];
   567	        end
   568	    endgenerate
   569	
   570	    // ---------------- 3D vredsum.vs (vd[0] = vs1[0] + sum of active vs2) ----------------
   571	    reg [31:0] red_sum;
   572	    integer rk;
   573	    always @* begin
   574	        red_sum = (vsew == 3'b000) ? {24'b0, vs1_data[7:0]} :
   575	                  (vsew == 3'b001) ? {16'b0, vs1_data[15:0]} : vs1_data[31:0];
   576	        for (rk = 0; rk < 16; rk = rk + 1) begin
   577	            if (rk < q_vl) begin
   578	                case (vsew)
   579	                    3'b000:  red_sum = red_sum + {24'b0, vs2_data[(rk%16)*8 +: 8]};
   580	                    3'b001:  if (rk < 8) red_sum = red_sum + {16'b0, vs2_data[(rk%8)*16 +: 16]};
   581	                    default: if (rk < 4) red_sum = red_sum + vs2_data[(rk%4)*32 +: 32];
   582	                endcase
   583	            end
   584	        end
   585	    end
   586	    wire [127:0] res_red = (vsew == 3'b000) ? {vd_old[127:8],  red_sum[7:0]} :
   587	                           (vsew == 3'b001) ? {vd_old[127:16], red_sum[15:0]} :
   588	                                              {vd_old[127:32], red_sum[31:0]};
   589	    // vmv.s.x: element 0 = x[rs1] truncated to SEW; tail undisturbed
   590	    wire [127:0] res_sx = (vsew == 3'b000) ? {vd_old[127:8],  q_rs1[7:0]} :
   591	                          (vsew == 3'b001) ? {vd_old[127:16], q_rs1[15:0]} :
   592	                                             {vd_old[127:32], q_rs1[31:0]};
   593	
   594	    // ---------------- S2 datapaths (sat / avg / scaling shift / nclip) --------
   595	    // Rounding increment per vxrm (d = shift amount, x = raw bits):
   596	    //   rnu: x[d-1] | rne: x[d-1] & (x[d-2:0]!=0 | x[d]) | rdn: 0
   597	    //   rod: !x[d] & (x[d-1:0]!=0)
   598	    wire [15:0] s2_sat8, s2_sat16_x;  // per-lane sat flags (padded)
   599	    wire [3:0]  s2_sat32;
   600	    wire [7:0]  nc_sat8;
   601	    wire [3:0]  nc_sat16;
   602	    wire [127:0] res_s2_8, res_s2_16, res_s2_32, res_nc8, res_nc16;
   603	    wire [127:0] res_ext16, res_ext32;   // B2b vzext/vsext
   604	
   605	    generate
   606	        for (gi = 0; gi < 16; gi = gi + 1) begin : g_s2_8
   607	            wire [7:0] a = vs2_data[gi*8 +: 8];
   608	            wire [7:0] b = (is_opivv || is_opmvv) ? vs1_data[gi*8 +: 8] : scalar_b[7:0];
   609	            wire signed [8:0] sxs = {a[7], a} + {b[7], b};
   610	            wire signed [8:0] sxd = {a[7], a} - {b[7], b};
   611	            wire        [8:0] uxs = {1'b0, a} + {1'b0, b};
   612	            wire        [8:0] uxd = {1'b0, a} - {1'b0, b};
   613	            // signed sat: top two bits differ
   614	            wire ss_ov  = sxs[8] != sxs[7];
   615	            wire sd_ov  = sxd[8] != sxd[7];
   616	            wire [7:0] r_sadd  = ss_ov ? (sxs[8] ? 8'h80 : 8'h7F) : sxs[7:0];
   617	            wire [7:0] r_ssub  = sd_ov ? (sxd[8] ? 8'h80 : 8'h7F) : sxd[7:0];
   618	            wire [7:0] r_saddu = uxs[8] ? 8'hFF : uxs[7:0];
   619	            wire [7:0] r_ssubu = uxd[8] ? 8'h00 : uxd[7:0];
   620	            // averaging: (a +/- b) >> 1 with vxrm; signed uses arithmetic shift

codex
The decode and legality pieces are in one compact area, but the datapath risk is in the generated lanes. I’m checking this against RVV element indexing rules now, especially where source EEW differs from destination SEW.
exec
/bin/bash -lc "nl -ba design/cpu_m1/rtl/vexu.v | sed -n '620,940p'" in /home/edauser/project/SOC/Magpie_M3V
 succeeded in 0ms:
   620	            // averaging: (a +/- b) >> 1 with vxrm; signed uses arithmetic shift
   621	            wire [8:0] avg_x   = avg_sub ? (avg_signed ? sxd[8:0] : uxd)
   622	                                         : (avg_signed ? sxs[8:0] : uxs);
   623	            wire avg_inc = (q_vxrm == 2'd0) ?  avg_x[0] :
   624	                           (q_vxrm == 2'd1) ? (avg_x[0] & avg_x[1]) :
   625	                           (q_vxrm == 2'd2) ?  1'b0 :
   626	                                              (~avg_x[1] & avg_x[0]);
   627	            wire [7:0] r_avg = avg_x[8:1] + {7'b0, avg_inc};   // (a±b)>>1, sign in bit 8
   628	            // scaling shifts
   629	            wire [2:0] d8 = b[2:0];
   630	            wire [7:0] lowm = (8'h01 << d8) - 8'h1;          // bits below d (incl d-1)
   631	            wire b_dm1 = (d8 != 3'd0) && (((a >> (d8 - 3'd1)) & 8'h1) != 8'h0);
   632	            wire b_d   = ((a >> d8) & 8'h1) != 8'h0;
   633	            wire lo_nz = (a & (lowm >> 1)) != 8'h0;
   634	            wire any_lo= (a & lowm) != 8'h0;
   635	            wire sh_inc = (q_vxrm == 2'd0) ? b_dm1 :
   636	                          (q_vxrm == 2'd1) ? (b_dm1 & (lo_nz | b_d)) :
   637	                          (q_vxrm == 2'd2) ? 1'b0 :
   638	                                             (~b_d & any_lo);
   639	            wire signed [7:0] as8 = a;
   640	            wire [7:0] r_ssrl = (a >> d8) + {7'b0, sh_inc};
   641	            wire [7:0] r_ssra = $unsigned(as8 >>> d8) + {7'b0, sh_inc};
   642	            wire [7:0] r_s2 = op_sadd  ? r_sadd  :
   643	                              op_saddu ? r_saddu :
   644	                              op_ssub  ? r_ssub  :
   645	                              op_ssubu ? r_ssubu :
   646	                              op_avg   ? r_avg   :
   647	                              op_ssrl  ? r_ssrl  : r_ssra;
   648	            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
   649	            assign res_s2_8[gi*8 +: 8] = en ? r_s2 : vd_old[gi*8 +: 8];
   650	            assign s2_sat8[gi] = en && ((op_sadd && ss_ov) || (op_ssub && sd_ov) ||
   651	                                        (op_saddu && uxs[8]) || (op_ssubu && uxd[8]));
   652	        end
   653	
   654	        for (gi = 0; gi < 8; gi = gi + 1) begin : g_s2_16
   655	            wire [15:0] a = vs2_data[gi*16 +: 16];
   656	            wire [15:0] b = (is_opivv || is_opmvv) ? vs1_data[gi*16 +: 16] : scalar_b[15:0];
   657	            wire signed [16:0] sxs = {a[15], a} + {b[15], b};
   658	            wire signed [16:0] sxd = {a[15], a} - {b[15], b};
   659	            wire        [16:0] uxs = {1'b0, a} + {1'b0, b};
   660	            wire        [16:0] uxd = {1'b0, a} - {1'b0, b};
   661	            wire ss_ov  = sxs[16] != sxs[15];
   662	            wire sd_ov  = sxd[16] != sxd[15];
   663	            wire [15:0] r_sadd  = ss_ov ? (sxs[16] ? 16'h8000 : 16'h7FFF) : sxs[15:0];
   664	            wire [15:0] r_ssub  = sd_ov ? (sxd[16] ? 16'h8000 : 16'h7FFF) : sxd[15:0];
   665	            wire [15:0] r_saddu = uxs[16] ? 16'hFFFF : uxs[15:0];
   666	            wire [15:0] r_ssubu = uxd[16] ? 16'h0000 : uxd[15:0];
   667	            wire [16:0] avg_x   = avg_sub ? (avg_signed ? sxd[16:0] : uxd)
   668	                                          : (avg_signed ? sxs[16:0] : uxs);
   669	            wire avg_inc = (q_vxrm == 2'd0) ?  avg_x[0] :
   670	                           (q_vxrm == 2'd1) ? (avg_x[0] & avg_x[1]) :
   671	                           (q_vxrm == 2'd2) ?  1'b0 :
   672	                                              (~avg_x[1] & avg_x[0]);
   673	            wire [15:0] r_avg = avg_x[16:1] + {15'b0, avg_inc};
   674	            wire [3:0] d16 = b[3:0];
   675	            wire [15:0] lowm = (16'h0001 << d16) - 16'h1;
   676	            wire b_dm1 = (d16 != 4'd0) && (((a >> (d16 - 4'd1)) & 16'h1) != 16'h0);
   677	            wire b_d   = ((a >> d16) & 16'h1) != 16'h0;
   678	            wire lo_nz = (a & (lowm >> 1)) != 16'h0;
   679	            wire any_lo= (a & lowm) != 16'h0;
   680	            wire sh_inc = (q_vxrm == 2'd0) ? b_dm1 :
   681	                          (q_vxrm == 2'd1) ? (b_dm1 & (lo_nz | b_d)) :
   682	                          (q_vxrm == 2'd2) ? 1'b0 :
   683	                                             (~b_d & any_lo);
   684	            wire signed [15:0] as16 = a;
   685	            wire [15:0] r_ssrl = (a >> d16) + {15'b0, sh_inc};
   686	            wire [15:0] r_ssra = $unsigned(as16 >>> d16) + {15'b0, sh_inc};
   687	            wire [15:0] r_s2 = op_sadd  ? r_sadd  :
   688	                               op_saddu ? r_saddu :
   689	                               op_ssub  ? r_ssub  :
   690	                               op_ssubu ? r_ssubu :
   691	                               op_avg   ? r_avg   :
   692	                               op_ssrl  ? r_ssrl  : r_ssra;
   693	            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
   694	            assign res_s2_16[gi*16 +: 16] = en ? r_s2 : vd_old[gi*16 +: 16];
   695	            assign s2_sat16_x[gi] = en && ((op_sadd && ss_ov) || (op_ssub && sd_ov) ||
   696	                                           (op_saddu && uxs[16]) || (op_ssubu && uxd[16]));
   697	        end
   698	
   699	        for (gi = 0; gi < 4; gi = gi + 1) begin : g_s2_32
   700	            wire [31:0] a = vs2_data[gi*32 +: 32];
   701	            wire [31:0] b = (is_opivv || is_opmvv) ? vs1_data[gi*32 +: 32] : scalar_b;
   702	            wire signed [32:0] sxs = {a[31], a} + {b[31], b};
   703	            wire signed [32:0] sxd = {a[31], a} - {b[31], b};
   704	            wire        [32:0] uxs = {1'b0, a} + {1'b0, b};
   705	            wire        [32:0] uxd = {1'b0, a} - {1'b0, b};
   706	            wire ss_ov  = sxs[32] != sxs[31];
   707	            wire sd_ov  = sxd[32] != sxd[31];
   708	            wire [31:0] r_sadd  = ss_ov ? (sxs[32] ? 32'h8000_0000 : 32'h7FFF_FFFF) : sxs[31:0];
   709	            wire [31:0] r_ssub  = sd_ov ? (sxd[32] ? 32'h8000_0000 : 32'h7FFF_FFFF) : sxd[31:0];
   710	            wire [31:0] r_saddu = uxs[32] ? 32'hFFFF_FFFF : uxs[31:0];
   711	            wire [31:0] r_ssubu = uxd[32] ? 32'h0 : uxd[31:0];
   712	            wire [32:0] avg_x   = avg_sub ? (avg_signed ? sxd[32:0] : uxd)
   713	                                          : (avg_signed ? sxs[32:0] : uxs);
   714	            wire avg_inc = (q_vxrm == 2'd0) ?  avg_x[0] :
   715	                           (q_vxrm == 2'd1) ? (avg_x[0] & avg_x[1]) :
   716	                           (q_vxrm == 2'd2) ?  1'b0 :
   717	                                              (~avg_x[1] & avg_x[0]);
   718	            wire [31:0] r_avg = avg_x[32:1] + {31'b0, avg_inc};
   719	            wire [4:0] d32 = b[4:0];
   720	            wire [31:0] lowm = (32'h1 << d32) - 32'h1;
   721	            wire b_dm1 = (d32 != 5'd0) && (((a >> (d32 - 5'd1)) & 32'h1) != 32'h0);
   722	            wire b_d   = ((a >> d32) & 32'h1) != 32'h0;
   723	            wire lo_nz = (a & (lowm >> 1)) != 32'h0;
   724	            wire any_lo= (a & lowm) != 32'h0;
   725	            wire sh_inc = (q_vxrm == 2'd0) ? b_dm1 :
   726	                          (q_vxrm == 2'd1) ? (b_dm1 & (lo_nz | b_d)) :
   727	                          (q_vxrm == 2'd2) ? 1'b0 :
   728	                                             (~b_d & any_lo);
   729	            wire signed [31:0] as32 = a;
   730	            wire [31:0] r_ssrl = (a >> d32) + {31'b0, sh_inc};
   731	            wire [31:0] r_ssra = $unsigned(as32 >>> d32) + {31'b0, sh_inc};
   732	            wire [31:0] r_s2 = op_sadd  ? r_sadd  :
   733	                               op_saddu ? r_saddu :
   734	                               op_ssub  ? r_ssub  :
   735	                               op_ssubu ? r_ssubu :
   736	                               op_avg   ? r_avg   :
   737	                               op_ssrl  ? r_ssrl  : r_ssra;
   738	            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
   739	            assign res_s2_32[gi*32 +: 32] = en ? r_s2 : vd_old[gi*32 +: 32];
   740	            assign s2_sat32[gi] = en && ((op_sadd && ss_ov) || (op_ssub && sd_ov) ||
   741	                                         (op_saddu && uxs[32]) || (op_ssubu && uxd[32]));
   742	        end
   743	
   744	        // ---- vnclip[u]: wide 2*SEW source -> SEW dest with round + clip ----
   745	        for (gi = 0; gi < 8; gi = gi + 1) begin : g_nc8
   746	            wire [15:0] v = vs2_data[gi*16 +: 16];             // wide lane
   747	            wire [7:0]  b = is_opivv ? vs1_data[gi*8 +: 8] : scalar_b[7:0];
   748	            wire [3:0]  d = b[3:0];                            // shamt & (2*SEW-1)
   749	            wire [15:0] lowm = (16'h0001 << d) - 16'h1;
   750	            wire b_dm1 = (d != 4'd0) && (((v >> (d - 4'd1)) & 16'h1) != 16'h0);
   751	            wire b_d   = ((v >> d) & 16'h1) != 16'h0;
   752	            wire lo_nz = (v & (lowm >> 1)) != 16'h0;
   753	            wire any_lo= (v & lowm) != 16'h0;
   754	            wire inc = (q_vxrm == 2'd0) ? b_dm1 :
   755	                       (q_vxrm == 2'd1) ? (b_dm1 & (lo_nz | b_d)) :
   756	                       (q_vxrm == 2'd2) ? 1'b0 :
   757	                                          (~b_d & any_lo);
   758	            wire signed [15:0] vs = v;
   759	            wire        [15:0] nsrl_w = v >> d;            // B2a vnsrl: logical
   760	            wire signed [15:0] nsra_w = vs >>> d;          // B2a vnsra: arithmetic (self-det signed)
   761	            wire signed [16:0] rs = {vs[15], $unsigned(vs >>> d)} + {16'b0, inc};
   762	            wire        [16:0] ru = {1'b0, v >> d} + {16'b0, inc};
   763	            wire s_ov = (rs > 17'sd127) || (rs < -17'sd128);
   764	            wire u_ov = (ru > 17'd255);
   765	            wire [7:0] r = op_nsrl  ? nsrl_w[7:0] :
   766	                           op_nsra  ? nsra_w[7:0] :
   767	                           op_nclip ? (s_ov ? (rs[16] ? 8'h80 : 8'h7F) : rs[7:0])
   768	                                    : (u_ov ? 8'hFF : ru[7:0]);
   769	            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
   770	            assign res_nc8[gi*8 +: 8] = en ? r : vd_old[gi*8 +: 8];
   771	            assign nc_sat8[gi] = en && (op_nclip ? s_ov : u_ov);
   772	        end
   773	        for (gi = 0; gi < 4; gi = gi + 1) begin : g_nc16
   774	            wire [31:0] v = vs2_data[gi*32 +: 32];
   775	            wire [15:0] b = is_opivv ? vs1_data[gi*16 +: 16] : scalar_b[15:0];
   776	            wire [4:0]  d = b[4:0];
   777	            wire [31:0] lowm = (32'h1 << d) - 32'h1;
   778	            wire b_dm1 = (d != 5'd0) && (((v >> (d - 5'd1)) & 32'h1) != 32'h0);
   779	            wire b_d   = ((v >> d) & 32'h1) != 32'h0;
   780	            wire lo_nz = (v & (lowm >> 1)) != 32'h0;
   781	            wire any_lo= (v & lowm) != 32'h0;
   782	            wire inc = (q_vxrm == 2'd0) ? b_dm1 :
   783	                       (q_vxrm == 2'd1) ? (b_dm1 & (lo_nz | b_d)) :
   784	                       (q_vxrm == 2'd2) ? 1'b0 :
   785	                                          (~b_d & any_lo);
   786	            wire signed [31:0] vs = v;
   787	            wire        [31:0] nsrl_w = v >> d;
   788	            wire signed [31:0] nsra_w = vs >>> d;
   789	            wire signed [32:0] rs = {vs[31], $unsigned(vs >>> d)} + {32'b0, inc};
   790	            wire        [32:0] ru = {1'b0, v >> d} + {32'b0, inc};
   791	            wire s_ov = (rs > 33'sd32767) || (rs < -33'sd32768);
   792	            wire u_ov = (ru > 33'd65535);
   793	            wire [15:0] r = op_nsrl  ? nsrl_w[15:0] :
   794	                            op_nsra  ? nsra_w[15:0] :
   795	                            op_nclip ? (s_ov ? (rs[32] ? 16'h8000 : 16'h7FFF) : rs[15:0])
   796	                                     : (u_ov ? 16'hFFFF : ru[15:0]);
   797	            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
   798	            assign res_nc16[gi*16 +: 16] = en ? r : vd_old[gi*16 +: 16];
   799	            assign nc_sat16[gi] = en && (op_nclip ? s_ov : u_ov);
   800	        end
   801	
   802	        // ---- B2b vzext/vsext: SEW/2 (vf2) or SEW/4 (vf4) source -> SEW dest ----
   803	        for (gi = 0; gi < 8; gi = gi + 1) begin : g_ext16   // dst e16, vf2 (src 8b)
   804	            wire [7:0]  s = vs2_data[gi*8 +: 8];
   805	            wire [15:0] e = ext_sext ? {{8{s[7]}}, s} : {8'b0, s};
   806	            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
   807	            assign res_ext16[gi*16 +: 16] = en ? e : vd_old[gi*16 +: 16];
   808	        end
   809	        for (gi = 0; gi < 4; gi = gi + 1) begin : g_ext32   // dst e32, vf2 (src 16b) / vf4 (src 8b)
   810	            wire [15:0] s2 = vs2_data[gi*16 +: 16];
   811	            wire [7:0]  s4 = vs2_data[gi*8 +: 8];
   812	            wire [31:0] e2 = ext_sext ? {{16{s2[15]}}, s2} : {16'b0, s2};
   813	            wire [31:0] e4 = ext_sext ? {{24{s4[7]}},  s4} : {24'b0, s4};
   814	            wire [31:0] e  = ext_vf4 ? e4 : e2;
   815	            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
   816	            assign res_ext32[gi*32 +: 32] = en ? e : vd_old[gi*32 +: 32];
   817	        end
   818	    endgenerate
   819	
   820	    // narrowing writes at most 8 (SEW8) / 4 (SEW16) dst elements under the
   821	    // fractional-LMUL rule -> the upper half of the dst register is tail
   822	    assign res_nc8[127:64]  = vd_old[127:64];
   823	    assign res_nc16[127:64] = vd_old[127:64];
   824	
   825	    wire [127:0] res_s2 = (vsew == 3'b000) ? res_s2_8 :
   826	                          (vsew == 3'b001) ? res_s2_16 : res_s2_32;
   827	    wire [127:0] res_nc = (vsew == 3'b000) ? res_nc8 : res_nc16;
   828	    wire part_sat_or = (op_s2same && ((vsew == 3'b000) ? (|s2_sat8) :
   829	                                      (vsew == 3'b001) ? (|s2_sat16_x[7:0]) :
   830	                                                         (|s2_sat32))) ||
   831	                       (op_nc && ((vsew == 3'b000) ? (|nc_sat8) : (|nc_sat16)));
   832	    assign q_vxsat = q_valid && !q_illegal && (q_vstart < q_vl) &&
   833	                     (is_grp ? grp_sat_q : part_sat_or);
   834	
   835	    // per-part combinational result for the group beats (arith class)
   836	    wire [127:0] part_res = op_s2same ? res_s2 :
   837	                            (vsew == 3'b000) ? res8 :
   838	                            (vsew == 3'b001) ? res16 : res32;
   839	    wire [15:0] cmp_seg  = (vsew == 3'b000) ? cmp_bits8 :
   840	                           (vsew == 3'b001) ? {8'b0, cmp_bits16} :
   841	                                              {12'b0, cmp_bits32};
   842	    wire [127:0] mask_nl = (vsew == 3'b000) ? 128'hFFFF :
   843	                           (vsew == 3'b001) ? 128'hFF : 128'hF;
   844	    // group compare: bits < vl from the accumulator, tail from the dest reg
   845	    wire [127:0] vl_ones  = (128'h1 << q_vl[6:0]) - 128'h1;
   846	    wire [127:0] grp_cmp_res = (cmpd_old & ~vl_ones) | (grp_mask_acc & vl_ones);
   847	
   848	    // ---- S1 result assembly: compares + mask logicals ----
   849	    wire [15:0] cmp_bits8;
   850	    wire [7:0]  cmp_bits16;
   851	    wire [3:0]  cmp_bits32;
   852	    wire [127:0] res_cmp = (vsew == 3'b000) ? {cmpd_old[127:16], cmp_bits8}  :
   853	                           (vsew == 3'b001) ? {cmpd_old[127:8],  cmp_bits16} :
   854	                                              {cmpd_old[127:4],  cmp_bits32};
   855	    wire [127:0] mlog_full =
   856	        (f6[2:0] == 3'b000) ?  (vs2_data & ~vs1_data) :   // vmandn
   857	        (f6[2:0] == 3'b001) ?  (vs2_data &  vs1_data) :   // vmand
   858	        (f6[2:0] == 3'b010) ?  (vs2_data |  vs1_data) :   // vmor
   859	        (f6[2:0] == 3'b011) ?  (vs2_data ^  vs1_data) :   // vmxor
   860	        (f6[2:0] == 3'b100) ?  (vs2_data | ~vs1_data) :   // vmorn
   861	        (f6[2:0] == 3'b101) ? ~(vs2_data &  vs1_data) :   // vmnand
   862	        (f6[2:0] == 3'b110) ? ~(vs2_data |  vs1_data) :   // vmnor
   863	                              ~(vs2_data ^  vs1_data);    // vmxnor
   864	    wire [127:0] res_mlog;
   865	    generate
   866	        for (gi = 0; gi < 128; gi = gi + 1) begin : g_mlog
   867	            assign res_mlog[gi] = (gi < q_vl) ? mlog_full[gi] : vd_old[gi];
   868	        end
   869	    endgenerate
   870	
   871	    assign q_wdata = is_vmem ? vm_buf :
   872	                     (is_grp && op_cmp) ? grp_cmp_res :
   873	                     (is_grp) ? grp_stage[0] :
   874	                     op_cmp  ? res_cmp :
   875	                     op_mlog ? res_mlog :
   876	                     op_s2same ? res_s2 :
   877	                     (op_nc || op_nsr) ? res_nc :
   878	                     op_vext ? ((vsew == 3'b001) ? res_ext16 : res_ext32) :
   879	                     op_widen ? ((vsew == 3'b000) ? res_w8 : res_w16) :
   880	                     op_redsum ? res_red :
   881	                     op_mvsx ? res_sx :
   882	                     (vsew == 3'b000) ? res8 :
   883	                     (vsew == 3'b001) ? res16 : res32;
   884	    assign q_vd    = vd_i;
   885	    // whole-instruction no-op when vstart>=vl (includes vl==0); vmv.x.s and
   886	    // vector STORES never write the VRF
   887	    assign q_vrf_we = q_valid && !q_illegal && !op_mvxs && !is_vstore && (q_vstart < q_vl);
   888	
   889	    // ---------------- vmv.x.s (executes even when vl==0) ----------------
   890	    wire [7:0]  e0_8  = vs2_data[7:0];
   891	    wire [15:0] e0_16 = vs2_data[15:0];
   892	    assign q_scalar = (vsew == 3'b000) ? {{24{e0_8[7]}},  e0_8} :
   893	                      (vsew == 3'b001) ? {{16{e0_16[15]}}, e0_16} :
   894	                                         vs2_data[31:0];
   895	    assign q_scalar_we = q_valid && !q_illegal && op_mvxs;
   896	
   897	endmodule
   898	`default_nettype wire

exec
/bin/bash -lc 'rg -n "op_vext|op_nsr|vnsr|vnsra|vnsrl|vzext|vsext|101100|101101|010010|nc_sat|q_vxsat|part_sat_or|beats_op|is_grp" design/cpu_m1/rtl/vexu.v' in /home/edauser/project/SOC/Magpie_M3V
 succeeded in 0ms:
38:    output wire         q_is_grp,     // S3: multi-beat register-group op (hold like vmem)
44:    output wire         q_vxsat,      // S2: saturation occurred (active lanes)
140:    // same-shape element-wise ALU: join the per-SEW mux + beats_op (m2/m4 groups).
151:    // ---------------- Phase-B B2a (ADR-0055): narrowing shift (vnsrl/vnsra) ----
155:    wire op_nsrl  = (f6 == 6'b101100) && (is_opivv || is_opivx || is_opivi);
156:    wire op_nsra  = (f6 == 6'b101101) && (is_opivv || is_opivx || is_opivi);
157:    wire op_nsr   = op_nsrl || op_nsra;
159:    // ---------------- Phase-B B2b (ADR-0055): vzext/vsext.vf2/vf4 ----------------
160:    // OPMVV f6=010010 (gated by f3 -> disjoint from OPIVV vsbc, which shares f6).
164:    wire ext_enc  = is_opmvv && (f6 == 6'b010010) && (vs1_i[4:3] == 2'b00);
168:    wire op_vext  = ext_enc &&
189:    assign q_is_grp = q_valid && is_grp && !q_illegal;    // hold/beats (incl. cmp)
191:    assign q_grp_w  = q_valid && is_grp && !op_cmp && !q_illegal;
231:                    op_nsr || op_vext;
235:    wire beats_op  = op_add || op_sub || op_mv || op_merge || op_mm ||
239:    wire is_grp    = (grp_parts != 3'd1) && beats_op && !is_vmem;
241:        (op_widen || op_redsum || op_nc || op_nsr || op_vext ||
242:         !beats_op && !op_mvxs && !op_mvsx && !op_mlog && !is_vmem);
245:    wire grp_align_illegal = is_grp &&
253:    wire nc_illegal = (op_nc || op_nsr) && (!widen_lmul_ok || (vsew == 3'b010));
269:                           op_b1 || op_nsr || op_vext) &&
486:                    if (is_grp) begin
508:                    grp_sat_q <= grp_sat_q | part_sat_or;
600:    wire [7:0]  nc_sat8;
601:    wire [3:0]  nc_sat16;
603:    wire [127:0] res_ext16, res_ext32;   // B2b vzext/vsext
759:            wire        [15:0] nsrl_w = v >> d;            // B2a vnsrl: logical
760:            wire signed [15:0] nsra_w = vs >>> d;          // B2a vnsra: arithmetic (self-det signed)
765:            wire [7:0] r = op_nsrl  ? nsrl_w[7:0] :
766:                           op_nsra  ? nsra_w[7:0] :
771:            assign nc_sat8[gi] = en && (op_nclip ? s_ov : u_ov);
793:            wire [15:0] r = op_nsrl  ? nsrl_w[15:0] :
794:                            op_nsra  ? nsra_w[15:0] :
799:            assign nc_sat16[gi] = en && (op_nclip ? s_ov : u_ov);
802:        // ---- B2b vzext/vsext: SEW/2 (vf2) or SEW/4 (vf4) source -> SEW dest ----
828:    wire part_sat_or = (op_s2same && ((vsew == 3'b000) ? (|s2_sat8) :
831:                       (op_nc && ((vsew == 3'b000) ? (|nc_sat8) : (|nc_sat16)));
832:    assign q_vxsat = q_valid && !q_illegal && (q_vstart < q_vl) &&
833:                     (is_grp ? grp_sat_q : part_sat_or);
872:                     (is_grp && op_cmp) ? grp_cmp_res :
873:                     (is_grp) ? grp_stage[0] :
877:                     (op_nc || op_nsr) ? res_nc :
878:                     op_vext ? ((vsew == 3'b001) ? res_ext16 : res_ext32) :

exec
/bin/bash -lc 'git diff -- design/cpu_m1/rtl/vexu.v' in /home/edauser/project/SOC/Magpie_M3V
 succeeded in 0ms:
diff --git a/design/cpu_m1/rtl/vexu.v b/design/cpu_m1/rtl/vexu.v
index e0f4240..767bb8b 100644
--- a/design/cpu_m1/rtl/vexu.v
+++ b/design/cpu_m1/rtl/vexu.v
@@ -148,6 +148,27 @@ module vexu #(
     wire op_b1    = op_and || op_or || op_xor || op_rsub ||
                     op_sll || op_srl || op_sra;
 
+    // ---------------- Phase-B B2a (ADR-0055): narrowing shift (vnsrl/vnsra) ----
+    // wide 2*SEW source >> shamt -> SEW dest (low bits). Reuses the vnclip wide
+    // datapath minus round/clip. Only SEW8/16 (2*SEW=16/32) — SEW32 narrowing
+    // needs a 64-bit source, absent in Zve32x (same rule as vnclip).
+    wire op_nsrl  = (f6 == 6'b101100) && (is_opivv || is_opivx || is_opivi);
+    wire op_nsra  = (f6 == 6'b101101) && (is_opivv || is_opivx || is_opivi);
+    wire op_nsr   = op_nsrl || op_nsra;
+
+    // ---------------- Phase-B B2b (ADR-0055): vzext/vsext.vf2/vf4 ----------------
+    // OPMVV f6=010010 (gated by f3 -> disjoint from OPIVV vsbc, which shares f6).
+    // vs1 selects variant: [2:1]=11 vf2 / 10 vf4 / 01 vf8; [0]=1 sign, 0 zero.
+    // Zve32x: no e64 source -> vf8 always illegal; vf4 needs SEW32 (src8), vf2
+    // needs SEW>=16 (src SEW/2). Extends the low SEW/2 (or SEW/4) source lane.
+    wire ext_enc  = is_opmvv && (f6 == 6'b010010) && (vs1_i[4:3] == 2'b00);
+    wire ext_vf2  = (vs1_i[2:1] == 2'b11);
+    wire ext_vf4  = (vs1_i[2:1] == 2'b10);
+    wire ext_sext = vs1_i[0];
+    wire op_vext  = ext_enc &&
+                    ((ext_vf2 && ((vsew == 3'b001) || (vsew == 3'b010))) ||
+                     (ext_vf4 &&  (vsew == 3'b010)));
+
     // ---------------- config legality ----------------
     wire        vill  = q_vtype[31];
     wire [2:0]  vlmul = q_vtype[2:0];
@@ -206,7 +227,8 @@ module vexu #(
 
     wire known_op = op_add || op_sub || op_mv || op_merge || op_mvxs ||
                     op_wmul || op_waddw || op_redsum || op_mvsx ||
-                    op_mm || op_cmp || op_mlog || op_s2same || op_nc || op_b1;
+                    op_mm || op_cmp || op_mlog || op_s2same || op_nc || op_b1 ||
+                    op_nsr || op_vext;
     // ops that iterate register-group parts (compares read groups, write ONE
     // mask register); widening/narrowing/reductions stay <= m1 (their own
     // LMUL rules) and vmv.x.s/vmv.s.x touch element 0 only.
@@ -216,7 +238,7 @@ module vexu #(
     // site is guarded by an is_vmem priority mux) — exclude them here too.
     wire is_grp    = (grp_parts != 3'd1) && beats_op && !is_vmem;
     wire grp_only_illegal = (grp_parts != 3'd1) &&
-        (op_widen || op_redsum || op_nc ||
+        (op_widen || op_redsum || op_nc || op_nsr || op_vext ||
          !beats_op && !op_mvxs && !op_mvsx && !op_mlog && !is_vmem);
     // register-group alignment (vd for writes except mask-dest; sources)
     wire [4:0] grp_amask = lmul_m4 ? 5'd3 : lmul_m2 ? 5'd1 : 5'd0;
@@ -228,7 +250,7 @@ module vexu #(
          ((is_opivv || is_opmvv) && ((vs1_i & grp_amask) != 5'd0)));
     // narrowing legality mirrors widening (source EMUL = 2*LMUL <= 1); the
     // low-part destination overlap (vd == vs2) is spec-legal for narrowing.
-    wire nc_illegal = op_nc && (!widen_lmul_ok || (vsew == 3'b010));
+    wire nc_illegal = (op_nc || op_nsr) && (!widen_lmul_ok || (vsew == 3'b010));
     // vstart!=0 on arithmetic = illegal (spec-allowed choice; MATCHES SPIKE —
     // caught by gate_42 lockstep: Spike trapped where the RTL executed).
     // Loads/stores are resumable: vstart is honored (start element), not illegal.
@@ -244,7 +266,7 @@ module vexu #(
                          // targeting v0 remain legal.
                          nc_illegal || grp_only_illegal || grp_align_illegal ||
                          ((op_add || op_sub || op_mm || op_s2same || op_nc ||
-                           op_b1) &&
+                           op_b1 || op_nsr || op_vext) &&
                           !vm && (vd_i == 5'd0)))));
 
     // ---------------- VRF ----------------
@@ -578,6 +600,7 @@ module vexu #(
     wire [7:0]  nc_sat8;
     wire [3:0]  nc_sat16;
     wire [127:0] res_s2_8, res_s2_16, res_s2_32, res_nc8, res_nc16;
+    wire [127:0] res_ext16, res_ext32;   // B2b vzext/vsext
 
     generate
         for (gi = 0; gi < 16; gi = gi + 1) begin : g_s2_8
@@ -733,11 +756,15 @@ module vexu #(
                        (q_vxrm == 2'd2) ? 1'b0 :
                                           (~b_d & any_lo);
             wire signed [15:0] vs = v;
+            wire        [15:0] nsrl_w = v >> d;            // B2a vnsrl: logical
+            wire signed [15:0] nsra_w = vs >>> d;          // B2a vnsra: arithmetic (self-det signed)
             wire signed [16:0] rs = {vs[15], $unsigned(vs >>> d)} + {16'b0, inc};
             wire        [16:0] ru = {1'b0, v >> d} + {16'b0, inc};
             wire s_ov = (rs > 17'sd127) || (rs < -17'sd128);
             wire u_ov = (ru > 17'd255);
-            wire [7:0] r = op_nclip ? (s_ov ? (rs[16] ? 8'h80 : 8'h7F) : rs[7:0])
+            wire [7:0] r = op_nsrl  ? nsrl_w[7:0] :
+                           op_nsra  ? nsra_w[7:0] :
+                           op_nclip ? (s_ov ? (rs[16] ? 8'h80 : 8'h7F) : rs[7:0])
                                     : (u_ov ? 8'hFF : ru[7:0]);
             wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
             assign res_nc8[gi*8 +: 8] = en ? r : vd_old[gi*8 +: 8];
@@ -757,16 +784,37 @@ module vexu #(
                        (q_vxrm == 2'd2) ? 1'b0 :
                                           (~b_d & any_lo);
             wire signed [31:0] vs = v;
+            wire        [31:0] nsrl_w = v >> d;
+            wire signed [31:0] nsra_w = vs >>> d;
             wire signed [32:0] rs = {vs[31], $unsigned(vs >>> d)} + {32'b0, inc};
             wire        [32:0] ru = {1'b0, v >> d} + {32'b0, inc};
             wire s_ov = (rs > 33'sd32767) || (rs < -33'sd32768);
             wire u_ov = (ru > 33'd65535);
-            wire [15:0] r = op_nclip ? (s_ov ? (rs[32] ? 16'h8000 : 16'h7FFF) : rs[15:0])
+            wire [15:0] r = op_nsrl  ? nsrl_w[15:0] :
+                            op_nsra  ? nsra_w[15:0] :
+                            op_nclip ? (s_ov ? (rs[32] ? 16'h8000 : 16'h7FFF) : rs[15:0])
                                      : (u_ov ? 16'hFFFF : ru[15:0]);
             wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
             assign res_nc16[gi*16 +: 16] = en ? r : vd_old[gi*16 +: 16];
             assign nc_sat16[gi] = en && (op_nclip ? s_ov : u_ov);
         end
+
+        // ---- B2b vzext/vsext: SEW/2 (vf2) or SEW/4 (vf4) source -> SEW dest ----
+        for (gi = 0; gi < 8; gi = gi + 1) begin : g_ext16   // dst e16, vf2 (src 8b)
+            wire [7:0]  s = vs2_data[gi*8 +: 8];
+            wire [15:0] e = ext_sext ? {{8{s[7]}}, s} : {8'b0, s};
+            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
+            assign res_ext16[gi*16 +: 16] = en ? e : vd_old[gi*16 +: 16];
+        end
+        for (gi = 0; gi < 4; gi = gi + 1) begin : g_ext32   // dst e32, vf2 (src 16b) / vf4 (src 8b)
+            wire [15:0] s2 = vs2_data[gi*16 +: 16];
+            wire [7:0]  s4 = vs2_data[gi*8 +: 8];
+            wire [31:0] e2 = ext_sext ? {{16{s2[15]}}, s2} : {16'b0, s2};
+            wire [31:0] e4 = ext_sext ? {{24{s4[7]}},  s4} : {24'b0, s4};
+            wire [31:0] e  = ext_vf4 ? e4 : e2;
+            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
+            assign res_ext32[gi*32 +: 32] = en ? e : vd_old[gi*32 +: 32];
+        end
     endgenerate
 
     // narrowing writes at most 8 (SEW8) / 4 (SEW16) dst elements under the
@@ -826,7 +874,8 @@ module vexu #(
                      op_cmp  ? res_cmp :
                      op_mlog ? res_mlog :
                      op_s2same ? res_s2 :
-                     op_nc  ? res_nc :
+                     (op_nc || op_nsr) ? res_nc :
+                     op_vext ? ((vsew == 3'b001) ? res_ext16 : res_ext32) :
                      op_widen ? ((vsew == 3'b000) ? res_w8 : res_w16) :
                      op_redsum ? res_red :
                      op_mvsx ? res_sx :

exec
/bin/bash -lc "find . -maxdepth 4 -iname '*rvv*' -o -iname '*vector*' -o -iname '*ADR-0055*'" in /home/edauser/project/SOC/Magpie_M3V
 succeeded in 0ms:
./docs/adr/0049-rvv-phase-a.md
./docs/adr/0036-rvv-zve32x-exu.md
./docs/reviews/2026-07-04_gemini_backfill_and_rvv_dossier.md
./design/npu/sw/rvv_zve32x_smoke
./tests/gates/gate_62_rvv_b1_intcore.py
./tests/gates/__pycache__/gate_57_rvv_s2_sat.cpython-311-pytest-9.0.3.pyc
./tests/gates/__pycache__/gate_62_rvv_b1_intcore.cpython-311-pytest-9.0.3.pyc
./tests/gates/__pycache__/gate_40_vector_csr_lockstep.cpython-311-pytest-9.0.3.pyc
./tests/gates/__pycache__/gate_58_rvv_s3_lmul.cpython-311-pytest-9.0.3.pyc
./tests/gates/__pycache__/gate_43_vector_lsu_tcm.cpython-311-pytest-9.0.3.pyc
./tests/gates/__pycache__/gate_56_rvv_s1_mask.cpython-311-pytest-9.0.3.pyc
./tests/gates/__pycache__/gate_42_vector_alu_lockstep.cpython-311-pytest-9.0.3.pyc
./tests/gates/gate_42_vector_alu_lockstep.py
./tests/gates/gate_43_vector_lsu_tcm.py
./tests/gates/gate_57_rvv_s2_sat.py
./tests/gates/gate_40_vector_csr_lockstep.py
./tests/gates/gate_56_rvv_s1_mask.py
./tests/gates/gate_58_rvv_s3_lmul.py
./flow/v2_pipeline/phase_23_mat_engine/vectors
./flow/v2_pipeline/phase_22_vector_csr_lockstep
./flow/v2_pipeline/phase_22_vector_csr_lockstep/gen_vector_random.py

exec
/bin/bash -lc 'rg -n "vzext|vsext|vf2|vf4|vf8|EMUL|LMUL|source EMUL|narrowing" -S . /tmp/claude-1000/-home-edauser-project-SOC-Magpie-M3V/4fbea76a-d14b-44c4-be15-55488b94edcb/scratchpad 2>/dev/null' in /home/edauser/project/SOC/Magpie_M3V
 succeeded in 158ms:
./tests/gates/gate_53_rvfi_trace.py:21:the implemented LMUL<=1 subset.
./flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_vill_ladder.S:27:    /* fractional-rule violation: e8 mf8 -> SEW/LMUL = 64 > ELEN=32 -> vill */
./docs/reports/2026-07-03_replaceability_status.md:11:| 2 | 向量(RVV Zve32x + vector CSR) | 🟢 GREEN-leaning(2026-07-04,Phase-A 收齊) | **ADR-0049 S1-S4 全落**:masked 執行/mask logicals/比較/min-max + sat/avg/scaling/nclip(vxsat/vxrm 契約)+ LMUL m2/m4 原子群寫 + **POOL kernels 對 TFLM golden bit-exact(含 half-away 捨入重建,雙引理)**——全部 Spike lockstep 權威(gate_56-59)。餘:slides/gather(workload 外)、m8、vlse RTL(裁定不做) |
./flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:1:/* ADR-0055 Phase-B B2a directed: narrowing shift vnsrl/vnsra (.wv/.wx/.wi).
./flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:3:   minus round/clip. Only SEW8 (src e16) and SEW16 (src e32) — SEW32 narrowing
./flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:4:   needs a 64-bit source, absent in Zve32x. Fractional LMUL (source EMUL=2*LMUL
./flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:52:       e16/mf2 vtype (EMUL=EEW/SEW*LMUL = 32/16*mf2 = m1); avoids e32/mf2. */
./flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:72:    /* ===== B2b vzext/vsext ===== */
./flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:77:    /* vf2 -> e16 */
./flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:80:    vzext.vf2 v3, v2
./flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:84:    vsext.vf2 v3, v2           /* sign-extend: 0x80 -> 0xFF80 */
./flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:88:    /* vf4 -> e32 (8-bit source) */
./flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:91:    vsext.vf4 v3, v2
./flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:95:    vzext.vf4 v3, v2
./flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:98:    /* vf2 -> e32 (16-bit source) */
./flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:102:    vsext.vf2 v3, v4
./flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:107:    /* terminator: masked narrowing writing v0 = ILLEGAL (dest overlaps mask) */
./flow/v2_pipeline/phase_22_vector_csr_lockstep/spike.log:134:core   0: 0x80000108 (0x4a2321d7) vzext.vf2 v3, v2
./flow/v2_pipeline/phase_22_vector_csr_lockstep/spike.log:142:core   0: 0x80000118 (0x4a23a1d7) vsext.vf2 v3, v2
./flow/v2_pipeline/phase_22_vector_csr_lockstep/spike.log:154:core   0: 0x80000130 (0x4a22a1d7) vsext.vf4 v3, v2
./flow/v2_pipeline/phase_22_vector_csr_lockstep/spike.log:162:core   0: 0x80000140 (0x4a2221d7) vzext.vf4 v3, v2
./flow/v2_pipeline/phase_22_vector_csr_lockstep/spike.log:174:core   0: 0x80000158 (0x4a43a1d7) vsext.vf2 v3, v4
./flow/v2_pipeline/phase_22_vector_csr_lockstep/gen_vector_random.py:5:- configs: legal SEW x LMUL with LMUL in {m1, mf2, mf4} only (m2+ = deferred-illegal)
./flow/v2_pipeline/phase_22_vector_csr_lockstep/gen_vector_random.py:12:  data_area; EEW picked legal for the live SEW/LMUL (EMUL<=1), base aligned to
./flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_vmem.S:102:    /* ---- EEW != SEW: vle8 under e32 m1 (EMUL=mf4, vl=4 bytes) ---- */
./flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_s2.S:91:    /* vnclip: fractional LMUL config (source EMUL=2*LMUL<=1) */
./flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_vcsr_grid.S:2: * Straight-line vset{i}vl{i} grid over legal SEW×LMUL configs and AVL boundary
./flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_s3.S:1:/* ADR-0049 S3 directed: LMUL m2/m4 register groups — atomic group commit.
./flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_valu.S:5: * sign extension, vmerge masking, fractional-LMUL execution, vl=0 no-op,
./docs/adr/0045-rvfi-trace-port.md:24:  `vl/vtype`。**有效範圍 = 實作子集(LMUL≤1、tail-undisturbed、vstart≠0 算術 illegal)**
./docs/reports/dv_roadmap/acceptance_spec_B.md:20:| S6 | Full sync mix | load/store, branch/jump, CSR, RV32M, RV32C, sync traps — no narrowing flags |
./docs/reports/dv_roadmap/acceptance_spec_B.md:248:| R1 | **Green-wash / scope narrowing** (`--no_fence`, `--enable_interrupt=0`, drop CSR) to regain green | `gate_03_09` + config hash in provenance; Bar B requires explicit S3/S4; PL rejects any campaign pass without them |
./docs/adr/0055-zve32x-phase-b.md:13:Phase-B 補齊 Zve32x 的**通用整數核心**:bitwise、shift、reverse-sub、narrowing shift、
./docs/adr/0055-zve32x-phase-b.md:36:### B2 — narrowing shift + extension(複用既有寬/窄 datapath)
./docs/adr/0055-zve32x-phase-b.md:38:  vnclip 的 wide→narrow 結構**,去掉 clip/round(vnclip 已在 S2)。narrowing → 非群組(≤m1,同
./docs/adr/0055-zve32x-phase-b.md:40:- **vzext/vsext.vf2/vf4**(OPMVV f6=010010,vs1 選變體:vf2=00110/00111、vf4=00100/00101):
./docs/adr/0055-zve32x-phase-b.md:42:- SEW=8 時 vf4 非法(無 2-bit 源)、e8 的 nsr 需 wide=16;逐項 legality 對 Spike。
./docs/adr/0055-zve32x-phase-b.md:59:  的 element-wise 項(B2 narrowing/ext 維持 ≤m1;B4 走自身群組)。
./docs/adr/0055-zve32x-phase-b.md:62:- **不動**:vector CSR 契約、mask/tail policy、EMUL/群組對齊守衛(既有,隨新 op 更新非法性)。
./docs/adr/0055-zve32x-phase-b.md:67:  - directed 網格:全 form(vv/vx/vi)× SEW(8/16/32)× LMUL(m1/m2/m4)× mask(vm/v0)× 邊界
./docs/adr/0055-zve32x-phase-b.md:70:- **green-wash 守衛**:①非法性(m8/群組對齊/widen-overlap/narrowing≤m1/vf4@e8/vmadc vd≠v0)
./docs/adr/0055-zve32x-phase-b.md:85:  118 commits 全符**(gate_62;全 form×SEW×LMUL m1/m2,含 shamt≥SEW 截斷、vsra sign edge)。
./docs/adr/0055-zve32x-phase-b.md:92:  會執行而分歧)。Grok 確認 B1 乾淨、給 B2 指引(narrowing 先,複用 vnclip bus + 2*SEW shift)。
./docs/adr/0055-zve32x-phase-b.md:101:- **B2 narrowing shift amount = `log2(2*SEW)` 位(4/5/**6**),非 log2(SEW)**——源是 2*SEW,
./docs/adr/0055-zve32x-phase-b.md:103:- **vzext/vsext = OPMVV(f3=010),f6=010010 與 vsbc(OPIVV)撞**——decode 必須以 f3 分,非只 f6。
./docs/adr/0055-zve32x-phase-b.md:104:  vext vs1 uimm 編碼:vf2=00110(z)/00111(s)、vf4=00100/00101、vf8=00010/00011。vext 無 vx/vi。
./docs/adr/0055-zve32x-phase-b.md:105:- **B2 narrowing/vext 的 EMUL/overlap**:dst EMUL = src/2(narrowing)或 ×2/×4(ext);Spike
./docs/adr/0055-zve32x-phase-b.md:106:  `require_noover` 對群組映射檢查 vd 不重疊源。「≤m1」只在 net dst EMUL=1 時套,LMUL=2→1 narrowing
./docs/adr/0049-rvv-phase-a.md:11:**做**(TFLM/Gemma int8 缺口):S1 mask 族、S2 saturating、S3 LMUL m2/m4、S4 POOL
./docs/adr/0049-rvv-phase-a.md:36:**S3 — LMUL m2/m4(單 commit 原子性,Grok+Codex 同裁)**:vexu 內 **multi-beat**(如
./docs/adr/0049-rvv-phase-a.md:39:**不裂 uop**(per-commit lockstep 不變)。非法:群組未對齊 vd/vs、EMUL>8。
./docs/adr/0049-rvv-phase-a.md:71:+ clip,fractional-LMUL 規則同 widening)。core.v:`eff_vxrm`(MEM+WB csr-next-val
./docs/adr/0049-rvv-phase-a.md:84:LMUL m2/m4 依裁定落地:vexu 內 **VM_GRP multi-beat**(drained-start 復用 vmem hold;每拍
./docs/adr/0049-rvv-phase-a.md:88:widen/redsum/nclip 維持自身規則、**vmem 維持 EMUL≤1(vlmax_el 補整數 LMUL 乘項)**。
./docs/adr/0049-rvv-phase-a.md:93:②e16/m2+vse16(EMUL=2)滑過 legality → 群組記憶體越界寫錯源。**Codex 1 真發現**:
./arch_review.html:631:    <li><b>RVV 補齊</b><span class="sub">mask / strided / saturating / LMUL + lockstep</span></li>
./docs/adr/0054-zve32x-completeness-roadmap.md:25:vredsum.vs、vmv.x.s/vmv.s.x、vmerge、vmv.v.*、LMUL m1/mf*/m2/m4(**m8 禁**)。tail 恆 undisturbed
./docs/adr/0054-zve32x-completeness-roadmap.md:28:**這遠非完整 Zve32x**——缺:全部 bitwise/shift、一般 multiply/MAC、多數 widening/narrowing、
./docs/adr/0054-zve32x-completeness-roadmap.md:38:- **narrowing shift**:vnsrl/vnsra(**複用既有 vnclip datapath**,去掉 clip)
./docs/adr/0054-zve32x-completeness-roadmap.md:39:- **extension**:vzext.vf2/vf4、vsext.vf2/vf4
./docs/adr/0054-zve32x-completeness-roadmap.md:74:### Phase-F — m8 LMUL(scaling)
./docs/adr/0054-zve32x-completeness-roadmap.md:80:  checkpoint 紀律)。每片 directed 網格(全 vv/vx/vi form × SEW × LMUL × mask)+ random 語料。
./docs/adr/0036-rvv-zve32x-exu.md:32:| **3A** | vector CSRs + config, **no datapath**; **P0④ lands here** | `vsetvli/vsetivli` (incl. `rs1=x0`/`rd=x0` keep semantics); CSRs `vtype/vl/vstart/vxsat/vcsr/vlenb`; `vill` set + propagation (post-illegal config every vector op is illegal until a legal `vsetvli`); fractional LMUL legality (`mf2/mf4/mf8`) and `vlmax` math |
./docs/adr/0036-rvv-zve32x-exu.md:33:| **3B** | VRF 32×128b + same-SEW integer ALU | `vadd.vv/vsub.vv/vmv.v.v/vmv.v.x/vmv.v.i`, `vmv.x.s`, `vmerge.vvm` (mask plumbing smoke); LMUL 1 + fractional; lane iterator |
./docs/adr/0036-rvv-zve32x-exu.md:42:**Deferred honestly (recorded):** strided/indexed loads, LMUL m2/m4/m8 (m1+fractional only),
./docs/adr/0036-rvv-zve32x-exu.md:72:| `gate_40_vector_csr_lockstep` | 3A | `vsetvli/vsetivli` grid (SEW×LMUL incl. mf2/4/8, boundary vl = vlmax/vlmax−1/1, keep-vl x0 matrix) with dense `csrr` checkpoints — 100% scalar-stream match vs Spike |
./docs/adr/0036-rvv-zve32x-exu.md:84:1. Fractional-LMUL `vlmax` math (`e8,mf4` is kernel-critical) → gate_40 boundary grid.
./docs/adr/0036-rvv-zve32x-exu.md:87:4. Widening dest-overlap/EMUL legality (`vwmul/vwadd.wv`) → gate_44 + directed illegal encodings.
./docs/adr/0036-rvv-zve32x-exu.md:92:**Gates 40/41 green.** `gate_40`: vset{i}vl{i}/vsetvl grid (SEW×LMUL incl. mf4/mf2, AVL
./docs/adr/0036-rvv-zve32x-exu.md:129:architecture review: approve; flags adopted as stage gates — LMUL>1 needed only post-kernel
./docs/adr/0036-rvv-zve32x-exu.md:136:with EMUL=mf4, partial-vl stores with sentinels, whole-register store proving the
./docs/adr/0036-rvv-zve32x-exu.md:184:(masking, saturating ops, strided memory, LMUL>1) remains recorded future work.
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:24:| vzext/vsext | 010010 | **OPMVV only** (010) | no vx/vi |
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:26:`f6=010010` collision between `vsbc` (OPIVV) and `vzext` (OPMVV) is legal — decode must gate on `f3`, not `f6` alone.
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:32:| vzext.vf8 | 00010 |
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:33:| vsext.vf8 | 00011 |
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:34:| vzext.vf4 | 00100 |
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:35:| vsext.vf4 | 00101 |
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:36:| vzext.vf2 | 00110 |
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:37:| vsext.vf2 | 00111 |
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:62:**Narrowing shift amount (B2)**: **different width** — source is 2×SEW wide → mask is **`log2(2×SEW)` bits** (4/5/**6** @ SEW 8/16/32). At SEW=32, narrowing needs **6** bits; regular `vsrl` needs 5. **Spike-mismatch risk** if B1 SHW reused for vnsrl/vnsra.
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:72:## 4. B2 narrowing + vext roles
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:82:**EMUL / overlap (Spike `require_nooverlap`)**
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:84:- Dest EMUL = src EMUL / 2 (halving). Spike enforces `vd` not overlapping `vs2`/`vs1` under group mapping.
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:85:- Proposal “≤ m1” is fine as implementation scope if only invoked when net dest EMUL = 1; at LMUL=2→1 narrowing is spec-legal — don’t blanket-illegal if Spike allows it.
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:89:- `vzext.vf2`: SEW/2 → SEW zero-extend; dest EMUL = 2 × src EMUL.
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:90:- `vf4`: SEW/4 → SEW; dest EMUL = 4 × src EMUL.
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:91:- `vf8`: SEW/8 → SEW; dest EMUL = 8 × src EMUL.
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:97:| vf2 @ e8/e16/e32 | ✓ (4/8/16-bit src) |
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:98:| vf4 @ e8/e16/e32 | ✓ (2/4/8-bit src) |
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:99:| vf8 @ e8/e16/e32 | ✓ (1/2/4-bit src) |
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:101:No “vf4 illegal at e8”. **vf8 is in Zve32x** (not stripped). Illegality is via **EMUL>8** or **vill**, not SEW alone at e8.
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:103:**4b confirmed**: vnsrl/vnsra = OPI*; vzext/vsext = OPMVV only.
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:146:- Ignores **vl**, **vtype** fields (LMUL/SEW/TA/MA) except **vill=1 → illegal**.
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:166:3. **B2** (vnsrl/vnsra + vext) — new EMUL/overlap + **6-bit** narrowing shamt.
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:174:| 2 | **B2** | `log2(2×SEW)` shamt; EMUL halving overlap; vext EMUL expansion |
./docs/reviews/2026-07-05_phase_b_encoding_grok.md:178:**Pre-RTL checklist**: extend decode with `(f6, f3)` tuple for `010010`; separate narrowing SHW from ordinary SHW; B3 illegality table as Spike gate cases before lockstep vectors.
./docs/reviews/2026-07-04_gemini_backfill_and_rvv_dossier.md:70:*   **vsetvli Execution:** The `vsetvli rd, rs1, vtypei` instruction calculates the legal vector length (`vl`) based on standard LMUL and SEW parameters against `VLEN=128`, writing the result to the destination register `rd` and updating `vtype` and `vl`.
./docs/reviews/2026-07-04_gemini_backfill_and_rvv_dossier.md:79:*   **Supported LMULs:** Fractional LMULs `mf4` (1/4 vector register grouping) and `mf2` (1/2 grouping) to support the widening operations (`vwmul` and `vwadd` double the element width, meaning an `mf4` group of 8-bit elements widens to an `mf2` group of 16-bit elements), and integer LMUL `m1` for final reduction.
./docs/reviews/2026-07-04_gemini_backfill_and_rvv_dossier.md:81:    *   `vsetvli` (SEW/LMUL configuration logic).
./docs/reviews/2026-07-04_gemini_backfill_and_rvv_dossier.md:90:    *   *Large LMULs (`m4`, `m8`):* Multi-register grouping state machines can be deferred; mapping groups to a maximum of `m1`/`m2` simplifies the vector register file (VRF) port arbitration.
./flow/v2_pipeline/phase_03_09_riscvdv_lockstep/config/m1_riscvdv/riscv_core_setting.py:27:MAX_LMUL = 8
./flow/v2_pipeline/phase_03_09_riscvdv_lockstep/config/m1_riscvdv/riscv_core_setting.sv:40:parameter int MAX_LMUL = 8;

codex
One thing outside the seven bullets stood out in the local ADR notes: the B2 section calls out overlap/EMUL behavior as a risk area. I’m checking whether this implementation deliberately scopes that away or whether it creates a real Spike-visible legality gap.
exec
/bin/bash -lc "nl -ba flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S | sed -n '1,130p'" in /home/edauser/project/SOC/Magpie_M3V
exec
/bin/bash -lc "nl -ba docs/adr/0055-zve32x-phase-b.md | sed -n '32,112p'" in /home/edauser/project/SOC/Magpie_M3V
 succeeded in 0ms:
    32	| vsra | 101001 | vv/vx/vi | `as >>> b[SHW-1:0]`(arith) |
    33	
    34	mask/tail 同 add(active = masked-off undisturbed);vstart≠0 arith 仍 illegal(現況一致)。
    35	
    36	### B2 — narrowing shift + extension(複用既有寬/窄 datapath)
    37	- **vnsrl(101100)/vnsra(101101)**(wv/wx/wi):2*SEW 源右移 → SEW 目標(取低 SEW 位)。**複用
    38	  vnclip 的 wide→narrow 結構**,去掉 clip/round(vnclip 已在 S2)。narrowing → 非群組(≤m1,同
    39	  vnclip 的 grp_only_illegal 規則)。
    40	- **vzext/vsext.vf2/vf4**(OPMVV f6=010010,vs1 選變體:vf2=00110/00111、vf4=00100/00101):
    41	  SEW/2 或 SEW/4 源零/符號延伸 → SEW。dst-only,非群組先做(m1)。
    42	- SEW=8 時 vf4 非法(無 2-bit 源)、e8 的 nsr 需 wide=16;逐項 legality 對 Spike。
    43	
    44	### B3 — carry/borrow(mask 當 carry 源/目標)
    45	- **vadc(010000 vvm/vxm/vim)**:`a + b + v0[i]`;**vmadc(010001)**:carry-out → mask dest。
    46	- **vsbc(010010)/vmsbc(010011)**:borrow 版。
    47	- 注意:vadc/vsbc 用 mask 當 **carry-in**(非 predicate,vm=0 編碼但**所有 element 都算**);
    48	  vmadc/vmsbc 寫 **mask register**(單暫存器,同 compare 的 mask-dest 路徑)。legality:vd 不得
    49	  = v0(mask 源)於 vmadc/vmsbc 帶 mask 形。
    50	
    51	### B4 — whole-register move(vmv1r/2r/4r/8r.v)
    52	- OPIVI f6=100111,`simm` 欄編 NREG-1(0/1/3/7 → 1/2/4/8 reg)。複製 NREG 個 vector reg
    53	  (vd..vd+N-1 = vs2..vs2+N-1),與 vl/vtype 無關(整暫存器)。用群組寫路徑(WB 多 part)或
    54	  多-beat;vd/vs2 需 NREG 對齊。
    55	
    56	## §3 契約(§2 第 2 問)
    57	
    58	- **decode**:每 op 加 `wire op_X = (f6==...) && (form)`;`known_op` += 全部;`beats_op` += B1
    59	  的 element-wise 項(B2 narrowing/ext 維持 ≤m1;B4 走自身群組)。
    60	- **datapath**:B1 加 g_sew8/16/32 mux 項;B2 複用 nclip/widen 路徑;B3 加 carry 鏈 + mask-dest;
    61	  B4 加 reg-group copy。
    62	- **不動**:vector CSR 契約、mask/tail policy、EMUL/群組對齊守衛(既有,隨新 op 更新非法性)。
    63	
    64	## §4 驗證計畫(§2 第 3 問)+ green-wash 守衛
    65	
    66	- **權威 = Spike lockstep `--isa=zve32x_zvl128b`**(phase_22 harness)。每子片:
    67	  - directed 網格:全 form(vv/vx/vi)× SEW(8/16/32)× LMUL(m1/m2/m4)× mask(vm/v0)× 邊界
    68	    (vl=0/vstart/tail);shift 全 shamt(含 ≥SEW 的截斷)。
    69	  - random 語料擴新 f6(gen_vector_random 加這些 op),多 seed。
    70	- **green-wash 守衛**:①非法性(m8/群組對齊/widen-overlap/narrowing≤m1/vf4@e8/vmadc vd≠v0)
    71	  必有 illegal-ladder directed ②不裂算術 ③新增 0 回歸(對 fail baseline diff)④lint clean。
    72	- gate:gate_62(B1)... 逐子片一個 gate,或擴 gate_56/57 系列。
    73	
    74	## §5 review 後才實作
    75	
    76	accepted 後:Grok 複核(編碼/語意 hazard)→ Codex 外科實作(逐子片)→ 我跑 Spike lockstep
    77	directed+random → commit。**逐子片把關,B1 證完才進 B2**(同 Phase-A 嚴格分片)。
    78	
    79	## §6 實作結果
    80	
    81	- **B1 完成(2026-07-05)**:vand/vor/vxor、vsll/vsrl/vsra、vrsub 加進 g_sew8/16/32 mux +
    82	  known_op/beats_op。shift amount 取 `b[SHW-1:0]`。**bug 抓到並修**:vsra 的 `as >>> shamt` 在
    83	  unsigned ternary context 被當**邏輯右移**(負數 sign 不延伸)——用自決定 signed 中間 wire
    84	  `sra_r` 修(recurring Verilog gotcha,memory 已記)。**Spike lockstep `--isa=zve32x_zvl128b`
    85	  118 commits 全符**(gate_62;全 form×SEW×LMUL m1/m2,含 shamt≥SEW 截斷、vsra sign edge)。
    86	  既有 vector 測試(grid/s1/s2/s3/vrand)全綠無回歸。
    87	  **三方 review(Codex/Gemini/Grok)抓到 118-commit lockstep 漏的一個真洞**:masked-body
    88	  `vd==v0` 非法檢查漏 op_b1(masked vm=0 + vd=v0 dest 與 mask 源 v0 重疊,RVV §5.3 應 illegal;
    89	  現有檢查涵蓋 add/sub/mm/s2same/nc 卻漏 B1)。**Codex 與 Gemini 獨立都抓到**(random 語料 vd≠0
    90	  排除故漏,同 ADR-0049 S1 盲區)。修=`op_b1` 加進該檢查;firmware 加 illegal terminator
    91	  (`vand.vv v0,v1,v2,v0.t`)——DUT+Spike 同點 trap illegal,lockstep **120 commits** 匹配(沒修
    92	  會執行而分歧)。Grok 確認 B1 乾淨、給 B2 指引(narrowing 先,複用 vnclip bus + 2*SEW shift)。
    93	  **測試基建修**:`-mno-relax` 加進 phase_22 firmware 編譯——`la`/data-table 位址在 DUT(base
    94	  0x0)會被 relaxation 收成 `li`(絕對定址),Spike(base 0x8000_0000)不能 → instr 編碼分歧;
    95	  `-mno-relax` 強制 PC-relative,兩邊一致。(這解鎖了 data-table + vse/lw 逐 element 驗證法。)
    96	- **B2 __/ B3 __/ B4 __**（續）。
    97	
    98	## 附:Grok 架構複核(2026-07-05,全文歸檔 docs/reviews/2026-07-05_phase_b_encoding_grok.md)
    99	
   100	**B1 全對**(已 lockstep 驗)。**B2-B4 關鍵 flags(續做時務必遵守)**:
   101	- **B2 narrowing shift amount = `log2(2*SEW)` 位(4/5/**6**),非 log2(SEW)**——源是 2*SEW,
   102	  SEW=32 要 **6 位**;**不可複用 B1 的 SHW**(Spike-mismatch 風險)。
   103	- **vzext/vsext = OPMVV(f3=010),f6=010010 與 vsbc(OPIVV)撞**——decode 必須以 f3 分,非只 f6。
   104	  vext vs1 uimm 編碼:vf2=00110(z)/00111(s)、vf4=00100/00101、vf8=00010/00011。vext 無 vx/vi。
   105	- **B2 narrowing/vext 的 EMUL/overlap**:dst EMUL = src/2(narrowing)或 ×2/×4(ext);Spike
   106	  `require_noover` 對群組映射檢查 vd 不重疊源。「≤m1」只在 net dst EMUL=1 時套,LMUL=2→1 narrowing
   107	  是 spec-legal,**別一律 blanket-illegal**。
   108	- **B3 f6**:vadc 010000/vmadc 010001/vsbc 010010/vmsbc 010011,全 vvm/vxm/vim。vi 立即數:shift
   109	  用 uimm5,但 vrsub/bitwise 的 vi 用 **sext(imm5)**(B1 已正確)。
   110	- **B4**:OPIVI f6=100111,僅 vi。

 succeeded in 0ms:
     1	/* ADR-0055 Phase-B B2a directed: narrowing shift vnsrl/vnsra (.wv/.wx/.wi).
     2	   wide 2*SEW source >> shamt -> SEW dest (low bits); reuses the vnclip wide bus
     3	   minus round/clip. Only SEW8 (src e16) and SEW16 (src e32) — SEW32 narrowing
     4	   needs a 64-bit source, absent in Zve32x. Fractional LMUL (source EMUL=2*LMUL
     5	   <=1). vnsra sign edges shown with shamt >= 9 (the sign-fill reaches the low
     6	   SEW bits). Terminator = masked vd==v0 illegal. Spike --isa=zve32x is authority. */
     7	.section .init
     8	.global _start
     9	_start:
    10	    li   t0, 0x200
    11	    csrs mstatus, t0
    12	    lla  x20, wsrc16
    13	    lla  x21, sh8
    14	    lla  x19, wsrc32
    15	    lla  x18, sh16
    16	    lla  x22, dst
    17	
    18	    /* ===== e8 dest from e16 source (narrow 16->8), mf2 vl=8 ===== */
    19	    li   a0, 8
    20	    vsetvli t1, a0, e16, mf2, ta, ma
    21	    vle16.v v2, (x20)          /* wide 16-bit source (incl negatives) */
    22	    vsetvli t1, a0, e8, mf2, ta, ma
    23	    vle8.v  v1, (x21)          /* per-element shamts (8-bit) */
    24	
    25	    vnsrl.wv v3, v2, v1
    26	    vse8.v   v3, (x22)
    27	    lw t3, 0(x22)
    28	    lw t4, 4(x22)
    29	    vnsra.wv v3, v2, v1        /* arithmetic — differs where shamt>=9 */
    30	    vse8.v   v3, (x22)
    31	    lw t3, 0(x22)
    32	    lw t4, 4(x22)
    33	    vnsrl.wi v3, v2, 12        /* large shamt: logical zero-fill */
    34	    vse8.v   v3, (x22)
    35	    lw t3, 0(x22)
    36	    vnsra.wi v3, v2, 12        /* large shamt: sign-fill into low byte */
    37	    vse8.v   v3, (x22)
    38	    lw t3, 0(x22)
    39	    lw t4, 4(x22)
    40	    li t2, 3
    41	    vnsrl.wx v3, v2, t2
    42	    vse8.v   v3, (x22)
    43	    lw t3, 0(x22)
    44	    li t2, 11                  /* wx shamt masked to low 4 bits -> 11 */
    45	    vnsra.wx v3, v2, t2
    46	    vse8.v   v3, (x22)
    47	    lw t3, 0(x22)
    48	    lw t4, 4(x22)
    49	
    50	    /* ===== e16 dest from e32 source (narrow 32->16), mf2 vl=4 =====
    51	       load the wide 32-bit source with an EEW=32 unit-stride load AT the
    52	       e16/mf2 vtype (EMUL=EEW/SEW*LMUL = 32/16*mf2 = m1); avoids e32/mf2. */
    53	    li   a0, 4
    54	    vsetvli t1, a0, e16, mf2, ta, ma
    55	    vle32.v v2, (x19)          /* wide 32-bit source (EEW32 @ SEW16) */
    56	    vle16.v v1, (x18)          /* shamts (16-bit) */
    57	    vnsrl.wv v3, v2, v1
    58	    vse16.v  v3, (x22)
    59	    lw t3, 0(x22)
    60	    lw t4, 4(x22)
    61	    vnsra.wv v3, v2, v1
    62	    vse16.v  v3, (x22)
    63	    lw t3, 0(x22)
    64	    lw t4, 4(x22)
    65	    vnsra.wi v3, v2, 20        /* large shamt (>=17): sign-fill */
    66	    vse16.v  v3, (x22)
    67	    lw t3, 0(x22)
    68	    vnsrl.wi v3, v2, 20
    69	    vse16.v  v3, (x22)
    70	    lw t3, 0(x22)
    71	
    72	    /* ===== B2b vzext/vsext ===== */
    73	    lla  x17, esrc8
    74	    li   a0, 16
    75	    vsetvli t1, a0, e8, m1, ta, ma
    76	    vle8.v  v2, (x17)          /* signed 8-bit source (0x80/0xFF... negatives) */
    77	    /* vf2 -> e16 */
    78	    li   a0, 8
    79	    vsetvli t1, a0, e16, m1, ta, ma
    80	    vzext.vf2 v3, v2
    81	    vse16.v  v3, (x22)
    82	    lw t3, 0(x22)
    83	    lw t4, 4(x22)
    84	    vsext.vf2 v3, v2           /* sign-extend: 0x80 -> 0xFF80 */
    85	    vse16.v  v3, (x22)
    86	    lw t3, 0(x22)
    87	    lw t4, 12(x22)
    88	    /* vf4 -> e32 (8-bit source) */
    89	    li   a0, 4
    90	    vsetvli t1, a0, e32, m1, ta, ma
    91	    vsext.vf4 v3, v2
    92	    vse32.v  v3, (x22)
    93	    lw t3, 0(x22)
    94	    lw t4, 12(x22)
    95	    vzext.vf4 v3, v2
    96	    vse32.v  v3, (x22)
    97	    lw t3, 0(x22)
    98	    /* vf2 -> e32 (16-bit source) */
    99	    vsetvli t1, a0, e16, m1, ta, ma
   100	    vle16.v v4, (x20)          /* 16-bit source (wsrc16, negatives) */
   101	    vsetvli t1, a0, e32, m1, ta, ma
   102	    vsext.vf2 v3, v4
   103	    vse32.v  v3, (x22)
   104	    lw t3, 0(x22)
   105	    lw t4, 4(x22)
   106	
   107	    /* terminator: masked narrowing writing v0 = ILLEGAL (dest overlaps mask) */
   108	    li   a0, 8
   109	    vsetvli t1, a0, e8, mf2, ta, ma
   110	    vnsrl.wv v0, v2, v1, v0.t
   111	    ebreak
   112	
   113	.section .data
   114	.align 6
   115	wsrc16:
   116	    .short 0x0001, 0x8000, 0xFF00, 0x1234, 0x8010, 0x7FFF, 0xABCD, 0x0080
   117	sh8:
   118	    .byte 0, 1, 4, 8, 12, 15, 3, 9
   119	    .byte 0, 0, 0, 0, 0, 0, 0, 0
   120	.align 6
   121	wsrc32:
   122	    .word 0x00000001, 0x80000000, 0xFFFF0000, 0x12345678
   123	sh16:
   124	    .short 0, 4, 20, 31
   125	    .short 0, 0, 0, 0
   126	esrc8:
   127	    .byte 0x80, 0xFF, 0x7F, 0x01, 0xC0, 0x3F, 0x88, 0x08
   128	    .byte 0xF0, 0x0F, 0xA5, 0x5A, 0x00, 0xFE, 0x40, 0x81
   129	.align 6
   130	dst:

exec
/bin/bash -lc "nl -ba docs/reviews/2026-07-05_phase_b_encoding_grok.md | sed -n '80,110p'" in /home/edauser/project/SOC/Magpie_M3V
 succeeded in 0ms:
    80	**vnsrl.wx / .wi**: same source; scalar `rs1` or uimm5 shift for all elements.
    81	
    82	**EMUL / overlap (Spike `require_nooverlap`)**
    83	
    84	- Dest EMUL = src EMUL / 2 (halving). Spike enforces `vd` not overlapping `vs2`/`vs1` under group mapping.
    85	- Proposal “≤ m1” is fine as implementation scope if only invoked when net dest EMUL = 1; at LMUL=2→1 narrowing is spec-legal — don’t blanket-illegal if Spike allows it.
    86	
    87	**vext** (OPMVV, `vd`/`vs2` only; `vs1` = variant uimm)
    88	
    89	- `vzext.vf2`: SEW/2 → SEW zero-extend; dest EMUL = 2 × src EMUL.
    90	- `vf4`: SEW/4 → SEW; dest EMUL = 4 × src EMUL.
    91	- `vf8`: SEW/8 → SEW; dest EMUL = 8 × src EMUL.
    92	
    93	**SEW legality @ Zve32x (SEW ∈ {8,16,32})**
    94	
    95	| insn | legal? |
    96	|------|--------|
    97	| vf2 @ e8/e16/e32 | ✓ (4/8/16-bit src) |
    98	| vf4 @ e8/e16/e32 | ✓ (2/4/8-bit src) |
    99	| vf8 @ e8/e16/e32 | ✓ (1/2/4-bit src) |
   100	
   101	No “vf4 illegal at e8”. **vf8 is in Zve32x** (not stripped). Illegality is via **EMUL>8** or **vill**, not SEW alone at e8.
   102	
   103	**4b confirmed**: vnsrl/vnsra = OPI*; vzext/vsext = OPMVV only.
   104	
   105	---
   106	
   107	## 5. B3 carry/borrow — highest semantic risk
   108	
   109	**vm bit meaning (inverted from body-mask intuition)**
   110	

exec
/bin/bash -lc 'rg -n "vlmul|vsew|vill|SEW/LMUL|mf8|vtype" design/cpu_m1/rtl -S' in /home/edauser/project/SOC/Magpie_M3V
 succeeded in 0ms:
design/cpu_m1/rtl/core.v:83:    output     [31:0] rvvi_vtype,
design/cpu_m1/rtl/core.v:612:    reg [31:0] ex_mem_vcfg_vtype_r;
design/cpu_m1/rtl/core.v:714:        input [31:0] vtype;
design/cpu_m1/rtl/core.v:721:            sew_bits = 32'd8 << vtype[5:3];
design/cpu_m1/rtl/core.v:722:            base_elems = 32'd16 >> vtype[5:3]; // VLEN=128, SEW in {8,16,32}
design/cpu_m1/rtl/core.v:725:            if (vtype[31] || (vtype[30:8] != 23'h0) || (vtype[5:3] > 3'd2) ||
design/cpu_m1/rtl/core.v:726:                (vtype[2:0] == 3'b100)) begin
design/cpu_m1/rtl/core.v:730:            case (vtype[2:0])
design/cpu_m1/rtl/core.v:736:                    vlmax = base_elems >> 3;       // mf8
design/cpu_m1/rtl/core.v:763:    wire [31:0] rvv_cur_vtype  = (ex_mem_valid_r && ex_mem_vcfg_we_r) ? ex_mem_vcfg_vtype_r :
design/cpu_m1/rtl/core.v:764:                                 (ex_wb_valid_r  && ex_wb_vcfg_we_r)  ? ex_wb_vcfg_vtype_r : csr_vtype;
design/cpu_m1/rtl/core.v:782:    wire [31:0] rvv_req_vtype  = id_is_vsetvl   ? rs2_val :
design/cpu_m1/rtl/core.v:785:    wire [32:0] rvv_new_info   = rvv_vlmax_info(rvv_req_vtype);
design/cpu_m1/rtl/core.v:786:    wire [32:0] rvv_old_info   = rvv_vlmax_info(rvv_cur_vtype);
design/cpu_m1/rtl/core.v:787:    wire        rvv_new_vtype_legal = rvv_new_info[32];
design/cpu_m1/rtl/core.v:795:    wire        rvv_vill_next = !rvv_new_vtype_legal ||
design/cpu_m1/rtl/core.v:800:    wire [31:0] rvv_vl_next = rvv_vill_next ? 32'h0 : rvv_vl_next_raw;
design/cpu_m1/rtl/core.v:801:    wire [31:0] rvv_vtype_next = rvv_vill_next ? 32'h8000_0000 : rvv_req_vtype;
design/cpu_m1/rtl/core.v:907:        .q_vtype    (rvv_cur_vtype),
design/cpu_m1/rtl/core.v:1276:    wire [31:0] csr_vtype;
design/cpu_m1/rtl/core.v:1320:    reg [31:0] ex_wb_vcfg_vtype_r;
design/cpu_m1/rtl/core.v:1447:        .vcfg_vtype         (ex_wb_vcfg_vtype_r),
design/cpu_m1/rtl/core.v:1488:        .vtype_o            (csr_vtype),
design/cpu_m1/rtl/core.v:1515:                `CSR_VTYPE : id_csr_rdata = ex_mem_vcfg_vtype_r;
design/cpu_m1/rtl/core.v:1674:            ex_mem_vcfg_vtype_r      <= 32'h8000_0000;
design/cpu_m1/rtl/core.v:1774:            ex_mem_vcfg_vtype_r      <= rvv_vtype_next;
design/cpu_m1/rtl/core.v:1984:            ex_wb_vcfg_vtype_r      <= 32'h8000_0000;
design/cpu_m1/rtl/core.v:2084:            ex_wb_vcfg_vtype_r      <= ex_mem_vcfg_vtype_r;
design/cpu_m1/rtl/core.v:2398:    assign rvvi_vtype    = csr_vtype;
design/cpu_m1/rtl/csr.v:54:    input  [31:0]     vcfg_vtype,
design/cpu_m1/rtl/csr.v:119:    output [31:0]     vtype_o,
design/cpu_m1/rtl/csr.v:157:    reg [31:0] vtype_reg;
design/cpu_m1/rtl/csr.v:278:                `CSR_VTYPE   : csr_debug_read = (EN_RVV != 0) ? vtype_reg : 32'h0;
design/cpu_m1/rtl/csr.v:326:            `CSR_VTYPE   : csr_rdata = (EN_RVV != 0) ? vtype_reg : 32'h0;
design/cpu_m1/rtl/csr.v:413:                `CSR_VTYPE : csr_rdata = vcfg_vtype;
design/cpu_m1/rtl/csr.v:516:            vtype_reg    <= 32'h8000_0000;
design/cpu_m1/rtl/csr.v:649:                    `CSR_VTYPE   : if (EN_RVV != 0) vtype_reg <= debug_csr_wdata;
design/cpu_m1/rtl/csr.v:684:                vtype_reg  <= vcfg_vtype;
design/cpu_m1/rtl/csr.v:744:    assign vtype_o      = (EN_RVV != 0) ? vtype_reg : 32'h8000_0000;
design/cpu_m1/rtl/cpu_m1_axil_top.v:100:        .rvvi_v_valid(), .rvvi_v_vd(), .rvvi_v_wdata(), .rvvi_vl(), .rvvi_vtype(),
design/cpu_m1/rtl/vexu.v:13://   vmerge.vvm/vxm/vim, vmv.x.s. LMUL: m1 + fractional (mf2/mf4/mf8-legal
design/cpu_m1/rtl/vexu.v:34:    input  wire [31:0]  q_vtype,     // effective (forwarded) vtype
design/cpu_m1/rtl/vexu.v:169:                    ((ext_vf2 && ((vsew == 3'b001) || (vsew == 3'b010))) ||
design/cpu_m1/rtl/vexu.v:170:                     (ext_vf4 &&  (vsew == 3'b010)));
design/cpu_m1/rtl/vexu.v:173:    wire        vill  = q_vtype[31];
design/cpu_m1/rtl/vexu.v:174:    wire [2:0]  vlmul = q_vtype[2:0];
design/cpu_m1/rtl/vexu.v:175:    wire [2:0]  vsew  = q_vtype[5:3];
design/cpu_m1/rtl/vexu.v:178:    wire lmul_m2   = (vlmul == 3'b001);
design/cpu_m1/rtl/vexu.v:179:    wire lmul_m4   = (vlmul == 3'b010);
design/cpu_m1/rtl/vexu.v:180:    wire lmul_m8   = (vlmul == 3'b011);
design/cpu_m1/rtl/vexu.v:182:    wire cfg_illegal = vill || lmul_m8;
design/cpu_m1/rtl/vexu.v:202:    wire [2:0] frac_sh  = (vlmul == 3'b111) ? 3'd1 :
design/cpu_m1/rtl/vexu.v:203:                          (vlmul == 3'b110) ? 3'd2 :
design/cpu_m1/rtl/vexu.v:204:                          (vlmul == 3'b101) ? 3'd3 : 3'd0;
design/cpu_m1/rtl/vexu.v:209:    wire [6:0] vlmax_el = ({2'b0, 5'd16 >> vsew} << int_sh) >> frac_sh;
design/cpu_m1/rtl/vexu.v:222:    wire widen_lmul_ok = (vlmul == 3'b111) || (vlmul == 3'b110) || (vlmul == 3'b101);
design/cpu_m1/rtl/vexu.v:224:                         (!widen_lmul_ok || (vsew == 3'b010) ||
design/cpu_m1/rtl/vexu.v:253:    wire nc_illegal = (op_nc || op_nsr) && (!widen_lmul_ok || (vsew == 3'b010));
design/cpu_m1/rtl/vexu.v:283:    wire [5:0]  nl_el     = (vsew == 3'b000) ? 6'd16 : (vsew == 3'b001) ? 6'd8 : 6'd4;
design/cpu_m1/rtl/vexu.v:574:        red_sum = (vsew == 3'b000) ? {24'b0, vs1_data[7:0]} :
design/cpu_m1/rtl/vexu.v:575:                  (vsew == 3'b001) ? {16'b0, vs1_data[15:0]} : vs1_data[31:0];
design/cpu_m1/rtl/vexu.v:578:                case (vsew)
design/cpu_m1/rtl/vexu.v:586:    wire [127:0] res_red = (vsew == 3'b000) ? {vd_old[127:8],  red_sum[7:0]} :
design/cpu_m1/rtl/vexu.v:587:                           (vsew == 3'b001) ? {vd_old[127:16], red_sum[15:0]} :
design/cpu_m1/rtl/vexu.v:590:    wire [127:0] res_sx = (vsew == 3'b000) ? {vd_old[127:8],  q_rs1[7:0]} :
design/cpu_m1/rtl/vexu.v:591:                          (vsew == 3'b001) ? {vd_old[127:16], q_rs1[15:0]} :
design/cpu_m1/rtl/vexu.v:825:    wire [127:0] res_s2 = (vsew == 3'b000) ? res_s2_8 :
design/cpu_m1/rtl/vexu.v:826:                          (vsew == 3'b001) ? res_s2_16 : res_s2_32;
design/cpu_m1/rtl/vexu.v:827:    wire [127:0] res_nc = (vsew == 3'b000) ? res_nc8 : res_nc16;
design/cpu_m1/rtl/vexu.v:828:    wire part_sat_or = (op_s2same && ((vsew == 3'b000) ? (|s2_sat8) :
design/cpu_m1/rtl/vexu.v:829:                                      (vsew == 3'b001) ? (|s2_sat16_x[7:0]) :
design/cpu_m1/rtl/vexu.v:831:                       (op_nc && ((vsew == 3'b000) ? (|nc_sat8) : (|nc_sat16)));
design/cpu_m1/rtl/vexu.v:837:                            (vsew == 3'b000) ? res8 :
design/cpu_m1/rtl/vexu.v:838:                            (vsew == 3'b001) ? res16 : res32;
design/cpu_m1/rtl/vexu.v:839:    wire [15:0] cmp_seg  = (vsew == 3'b000) ? cmp_bits8 :
design/cpu_m1/rtl/vexu.v:840:                           (vsew == 3'b001) ? {8'b0, cmp_bits16} :
design/cpu_m1/rtl/vexu.v:842:    wire [127:0] mask_nl = (vsew == 3'b000) ? 128'hFFFF :
design/cpu_m1/rtl/vexu.v:843:                           (vsew == 3'b001) ? 128'hFF : 128'hF;
design/cpu_m1/rtl/vexu.v:852:    wire [127:0] res_cmp = (vsew == 3'b000) ? {cmpd_old[127:16], cmp_bits8}  :
design/cpu_m1/rtl/vexu.v:853:                           (vsew == 3'b001) ? {cmpd_old[127:8],  cmp_bits16} :
design/cpu_m1/rtl/vexu.v:878:                     op_vext ? ((vsew == 3'b001) ? res_ext16 : res_ext32) :
design/cpu_m1/rtl/vexu.v:879:                     op_widen ? ((vsew == 3'b000) ? res_w8 : res_w16) :
design/cpu_m1/rtl/vexu.v:882:                     (vsew == 3'b000) ? res8 :
design/cpu_m1/rtl/vexu.v:883:                     (vsew == 3'b001) ? res16 : res32;
design/cpu_m1/rtl/vexu.v:892:    assign q_scalar = (vsew == 3'b000) ? {{24{e0_8[7]}},  e0_8} :
design/cpu_m1/rtl/vexu.v:893:                      (vsew == 3'b001) ? {{16{e0_16[15]}}, e0_16} :
design/cpu_m1/rtl/cpu_m1_top.v:94:    output     [31:0] rvvi_vtype,
design/cpu_m1/rtl/cpu_m1_top.v:248:        .rvvi_vtype         (rvvi_vtype),

exec
/bin/bash -lc 'rg -n "vsext|vzext|vnsrl|vnsra|overlap|noover|vf8|vf4|vf2|vd == vs2|vd_i == vs2" tests flow docs IP -S' in /home/edauser/project/SOC/Magpie_M3V
 succeeded in 0ms:
flow/state/magpie_m3v.phase2_step4_npu_core.state.json:7:  "summary": "Phase 2 Step 4 (ADR-0034): stripped cpu_m1 sequencer (EN_RVC/BP/RAS=0, RESET_PC=0) instantiated inside npu_top, fetching through real npu_tcm core ports (FETCH_SRC=TCM realized as integration wiring). CTRL.start gates core reset (Coral cg-release shape); DONE mailbox @0x0001_0000 -> STATUS.npu_done + level IRQ; TCM write arbitration dma > core > host with host B-response held until grant. Authoritative verification (Claude, not Codex self-report): boot-from-TCM via host AXI load path, busy/done/IRQ/re-run (42->55) directed; Spike rv32im_zicsr_zifencei (NO C) lockstep directed 1164/1164 commits; random 8 seeds x 10,809 commits (loop-wrapped rv32im in 4KB TCM, ebreak-only terminator, mailbox never EOF) 0 divergences; DMA burst overlapped with running core - real overlap proven on internal retire/busy signals, 256-beat region exact, core result exact, program intact; strip coverage: bp/ras/cdec zero coverage points (generate-off at elaboration), no EN_* guard line uncovered, ifu 100%. No regression in existing suite (only pre-existing M1-era artifact gate failures, verified failing at pre-change HEAD).",
design/cpu_m1/rtl/vexu.v:8:// half-updated architectural state (vd==vs source overlap would otherwise not
design/cpu_m1/rtl/vexu.v:151:    // ---------------- Phase-B B2a (ADR-0055): narrowing shift (vnsrl/vnsra) ----
design/cpu_m1/rtl/vexu.v:159:    // ---------------- Phase-B B2b (ADR-0055): vzext/vsext.vf2/vf4 ----------------
design/cpu_m1/rtl/vexu.v:161:    // vs1 selects variant: [2:1]=11 vf2 / 10 vf4 / 01 vf8; [0]=1 sign, 0 zero.
design/cpu_m1/rtl/vexu.v:162:    // Zve32x: no e64 source -> vf8 always illegal; vf4 needs SEW32 (src8), vf2
design/cpu_m1/rtl/vexu.v:165:    wire ext_vf2  = (vs1_i[2:1] == 2'b11);
design/cpu_m1/rtl/vexu.v:166:    wire ext_vf4  = (vs1_i[2:1] == 2'b10);
design/cpu_m1/rtl/vexu.v:169:                    ((ext_vf2 && ((vsew == 3'b001) || (vsew == 3'b010))) ||
design/cpu_m1/rtl/vexu.v:170:                     (ext_vf4 &&  (vsew == 3'b010)));
design/cpu_m1/rtl/vexu.v:219:    // <= 1 (single register group) => LMUL must be fractional. Overlap (match
design/cpu_m1/rtl/vexu.v:220:    // Spike require_noover): a widening dest may not overlap a NARROWER source;
design/cpu_m1/rtl/vexu.v:226:                          (op_wmul && (vd_i == vs2_i)));
design/cpu_m1/rtl/vexu.v:252:    // low-part destination overlap (vd == vs2) is spec-legal for narrowing.
design/cpu_m1/rtl/vexu.v:265:                         // write v0 (dest overlaps the mask); mask-DEST compares
design/cpu_m1/rtl/vexu.v:603:    wire [127:0] res_ext16, res_ext32;   // B2b vzext/vsext
design/cpu_m1/rtl/vexu.v:759:            wire        [15:0] nsrl_w = v >> d;            // B2a vnsrl: logical
design/cpu_m1/rtl/vexu.v:760:            wire signed [15:0] nsra_w = vs >>> d;          // B2a vnsra: arithmetic (self-det signed)
design/cpu_m1/rtl/vexu.v:802:        // ---- B2b vzext/vsext: SEW/2 (vf2) or SEW/4 (vf4) source -> SEW dest ----
design/cpu_m1/rtl/vexu.v:803:        for (gi = 0; gi < 8; gi = gi + 1) begin : g_ext16   // dst e16, vf2 (src 8b)
design/cpu_m1/rtl/vexu.v:809:        for (gi = 0; gi < 4; gi = gi + 1) begin : g_ext32   // dst e32, vf2 (src 16b) / vf4 (src 8b)
design/cpu_m1/rtl/vexu.v:814:            wire [31:0] e  = ext_vf4 ? e4 : e2;
tests/gates/gate_52_memory_sizing.py:12:2R budget) AND a forced host-polling overlap makes the counter fire (the
docs/v2_pipeline_bug_taxonomy.md:9:| BUG-IRQ-0001 | CSR external IRQ pending | Phase 3.1 trap/IRQ lockstep | A one-cycle IRQ pulse overlapping trap entry can leave `ext_pending` set and cause repeated IRQ after `mret`. | Pulse-based external IRQ model uses one sticky pending bit; original lab08e `pulse > trap_enter > hold` priority preserves same-cycle pulses but can retain the current IRQ pulse through trap entry. | Local Magpie_M1 `csr.v` changed to `trap_enter > pulse > hold`; ADR-0003 records this as a local deviation. | `tests/gates/gate_03_01_trap_irq_lockstep.py`; `tests/gates/gate_03_02_irq_collision.py` | Closed for current pulse contract: single compressed IRQ path and collision contract pass. |
tests/gates/gate_63_rvv_b2_narrow_ext.py:3:B2a narrowing shift (vnsrl/vnsra, .wv/.wx/.wi): wide 2*SEW source >> shamt -> SEW
tests/gates/gate_63_rvv_b2_narrow_ext.py:6:Zve32x. shamt masked to log2(2*SEW) bits; vnsra arithmetic via a self-determined
tests/gates/gate_63_rvv_b2_narrow_ext.py:8:reaches the low SEW bits. B2b extension (vzext/vsext.vf2/vf4, OPMVV f6=010010,
tests/gates/gate_63_rvv_b2_narrow_ext.py:10:zero/sign extended; vf2 needs SEW>=16, vf4 needs SEW32, vf8 illegal (no e64).
tests/gates/gate_63_rvv_b2_narrow_ext.py:44:    for pat, floor in ((r"vnsrl\.", 3), (r"vnsra\.", 3),
tests/gates/gate_63_rvv_b2_narrow_ext.py:45:                       (r"vzext\.vf2", 1), (r"vsext\.vf2", 2),
tests/gates/gate_63_rvv_b2_narrow_ext.py:46:                       (r"vzext\.vf4", 1), (r"vsext\.vf4", 1)):
tests/gates/gate_33_npu_core_arbitration.py:3:tb_npu_core_arb overlaps a 256-beat DMA burst into TCM words 512..767 with a running
tests/gates/gate_33_npu_core_arbitration.py:4:300-iteration core load/store loop at word 64. Pass requires REAL overlap (core retired
tests/gates/gate_33_npu_core_arbitration.py:25:def test_dma_vs_core_arbitration_overlap(tmp_path):
tests/gates/gate_43_vector_lsu_tcm.py:18:arbitration (dma > core > host) already proven under overlap by gate_33; a dedicated
tests/gates/gate_43_vector_lsu_tcm.py:19:vector-vs-DMA overlap test is deferred to the 3D/system stage (honest note).
docs/v2_pipeline_full_verification_report.md:233:the `ext_pending` mux. If the pulse overlapped trap entry, pending could remain
design/npu/dv/tb/tb_npu_core_arb.v:2:// tb_npu_core_arb.v — ADR-0034 gate_33: DMA-vs-core TCM arbitration under overlap.
design/npu/dv/tb/tb_npu_core_arb.v:5://   - real overlap observed (core retires instructions while the DMA engine is busy)
design/npu/dv/tb/tb_npu_core_arb.v:69:    reg overlap_seen;
design/npu/dv/tb/tb_npu_core_arb.v:127:    // overlap evidence: the core retired an instruction on a cycle the DMA engine was busy
design/npu/dv/tb/tb_npu_core_arb.v:129:        if (!resetn) overlap_seen <= 1'b0;
design/npu/dv/tb/tb_npu_core_arb.v:130:        else if (dut.dma_busy_engine && dut.u_npu_core.u_core.wb_instr_retired) overlap_seen <= 1'b1;
design/npu/dv/tb/tb_npu_core_arb.v:171:        chk({31'b0, overlap_seen}, 32'h1, "true_overlap_core_retire_during_dma");
design/npu/dv/tb/tb_npu_memsize.v:183:        // ---- S3 checker: host-only traffic = zero; forced overlap = fires ----
design/npu/dv/tb/tb_npu_memsize.v:196:            $display("  FAIL checker never fired under forced 3-read overlap");
design/npu/dv/tb/tb_npu_memsize.v:198:            $display("  checker fired %0d times under forced overlap (expected)",
docs/adr/0035-command-queue-ssot.md:97:3. Sequencer DMA-fetch vs core fetch arbitration on the 4KB TCM → gate_36/37 overlap stress (extends gate_33 pattern).
docs/reviews/2026-07-05_cq_autonomous_prefetch_grok.md:29:| Step 6 only | 64 × (3 writes + mat poll) ≈ **1,500–4,000** cycles (compute-overlapped with requant CP) |
docs/reviews/2026-07-05_cq_autonomous_prefetch_grok.md:158:| **S3** | Stage `CSR_MAT_A/B` during `mat_run` poll | **Low–medium** — hides 2 MMIO writes (~6–10 cycles) if mat_run ≫ staging | Medium: GO-while-busy ignored → must not write CTRL early; same-bank accumulate forbids overlapping OP issue | Firmware (careful) |
docs/reviews/2026-07-05_phase_b_encoding_grok.md:23:| vnsrl/vnsra | 101100/101101 | OPIVV/VX/VI (000/100/011) | `.wv` / `.wx` / `.wi` |
docs/reviews/2026-07-05_phase_b_encoding_grok.md:24:| vzext/vsext | 010010 | **OPMVV only** (010) | no vx/vi |
docs/reviews/2026-07-05_phase_b_encoding_grok.md:26:`f6=010010` collision between `vsbc` (OPIVV) and `vzext` (OPMVV) is legal — decode must gate on `f3`, not `f6` alone.
docs/reviews/2026-07-05_phase_b_encoding_grok.md:32:| vzext.vf8 | 00010 |
docs/reviews/2026-07-05_phase_b_encoding_grok.md:33:| vsext.vf8 | 00011 |
docs/reviews/2026-07-05_phase_b_encoding_grok.md:34:| vzext.vf4 | 00100 |
docs/reviews/2026-07-05_phase_b_encoding_grok.md:35:| vsext.vf4 | 00101 |
docs/reviews/2026-07-05_phase_b_encoding_grok.md:36:| vzext.vf2 | 00110 |
docs/reviews/2026-07-05_phase_b_encoding_grok.md:37:| vsext.vf2 | 00111 |
docs/reviews/2026-07-05_phase_b_encoding_grok.md:62:**Narrowing shift amount (B2)**: **different width** — source is 2×SEW wide → mask is **`log2(2×SEW)` bits** (4/5/**6** @ SEW 8/16/32). At SEW=32, narrowing needs **6** bits; regular `vsrl` needs 5. **Spike-mismatch risk** if B1 SHW reused for vnsrl/vnsra.
docs/reviews/2026-07-05_phase_b_encoding_grok.md:74:**vnsrl.wv / vnsra.wv**
docs/reviews/2026-07-05_phase_b_encoding_grok.md:80:**vnsrl.wx / .wi**: same source; scalar `rs1` or uimm5 shift for all elements.
docs/reviews/2026-07-05_phase_b_encoding_grok.md:82:**EMUL / overlap (Spike `require_nooverlap`)**
docs/reviews/2026-07-05_phase_b_encoding_grok.md:84:- Dest EMUL = src EMUL / 2 (halving). Spike enforces `vd` not overlapping `vs2`/`vs1` under group mapping.
docs/reviews/2026-07-05_phase_b_encoding_grok.md:89:- `vzext.vf2`: SEW/2 → SEW zero-extend; dest EMUL = 2 × src EMUL.
docs/reviews/2026-07-05_phase_b_encoding_grok.md:90:- `vf4`: SEW/4 → SEW; dest EMUL = 4 × src EMUL.
docs/reviews/2026-07-05_phase_b_encoding_grok.md:91:- `vf8`: SEW/8 → SEW; dest EMUL = 8 × src EMUL.
docs/reviews/2026-07-05_phase_b_encoding_grok.md:97:| vf2 @ e8/e16/e32 | ✓ (4/8/16-bit src) |
docs/reviews/2026-07-05_phase_b_encoding_grok.md:98:| vf4 @ e8/e16/e32 | ✓ (2/4/8-bit src) |
docs/reviews/2026-07-05_phase_b_encoding_grok.md:99:| vf8 @ e8/e16/e32 | ✓ (1/2/4-bit src) |
docs/reviews/2026-07-05_phase_b_encoding_grok.md:101:No “vf4 illegal at e8”. **vf8 is in Zve32x** (not stripped). Illegality is via **EMUL>8** or **vill**, not SEW alone at e8.
docs/reviews/2026-07-05_phase_b_encoding_grok.md:103:**4b confirmed**: vnsrl/vnsra = OPI*; vzext/vsext = OPMVV only.
docs/reviews/2026-07-05_phase_b_encoding_grok.md:125:- **vd overlap**: `vd == vs1` or `vd == vs2` → illegal (vadc/vsbc/vmadc/vmsbc).
docs/reviews/2026-07-05_phase_b_encoding_grok.md:166:3. **B2** (vnsrl/vnsra + vext) — new EMUL/overlap + **6-bit** narrowing shamt.
docs/reviews/2026-07-05_phase_b_encoding_grok.md:167:4. **B3** (carry) — **last**; vm-bit polarity, illegality matrix, vd/v0 overlap.
docs/reviews/2026-07-05_phase_b_encoding_grok.md:174:| 2 | **B2** | `log2(2×SEW)` shamt; EMUL halving overlap; vext EMUL expansion |
docs/adr/0003-csr-external-irq-pending-collision.md:22:`ext_pending`. If `irq_external_pulse` overlaps trap entry, `ext_pending` can
docs/adr/0055-zve32x-phase-b.md:37:- **vnsrl(101100)/vnsra(101101)**(wv/wx/wi):2*SEW 源右移 → SEW 目標(取低 SEW 位)。**複用
docs/adr/0055-zve32x-phase-b.md:40:- **vzext/vsext.vf2/vf4**(OPMVV f6=010010,vs1 選變體:vf2=00110/00111、vf4=00100/00101):
docs/adr/0055-zve32x-phase-b.md:42:- SEW=8 時 vf4 非法(無 2-bit 源)、e8 的 nsr 需 wide=16;逐項 legality 對 Spike。
docs/adr/0055-zve32x-phase-b.md:70:- **green-wash 守衛**:①非法性(m8/群組對齊/widen-overlap/narrowing≤m1/vf4@e8/vmadc vd≠v0)
docs/adr/0055-zve32x-phase-b.md:103:- **vzext/vsext = OPMVV(f3=010),f6=010010 與 vsbc(OPIVV)撞**——decode 必須以 f3 分,非只 f6。
docs/adr/0055-zve32x-phase-b.md:104:  vext vs1 uimm 編碼:vf2=00110(z)/00111(s)、vf4=00100/00101、vf8=00010/00011。vext 無 vx/vi。
docs/adr/0055-zve32x-phase-b.md:105:- **B2 narrowing/vext 的 EMUL/overlap**:dst EMUL = src/2(narrowing)或 ×2/×4(ext);Spike
docs/adr/0055-zve32x-phase-b.md:106:  `require_noover` 對群組映射檢查 vd 不重疊源。「≤m1」只在 net dst EMUL=1 時套,LMUL=2→1 narrowing
design/npu/docs/01_axi_fabric_spec.md:117:- [ ] Double-buffer ping-pong / multi-outstanding bursts (overlap fetch with compute) — throughput.
docs/adr/0037-matrix-engine.md:44:MAT_PARAM probe (recorded gate transition); DMA∥engine overlap = deferred scoreboard
docs/adr/0037-matrix-engine.md:88:semantics, DMA∥engine overlap scoreboard (time-division SW contract documented),
docs/adr/0005-mem-valid-ready-wrapper.md:105:- Single-outstanding only — no overlapped I/D latency hiding (deferred).
docs/adr/0036-rvv-zve32x-exu.md:87:4. Widening dest-overlap/EMUL legality (`vwmul/vwadd.wv`) → gate_44 + directed illegal encodings.
docs/adr/0036-rvv-zve32x-exu.md:177:Codex 3D review: **CLEAN** (decode aliasing OPIVV/OPMVV f6=000000, widening overlap rules
docs/adr/0052-cq-autonomous-mat-op.md:88:**掃到的次要 win**:4a(ring config 迴圈外讀)採納;4b(issue/poll overlap)、4c(硬體 command
docs/adr/0018-cpu-subsystem-fpga-asic-variants.md:5:- Deciders: Claude (PL), 3-agent consensus (Grok strategy, Gemini overlap, Codex effort), user direction
design/cpu_m1/ip.json:133:          "reason": "Phase 3.1 directed trap/IRQ test found repeated IRQ after mret when a one-cycle pulse overlaps trap entry",
docs/adr/0023-rv32a-optional.md:17:- **Reservation lifetime**: set on LR; cleared on any overlapping store (incl. AMO beat1, failed SC),
docs/adr/0034-npu-core-tcm-integration.md:84:| `gate_33_npu_core_arbitration` | DMA write burst overlapped with running core (fetch+load/store); both complete, no X, TCM golden intact | scoreboard pass |
docs/adr/0034-npu-core-tcm-integration.md:96:scoreboard passed with real overlap (core retired instructions while the DMA engine was busy).
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1441: Number of Nodes with overlaps = 0
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1460:  Number of Node Overlaps             = 0
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1500: Number of Nodes with overlaps = 4322
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1501: Number of Nodes with overlaps = 2130
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1502: Number of Nodes with overlaps = 1288
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1503: Number of Nodes with overlaps = 705
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1504: Number of Nodes with overlaps = 283
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1505: Number of Nodes with overlaps = 91
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1506: Number of Nodes with overlaps = 22
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1507: Number of Nodes with overlaps = 7
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1508: Number of Nodes with overlaps = 4
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1509: Number of Nodes with overlaps = 0
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1517: Number of Nodes with overlaps = 741
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1518: Number of Nodes with overlaps = 533
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1519: Number of Nodes with overlaps = 396
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1520: Number of Nodes with overlaps = 220
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1521: Number of Nodes with overlaps = 153
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1522: Number of Nodes with overlaps = 72
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1523: Number of Nodes with overlaps = 24
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1524: Number of Nodes with overlaps = 5
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1525: Number of Nodes with overlaps = 2
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1526: Number of Nodes with overlaps = 2
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1527: Number of Nodes with overlaps = 0
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1535: Number of Nodes with overlaps = 1071
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1536: Number of Nodes with overlaps = 748
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1537: Number of Nodes with overlaps = 467
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1538: Number of Nodes with overlaps = 314
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1539: Number of Nodes with overlaps = 171
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1540: Number of Nodes with overlaps = 110
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1541: Number of Nodes with overlaps = 74
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1542: Number of Nodes with overlaps = 24
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1543: Number of Nodes with overlaps = 8
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1544: Number of Nodes with overlaps = 5
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1545: Number of Nodes with overlaps = 2
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1546: Number of Nodes with overlaps = 0
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1554: Number of Nodes with overlaps = 1445
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1555: Number of Nodes with overlaps = 776
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1556: Number of Nodes with overlaps = 340
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1557: Number of Nodes with overlaps = 149
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1558: Number of Nodes with overlaps = 67
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1559: Number of Nodes with overlaps = 42
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1577: Number of Nodes with overlaps = 0
flow/fpga/pynq_z2/synth_pynq_415218.backup.log:1614:  Number of Node Overlaps             = 0
flow/fpga/pynq_z2/synth_pynq.log:1022: Number of Nodes with overlaps = 0
flow/fpga/pynq_z2/synth_pynq.log:1041:  Number of Node Overlaps             = 0
flow/fpga/pynq_z2/synth_pynq.log:1065: Number of Nodes with overlaps = 2325
flow/fpga/pynq_z2/synth_pynq.log:1066: Number of Nodes with overlaps = 426
flow/fpga/pynq_z2/synth_pynq.log:1067: Number of Nodes with overlaps = 100
flow/fpga/pynq_z2/synth_pynq.log:1068: Number of Nodes with overlaps = 20
flow/fpga/pynq_z2/synth_pynq.log:1069: Number of Nodes with overlaps = 2
flow/fpga/pynq_z2/synth_pynq.log:1070: Number of Nodes with overlaps = 1
flow/fpga/pynq_z2/synth_pynq.log:1071: Number of Nodes with overlaps = 0
flow/fpga/pynq_z2/synth_pynq.log:1127:  Number of Node Overlaps             = 0
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1044: Number of Nodes with overlaps = 0
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1063:  Number of Node Overlaps             = 0
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1087: Number of Nodes with overlaps = 5065
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1088: Number of Nodes with overlaps = 2871
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1089: Number of Nodes with overlaps = 1443
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1090: Number of Nodes with overlaps = 660
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1091: Number of Nodes with overlaps = 218
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1092: Number of Nodes with overlaps = 125
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1093: Number of Nodes with overlaps = 47
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1094: Number of Nodes with overlaps = 17
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1095: Number of Nodes with overlaps = 11
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1096: Number of Nodes with overlaps = 14
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1097: Number of Nodes with overlaps = 3
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1098: Number of Nodes with overlaps = 2
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1099: Number of Nodes with overlaps = 0
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1107: Number of Nodes with overlaps = 840
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1108: Number of Nodes with overlaps = 748
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1109: Number of Nodes with overlaps = 428
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1110: Number of Nodes with overlaps = 221
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1111: Number of Nodes with overlaps = 116
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1112: Number of Nodes with overlaps = 80
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1113: Number of Nodes with overlaps = 51
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1114: Number of Nodes with overlaps = 23
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1115: Number of Nodes with overlaps = 17
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1116: Number of Nodes with overlaps = 9
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1117: Number of Nodes with overlaps = 5
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1118: Number of Nodes with overlaps = 3
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1119: Number of Nodes with overlaps = 3
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1120: Number of Nodes with overlaps = 0
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1128: Number of Nodes with overlaps = 961
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1129: Number of Nodes with overlaps = 528
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1130: Number of Nodes with overlaps = 469
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1131: Number of Nodes with overlaps = 248
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1132: Number of Nodes with overlaps = 164
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1133: Number of Nodes with overlaps = 118
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1134: Number of Nodes with overlaps = 57
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1135: Number of Nodes with overlaps = 48
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1136: Number of Nodes with overlaps = 15
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1137: Number of Nodes with overlaps = 8
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1138: Number of Nodes with overlaps = 3
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1139: Number of Nodes with overlaps = 1
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1140: Number of Nodes with overlaps = 0
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1148: Number of Nodes with overlaps = 994
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1149: Number of Nodes with overlaps = 590
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1150: Number of Nodes with overlaps = 305
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1151: Number of Nodes with overlaps = 253
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1152: Number of Nodes with overlaps = 134
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1153: Number of Nodes with overlaps = 82
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1154: Number of Nodes with overlaps = 33
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1155: Number of Nodes with overlaps = 26
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1156: Number of Nodes with overlaps = 15
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1157: Number of Nodes with overlaps = 5
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1158: Number of Nodes with overlaps = 2
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1159: Number of Nodes with overlaps = 2
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1160: Number of Nodes with overlaps = 1
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1161: Number of Nodes with overlaps = 0
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1181: Number of Nodes with overlaps = 0
flow/fpga/pynq_z2/synth_pynq_468943.backup.log:1218:  Number of Node Overlaps             = 0
docs/adr/0054-zve32x-completeness-roadmap.md:38:- **narrowing shift**:vnsrl/vnsra(**複用既有 vnclip datapath**,去掉 clip)
docs/adr/0054-zve32x-completeness-roadmap.md:39:- **extension**:vzext.vf2/vf4、vsext.vf2/vf4
docs/adr/0054-zve32x-completeness-roadmap.md:84:- green-wash:m8/群組對齊/widen-overlap 等既有非法性守衛(gate_42 誠實界)隨每階段更新。
flow/v2_pipeline/phase_p_lint_current/cpu_m1_phase_p_lint_current/consolidated_reports/cpu_m1_top_lint_lint_rtl/spyglass.log:3744:	-overlappingLatchLoops                             yes                  yes
flow/v2_pipeline/phase_p_lint_current/cpu_m1_phase_p_lint_current/consolidated_reports/cpu_m1_top_lint_lint_rtl/spyglass.log:3745:	-overlappingLoops                                  yes                  yes
flow/v2_pipeline/phase_p_lint_current/cpu_m1_phase_p_lint_current/consolidated_reports/cpu_m1_top_lint_lint_rtl/spyglass.log:4003: Reset_overlap01                clock-reset     No             - FLATDU2_ABSTRACT_PRD_WL   -               
flow/v2_pipeline/phase_p_lint_current/cpu_m1_phase_p_lint_current/consolidated_reports/cpu_m1_top_lint_lint_rtl/spyglass.log:4054: SGDC_filter_clock_overlap02    clock-reset     No             - SETUP          -               
flow/v2_pipeline/phase_p_lint_current/cpu_m1_phase_p_lint_current/consolidated_reports/cpu_m1_top_lint_lint_rtl/spyglass.log:4055: SGDC_filter_clock_overlap01    clock-reset     No             - SETUP          -               
flow/v2_pipeline/phase_p_lint_current/cpu_m1_phase_p_lint_current/consolidated_reports/cpu_m1_top_lint_lint_rtl/spyglass.log:4056: FilterClockOverlapSetup        clock-reset     No             - FLATDU2_ABSTRACT_PRD_WL   -               
flow/v2_pipeline/phase_p_lint_current/cpu_m1_phase_p_lint_current/consolidated_reports/cpu_m1_top_lint_lint_rtl/spyglass.log:5580: NoOverlappingCaseLabel-ML(Verilog) morelint        No             - ELABDU         -               
flow/v2_pipeline/phase_p_lint_current/cpu_m1_phase_p_lint_current/consolidated_reports/cpu_m1_top_lint_lint_rtl/spyglass.log:5952: IfOverlap-ML         (VHDL   ) morelint        No             - ELABDU         -               
flow/v2_pipeline/phase_p_lint_current/cpu_m1_phase_p_lint_current/consolidated_reports/cpu_m1_top_lint_lint_rtl/spyglass.log:5953: IfOverlap-ML         (Verilog) morelint        No             - ELABDU         -               
flow/v2_pipeline/phase_p_lint_current/cpu_m1_phase_p_lint_current/cpu_m1_top/lint/lint_rtl/in_tool_debug_data/spyglass_data.xml:1575:	<Param name="-overlappingLatchLoops">
flow/v2_pipeline/phase_p_lint_current/cpu_m1_phase_p_lint_current/cpu_m1_top/lint/lint_rtl/in_tool_debug_data/spyglass_data.xml:1579:	<Param name="-overlappingLoops">
flow/v2_pipeline/phase_20_npu_core_lockstep/ann_cov/vexu.v:9:        // half-updated architectural state (vd==vs source overlap would otherwise not
flow/v2_pipeline/phase_20_npu_core_lockstep/ann_cov/vexu.v:187:            // <= 1 (single register group) => LMUL must be fractional. Overlap (match
flow/v2_pipeline/phase_20_npu_core_lockstep/ann_cov/vexu.v:188:            // Spike require_noover): a widening dest may not overlap a NARROWER source;
flow/v2_pipeline/phase_20_npu_core_lockstep/ann_cov/vexu.v:194:                                  (op_wmul && (vd_i == vs2_i)));
flow/v2_pipeline/phase_20_npu_core_lockstep/ann_cov/vexu.v:219:            // low-part destination overlap (vd == vs2) is spec-legal for narrowing.
flow/v2_pipeline/phase_20_npu_core_lockstep/ann_cov/vexu.v:232:                                 // write v0 (dest overlaps the mask); mask-DEST compares
flow/v2_pipeline/phase_p_lint_current/cpu_m1_phase_p_lint_current/cpu_m1_top/lint/lint_rtl/spyglass.vdb:1253:##rulegroup: SystemVerilog DirectTopInputToInout-ML AlwaysFalseTrueCond-ML OperShortCircuit-ML NonVoidFunction-ML BitDataType-ML LogicEnumBase-ML TwoStateData-ML UnpackedStructUsed-ML InterfaceWithoutModport-ML UniqueCase-ML SVConstruct-ML DuplicateCase-ML AlwaysCombExhaustive-ML IfOverlap-ML 
flow/v2_pipeline/phase_p_lint_current/cpu_m1_phase_p_lint_current/cpu_m1_top/lint/lint_rtl/spyglass.vdb:1266:##rulegroup: VERIFY Reset_overlap01 Reset_check12 Reset_check11 Reset_check10 Reset_check09 Reset_check08 Reset_check07 Reset_check06 Reset_check05 Reset_check04 Reset_check03 Reset_check02 Reset_check01 Clock_Reset_check03 Clock_Reset_check02 Clock_Reset_check01 Clock_hier03 Clock_hier02 Clock_hier01 Clock_glitch04 Clock_glitch03 Clock_glitch02 Clock_glitch01 Clock_converge01 Clock_check10 Clock_check07 Clock_check06b Clock_check06a Clock_check05 Clock_check04 Clock_check03 Clock_check02 Clock_check01 Ar_converge02 Ar_converge01 
flow/v2_pipeline/phase_p_lint_current/cpu_m1_phase_p_lint_current/cpu_m1_top/lint/lint_rtl/spyglass.vdb:1292:##rulegroup: morelint ComplexPort-ML PreferImplicitPort-ML GenvarInCondExpr-ML CheckSVFile-ML CheckModulePrefix-ML CheckLocalParamOrder-ML preReq_DetectConstInSensListElements CheckParamInTop-ML VerilogAttributeInfo-ML CheckMacroPrefix-ML ImproperPackage-ML ImproperFileName-ML ImproperConfigFile-ML SeqAssignOutsideIf-ML MixedArch-ML SensitiveSigLoopCheck-ML NoLogicInWrapperModule-ML MemberWidthMismatch-ML IncludeFileWithPath-ML LogicalOpOnSingleBit-ML ParamPropagateMismatch-ML DisallowConstruct-ML IfMissingElse-ML InputSupplyNetDef-ML DisabledForLoop-ML ProtectDirUsage-ML IncompatibleTypedefUsed-ML DifferentTypedefUsed-ML RtlModuleGenerator-ML RtlSnippetGenerator-ML ConsecutiveRelationalOP-ML WidthlessConstantTiedPort-ML EscapedNameVariant-ML SignedSysFuncUsage-ML SignedUnsignedConvert-ML SignedKeywordUsage-ML POWER_DEFAULT_STATIC_ASSIGNMENT RedundantFlopArray-ML InterfaceModPort-ML ParameterizedInterface-ML InterfaceArray-ML InterfaceLogic-ML DuplicatePackageImport-ML AvoidMultiDimParam-ML AvoidInstArray-ML GlobalPackageImport-ML NegativeValueInfer-ML ScopedVarUsedBeforeDefine-ML VariableIndex-ML ContinuousRegAssign-ML InterfaceArraySliceIndexing-ML IndexSelectOnConcat-ML MultiTimeScaleUsage-ML SizeCastedSignedValue-ML NoUnsizedNUnbasedNum-ML MultipleInterfaceInstancesInFuncTaskCall-ML CheckXZShift-ML MultiDimInterfaceInstantiation-ML OverCasting-ML MultiAssignConcat-ML DisallowModules-ML NoAbsolutePathName-ML EnableName-ML ClockName-ML ResetName-ML LiteralUnderflow-ML Prereqs_Elab_Hier_Dialog GlueLogic-ML MixedLangBoundaryMismatch-ML DeclarationComment-ML Indentation-ML BitwiseOpOnSingleBit-ML CheckDeclKeywords-ML InoutNotRead-ML RedundantGenBlock-ML EnumTypeUsedWithRange-ML FunctionCallUsed-ML SignedType-ML InstanceComment-ML NextStateFsmName-ML NestedComment-ML SingleBitVector-ML SingleBitMemory-ML ZeroExtension-ML DuplicateInclude-ML PackageName-ML GenerateName-ML EnumValueName-ML EscapeSpace-ML SignalDrivenByConst-ML PortIndex-ML ExplicitSignedUnsignedExpr-ML NoOverlappingCaseLabel-ML NoLibCellInst-ML DetectNonStaticCaseLabels-ML InvalidReverseIndexing-ML CheckSyncResetUse-ML MultipleBitsInReset-ML NoExitInFSM-ML NoValueX-ML UnreachableStatesInFSM-ML ExternalVarUsage-ML SignCastInSelfDetermined-ML CondOpInReset-ML InternalResetDriver-ML InternalClockDriver-ML MultipleRangeDefine-ML ArrayAscending-ML CommonSubproduct-ML SignRange-ML InefficientRounding-ML SingleRangeInPacked-ML ValueAssignInDeclaration-ML SingleRangeInUnpacked-ML RightShiftTrunc-ML MultiplicationOpTrunc-ML LeftShiftTrunc-ML ClockMuxDriven-ML CaseWithDontCare-ML UniqueWithOneBranch-ML NonConstValueInShift-ML StringUsage-ML DisallowSignalType-ML ExprInSenseList-ML MismatchPortTypeInFuncTaskUse-ML MultipleSignDefine-ML CheckDelayFlopRace-ML ReportCppKeyWords-ML UseSystemTaskFunction-ML CheckFileName-ML FSMCurrentStateName-ML MultiDimArrayUsed-ML CheckEnumMethodUsage-ML DuplicateLabelInUniqueCase-ML CheckComplexForStmt-ML ExplicitParamDefine-ML UseParamInsteadDefine-ML InvalidEdgeSignalUsage-ML Unreachable-ML XOrZInCompare-ML ClockSignalInSenseList-ML PartialConstantAssign-ML OutputPortDirection-ML UseXInMuxCase-ML Prereqs_UseXInMuxCase-ML SignedBitPartSelect-ML RecursiveFunction-ML CheckParenthesesOfMacroOP-ML InvalidMacroCall-ML CheckFlopRaceCond-ML HierarchicalFunctionTask-ML DetectUnderAndOverFlows-ML DetectInvalidSignedAssignment-ML LatchInfo-ML UnsupportedSvFunction-ML ModuleComplexityInfo-ML SignalBitLength-ML ArrayUsedInSensList-ML ReportCompOperator-ML PortWithoutDirection-ML MissingPinFunctionCall-ML PortUsedBeforeDefine-ML ConstPropagatedPort-ML NonConstCompare-ML SignalModifiedAfterRead-ML BreakInMultiDimForeach-ML EnumOutOfRangeCast-ML InvalidVariedTypedefNameStyle-ML LiteralOverflow-ML ExplicitSignExtend-ML ExplicitTwosCompliment-ML MaxDelay-ML ConcatenationInArrayAssign-ML DuplicatePort-ML LongHierName-ML IncompatibleSVAssign-ML MissingPortInModport-ML SeqInputOutputCodeDup-ML RepeatedLogic-ML RedundantLogicalOpInExpr-ML VarInCaseInside-ML HierarchyReport-ML AssignPatInInst-ML UncoveredEnumCase-ML FsmUsage-ML NonBlockingCounters-ML NestedInterfaceInst-ML NonLocalLoopIndex-ML SpecifyBlockUsed-ML DivideByConstant-ML ArrayPortConnect-ML ConstBitCase-ML CheckPortType-ML SimSynthMismatchInVarInit-ML UniqueIfMissingCond-ML SpareCaseExprBit-ML BadResourceShare-ML MacroWithoutUndef-ML CheckSwappedIndex-ML NonReusableParametricModule-ML LoopVarFreeAssign-ML DisallowUnknownInCase-ML PackedArrayInRange-ML UndrivenCaseExpr-ML InstanceNameRequired-ML InvLatchFeed-ML ComplexModport-ML NonResetFSM-ML ConcatUnsizedNumbers-ML ShiftRegister-ML IncrementalForLoop-ML UseParamWidthInOverriding-ML DetectNonBlockGenFor-ML ClockConnectedToOut-ML RegisterDriveMultiplePorts-ML UseImplicitAlways-ML GenvarDeclaration-ML LoopVarInAlways-ML FlopFeedbackRace-ML ResetConnectedToOut-ML CheckAsyncHold-ML FSMNextStateName-ML NoArithShiftInConcat-ML ParamValueOverride-ML PortTypeMismatch-ML SameAssignment-ML HierNameLength-ML RealValueUsed-ML InoutPortConnectionSanity-ML PortIOConnectionSanity-ML UniquePriorityMisuse-ML SyncRstFirstUse-ML InvalidTypedefName-ML DisallowSVAlwaysLatch-ML DefineTypeDefStructure-ML CheckImplicitPort-ML AutomaticFuncOnly-ML AnsiPort-ML ImplicitAlways-ML PortConnToInout-ML CheckSignedFunc-ML CheckRegAndWire-ML InstPortConnType-ML NegativeIndex-ML CheckAlwaysCombSenseList-ML GlobalDataTypeDefined-ML BitRangeUsedParam-ML ProhibitedDataTypes-ML ClockFeedsFloatingGate-ML NoOutputPort-ML NonOverriddenParams-ML UnInitializedReset-ML PortConnectToFixedVal-ML NonSynthRepeat-ML CheckModulesWithoutPorts-ML LatchName-ML NonConstShift-ML CheckLocalParam-ML ImproperRangeIndex-ML Prereqs_ReportPortInfo-ML DisallowNoRstFlops-ML SelfGatingRegister-ML FuncTaskUsedBeforeDefine-ML NeverExecutingForLoop-ML InvalidRepeatCondition-ML PortWithoutType-ML CheckTimeUnitandPrecision-ML AutomaticFuncTask-ML ZeroReplicationMultiplier-ML ResetTiedToConst-ML FixedValueInCGCEnable-ML EnableXPropagation-ML MultOperVar-ML NoTopCombPath-ML UniqueInputOutputSampling-ML Postreqs_Usage_ML UseLogic-ML UseSVCasting-ML UseSVAlways-ML NoConstSourceInAlways-ML TypedefNameConflict-ML EnumBaseComparison-ML IncludeFileForEachModule-ML Prereqs_InclFileSetup-ML width_rules_ml CheckShiftOperator-ML NoGenLabel-ML PragmaComments-ML ReportPortInfo-ML UnUsedFunctionInput-ML InterfaceNameConflicts-ML OneLineComm-ML OneModule-ML NoVerilogPrims-ML PartSelectRange-ML GenvarUsage-ML SynthElabDuName-ML RptNegEdgeFF-ML HangingFlopOutput-ML PrintObjectDetails-ML CheckKeywordsOfCaseStmt-ML PortRange-ML CloseCaseWithX-ML UnUsedFlopOutput-ML MixedResetEdges-ML SigAssignZ-ML SigAssignX-ML DirectiveCheck-ML UnInitParam-ML UnInitTopDuParam-ML SameDu-ML SameControlNDataNet-ML MaxFanoutCount-ML EntityCompMismatch-ML HierarchicalModule-ML FindStringsInComment-ML MergeFlops-ML ResetPreventSRL-ML UseSRLPrim-ML ExoticClock-ML CheckAssignToVecBits-ML ConstWithoutValue-ML GenIndexNonInt-ML NoFuncOrProc-ML AMSKeyword-ML SelfDeterminedExpr-ML NoInoutPort-ML ModuleName-ML NoBitArray-ML SameLabelsInGenerate-ML SetResetConverge-ML RegInput-ML MultipleFilesCellDefine-ML NestedCellDefine-ML MultiModuleInCellDefine-ML ConflictVar-ML V2K_Rules MultiOpInModule-ML EventControlInRHS-ML NoArithOp-ML SystemVerilog Morelint_Elab_Rules Morelint_Lexical_Rules MultiAssign-ML DisallowVal-ML UnsuppCompDir-ML NonWireSignal-ML CheckSyncReset-ML NoOpen-ML ReserveNameSystemVerilog-ML CheckParamSensList-ML NestedCaseStmt-ML ConstDrivenNet-ML CheckSynthPragma-ML ComplexExpr-ML ValueSizeOverFlow-ML CAPA-ML CoveragePragma-ML NonConstReset-ML DuplicateNonStaticCaseLabel-ML DuplicateCaseLabel-ML SingleEntInFile-ML CheckDelayTimescale-ML RegInputOutput-ML Prereqs_RegInputOutputs ChkUndefMacro-ML BitOrder-ML NonStaticMacro-ML NoOthersInAsgn-ML ChkSensExprPar-ML ConstantInput-ML Prereqs_ConstantInput-ML IntRange-ML NoGenericMap-ML InstNameSameAsMaster-ML UnrecSynthDir-ML NoArray-ML NoParamMultConcat-ML NoSigCaseX-ML DisallowXInCaseZ-ML DiffTimescaleUsed-ML ReserveNameV2K-ML EnumStateDecl-ML ReEntrantOutput-ML InlineComment-ML NoFeedThrus-ML WrapInstance-ML SensListRepeat-ML ParamOverrideMismatch-ML IfWithoutElse-ML UnConstrLoop-ML NullOthers-ML DetectBlackBoxes-ML NoBusPartClock-ML NullPort-ML NoExprInPort-ML DisallowDWComp-ML DisallowMult-ML NoWidthInBasedNum-ML SynchReset-ML AsgnOverflow-ML MemConflict-ML ParamWidthMismatch-ML SetBeforeRead-ML MacroFileName-ML FuncFileName-ML TaskFileName-ML HangingInst-ML HangingInstOutput-ML HangingInstInput-ML SynchValueUsed-ML GroupOFAsgn-ML HangingNet-ML SepTFMacro-ML AsgnNextSt-ML RedundantLogicalOp-ML SigAsgnDelay-ML InstNameStyle-ML ResetFlop-ML NoXInCase-ML CondSigAsgnDelay-ML TristateSig-ML TristatePort-ML UseBusWidth-ML PortNameSameAsModule-ML PartConnPort-ML AsgnToOneBit-ML LINT_RSTGEN_AVOID_SEQSTMT LINT_CLKGEN_AVOID_CONTASSIGN LINT_CLKGEN_AVOID_SEQSTMT LINT_UNSPECIFIED_MACRO_NAME LINT_INSTANCE_WITHOUT_NAME LINT_UNDEFINED_MACRO_USED LINT_LOOP_THRU_FLOP_WITHOUT_SETRESET LINT_FSM_WITHOUT_EXIT_STATE LINT_SUB_MODULE_NAMING_STYLE LINT_GTECH_CELL_USED LINT_FSM_WITHOUT_INITIAL_STATE LINT_FSM_UNREACHABLE_STATES LINT_SNPS_DIRECTIVE_USED LINT_SV_STRING_USED_IN_DESIGN LINT_INVALID_NET_TYPE_IN_DU_INSTANTIATION LINT_DETECT_UNSYNTHESIZABLE_NET ParameterCheck-ML InvalidNetType-ML LINT_MACRO_MODULE_USED LINT_ALL_BITS_SHIFT_OUT LINT_DETECT_EMPTY_MODULE LINT_INVALID_ENTITY_NAME LINT_INVALID_FILENAME NoAssignX-ML SelfAssignment-ML DisallowTimeArr-ML LINT_LOGICAL_EXPR_USED_IN_SENS_LIST NoStrengthInput-ML NoRealFunc-ML NoDisableInFunc-ML LINT_IMPROPER_RANGE_INDEX NoDisableInTask-ML DisallowCaseZ-ML DisallowCaseX-ML 
flow/v2_pipeline/phase_p_cdc_rdc_xprop/sg_shell.log:803:Checking Rule FilterClockOverlapSetup (Rule 399 of total 533) .... done (Time = 0.00s, Memory = 0.0K)
flow/v2_pipeline/phase_p_cdc_rdc_xprop/sg_shell.log:1346:Checking Rule FilterClockOverlapSetup (Rule 359 of total 479) .... done (Time = 0.00s, Memory = 0.0K)
flow/v2_pipeline/phase_p_cdc_rdc_xprop/spyglass_shell.log:785:Checking Rule FilterClockOverlapSetup (Rule 399 of total 533) .... done (Time = 0.00s, Memory = 0.0K)
flow/v2_pipeline/phase_p_cdc_rdc_xprop/spyglass_shell.log:1327:Checking Rule FilterClockOverlapSetup (Rule 359 of total 479) .... done (Time = 0.00s, Memory = 0.0K)
flow/v2_pipeline/phase_p_cdc_rdc_xprop/spyglass_stdout.postfix_20260612_160433.log:793:Checking Rule FilterClockOverlapSetup (Rule 399 of total 533) .... done (Time = 0.00s, Memory = 0.0K)
flow/v2_pipeline/phase_p_cdc_rdc_xprop/spyglass_stdout.postfix_20260612_160433.log:1336:Checking Rule FilterClockOverlapSetup (Rule 359 of total 479) .... done (Time = 0.00s, Memory = 0.0K)
flow/v2_pipeline/phase_p_cdc_rdc_xprop/spyglass_stdout.log:793:Checking Rule FilterClockOverlapSetup (Rule 399 of total 533) .... done (Time = 0.00s, Memory = 0.0K)
flow/v2_pipeline/phase_p_cdc_rdc_xprop/spyglass_stdout.log:1336:Checking Rule FilterClockOverlapSetup (Rule 359 of total 479) .... done (Time = 0.00s, Memory = 0.0K)
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_s1.S:112:    /* terminator: masked body op writing v0 = ILLEGAL (dest overlaps mask;
flow/v2_pipeline/phase_05_leader/J8_run.log:7420:devices at [0, 1000) and [0, 40000) overlap
flow/v2_pipeline/phase_22_vector_csr_lockstep/spike.log:36:core   0: 0x80000044 (0xb22081d7) vnsrl.wv v3, v2, v1
flow/v2_pipeline/phase_22_vector_csr_lockstep/spike.log:44:core   0: 0x80000054 (0xb62081d7) vnsra.wv v3, v2, v1
flow/v2_pipeline/phase_22_vector_csr_lockstep/spike.log:52:core   0: 0x80000064 (0xb22631d7) vnsrl.wi v3, v2, 12
flow/v2_pipeline/phase_22_vector_csr_lockstep/spike.log:58:core   0: 0x80000070 (0xb62631d7) vnsra.wi v3, v2, 12
flow/v2_pipeline/phase_22_vector_csr_lockstep/spike.log:68:core   0: 0x80000084 (0xb223c1d7) vnsrl.wx v3, v2, t2
flow/v2_pipeline/phase_22_vector_csr_lockstep/spike.log:76:core   0: 0x80000094 (0xb623c1d7) vnsra.wx v3, v2, t2
flow/v2_pipeline/phase_22_vector_csr_lockstep/spike.log:92:core   0: 0x800000b4 (0xb22081d7) vnsrl.wv v3, v2, v1
flow/v2_pipeline/phase_22_vector_csr_lockstep/spike.log:100:core   0: 0x800000c4 (0xb62081d7) vnsra.wv v3, v2, v1
flow/v2_pipeline/phase_22_vector_csr_lockstep/spike.log:108:core   0: 0x800000d4 (0xb62a31d7) vnsra.wi v3, v2, 20
flow/v2_pipeline/phase_22_vector_csr_lockstep/spike.log:114:core   0: 0x800000e0 (0xb22a31d7) vnsrl.wi v3, v2, 20
flow/v2_pipeline/phase_22_vector_csr_lockstep/spike.log:134:core   0: 0x80000108 (0x4a2321d7) vzext.vf2 v3, v2
flow/v2_pipeline/phase_22_vector_csr_lockstep/spike.log:142:core   0: 0x80000118 (0x4a23a1d7) vsext.vf2 v3, v2
flow/v2_pipeline/phase_22_vector_csr_lockstep/spike.log:154:core   0: 0x80000130 (0x4a22a1d7) vsext.vf4 v3, v2
flow/v2_pipeline/phase_22_vector_csr_lockstep/spike.log:162:core   0: 0x80000140 (0x4a2221d7) vzext.vf4 v3, v2
flow/v2_pipeline/phase_22_vector_csr_lockstep/spike.log:174:core   0: 0x80000158 (0x4a43a1d7) vsext.vf2 v3, v4
flow/v2_pipeline/phase_22_vector_csr_lockstep/spike.log:186:core   0: 0x80000170 (0xb0208057) vnsrl.wv v0, v2, v1, v0.t
flow/v2_pipeline/phase_05_leader/J7_run.log:2269:The Makefile patch needs correction because I attempted overlapping hunks. I’ll re-open the file once and apply a clean, single coherent edit including wrapper build/run targets without touching existing test flow semantics except adding coverage-vdb generation/merge prerequisites.
flow/v2_pipeline/phase_05_leader/codex_review.log:762:    12	                    seed N+1 overlaps with simulation of seed N (producer-consumer).
flow/v2_pipeline/phase_05_leader/codex_review.log:5134:| F3 | `dv_farm.py:66-69`, `dv_farm.py:89-91`, `dv_farm.py:140-156` | Campaigns share `runs/seed_<n>` and status files are not cleared for reused campaign names. | Medium | Two farms, or a farm plus serial run, using overlapping seeds will `rmtree` the same work dir. Separately, rerunning `--campaign same_name` leaves old `status/seed_*.json` files and the rollup counts stale seeds not in the current run. Both can corrupt reported results without any DUT issue. |
flow/v2_pipeline/phase_05_leader/codex_review.log:5145:| F3 | `dv_farm.py:66-69`, `dv_farm.py:89-91`, `dv_farm.py:140-156` | Campaigns share `runs/seed_<n>` and status files are not cleared for reused campaign names. | Medium | Two farms, or a farm plus serial run, using overlapping seeds will `rmtree` the same work dir. Separately, rerunning `--campaign same_name` leaves old `status/seed_*.json` files and the rollup counts stale seeds not in the current run. Both can corrupt reported results without any DUT issue. |
flow/v2_pipeline/phase_02_01_mem_wrapper/codex_review_run.log:2259:    86	- Single-outstanding only — no overlapped I/D latency hiding (deferred).
flow/v2_pipeline/phase_03_09_riscvdv_lockstep/dv_farm.py:12:                    seed N+1 overlaps with simulation of seed N (producer-consumer).
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b1.S:143:    /* terminator: masked B1 op writing v0 = ILLEGAL (dest overlaps the mask
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:1:/* ADR-0055 Phase-B B2a directed: narrowing shift vnsrl/vnsra (.wv/.wx/.wi).
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:5:   <=1). vnsra sign edges shown with shamt >= 9 (the sign-fill reaches the low
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:25:    vnsrl.wv v3, v2, v1
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:29:    vnsra.wv v3, v2, v1        /* arithmetic — differs where shamt>=9 */
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:33:    vnsrl.wi v3, v2, 12        /* large shamt: logical zero-fill */
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:36:    vnsra.wi v3, v2, 12        /* large shamt: sign-fill into low byte */
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:41:    vnsrl.wx v3, v2, t2
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:45:    vnsra.wx v3, v2, t2
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:57:    vnsrl.wv v3, v2, v1
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:61:    vnsra.wv v3, v2, v1
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:65:    vnsra.wi v3, v2, 20        /* large shamt (>=17): sign-fill */
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:68:    vnsrl.wi v3, v2, 20
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:72:    /* ===== B2b vzext/vsext ===== */
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:77:    /* vf2 -> e16 */
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:80:    vzext.vf2 v3, v2
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:84:    vsext.vf2 v3, v2           /* sign-extend: 0x80 -> 0xFF80 */
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:88:    /* vf4 -> e32 (8-bit source) */
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:91:    vsext.vf4 v3, v2
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:95:    vzext.vf4 v3, v2
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:98:    /* vf2 -> e32 (16-bit source) */
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:102:    vsext.vf2 v3, v4
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:107:    /* terminator: masked narrowing writing v0 = ILLEGAL (dest overlaps mask) */
flow/v2_pipeline/phase_22_vector_csr_lockstep/firmware_b2.S:110:    vnsrl.wv v0, v2, v1, v0.t

codex
The current directed gate only exercises non-overlap `vext` cases (`vd=v3`, `vs2=v2/v4`) and a single masked `vnsrl` illegal terminator. That leaves overlap legality as the main untested surface I can see.
exec
/bin/bash -lc "nl -ba design/cpu_m1/rtl/vexu.v | sed -n '216,270p'" in /home/edauser/project/SOC/Magpie_M3V
 succeeded in 0ms:
   216	    wire mem_illegal = !mem_enc_ok || !emul_ok || !align_ok;
   217	
   218	    // 3D widening legality: dst EEW = 2*SEW needs SEW<=16 and dst EMUL = 2*LMUL
   219	    // <= 1 (single register group) => LMUL must be fractional. Overlap (match
   220	    // Spike require_noover): a widening dest may not overlap a NARROWER source;
   221	    // vwadd.wv vd==vs2 is legal (same EEW — the kernel's accumulate uses it).
   222	    wire widen_lmul_ok = (vlmul == 3'b111) || (vlmul == 3'b110) || (vlmul == 3'b101);
   223	    wire widen_illegal = op_widen &&
   224	                         (!widen_lmul_ok || (vsew == 3'b010) ||
   225	                          (vd_i == vs1_i) ||
   226	                          (op_wmul && (vd_i == vs2_i)));
   227	
   228	    wire known_op = op_add || op_sub || op_mv || op_merge || op_mvxs ||
   229	                    op_wmul || op_waddw || op_redsum || op_mvsx ||
   230	                    op_mm || op_cmp || op_mlog || op_s2same || op_nc || op_b1 ||
   231	                    op_nsr || op_vext;
   232	    // ops that iterate register-group parts (compares read groups, write ONE
   233	    // mask register); widening/narrowing/reductions stay <= m1 (their own
   234	    // LMUL rules) and vmv.x.s/vmv.s.x touch element 0 only.
   235	    wire beats_op  = op_add || op_sub || op_mv || op_merge || op_mm ||
   236	                     op_s2same || op_cmp || op_b1;
   237	    // NOTE: memory opcodes alias the f6-based arith decodes (every other use
   238	    // site is guarded by an is_vmem priority mux) — exclude them here too.
   239	    wire is_grp    = (grp_parts != 3'd1) && beats_op && !is_vmem;
   240	    wire grp_only_illegal = (grp_parts != 3'd1) &&
   241	        (op_widen || op_redsum || op_nc || op_nsr || op_vext ||
   242	         !beats_op && !op_mvxs && !op_mvsx && !op_mlog && !is_vmem);
   243	    // register-group alignment (vd for writes except mask-dest; sources)
   244	    wire [4:0] grp_amask = lmul_m4 ? 5'd3 : lmul_m2 ? 5'd1 : 5'd0;
   245	    wire grp_align_illegal = is_grp &&
   246	        ((!op_cmp && ((vd_i & grp_amask[4:0]) != 5'd0)) ||
   247	         ((vs2_i & grp_amask) != 5'd0) ||
   248	         // .vv source includes OPMVV vector-vector forms (vaadd family) —
   249	         // Codex S3 finding: is_opivv alone missed them
   250	         ((is_opivv || is_opmvv) && ((vs1_i & grp_amask) != 5'd0)));
   251	    // narrowing legality mirrors widening (source EMUL = 2*LMUL <= 1); the
   252	    // low-part destination overlap (vd == vs2) is spec-legal for narrowing.
   253	    wire nc_illegal = (op_nc || op_nsr) && (!widen_lmul_ok || (vsew == 3'b010));
   254	    // vstart!=0 on arithmetic = illegal (spec-allowed choice; MATCHES SPIKE —
   255	    // caught by gate_42 lockstep: Spike trapped where the RTL executed).
   256	    // Loads/stores are resumable: vstart is honored (start element), not illegal.
   257	    assign q_illegal = q_valid && ((EN_RVV == 0) || cfg_illegal ||
   258	                       (is_vmem ? mem_illegal :
   259	                        (!known_op ||
   260	                         (q_vstart != 32'h0) ||
   261	                         widen_illegal ||
   262	                         (op_mv && (vs2_i != 5'd0)) ||
   263	                         (op_merge && (vd_i == 5'd0)) ||
   264	                         // S1 (Codex, Spike-confirmed): a MASKED body op may not
   265	                         // write v0 (dest overlaps the mask); mask-DEST compares
   266	                         // targeting v0 remain legal.
   267	                         nc_illegal || grp_only_illegal || grp_align_illegal ||
   268	                         ((op_add || op_sub || op_mm || op_s2same || op_nc ||
   269	                           op_b1 || op_nsr || op_vext) &&
   270	                          !vm && (vd_i == 5'd0)))));

exec
/bin/bash -lc "nl -ba tests/gates/gate_63_rvv_b2_narrow_ext.py | sed -n '1,120p'" in /home/edauser/project/SOC/Magpie_M3V
 succeeded in 0ms:
     1	"""gate_63_rvv_b2_narrow_ext — ADR-0055 Phase-B B2: narrowing shift + extension.
     2	
     3	B2a narrowing shift (vnsrl/vnsra, .wv/.wx/.wi): wide 2*SEW source >> shamt -> SEW
     4	dest low bits, reusing the vnclip wide datapath minus round/clip. Only SEW8 (src
     5	e16) and SEW16 (src e32) — SEW32 narrowing needs a 64-bit source, absent in
     6	Zve32x. shamt masked to log2(2*SEW) bits; vnsra arithmetic via a self-determined
     7	signed wire, its sign edges observable at shamt >= log2(2*SEW)/... where the fill
     8	reaches the low SEW bits. B2b extension (vzext/vsext.vf2/vf4, OPMVV f6=010010,
     9	gated on f3 so disjoint from OPIVV vsbc): SEW/2 or SEW/4 low-lane source -> SEW
    10	zero/sign extended; vf2 needs SEW>=16, vf4 needs SEW32, vf8 illegal (no e64).
    11	
    12	Both are body ops carrying the masked-vd==v0 illegality (proactively added after
    13	the B1 3-way review caught that gap). Authority: phase_22 `make b2` vs Spike
    14	--isa=zve32x_zvl128b (fractional-LMUL narrowing configs, EEW-override wide loads,
    15	sign/zero extension of negative sources, masked-vd0 illegal terminator).
    16	"""
    17	
    18	import re
    19	import shutil
    20	import subprocess
    21	from pathlib import Path
    22	
    23	import pytest
    24	
    25	ROOT = Path(__file__).resolve().parents[2]
    26	PHASE = ROOT / "flow/v2_pipeline/phase_22_vector_csr_lockstep"
    27	
    28	
    29	def _run(target, min_commits):
    30	    r = subprocess.run(["make", "-C", str(PHASE), target],
    31	                       capture_output=True, text=True)
    32	    assert r.returncode == 0, f"{target} failed:\n{r.stdout[-3000:]}"
    33	    m = re.search(r"PASS: vcsr-lockstep matched (\d+) commits", r.stdout)
    34	    assert m and int(m.group(1)) >= min_commits, r.stdout[-1500:]
    35	
    36	
    37	@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
    38	def test_b2_directed_lockstep():
    39	    _run("b2", 85)
    40	
    41	
    42	def test_b2_corpus_covers_narrow_and_ext():
    43	    fw = (PHASE / "firmware_b2.S").read_text()
    44	    for pat, floor in ((r"vnsrl\.", 3), (r"vnsra\.", 3),
    45	                       (r"vzext\.vf2", 1), (r"vsext\.vf2", 2),
    46	                       (r"vzext\.vf4", 1), (r"vsext\.vf4", 1)):
    47	        n = len(re.findall(pat, fw))
    48	        assert n >= floor, f"B2 corpus lost {pat}: {n} < {floor}"
    49	
    50	
    51	@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
    52	def test_prior_vector_targets_still_green():
    53	    for tgt, bar in (("b1", 115), ("grid", 140), ("s2", 100), ("vrand", 1200)):
    54	        _run(tgt, bar)

exec
/bin/bash -lc "nl -ba design/cpu_m1/rtl/vexu.v | sed -n '744,833p'" in /home/edauser/project/SOC/Magpie_M3V
 succeeded in 0ms:
   744	        // ---- vnclip[u]: wide 2*SEW source -> SEW dest with round + clip ----
   745	        for (gi = 0; gi < 8; gi = gi + 1) begin : g_nc8
   746	            wire [15:0] v = vs2_data[gi*16 +: 16];             // wide lane
   747	            wire [7:0]  b = is_opivv ? vs1_data[gi*8 +: 8] : scalar_b[7:0];
   748	            wire [3:0]  d = b[3:0];                            // shamt & (2*SEW-1)
   749	            wire [15:0] lowm = (16'h0001 << d) - 16'h1;
   750	            wire b_dm1 = (d != 4'd0) && (((v >> (d - 4'd1)) & 16'h1) != 16'h0);
   751	            wire b_d   = ((v >> d) & 16'h1) != 16'h0;
   752	            wire lo_nz = (v & (lowm >> 1)) != 16'h0;
   753	            wire any_lo= (v & lowm) != 16'h0;
   754	            wire inc = (q_vxrm == 2'd0) ? b_dm1 :
   755	                       (q_vxrm == 2'd1) ? (b_dm1 & (lo_nz | b_d)) :
   756	                       (q_vxrm == 2'd2) ? 1'b0 :
   757	                                          (~b_d & any_lo);
   758	            wire signed [15:0] vs = v;
   759	            wire        [15:0] nsrl_w = v >> d;            // B2a vnsrl: logical
   760	            wire signed [15:0] nsra_w = vs >>> d;          // B2a vnsra: arithmetic (self-det signed)
   761	            wire signed [16:0] rs = {vs[15], $unsigned(vs >>> d)} + {16'b0, inc};
   762	            wire        [16:0] ru = {1'b0, v >> d} + {16'b0, inc};
   763	            wire s_ov = (rs > 17'sd127) || (rs < -17'sd128);
   764	            wire u_ov = (ru > 17'd255);
   765	            wire [7:0] r = op_nsrl  ? nsrl_w[7:0] :
   766	                           op_nsra  ? nsra_w[7:0] :
   767	                           op_nclip ? (s_ov ? (rs[16] ? 8'h80 : 8'h7F) : rs[7:0])
   768	                                    : (u_ov ? 8'hFF : ru[7:0]);
   769	            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
   770	            assign res_nc8[gi*8 +: 8] = en ? r : vd_old[gi*8 +: 8];
   771	            assign nc_sat8[gi] = en && (op_nclip ? s_ov : u_ov);
   772	        end
   773	        for (gi = 0; gi < 4; gi = gi + 1) begin : g_nc16
   774	            wire [31:0] v = vs2_data[gi*32 +: 32];
   775	            wire [15:0] b = is_opivv ? vs1_data[gi*16 +: 16] : scalar_b[15:0];
   776	            wire [4:0]  d = b[4:0];
   777	            wire [31:0] lowm = (32'h1 << d) - 32'h1;
   778	            wire b_dm1 = (d != 5'd0) && (((v >> (d - 5'd1)) & 32'h1) != 32'h0);
   779	            wire b_d   = ((v >> d) & 32'h1) != 32'h0;
   780	            wire lo_nz = (v & (lowm >> 1)) != 32'h0;
   781	            wire any_lo= (v & lowm) != 32'h0;
   782	            wire inc = (q_vxrm == 2'd0) ? b_dm1 :
   783	                       (q_vxrm == 2'd1) ? (b_dm1 & (lo_nz | b_d)) :
   784	                       (q_vxrm == 2'd2) ? 1'b0 :
   785	                                          (~b_d & any_lo);
   786	            wire signed [31:0] vs = v;
   787	            wire        [31:0] nsrl_w = v >> d;
   788	            wire signed [31:0] nsra_w = vs >>> d;
   789	            wire signed [32:0] rs = {vs[31], $unsigned(vs >>> d)} + {32'b0, inc};
   790	            wire        [32:0] ru = {1'b0, v >> d} + {32'b0, inc};
   791	            wire s_ov = (rs > 33'sd32767) || (rs < -33'sd32768);
   792	            wire u_ov = (ru > 33'd65535);
   793	            wire [15:0] r = op_nsrl  ? nsrl_w[15:0] :
   794	                            op_nsra  ? nsra_w[15:0] :
   795	                            op_nclip ? (s_ov ? (rs[32] ? 16'h8000 : 16'h7FFF) : rs[15:0])
   796	                                     : (u_ov ? 16'hFFFF : ru[15:0]);
   797	            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
   798	            assign res_nc16[gi*16 +: 16] = en ? r : vd_old[gi*16 +: 16];
   799	            assign nc_sat16[gi] = en && (op_nclip ? s_ov : u_ov);
   800	        end
   801	
   802	        // ---- B2b vzext/vsext: SEW/2 (vf2) or SEW/4 (vf4) source -> SEW dest ----
   803	        for (gi = 0; gi < 8; gi = gi + 1) begin : g_ext16   // dst e16, vf2 (src 8b)
   804	            wire [7:0]  s = vs2_data[gi*8 +: 8];
   805	            wire [15:0] e = ext_sext ? {{8{s[7]}}, s} : {8'b0, s};
   806	            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
   807	            assign res_ext16[gi*16 +: 16] = en ? e : vd_old[gi*16 +: 16];
   808	        end
   809	        for (gi = 0; gi < 4; gi = gi + 1) begin : g_ext32   // dst e32, vf2 (src 16b) / vf4 (src 8b)
   810	            wire [15:0] s2 = vs2_data[gi*16 +: 16];
   811	            wire [7:0]  s4 = vs2_data[gi*8 +: 8];
   812	            wire [31:0] e2 = ext_sext ? {{16{s2[15]}}, s2} : {16'b0, s2};
   813	            wire [31:0] e4 = ext_sext ? {{24{s4[7]}},  s4} : {24'b0, s4};
   814	            wire [31:0] e  = ext_vf4 ? e4 : e2;
   815	            wire en = (gi >= vst_view) && (gi < vl_view) && (vm || v0_view[gi]);
   816	            assign res_ext32[gi*32 +: 32] = en ? e : vd_old[gi*32 +: 32];
   817	        end
   818	    endgenerate
   819	
   820	    // narrowing writes at most 8 (SEW8) / 4 (SEW16) dst elements under the
   821	    // fractional-LMUL rule -> the upper half of the dst register is tail
   822	    assign res_nc8[127:64]  = vd_old[127:64];
   823	    assign res_nc16[127:64] = vd_old[127:64];
   824	
   825	    wire [127:0] res_s2 = (vsew == 3'b000) ? res_s2_8 :
   826	                          (vsew == 3'b001) ? res_s2_16 : res_s2_32;
   827	    wire [127:0] res_nc = (vsew == 3'b000) ? res_nc8 : res_nc16;
   828	    wire part_sat_or = (op_s2same && ((vsew == 3'b000) ? (|s2_sat8) :
   829	                                      (vsew == 3'b001) ? (|s2_sat16_x[7:0]) :
   830	                                                         (|s2_sat32))) ||
   831	                       (op_nc && ((vsew == 3'b000) ? (|nc_sat8) : (|nc_sat16)));
   832	    assign q_vxsat = q_valid && !q_illegal && (q_vstart < q_vl) &&
   833	                     (is_grp ? grp_sat_q : part_sat_or);

exec
/bin/bash -lc "nl -ba design/cpu_m1/rtl/core.v | sed -n '714,742p'" in /home/edauser/project/SOC/Magpie_M3V
 succeeded in 0ms:
   714	        input [31:0] vtype;
   715	        reg          legal;
   716	        reg [31:0]   sew_bits;
   717	        reg [31:0]   base_elems;
   718	        reg [31:0]   vlmax;
   719	        begin
   720	            legal = 1'b1;
   721	            sew_bits = 32'd8 << vtype[5:3];
   722	            base_elems = 32'd16 >> vtype[5:3]; // VLEN=128, SEW in {8,16,32}
   723	            vlmax = 32'h0;
   724	
   725	            if (vtype[31] || (vtype[30:8] != 23'h0) || (vtype[5:3] > 3'd2) ||
   726	                (vtype[2:0] == 3'b100)) begin
   727	                legal = 1'b0;
   728	            end
   729	
   730	            case (vtype[2:0])
   731	                3'b000: vlmax = base_elems;
   732	                3'b001: vlmax = base_elems << 1;
   733	                3'b010: vlmax = base_elems << 2;
   734	                3'b011: vlmax = base_elems << 3;
   735	                3'b101: begin
   736	                    vlmax = base_elems >> 3;       // mf8
   737	                    if ((sew_bits << 3) > 32'd32) legal = 1'b0;
   738	                end
   739	                3'b110: begin
   740	                    vlmax = base_elems >> 2;       // mf4
   741	                    if ((sew_bits << 2) > 32'd32) legal = 1'b0;
   742	                end

exec
/bin/bash -lc "nl -ba design/cpu_m1/rtl/core.v | sed -n '742,758p'" in /home/edauser/project/SOC/Magpie_M3V
 succeeded in 0ms:
   742	                end
   743	                3'b111: begin
   744	                    vlmax = base_elems >> 1;       // mf2
   745	                    if ((sew_bits << 1) > 32'd32) legal = 1'b0;
   746	                end
   747	                default: begin
   748	                    vlmax = 32'h0;
   749	                    legal = 1'b0;
   750	                end
   751	            endcase
   752	
   753	            rvv_vlmax_info = {legal, vlmax};
   754	        end
   755	    endfunction
   756	
   757	    wire        id_is_vsetivli = id_is_vset && (if_ex_instr[31:30] == 2'b11);
   758	    wire        id_is_vsetvl   = id_is_vset && (if_ex_instr[31:25] == 7'b1000000);

codex
I found one concrete issue candidate and am avoiding speculation on the conflicting local notes around narrowing overlap. The code itself treats `vd==vs2` narrowing as intentionally legal, while extension matches the existing “dest wider than source” overlap class and has no corresponding guard.
exec
/bin/bash -lc 'which spike || true' in /home/edauser/project/SOC/Magpie_M3V
 succeeded in 0ms:
/home/edauser/.local/bin/spike

exec
/bin/bash -lc 'which riscv64-unknown-elf-as || which riscv32-unknown-elf-as || true' in /home/edauser/project/SOC/Magpie_M3V
 succeeded in 0ms:
/usr/bin/which: no riscv64-unknown-elf-as in (/home/edauser/.npm-global/lib/node_modules/@openai/codex/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/codex-path:/home/edauser/.grok/bin:/home/edauser/.npm-global/bin:/mnt/c/Users/Hans Yang/AppData/Local/Programs/Microsoft VS Code/bin:/soft/license/bin:/home/edauser/.grok/bin:/home/edauser/.npm-global/bin:/mnt/c/Users/Hans Yang/AppData/Local/Programs/Microsoft VS Code/bin:/soft/license/bin:/home/edauser/.codex/tmp/arg0/codex-arg0iW1lgz:/home/edauser/.npm-global/lib/node_modules/@openai/codex/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/codex-path:/home/edauser/.grok/bin:/home/edauser/.npm-global/bin:/mnt/c/Users/Hans Yang/AppData/Local/Programs/Microsoft VS Code/bin:/soft/license/bin:/home/edauser/.local/opt/riscv/xpack-riscv-none-elf-gcc-13.2.0-2/bin:/home/edauser/miniforge3/envs/magpie_claude/bin:/home/edauser/miniforge3/condabin:/home/edauser/.cargo/bin:/home/edauser/.local/bin:/home/edauser/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/lib/wsl/lib:/mnt/c/Windows/system32:/mnt/c/Windows:/mnt/c/Windows/System32/Wbem:/mnt/c/Windows/System32/WindowsPowerShell/v1.0:/mnt/c/Windows/System32/OpenSSH:/mnt/c/Program Files/dotnet:/mnt/c/Program Files/usbipd-win:/mnt/c/Program Files/PuTTY:/mnt/c/Program Files/Git/cmd:/mnt/c/Users/Hans Yang/AppData/Local/Microsoft/WindowsApps:/mnt/c/Users/Hans Yang/AppData/Local/Programs/Microsoft VS Code/bin:/mnt/c/Users/Hans Yang/AppData/Local/Programs/Ollama:/soft/cadence/IC251/tools/dfII/bin:/soft/cadence/IC251/tools/plot/bin:/soft/cadence/IC251/tools/bin:/soft/cadence/IC251/tools:/soft/cadence/IC251/bin:/soft/cadence/SPECTRE251/bin:/soft/cadence/SPECTRE251/tools.lnx86/bin:/soft/cadence/SPECTRE251/tools.lnx86/dfII/bin:/soft/cadence/XCELIUM2509/bin:/soft/cadence/XCELIUM2509/tools.lnx86/bin:/soft/cadence/XCELIUM2509/tools.lnx86/dfII/bin:/soft/mentor/calibre_aok_2025.4_36.20/aok_cal_2025.4_36.20/bin:/soft/synopsys/customcompiler/X-2025.06/bin:/soft/synopsys/fm/X-2025.06-SP2/bin:/soft/synopsys/fusioncompiler/X-2025.06-SP1/bin:/soft/synopsys/lc/X-2025.06-SP2/bin:/soft/synopsys/syn/X-2025.06-SP2/bin:/soft/synopsys/vcs/X-2025.06-SP1/bin:/soft/synopsys/vcs/X-2025.06-SP1/amd64/bin:/soft/synopsys/vcs/X-2025.06-SP1/linux64/bin:/soft/synopsys/vcs/X-2025.06-SP1/gui/dve/bin:/soft/synopsys/verdi/X-2025.06-SP1-1/bin:/soft/synopsys/hspice/X-2025.06/hspice/bin:/soft/synopsys/wv/X-2025.06/bin:/soft/synopsys/icc2/X-2025.06-SP2/bin:/soft/synopsys/starrc/X-2025.06-SP2/bin:/soft/synopsys/prime/X-2025.06-SP1/bin:/soft/synopsys/spyglass/X-2025.06-SP1/SPYGLASS_HOME/bin:/home/edauser/.claude/plugins/cache/claude-plugins-official/rust-analyzer-lsp/1.0.0/bin:/soft/cadence/IC251/tools/dfII/bin:/soft/cadence/IC251/tools/plot/bin:/soft/cadence/IC251/tools/bin:/soft/cadence/IC251/tools:/soft/cadence/IC251/bin:/soft/cadence/SPECTRE251/bin:/soft/cadence/SPECTRE251/tools.lnx86/bin:/soft/cadence/SPECTRE251/tools.lnx86/dfII/bin:/soft/cadence/XCELIUM2509/bin:/soft/cadence/XCELIUM2509/tools.lnx86/bin:/soft/cadence/XCELIUM2509/tools.lnx86/dfII/bin:/soft/mentor/calibre_aok_2025.4_36.20/aok_cal_2025.4_36.20/bin:/soft/synopsys/customcompiler/X-2025.06/bin:/soft/synopsys/fm/X-2025.06-SP2/bin:/soft/synopsys/fusioncompiler/X-2025.06-SP1/bin:/soft/synopsys/lc/X-2025.06-SP2/bin:/soft/synopsys/syn/X-2025.06-SP2/bin:/soft/synopsys/vcs/X-2025.06-SP1/bin:/soft/synopsys/vcs/X-2025.06-SP1/amd64/bin:/soft/synopsys/vcs/X-2025.06-SP1/linux64/bin:/soft/synopsys/vcs/X-2025.06-SP1/gui/dve/bin:/soft/synopsys/verdi/X-2025.06-SP1-1/bin:/soft/synopsys/hspice/X-2025.06/hspice/bin:/soft/synopsys/wv/X-2025.06/bin:/soft/synopsys/icc2/X-2025.06-SP2/bin:/soft/synopsys/starrc/X-2025.06-SP2/bin:/soft/synopsys/prime/X-2025.06-SP1/bin:/soft/synopsys/spyglass/X-2025.06-SP1/SPYGLASS_HOME/bin:/soft/cadence/IC251/tools/dfII/bin:/soft/cadence/IC251/tools/plot/bin:/soft/cadence/IC251/tools/bin:/soft/cadence/IC251/tools:/soft/cadence/IC251/bin:/soft/cadence/SPECTRE251/bin:/soft/cadence/SPECTRE251/tools.lnx86/bin:/soft/cadence/SPECTRE251/tools.lnx86/dfII/bin:/soft/cadence/XCELIUM2509/bin:/soft/cadence/XCELIUM2509/tools.lnx86/bin:/soft/cadence/XCELIUM2509/tools.lnx86/dfII/bin:/soft/mentor/calibre_aok_2025.4_36.20/aok_cal_2025.4_36.20/bin:/soft/synopsys/customcompiler/X-2025.06/bin:/soft/synopsys/fm/X-2025.06-SP2/bin:/soft/synopsys/fusioncompiler/X-2025.06-SP1/bin:/soft/synopsys/lc/X-2025.06-SP2/bin:/soft/synopsys/syn/X-2025.06-SP2/bin:/soft/synopsys/vcs/X-2025.06-SP1/bin:/soft/synopsys/vcs/X-2025.06-SP1/amd64/bin:/soft/synopsys/vcs/X-2025.06-SP1/linux64/bin:/soft/synopsys/vcs/X-2025.06-SP1/gui/dve/bin:/soft/synopsys/verdi/X-2025.06-SP1-1/bin:/soft/synopsys/hspice/X-2025.06/hspice/bin:/soft/synopsys/wv/X-2025.06/bin:/soft/synopsys/icc2/X-2025.06-SP2/bin:/soft/synopsys/starrc/X-2025.06-SP2/bin:/soft/synopsys/prime/X-2025.06-SP1/bin:/soft/synopsys/spyglass/X-2025.06-SP1/SPYGLASS_HOME/bin)
/usr/bin/which: no riscv32-unknown-elf-as in (/home/edauser/.npm-global/lib/node_modules/@openai/codex/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/codex-path:/home/edauser/.grok/bin:/home/edauser/.npm-global/bin:/mnt/c/Users/Hans Yang/AppData/Local/Programs/Microsoft VS Code/bin:/soft/license/bin:/home/edauser/.grok/bin:/home/edauser/.npm-global/bin:/mnt/c/Users/Hans Yang/AppData/Local/Programs/Microsoft VS Code/bin:/soft/license/bin:/home/edauser/.codex/tmp/arg0/codex-arg0iW1lgz:/home/edauser/.npm-global/lib/node_modules/@openai/codex/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/codex-path:/home/edauser/.grok/bin:/home/edauser/.npm-global/bin:/mnt/c/Users/Hans Yang/AppData/Local/Programs/Microsoft VS Code/bin:/soft/license/bin:/home/edauser/.local/opt/riscv/xpack-riscv-none-elf-gcc-13.2.0-2/bin:/home/edauser/miniforge3/envs/magpie_claude/bin:/home/edauser/miniforge3/condabin:/home/edauser/.cargo/bin:/home/edauser/.local/bin:/home/edauser/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/lib/wsl/lib:/mnt/c/Windows/system32:/mnt/c/Windows:/mnt/c/Windows/System32/Wbem:/mnt/c/Windows/System32/WindowsPowerShell/v1.0:/mnt/c/Windows/System32/OpenSSH:/mnt/c/Program Files/dotnet:/mnt/c/Program Files/usbipd-win:/mnt/c/Program Files/PuTTY:/mnt/c/Program Files/Git/cmd:/mnt/c/Users/Hans Yang/AppData/Local/Microsoft/WindowsApps:/mnt/c/Users/Hans Yang/AppData/Local/Programs/Microsoft VS Code/bin:/mnt/c/Users/Hans Yang/AppData/Local/Programs/Ollama:/soft/cadence/IC251/tools/dfII/bin:/soft/cadence/IC251/tools/plot/bin:/soft/cadence/IC251/tools/bin:/soft/cadence/IC251/tools:/soft/cadence/IC251/bin:/soft/cadence/SPECTRE251/bin:/soft/cadence/SPECTRE251/tools.lnx86/bin:/soft/cadence/SPECTRE251/tools.lnx86/dfII/bin:/soft/cadence/XCELIUM2509/bin:/soft/cadence/XCELIUM2509/tools.lnx86/bin:/soft/cadence/XCELIUM2509/tools.lnx86/dfII/bin:/soft/mentor/calibre_aok_2025.4_36.20/aok_cal_2025.4_36.20/bin:/soft/synopsys/customcompiler/X-2025.06/bin:/soft/synopsys/fm/X-2025.06-SP2/bin:/soft/synopsys/fusioncompiler/X-2025.06-SP1/bin:/soft/synopsys/lc/X-2025.06-SP2/bin:/soft/synopsys/syn/X-2025.06-SP2/bin:/soft/synopsys/vcs/X-2025.06-SP1/bin:/soft/synopsys/vcs/X-2025.06-SP1/amd64/bin:/soft/synopsys/vcs/X-2025.06-SP1/linux64/bin:/soft/synopsys/vcs/X-2025.06-SP1/gui/dve/bin:/soft/synopsys/verdi/X-2025.06-SP1-1/bin:/soft/synopsys/hspice/X-2025.06/hspice/bin:/soft/synopsys/wv/X-2025.06/bin:/soft/synopsys/icc2/X-2025.06-SP2/bin:/soft/synopsys/starrc/X-2025.06-SP2/bin:/soft/synopsys/prime/X-2025.06-SP1/bin:/soft/synopsys/spyglass/X-2025.06-SP1/SPYGLASS_HOME/bin:/home/edauser/.claude/plugins/cache/claude-plugins-official/rust-analyzer-lsp/1.0.0/bin:/soft/cadence/IC251/tools/dfII/bin:/soft/cadence/IC251/tools/plot/bin:/soft/cadence/IC251/tools/bin:/soft/cadence/IC251/tools:/soft/cadence/IC251/bin:/soft/cadence/SPECTRE251/bin:/soft/cadence/SPECTRE251/tools.lnx86/bin:/soft/cadence/SPECTRE251/tools.lnx86/dfII/bin:/soft/cadence/XCELIUM2509/bin:/soft/cadence/XCELIUM2509/tools.lnx86/bin:/soft/cadence/XCELIUM2509/tools.lnx86/dfII/bin:/soft/mentor/calibre_aok_2025.4_36.20/aok_cal_2025.4_36.20/bin:/soft/synopsys/customcompiler/X-2025.06/bin:/soft/synopsys/fm/X-2025.06-SP2/bin:/soft/synopsys/fusioncompiler/X-2025.06-SP1/bin:/soft/synopsys/lc/X-2025.06-SP2/bin:/soft/synopsys/syn/X-2025.06-SP2/bin:/soft/synopsys/vcs/X-2025.06-SP1/bin:/soft/synopsys/vcs/X-2025.06-SP1/amd64/bin:/soft/synopsys/vcs/X-2025.06-SP1/linux64/bin:/soft/synopsys/vcs/X-2025.06-SP1/gui/dve/bin:/soft/synopsys/verdi/X-2025.06-SP1-1/bin:/soft/synopsys/hspice/X-2025.06/hspice/bin:/soft/synopsys/wv/X-2025.06/bin:/soft/synopsys/icc2/X-2025.06-SP2/bin:/soft/synopsys/starrc/X-2025.06-SP2/bin:/soft/synopsys/prime/X-2025.06-SP1/bin:/soft/synopsys/spyglass/X-2025.06-SP1/SPYGLASS_HOME/bin:/soft/cadence/IC251/tools/dfII/bin:/soft/cadence/IC251/tools/plot/bin:/soft/cadence/IC251/tools/bin:/soft/cadence/IC251/tools:/soft/cadence/IC251/bin:/soft/cadence/SPECTRE251/bin:/soft/cadence/SPECTRE251/tools.lnx86/bin:/soft/cadence/SPECTRE251/tools.lnx86/dfII/bin:/soft/cadence/XCELIUM2509/bin:/soft/cadence/XCELIUM2509/tools.lnx86/bin:/soft/cadence/XCELIUM2509/tools.lnx86/dfII/bin:/soft/mentor/calibre_aok_2025.4_36.20/aok_cal_2025.4_36.20/bin:/soft/synopsys/customcompiler/X-2025.06/bin:/soft/synopsys/fm/X-2025.06-SP2/bin:/soft/synopsys/fusioncompiler/X-2025.06-SP1/bin:/soft/synopsys/lc/X-2025.06-SP2/bin:/soft/synopsys/syn/X-2025.06-SP2/bin:/soft/synopsys/vcs/X-2025.06-SP1/bin:/soft/synopsys/vcs/X-2025.06-SP1/amd64/bin:/soft/synopsys/vcs/X-2025.06-SP1/linux64/bin:/soft/synopsys/vcs/X-2025.06-SP1/gui/dve/bin:/soft/synopsys/verdi/X-2025.06-SP1-1/bin:/soft/synopsys/hspice/X-2025.06/hspice/bin:/soft/synopsys/wv/X-2025.06/bin:/soft/synopsys/icc2/X-2025.06-SP2/bin:/soft/synopsys/starrc/X-2025.06-SP2/bin:/soft/synopsys/prime/X-2025.06-SP1/bin:/soft/synopsys/spyglass/X-2025.06-SP1/SPYGLASS_HOME/bin)

exec
/bin/bash -lc 'rg -n "spike|RISCV|CROSS|TOOL|riscv.*gcc|OBJCOPY|make b2|b2:" flow/v2_pipeline/phase_22_vector_csr_lockstep/Makefile' in /home/edauser/project/SOC/Magpie_M3V
 succeeded in 0ms:
6:TOOLCHAIN_DIR    = /home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin
7:TOOLCHAIN_PREFIX = $(TOOLCHAIN_DIR)/riscv64-unknown-elf-
8:TOOLCHAIN_LIBS   = /home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib:/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib:/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib
9:TOOLCHAIN_ENV    = LD_LIBRARY_PATH=$(TOOLCHAIN_LIBS)
30:.PHONY: all grid vill valu vrand vmem vwide s1 clean firmware.elf firmware_spike.elf firmware.hex
46:	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -Os -march=$(GCC_MARCH) -mabi=$(GCC_MABI) -mno-relax \
51:firmware_spike.elf: $(FW_ASM) ../phase_20_npu_core_lockstep/firmware_spike.lds
52:	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -Os -march=$(GCC_MARCH) -mabi=$(GCC_MABI) -mno-relax \
54:	    -Wl,-Bstatic,-T,../phase_20_npu_core_lockstep/firmware_spike.lds,--strip-debug \
58:	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=4 $< $@
68:lockstep.log: sim.log firmware_spike.elf vcsr_lockstep.py
73:	rm -rf obj_dir sim.log firmware.elf firmware.hex firmware_spike.elf \
74:	    dut_commit.trace spike.log spike_commit.trace lockstep.log lockstep_report.md
88:b2:
137:	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -Os -march=$(GCC_MARCH) -mabi=$(GCC_MABI) -mno-relax \
141:	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -Os -march=$(GCC_MARCH) -mabi=$(GCC_MABI) -mno-relax \
143:	    -Wl,-Bstatic,-T,../phase_20_npu_core_lockstep/firmware_spike.lds,--strip-debug \
144:	    -o firmware_spike.elf crt_kernel.S vdot_i8.o
145:	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=4 firmware.elf firmware.hex

codex
1. [design/cpu_m1/rtl/vexu.v:257](/home/edauser/project/SOC/Magpie_M3V/design/cpu_m1/rtl/vexu.v:257): `op_vext` is missing the widening-style `vd == vs2` overlap illegal. The datapath extends a narrower `vs2` lane into wider `vd` lanes at [vexu.v:802](/home/edauser/project/SOC/Magpie_M3V/design/cpu_m1/rtl/vexu.v:802), but legality only applies `widen_illegal` to `op_widen`, not `op_vext` ([vexu.v:223](/home/edauser/project/SOC/Magpie_M3V/design/cpu_m1/rtl/vexu.v:223)). So unmasked `vzext/vsext.vf2/vf4 v2, v2` can execute instead of trapping. The directed B2 firmware uses `vd=v3, vs2=v2/v4`, so it would miss this.

I found no defects in the seven listed datapath/decode checks: vnsr shamt width is 4/5 bits, vnsra uses signed self-determined wires in both lanes, `op_nsr` cannot leak into `vxsat`, vext lane extraction/packing matches the scoped vf2/vf4 cases, vf8 and low-SEW variants stay illegal by `known_op`, OPMVV f6 collision is f3-gated, and neither B2 op enters `beats_op`/`is_grp`.

No edits made.
tokens used
101,965
1. [design/cpu_m1/rtl/vexu.v:257](/home/edauser/project/SOC/Magpie_M3V/design/cpu_m1/rtl/vexu.v:257): `op_vext` is missing the widening-style `vd == vs2` overlap illegal. The datapath extends a narrower `vs2` lane into wider `vd` lanes at [vexu.v:802](/home/edauser/project/SOC/Magpie_M3V/design/cpu_m1/rtl/vexu.v:802), but legality only applies `widen_illegal` to `op_widen`, not `op_vext` ([vexu.v:223](/home/edauser/project/SOC/Magpie_M3V/design/cpu_m1/rtl/vexu.v:223)). So unmasked `vzext/vsext.vf2/vf4 v2, v2` can execute instead of trapping. The directed B2 firmware uses `vd=v3, vs2=v2/v4`, so it would miss this.

I found no defects in the seven listed datapath/decode checks: vnsr shamt width is 4/5 bits, vnsra uses signed self-determined wires in both lanes, `op_nsr` cannot leak into `vxsat`, vext lane extraction/packing matches the scoped vf2/vf4 cases, vf8 and low-SEW variants stay illegal by `known_op`, OPMVV f6 collision is f3-gated, and neither B2 op enters `beats_op`/`is_grp`.

No edits made.

## Grok
## (1) B2 semantics — mostly sound; a few directed gaps

**vnsr:** Reusing `d` from the vnclip beat (`b[3:0]` @ 2×SEW=16, `b[4:0]` @ 32) matches the spec’s “low log₂(2·SEW) bits” rule. `vnsrl` = logical `>>`, `vnsra` = `>>>` on the wide lane, then take low SEW bits — correct and distinct from vnclip (no `vxrm`/sat). Self-detect signed `vnsra` on the wide element is right.

**Likely missed corners (directed 92 commits):**
- **Large shamt** (`d ≥ 2·SEW`): should saturate to 0 / sign-fill; cheap to miss if tests only use small `d`.
- **SEW=8 vf2:** `op_vext` only allows vf2 @ SEW16/32. If Spike allows `vzext.vf2` @ SEW8 (4→8), that’s a deliberate Zve32x scope cut or a hole — worth one Spike probe.
- **vf4 lane packing @ SEW32:** `g_ext32` uses `gi*8` byte lanes for vf4; correct only if the beat’s `vs2_data` is already presented at source-EEW layout (same assumption as vnclip/widen). If group iteration ever widens, byte indexing must track **source** EMUL, not dest.
- **Tail/mask:** `en` path matches other arithmetic — fine if B2 firmware always `ta=ma` or `vm=1`.

**vext:** Low half-lane sign/zero extend logic is correct for vf2/vf4. vf8 correctly never arms.

---

## (2) Legality

**`nc_illegal` for `op_nsr`:** Correct. vnsr is narrowing-class: source EMUL = 2·LMUL ≤ 1, and SEW32 narrowing (needs 64b source) must trap — same as vnclip on Zve32x.

**`vext` + `grp_only_illegal`:** Partially right, possibly **too strict**. vf2/vf4 **grow** dest EMUL (×2 / ×4); forbidding `grp_parts != 1` caps you at **dst LMUL = m1** only. Spec-legal cases like dst **m2/m4** (or src **mf2** with matching alignment) may trap in DUT while Spike runs them. B2 directed suite probably never leaves `grp_parts==1`.

**Overlap:** vext is widening-class for register layout. You should add a **`require_nooverlap`-style check** (vd vs vs1/vs2 per vf2/vf4 EMUL), analogous to `op_widen` — narrowing’s vd==vs2 allowance does **not** apply. Missing this is the main pre-B3 legality risk.

---

## (3) `vle32.v` trap @ e32/mf2, vlmax=2

**Probably not B2 regression** — vnsr/vext don’t touch vmem. For VLEN=128, SEW=32, LMUL=mf2 → vlmax=2 is legal; Spike normally accepts `vle32.v` there.

If DUT traps, treat as **latent vsetvli/vmem fractional-LMUL issue** (alignment, `vl`/`vstart`, or load illegal matrix), not Spike-matched until you run **that exact** `vtype` on Spike side-by-side. The 92-commit B2 lockstep wouldn’t cover it unless that config is in firmware.

---

## (4) Before B3 (vadc/vsbc)

- **Decode is safe:** vext = `is_opmvv && f6==010010`; vadc/vsbc = `is_opivv && f6==010010` — disjoint. B3 won’t collide with B2b.
- **Do fix overlap legality for `op_vext`** before piling on more OPMVV/OPIVV at the same f6.
- **Clarify EMUL>1 policy:** either document “vext m1-only” as an intentional Zve32x subset, or relax `grp_only_illegal` and wire proper multi-beat src/dst indexing (like widen).
- **Keep `vs1_i[4:3]==00` gate** for vext; reserve other `vs1` encodings on OPMVV+010010 as illegal until defined.

**Bottom line:** B2 semantics look Spike-aligned for the exercised space; biggest architectural debt is **vext overlap + fractional/multi-register EMUL**, not vnsr. Chase the `vle32`/mf2 trap separately on Spike — unlikely related to this diff.

## Gemini
### 1. Mask/Tail, `vstart`, and Legality Integration
* **`vstart` Legality:** Since `vnsr` and `op_vext` are added to the `known_op` list, they are subject to the global vector arithmetic trap guard `q_vstart != 32'h0 -> q_illegal`. This perfectly mirrors the choice of non-resumability for arithmetic instructions.
* **Element Masking/Tail:** Both extensions utilize the localized `vst_view` and `vl_view` boundaries and the `en` active lane control:
  * For `vnsr`, active elements write the narrowed shifted value `r`, while inactive lanes (and tail lanes) are preserved using `vd_old`.
  * For `op_vext`, active lanes perform zero/sign extension `e`, while inactive elements revert to `vd_old`.
* **Mask Overlap Rule:** The implementation correctly incorporates `op_nsr` and `op_vext` into the destination register overlap check:
  ```verilog
  ((op_add || op_sub || op_mm || op_s2same || op_nc || op_b1 || op_nsr || op_vext) && !vm && (vd_i == 5'd0))
  ```
  This cleanly prevents masked instructions from overwriting the mask register `v0` (as required by the RISC-V spec).

---

### 2. Narrowing Shift (`op_nsr`) Bus Reuse & Saturation Leakage
* **Saturation Gating:** Inside `g_nc8` and `g_nc16`, the narrowing shifts (`vnsrl`/`vnsra`) utilize the `res_nc8`/`res_nc16` results. Although `nc_sat8` and `nc_sat16` generate values during narrowing execution, the global saturating flag `q_vxsat` is immune to leakage. It utilizes `part_sat_or` which explicitly gates the check with `op_nc`:
  ```verilog
  (op_nc && ((vsew == 3'b000) ? (|nc_sat8) : (|nc_sat16)))
  ```
  Since `op_nc` is `0` when `op_nsr` is executed, no saturation can leak.
* **Independent Shifts:** The shifted expressions (`nsrl_w`/`nsra_w`) do not use the rounding increment `inc`. This guarantees that rounding mode `vxrm` does not contaminate logical and arithmetic narrowing shifts.

---

### 3. Register-Fill Muxing and `vd_old` Consistency
* **Narrowing Partials:** For `op_nsr` / `op_nc` (under single register/fractional-LMUL rules), only the lower half of the 128-bit destination is written (`gi < 8` elements for SEW8, `gi < 4` elements for SEW16). The upper 64 bits are cleanly assigned to undisturbed tail bits:
  ```verilog
  assign res_nc8[127:64]  = vd_old[127:64];
  assign res_nc16[127:64] = vd_old[127:64];
  ```
* **Extension Full-Fill:** In contrast, `op_vext` represents a full-register writeback (preserving element count relative to `vl`). `g_ext16` covers all 8 elements (bits 0..127), and `g_ext32` covers all 4 elements (bits 0..127), utilizing `vd_old` individually per inactive lane.
* **Mux Selection:** The writeback multiplexer is fully constrained:
  ```verilog
  op_vext ? ((vsew == 3'b001) ? res_ext16 : res_ext32)
  ```
  Since `op_vext` evaluates to `0` when `vsew == 3'b000` (SEW8), this 2-way select is perfectly precise.

---

### 4. Decode Collision and Legality Verification
* **Decode Uniqueness:** `ext_enc` selects `is_opmvv` with `f6 = 6'b010010`. This is fully disjoint from `vmadc.vvm`/`vsbc.vvm` (which reside on the `OPIVV`/`OPIVX` space) and prevents any decode collisions.
* **ISA Bounds Enforcement:** 
  * **`vf8`:** Automatically evaluates to `op_vext = 0` (via the `vs1_i[2:1]` check) and triggers `!known_op -> q_illegal`. This correctly mirrors the Zve32x restriction (no SEW64 destinations).
  * **`vf4` at SEW16:** Evaluates to `0` since `vf4` is only allowed when `vsew == 3'b010` (SEW32). Correct (source size cannot be < 8b).
  * **`vf2` at SEW8:** Evaluates to `0` since `vf2` is restricted to `vsew == 3'b001` or `3'b010`. Correct (source size cannot be < 8b).
