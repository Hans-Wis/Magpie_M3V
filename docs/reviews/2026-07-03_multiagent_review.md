# M3V multi-agent architecture review + revised plan (2026-07-03)

Reviewers: **Codex** (RTL bug hunt, self-verified w/ repro sims), **Grok** (architecture/DV strategy),
**Gemini** (plan↔impl reconciliation — *could not run headless: no `GEMINI_API_KEY`; reconciliation
done by PL/Claude instead*). Basis: `rv32_npu_design_plan.html` (v0.1) vs built reality (HEAD 8115507,
Phase 0+1). Producer≠approver: Claude integrates, PL owns decisions.

## A. Codex — verified RTL findings (Phase 1)

Codex self-verified: `verilator --lint-only` = 0 for all; official gates pass; each bug below
reproduced by a focused legal-stimulus sim under `/tmp`. **The current gates pass only the happy path.**

| # | sev | file | bug | repro |
|---|-----|------|-----|-------|
| 1 | **HIGH** | `axil_1to2.v` | **W-before-AW misroute → deadlock**. AXI-Lite legally allows WVALID before AWVALID; the router picks the W route from `s_awaddr` (stale) → W and AW go to different slaves, both hang. | `W_BEFORE_AW_DEADLOCK_REPRO` ✓ |
| 2 | **HIGH** | `npu_top.v` | same W-before-AW bug in the internal CSR/TCM router. | `TOP_W_BEFORE_AW_DEADLOCK_REPRO` ✓ |
| 3 | med | `npu_axil_regs.v` | **WSTRB ignored** — a byte write overwrites the full CSR word. | `CSR_WSTRB_IGNORED_REPRO` ✓ |
| 4 | med | `npu_tcm.v` | WSTRB ignored on TCM host writes. | `TCM_WSTRB_IGNORED_REPRO` ✓ |
| 5 | med | `npu_top.v`/`npu_axil_regs.v` | **decode aliasing** — `0x3002_0000` returns CSR ID (only `addr[16]`+`[7:2]` decoded, upper bits unchecked). | `CSR_ALIAS_REPRO` ✓ |
| 6 | med | `npu_tcm.v`/`npu_top.v` | TCM/DMA addr **silently wraps** (`0x3001_1000`→word0; DMA `DST=1024`→word0). | `TCM_ADDR_ALIAS_REPRO`,`DMA_DST_WRAP_REPRO` ✓ |
| 7 | med | `npu_dma.v` | **`LEN=0` not rejected** → `ARLEN` underflows to `0xff` → rogue 256-beat burst. | `DMA_ZERO_LEN_AR_REPRO` ✓ |
| 8 | med | `npu_dma.v` | **RRESP ignored** — SLVERR data written to TCM and `done` asserts as success. | `DMA_RRESP_WRITES_BAD_DATA_REPRO` ✓ |
| 9 | low | tbs | BFMs mask all above (AW/W always together, WSTRB=f, no negative/decode/error coverage). | gates pass while repros fail ✓ |

**Verdict (Codex):** happy-path clean; protocol NOT sealed — W-ordering, strobes, decode bounds,
DMA error/zero-len are real holes; TBs need adversarial AXI timing + negative-response coverage.

→ These are legitimate. **"Phase 1 sealed" must be qualified**: functionally integrated, but bus-
correctness hardening (Phase 1.5) is owed before it is trustworthy silicon.

## B. Grok — architecture / roadmap (per-tension, ranked)

| tension | recommendation | why |
|---|---|---|
| NPU scalar | **Stripped `cpu_m1` fork** (drop RVC/BP/RAS; keep exec/CSR/MUL/regfile) — not full copy, not greenfield | matrix NPU needs a run-to-completion sequencer; RVC/BP/RAS are liability + DV surface |
| compute org | **RVV Zve32x int8 GEMV/conv FIRST**; command-queue + matrix engine Phase 4–6 | open path today = clang RVV + TFLM; matrix HW without an encoder is unverifiable |
| closed toolchain | **Build**: CQ-encoding SSOT (schema→RTL decode + C headers) + reference encoder (~0.5–2k LOC) + host ring driver + TFLM custom op. **Defer** IREE/StableHLO auto-lowering | no Google/Synaptics dependency; manual microkernel mapping suffices for first GEMV |
| matrix verification | **NumPy golden that decodes CQ bytes independently** (shares only the SSOT spec, not RTL internals) — anti-common-mode | matrix has no ISA golden; this is the one net-new DV capability |
| memory map / CQ | **Keep built 0x3000/0x3001**; add **SHARED_MEM@0x8000 CQ ring** + doorbell CSR + DONE/ERR IRQ bits; CQ is a memory ring, NOT CSR space | fabric is sunk cost; missing piece is the ring region + ordering rules |

**Grok red flags:** non-coherent AXI — host must flush/invalidate before doorbell (document);
add abort/reset CSR (no mid-queue host patching); STATUS needs DONE+ERR+FULL bits.

## C. Plan (v0.1) ↔ built reality — reconciliation (PL/Claude, Gemini's slot)

| topic | plan HTML says | built / decided | resolution |
|---|---|---|---|
| memory map | NPU_CSR@0x4000, SHARED_MEM@0x8000 | NPU@0x3000 (CSR)/0x3001 (TCM); DMA reads shared mem | **keep 0x3000/0x3001**; adopt **SHARED_MEM@0x8000** for weights + CQ ring (update plan HTML) |
| NPU scalar | minimal run-to-completion, no spec/no C | ADR-0031 "copy cpu_m1" (heavy) | **revise to stripped `cpu_m1` fork** (Grok) — update ADR-0031 |
| compute | matrix-CENTRIC command-queue is day-1 compute | ADR-0031 RVV-first, GEMV bolt-on | **RVV int8 first; matrix/CQ Phase 4–6** — plan's matrix layer is the accelerator, not day-1 |
| compile flow | TF→MLIR→**IREE+NPU plugin**→RV32 | Phase 0 proved: IREE-NPU plugin is **CLOSED/unavailable** | plan is **infeasible as drawn**; substitute open path (clang RVV+TFLM+own CQ encoder) |
| command queue | central abstraction | not in RTL yet | introduce as **SSOT schema** in Phase 4 (bridges open RVV tooling ↔ matrix) |
| matrix golden | "bit-accurate numerical ref" (correct) | not built | NumPy-from-SSOT, independent chain (agrees w/ Grok) |

**Plan's biggest gap:** it assumes Google's IREE-NPU-plugin compile flow, which is closed-source and
unavailable here (Phase-0 finding). The plan HTML needs a "toolchain reality" revision.

## D. Revised roadmap (reconciled — supersedes ADR-0031 Phase list)

- **Phase 1.5 (hardening, NEW, do before Phase 2):** fix Codex #1–#8; add adversarial AXI BFM
  (W-before-AW, WSTRB byte-writes, out-of-range decode→DECERR, SLVERR, LEN=0); re-seal gates 20/25/27.
- **Phase 2:** stripped `cpu_m1` fork = NPU scalar sequencer (drop RVC/BP/RAS; keep exec/CSR/MUL),
  plugged into `npu_top`; boots from TCM; standalone Spike lockstep on the scalar leg.
- **Phase 3:** attach **RVV Zve32x** (VLEN128); hand-written int8 GEMV/conv microkernel in TCM, DMA
  weights in; RVV vector-retire equivalence vs Spike (reuse M1V ADR-0028). Measure c/MAC.
- **Phase 4:** **CQ SSOT** (schema → RTL decode + C headers) + reference encoder + host ring driver
  + **NumPy golden**; random-CQ unit tests (golden vs decode-only RTL).
- **Phase 5:** **matrix engine** RTL (256-MAC outer-product) driven by CQ; bit-accurate vs NumPy golden.
- **Phase 6:** **TFLM e2e** — one int8 conv/GEMV layer: TFLM custom op → CQ encoder → NPU → IRQ → check.
- **Phase 7:** hardening/PPA; optionally minimize scalar to a 2-stage sequencer if area bites; add F.

**One-line consensus:** ship **RVV-first int8 on a stripped scalar over the existing 0x3000 fabric**;
treat the plan's matrix-centric command-queue as the Phase 4–6 accelerator layer, with the **CQ SSOT**
as the bridge between open RVV tooling and future matrix speedup — not the day-1 compute path. And
**harden the Phase-1 bus (Phase 1.5) first** — Codex proved it is not yet protocol-correct.
