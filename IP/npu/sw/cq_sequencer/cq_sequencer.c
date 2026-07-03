#include "../include/command_descriptor.h"

#define CSR_BASE        CQ_CORE_WINDOW_BASE
#define MAILBOX_BASE    CQ_MAILBOX_BASE
#define TCM_SCRATCH_B   0x00000F00u
#define TCM_SCRATCH_W   (TCM_SCRATCH_B >> 2)
#define TCM_WEIGHT_B    0x00000400u
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

__attribute__((naked, section(".init"))) void _start(void)
{
    __asm__ volatile (
        "li sp, 0x0f00\n"
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
            dma_writeback(TCM_WEIGHT_W, w1, rows * cols);
            break;
        }
        case CQ_OP_MAT_ACC_CLR:
            acc_mask_latch = w1;
            break;
        case CQ_OP_MAT_FENCE:
            drain_dma_wb();
            break;
        case CQ_OP_MAT_OP:
        case CQ_OP_MAT_RESCALE:
            cq_halt(CQ_ERR_ENGINE_NOT_READY);
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
