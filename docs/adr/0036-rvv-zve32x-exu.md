# ADR-0036 — Phase 3: RVV Zve32x EXU (in-core, staged 3A–3D) + P0④ vector-CSR lockstep contract

- Status: **ACCEPTED** (per-phase architecture confirmation, CLAUDE.md §2; User directive
  2026-07-04 "下一步(a)"). Architects: Grok (staging/microarch/contract/DV) + **Gemini
  full-context** (Coral vector dossier + ADR-0034/0035 backfill review — quota unblocked via
  the background-run + file-polling pattern; both prior ADRs reviewed **consistent, no
  unbacked claims**). Integrator/approver = Claude PL.
- Date: 2026-07-04
- Relates: ADR-0031 (scope: rv32im_zve32x_zvl128b, VLEN=128, int-only), ADR-0032 (EN_* param
  spine), ADR-0034 (live sequencer), ADR-0035 (CQ). Phase 3 exit bar = the Phase 0 proof
  kernel (clang, `vsetvli e8/mf4 → vle8.v → vwmul.vv → vwadd.wv → vredsum.vs → vmv.x.s →
  vse32.v`, result 240) runs on RTL with full stated evidence.

## Coral comparison (Gemini dossier, observation-only)

Kelvin: RVV 1.0 Zve32x/Zvl128b, SEW 8/16/32, **2× Vector ALU behind a Vector Command Queue**
(~8 deep, non-blocking dispatch + scoreboard for vector→scalar writebacks), **128-bit vector
LSU into DTCM** (unit-stride 128b/cycle; strided serialized), standard vector CSRs with
limited `vstart` resumption in the open emit.

**Recorded deviation (function-parity honest):** Phase 3 builds an **in-core iterative EXU**
(scalar pipe freezes for the op; VLEN128/ELEN32 = 4×32b lanes) and reuses the **32-bit scalar
dbus** for unit-stride vector memory. Coral's VCQ + 128-bit LSU are a *throughput shape*, not
a replaceability requirement — the matrix engine + CQ (ADR-0035) is the ML MAC path, and the
`vector_exu` boundary (`start/busy/done/illegal`, no CQ embedded) lets Phase 4/5 add a
decoupled issue buffer without ISA/lockstep changes. 128-bit TCM port = P1 (with DTCM split).

## Decision — staging (each stage independently gated, no stage skipped)

| stage | scope | minimum op/feature list |
|---|---|---|
| **3A** | vector CSRs + config, **no datapath**; **P0④ lands here** | `vsetvli/vsetivli` (incl. `rs1=x0`/`rd=x0` keep semantics); CSRs `vtype/vl/vstart/vxsat/vcsr/vlenb`; `vill` set + propagation (post-illegal config every vector op is illegal until a legal `vsetvli`); fractional LMUL legality (`mf2/mf4/mf8`) and `vlmax` math |
| **3B** | VRF 32×128b + same-SEW integer ALU | `vadd.vv/vsub.vv/vmv.v.v/vmv.v.x/vmv.v.i`, `vmv.x.s`, `vmerge.vvm` (mask plumbing smoke); LMUL 1 + fractional; lane iterator |
| **3C** | unit-stride LSU on the scalar dbus | `vle8.v`, `vse32.v` (+`vle32.v`); `vl`-bounded beats; one vector mem op atomic across beats under `mem_stall`; TCM-wrap + mailbox/CSR-window non-collision directed |
| **3D** | widening + reduction → kernel e2e | `vwmul.vv` (i8×i8→i16), `vwadd.wv` (→i32), `vredsum.vs`; **exit: Phase 0 kernel = 240 on RTL** |

**Microarchitecture:** `EN_RVV` elaboration parameter on the cpu_m1 spine (host default **0**
— host equivalence untouched; NPU config 1). Vector unit sits beside mul/div at EX with the
same busy/stall discipline; VRF is architecturally separate (no scalar RFU change). LSU
captures dbus data per beat; no second scalar mem op until vector `done`.

**Deferred honestly (recorded):** strided/indexed loads, LMUL m2/m4/m8 (m1+fractional only),
masked-op completeness beyond `vmerge` smoke, saturating ops (so `vxsat` has no setter yet —
it is still a real, readable/writable CSR in the checkpoint contract), `vxrm` rounding modes,
vector FP (Zve32x excludes), 128-bit memory port.

## P0④ — vector-CSR lockstep contract (the bar, pinned)

Commit-trace comparison is scalar-centric; the honest layered authority is:

- **Per-commit (MUST):** (a) every `vsetvli` writes `rd` → already in the compared stream;
  (b) **firmware checkpoint discipline**: after every `vsetvli` and after every vector
  instruction that can change `vl/vtype/vstart/vxsat`, the test firmware executes `csrr` of
  those CSRs (+`vlenb` once) so the values enter the compared scalar stream bit-exact.
- **Post-run (MUST):** every vector-store target region in TCM compared against the Spike
  memory image (authoritative for `vse*`).
- **NOT required for P0④:** per-lane VRF shadow per commit (Spike's vector commit-log format
  is not RVFI-clean; usable for debug, not gate authority).

The checkpoint discipline is verification SSOT (test macro + linker), same tier as the
dual-linker normalization.

**Spike golden:** `--isa=rv32im_zve32x_zvl128b` (pins VLEN=128; **no C, no F** — green-wash
guard), same dual-base normalization. **Tail policy:** per-instruction RVV-1.0/Spike
behavior, documented as an opcode table in the `00_isa_contract.md` delta when 3B lands —
not a single global choice.

## Gates

| gate | stage | pass bar |
|---|---|---|
| `gate_40_vector_csr_lockstep` | 3A | `vsetvli/vsetivli` grid (SEW×LMUL incl. mf2/4/8, boundary vl = vlmax/vlmax−1/1, keep-vl x0 matrix) with dense `csrr` checkpoints — 100% scalar-stream match vs Spike |
| `gate_41_vill_illegal_ladder` | 3A | illegal config → `vill`; following vector op behavior matches Spike; recovery via legal `vsetvli` |
| `gate_42_vector_alu_lockstep` | 3B | directed OPIVV/vmv + 1k-commit mixed vector-scalar random smoke (C off, checkpoints mandatory) |
| `gate_43_vector_lsu_tcm` | 3C | `vle8/vse32` varied `vl` + TCM-wrap edge; post-run TCM region == Spike; LSU-vs-scalar-mem and LSU-vs-DMA stall directed |
| `gate_44_phase0_kernel_e2e` | 3D | the unmodified Phase 0 clang kernel: result 240 + full scalar commit match + result region == Spike |

**Green-wash guards:** wrong `--isa` (C or missing zvl128b); vector ops without checkpoints;
claiming lockstep from `vsetvli rd` alone; kernel recompiled with a different `-march`;
skipping the memory-region compare; host config elaborating with `EN_RVV=1`.

## Top risks → directed catch

1. Fractional-LMUL `vlmax` math (`e8,mf4` is kernel-critical) → gate_40 boundary grid.
2. `vill` not enforced on subsequent vector ops → gate_41 ladder.
3. `vsetvli` x0 keep-vl/keep-vtype semantics → gate_40 rs1/rd ∈ {x0,≠x0} matrix.
4. Widening dest-overlap/EMUL legality (`vwmul/vwadd.wv`) → gate_44 + directed illegal encodings.
5. `mem_stall` × multi-beat vector LSU (atomicity, DMA-write priority collision) → gate_43 stress.

## Stage 3A result (2026-07-04)

**Gates 40/41 green.** `gate_40`: vset{i}vl{i}/vsetvl grid (SEW×LMUL incl. mf4/mf2, AVL
boundaries, vsetivli, tail/mask bits, keep-vl x0 matrix, register-vtype form) + dense csrr
checkpoints — 146 commits, 100% match vs Spike `rv32im_zve32x_zvl128b`. `gate_41`: vill
ladder (e8mf8/e16mf4/e32mf2 fractional violations, reserved vlmul=100, e64, reserved vtype
bits — injected via vsetvl rs2) + recovery — 51 commits matched. Host equivalence: EN_RVV=0
default, phase_03_00 lockstep re-run pass, full suite = pre-existing failures only.

**Bug found by gate_40 and fixed (PL surgical):** the CSR read-after-write bypass matched
exact addresses only — a write to one member of the `vxsat/vxrm/vcsr` ALIAS group was not
forwarded into a same-window read of another member (nor were `mstatus.VS` dirty side
effects), giving stale reads in the EX/MEM (1-apart) and WB (same-cycle, 2-apart) windows.
Fixed in both windows (core.v overlay + csr.v same-cycle alias forward); adjacent-pair cases
added to the gate_40 firmware permanently. Two source-literal assertions in
`gate_02_00` were synced to the governed mstatus/illegal-path changes.

## Stage 3B result (2026-07-04) — PL-design mode trial

**Gate_42 green** (directed 69/69 + mixed random 819/819 commits vs Spike); gates 40/41 and
the full suite re-green (host EN_RVV=0 lockstep unchanged; one hazard.v source-literal gate
synced). Implementation BY THE PL (mode trial per User 2026-07-04): `vexu.v` (VRF 32x128b,
combinational EX compute, WB-commit with scalar-rd kill rules so trap/IRQ replay never sees
partial VRF state), conservative RAW stall (<=2 bubbles, 128b forwarding = recorded perf
debt), effective-config forwarding at EX (incl. the **3A latent fix**: vset-in-flight at
EX/WB was not forwarded to a vset/vop at EX), csr/core vstart+VS read-forward windows,
COMMIT_RE extended for Spike RVV commit lines (backward compatible), VRF debug tap.

**Spike-matched semantics DISCOVERED by lockstep (contract corrections):**
1. **Arithmetic with vstart!=0 traps illegal** — Spike's spec-allowed choice; the plan's
   earlier claim ("not illegal", Grok) was wrong. Scoped to the arithmetic subset; 3C
   loads/stores stay resumable (Grok re-review confirms scoping is the 3C blocker to watch).
2. **Tail policy = UNDISTURBED regardless of vta** — this Spike build implements
   tail-agnostic as undisturbed, not all-1s. Recorded as the ISA-profile choice; directed
   tail case + clang-emission check before Phase 3 exit (parity guard).

**Review round (new labor model):** Codex surgical review found **one real bug** the random
corpus missed — masked (vm=0) vadd/vsub was accepted and executed unmasked; fixed
(q_illegal now rejects it; masked forms other than vmerge = recorded 3B deferral). Grok
architecture review: approve; flags adopted as stage gates — LMUL>1 needed only post-kernel
(kernel widening path is fractional-only), LSU assemble buffer lives MEM-side not VRF (3C),
128b forwarding before 3D perf claims, tail-profile doc+test before exit.

## Stage 3C result (2026-07-04) — PL-design mode, second round

**Gate_43 green**: directed vmem lockstep 110/110 commits (vle8/16/32, vse16/32, EEW!=SEW
with EMUL=mf4, partial-vl stores with sentinels, whole-register store proving the
undisturbed policy IN MEMORY, vl=0 no-ops, and a **vstart!=0 resumable load** — Spike
executes it, lockstep-proving the arithmetic-only scope of the vstart-illegal rule).
Random corpus extended with one legal-EEW unit-stride memory op per block against a
scalar-initialized pool: 841/841 commits. Memory authority realized IN-STREAM (every
vector-store target scalar-lw'ed back; every vector load reads scalar-sw-initialized
data) — the P0④ post-run half, delivered through the commit stream itself.

**Microarchitecture (per Grok's 3C flags):** the memory FSM + 128b assemble buffer live in
vexu (MEM-side, never streaming into the VRF); 2-cycle-per-element ISSUE→CAP beats on the
32b dbus gated by `mem_stall`; the FSM **starts only with EX/MEM+EX/WB drained**, so no
older instruction exists during a run — wrong-path store beats and mid-op flush/IRQ are
impossible by construction.

**Codex review round — 3 findings, all real, dispositioned:**
1. VS=Off deadlock on a legal vmem op (hold ignored the VS gate; the op could neither
   start nor trap) → **fixed** (VS folded into `vex_mem_hold`).
2. Vector beats bypass data PMP + load/store triggers → **recorded limitation**
   (unreachable in every current config: NPU has PMP_ENTRIES=0 and no debug module, host
   has EN_RVV=0; must be plumbed before RVV meets a PMP/debug-bearing config).
3. A vmem op could finish its beats then be IRQ-killed at its own WB slot — the handler
   would observe store data Spike has not written → **fixed** (interrupt acceptance gated
   while a vector-memory op is in flight, EX hold through WB commit — a bounded
   instruction-boundary delay; host trap/IRQ lockstep re-verified green).

## Stage 3D result (2026-07-04) — PHASE 3 EXIT BAR MET

**The unmodified Phase 0 clang kernel runs on RTL: dot([1..8],[2..9]) = 240, 43/43 commits
matched vs Spike**, result observed three ways in the compared stream (a0 return, register
move, scalar readback of the stored slot). Directed vwide lockstep 86/86: vwmul.vv,
vwadd.wv with the kernel's vd==vs2 accumulate, vmv.s.x, vredsum.vs (vd==vs2), negative
operands through widening, 16-bit lanes memory-verified via vse16, vl=0 no-ops.

Bugs found and fixed during 3D (both by the verification loop, not by inspection):
1. **Verilog signedness trap**: an unsigned concat branch inside a conditional silently
   zero-extended negative operands (0x81 -> 129) — caught by the directed negative-squares
   case; fixed by computing each result in an all-signed expression.
2. **WIDTHEXPAND lint regression**: the signedness fix introduced implicit-width adds that
   broke every core-linting gate in the suite — caught by the full-suite diff discipline;
   fixed with equal-width manual sign-extension (bit-exact, directed re-verified).

Codex 3D review: **CLEAN** (decode aliasing OPIVV/OPMVV f6=000000, widening overlap rules
vs Spike VI_CHECK_DSS/DDS, reduction corners, vmv.s.x semantics all checked).
Recorded deferrals: random-corpus widening coverage (directed + kernel are the 3D bar);
128b operand forwarding stays perf debt (function-parity exit met with conservative stalls).

**Phase 3 exit declared**: vector rows of the Coral parity checklist move to PARTIAL —
the TFLM int8 kernel subset of Zve32x is lockstep-proven end-to-end; full Zve32x coverage
(masking, saturating ops, strided memory, LMUL>1) remains recorded future work.
## Labor division (§5)

Grok+Gemini arch (done, this ADR) → Codex staged RTL (3A first: idu/csr/core `EN_RVV`
generate + vector CSR block; each stage self-smoke) → Claude authoritative gates 40–44,
host-equivalence re-run (EN_RVV=0 unchanged), sole commit per stage.
