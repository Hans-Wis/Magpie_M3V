# M3V design-completeness gap review vs Google Coral NPU (2026-07-03)

Reviewers: **Grok** (architecture completeness) + **Codex** (grounded repo audit, file:line). Gemini
blocked (no `GEMINI_API_KEY`). Basis: built state @ HEAD 210a1e8 (Phase 0+1+1.5 + Phase 2 Step 2) vs
Coral (Kelvin) reference. Both reviewers concurred on the P0 list.

## A. Real omissions — DESIGN NOW (P0)

| # | gap | Coral has | our status | close with |
|---|---|---|---|---|
| 1 | **Result writeback DMA** | NPU DMAs results→shared mem before IRQ | `npu_dma` is READ-only (AR/R); `npu_top` exposes no AW/W/B write master | add AXI4 write channel to npu_dma/npu_top + result SRC/DST/LEN (or CQ descriptor) + BRESP handling before DONE. **The read-only DMA makes the Coral loop impossible — highest-impact gap.** |
| 2 | **Command-queue contract** | scalar → ring CQ → RVV+matrix; doorbell points at cmd buffer | CSR doorbell + DMA SRC/DST/LEN/GO only; CQ is "planned Phase 4", no schema | freeze CQ SSOT (descriptor layout) + ring base/head/tail/depth CSRs + FULL/DONE/ERR; the shared contract for host-fw/DMA/matrix |
| 3 | **Matrix accumulator + requant** | 256-MAC int8→int32, 8×8×32b accumulator, scale/zero-point/requant | "64→256 MAC" named; no acc width / saturation / requant / per-channel scale spec | matrix EXU spec: acc RF, int8→int32, requant-to-int8 (scale+ZP) + NumPy golden — without this it is a MAC array with no inference semantics |
| 4 | **RVV vector CSR lockstep** | vtype/vl/vstart/vxsat + vector traps | contract names Zve32x/VLEN only; vector CSRs not in the lockstep/trace contract | extend Spike trace + gate for scalar+vector CSR parity BEFORE any RVV EXU RTL (else the EXU diverges silently from the only golden) |
| 5 | **Compute-done + error IRQ / control** | doorbell→compute→writeback→IRQ; completion+fault flow | only `dma_done`; STATUS lacks FULL/ERR-cause; `CTRL[2]=soft_reset` documented but NOT wired; no abort | wire real `soft_reset` + `CTRL.abort` (DMA drain / matrix idle) + `STATUS.full/err/cause` + NPU-fault→IRQ |

## B. Real omissions — P1 (design before their phase)

| gap | note |
|---|---|
| **NPU traps/exceptions** | stripped sequencer still needs illegal/misalign/ecall; no NPU trap-to-host `ERR_CAUSE` interface yet |
| **Job abort / soft-reset wired** | see A5 |
| **Host cache coherency** | non-coherent AXI: host must flush/invalidate before doorbell — undocumented protocol |
| **TCM sizing / ITCM|DTCM split / 128-bit** | contract says 8K/32K + 128-bit; RTL is a single `TCM_WORDS=1024` 32-bit sim TCM |
| **2D / strided / scatter-gather DMA** | contiguous INCR only — fine for GEMV, real gap for general TFLM conv/depthwise strides |
| **RVVI/RVFI trace ports** | plan claims them; NPU RTL has none — needed before a "verified NPU" claim |
| **AXI QoS / outstanding limits** on the NPU master | unspecified |
| **weight + bias descriptors** | Coral fuses both; we chunk weights only |

## C. Deliberate scope-cuts (documented, acceptable for v1)

double-buffer / multi-outstanding DMA · scalar F (int8-first; revisit if TFLM needs in-core
dequant/softmax) · L0 I-cache (TCM-only) · clock/power gating (physical phase) · closed coral-opt/IREE
(open RVV instead, ADR-0031).

## D. Honesty gaps — docs overclaim vs RTL (FIX NOW)

1. `rv32_npu_design_plan.html` (v0.1) presents writeback DMA, CQ-driven compute, RVVI/RVFI, IREE-plugin
   flow, and clock/power gating as architectural FACTS — none are in RTL. → add a "built vs aspirational"
   banner + point to this review (done).
2. **Memory-map conflict**: plan says `NPU_CSR@0x4000_0000`; built/spec is `0x3000/0x3001`. → plan banner.
3. `design/npu/ip.json` **stale**: NPU `status:"not-started"` and "frozen cpu_m1 never touched" — both now
   false (Phase 1/1.5 RTL exists; Phase 2 params landed). → update (done).
4. `design/npu/docs/01_axi_fabric_spec.md` §4 still lists "wstrb ignored" as a limitation — contradicted by
   the Phase 1.5 byte-merge fix in §7. → correct (done).
5. ADR-0032 Step 2 prose mentions `FETCH_SRC` while Step 2 RTL added only `EN_RVC/EN_BP/EN_RAS`
   (FETCH_SRC is correctly Step 4). → clarified.

## E. Roadmap impact (fold into ADR-0031/0032)

- **Move Result-writeback DMA EARLY** (it is symmetric to the read DMA already built — do it as a
  Phase 1 extension, not late). Pairs with the CQ descriptor.
- **CQ SSOT + DONE/ERR/FULL/abort** become a near-term contract deliverable (before matrix RTL).
- **RVV vector-CSR lockstep contract** is a hard precondition for Phase 3 (Grok + Codex agree).
- **Matrix accumulator/requant/quant** must be specified with the engine, not after.
- Bump TCM to realistic ITCM/DTCM sizes when the NPU core lands (Phase 2 Step 4).

**Bottom line (both reviewers):** the three blind spots to design for NOW, or pay later — (1)
**bidirectional DMA + command-queue SSOT** (without them the Coral offload loop can't exist), (2)
**matrix accumulator + requant semantics** (without them 256 MACs have no inference meaning or golden),
(3) **RVV vector-CSR lockstep boundary** (without it the vector EXU has no authoritative reference).
