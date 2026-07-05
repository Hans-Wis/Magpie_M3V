# ADR Draft: CQ Sequencer Batched Descriptor Prefetch (Software Optimization)

**Status:** Architecture confirmation for firmware-only optimization  
**Authority preserved:** `mat_golden.py` engine-command stream; FENCE/IRQ/LAST/ERR ordering; HEAD-per-descriptor advancement  
**RTL touch:** None for primary path

---

## 1. Dominant Tax — Confirm and Quantify

**Confirmed:** Step 4 (per-descriptor `dma_read(16B)` + `wait_dma_done()` poll) is the dominant software serialization tax, not step 6 (engine CSR stores + `mat_run` poll).

**Rough cycle budget per descriptor (sequencer @ single-issue, MMIO + poll):**

| Component | Step 4 (fetch) | Step 6 (engine, MAT_OP only) |
|---|---|---|
| CSR writes | 4 (DMA_SRC/DST/LEN/GO) | 3 (A/B/CTRL) |
| CSR reads | 0 (setup) + poll loop | poll `MAT_STATUS` until DONE |
| Fixed overhead | DMA arb + burst setup for **16 B** | — |
| Poll iterations | ~10–80 (DMA done) | ~5–40 (engine done, requant-bound locally) |

**Non-MAT_OP descriptors** (CFG, ACC_CLR, RESCALE, STORE, FENCE-flagged ops) pay **full step-4 cost** but step-6 is 1–3 CSR writes + short poll. Fetch tax is nearly 100% of their wall time.

**Example layer** (64 `MAT_OP` tiles): 68 ring entries.

| Path | Round-trips / CSR traffic |
|---|---|
| Step 4 only | 68 × (4 writes + DMA poll + 16B burst) ≈ **6,800–10,000+** fixed cycles |
| Step 6 only | 64 × (3 writes + mat poll) ≈ **1,500–4,000** cycles (compute-overlapped with requant CP) |
| Redundant step 2–3 | 68 × (2 HEAD/TAIL polls + 2 BASE/SIZE reads) ≈ **~270** CSR reads |

**Ratio:** Fetch overhead is **~2–5×** engine-issue overhead for compute-heavy layers, and **~10–50×** for metadata descriptors. At 730 MHz engine Fmax, the sequencer spends more time **moving 16-byte envelopes** than driving the engine.

**Primary move:** **Yes — batched descriptor prefetch** is the correct P0 software optimization. It attacks the only term that scales O(descriptors) with a large constant, without changing the mat_engine command stream.

---

## 2. Concrete Batched-Prefetch Design

### Core invariant

Process descriptors **strictly in ring order**. Execute engine side effects **only at the point** each descriptor would have been fetched in the legacy loop. Prefetched-but-not-yet-executed bytes are inert.

### Loop structure (replaces steps 1–7)

```
// Boot / layer entry
ring_base  = CSR_CQ_RING_BASE;   // once
ring_mask  = CSR_CQ_RING_SIZE - 1; // once, power-of-2 assumed
local_idx  = 0;
local_cnt  = 0;

forever:
  if (local_idx >= local_cnt):
    // Batch boundary: re-sync with ring
    head = CSR_CQ_HEAD;
    tail = CSR_CQ_TAIL;
    if (head == tail): poll or idle-exit per existing policy
    CSR_CQ_EVENT = BUSY;

    avail     = (tail - head) & ring_mask;  // if avail==0 and head!=tail → full ring, use ring_size
    if (avail == 0 && head != tail) avail = ring_size;
    to_wrap   = ring_size - (head & ring_mask);
    n         = min(N_MAX, avail, to_wrap, SCRATCH_SLOTS);

    dma_read(ring_base + ((head & ring_mask) << 4), TCM_SCRATCH, n << 4);
    wait_dma_done();
    local_idx = 0;
    local_cnt = n;

  w0..w3 = scratch[local_idx];
  decode → dispatch → engine commands (unchanged)
  handle FENCE / IRQ / LAST / ERR at this descriptor
  CSR_CQ_HEAD = (head + 1) & ring_mask;  // advance exactly once per descriptor
  head++;
  local_idx++;

  on ERR: cq_halt(); // do NOT advance local_idx into unexecuted prefetched slots
```

### N selection: **N_MAX = 8** (128 bytes)

| Constraint | Value |
|---|---|
| Descriptor size | 16 B |
| Batch DMA | 128 B burst — good AXI efficiency, single LEN encoding |
| TCM scratch | 128 B ≪ DTCM budget; reserve `CQ_PREFETCH_BUF[8]` at fixed offset |
| Typical FC tile chain | 5–80 descriptors/layer → 1–10 DMA fetches vs 5–80 |
| Wrap split | `to_wrap` cap avoids cross-wrap burst without hardware change |

N=16 (256 B) is viable if scratch budget confirmed, but diminishing returns: engine time per MAT_OP often exceeds 8-descriptor fetch savings. **Start N=8**; make N a compile-time constant for A/B via gate.

### Wrap

`n = min(..., ring_size - (head & ring_mask))` guarantees no burst crosses the ring end. Next batch starts at index 0. **Identical** to legacy per-descriptor indexing; only DMA contiguity changes.

### TAIL re-poll

Re-read HEAD/TAIL **only at batch boundary** (`local_idx >= local_cnt`). Mid-batch, new producer entries are invisible — same as legacy loop that only checked `head!=tail` once per descriptor at step 1 (actually legacy re-polled every iteration; batched defers TAIL visibility by ≤N−1 descriptors).

**Contract impact:** None, if producer obeys ADR-0043 fence-before-doorbell and does not assume sub-descriptor consumer visibility. LAST/FENCE semantics are per-descriptor, not per-poll.

If paranoid: re-poll TAIL after every `W0.FENCE` descriptor (producer may doorbell post-fence). Optional; not required for bit-exact if engine stream unchanged.

### FENCE / IRQ / LAST / ERR

| Flag | Rule |
|---|---|
| **FENCE** | Execute drain (DMA + WB) **before** `HEAD++` on that descriptor. Do not prefetch next batch until FENCE retires. Pre-fetched data after FENCE in the **same** batch is fine — execution order enforces drain point. |
| **IRQ** | Assert after that descriptor's engine ops + FENCE drain complete. Unchanged. |
| **LAST** | BUSY→idle, mailbox, exit policy — after descriptor fully retired. Unchanged. |
| **ERR** | On decode/dispatch ERR: `cq_halt`, **stop executing** prefetched slots; prefetched garbage never reaches engine. HEAD advancement on ERR: **freeze** (existing `cq_halt` spins with ERR_CAUSE). |
| **RING_OVERRUN** | Host producer discipline unchanged. Consumer still advances HEAD one step per consumed descriptor; overrun detection stays host-side. Firmware does not "catch up" via larger batches. |

### Bit-exact guarantee

`mat_golden.py` compares **engine command sequence** (CFG → ACC_CLR → OP×tiles → RESCALE → STORE). Batched fetch is invisible to `mat_engine` if dispatch order is unchanged. **Bit-exact preserved.**

---

## 3. gate_35..39 Equivalence Risk

**Does batched prefetch break CQ-vs-direct-CSR AXI equivalence as likely written today?**

**Yes, if the gate equates full AXI traces** including descriptor-fetch DMA transactions. Expect:

- Fewer `dma_read` transactions (larger LEN)
- Fewer `CSR_CQ_RING_BASE/SIZE` reads
- Identical mat-engine CSR write sequences and ordering

**Does that invalidate the safety property the gate was guarding?**

**No.** The gate's real intent is: *CQ consumption path produces the same engine command stream as direct CSR programming.* Descriptor-fetch DMA is an implementation detail of the consumer, not part of the Coral-parity contract.

### Reframed equivalence (proposed ADR language)

> **E1 — Engine-command-stream equivalence (authoritative):**  
> CQ batched path vs direct-CSR path → identical `mat_engine` CSR transaction sequence (opcode, operands, ordering), verified by `mat_golden.py` + gate_48/49/50.

> **E2 — Per-descriptor semantic equivalence:**  
> Identical HEAD advancement cadence (once per descriptor), FENCE/IRQ/LAST/ERR behavior, ERR halt point, LAST mailbox.

> **E3 — Descriptor-fetch DMA (non-equivalent, informational):**  
> Batched path **intentionally diverges** in shared-mem read burst count/size. Log ratio as optimization metric; do not fail on mismatch.

**Gate change:** Amend gate_35..39 comparator to diff **engine CSR window** transactions only; move full-AXI diff to a non-blocking metric or separate `gate_39b_prefetch_sanity` (burst count ↓, total bytes =).

`phase_21_cq_lockstep` (MMIO-shadow, poll-free golden) remains valid for E2 — firmware poll loops change timing but not retired semantics.

---

## 4. Secondary Wins — Ranked

| Rank | Optimization | ROI | Risk | RTL? |
|---|---|---|---|---|
| **S1** | Batched prefetch (§2) | **High** — divides step-4 by ~N | Low if ordering invariants held | Firmware |
| **S2** | RING_BASE/SIZE read once per layer/idle-wake | **Medium-low** — saves ~2×D CSR reads/layer | Trivial | Firmware |
| **S3** | Stage `CSR_MAT_A/B` during `mat_run` poll | **Low–medium** — hides 2 MMIO writes (~6–10 cycles) if mat_run ≫ staging | Medium: GO-while-busy ignored → must not write CTRL early; same-bank accumulate forbids overlapping OP issue | Firmware (careful) |
| **S4** | Hardware engine-command FIFO | **Low now** — helps only if sequencer can issue faster than engine retires; engine is requant-bound, not starved | High — CSR protocol, busy, acc banking, verification surface | **RTL — scope creep** |

**S3 detail:** Only safe pattern: while polling `MAT_STATUS`, pre-write **next** descriptor's A/B **if** next is `MAT_OP` and current op has already accepted GO. Do not prefetch CTRL. Gain is microsecond-scale per tile; do after S1+S2.

**S4 verdict:** Defer to architecture optimization phase (MAC pipelining / 128b port). FIFO decouples issue rate from a bottleneck that is **not** issue-bound.

---

## 5. Recommendation + Ordered Sub-Steps

### Decision

**Approve firmware-only batched descriptor prefetch (N=8) + loop-invariant CSR caching.** No RTL. Amend equivalence gate framing before claiming green.

### Sub-steps

| Step | Work | Verification | Green-wash guard |
|---|---|---|---|
| **0** | ADR: prefetch design + E1/E2/E3 equivalence framing | ADR review | Do not claim perf win without cycle count evidence |
| **1** | Implement `cq_prefetch_batch()`; N=8 constant; FENCE stalls next batch | `gate_35` SSOT regen-diff (unchanged) | Don't skip wrap cap `to_wrap` |
| **2** | RING_BASE/MASK read once per consume session | `gate_36` ring wrap/FULL | Don't hardcode ring size |
| **3** | Amend gate_37 comparator → engine CSR stream only; add fetch-DMA metric | `gate_37` **re-baselined** | **Fail if engine CSR seq diverges**, not if fetch DMA differs |
| **4** | ERR ladder unchanged | `gate_38` | Must halt before executing post-ERR prefetched slots |
| **5** | Full consume chain | `gate_39` + `phase_21` lockstep 298/298 | No `--isa` drift; checkpoint discipline |
| **6** | E2E regression | `gate_48/49/50` | `mat_golden.py` bit-exact; no golden patch to mask divergence |
| **7** | (Optional) S3 A/B staging behind mat_run | Add directed firmware test + re-run gate_48 | Prove no early CTRL; prove same-bank ordering |
| **8** | Perf sign-off | Synopsys DC N/A (firmware); measure cycles/layer via CSR cycle counter or sim heartbeat | Report fetch DMA count ↓≥7× for typical 68-descriptor layer |

### RTL touch flag

| Item | Touches RTL? |
|---|---|
| Batched prefetch | **No** |
| CSR cache | **No** |
| Gate comparator amend | **No** (test infra) |
| A/B staging | **No** |
| Engine command FIFO | **Yes — reject this task** |

### Exit criteria

- E1/E2 green on amended gates  
- gate_48/49/50 bit-exact unchanged  
- Descriptor-fetch DMA transactions per layer ↓ by ~7–8×  
- Zero change to `mat_engine` command stream (prove via golden diff, not waveform eyeball)

---

**Bottom line:** The sequencer is acting as a 16-byte parcel courier to TCM. Stop courting; ship boxes of 8. Engine command stream stays byte-identical; only the equivalence **definition** needs to stop conflating courier trips with compute commands.
