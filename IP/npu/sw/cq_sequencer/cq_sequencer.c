#include "../include/command_descriptor.h"

#define CSR_BASE        CQ_CORE_WINDOW_BASE
#define MAILBOX_BASE    CQ_MAILBOX_BASE
#define TCM_SCRATCH_B   0x00000F00u
#define TCM_SCRATCH_W   (TCM_SCRATCH_B >> 2)
#define TCM_WEIGHT_B    0x00000600u   /* ADR-0037: moved from 0x400 (firmware text grew past it) */
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

static uint32_t csr_read(uint32_t off)
{
    return csr[off >> 2];
}

static void csr_write(uint32_t off, uint32_t value)
{
    csr[off >> 2] = value;
}

static void cq_halt(uint32_t cause)
{
    csr_write(CSR_ERR_CAUSE, cause);
    for (;;)
        ;
}

static void wait_dma_done(void)
{
    uint32_t st;
    do {
        st = csr_read(CSR_STATUS);
        if (st & STATUS_DMA_ERR)
            cq_halt(CQ_ERR_DMA_FAULT);
    } while ((st & STATUS_DMA_DONE) == 0u);
}

static void wait_wb_done(void)
{
    uint32_t st;
    do {
        st = csr_read(CSR_STATUS);
        if (st & STATUS_DMA_ERR)
            cq_halt(CQ_ERR_DMA_FAULT);
    } while ((st & STATUS_WB_DONE) == 0u);
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
    wait_dma_done();
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
    wait_wb_done();
}

void main(void)
{
    if ((csr_read(CSR_CQ_CTRL) & CQ_CTRL_ENABLE) == 0u) {
        *mailbox = 1u;
        for (;;)
            ;
    }

    for (;;) {
        uint32_t head = csr_read(CSR_CQ_HEAD);
        uint32_t tail = csr_read(CSR_CQ_TAIL);
        if (head == tail)
            continue;

        csr_write(CSR_CQ_EVENT, CQ_EVENT_BUSY);
        uint32_t ring_base = csr_read(CSR_CQ_RING_BASE);
        uint32_t ring_size = csr_read(CSR_CQ_RING_SIZE);
        if ((ring_base & 0xFu) != 0u)
            cq_halt(CQ_ERR_DESC_ALIGN);

        dma_read(ring_base + (head << 4), TCM_SCRATCH_W, 4u);

        uint32_t w0 = scratch->w0;
        uint32_t w1 = scratch->w1;
        uint32_t w2 = scratch->w2;
        uint32_t w3 = scratch->w3;
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
            if (w2 != 0u)
                cq_halt(CQ_ERR_RSVD_VIOLATION);
            /* P0.2 simplification: contiguous rows*cols words land at TCM byte 0x400. */
            dma_read(w1, TCM_WEIGHT_W, rows * cols);
            break;
        }
        case CQ_OP_MAT_STORE: {
            uint32_t rows = (w3 >> 8) & 0xFFu;
            uint32_t cols = w3 & 0xFFu;
            /* ADR-0037: W2 = TCM source byte addr; 0 = legacy weight region.
             * Bound + alignment checked (no silent TCM aliasing). */
            uint32_t src_w;
            if ((w2 & 3u) != 0u || (w2 + rows * cols * 4u) > 0x1000u)
                cq_halt(CQ_ERR_MAT_PARAM);
            src_w = (w2 != 0u) ? (w2 >> 2) : TCM_WEIGHT_W;
            dma_writeback(src_w, w1, rows * cols);
            break;
        }
        case CQ_OP_MAT_ACC_CLR:
            acc_mask_latch = w1;
            mat_run(MAT_CMD_CLR, w1 & 0xFu, 1u);
            break;
        case CQ_OP_MAT_FENCE:
            drain_dma_wb();
            break;
        case CQ_OP_MAT_OP: {
            uint32_t rpt = cq_w0_rpt(w0);
            /* ADR-0037 bindings: W3 must be 0; RPT*8 must equal latched K;
             * int8-only engine (DTYPE=0); a/b must sit inside the TCM below
             * the scratch region (no silent aliasing — Codex 4B review) */
            if (w3 != 0u || (rpt * 8u) != cfg_k || cq_w0_dtype(w0) != 0u ||
                (w1 + rpt * 8u) > TCM_SCRATCH_B || (w2 + rpt * 8u) > TCM_SCRATCH_B)
                cq_halt(CQ_ERR_MAT_PARAM);
            csr_write(CSR_MAT_A, w1);
            csr_write(CSR_MAT_B, w2);
            mat_run(MAT_CMD_OP, cq_w0_acc(w0), rpt);
            break;
        }
        case CQ_OP_MAT_RESCALE:
            if (cq_w0_dtype(w0) != 0u)
                cq_halt(CQ_ERR_MAT_PARAM);
            csr_write(CSR_MAT_MULT, w1);
            csr_write(CSR_MAT_RSP, w2);
            csr_write(CSR_MAT_CLAMP, w3);
            mat_run(MAT_CMD_RESCALE, cq_w0_acc(w0), 1u);
            break;
        default:
            cq_halt(CQ_ERR_BAD_OPCODE);
            break;
        }

        if (cq_w0_fence(w0))
            drain_dma_wb();
        if (cq_w0_irq(w0))
            csr_write(CSR_CQ_EVENT, CQ_EVENT_IRQ);

        csr_write(CSR_CQ_HEAD, (head + 1u) & (ring_size - 1u));
        if (cq_w0_last(w0)) {
            csr_write(CSR_CQ_EVENT, CQ_EVENT_IDLE);
            *mailbox = 1u;
        }
    }
}
