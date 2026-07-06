# ADR-0035 — P0② Command Queue: shared-memory ring + sequencer consumer + descriptor SSOT

- Status: **ACCEPTED** (per-phase architecture confirmation, CLAUDE.md §2; User directive
  2026-07-03 "下一步(a)"). Architect = Grok (ring/consumer/SSOT/DV contract, this session);
  integrator/approver = Claude PL. Gemini full-context pass: **attempted, quota-blocked** —
  the re-supplied API key is free-tier with a 20-requests/DAY limit (exhausted by the first
  agentic run; all single-shot retries 429'd). Backfill when the daily quota resets; the
  Coral-side evidence below stands on the committed gap review + Ch5 de-blackbox lab
  (same honesty handling as ADR-0034). **Backfill DONE 2026-07-04**: Gemini full-context review completed (docs/reviews/2026-07-04_gemini_backfill_and_rvv_dossier.md) — verdict: consistent, no unbacked claims.
- Date: 2026-07-03
- Relates: ADR-0031 (scope), ADR-0033 (bidirectional DMA — the executors), ADR-0034 (live
  sequencer — the consumer), design report v4 **§06 Command 編碼 Spec v0.1 = frozen SSOT
  baseline** (128-bit descriptor, opcodes 0x01–0x07, MAT.RESCALE Q31 contract).

## Context

The Coral offload loop needs a work-submission mechanism: Coral's host writes command
buffers into shared memory and rings a doorbell; the NPU-side scalar core drives the
decoupled backend queues (v4 §02; lab de-blackbox: VCQ/MCQ FIFOs). We have the two halves
it connects — a verified bidirectional DMA and a live run-to-completion sequencer — but work
arrives today only via direct host CSR pokes. P0② lands the CQ **transport + SSOT decode +
the ops executable today**. The matrix/RVV engines do not exist yet (Phase 3/4); this ADR
must not pretend they do.

## Decision — contract

**1. Ring transport (host = producer).** Descriptor ring lives in shared memory
(0x8000_xxxx), 128-bit (4×32b) descriptors per v4 §06, 16B-aligned, power-of-2 count.
Host CSRs (new block @0x3000_0040): `CQ_RING_BASE 0x40`, `CQ_RING_SIZE 0x44`,
`CQ_HEAD 0x48` (RO to host), `CQ_TAIL 0x4C` (**monotonic write = doorbell**, no separate GO),
`CQ_CTRL 0x50` (enable; flush/soft_abort = P0⑤ stubs), `CQ_STATUS 0x54`
(empty/full/busy/err), `ERR_CAUSE 0x58` (latched first fault — P0⑤ hook). EMPTY =
HEAD==TAIL; FULL = (TAIL+1)&MASK==HEAD (leave-one-slot; advisory on NPU side — the
authoritative FULL check is the host's before advancing TAIL). Host ABI: all 4 descriptor
words must be globally visible **before** the TAIL write (host store ordering; no HW
torn-write detection in P0② — caught defensively by opcode/rsvd checks, risk R2).

**2. Consumer = the scalar sequencer (Coral-faithful), via a new core-local CSR window.**
Core dbus decode extends to: `addr[17]==1` → **NPU-local CSR mirror** (0x0002_xxxx, priority
over the `addr[16]` DONE mailbox), else mailbox, else TCM. The mirror exposes the SAME
register bank the host sees (DMA_SRC/DST/LEN/GO, WB_*, CQ_HEAD/TAIL/STATUS/ERR_CAUSE) so
sequencer firmware can: poll TAIL≠HEAD → program the **existing** npu_dma read engine to
fetch the descriptor `RING_BASE+HEAD*16 → TCM scratch` → decode per SSOT → execute →
`HEAD++`. Rejected: pure-RTL CQ FSM (abandons the Coral shape and the ADR-0034 lockstep
investment); dedicated fetch FSM (duplicates the verified DMA path). Register-bank write
ownership: core writes DMA_*/WB_*/CQ_HEAD, host writes CQ_RING_*/CQ_TAIL/CQ_CTRL; legacy
host writes to DMA_*/WB_* remain legal **only while CQ_CTRL.enable=0** (documented ABI;
same-cycle collision resolves core-wins in RTL).

**3. Per-opcode behavior (honesty-scoped executable subset):**

| opcode | P0② behavior |
|---|---|
| 0x01 MAT.CFG | latch {M,N,K,tile_flags} (params for Phase 4) → ack |
| 0x02 MAT.LOAD_W | map W1..W3 → DMA read (shared→TCM), wait done → ack |
| 0x03 MAT.OP | **ERR halt, ERR_CAUSE=ENGINE_NOT_READY(0x04)** — never silently ack |
| 0x04 MAT.RESCALE | same ERR halt (no engine, no queue-and-defer green-wash) |
| 0x05 MAT.STORE | map → writeback DMA (TCM→shared), wait done → ack |
| 0x06 MAT.ACC_CLR | latch acc_mask → ack |
| 0x07 MAT.FENCE | drain in-flight DMA/WB before ack |
| W0.IRQ / LAST / FENCE | IRQ pulse on completion / DONE mailbox + STATUS.done / pre-ack drain |
| W0.RPT | latched only (stripmine needs MAT.OP — Phase 4) |

ERR codes: 0x01 BAD_OPCODE, 0x02 RSVD_VIOLATION (rsvd≠0 per SSOT mask), 0x03 RING_OVERRUN,
0x04 ENGINE_NOT_READY, 0x05 DMA_FAULT, 0x06 DESC_ALIGN. On ERR: queue halts, HEAD frozen,
CQ_STATUS.err=1, ERR_CAUSE latched, no DONE. Recovery = CQ_CTRL flush stub (full abort = P0⑤).

**4. SSOT mechanics.** `design/npu/schema/command_descriptor_v0_1.yaml` = single truth
(opcode enum, W0 masks, per-opcode W1–W3 layouts, RESCALE Q31 constants, rsvd rules).
Generator `design/npu/schema/gen_cq_ssot.py` emits three checked-in artifacts:
`design/npu/rtl/cq_defs.vh` (RTL localparams), `design/npu/sw/include/command_descriptor.h`
(sequencer firmware), `design/npu/sw/cq_codec.py` (golden encoder/decoder for TBs + future host
runtime). `gate_35` regenerates and fails on any git-diff divergence (four-way SSOT per v4
§06: RTL decoder / codegen target / golden / assembler share one definition).

**5. Lockstep honesty for MMIO.** CQ firmware paths use **directed** lockstep only, with a
Spike-side shadow device for 0x0002_xxxx (MMIO loads return shadow state; DMA-done bits
driven by harness co-simulation hooks, not DUT cycle timing) — status-poll loops become
commit-deterministic. The 8×10k **random** lockstep corpus stays TCM-only (unchanged scope);
extending random lockstep over MMIO without a Spike device would be a false green (guard).

## Verification plan (gates, all Verilator; VCS signoff OUTSIDE-SANDBOX)

| gate | pass bar |
|---|---|
| `gate_35_cq_ssot` | regen == checked-in (0 diff); 256-random + all-opcode encode→RTL-decode round-trip bit-exact; rsvd-injection rejected both sides |
| `gate_36_cq_ring` | wrap / EMPTY / FULL / batch-of-N / doorbell race directed; HEAD-TAIL invariants; ring-base vs host-data alias check |
| `gate_37_cq_exec_equiv` | CQ LOAD_W / STORE produce **the same AXI transactions** as the direct-CSR paths (scoreboard equivalence vs gate_29-class checks); FENCE ordering (no WB before DMA done); IRQ/LAST semantics |
| `gate_38_cq_err` | BAD_OPCODE / rsvd / OP / RESCALE / overrun / align → ERR_CAUSE latched, HEAD frozen, no DONE; a queued STORE after a failing OP must NOT execute |
| `gate_39_cq_lockstep_mmio` | directed sequencer firmware (poll→fetch→exec→HEAD++) per-commit match vs Spike with the 0x0002 shadow device |
| regression | gates 30–34 + full existing suite stay green |

## Top risks → directed catch

1. Doorbell/TAIL race (descriptor words not yet visible) → gate_36 staggered-write directed + documented host ordering ABI.
2. Torn 128b descriptor → defensive opcode/rsvd rejection path in gate_38; P1 option: generation counter in W3 rsvd.
3. Sequencer DMA-fetch vs core fetch arbitration on the 4KB TCM → gate_36/37 overlap stress (extends gate_33 pattern).
4. MAT.OP/RESCALE green-wash (docs or gates implying they execute) → gate_38 asserts the ERR path; report wording fixed in this ADR.
5. Spike-vs-DUT divergence on MMIO polls → gate_39 shadow-device technique; random corpus untouched.

4KB TCM pressure (firmware + scratch + data) is acceptable for the P0② sequencer but is a
real dependency for P1 ITCM/DTCM sizing — recorded.

## Result + implementation deviations (2026-07-04, recorded at verification close)

Gates 35–39 all green: SSOT regen byte-identical + codec round-trip/rsvd-reject; smoke
offload batch over the ring (LOAD_W/FENCE/STORE/IRQ/LAST, 38 checks); ring WRAP + FULL/EMPTY
advisory; CQ-vs-direct-CSR **execution equivalence** (identical write-channel bursts/beats/
WLAST + weight-read activity + byte-identical result region); ERR ladder (BAD_OPCODE/RSVD/
ENGINE_NOT_READY/DESC_ALIGN — latched cause, frozen HEAD, no DONE, enable-toggle recovery);
CQ consume slice per-commit lockstep **298/298 commits** vs Spike.

Deviations vs the plan above (all honesty-reviewed):
1. **RING_OVERRUN (0x03) detection not implemented** — the firmware cannot cheaply
   distinguish a TAIL jump from a legal batch; enforcement stays host-side discipline.
   Code point reserved; revisit with P0⑤ abort. gate_38 documents the exclusion.
2. **DMA_FAULT (0x05)** exercised only at the engine level (gate_28/29); the firmware wait
   loops route it to `cq_halt(DMA_FAULT)` but no CQ-level directed test injects it yet.
3. **CQ-mode IRQ ownership** (Codex addition, accepted): while `CQ_CTRL.enable=1`, raw
   dma_done/wb_done edges no longer pulse the host IRQ — descriptor-level `W0.IRQ`
   (via `CQ_EVENT`) and `npu_done` own completion signaling. Legacy behavior is unchanged
   when the CQ is disabled (gate_29/30 regressions green).
4. **Spike MMIO shadow realized as image seeding** (no device plugin available in-env):
   deterministic poll-free firmware + seeded MMIO/DMA values; drift in real STATUS
   composition fails the commit diff loudly (gate_39 docstring records the technique).
5. **MAT.LOAD_W/STORE P0② simplification**: stride (W2) must be 0 (else RSVD_VIOLATION);
   contiguous rows*cols words land at the fixed TCM weight region (byte 0x400). Real
   strided/2D tiling arrives with the matrix engine (P1 strided DMA note stands).

## Labor division (§5)

Grok contract+DV (done, this ADR) → Codex surgical implementation (CSR bank + mirror decode
+ SSOT generator artifacts + sequencer firmware + self-smoke) → Claude authoritative gates
35–39 + regression + sole commit.
