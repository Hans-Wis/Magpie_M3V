#include "../include/command_descriptor.h"

#define CSR_BASE        CQ_CORE_WINDOW_BASE
#define MAILBOX_BASE    CQ_MAILBOX_BASE
#define TCM_SCRATCH_B   0x00000F00u
#define TCM_SCRATCH_W   (TCM_SCRATCH_B >> 2)
#define TCM_WEIGHT_B    0x00000700u   /* ADR-0043/0052: 0x400->0x600->0x680->0x700 (batched-prefetch code growth) */
#define TCM_WEIGHT_W    (TCM_WEIGHT_B >> 2)

#define CSR_CTRL        0x04u
#define CSR_STATUS      0x08u
#define CSR_DMA_SRC     0x20u
#define CSR_DMA_DST     0x24u
#define CSR_DMA_LEN     0x28u
#define CSR_DMA_GO      0x2Cu
#define CSR_WB_SRC      0x30u
#define CSR_WB_DST      0x34u
#define CSR_WB_LEN      0x38u
#define CSR_WB_GO       0x3Cu
#define CSR_MAT_A       0x60u
#define CSR_MAT_B       0x64u
#define CSR_MAT_CTRL    0x68u
#define CSR_MAT_MULT    0x6Cu
#define CSR_MAT_RSP     0x70u
#define CSR_MAT_CLAMP   0x74u
#define CSR_MAT_OUT     0x78u
#define CSR_MAT_STATUS  0x7Cu
#define CSR_ERR_PC      0x80u
#define MAT_ST_BUSY     1u
#define MAT_ST_DONE     2u
#define MAT_ST_ERR      4u
#define MAT_CMD_CLR     0u
#define MAT_CMD_LOADACC 3u
#define MAT_CMD_RESCALE_PC 4u
#define MAT_CMD_OP      1u
#define MAT_CMD_RESCALE 2u

#define STATUS_DMA_BUSY (1u << 2)
#define STATUS_DMA_DONE (1u << 3)
#define STATUS_DMA_ERR  (1u << 5)
#define STATUS_WB_BUSY  (1u << 6)
#define STATUS_WB_DONE  (1u << 7)

#define CQ_CTRL_ENABLE  1u
#define CQ_EVENT_IRQ    1u
#define CQ_EVENT_BUSY   2u
#define CQ_EVENT_IDLE   4u

/* ADR-0052: descriptors are prefetched a batch at a time to amortize the
 * per-descriptor ring DMA round-trip. 8 x 16B = 128B fits the 0xF00..0x1000
 * scratch region with margin (16 would exactly fill it). */
#define BATCH_N         8u

static volatile uint32_t *const csr = (volatile uint32_t *)CSR_BASE;
static volatile uint32_t *const mailbox = (volatile uint32_t *)MAILBOX_BASE;
static volatile cq_desc_t *const scratch = (volatile cq_desc_t *)TCM_SCRATCH_B;

static volatile uint32_t cfg_m, cfg_n, cfg_k, cfg_tile_flags, acc_mask_latch;

/* ADR-0038: terminal trap handler — reports the fault to the host through the
 * latch-once ERR_PC/ERR_CAUSE pair (cause bit31 = CORE_TRAP flag | mcause);
 * the cq_err rising edge raises the host ERR IRQ. Then spin (Kelvin io_fault
 * shape: host soft_resets and resubmits). A trap inside the handler re-enters
 * and spins with the FIRST cause preserved (latch-once). */
__attribute__((naked, aligned(4))) void trap_handler(void)
{
    __asm__ volatile (
        "lui  t1, 0x20\n"          /* CSR mirror base */
        "csrr t2, mepc\n"
        "sw   t2, 0x80(t1)\n"      /* ERR_PC first (pairs with cause) */
        "csrr t0, mcause\n"
        "lui  t3, 0x80000\n"
        "or   t0, t0, t3\n"
        "sw   t0, 0x58(t1)\n"      /* ERR_CAUSE = CORE_TRAP|mcause -> ERR IRQ */
        "1: j 1b\n"
    );
}

__attribute__((naked, section(".init"))) void _start(void)
{
    __asm__ volatile (
        "la   t0, trap_handler\n"  /* mtvec FIRST: traps are host-visible from here on */
        "csrw mtvec, t0\n"
        "li   sp, 0x0f00\n"
        "call main\n"
        "1: j 1b\n"
    );
}

/* noinline: these are called ~30x; keeping them as real calls (vs -Os inlining
 * each expansion) reclaims the code budget the ADR-0052 batch loop needs. */
static __attribute__((noinline)) uint32_t csr_read(uint32_t off)
{
    return csr[off >> 2];
}

static __attribute__((noinline)) void csr_write(uint32_t off, uint32_t value)
{
    csr[off >> 2] = value;
}

static void cq_halt(uint32_t cause)
{
    csr_write(CSR_ERR_CAUSE, cause);
    for (;;)
        ;
}

static void wait_done(uint32_t done_bit)
{
    uint32_t st;
    do {
        st = csr_read(CSR_STATUS);
        if (st & STATUS_DMA_ERR)
            cq_halt(CQ_ERR_DMA_FAULT);
    } while ((st & done_bit) == 0u);
}

static void drain_dma_wb(void)
{
    uint32_t st;
    do {
        st = csr_read(CSR_STATUS);
        if (st & STATUS_DMA_ERR)
            cq_halt(CQ_ERR_DMA_FAULT);
    } while (st & (STATUS_DMA_BUSY | STATUS_WB_BUSY));
}

static void dma_read(uint32_t src, uint32_t dst_word, uint32_t len_words)
{
    csr_write(CSR_DMA_SRC, src);
    csr_write(CSR_DMA_DST, dst_word);
    csr_write(CSR_DMA_LEN, len_words);
    csr_write(CSR_DMA_GO, 1u);
    wait_done(STATUS_DMA_DONE);
}

static void mat_run(uint32_t cmd, uint32_t bank, uint32_t rpt)
{
    uint32_t st;
    csr_write(CSR_MAT_CTRL, (cmd << 16) | (bank << 8) | (rpt & 0xFFu));
    do {
        st = csr_read(CSR_MAT_STATUS);
    } while ((st & MAT_ST_DONE) == 0u);
    if (st & MAT_ST_ERR)
        cq_halt(CQ_ERR_MAT_PARAM);
}

static void dma_writeback(uint32_t src_word, uint32_t dst, uint32_t len_words)
{
    csr_write(CSR_WB_SRC, src_word);
    csr_write(CSR_WB_DST, dst);
    csr_write(CSR_WB_LEN, len_words);
    csr_write(CSR_WB_GO, 1u);
    wait_done(STATUS_WB_DONE);
}

void main(void)
{
    if ((csr_read(CSR_CQ_CTRL) & CQ_CTRL_ENABLE) == 0u) {
        *mailbox = 1u;
        for (;;)
            ;
    }

    /* ADR-0052: ring config is loop-invariant — read once, not per descriptor. */
    uint32_t ring_base = csr_read(CSR_CQ_RING_BASE);
    uint32_t ring_size = csr_read(CSR_CQ_RING_SIZE);
    uint32_t ring_mask = ring_size - 1u;
    if ((ring_base & 0xFu) != 0u)
        cq_halt(CQ_ERR_DESC_ALIGN);

    for (;;) {
        uint32_t head = csr_read(CSR_CQ_HEAD);
        uint32_t tail = csr_read(CSR_CQ_TAIL);
        if (head == tail)
            continue;

        csr_write(CSR_CQ_EVENT, CQ_EVENT_BUSY);

        /* ADR-0052 batched prefetch: one dma_read pulls up to BATCH_N contiguous
         * descriptors (bounded by the pending count and the ring-wrap edge) into
         * the local scratch buffer; each then executes in ring order with the
         * identical engine command stream and per-descriptor HEAD advance. The
         * ring-fetch DMA round-trips drop from one-per-descriptor to one-per-batch;
         * the wrapped tail (if any) is handled by the next outer iteration. */
        uint32_t hidx    = head & ring_mask;
        uint32_t pending = (tail - head) & ring_mask;
        uint32_t to_wrap = ring_size - hidx;
        uint32_t n = pending;
        if (n > to_wrap) n = to_wrap;
        if (n > BATCH_N)  n = BATCH_N;

        dma_read(ring_base + (hidx << 4), TCM_SCRATCH_W, n << 2);

        for (uint32_t bi = 0u; bi < n; bi++) {
        uint32_t w0 = scratch[bi].w0;
        uint32_t w1 = scratch[bi].w1;
        uint32_t w2 = scratch[bi].w2;
        uint32_t w3 = scratch[bi].w3;
        uint32_t op = cq_w0_opcode(w0);

        if (w0 & CQ_W0_RSVD_MASK)
            cq_halt(CQ_ERR_RSVD_VIOLATION);

        switch (op) {
        case CQ_OP_MAT_CFG:
            cfg_m = (w1 >> 16) & 0xFFFFu;
            cfg_n = w1 & 0xFFFFu;
            cfg_k = w2;
            cfg_tile_flags = w3;
            if (cfg_m > 8u || cfg_n > 8u)
                cq_halt(CQ_ERR_MAT_PARAM);
            break;
        case CQ_OP_MAT_LOAD_W: {
            uint32_t rows = (w3 >> 8) & 0xFFu;
            uint32_t cols = w3 & 0xFFu;
            /* ADR-0043 (Codex #3): destination capacity — the fixed weight
             * region holds (SCRATCH - WEIGHT)/4 words; more must halt. */
            if (rows * cols > (TCM_SCRATCH_B - TCM_WEIGHT_B) / 4u)
                cq_halt(CQ_ERR_MAT_PARAM);
            if (w2 == 0u) {
                /* contiguous rows*cols words -> TCM weight region */
                dma_read(w1, TCM_WEIGHT_W, rows * cols);
            } else {
                /* ADR-0043: W2 = src row stride in BYTES (2D gather).
                 * stride word-aligned, >= row bytes, capped at 64K (a stray
                 * huge stride lands on the DMA_FAULT path, not silent wrap) */
                uint32_t r;
                if ((w2 & 3u) != 0u || w2 < cols * 4u || w2 > 0xFFFFu ||
                    (rows != 0u && w1 > 0xFFFFFFFFu - (rows - 1u) * w2))
                    cq_halt(CQ_ERR_MAT_PARAM);   /* Codex #2: no silent wrap */
                for (r = 0u; r < rows; r++)
                    dma_read(w1 + r * w2, TCM_WEIGHT_W + r * cols, cols);
            }
            break;
        }
        case CQ_OP_MAT_STORE: {
            uint32_t rows = (w3 >> 8) & 0xFFu;
            uint32_t cols = w3 & 0xFFu;
            uint32_t dstride = (w3 >> 16) & 0xFFFFu;   /* ADR-0043: words, 0=contig */
            /* ADR-0037: W2 = TCM source byte addr; 0 = legacy weight region.
             * Bound + alignment checked (no silent TCM aliasing). */
            uint32_t src_w;
            /* ADR-0052 (Codex #2): source ceiling is the scratch base, not the
             * TCM top — the 0xF00.. region now holds the batch descriptor
             * prefetch buffer, which must not be observable as a STORE source. */
            if ((w2 & 3u) != 0u || rows * cols * 4u > TCM_SCRATCH_B ||
                w2 > (TCM_SCRATCH_B - rows * cols * 4u))
                cq_halt(CQ_ERR_MAT_PARAM);
            src_w = (w2 != 0u) ? (w2 >> 2) : TCM_WEIGHT_W;
            if (dstride == 0u) {
                dma_writeback(src_w, w1, rows * cols);
            } else {
                /* 2D scatter: dst row r at w1 + r*stride*4 */
                uint32_t r;
                if (dstride < cols ||
                    (rows != 0u && w1 > 0xFFFFFFFFu - (rows - 1u) * dstride * 4u))
                    cq_halt(CQ_ERR_MAT_PARAM);   /* Codex #2: no silent wrap */
                for (r = 0u; r < rows; r++)
                    dma_writeback(src_w + r * cols, w1 + r * dstride * 4u, cols);
            }
            break;
        }
        case CQ_OP_MAT_ACC_CLR:
            acc_mask_latch = w1;
            if (w2 != 0u) {
                /* ADR-0039: W2 = TCM byte addr of 8 int32 fold words
                 * (input_offset*sum_w + bias); broadcast into every row of
                 * each masked bank. Bound + alignment checked. */
                uint32_t b;
                if ((w2 & 3u) != 0u || w2 > (TCM_SCRATCH_B - 32u))
                    cq_halt(CQ_ERR_MAT_PARAM);
                for (b = 0u; b < 4u; b++)
                    if (w1 & (1u << b)) {
                        csr_write(CSR_MAT_A, w2);
                        mat_run(MAT_CMD_LOADACC, b, 1u);
                    }
            } else {
                mat_run(MAT_CMD_CLR, w1 & 0xFu, 1u);
            }
            break;
        case CQ_OP_MAT_FENCE:
            drain_dma_wb();
            break;
        case CQ_OP_MAT_OP: {
            uint32_t rpt = cq_w0_rpt(w0);
            /* ADR-0037 bindings: W3 must be 0; RPT*8 must equal latched K;
             * int8-only engine (DTYPE=0); a/b must sit inside the TCM below
             * the scratch region (no silent aliasing — Codex 4B review) */
            /* wrap-safe bounds: rpt*8 <= 2040 << TCM_SCRATCH_B, so compare
             * the base against (limit - len) instead of forming base + len
             * (uint32 wrap bypass — Codex Phase-6 finding) */
            if (w3 != 0u || (rpt * 8u) != cfg_k || cq_w0_dtype(w0) != 0u ||
                w1 > (TCM_SCRATCH_B - rpt * 8u) || w2 > (TCM_SCRATCH_B - rpt * 8u))
                cq_halt(CQ_ERR_MAT_PARAM);
            csr_write(CSR_MAT_A, w1);
            csr_write(CSR_MAT_B, w2);
            mat_run(MAT_CMD_OP, cq_w0_acc(w0), rpt);
            break;
        }
        case CQ_OP_MAT_RESCALE: {
            uint32_t rmode = cq_w0_rpt(w0);
            if (cq_w0_dtype(w0) != 0u || rmode > 1u)
                cq_halt(CQ_ERR_MAT_PARAM);
            if (rmode == 1u) {
                /* ADR-0042 per-channel: W1 = 32B-aligned TCM ptr to 8x Q31
                 * mult + 8 shift bytes (40B); wrap-safe bound. */
                if ((w1 & 31u) != 0u || w1 > (TCM_SCRATCH_B - 40u))
                    cq_halt(CQ_ERR_MAT_PARAM);
            }
            csr_write(CSR_MAT_MULT, w1);
            csr_write(CSR_MAT_RSP, w2);
            csr_write(CSR_MAT_CLAMP, w3);
            mat_run(rmode ? MAT_CMD_RESCALE_PC : MAT_CMD_RESCALE,
                    cq_w0_acc(w0), 1u);
            break;
        }
        default:
            cq_halt(CQ_ERR_BAD_OPCODE);
            break;
        }

        if (cq_w0_fence(w0))
            drain_dma_wb();
        if (cq_w0_irq(w0))
            csr_write(CSR_CQ_EVENT, CQ_EVENT_IRQ);

        head = (head + 1u) & ring_mask;
        csr_write(CSR_CQ_HEAD, head);
        if (cq_w0_last(w0)) {
            csr_write(CSR_CQ_EVENT, CQ_EVENT_IDLE);
            *mailbox = 1u;
        }
        }   /* end per-descriptor batch loop */
    }
}
