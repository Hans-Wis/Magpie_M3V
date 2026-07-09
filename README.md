# Edge-AI Processor - RISC-V CPU with Vector-Engin & Matrix-Engine 

**Magpie_M3V** is a synthesizable two-core RISC-V SoC: a host CPU (`cpu_m1`) driving, over AXI, a
self-built **NPU domain** whose goal is to *functionally replace* the Google Coral NPU —
run the same open-source int8 TFLM inference path (RVV Zve32x + a 256-MAC matrix engine) with
bit-exact results, verified against the Spike ISS by per-commit lockstep.

> This line is **clean-room / self-built** (not an import). Correctness authority is the project's
> own **Spike lockstep + bit-accurate golden + scoreboards** — not "looks right" or a passing lint.

## Architecture

**Two-core SoC** — host `cpu_m1` (M1A) `--AXI-->` the NPU domain (scalar / vector / matrix engines,
TCM, DMA, command-queue), plus PLIC / shared memory / peripherals over a shared AXI4 fabric:

![Magpie-M3V two-core SoC top-level architecture — NPU domain (scalar RV32IMF core, RVV vector engine, 256-MAC matrix engine, ITCM/DTCM, DMA) and host cpu_m1 / PLIC / shared memory / peripherals on a shared AXI4 fabric](docs/img/soc_toplevel.svg)

**Target bus architecture — two-AXI + bridge (bandwidth scales with the SKU).** A narrow control
AXI (32/64-bit: config CSR, doorbell, TCM load) plus a wide data AXI (64/128/256-bit) whose width
tracks the MAC-array `LANES` SKU (256 MAC → 256-bit, matched to the MAC consumption rate), joined by
a bridge — attacking the DMA bottleneck (ADR-0068 §2.5):

![Target two-AXI architecture — narrow control AXI (32/64-bit) + wide data AXI (64/128/256-bit, width = LANES SKU) + bridge; the data-domain width scales with the MAC array to match bandwidth](docs/img/two_axi_bridge.svg)

**Pipeline & memory hierarchy**

![Four-stage single-issue in-order pipeline — FETCH (ITCM read, branch predict) / DECODE-ISSUE (hazard detect + forwarding) / EX (scalar · vector vexu · load-store units) / WB](docs/img/pipeline.svg)

![Memory hierarchy — ITCM 8KB / DTCM 32KB single-cycle SRAM; out-of-TCM accesses go EBUS → AXI4 external memory](docs/img/memory.svg)

*Diagrams from [`docs/Magpie-M3V-RV_NPU_Design_Spec.html`](docs/Magpie-M3V-RV_NPU_Design_Spec.html) (§3 top-level & bus topology, §4 pipeline, §8 memory).*

### How the three engines divide the work

The NPU runs one inference across **three engines**, and the split is decided by a single
mechanical criterion — *does the op accumulate along a **contraction axis** (a dimension that is
summed away and vanishes from the output)?* The compiler backend (MLIR `linalg` parallel-vs-reduction
dims) assigns each op at lowering time; the developer never hand-partitions.

| Engine | Role | Work | ISA / interface |
|---|---|---|---|
| **Scalar** (control) | only touches **addresses** | loops · addr-gen · branches · issue commands · sync | standard **RV32IM(F)** |
| **Vector** (element-wise) | touches **data**, no axis vanishes | activation · bias · requantize · pooling (relu/add/rescale/pool) | standard **RVV Zve32x** |
| **Matrix** (accumulate along axis) | a **contraction axis** is summed away | matmul · conv · QKᵀ | custom **command** (not ISA) |

`C[i,j] = Σₖ A[i,k]·B[k,j]` — the `k` dimension exists in the inputs but disappears in `C`; that is
the contraction axis, and "accumulate along it" is exactly MAC (multiply-accumulate, accumulator
never cleared) → it needs the **matrix engine's accumulator array**. Element-wise ops (e.g. ReLU:
input shape = output shape, nothing vanishes) need no accumulator → the **vector engine**. This
"does it converge onto one accumulator?" test is what draws the scalar/vector/matrix boundary.
### Worked example — running a CNN front-end

`image → conv → +bias → ReLU → maxpool`. Which engine each stage lands on is decided by the
contraction-axis test above — only the convolution accumulates along an axis.

![CNN front-end dataflow — input image H×W×C int8 → Conv 3×3 (Σ over c·kh·kw → int32) on the Matrix engine → bias/rescale/ReLU on the Vector engine → pooling, with Scalar driving the loops and sync](docs/img/cnn_dataflow.svg)

Walking one output pixel with real int8 numbers:

1. **Conv 3×3 → Matrix.** A 3×3 image patch `⊙` a 3×3 vertical-edge kernel, summed over the whole
   window into one int32: `Σ = (5−1) + (6−0) + (2−0) = 12`. That "Σ over the kernel window" *is* the
   contraction → it runs on the MAC array (accumulator never cleared).
2. **+bias · rescale · ReLU → Vector.** Fixed-point post-processing pulling the int32 back to int8:
   `12 + bias 4 = 16 → rescale ×½ = 8 → ReLU max(8,0) = 8`. (A patch giving `Σ=−10`:
   `−10+4=−6 → −3 → ReLU = 0`.) Pure element-wise, no accumulator → standard RVV.
3. **MaxPool 2×2 → Vector.** Max over a 2×2 window: `max(8,0,5,3) = 8`. An axis vanishes (4→1) but
   there's no multiply-reuse → a Vector *reduction*, not the MAC array.

| Stage | Op | Contraction axis? | Engine |
|---|---|---|---|
| Conv 3×3 | Σ over c·kh·kw multiply-add | yes (+ multiply reuse) | **Matrix** · command |
| +bias | element-wise add | no | **Vector** · RVV |
| rescale | element-wise fixed-point mul-shift | no | **Vector** · RVV |
| ReLU | element-wise `max(x,0)` | no | **Vector** · RVV |
| MaxPool | window reduction (max) | yes (no multiply reuse) | **Vector** · reduction |
| loop / addr / sync | control flow | doesn't touch data | **Scalar** · RV32IM |

**The rhythm of a whole layer:** Scalar loops over each output position → issues `MAT.OP` so the
Matrix engine accumulates the conv Σ into ACC (this is where the compute concentrates) → the result
lands in DTCM → Vector does bias / rescale / ReLU / pool in standard RVV → writeback → next tile.
Only the convolution actually burns compute; everything else is a lightweight element-wise tail.
Full walk-through (instruction-vs-command identity, fence/memory hand-off between engines):
[`docs/rv-npu_operation.html`](docs/rv-npu_operation.html).

## What's inside

| Area | Highlights |
|---|---|
| **Scalar core** | RV32IM**F** parametric spine (`EN_RVC/EN_BP/EN_RAS/EN_F/EN_RVV`); 4-stage in-order; host = full, NPU = stripped run-to-completion sequencer |
| **Vector** | Standard **RVV Zve32x**, integer + LMUL (mf8..m8) full grid; vector-CSR lockstep contract |
| **Matrix** | 256-MAC (LANES 1/2/4) outer-product int8→int32 + gemmlowp requant; NumPy golden |
| **NPU domain** | AXI4-Lite CSR / TCM (Harvard ITCM+DTCM, real TSMC28 SRAM macro) / bidirectional DMA / shared-mem command-queue |
| **ML e2e** | TFLM FC / MLP / CNN + MobileNet block + **Gemma-3 270M decoder layer**, all int8 bit-exact vs TFLM |
| **SoC** | `soc_m3v_top` two-core (host --AXI--> NPU), PLIC/IRQ, DMA width scaling with LANES |

## Verification

Open-source, one-command reproducible: **Verilator (DUT) + Spike (golden) + riscv64-unknown-elf-gcc
(firmware)**. Functional gates live in `gates/`, `sim/gates/`, `dv/gates/`; the RTL↔ISS lockstep
harnesses are under `flow/v2_pipeline/phase_2*`. See **[`EXTERNAL_DEPS.md`](EXTERNAL_DEPS.md)** for
exactly what a fresh checkout needs (Verilator / Spike / RISC-V GCC on `PATH`).

## Physical (TSMC28, Synopsys DC + real dual-port TCM SRAM macros)

The full flagship `npu_top` (MAT_LANES=4 / DMA_DATA_W=256, RV32IMF + full Zve32x + 256-MAC) is
DC-synthesizable and timing-closed. A multi-cycle rework of the divide/sqrt/FMA datapaths took it
from **166.7 MHz → ~460 MHz (2.8×)** while cutting cell area **−50%**, moving the critical path out
of the CPU core onto the matrix-engine MAC. Details:
[`docs/reports/2026-07-09_fdiv_multicycle_poc.md`](docs/reports/2026-07-09_fdiv_multicycle_poc.md).

## Where to start

- **[`CLAUDE.md`](CLAUDE.md)** — architecture, memory map, phase status, and the per-phase design
  discipline (the primary orientation doc).
- **`docs/adr/`** — architecture decision records · **`docs/reviews/`** — design reviews ·
  **`docs/reports/`** — PPA / perf reports.
- **`design/`** — core + NPU RTL · **`design/*/docs/`** — per-phase design confirmations.

## License / provenance

Self-built RTL. The RISC-V specification is the architectural contract; Google Coral
(Apache-2.0) is *observed* for parity, not copied. Licensed EDA tools (VCS, Spyglass, Design
Compiler, Vivado) and the TSMC28 PDK are **not** included — the open-source core flow runs without
them (see `EXTERNAL_DEPS.md`).
