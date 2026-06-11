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
