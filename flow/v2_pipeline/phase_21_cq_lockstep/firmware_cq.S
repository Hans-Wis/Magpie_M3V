/* ADR-0035 gate_39 — deterministic (poll-free) CQ consume slice for Spike lockstep.
 *
 * Technique ("shadow device via image seeding", ADR-0035 §lockstep-honesty):
 * every MMIO/DMA-produced value this program LOADS is pre-seeded at the same
 * address in the Spike image (assembled with -DSPIKE_SEED), so the commit
 * stream is deterministic without a Spike device plugin:
 *   - poll loops are replaced by a bounded pure-ALU delay + ONE status read,
 *   - the seeded STATUS value must equal the DUT's real deterministic STATUS
 *     at that commit (npu_busy|dma_done|irq_pending = 0x19) — if RTL status
 *     composition drifts, the lockstep diff catches it loudly.
 * Flow exercised: read TAIL/HEAD -> DMA-fetch descriptor (ring @0x400) ->
 * decode LOAD_W -> DMA-execute (weights @0x800 -> TCM 0x400) -> verify loads
 * -> HEAD++ -> LAST mailbox -> ebreak (lockstep terminator).
 */
.section .init
.global _start
/* All bases are pc-relative (auipc/la) so the DUT (link @0x0) and Spike
 * (link @0x8000_0000) images have IDENTICAL instruction encodings; the
 * runtime pointer values differ by the link base and are normalized by the
 * comparator (normalize_window=0x40000). */
_start:
    auipc x21, 0x20           /* offset 0: x21 = link_base + 0x20000 (CSR mirror) */
    auipc x19, 0x10           /* offset 4: x19 = link_base + 0x10004 */
    addi  x19, x19, -4        /* x19 = link_base + 0x10000 (DONE mailbox) */
    la    x20, _start + 0xF00 /* TCM descriptor scratch */
    la    x22, _start + 0x400 /* TCM weight region */
    li    sp, 0x0F00          /* unused, kept sane */

    lw   x5, 0x4C(x21)        /* TAIL (seed: 1) */
    lw   x6, 0x48(x21)        /* HEAD (seed: 0) */

    /* fetch descriptor: ring slot 0 @ shared 0x400 -> TCM scratch word 0x3C0 */
    li   x7, 0x400
    sw   x7, 0x20(x21)        /* DMA_SRC  */
    li   x7, 0x3C0
    sw   x7, 0x24(x21)        /* DMA_DST word */
    li   x7, 4
    sw   x7, 0x28(x21)        /* DMA_LEN  */
    li   x7, 1
    sw   x7, 0x2C(x21)        /* DMA_GO   */
    li   x8, 64               /* bounded pure-ALU delay >> 4-beat DMA latency */
1:  addi x8, x8, -1
    bne  x8, zero, 1b
    lw   x9, 0x08(x21)        /* single STATUS read (seed: 0x19) */

    lw   x10, 0(x20)          /* descriptor W0 (seed: LOAD_W 0x00000002) */
    lw   x11, 4(x20)          /* W1 src (seed: 0x800) */
    lw   x12, 8(x20)          /* W2 (seed: 0) */
    lw   x13, 12(x20)         /* W3 rows/cols (seed: 0x202) */

    /* execute LOAD_W: 4 words shared 0x800 -> TCM weight word 0x100 */
    sw   x11, 0x20(x21)
    li   x7, 0x100
    sw   x7, 0x24(x21)
    li   x7, 4
    sw   x7, 0x28(x21)
    li   x7, 1
    sw   x7, 0x2C(x21)
    li   x8, 64
2:  addi x8, x8, -1
    bne  x8, zero, 2b
    lw   x14, 0x08(x21)       /* single STATUS read (seed: 0x19) */

    lw   x15, 0(x22)          /* weights landed (seed: 0x5A5A0000..3) */
    lw   x16, 4(x22)
    lw   x17, 8(x22)
    lw   x18, 12(x22)

    addi x6, x6, 1            /* HEAD++ */
    sw   x6, 0x48(x21)
    li   x7, 1                /* mailbox: LAST -> DONE */
    sw   x7, 0(x19)
    ebreak

#ifdef SPIKE_SEED
/* ---- Spike-image-only shadow seeds (absent from the DUT image) ---- */
.org 0x400
    .word 0x5A5A0000, 0x5A5A0001, 0x5A5A0002, 0x5A5A0003   /* post-LOAD_W TCM weights */
.org 0xF00
    .word 0x00000002, 0x00000800, 0x00000000, 0x00000202   /* fetched descriptor */
.org 0x20008
    .word 0x00000019                                        /* STATUS: busy|dma_done|irq_pending */
.org 0x20048
    .word 0x00000000                                        /* HEAD */
.org 0x2004C
    .word 0x00000001                                        /* TAIL */
#endif
