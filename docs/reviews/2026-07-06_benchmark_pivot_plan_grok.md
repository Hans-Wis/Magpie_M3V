# Magpie_M3V Benchmark Pivot — Architecture Plan (ADR + `/sim` Harness)

**Scope:** Functional verification of four benchmark families + honest performance-improvement analysis.  
**Authority:** Spike lockstep · bit-exact NumPy/BUILTIN_REF · AXI scoreboard.  
**Constraint:** No green-wash — `not-run` stays `not-run`.

---

## 0. Executive Summary

| Family | Runnable on RTL e2e **today** | Blocker | Functional proof class |
|--------|------------------------------|---------|------------------------|
| **MobileNet block** | ✅ Yes (`gate_82`, block-diagonal depthwise) | Full-network script + multi-layer harness | Bit-exact RTL vs BUILTIN_REF |
| **MLPerf AD (FC-AE)** | ✅ Mostly (FC stack) | `build_model` + weight layout script | Bit-exact RTL vs NumPy golden |
| **MLPerf KWS (DS-CNN)** | 🟡 Partial | Conv layers if stride-1 VALID; depthwise via block-diag; build script | Layer-wise bit-exact; e2e after script |
| **MLPerf VWW (MobileNetV1)** | 🔴 No | **Stride-2 depthwise** + padding | Needs RTL stride-2 im2col or SW workaround |
| **MLPerf IC (ResNet-8)** | 🔴 No | Stride-2 conv + **residual add** (no fused add op) | Stride-2 + scalar/vector add path |
| **Gemma-3 270M** | 🔴 No | **S0..S5 RTL slices** (ADR-0062 golden only) | Slice lockstep → tier assembly |
| **SmolLM2 135M** | 🔴 No | Same LLM stack; smaller = faster bring-up after Gemma path | Reuse Gemma S-slices |

**Build first for max signal:** `/sim` harness skeleton → MLPerf AD → KWS DS-CNN → wire existing MobileNet gate into harness → stride-2 gap analysis → LLM S0 (GeGLU int8 Tier-C already golden).

---

## 1. `/sim` Benchmark Harness — Structure

### 1.1 Directory & contract

```
flow/sim/
├── bench.yaml              # SSOT: model, phase, golden, pass criteria
├── run_bench.py            # unified entry: ./run_bench.py <bench_id> [--perf]
├── lib/
│   ├── golden.py           # NumPy / BUILTIN_REF loaders
│   ├── spike_lockstep.py   # thin wrapper → phase_20/22 flows
│   ├── cycle_probe.py      # perf counters from sim VCD/trace
│   └── report.py           # functional + perf JSON/MD
├── cnn/                    # TFLM mat_engine path
│   ├── mobilenet_block/
│   ├── mlperf_kws/
│   ├── mlperf_vww/
│   ├── mlperf_ic/
│   └── mlperf_ad/
└── llm/
    ├── gemma3_270m/        # S0..S5 slice firmware + golden
    └── smollm2_135m/       # defers to gemma slices where identical
```

**`bench.yaml` entry (per benchmark):**

```yaml
- id: mlperf_ad_fc_ae
  class: cnn_fc
  rtl_e2e: true          # honest flag
  firmware: cnn/mlperf_ad/firmware.S
  golden: cnn/mlperf_ad/golden.npz
  verify: bit_exact      # spike_lockstep | bit_exact | tolerance
  gates: [gate_48, gate_49]
  perf: {cycles: true, mac_util: true}
```

### 1.2 Runner phases (every bench)

```
┌─────────────┐   ┌──────────────┐   ┌─────────────┐   ┌──────────────┐
│ build_model │ → │ gen_firmware │ → │ verilator   │ → │ compare      │
│ (host Py)   │   │ + weights    │   │ + Spike LS  │   │ golden/report│
└─────────────┘   └──────────────┘   └─────────────┘   └──────────────┘
                                              │
                                    optional: cycle_probe (perf mode)
```

- **Functional mode (default):** Verilator DUT + Spike `--isa=rv32imfzve32x_zvl128b` lockstep on firmware; output tensors compared to golden (bit-exact int8, fp32 tolerance for LLM slices).
- **Perf mode (`--perf`):** Same firmware, no Spike; sample CSR/trace counters + `$finish` cycle count; emit `perf_report.json`.

### 1.3 Functional-correctness matrix (honest)

| Bench | RTL e2e | Golden today | Verify method | Pass criterion |
|-------|---------|--------------|---------------|----------------|
| TFLM FC/MLP | ✅ `gate_48/49` | BUILTIN_REF | Spike LS + tensor diff | int8 bit-exact |
| CNN conv+FC (stride-1 VALID) | ✅ `gate_50` | BUILTIN_REF | Spike LS + tensor diff | int8 bit-exact |
| MobileNet DW-sep block | ✅ `gate_82` | BUILTIN_REF | Spike LS + tensor diff | int8 bit-exact |
| MLPerf AD FC-AE | 🟡 FC layers only | NumPy (to build) | bit-exact per layer → e2e | int8 bit-exact e2e |
| MLPerf KWS DS-CNN | 🟡 layer-wise | NumPy (to build) | per-op golden | e2e after full script |
| MLPerf VWW MobileNetV1 | 🔴 | MLPerf ref (analysis) | — until stride-2 | `not-run` |
| MLPerf IC ResNet-8 | 🔴 | MLPerf ref (analysis) | — until stride-2 + residual | `not-run` |
| Gemma-3 decoder slice | 🔴 S0..S5 | ADR-0062 NumPy | slice LS when RTL lands | Tier-C int8 bit-exact per slice |
| SmolLM2 135M | 🔴 | reuse Gemma golden pattern | same | same |

**“Functional correct” definitions per class:**

| Class | Definition | Authority |
|-------|------------|-----------|
| **CNN int8** | Every layer output == golden byte-for-byte | Spike LS on firmware + NumPy/BUILTIN_REF |
| **CQ/DMA path** | Descriptor sequence + memory traffic scoreboard-clean | Existing `gate_35..39`, `gate_51` patterns |
| **LLM slice** | Subgraph (GeGLU, RMSNorm, QKV proj) bit-exact int8 Tier-C | NumPy golden (ADR-0062) + slice lockstep |
| **LLM e2e** | Token-step hidden state within Tier-C tolerance | Assembly of S0..S5 — **future** |
| **Analysis-only** | Shape/op graph validated; no RTL claim | Document only |

---

## 2. MLPerf Tiny — Minimal Path per Model

### 2.1 Shared existing assets

- **FC:** `gate_48/49` TFLM int8 FC path — direct.
- **Conv (VALID, stride-1):** `gate_50` im2col + mat_engine CQ.
- **Depthwise:** `gate_82` block-diagonal trick — works but **~1/8 MAC util** on depthwise geometry.
- **DMA:** 2D/strided host ABI (`gate_51`) — strided **DMA** exists; **conv im2col stride-2** does not.
- **Missing globally:** stride-2/padding conv im2col, fused residual add, avg-pool beyond Phase-A pool ops.

### 2.2 Per-model minimal path & effort rank

| Rank | Model | Ops profile | Minimal path | New work | Effort |
|------|-------|-------------|--------------|----------|--------|
| **1** | **AD / FC-autoencoder** | FC + (maybe 1 small conv) | `build_model.py` → CQ FC chain; weights @ 0x8000 | Script + golden only | **S** (1–2 d) |
| **2** | **KWS / DS-CNN** | DS-CNN: conv + depthwise + FC | Per-layer golden; DS conv stride-1 likely; depthwise via block-diag | `build_model`, multi-layer firmware, depthwise util audit | **M** (3–5 d) |
| **3** | **VWW / MobileNetV1** | Stride-2 depthwise + pointwise | Block-diag DW at stride-1 layers only first; **stride-2 DW is blocker** | **im2col stride-2** OR explicit im2col expand in SW (slow, not perf) | **L** (1–2 w) |
| **4** | **IC / ResNet-8** | Stride-2 conv + residual + FC | Stride-2 conv + **int8 residual add** (scalar RVV or host) | Stride-2 im2col + add kernel + shortcut tensor layout | **XL** (2–3 w) |

### 2.3 Stride-2 gap (arch decision needed)

**Option A — RTL im2col stride-2 (preferred for Coral parity):** Extend im2col in vexu/CQ LOAD path; VALID padding modes per TFLM. Touches `gate_50` contract.

**Option B — SW expand + stride-1 conv:** Functionally provable faster; **not** performance-representative; OK for functional-only milestone.

**Recommendation:** Option B for **first functional proof** on VWW/ResNet; Option A before perf signoff.

---

## 3. Performance Analysis Method

### 3.1 Cycle accounting (RTL)

Instrument `npu_top` sim with **non-invasive probes** (reuse trace/CSR debug from `gate_53/54`):

| Counter | Source | Meaning |
|---------|--------|---------|
| `cycles_total` | sim `$time` / retire count | Wall cycles |
| `mat_busy` | `mat_engine` FSM busy | MAC array active |
| `mat_stall` | CQ empty / DMA wait | Bubble cycles |
| `cq_dispatch` | CQ consumer commits | Descriptor overhead |
| `dma_rd` / `dma_wr` | `npu_dma` beat count | Memory bandwidth |
| `requant_active` | post-ADR-0053 pipe valid | Requant overlap (should be hidden) |
| `vexu_busy` | RVV op cycles | Activation / depthwise diag / LLM eltwise |

**Derived metrics:**

```
MAC_util     = MACs_executed / (cycles_total × 256)
CQ_overhead  = cq_dispatch_cycles / cycles_total
DMA_bound    = dma_stall_cycles / cycles_total
DW_waste     = 1 - (effective_DW_MACs / mat_busy_MACs)   # block-diag penalty
```

### 3.2 Bottleneck levers — ROI ranking

| Lever | Status | CNN impact | LLM impact | Est. speedup | ROI |
|-------|--------|------------|------------|--------------|-----|
| **Dedicated depthwise / 1×1 fast path** | Not done | **High** (MobileNet, VWW, KWS) | Low | 2–8× on DW layers | **#1 CNN** |
| **Stride-2 im2col (hardware)** | Not done | **High** (VWW, ResNet) | Low | Enables + removes SW expand | **#2 CNN** |
| **Activation: LUT vs polynomial** | Polynomial today | Medium (every layer) | **High** (GeGLU, GELU) | 1.5–3× on act-bound slices | **#1 LLM** |
| **LLM weight streaming / double-buffer** | Scope-cut | Low | **Critical** | 2–5× on memory-bound proj | **#2 LLM** |
| **CQ batching** | ✅ ADR-0052 | Low (already batched) | Medium | 10–20% | Done |
| **Requant pipe** | ✅ ADR-0053 | Low (hidden) | Low | — | Done |
| **S_RUN sequencer pipe** | Standby ADR | Low | Medium (long FC chains) | 10–15% | **#3 both** |
| **Residual add fusion** | Not done | ResNet only | Low | 1.1× | Niche |

### 3.3 Benchmark-class bottleneck map

```
CNN (MLPerf, MobileNet):
  Dominant → depthwise MAC waste (block-diag) → stride-2 gap → DMA input staging
  Secondary → activation polynomial latency → CQ (mostly solved)

LLM (Gemma, SmolLM2):
  Dominant → weight streaming bandwidth (270M/135M params)
  Secondary → GeGLU activation + RMSNorm (vexu/scalar-F)
  Tertiary → FC mat_util (should be good if CQ batch + 256 MAC/cyc)
```

**Perf analysis deliverable:** Per-bench `perf_report.json` + `docs/reports/perf_<bench>_<date>.md` with MAC_util, top-3 stall reasons, and lever sensitivity (analytical, pre-RTL for blocked benches).

---

## 4. Sequencing — Must-Have vs Optimization

### Phase F1 — Functional proof (must-have)

| Step | Deliverable | Signal |
|------|-------------|--------|
| **F1.0** | `/sim` harness + `bench.yaml` SSOT + `run_bench.py` | All future benches plug in one way |
| **F1.1** | MLPerf **AD** e2e bit-exact | Proves FC chain at scale |
| **F1.2** | Port **MobileNet block** (`gate_82`) into `/sim` | Proves DS-CNN-class depthwise functional |
| **F1.3** | MLPerf **KWS DS-CNN** layer-wise → e2e | First full MLPerf model green |
| **F1.4** | Stride-2 **functional** (SW expand path) for VWW + ResNet | Honest functional matrix expansion |
| **F1.5** | LLM **S0** (int8 GeGLU Tier-C) RTL slice + lockstep | Proves LLM datapath |
| **F1.6** | Gemma-3 S1..S5 slices → SmolLM2 reuse | Full LLM slice coverage |

**Exit criteria F1:** 4 benchmark families have at least one **bit-exact RTL** proof point; MLPerf 4/4 e2e functional (stride-2 may be SW path); LLM at least S0+one projection slice lockstep.

### Phase P1 — Performance analysis (parallel after F1.1)

| Step | Deliverable |
|------|-------------|
| **P1.0** | `cycle_probe.py` + CSR counter spec in ADR |
| **P1.1** | Perf reports for AD, KWS, MobileNet (RTL-runnable) |
| **P1.2** | Analytical model for Gemma/SmolLM2 (weight bytes/cycle budget) |
| **P1.3** | ROI-ranked improvement backlog with per-bench sensitivity |

### Phase P2 — Perf optimization (after functional matrix green)

Only after F1 functional matrix is honest-green:

1. Native depthwise MAC path (biggest CNN ROI)
2. Hardware stride-2 im2col
3. LLM activation LUT + weight double-buffer
4. S_RUN pipe (if CQ/sequencer shows in P1 reports)

---

## 5. ADR Skeleton (→ `docs/adr/0063-benchmark-harness-and-perf-pivot.md`)

**Title:** Benchmark Harness (`/sim`) + Functional Verification & Performance Analysis Pivot

**Context:** User directive 2026-07-06 — pivot from Zve32x feature completion to benchmark-functional proof + perf ROI.

**Decision:**
1. Unified `/sim` runner with `bench.yaml` SSOT.
2. Functional authority unchanged: Spike lockstep + bit-exact golden; `not-run` for blocked models.
3. MLPerf order: AD → KWS → VWW → ResNet; stride-2 functional via SW expand first.
4. LLM via ADR-0062 S0..S5 slices; SmolLM2 reuses Gemma slice infra.
5. Perf counters + MAC_util reports mandatory for RTL-runnable benches; analytical-only for blocked.
6. Optimization deferred until F1 exit; depthwise native path is CNN ROI #1, LLM weight streaming is LLM ROI #1.

**Consequences:** New `flow/sim/` tree; new gates `gate_82_sim` (harness integration), `gate_83..86` (MLPerf per model), `gate_87..92` (LLM slices). Coverage freeze stands; benchmark firmware adds line cov opportunistically.

---

## 6. Honest Bottom Line

**Runnable today on RTL e2e:** MobileNet DW-sep block, TFLM FC/MLP, stride-1 VALID CNN — enough for **MLPerf AD** and most of **KWS DS-CNN** with scripts only.

**Not runnable without new RTL or substantial firmware:** VWW stride-2 depthwise, ResNet-8 residuals, full Gemma/SmolLM2 (S-slices).

**Max signal first week:** `/sim` harness + MLPerf AD + KWS + MobileNet in harness → functional matrix goes from 3 gates to **5+ e2e benches** with minimal RTL risk; perf probes on those three give real MAC_util data to justify depthwise vs LLM streaming investments.

I can turn this into the full ADR-0063 markdown and a stub `flow/sim/bench.yaml` when you want implementation — say the word.
