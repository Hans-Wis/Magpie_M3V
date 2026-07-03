# ADR-0031 — Magpie_M3V scope: two-core SoC (frozen cpu_m1 host --AXI--> cpu_m1-derived NPU core)

- Status: **PROPOSED** (draft — awaiting User acceptance; producer≠approver)
- Date: 2026-07-03
- Deciders: User (directive — architecture fixed by User), PL (Claude)
- Line: Magpie_M3V (`design_id = cpu_m3v`), full-history fork of Magpie_M1A @ `m1a-rtl-freeze-v1.0` (SHA 51a6fe0)
- Relates: `docs/reports/m1a_performance_evaluation.md` route #5 (loosely-coupled NPU), but companion is self-built from our own scalar; sibling of Magpie_M1V ADR-0030 (CoralNPU IMPORT, *different* route)

## Context

Goal: grow the M1A RV32 scalar core into **"Google CoralNPU-class" edge-ML capability**
(competitor bar = Cortex-M55 + Ethos-U55). Three strategy routes were ranked (Grok + the M1A
performance evaluation report, independently concordant):

1. **HYBRID** — M1A frozen scalar as *host* + net-new *tightly-coupled* int8/int4 GEMV unit
   driven by custom-0 instructions. Single-core per-commit Spike lockstep preserved. ✅ top rank.
2. **BUILD** — from-scratch full RVV Zve32x + matrix. Highest ownership, multi-year verification;
   right as a *later* evolution (Phase 5), not the day-one fork.
3. **IMPORT** — pair with imported CoralNPU core (Apache-2.0). Fastest demo, worst for owned-IP
   flow (inherit a 2nd RISC-V core, lockstep drops to system boundary). **This is the existing
   Magpie_M1V line** — M3V deliberately does *not* duplicate it.

Honest physics (report §3): edge-LLM (batch-1 GEMV) is **bandwidth-bound, not MAC-bound**.
tokens/s ≈ weight-stream BW ÷ model size. → **memory-system-first**, then a right-sized MAC array.

## Decision

Adopt a **two-core SoC** for Magpie_M3V: **main CPU `cpu_m1` (frozen) --AXI--> NPU core
(cpu_m1-derived, modified)**. Loosely-coupled companion accelerator (CoralNPU SoC shape), built
from our own scalar rather than imported.

- **Main CPU = frozen M1A scalar.** `IP/cpu_m1/rtl/` stays **byte-identical** to the freeze tag; it
  is the control CPU that orchestrates the NPU. Re-verified as a no-regression guard, never
  re-claimed. It already exposes an **AXI4-Lite master** (`cpu_m1_axil_top.v` + `axil_bridge.v`,
  vcformal-checked) → the control plane to the NPU exists out of the box.
- **NPU core = a COPY of the cpu_m1 scalar RTL, MODIFIED.** The copy lives under `IP/npu/` (frozen
  core untouched → freeze not violated) and gains: vector/GEMV/matrix EXU, local ITCM/DTCM +
  128-bit data path, an **AXI slave** (host control/CSR + local-mem window) and an **AXI master**
  (weight/activation DMA). The reused scalar spine is the NPU's control/sequencer; the ML datapath
  is net-new. CoralNPU is reference-only for microarch shapes + SW API, not an RTL graft.
- **AXI fabric (net-new bus work).** Interconnect + address decode; **AXI4-Lite for control**,
  **AXI4-full + DMA for the data path** (current bus is AXI4-Lite only — 32-bit, no burst — enough
  for control, not for weight streaming). Bandwidth-first per the roofline (report §3).
- **Verification authority = SPLIT (route #5, honest deviation).** Host cpu_m1 stays per-commit
  Spike lockstep. The NPU **scalar spine is still Spike-lockstep-able** (it is cpu_m1-derived — an
  advantage over the M1V imported-core route where the OoO core cannot be per-commit lockstep'd).
  The NPU **vector extension** reuses the **RVV Zve32x vector-retire equivalence** methodology
  (M1V ADR-0028 is directly reusable as reference); the GEMV/matrix engine gets a bit-accurate C
  golden model. The boundary gets an AXI transaction scoreboard; the system gets ML e2e. This split
  is documented as a methodology deviation in the SKU contract.

### ISA contract = CoralNPU parity (User directive 2026-07-03: match Google NPU first)

- **NPU target ISA = `RV32IMF_Zve32x_Zicsr_Zifencei_Zbb`, VLEN=128** — byte-for-byte the CoralNPU
  datasheet string, so the software contract matches. Delta vs the cpu_m1-derived spine: **add F
  (FPU) + Zve32x (vector)**; **C is dropped/optional** (CoralNPU has no compressed; the toolchain
  won't emit it — keeping cpu_m1's C is a harmless superset, not required for parity).
- **Config parity**: ITCM 8 KB / DTCM 32 KB, AXI4 master+slave (matches datasheet), GEMV/matrix
  array **64 MAC first → path to 256** (256 = the datasheet matrix engine).
- **Toolchain-first (the "make Google's toolchain apply" goal — HONEST scope).** Google's real
  `coral-opt` (MLIR) + CoralNPU IREE runtime are **closed-source / commercial (Synaptics Torq) and
  unavailable here** — M1V already hit this and wrote a stand-in `m1v-coral-opt`. What actually
  "applies" once the ISA matches is the **standard OPEN RVV toolchain**: upstream
  `clang -march=rv32imf_zve32x_zbb` + RVV intrinsics + TFLM (open), plus M1V's stand-in
  StableHLO→RV32 emitter as reference. Matching the ISA buys the open toolchain, **not** Google's
  proprietary compiler — and that is the more robust position (no closed-tool dependency).
- **Golden = Spike ISS** with `--isa rv32imf_zve32x` (Spike accepts `zve32x` locally, report §1) —
  the toolchain is stood up + proven on the ISS **before** RTL, then RTL is verified against it.
- **256-MAC matrix caveat**: the dedicated matrix engine is **NOT in the open CoralNPU emit**
  (separate config, no open RTL reference); Zve32x VLEN=128 alone ≈ 8 int8 MAC/c. The 64→256 GEMV
  array is therefore genuinely net-new, not a port.

## Phased plan (gate per phase; ADR → gate_map → green → record_step)

**Contract/toolchain-first**: prove the ISA + open toolchain on the Spike ISS *before* building RTL,
then build RTL to that frozen contract.

| Phase | Deliverable | Exit gate |
|---|---|---|
| **0** | **Lock CoralNPU-parity contract**: ISA `RV32IMF_Zve32x_Zbb` VLEN=128 + ABI + memory map (ITCM/DTCM, AXI4, host↔NPU CSR/IRQ). Stand up the **open toolchain against Spike ISS**: `clang -march=rv32imf_zve32x_zbb` + RVV kernel + TFLM compile & run on `spike --isa rv32imf_zve32x`; adapt M1V stand-in emitter. Host benchmark baseline + GEMV roofline. | **A vector kernel + a TFLM op run on Spike ISS** (toolchain "applies" proven); contract doc + numbers recorded; ADR-0031 accepted |
| **1** | **AXI fabric**: interconnect + addr decode + AXI4-full + DMA double-buffer (host AXI4-Lite control reused, already vcformal-checked) | `gate_20_axi_fabric` transaction scoreboard + host scalar no-regress |
| **2** | **NPU scalar spine**: copy cpu_m1 → add **F (FPU)**, drop/keep C, wrap with AXI slave/master + local ITCM/DTCM; boots + runs scalar kernels standalone | `gate_30_npu_scalar_lockstep` (NPU scalar+F vs Spike) |
| **3** | **RVV Zve32x EXU** (VLEN=128, integer EEW≤32) on the NPU core — the ISA-parity vector unit | `gate_40_npu_rvv_cosim` (RVV vector-retire equivalence, reuse M1V ADR-0028 methodology) + functional coverage |
| **4** | **GEMV/matrix engine** (int8/int4, **64 MAC → path to 256**) driven from RVV/kernels | `gate_45_gemv_cosim` (bit-accurate C golden) + roofline |
| **5** | **Two-core ML e2e**: host orchestrates NPU over AXI; TFLM / int4 GEMV tinyLLM demo via the open toolchain | `gate_50_two_core_ml_e2e` named-workload roofline numbers |
| **6** | Signoff: Spyglass lint + DC PPA trial (2-core); M55+U55 competitive scorecard | lint/PPA gates (OUTSIDE-SANDBOX) |

## Consequences

- **+** Freeze intact (host + NPU-copy both leave `IP/cpu_m1/rtl/` untouched); CoralNPU SoC shape
  with a **fully-owned, Spike-lockstep-able** scalar on BOTH cores (M1V's imported core cannot claim
  this); host control plane (AXI-Lite) already exists + formal-checked.
- **+** Evidence hard-isolated from M1A/M1/M1V; M3V re-earns all gates (`gate_00_identity_m3v`).
- **−** **Split verification authority** — no longer one unified per-commit lockstep; boundary +
  vector golden model are new surfaces (report §5 flagged this as the route-#5 cost).
- **−** **Two scalar bloodlines to maintain** (frozen host + modified NPU copy diverge).
- **−** AXI4-full + DMA fabric is real net-new bus work; NPU-class throughput comes from the vector
  array + bandwidth, **not** from the reused 4-stage scalar (don't expect NPU perf from the copy).

## Decisions locked by User (2026-07-03)

- ✅ **NPU = programmable RISC-V + vector core** running ML kernels (CoralNPU model).
- ✅ **Vector ISA = standard RVV Zve32x** (VLEN=128) — not custom-0.
- ✅ **CoralNPU-parity first**: match ISA `RV32IMF_Zve32x_Zbb` so the (open) toolchain applies.
- ✅ **GEMV array 64 MAC first → 256** (256 = CoralNPU datasheet matrix engine).
- ✅ **FPU deferred**: **integer-only first** — Phase 0 contract = **`rv32im_zve32x_zicsr_zifencei_zbb`**
  (no scalar F; Zve32x is integer-EEW≤32 vector, so no vector float either). Scalar F is added in a
  later phase to reach full `rv32imf_...` CoralNPU parity. Phase 0 kernels/TFLM must be int-only
  (int8/int16 — the edge-ML path anyway). This also sidesteps CoralNPU's upstream no-float emit bug.

## Open items (remaining, for User before acceptance)

1. Line name **Magpie_M3V** confirmed? (fork done at `~/project/SOC/Magpie_M3V`, `design_id=cpu_m3v`.)
2. **Governance framing**: keep the M1A "AI-design-flow / IP demo" north-star, or pure-engineering
   line like M1V? (affects whether IDE/flow evidence is a deliverable.)
