# ADR-0033 — Result writeback DMA (P0 Coral-parity gap ①)

- Status: **ACCEPTED** (per-phase architecture-design confirmation, CLAUDE.md §2). Producer = Claude
  integrating Grok (contract/DV) + Gemini (full-context Coral confirmation); approver = User (directive
  "b: writeback DMA, three-agent"). Reviewers concurred.
- Date: 2026-07-03
- Relates: closes gap ① of `docs/reviews/2026-07-03_coral_gap_review.md`; extends `IP/npu/docs/01_axi_fabric_spec.md`.

## Architecture confirmation vs Coral (§2 step 1)

Coral's offload loop = doorbell → DMA cmd+weights IN → compute → **DMA results OUT to shared mem** →
IRQ. We built only the IN half (`npu_dma` is a read-only AXI4-full master). To be a **functional
replacement**, the NPU must DMA results back to shared memory and raise IRQ **only after the AXI write
response channel is fully drained** (strongly ordered — no DONE/IRQ before the final `BVALID&&BREADY`),
else the host races on stale/partial results.

## Decision

**Generalize `npu_dma` into a bidirectional single-outstanding engine** (reuse the ≤256-beat + 4KB-safe
chunking, address progression, beat counters for BOTH read and write). Writeback is an **independent
triggered op** (its own `WB_GO`), symmetric to the existing read op — host firmware phases weights-in
(`GO`) then results-out (`WB_GO`); a unified read+write job sequencer is deferred (not needed for v1,
avoids re-architecting the proven read path).

### CSR contract (npu_axil_regs, WB_* block; LEN/SRC in beats/word-offset like the read path)

| off | reg | meaning |
|---|---|---|
| 0x30 | WB_SRC | TCM word offset (source of result data) |
| 0x34 | WB_DST | shared-mem **byte** address (word-aligned), 0x8000 region |
| 0x38 | WB_LEN | beats (32-bit words) to write back; **0 = no-op** |
| 0x3C | WB_CTRL | bit0 = WB_GO (1-cycle pulse) |
| 0x08 | STATUS | **[5]=dma_err (combined RRESP|BRESP)** · **[6]=wb_busy** · **[7]=wb_done** (existing [0..4] unchanged) |

`wb_done` (and its IRQ) assert **only after the final write B handshake**. `wb_err` = BRESP SLVERR/DECERR
latched → abort job, **no wb_done**, sticky in STATUS[5]. IRQ rises on `wb_done` (as it does on `dma_done`).

### RTL (touch-list, Grok+Gemini concurred)

1. **npu_tcm.v** — add a DMA **read port** (`dma_re`, `dma_raddr[AW-1:0]`, `dma_rdata[31:0]`, async
   `assign dma_rdata = mem[dma_raddr]`). Arbitration: host loader > DMA (DMA read only when writeback active).
2. **npu_dma.v** — add `write_mode` input; AXI4 write channels (`m_aw*`,`m_w*`,`m_b*`); TCM read
   interface; FSM states **S_AW → S_W → S_B → S_DONE** (mirror S_AR/S_R). Reuse chunking on AW.
   `err` latches on `m_bvalid&&m_bready&&m_bresp[1]` (in addition to existing RRESP).
3. **npu_axil_regs.v** — WB_SRC/DST/LEN/GO CSRs; STATUS[5..7]; `wb_go` pulse; combined `dma_err`.
4. **npu_top.v** — expose external `m_aw*`/`m_w*`/`m_b*`; wire WB CSRs ↔ dma ↔ tcm read port.

### AXI4 write correctness (RTL must-haves — pre-empt the classic bugs)

- AW accepted before first W; hold WDATA when `WREADY` low. **WLAST exactly once** per burst (final beat).
- **Same ≤256-beat AND 4KB-boundary chunking on AW** as on AR. Single-outstanding (complete B before next AW).
- Accept every B; SLVERR → `wb_err` + abort, no wb_done. WSTRB=full on interior beats (byte tail if needed).

## Verification (authority = Verilator scoreboard; VCS = signoff OUTSIDE-SANDBOX)

`tb_npu_writeback.v` + `gate_29_npu_writeback.py`: host preloads a golden pattern into TCM via AXI-Lite;
programs WB_SRC=0, WB_DST=0x8000_xxxx crossing a 4KB boundary, WB_LEN>256 (multi-burst); pulses WB_GO;
an AXI4 write-capable mem model captures bursts; on IRQ, read back shared mem and assert
`SHARED[WB_DST+n] == TCM[WB_SRC+n]` for all n. Separate SLVERR-injection case asserts STATUS.dma_err
sticky + graceful terminate (no lockup, no wb_done).

**Green-wash guards (Claude enforces):** early-DONE (wb_done before final BVALID&BREADY); WLAST
missing/early/duplicate; no 4KB/256 split on the write path; `wb_err` not wired (injected SLVERR must
set STATUS + block wb_done); "read-only pass" (writeback claimed with no AW/W/B bus activity);
WB_LEN=0 spurious-done or stuck-busy.

## Implementation sequence (each independently Verilator-verifiable) — Codex

| step | deliverable | pass |
|---|---|---|
| S1 | WB_* CSRs + npu_tcm DMA read port | CSR R/W; TCM DMA-read returns host-preloaded pattern |
| S2 | AXI write channel + chunking + wb_err latch | directed clean burst + SLVERR; WLAST/WSTRB/BRESP scoreboard |
| S3 | phased WB_GO: TCM→W→B→wb_done/IRQ | e2e SHARED==TCM golden (4KB-cross, >256); wb_done only post-B |
| S4 | edge/error: WB_LEN=0, mid-job SLVERR, busy-on-GO | no false done; wb_err sticky; gate_20/25/27/28 regression green |

Note: writeback DST region 0x8000 (our map), NOT Coral's 0x4000 (Gemini's draft used Coral's number).
