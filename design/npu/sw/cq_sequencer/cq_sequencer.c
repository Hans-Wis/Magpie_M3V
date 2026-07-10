#include "../include/command_descriptor.h"
#include <riscv_vector.h>   /* ADR-0062 perf: Zve32x on the EN_RVV=1 sequencer core */

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
#define MAT_OUT_B_DEFAULT 0x800u
#define CSR_ERR_PC      0x80u
#define MAT_ST_BUSY     1u
#define MAT_ST_DONE     2u
#define MAT_ST_ERR      4u
#define MAT_CMD_CLR     0u
#define MAT_CMD_LOADACC 3u
#define MAT_CMD_RESCALE_PC 4u
#define MAT_CMD_LOADVEC 5u
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

/* 64-bit variable shifts (S1 rsqrt/requant) call these libgcc DImode helpers, which
 * -nostdlib omits. Implement them freestanding via 32-bit halves only (little-endian
 * RISC-V), so they compile to hardware sll/srl/sra with no recursive DImode call. GCC's
 * calling convention: DItype (long long) value, SItype (int) shift count in [0,63]. */
typedef union { long long ll; struct { unsigned int lo, hi; } s; } u_dw;

long long __ashldi3(long long v, int b)
{
    u_dw w; w.ll = v;
    if (b == 0) return v;
    if (b >= 32) { w.s.hi = w.s.lo << (b - 32); w.s.lo = 0u; }
    else { w.s.hi = (w.s.hi << b) | (w.s.lo >> (32 - b)); w.s.lo <<= b; }
    return w.ll;
}

long long __lshrdi3(long long v, int b)
{
    u_dw w; w.ll = v;
    if (b == 0) return v;
    if (b >= 32) { w.s.lo = w.s.hi >> (b - 32); w.s.hi = 0u; }
    else { w.s.lo = (w.s.lo >> b) | (w.s.hi << (32 - b)); w.s.hi >>= b; }
    return w.ll;
}

long long __ashrdi3(long long v, int b)
{
    u_dw w; w.ll = v;
    int hi = (int)w.s.hi;                 /* signed high word -> arithmetic shift */
    if (b == 0) return v;
    if (b >= 32) { w.s.lo = (unsigned int)(hi >> (b - 32)); w.s.hi = (unsigned int)(hi >> 31); }
    else { w.s.lo = (w.s.lo >> b) | ((unsigned int)hi << (32 - b)); w.s.hi = (unsigned int)(hi >> b); }
    return w.ll;
}

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
        "li   t0, 0x200\n"         /* mstatus.VS = Initial: enable the Zve32x vexu (perf) */
        "csrs mstatus, t0\n"
        "li   sp, 0x8000\n"        /* stack at top of DTCM (32KB), grows down away from the
                                    * weight/blob region (was 0x0F00 = inside it) */
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

/* ADR-0062 S0: gemmlowp requant primitives for MAT_EWISE_MUL, bit-exact to
 * mat_golden.py / mat_engine.v (trunc toward zero for negative srdhm). */
static int32_t seq_srdhm(int32_t a, int32_t b)
{
    int64_t ab, s;
    if (a == (int32_t)0x80000000 && b == (int32_t)0x80000000)
        return 0x7FFFFFFF;
    ab = (int64_t)a * (int64_t)b;
    s = ab + ((ab >= 0) ? (1 << 30) : (1 - (1 << 30)));
    return (int32_t)(s / (int64_t)((int64_t)1 << 31));
}

static int32_t seq_rdbpot(int32_t x, int32_t exp)
{
    int32_t mask, rem, thr;
    if (exp <= 0)
        return x;
    mask = (int32_t)((1u << exp) - 1u);
    rem = x & mask;
    thr = (mask >> 1) + ((x < 0) ? 1 : 0);
    return (x >> exp) + ((rem > thr) ? 1 : 0);
}

/* ADR-0062 S1: fixed-point rsqrt (degree-3 mantissa polynomial), bit-exact to
 * gemma_quant_s1.rsqrt_q31. Coefficients arrive from the golden param blob (zero
 * firmware constants -> no golden/firmware drift). Returns rsqrt(arg_q/2^16) as
 * y_adj / 2^(31+sh); *sh_out may be negative for arg_real < 1. arg_q > 0. */
static int32_t rsqrt_q31(uint64_t arg_q, const int32_t *coeff, uint32_t inv_sqrt2,
                         int32_t *sh_out)
{
    uint64_t t = arg_q;
    int32_t p = -1;
    while (t) { p++; t >>= 1; }           /* p = bit_length(arg_q) - 1 */
    uint64_t norm = (p >= 47) ? (arg_q >> (p - 47)) : (arg_q << (47 - p));
    uint32_t f = (uint32_t)((norm >> 31) & 0xFFFFu);   /* 47 - 16 = 31; UQ0.16 fraction */
    int64_t acc = coeff[3];
    acc = (((acc * (int64_t)f) + (1 << 15)) >> 16) + coeff[2];
    acc = (((acc * (int64_t)f) + (1 << 15)) >> 16) + coeff[1];
    acc = (((acc * (int64_t)f) + (1 << 15)) >> 16) + coeff[0];
    int32_t y_adj = (int32_t)acc;          /* rsqrt(m) UQ0.31, m in [1,2) */
    int32_t e = p - 16;                    /* arg_real = m * 2^e */
    int32_t sh;
    if (e & 1) {                           /* odd (two's-complement & matches Python) */
        y_adj = (int32_t)(((int64_t)y_adj * (int64_t)inv_sqrt2 + (1 << 15)) >> 16);
        sh = (e - 1) >> 1;                 /* arithmetic >> floors (matches Python) */
    } else {
        sh = e >> 1;
    }
    *sh_out = sh;
    return y_adj;
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
        case CQ_OP_MAT_REQUANT_VEC: {
            uint32_t bank = cq_w0_acc(w0);
            uint32_t src = (w3 >> 16) & 0xFFFFu;
            uint32_t dst = w3 & 0xFFFFu;
            if (bank >= 4u || (src & 31u) != 0u ||
                src > (TCM_SCRATCH_B - 256u) || dst > (TCM_SCRATCH_B - 64u))
                cq_halt(CQ_ERR_MAT_PARAM);
            csr_write(CSR_MAT_A, src);
            mat_run(MAT_CMD_LOADVEC, bank, 1u);
            csr_write(CSR_MAT_MULT, w1);
            csr_write(CSR_MAT_RSP, (w2 >> 16) & 0xFFFFu);
            csr_write(CSR_MAT_CLAMP, w2 & 0xFFFFu);
            csr_write(CSR_MAT_OUT, dst);
            mat_run(MAT_CMD_RESCALE, bank, 1u);
            csr_write(CSR_MAT_OUT, MAT_OUT_B_DEFAULT);
            break;
        }
        case CQ_OP_MAT_ACT_LUT: {
            /* ADR-0062 S0: dst[i] = lut[(int8)src[i] + 128]. W1=src, W2=dst TCM
             * byte addrs; W3=256-entry int8 LUT byte addr; W0.RPT = len (<=255). */
            uint32_t len = cq_w0_rpt(w0);
            volatile int8_t *src = (volatile int8_t *)w1;
            volatile int8_t *dst = (volatile int8_t *)w2;
            volatile uint8_t *lut = (volatile uint8_t *)w3;
            uint32_t i;
            if (len == 0u)
                break;
            if (w1 > (TCM_SCRATCH_B - len) || w2 > (TCM_SCRATCH_B - len) ||
                w3 > (TCM_SCRATCH_B - 256u))
                cq_halt(CQ_ERR_MAT_PARAM);
            for (i = 0u; i < len; i++)
                dst[i] = (int8_t)lut[(uint8_t)((int32_t)src[i] + 128)];
            break;
        }
        case CQ_OP_MAT_EWISE_MUL: {
            /* ADR-0062 S0: dst[i] = clamp(rdbpot(srdhm(a[i]*b[i], mult), shift-31)).
             * W1=mult_q31; W2=(src_a<<16)|src_b; W3=(dst<<16)|shift; W0.RPT=len. */
            uint32_t len = cq_w0_rpt(w0);
            uint32_t src_a = (w2 >> 16) & 0xFFFFu;
            uint32_t src_b = w2 & 0xFFFFu;
            uint32_t dst = (w3 >> 16) & 0xFFFFu;
            uint32_t shift = w3 & 0xFFu;
            const signed char *pa = (const signed char *)src_a;
            const signed char *pb = (const signed char *)src_b;
            signed char *pd = (signed char *)dst;
            uint32_t i;
            int32_t S = (int32_t)shift - 31;
            size_t vl;
            if (len == 0u)
                break;
            if (src_a > (TCM_SCRATCH_B - len) || src_b > (TCM_SCRATCH_B - len) ||
                dst > (TCM_SCRATCH_B - len))
                cq_halt(CQ_ERR_MAT_PARAM);
            /* E1b (nonlinear_rvv_e1b_rope_design §2): scalar srdhm+rdbpot pair ->
             * Zve32x vsmul(rnu)+vssra(rnu) chain (Gemma-private rounding
             * redefinition; golden = gemma_quant.requant_rvv, flip 9/512 on the
             * gate corpus recorded). i8*i8 fits i16 exactly; qmul guarantees
             * shift-31 in [0,31]. */
            if (S < 0)
                S = 0;
            __asm__ volatile ("csrw vxrm, zero" ::: "memory");   /* rnu */
            for (i = 0u; i < len; i += vl) {
                vl = __riscv_vsetvl_e8mf4(len - i);
                vint16mf2_t p16 = __riscv_vwmul_vv_i16mf2(
                    __riscv_vle8_v_i8mf4(pa + i, vl),
                    __riscv_vle8_v_i8mf4(pb + i, vl), vl);
                vint32m1_t q = __riscv_vwcvt_x_x_v_i32m1(p16, vl);
                q = __riscv_vsmul_vx_i32m1(q, (int32_t)w1, vl);
                q = __riscv_vssra_vx_i32m1(q, (uint32_t)S, vl);
                q = __riscv_vmax_vx_i32m1(q, -128, vl);
                q = __riscv_vmin_vx_i32m1(q, 127, vl);
                __riscv_vse8_v_i8mf4(pd + i,
                    __riscv_vncvt_x_x_w_i8mf4(__riscv_vncvt_x_x_w_i16mf2(q, vl), vl), vl);
            }
            break;
        }
        case CQ_OP_MAT_RMSNORM: {
            /* ADR-0062 S1: one row of Gemma RMSNorm*(1+w) on the sequencer core.
             * W1=src, W2=dst TCM byte addrs; W3=32B-aligned param blob:
             *   [0]=SA2_Q [1]=OUT_NUM [2]=EPS_Q [3..6]=rsqrt coeffs [7]=INV_SQRT2_Q16,
             *   then H int16 (1+w) Q2.14 weights. W0.RPT = H. */
            uint32_t H = cq_w0_rpt(w0);
            const signed char *psrc = (const signed char *)w1;
            signed char *pdst = (signed char *)w2;
            volatile int32_t *ph = (volatile int32_t *)w3;
            const int16_t *wq = (const int16_t *)(w3 + 32u);
            uint32_t i;
            int32_t sum_sq;
            uint32_t mean_sq;
            uint64_t arg_q;
            int32_t coeff[4], y_adj, sh, M, S;
            uint32_t out_num, k;
            uint64_t P, Mu;
            size_t vl;
            if (H == 0u)
                break;
            if (w1 > (TCM_SCRATCH_B - H) || w2 > (TCM_SCRATCH_B - H) ||
                (w3 & 31u) != 0u || w3 > (TCM_SCRATCH_B - 32u - 2u * H))
                cq_halt(CQ_ERR_MAT_PARAM);
            coeff[0] = ph[3]; coeff[1] = ph[4]; coeff[2] = ph[5]; coeff[3] = ph[6];
            vint32m1_t vsum = __riscv_vmv_v_x_i32m1(0, __riscv_vsetvlmax_e32m1());
            for (i = 0u; i < H; i += vl) {
                vl = __riscv_vsetvl_e8mf4(H - i);
                vint8mf4_t x8 = __riscv_vle8_v_i8mf4(psrc + i, vl);
                vint16mf2_t sq16 = __riscv_vwmul_vv_i16mf2(x8, x8, vl);
                vsum = __riscv_vwadd_wv_i32m1(vsum, sq16, vl);
            }
            vint32m1_t z = __riscv_vmv_v_x_i32m1(0, 1);
            vsum = __riscv_vredsum_vs_i32m1_i32m1(vsum, z, __riscv_vsetvlmax_e32m1());
            sum_sq = __riscv_vmv_x_s_i32m1_i32(vsum);
            /* sum_sq <= H*127^2 <= 255*16129 < 2^22, so the row-mean divide is 32-bit
             * (hardware divu) — avoids a 64-bit __divdi3 and is exact (sum_sq >= 0). */
            mean_sq = (uint32_t)sum_sq / H;                     /* floor (sum_sq >= 0) */
            arg_q = (uint64_t)mean_sq * (uint32_t)ph[0] + (uint32_t)ph[2];  /* *SA2_Q + EPS_Q */
            y_adj = rsqrt_q31(arg_q, coeff, (uint32_t)ph[7], &sh);
            out_num = (uint32_t)ph[1];
            P = (uint64_t)(uint32_t)y_adj * (uint64_t)out_num;
            for (k = 0u; k < 64u; k++) {
                Mu = (k == 0u) ? P : ((P + (1ull << (k - 1u))) >> k);
                S = 30 + sh - (int32_t)k;
                if (Mu <= 0x7FFFFFFFull && S >= 0 && S <= 31)
                    break;
            }
            if (k == 64u)
                cq_halt(CQ_ERR_MAT_PARAM);
            M = (int32_t)Mu;
            __asm__ volatile ("csrw vxrm, zero" ::: "memory");   /* rnu for vsmul/vssra */
            for (i = 0u; i < H; i += vl) {
                vl = __riscv_vsetvl_e8mf4(H - i);
                vint16mf2_t x16 = __riscv_vwcvt_x_x_v_i16mf2(
                    __riscv_vle8_v_i8mf4(psrc + i, vl), vl);
                vint16mf2_t w16 = __riscv_vle16_v_i16mf2(wq + i, vl);
                vint32m1_t q = __riscv_vwmul_vv_i32m1(x16, w16, vl);
                q = __riscv_vsmul_vx_i32m1(q, M, vl);
                q = __riscv_vssra_vx_i32m1(q, (uint32_t)S, vl);
                q = __riscv_vmax_vx_i32m1(q, -128, vl);
                q = __riscv_vmin_vx_i32m1(q, 127, vl);
                __riscv_vse8_v_i8mf4(pdst + i,
                    __riscv_vncvt_x_x_w_i8mf4(__riscv_vncvt_x_x_w_i16mf2(q, vl), vl), vl);
            }
            break;
        }
        case CQ_OP_MAT_EWISE_ADD_REQUANT: {
            /* ADR-0062 S1: residual add. W1=(src_a<<16)|src_b, W2=dst; W3=param blob
             * [R_NUM, X_NUM, SHIFT]; W0.RPT=len. dst[i]=sat8((a*R_NUM+b*X_NUM+bias)>>SHIFT). */
            uint32_t len = cq_w0_rpt(w0);
            uint32_t src_a = (w1 >> 16) & 0xFFFFu;
            uint32_t src_b = w1 & 0xFFFFu;
            volatile int8_t *a = (volatile int8_t *)src_a;
            volatile int8_t *b = (volatile int8_t *)src_b;
            volatile int8_t *d = (volatile int8_t *)w2;
            volatile int32_t *ph = (volatile int32_t *)w3;
            const signed char *pa = (const signed char *)src_a;
            const signed char *pb = (const signed char *)src_b;
            signed char *pd = (signed char *)w2;
            int32_t r_num, x_num, vbias;
            uint32_t shift, i;
            size_t vl;
            if (len == 0u)
                break;
            if (src_a > (TCM_SCRATCH_B - len) || src_b > (TCM_SCRATCH_B - len) ||
                w2 > (TCM_SCRATCH_B - len) || (w3 & 3u) != 0u || w3 > (TCM_SCRATCH_B - 12u))
                cq_halt(CQ_ERR_MAT_PARAM);
            r_num = ph[0]; x_num = ph[1]; shift = (uint32_t)ph[2];
            /* ADR-0062 perf (RVV Cycle 1): a,b,acc all fit int32 (|a|,|b|<=127,
             * R/X_NUM ~ 2^16 -> acc ~ 2^24). vsra by the constant SHIFT is arithmetic
             * (floor) — bit-identical to the scalar (acc+bias)>>SHIFT; saturate then
             * narrow int32->int16->int8. Vectorized over the sequencer's Zve32x vexu. */
            /* vexu limits widening/narrowing/extension to dst LMUL<=m1 (B2 note), so the
             * vsext.vf4 / vncvt path runs at m1 (4 int32 lanes). */
            vbias = (shift > 0u) ? (1 << (shift - 1u)) : 0;
            for (i = 0u; i < len; i += vl) {
                vl = __riscv_vsetvl_e8mf4(len - i);
                vint16mf2_t a16 = __riscv_vwcvt_x_x_v_i16mf2(__riscv_vle8_v_i8mf4(pa + i, vl), vl);
                vint16mf2_t b16 = __riscv_vwcvt_x_x_v_i16mf2(__riscv_vle8_v_i8mf4(pb + i, vl), vl);
                vint32m1_t va = __riscv_vwcvt_x_x_v_i32m1(a16, vl);
                vint32m1_t vb = __riscv_vwcvt_x_x_v_i32m1(b16, vl);
                vint32m1_t acc = __riscv_vmul_vx_i32m1(va, r_num, vl);
                acc = __riscv_vmacc_vx_i32m1(acc, x_num, vb, vl);
                acc = __riscv_vadd_vx_i32m1(acc, vbias, vl);
                acc = __riscv_vsra_vx_i32m1(acc, shift, vl);
                acc = __riscv_vmax_vx_i32m1(acc, -128, vl);
                acc = __riscv_vmin_vx_i32m1(acc, 127, vl);
                __riscv_vse8_v_i8mf4(pd + i,
                    __riscv_vncvt_x_x_w_i8mf4(__riscv_vncvt_x_x_w_i16mf2(acc, vl), vl), vl);
            }
            break;
        }
        case CQ_OP_MAT_ROPE: {
            /* ADR-0062 S2: neox RoPE on one head-vector. W1=(src<<16)|dst; W2=table
             * (hd int16 cos Q15, then hd int16 sin Q15); W3=param [mult_q31, shift];
             * W0.RPT=hd. rot_i = -src[i+half] (i<half) else src[i-half]. */
            uint32_t hd = cq_w0_rpt(w0);
            uint32_t half = hd >> 1;
            uint32_t src = (w1 >> 16) & 0xFFFFu;
            uint32_t dst = w1 & 0xFFFFu;
            volatile int8_t *s = (volatile int8_t *)src;
            volatile int8_t *d = (volatile int8_t *)dst;
            volatile int16_t *cs = (volatile int16_t *)w2;
            volatile int16_t *sn = (volatile int16_t *)(w2 + 2u * hd);
            volatile int32_t *pp = (volatile int32_t *)w3;
            int32_t mult, shift;
            uint32_t i;
            if (hd == 0u)
                break;
            if (src > (TCM_SCRATCH_B - hd) || dst > (TCM_SCRATCH_B - hd) ||
                (w2 & 1u) != 0u || w2 > (TCM_SCRATCH_B - 4u * hd) ||
                (w3 & 3u) != 0u || w3 > (TCM_SCRATCH_B - 8u))
                cq_halt(CQ_ERR_MAT_PARAM);
            mult = pp[0]; shift = pp[1];
            /* RoPE RVV (nonlinear_rvv_e1b_rope_design §3): two unit-stride
             * segments kill the rotate-half shuffle (segment 1 subtracts the
             * +half partner, segment 2 adds the -half partner); the scalar
             * srdhm+rdbpot pair becomes vsmul(rnu)+vssra(rnu) — golden =
             * gemma_quant_s2.rope_int8, flip 0/256 on the probe corpus.
             * |s|<=127, |cs|,|sn|<=32767 -> two i16xi16 products sum < 2^24,
             * i32-safe. */
            {
                int32_t S = shift - 31;
                const signed char *ps = (const signed char *)src;
                signed char *pd2 = (signed char *)dst;
                const int16_t *pc = (const int16_t *)w2;
                const int16_t *pn = (const int16_t *)(w2 + 2u * hd);
                uint32_t seg, base;
                size_t vl;
                if (S < 0)
                    S = 0;
                __asm__ volatile ("csrw vxrm, zero" ::: "memory");   /* rnu */
                for (seg = 0u; seg < 2u; seg++) {
                    base = seg ? half : 0u;
                    const signed char *pr = seg ? ps : (ps + half);
                    uint32_t n = seg ? (hd - half) : half;
                    for (i = 0u; i < n; i += vl) {
                        vl = __riscv_vsetvl_e8mf4(n - i);
                        vint16mf2_t x16 = __riscv_vwcvt_x_x_v_i16mf2(
                            __riscv_vle8_v_i8mf4(ps + base + i, vl), vl);
                        vint16mf2_t r16 = __riscv_vwcvt_x_x_v_i16mf2(
                            __riscv_vle8_v_i8mf4(pr + i, vl), vl);
                        vint16mf2_t c16 = __riscv_vle16_v_i16mf2(pc + base + i, vl);
                        vint16mf2_t n16 = __riscv_vle16_v_i16mf2(pn + base + i, vl);
                        vint32m1_t acc = __riscv_vwmul_vv_i32m1(x16, c16, vl);
                        vint32m1_t rr = __riscv_vwmul_vv_i32m1(r16, n16, vl);
                        acc = seg ? __riscv_vadd_vv_i32m1(acc, rr, vl)
                                  : __riscv_vsub_vv_i32m1(acc, rr, vl);
                        acc = __riscv_vsmul_vx_i32m1(acc, mult, vl);
                        acc = __riscv_vssra_vx_i32m1(acc, (uint32_t)S, vl);
                        acc = __riscv_vmax_vx_i32m1(acc, -128, vl);
                        acc = __riscv_vmin_vx_i32m1(acc, 127, vl);
                        __riscv_vse8_v_i8mf4(pd2 + base + i,
                            __riscv_vncvt_x_x_w_i8mf4(
                                __riscv_vncvt_x_x_w_i16mf2(acc, vl), vl), vl);
                    }
                }
            }
            break;
        }
        case CQ_OP_MAT_SOFTMAX: {
            /* ADR-0062 S3: one attention-row softmax on the sequencer core. W1=(src<<16)|dst;
             * W2=256-entry uint16 EXP_LUT; W3=(valid<<16)|prob_scale; W0.RPT=n key positions.
             * dst[j<valid] = (EXP_LUT[mx-src[j]]*prob_scale + sm/2)/sm ; dst[j>=valid]=0. */
            uint32_t n = cq_w0_rpt(w0);
            uint32_t src = (w1 >> 16) & 0xFFFFu;
            uint32_t dst = w1 & 0xFFFFu;
            volatile int8_t *s = (volatile int8_t *)src;
            volatile int8_t *d = (volatile int8_t *)dst;
            volatile uint16_t *lut = (volatile uint16_t *)w2;
            uint32_t valid = (w3 >> 16) & 0xFFFFu;
            uint32_t prob_scale = w3 & 0xFFFFu;
            int32_t mx;
            uint32_t sm, i;
            if (n == 0u)
                break;
            if (src > (TCM_SCRATCH_B - n) || dst > (TCM_SCRATCH_B - n) ||
                (w2 & 1u) != 0u || w2 > (TCM_SCRATCH_B - 512u))
                cq_halt(CQ_ERR_MAT_PARAM);
            mx = -128;
            for (i = 0u; i < valid; i++) {
                int32_t v = s[i];
                if (v > mx) mx = v;
            }
            sm = 0u;
            for (i = 0u; i < valid; i++)
                sm += lut[mx - (int32_t)s[i]];
            for (i = 0u; i < n; i++) {
                if (i < valid) {
                    uint32_t e = lut[mx - (int32_t)s[i]];
                    d[i] = (int8_t)((e * prob_scale + (sm >> 1)) / sm);
                } else {
                    d[i] = 0;
                }
            }
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
