# Magpie_M3V Full-Circuit Verification & Coverage Signoff Plan

**Audience:** ADR roadmap + gate plan draft  
**Authority hierarchy (non-negotiable):** Spike lockstep / bit-exact golden / scoreboard = correctness; coverage = completeness evidence only.

---

## 1. Phasing (V0 → Signoff)

### Phase map

| Phase | Name | Primary deliverable | Depends on | Parallel with |
|-------|------|---------------------|------------|---------------|
| **V0** | Infra & contracts | Coverage SSOT YAML, DUT wrappers, merge scripts, waiver DB schema | — | — |
| **V1** | Instruction coverage | ISA tracker from Spike logs; per-extension report; exclusion ledger | V0 | Spyglass (V2) |
| **V2** | Spyglass static | Lint/CDC/RDC clean per ADR-0006 contract | V0 | V1, V3-prep |
| **V3a** | Block functional (existing gates) | All ~125 pytest gates green; 4 lockstep harnesses frozen baselines | V0 | V1, V2 |
| **V3b** | Integrated top functional | `soc_m3v_top` (host + NPU + fabric) directed + random lockstep | V3a | V4-prep |
| **V4** | Functional coverage (VCS) | SV covergroups + cross bins; UCDB per suite | V3b | V5 Verilator cov |
| **V5** | Code coverage — Verilator | Line + toggle + expr; nightly merge; gap triage | V3a (block OK) | V4, V6-prep |
| **V6** | Code coverage — VCS signoff | line/cond/branch/tgl/fsm; urg merge; waiver signoff | V3b + V4 seeds | V5 (compare) |
| **V7** | Dual-sim agreement | VCS ↔ Verilator coverage delta report; functional trace replay | V5 + V6 | — |
| **V8** | Signoff package | ADR + gate_8x evidence; raw vs effective; known-gaps doc | V1–V7 | — |

### Recommended order (why)

```
V0 ──┬── V1 (instruction cov)     ← cheap, uses existing Spike logs
     ├── V2 (Spyglass)            ← fully independent
     └── V3a (block gates green)  ← correctness floor

V3a ── V3b (integrated top)       ← heaviest functional; unlocks real crosses

V3b ──┬── V4 (func cov, VCS)      ← heaviest new work; needs stable stimulus
      └── V5 (Verilator code cov) ← fast iteration; block-level first

V4 + V5 ── V6 (VCS code cov signoff)
V5 + V6 ── V7 (dual-sim agreement)
ALL ─────── V8 (signoff)
```

**Rationale:**
- **Instruction cov first (V1):** Zero new RTL sim; replay `spike.log` / `--log-commits` from phase_20/21/22/23 + pytest. Surfaces ISA holes before writing covergroups.
- **Spyglass parallel (V2):** No sim dependency; blocks tape-out lint surprises.
- **Integrated top before func cov (V3b):** Block-only misses AXI fabric arbitration, doorbell path, IRQ merge, Harvard ITCM/DTCM load races.
- **Functional covergroups after integrated stimulus (V4):** Covergroups are expensive to write and regress; need stable `soc_m3v_top` TB.
- **Verilator code cov before/alongside VCS (V5→V6):** In-sandbox nightly; VCS is signoff-only (OUTSIDE-SANDBOX, licensed).

### Parallelism summary

| Track A (correctness) | Track B (static) | Track C (coverage) |
|-----------------------|------------------|---------------------|
| V3a gates | V2 Spyglass | V1 ISA from Spike |
| V3b integrated lockstep | — | V5 Verilator (block) |
| — | — | V4 VCS covergroups |
| — | — | V6 VCS signoff |
| V7 dual-sim | — | V8 merge |

---

## 2. DUT Scope

### Tiered DUT strategy (must-have)

| Tier | DUT | Purpose | Signoff? |
|------|-----|---------|----------|
| **T0** | `cpu_m1` (host config) | Scalar + host-only paths | Must |
| **T1** | `npu_top` (NPU config) | RVV + mat + DMA + CQ + traps | Must |
| **T2** | `soc_m3v_top` (integrated) | Cross-domain, fabric, IRQ, boot | **Must for full-circuit** |
| **T3** | Sub-blocks for deep FSM | Targeted FSM closure | Nice-to-have where integrated sim is slow |

**Do not sign off on integrated coverage using only block-level DUTs.** T0/T1 are necessary but not sufficient for "full-circuit."

### Integrated top contents (T2)

- `cpu_m1` @ host params (`EN_RVV=0`, `EN_F=1`, `EN_RVC/BP/RAS=1`, Zba/Zbb/Zbs/Zicond)
- `npu_top` @ NPU params (`EN_RVV=1`, `EN_F=1`, stripped sequencer, TCM fetch)
- AXI interconnect (host → NPU CSR/TCM/DMA path)
- Shared mem model @ `0x8000_xxxx` (CQ ring + weights)
- IRQ aggregator (NPU DONE/ERR → host)

### FSMs requiring explicit state + transition coverage

| FSM / sequencer | Location | Must-have transitions | Notes |
|-----------------|----------|----------------------|-------|
| **vexu VM_GRP / VMVR / SEGWR** | `cpu_m1` vector unit | Group iter, segment write, LMUL>1 body, `vstart` resume | Phase-B scope: m8, indexed, strided = excluded |
| **mat_engine S_*** | `design/npu/mat_engine` | Idle→CFG→LOAD→MAC→REQUANT→STORE→DONE; pipe stall; acc_clr | ADR-0053 2-stage requant pipe |
| **npu_dma** | `design/npu/npu_dma` | Idle→AR/R→AW/W→B; burst LEN; SLVERR abort; 2D/strided | Writeback + weight paths |
| **CQ sequencer** | `npu_top` | Ring consume; TAIL doorbell; FULL; ERR ladder; batch prefetch (ADR-0052) | Cross with direct CSR path |
| **npu_axil_regs** | CSR fabric | CTRL.start; soft_reset; STATUS/DONE; ERR_CAUSE | Hard-reset (ADR-0047) |
| **cpu_m1 fetch/decode** (NPU strip) | Sequencer | TCM fetch, run-to-completion, trap-to-host | No BP/RAS on NPU |
| **TCM arbiter** | `npu_tcm` | Core vs DMA vs AXI-lite | DMA-vs-core overlap (gate_30..34) |

**Nice-to-have FSM depth:** per-bank DTCM arbiter, individual AXI channel FSMs if not already hit by protocol covergroups.

### Gate mapping (proposed)

| Gate band | Content |
|-----------|---------|
| `gate_80` | V0 infra: coverage SSOT regen, exclusion ledger diff |
| `gate_81` | V1 ISA coverage thresholds per extension |
| `gate_82` | V2 Spyglass clean (lint + CDC/RDC) |
| `gate_83` | V3b integrated lockstep (directed + random) |
| `gate_84` | V4 functional UCDB thresholds |
| `gate_85` | V5 Verilator code cov (line/toggle) |
| `gate_86` | V6 VCS code cov signoff |
| `gate_87` | V7 dual-sim agreement |
| `gate_88` | V8 signoff package completeness |

(Adjust numbering to fit existing `gate_00..83` — these are illustrative.)

---

## 3. Instruction Coverage

### Source of truth

**Spike `--log-commits`** from all regression runs — not DUT disasm. Spike is the ISA golden already used for lockstep.

```
Inputs:
  phase_20_npu_core_lockstep/spike.log
  phase_21_cq/spike.log
  phase_22_vector_csr_lockstep/spike.log
  phase_23_mat_engine/spike.log
  tests/gates/* (any run producing spike logs)
```

### Tracker architecture

1. **ISA SSOT file** (`flow/coverage/isa_coverage.yaml`):
   - Extensions: `i`, `m`, `f`, `zba`, `zbb`, `zbs`, `zicond`, `zicsr`, `zve32x`, `zvl128b`
   - Per mnemonic: `ext`, `category`, `status`: `{covered | excluded | illegal-by-contract}`
   - Exclusion references ADR-0054 Phase-B/C/D/E scope cuts

2. **Parser** (`platform/lib/isa_cov.py`):
   - Ingest Spike commit log format
   - Normalize to `(pc, insn_hex, mnemonic, rd, rs1, rs2, …)`
   - Map via disasm table (capstone or Spike disasm export)
   - Bucket by extension using opcode/func7 rules

3. **Aggregation**:
   - Per-suite hit matrix
   - Union across full regression
   - **Per-extension mnemonic coverage %** = `covered_mnemonics / (total_in_scope - excluded)`

4. **Report** (`flow/coverage/isa_report.md` + JSON):
   ```
   Extension   In-scope  Excluded  Covered  %    Missing (top 10)
   zve32x      142       28        118      83%  vrgather_vv, ...
   f           45        0         44       98%  fclass_s
   ```

### Honest exclusion handling (critical)

Create **`isa_exclusions.yaml`** with three buckets:

| Bucket | Treatment in % | Example |
|--------|----------------|---------|
| **`excluded-scope-cut`** | Remove from denominator | strided/indexed/ff mem, `vrgatherei16`, masked reduction, m8 (until Phase-F) |
| **`excluded-illegal-npu`** | Remove from denominator | C extension on NPU (`EN_RVC=0`) |
| **`uncovered-in-scope`** | Counts against % | Everything else not hit |

**Rules:**
- Excluded ops **must** cite ADR section; gate fails if exclusion list shrinks without new coverage.
- Hitting an excluded op in a test → **warning**, not credit (prevents fake inflate via rogue firmware).
- **`vill`/illegal ladder** tests count as `zve32x` CSR coverage, not as executing excluded arithmetic ops.

### Must-have vs nice-to-have

| Must-have | Nice-to-have |
|-----------|--------------|
| 100% of in-scope RV32IMF + Zicsr used in production firmware paths | Every corner-case pseudo-op in Spike |
| ≥95% Zve32x Phase-A+B in-scope mnemonics | Full Phase-E/F mnemonics before RTL exists |
| Zero "uncovered" on trap/illegal/CSR ladder mnemonics | Exotic F rounding-mode combos not in TFLM |

---

## 4. Code Coverage

### Division of labor

| Metric | Verilator 5.046 | VCS X-2025.06 + urg |
|--------|-----------------|---------------------|
| Line | ✅ Nightly, in-sandbox | ✅ Signoff |
| Toggle | ✅ | ✅ |
| Expression | ✅ (`--coverage-expr`) | via cond |
| Condition | ❌ | ✅ |
| Branch | partial | ✅ |
| FSM | ❌ | ✅ |
| Covergroups | ❌ | ✅ (functional, not code) |

**Verilator = fast gap detection & CI.**  
**VCS = signoff authority for tape-out.**

### Merge / report flow

```
Verilator:
  make COV=1 → coverage.dat per test
  verilator_coverage --write merged.dat --read *.dat
  verilator_coverage --write-info merged.info
  → report: line%, toggle%, expr%

VCS:
  simv -cm line+cond+fsm+tgl+branch -cm_dir cov.vdb
  urg -dir cov.vdb -report urgReport/
  → signoff dashboard

Merge strategy:
  - Do NOT naively merge .dat + .vdb (different engines)
  - V7 produces DELTA report: same testlist, compare line hit sets
  - Discrepancies >2% line → triage before signoff
```

### Realistic targets (M3V honest)

| Metric | Verilator CI target | VCS signoff target | Waiver allowed? |
|--------|--------------------|--------------------|-----------------|
| Line (effective) | ≥90% | ≥95% | Yes, documented |
| Toggle | ≥80% | ≥85% | Yes, bus tie-offs |
| Branch/cond | — | ≥90% | Yes |
| FSM states | — | 100% reachable states | Yes, proven-dead |
| FSM transitions | — | ≥95% | Yes, with proof |

**Unreachable / dead code waiver policy:**
1. Static proof (Spyglass UNR/VCS unreachable) OR
2. Formal unreachable annotation + review OR
3. `// coverage off` only with ADR waiver ID — max 2% line budget per block

### Must-have vs nice-to-have

| Must-have | Nice-to-have |
|-----------|--------------|
| VCS line ≥95% effective on `npu_top` + `cpu_m1` | 100% line raw |
| FSM 100% reachable states on mat_engine, dma, CQ | Every vexu micro-state |
| Dual-sim line agreement ≥98% on shared testlist | Toggle 100% |

---

## 5. Functional Coverage — VPlan Sketch

VCS SV covergroups are **signoff** for functional crosses. Verilator pass uses **Python trace-based surrogate** for CI (not signoff).

### Python surrogate (in-sandbox)

Replay **RVVI-lite / commit trace** from phase_20/22 + AXI scoreboard logs:

```python
# platform/lib/func_cov.py
# Bins from trace tuples, not SV sampling
record("rvv_op", op, sew, lmul, masked, vl_bucket)
record("axi", channel, burst_len, resp, overlap)
```

**Limitation:** Cannot sample pre-commit internal FSM states without SV — acceptable for CI trend, not for signoff.

### Cross-coverage bins that matter

#### RVV (highest priority)

| Covergroup | Bins | Cross |
|------------|------|-------|
| `cg_rvv_op` | op_class: alu/mem/cmp/carry/narrow/widen/reduction | × |
| `cg_rvv_shape` | SEW: 8/16/32; LMUL: mf2,m1,m2,m4; vl: 0,1,vlmax-1,vlmax | `op × sew × lmul` |
| `cg_rvv_mask` | unmasked, masked-body, masked-dest, v0-policy | `× vl_edge` |
| `cg_rvv_csr` | vsetvli, vsetivli, vill, vstart≠0, vxsat set | × `op` |
| `cg_rvv_mem` | e8/e16/e32, unit-stride only | × `sew × lmul` |

**Exclude from crosses:** strided, indexed, ff, segment, m8 → mark `IGNORE_BIN`.

#### AXI

| Covergroup | Key bins |
|------------|----------|
| `cg_axi_dma` | AR/R burst LEN 0/1/15; AW/W; writeback; SLVERR; DECERR |
| `cg_axi_2d` | strided row; 2D tile (ADR-0043) |
| `cg_axi_overlap` | core-fetch + DMA same bank; W-before-AW violation guard |
| `cg_axi_lite` | CSR read/write; start pulse; reset during xfer |

#### mat_engine

| Covergroup | Cross |
|------------|-------|
| `cg_mat_cmd` | MAT.CFG, LOAD_W, OP, RESCALE, STORE, ACC_CLR, FENCE | × |
| `cg_mat_shape` | M/N/K edges; int8 overflow; acc saturation | |
| `cg_mat_requant` | scale/ZP modes; pipe stall (ADR-0053) | `cmd × requant_mode` |
| `cg_mat_tail` | non-multiple-of-8 tail | × `cmd` |

#### CQ

| Covergroup | Bins |
|------------|------|
| `cg_cq_ring` | empty, partial, full, wrap |
| `cg_cq_doorbell` | TAIL advance; batch prefetch (ADR-0052) |
| `cg_cq_err` | ERR ladder; RING_OVERRUN (host-side) |
| `cg_cq_equiv` | CQ path vs direct CSR same op |

#### Traps / reset

| Covergroup | Bins |
|------------|------|
| `cg_trap` | illegal insn, bus fault, NPU ERR_CAUSE, abort, soft_reset |
| `cg_reset` | hard_reset during MAC; during DMA; during CQ consume |

#### CSR matrix

| Covergroup | Bins |
|------------|------|
| `cg_csr_host` | mstatus.FS/VS, fcsr, satp (if applicable) |
| `cg_csr_npu` | CTRL, STATUS, ERR, vector CSR window 0x0002_xxxx |

### Functional coverage targets

| Covergroup family | Must-have | Nice-to-have |
|-------------------|-----------|--------------|
| RVV op×SEW×LMUL | ≥90% in-scope crosses | 100% |
| AXI protocol corners | 100% of defined bins | Exotic ID reuse |
| mat_engine cmd×requant | 100% | — |
| CQ ring/FULL/ERR | 100% | — |
| Trap causes | 100% of ADR-0038 ladder | — |

---

## 6. Green-Wash Guards (Coverage Campaign)

| # | Guard | Enforcement |
|---|-------|-------------|
| G1 | **Coverage ≠ correctness** | Gate requires lockstep green *before* coverage gate passes |
| G2 | **No toggle-only tests** | New tests must assert outcome (Spike diff, scoreboard, or golden); toggle bump alone rejected in review |
| G3 | **Raw vs effective** | All reports show both; signoff on effective only |
| G4 | **Justified waivers** | No waiver without ADR ID + owner + review; max budgets per block |
| G5 | **Dual-sim agreement** | V7 gate: same testlist, line-hit Jaccard ≥98%; list top 50 divergent files |
| G6 | **ISA exclusion drift** | `isa_exclusions.yaml` diff in CI; shrink → fail |
| G7 | **Excluded-op credit ban** | Hitting scope-cut mnemonic does not increment coverage |
| G8 | **No covergroup in TB-only** | Functional bins must sample DUT hierarchy, not TB wishbone |
| G9 | **Spike ISA lock** | ISA tracker `--isa` must match lockstep (`rv32imfc` host, `rv32imfc` + `zve32x_zvl128b` NPU) |
| G10 | **Honest not-run** | `flow/state/cpu_m3v_coverage.json` per phase; missing = red |
| G11 | **Regression union** | Coverage from full regression union, not single golden test |
| G12 | **Post-waiver review** | Gemini/Codex audit waivers quarterly |

---

## Signoff vs Nice-to-Have (Summary)

### Must-have for tape-out claim

1. All lockstep harnesses + integrated `soc_m3v_top` green
2. ISA coverage: 100% in-scope production mnemonics; exclusion ledger frozen
3. VCS line ≥95% effective, branch/cond ≥90%, FSM reachable-states 100%
4. Functional covergroups: mat_engine, CQ, AXI, trap ladders at 100% defined bins
5. RVV crosses ≥90% in-scope (Phase-A+B)
6. Spyglass lint/CDC/RDC clean
7. Dual-sim VCS↔Verilator line agreement ≥98%
8. Waiver package <5% line effective per top-level block

### Nice-to-have

- Verilator toggle ≥90%
- Python trace-based func cov at 100% (CI trend)
- 100% RVV cross product
- Phase-E/F ISA bins before RTL
- urg trend graphs over time

---

## Proposed ADR structure

| ADR | Title |
|-----|-------|
| **ADR-0055** | Full-circuit verification scope (`soc_m3v_top`, tiered DUT) |
| **ADR-0056** | ISA coverage methodology + exclusion ledger |
| **ADR-0057** | Code coverage signoff (VCS authority, Verilator CI, waiver policy) |
| **ADR-0058** | Functional coverage vplan + covergroup spec |
| **ADR-0059** | Coverage green-wash guards + dual-sim agreement |

---

## Suggested first 2 weeks (concrete)

| Day | Action |
|-----|--------|
| 1–2 | V0: `isa_coverage.yaml`, `isa_exclusions.yaml`, spike log ingester |
| 3 | V1: Run ingester on all 4 lockstep phases → first ISA gap report |
| 4–5 | V2: Spyglass rerun with M3V filelist |
| 6–10 | V3b: `soc_m3v_top` TB skeleton + 10 directed cross-domain tests |
| parallel | V5: Verilator `--coverage-line/-toggle` on existing phase_20 firmware |

This plan is honest about what existing assets buy you (Spike logs → cheap ISA cov; lockstep → correctness floor) and where real cost lands (integrated top, VCS covergroups, signoff waivers). Coverage proves you *looked everywhere*; lockstep proves you *got it right*.
