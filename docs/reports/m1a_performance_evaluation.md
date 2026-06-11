# Magpie_M1A — Performance Upgrade Evaluation (vs ARM Cortex-M55, DSP + edge-LLM)

Rev 1.0 · 2026-06-11 · Owner: PL (Claude) · Advisor: Grok (web-confirmed M55/U55 specs) · design_id = `cpu_m1`
Status: **EVALUATION** — no ADR opened yet; this informs the M1A direction decision.
Authority unchanged: Spike per-commit lockstep + pytest gates (extension strategy per §5 below).

## 1. Baseline facts (measured / verified)

| item | Magpie_M1 today |
|---|---|
| µarch | 4-stage in-order **single-issue**, BP (64-entry 2-way BTB) + RAS(8), RV32C cross-boundary prefetch |
| MUL / DIV | mul **2-cycle**, div **32-cycle** iterative |
| PPA | **699 MHz / 26298 µm² / 15.85 mW** (TSMC28HPC+ DC compile_ultra trial, SLOW WNS 0.00) |
| CoreMark / DMIPS | **NOT MEASURED** — first gap before any "beats M55" claim |
| Verification asset | Spike per-commit lockstep methodology (105k+ commits 0-div) + 309-gate xfail-free suite |
| Spike local capability | accepts `rv32imcv` / `zve32x` (RVV 1.0) and `rv32imcp` (P-ext) — both DSP routes lockstep-viable |

## 2. The bar: Cortex-M55 (ARM-published, Grok web-confirmed)

| domain | M55 number to beat |
|---|---|
| Scalar | **4.2 CoreMark/MHz**, 1.6 DMIPS/MHz; typical 28 nm implementation ≤ ~400 MHz |
| DSP (Helium MVE) | **8 int8 / 4 int16 / 2 int32 MACs/cycle**, 2 fp32 / 4 fp16 per cycle (128-bit vector, dual-beat) → ~3.2 int8 GOPS CPU-only @400 MHz |
| ML (the real competitor) | M55 **+ Ethos-U55 NPU**: 32–256 MAC/cycle configs → ~26–205 GOPS @400 MHz (64–512 @1 GHz) |

Implication: "超越 M55 含 LLM 加速" 實質上是對標 **M55+U55 組合**,不是 M55 單核。

## 3. Honest physics: edge-LLM is BANDWIDTH-bound, not MAC-bound

Batch-1 LLM inference = GEMV; every int8/int4 MAC consumes ~1 weight byte. tokens/s ≈ weight-stream
bandwidth ÷ model size. A 128-MAC array @700 MHz (≈180 GOPS) is wasted if weights stream at
100 MB/s octal-SPI (→ ~2 tok/s on a 50 MB model). The winning design is **memory-system-first**
(TCM + wide bus + DMA double-buffer + on-chip weight residency for tinyLLM), then a right-sized GEMV
engine. Stacking MACs beyond the bandwidth roofline is a marketing number, not performance.

## 4. Ranked M1A roadmap (Grok-ranked, PL-integrated)

| # | lever | gain | cost/risk | lockstep impact |
|---|---|---|---|---|
| 0 | **Benchmark baseline first**: CoreMark/DMIPS @699 MHz, µRISCV-NN int8 kernels, TFLM micro_speech, GEMV roofline (GB/s vs MAC/s) | the license to make any claim | trivial (AI-doable now) | n/a |
| 1 | **Memory system**: dual-port TCM + 128-bit data path + stream prefetch/DMA | unlocks GEMV BW; ~2× on mem-bound ML; benefits everything later | medium RTL; mem-model gates | ✅ unchanged |
| 2 | **Scalar uplift**: Zba/Zbb/Zbs + Zicond, **1-cycle MUL**, div early-exit, BTB/RAS tuning | +15–25% CoreMark/MHz (est. ~3.0→~3.5); with 699 vs 400 MHz freq edge → absolute CoreMark parity/win plausible | low–medium; new ISA gates + riscv-dv | ✅ native Spike |
| 3 | **DSP = RVV 1.0 Zve32x, VLEN=128** (dual-beat 64-bit datapath, M55-style) — **not P-ext** | matches/beats Helium 8 int8 MAC/c; TFLM + µRISCV-NN software path | high: vector EXU + hazards + compiler | 🟡 Spike has RVV; needs **vector-retire equivalence** (vreg/vcsr compare), ADR for lockstep extension |
| 4 | **Tightly-coupled int8/int4 GEMV unit** (64–128 MAC, custom instrs) | ~25–50+ GOPS @500–700 MHz; the edge-LLM workhorse | med-high; custom decode | 🟡 Spike `--extension` plugin; lockstep at dispatch/retire contract |
| 5 | **Loosely-coupled NPU** (Ethos-U55-like, 256 MAC) — optional SKU | 128+ GOPS; only path to beat U55-256 configs | high area/power; DMA/ABI | ❌ breaks unified per-commit → CPU-lockstep + NPU bit-accurate model + boundary cosim |
| 6 | **Dual-issue** | +10–15% scalar (per-MHz parity with 4.2 likely needs this) | high on a 4-stage; flush/BP risk; full regression | ✅ but costly |

**P-extension: rejected** — Spike accepts it locally, but ecosystem (toolchain/TFLM/kernels) is frozen
vs RVV; weak long-term story. RVV Zve32x is the strategic DSP route.

## 5. Verification strategy (the moat)

M1's differentiator is the lockstep methodology. Extension plan:
- Zb*/Zicond/1-cyc-MUL/TCM: same PC/GPR/CSR retire compare, riscv-dv regen — **no methodology change**.
- RVV: ADR for **vector retire equivalence** (vregs + vcsr + saturation flags vs Spike) — engineering, not research.
- Custom GEMV instrs: Spike plugin = golden functional model at commit boundary.
- NPU (if SKU'd): split authority — CPU stays per-commit; NPU gets bit-accurate C model + transaction
  scoreboard + DMA system tests. Document as methodology deviation in the SKU contract.

## 6. Defensible positioning (today vs after)

- **Today (honest)**: "Open RV32IMC MCU core, production-grade Spike per-commit signoff, 699 MHz DC
  trial on TSMC28HPC+ — not yet benchmark-ranked vs Cortex-M."
- **After #0–#2**: absolute-CoreMark comparison vs M55@28nm (frequency edge 699 vs ~400 MHz).
- **After #3**: named-workload DSP wins (µRISCV-NN vs CMSIS-NN kernels).
- **After #4 (+#1)**: edge-tinyLLM tokens/s on named models (e.g., int4 ≤100 MB) with roofline math shown.
- "Beats M55" must always be **workload-named and benchmark-backed** — per-MHz scalar parity with 4.2
  CoreMark/MHz likely needs dual-issue (#6); the freq + vector + GEMV route wins at workload level first.

## 7. Suggested phasing (if M1A is greenlit)

- **Phase 0 (days)**: benchmarks on M1 (#0) → ADR-0026 "M1A scope" with real numbers.
- **Phase A (weeks)**: #1 memory + #2 scalar → re-run DC trial + benchmarks.
- **Phase B**: #3 RVV Zve32x + vector lockstep ADR.
- **Phase C**: #4 TC-GEMV + tinyLLM demo (TFLM / llama.c-class int4 GEMV).
- **Phase D (optional SKU-3)**: #5 NPU companion.

Every phase keeps the IP-flow discipline: ADR → ip.json gate_map regen → gates green → record_step.
