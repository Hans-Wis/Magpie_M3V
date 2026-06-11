# Magpie_M1 — Coverage Report (Tier-2 §05 deliverable)

Rev 1.0 · 2026-06-11 · Owner: PL (Claude) · design_id = `cpu_m1`
Scope: RV32IMC core (SKU-1, `FEATURE_FREEZE.md`). Authority for correctness = Spike lockstep + gates.
This report is the §05 "Coverage Report (per sub-block + exclusion list)" deliverable, and it contains
the **whole-core toggle gap root-cause analysis** (Tier-2 blocker #1).

## 1. Headline (honest dual-number)

| Metric | Tier-2 bar | Per-island (gate_p02..p14) | **Whole-core (signed number)** | status |
|---|---|---|---|---|
| Line | 100% | 100% | **~95.95%** (1374/1432) | 🟡 |
| Branch | 100% | 100% | **~96%** (gate_p19) | 🟡 |
| Expr/Cond | 95–100% | ≥95% | **~79%** (gate_p19, floor 78) | ❌ |
| Toggle | 95% | ≥95% | **62.93%** (12745/20252, best single run) | ❌ |
| FSM | 100% | 100% | 100% | ✅ |

Per-island modules (alu/lsu/rfu/forward/hazard/mul/div/idu/cdec/csr/ras/bp/ifu) are at Tier-2.
The **whole-core** numbers are the acceptance numbers and are below bar — this report explains why and
how to close.

## 2. Toggle gap root-cause (blocker #1) — why 62.93%, and the path to 95%

**Finding 1 — the 62.93% is a single run, not a merge.** `gate_04_09` reports `max()` of the per-phase
DUT toggle %, i.e. the best *single* directed coverage run, not an aggregated coverage database. The
true achievable number with all stimulus merged is higher — but (Finding 2) the existing DBs cannot be
naively merged.

**Finding 2 — the whole-core coverage DBs were collected under different testbench tops.** The 6 whole-
core `.dat` files (`phase_04_01..07`) were each produced by a *different* TB (`tb_csr_irq`,
`tb_rv32c_cross_coverage`, `tb_bp_ras`, …). Verilator keys each coverage point by hierarchy path
(`h=tb_rv32c_cross_coverage.dut.u_alu`), so the same RTL bit under two different TBs is two distinct
points. Merging the 6 DBs inflates the point count (~20k → ~75k) instead of aggregating hits — a cross-TB
merge is **not** a valid whole-core toggle number.

**Finding 3 — the 105k-commit riscv-dv farm collects NO coverage.** `phase_03_09` builds its Verilator
model without `--coverage`, so the single largest stimulus source (105,111 commits of varied RV32IMC) is
not contributing any toggle data. This is the **biggest missed lever**.

**Closure plan (OSS, in-sandbox):**
1. **Instrument ONE TB with `--coverage` and accumulate** — rebuild the riscv-dv farm TB
   (`tb_riscvdv_lockstep`) with `--coverage`, run N seeds writing into a single consistent `coverage.dat`
   (Verilator accumulates across `--write-coverage` runs under one model). 105k varied commits should
   toggle the large majority of datapath + control bits in one coherent hierarchy.
2. **Directed top-ups** for residual control bits the random stream rarely hits (specific CSR fields,
   debug/trigger paths if in-scope, redirect/flush corner toggles).
3. **§04 written waivers** for true-unreachable toggles: default-config tie-offs (e.g. `RV32A=0` leaves
   AMO datapath bits untoggled, `PMP_ENTRIES=0` leaves PMP bits untoggled — structurally unreachable in
   the default SKU), and unused/parameterized-width upper bits. Each waiver: bit, unreachable reason,
   `spike_impact:none`, DV-lead sign.
4. Re-measure merged toggle on the single consistent DB; expect ≥95% after (1)+(2), the remainder waived.

Estimated effort: ~1–2 days (farm coverage rebuild + seed runs + merge + waiver authoring).

### 2.5 MEASURED (2026-06-11 farm-coverage run — executed)

Rebuilt the riscv-dv farm TB (`tb_riscvdv_lockstep`, single consistent hierarchy) with `--coverage`,
ran 8 seeds (`--keep-passing-runs`), merged `runs/seed_*/coverage.dat` →
`phase_03_09_riscvdv_lockstep/coverage_merged/farm_merged_coverage.dat`
(breakdown: `coverage_merged/toggle_breakdown.txt`). Result — **random RV32IMC plateaus at 53.3% toggle**
(10905/20450), confirming closure is NOT a stimulus-volume problem. Per-module decomposition:

| module | toggle | untoggled | disposition |
|---|---|---|---|
| alu/forward/hazard | 100% | 0 | core datapath fully toggled ✅ |
| mul/div/lsu | ~99–100% | 1–6 | ✅ |
| idu/cdec | 85–87% | 64–94 | directed corner top-ups |
| bp/ifu/rfu | 36–73% | 143–297 | DIRECTED (predictor/fetch/regfile corner) |
| **u_csr** | 18% | **3079** | DIRECTED (per-CSR field reads/writes — large bucket) |
| **u_ras** | 5.5% | **624** | DIRECTED (random has few call/return; need call/ret mispredict) |
| **dut glue** | 60% | **2998** | MIXED — RAS/debug-mode signals (directed) + AXI/glue (waiver) |
| **u_pmp** | 7% | **921** | **§04-WAIVABLE** (PMP_ENTRIES=0 in default SKU — structurally tied off) |
| **u_trigger** | 22% | **835** | **§04-WAIVABLE** (debug-trigger inactive in default SKU) |

**Decomposition of the 9545 untoggled bits:** ~1756 are structurally-disabled optional subsystems
(PMP + trigger) → §04 waivers per `FEATURE_FREEZE.md` (excl. those → 58.3%). The rest is dominated by
**u_csr (3079)** and **u_ras (624)** + debug-mode glue — these need DIRECTED stimulus (CSR field
sweeps, call/return mispredict streams, a debug-active run), not more random. **The core ALU/forward/
hazard/mul/div/lsu datapath is already ~100% toggled.**

**Revised closure path to 95% (precise, from measured data):**
1. §04 waivers: PMP (921) + trigger (835) + AXI-master/unused-counter glue → ~2.5–3k bits (disabled-in-SKU).
2. Directed CSR coverage program (sweep mstatus/mie/mip/mtvec/mepc/mcause/mscratch/mhartid + WARL fields) → most of u_csr's 3079.
3. Directed RAS call/return + mispredict stream → u_ras 624 + dut RAS glue.
4. Debug-active farm run (or fold the existing debug phases' coverage) → debug-mode glue bits.
5. Re-merge → expect ≥95% on the in-SKU denominator after waivers. Remaining effort ~1–2 days (directed
   programs + waiver authoring). Status: **measured + decomposed; directed/waiver campaign pending.**

## 3. Branch / Expr (blocker #2)
Whole-core branch ~96% / expr ~79% have the same single-TB limitation. The expr gap (~79%) is mostly
compound conditions in `core.v` trap/hazard priority logic that the directed mix under-samples; the
coverage-instrumented farm (plan §2.1) plus a few directed priority-ordering tests should lift both,
with §04 waivers for structurally-unreachable compound terms (mutually-exclusive guard combinations).

## 4. Functional coverage (§02) — status
riscvISACOV-mapped: ISA instruction 100%, M corner 100%, corner operands 100% (`riscvisacov_equivalence.md`).
Partial: per-mnemonic RVC bins, ISA-level RAW/WAW/WAR register-cross, per-CSR address bins (to author).
Custom covergroups: 72/72 bins (`gate_04_08`).

## 5. Formal coverage (§03)
VC Formal FCA (`phase_p_formal_coverage`): alu/rfu/forward/lsu **100%**, csr **10%** (needs more csr
properties to reach the Tier-2 ≥90% bar). 40/40 SVA properties proven, 0 CEX.

## 6. Exclusion list (current waivers)
Structural-only, dual-number RAW+ADJUSTED, `spike_impact:none`, producer≠approver, retained in
`IP/cpu_m1/dv/cov/waivers/`. The toggle/expr §04 waivers from §2.3/§3 are TO BE AUTHORED as part of
closure (not yet applied — so the whole-core numbers above are RAW, honest).

### 2.6 Waiver applied (2026-06-11)

§04 structural waiver authored: `IP/cpu_m1/dv/cov/waivers/toggle_structural_waivers.json` (PMP 921 + trigger 835 = 1756 bits, PMP_ENTRIES=0/debug-trigger-inactive in default SKU, spike_impact:none, **producer=Claude / approver_dv_lead=PENDING-SIGN**). **In-SKU adjusted toggle = 10905/18694 = 58.3%.** Remaining directed buckets to 95%: u_csr 3079 (riscv-dv `gen_csr_test.py` walking-bit CSR test — next step), u_ras 624 (call/return density), debug-mode glue.

### 2.7 Directed CSR-injection + refined waiver (2026-06-11, executed)

Extended the proven lockstep-safe injection mechanism to inject DETERMINISTIC CSR reads (mhartid/
mstatus/mie/mtvec/mscratch/mepc/mcause/mtval) + mscratch walking writes into the random stream
(`inject_csr_cov.py`, coverage build, 4 seeds). **Lockstep finding (real catch):** injecting reads of
*timing* CSRs (cycle/instret/mip) poisons the destination GPR with a DUT≠Spike value that diverges
downstream — excluded those; deterministic-CSR injection is 0-divergence (8243 commits). u_csr toggle
18.4%→21.5% (read-mux paths; storage bits need writes/traps).

**Refined structural waiver (`toggle_structural_waivers.json`):** u_csr's untoggled decomposes as
PMP-CSR 1280 + DEBUG-CSR 615 (both **waivable**, disabled in default SKU) + TRAP-CSR 229 (trap variety)
+ M-CSR 342 (directed writes) + other 495. Total structural-waivable now **3651** (u_pmp 921 + u_trigger
835 + u_csr-PMP 1280 + u_csr-DEBUG 615).

| | toggle |
|---|---|
| raw (8 farm seeds) | 10905/20450 = 53.3% |
| + CSR-injection (12 seeds) | 11149/20450 = 54.5% |
| **in-SKU (after 3651-bit structural waiver)** | **11149/16799 = 66.4%** |

**Remaining to 95% (in-SKU):** u_ras 624 (directed call/return), u_csr M-CSR/TRAP storage ~571 (directed
walking CSR writes + trap variety), u_csr other 495, ifu/bp/idu/cdec/rfu corner. Est ~1 day directed.
Status: CSR-injection + full structural waiver done (66.4% in-SKU); RAS + CSR-write directed pending.

### 2.8 RAS (u_ras 624) — sub-program lever blocked by pyflow hang (2026-06-11)

Attempted the native RAS lever: raise riscv-dv `--num_of_sub_program` (0→8, then 2) so the generator
emits a call graph (jal ra / ret) to toggle the return-address stack. **The vendored riscv-dv PYFLOW
generator HANGS with num_of_sub_program > 0** (gen process at 0 CPU, no asm, >5 min — a riscv-dv pyflow
limitation, not a cpu_m1 issue). Recorded in `inject_ras_cov.py`. FALLBACK (next step): inline
control-flow-neutral call/return injection (`jal ra,2f; 1: beq x0,x0,3f; 2: jalr x0,0(ra); 3:`) — same
proven lockstep-safe mechanism as fence/CSR injection — for RAS push/pop; mispredict-recovery needs a
return target != RAS top. u_ras 624 remains open pending this fallback (or a VCS gen path).

### 2.9 RAS inline-injection (executed, lockstep-safe) — u_ras 5.5%→15.2%

The pyflow sub-program hang (§2.8) forced the inline fallback: `inject_ras_inline.py` injects control-
flow-neutral call/return snippets (ra saved/restored via mscratch) — both correct-predict and
mispredict-recovery (ADR-0008) RAS paths — into random riscv-dv programs. **4 seeds, 7793 commits, 0
divergence** (lockstep-safe: RAS is a predictor invisible to retire; Spike has no RAS). u_ras toggle
**5.5%→15.2%**. (One harness fix en route: the work-dir path overran the TB `+TRACE=%s` reg buffer and
front-truncated `/home`→`ome`; shortened the dir.)

| | toggle |
|---|---|
| raw (base 8 + CSR 4 + RAS 4 = 16 seeds) | 11351/20450 = 55.5% |
| **in-SKU (after 3651-bit waiver)** | **11351/16799 = 67.6%** |

**RAS long-tail remaining:** deeper RAS stack entries need NESTED calls (depth>1, my snippets are
depth-1); ras_top high bits need address-varied return targets (my labels are in a narrow range). u_csr
M/TRAP storage (~571, directed CSR writes + trap variety), ifu/bp/idu/cdec corner also remain. This is
the classic coverage long tail — datapath 100%, predictor/CSR-storage/control bits each need bespoke
stimulus. Est ~1 day more directed + the §04 waiver DV-lead sign to reach the in-SKU 95% bar.

### 2.10 CSR save-modify-restore pattern injection — u_csr 21.6%→31.6%, in-SKU 67.6%→70.4%

The §2.4 CSR-read injection only toggled the read mux + mscratch; u_csr write-data / storage high bits
stayed dark. `inject_csr_pattern.py` adds the missing lever: for each writable M-CSR
(mscratch/mepc/mcause/mtval/mtvec/mstatus/mie) it injects a **save-modify-restore** snippet —
`csrr x31,<csr>` (save OLD), two `csrw <csr>,xPAT` with walking 0xAA/55/FF/00 patterns, then
`csrw <csr>,x31` (restore). **8 seeds, 17740 commits, 0 divergence.**

**Why lockstep-safe (verified against `flow/v2_pipeline/lib/spike_commit.py`):** the comparator parses
only `(pc, rd, wdata)` GPR writebacks from Spike `--log-commits`. A `csrw csr,rs` (rd=x0) emits **no**
`x<rd> 0x<wdata>` field, so the patterned — possibly WARL-legalized-differently on subset CSRs
(mstatus/mtvec/mie) — value is invisible to the comparator and cannot diverge. The only compared writes
are the save-read (OLD value — the same read the base farm does safely at 105k commits/0-div) and the
deterministic `li` constants. Restore returns architectural state, so the random program continues
unperturbed. This is *more* aggressive than the conservative "mscratch + RO csrr only" advice yet has a
concrete safety proof from the comparator's granularity.

| | toggle |
|---|---|
| raw (base 8 + CSR-read 4 + fence 4 + RAS 4 + CSR-pattern 8 = 28 seeds) | 11824/20450 = 57.8% |
| **in-SKU (after 3651-bit waiver)** | **11824/16799 = 70.4%** |

u_csr **813/3772 (21.6%) → 1192/3772 (31.6%)**. Full-width plain regs saturate to 100% (mscratch,
mcause, mtval; mepc 62/64). Coverage **plateaus after one seed** — walking patterns toggle every
instruction-stream-reachable CSR storage bit, so the 7 extra seeds add 0 new u_csr bits (they re-prove
lockstep at scale).

**u_csr residual (2580 untoggled) — precise classification (`classify_csr_waiver.py`):**

| bucket | bits | disposition |
|---|---|---|
| PMP (`pmp_addr_o/pmpaddr_r/pmp_cfg_o/pmpcfg_r`) | 1280 | structural waiver — PMP_ENTRIES=0 SKU (same class as u_pmp_*) |
| DCSR/DPC/DSCRATCH | 267 | structural waiver — debug-mode CSRs, debug never entered |
| TRIGGER routing | 218 | structural waiver — trigger inactive (same class as u_trigger) |
| DEBUG halt iface | 194 | structural waiver — debug halt never asserted |
| CONST read-mux zero fields (`misa/mstatus/mie/mip` hardwired-0) | 240 | unreachable — constant nets, cannot toggle by construction |
| COUNTER high bits (`cycle/instret`) | 202 | unreachable — rollover needs >2³² cycles |
| IRQ-sourced (`mip/irq_cause/ext_pending`) | 76 | → blocker 4b (msip software-interrupt directed) |
| coverable (trap_cause/trap_pc variety, mepc) | 103 | more directed trap-variety seeds |

**Structural+const+counter waiver subtotal = 2401 bits** (DV-lead sign PENDING). Applying it,
u_csr in-SKU = **1192/1371 = 87.0%**; the only genuine remaining stimulus gaps are IRQ (blocker 4b)
and trap-cause/PC variety (~50 bits). Artifacts: `csr_pattern_summary.json`,
`coverage_merged/farm_all2.dat`, `coverage_merged/toggle_breakdown.txt`.

### 2.11 msip directed lockstep — IRQ-sourced u_csr bits reachable + blocker #4b lockstep-able path

The §2.10 residual flagged 76 u_csr "IRQ-sourced" bits as needing interrupt stimulus. `phase_03_14_msip_
directed` drives the **msip** (CLINT M software interrupt, ADR-0019) — the *deterministic*, lockstep-able
interrupt — through a real handler. **Prefix per-commit lockstep vs Spike (12 commits, 0 divergence) +
spec-validated handler** (mcause=`0x8000_0003`, mepc=`0x82`, mstatus=`0x1880`, resume=`0x600d`); same
rigor as the through-trap slice (gate_03_12). This **closes blocker #4b's lockstep-able path**
(`gate_03_14`, 5/5).

The `--coverage` island confirms the msip IRQ path **toggles** in u_csr: `msip` 2/2, `irq_msi` 2/2,
`irq_pending` 2/2, `mie_msie`, `mstatus_mie` 2/2, `mip[3]`, `irq_cause`(MSW), `mcause_reg`(0x80000003).
Cold (as expected — non-msip paths): `ext_pending`/`irq_mei` (meip, external) and `irq_mti` (timer),
which stay **directed-only** (Spike has no deterministic async meip/mtip injection).

**Honest merge caveat:** this is a **per-island** result, *not* added to the farm 70.4%. A distinct TB
top (`tb_msip_directed`) gives every toggle point a distinct coverage *hierarchy* string, so a cross-TB
`verilator_coverage` union would double-count, not merge (the same cross-TB-unmergeable limitation noted
for the earlier "62.93%" figure). The island stands as per-island evidence that the msip IRQ bits are
reachable + lockstep-validated; folding IRQ coverage into the farm number would require driving msip
inside the farm TB itself. Artifact: `phase_03_14_msip_directed/msip_directed_summary.json`.
