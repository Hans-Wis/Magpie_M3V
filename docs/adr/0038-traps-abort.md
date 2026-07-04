# ADR-0038 — P0⑤: NPU fault reporting (trap-to-host) + soft_reset/abort

- Status: **ACCEPTED** (per-phase architecture confirmation, CLAUDE.md §2; User directive
  2026-07-04 "(a) P0⑤"). Mode: PL design with **Grok as critic** (major adoptions below);
  Codex post-implementation review (4 findings, dispositioned). Coral reference: Kelvin's
  `io_fault` in statusReg + host control-register reset (Ch5 lab evidence, ADR-0034 table).
- Date: 2026-07-04
- Relates: ADR-0034 (CTRL.start reset-gating), ADR-0035 (ERR_CAUSE namespace + enable-toggle
  ack), ADR-0037 (engines this abort must drain).

## Decision — contract

**1. Core trap → host = firmware, in the unified fault namespace.** The sequencer crt sets
`mtvec` FIRST (boot contract: traps are host-visible from the first real instruction); the
terminal handler stores `mepc → ERR_PC` (new mirror/host register 0x80) then
`CORE_TRAP_FLAG(bit31)|mcause → ERR_CAUSE` and spins. The `cq_err` rising edge now pulses
the host **ERR IRQ** (as does a `dma_err` edge — Grok: DMA faults must reach the IRQ, not
just STATUS). `ERR_PC`/`ERR_CAUSE` are a **latch-once pair** (PC accepted only while cause
is 0) and clear **together** on the ack.

**2. soft_reset/abort = CTRL[2] (momentary, not stored).** Sequence (Grok's ordering
adopted): the write clears `CTRL.start` **immediately** (core halts first — no torn mirror
writes), all GO pulses are **abort-locked**, `npu_dma` finishes the CURRENT AXI burst then
idles (protocol-clean; un-presented bursts are suppressed — Codex finding #1) and clears its
stickies, `mat_engine` aborts to IDLE (no AXI side); at quiesce (`STATUS[8]` drops) the run
state clears (`cq_busy`) and **ABORTED(8)** joins the fault namespace if no earlier cause
was latched. **Fault evidence PERSISTS through soft_reset** (Grok: post-mortem parity —
reset must not destroy evidence); ack = the existing `CQ_CTRL` enable-toggle. A same-cycle
ack-vs-quiesce collision resolves ack-wins (Codex finding #2). Preserved across abort: TCM
contents, CQ_RING_*/HEAD/TAIL, DMA/MAT config registers.

**3. Batch poison (documented ABI).** After an abort, the in-flight batch is INVALID:
partial RESCALE output, half-filled accumulators, and torn DMA windows are possible. The
host must ack, re-initialize ring/data, and re-arm (`gate_47` S4 exercises exactly this
flow — Kelvin shape: host reset + resubmit).

**4. Recorded limitations.** Nested trap inside the 7-instruction handler is practically
unreachable (straight-line MMIO stores to an always-ready TCM window) — if it ever occurs,
the second fault's PC/cause pair replaces the first coherently before the cause latch
closes, or the core simply spins (documented, Grok (c)). FULL IRQ stays unimplemented (the
producer-side FULL check is the ABI since ADR-0035). Traps before `mtvec` is written
(first 2 instructions) loop silently — boot contract documented.

## Verification (gate_47, 19 checks + SSOT assertions)

S1 deterministic illegal instruction at pc=0x14 → host reads `ERR_CAUSE=0x80000002`,
`ERR_PC=0x14`, ERR IRQ up, irq_clear works. S2 soft_reset: core halts, `STATUS[8]`
quiesces, **evidence persists**, ack clears the pair. S3 abort mid-4096-beat DMA read:
zero AR handshakes after quiesce (protocol clean), busy/done clear, `ERR_CAUSE=ABORTED`,
ERR IRQ. S4 ack → reload CQ firmware → full matrix batch (CFG/ACC_CLR/OP/RESCALE/STORE)
to DONE with no error. Full suite: gates 20–46 re-green (one intended expectation flip:
the CQ smoke's ERR phase now RAISES an IRQ); the `abort` port renamed `abort_i`
(SV reserved word, caught by gate_25's strict lint).

**Codex review dispositions:** #1 same-edge abort could launch one more burst → fixed
(S_AR/S_AW suppress un-presented bursts); #2 ack-vs-quiesce same-cycle left `cq_err=1,
cause=0` → fixed (quiesce block moved before the write case; ack wins); #3 ack did not
clear ERR_PC → fixed (pair clears together); #4 nested-trap PC/cause window → recorded
limitation (see above).

## Result

**P0⑤ complete — the P0 gap list (①writeback ②CQ ③matrix ④vector-CSR ⑤traps/abort) is
fully closed.** Parity checklist row 6 (例外/控制) moves to 🟡 PARTIAL→GREEN-leaning:
fault-to-host + abort/reset match the Kelvin host contract; row stays PARTIAL only for the
hard-reset distinction and trap-vector richness (recorded).
