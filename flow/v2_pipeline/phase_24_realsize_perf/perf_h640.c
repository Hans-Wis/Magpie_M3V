/* phase_24 — real-size (Gemma-3 270M geometry) nonlinear-kernel microbench.
 * ddr_wall_step1_design.md §B: measure cyc/op at H=640-class sizes vs the
 * ~431k cyc/layer DDR streaming wall.
 *
 * KERNEL PROVENANCE (measurement copies — the shipped kernels live in
 * design/npu/sw/cq_sequencer/cq_sequencer.c; keep bodies verbatim):
 *   seq_srdhm/seq_rdbpot   cq_sequencer.c:200-219
 *   rsqrt_q31              cq_sequencer.c:225-248
 *   ewise_mul (scalar)     cq_sequencer.c:445-469 (CQ_OP_MAT_EWISE_MUL loop)
 *   rmsnorm (RVV chain)    cq_sequencer.c:471-535 (CQ_OP_MAT_RMSNORM)
 *   ewise_add (RVV)        cq_sequencer.c:537-581 (CQ_OP_MAT_EWISE_ADD_REQUANT)
 *   rope (scalar)          cq_sequencer.c:583-613 (CQ_OP_MAT_ROPE)
 *   softmax (scalar)       cq_sequencer.c:615-650 (CQ_OP_MAT_SOFTMAX)
 * Honest bounds: single-kernel timing (no CQ per-op orchestration tax, no DMA);
 * data resident in the 1-cycle bench memory (== TCM timing class). Sizes use
 * the repo's toy->real scaling (H 64->640, nh=4, hd 16->160, FFN 128->2048,
 * seq 4 -> {4,64,256}); rsqrt params are representative constants (timing is
 * data-independent through that path except bit_length, which we pin typical).
 */
#include <stdint.h>
#include <stddef.h>
#include <riscv_vector.h>

typedef unsigned int u32;

/* 64-bit shift helpers, verbatim from cq_sequencer.c:67-97 (no libgcc). */
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
    int hi = (int)w.s.hi;
    if (b == 0) return v;
    if (b >= 32) { w.s.lo = (unsigned int)(hi >> (b - 32)); w.s.hi = (unsigned int)(hi >> 31); }
    else { w.s.lo = (w.s.lo >> b) | ((unsigned int)hi << (32 - b)); w.s.hi = (unsigned int)(hi >> b); }
    return w.ll;
}

static inline u32 rdcycle(void)
{
    u32 v;
    __asm__ volatile("csrr %0, cycle" : "=r"(v));
    return v;
}

static void putc_mmio(char c) { *(volatile u32 *)0x10000000 = (unsigned char)c; }
static void puts_mmio(const char *s) { while (*s) putc_mmio(*s++); }
static void putu(u32 v)
{
    char b[12];
    int i = 0;
    if (!v) { putc_mmio('0'); return; }
    while (v) { b[i++] = '0' + (v % 10); v /= 10; }
    while (i) putc_mmio(b[--i]);
}

static void report(const char *name, u32 size, u32 cyc)
{
    puts_mmio("PERF ");
    puts_mmio(name);
    puts_mmio(" size=");
    putu(size);
    puts_mmio(" cyc=");
    putu(cyc);
    putc_mmio('\n');
}

/* ---- verbatim helper copies (cq_sequencer.c:200-248) ---- */
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

static int32_t rsqrt_q31(uint64_t arg_q, const int32_t *coeff, uint32_t inv_sqrt2,
                         int32_t *sh_out)
{
    uint64_t t = arg_q;
    int32_t p = -1;
    while (t) { p++; t >>= 1; }
    uint64_t norm = (p >= 47) ? (arg_q >> (p - 47)) : (arg_q << (47 - p));
    uint32_t f = (uint32_t)((norm >> 31) & 0xFFFFu);
    int64_t acc = coeff[3];
    acc = (((acc * (int64_t)f) + (1 << 15)) >> 16) + coeff[2];
    acc = (((acc * (int64_t)f) + (1 << 15)) >> 16) + coeff[1];
    acc = (((acc * (int64_t)f) + (1 << 15)) >> 16) + coeff[0];
    int32_t y_adj = (int32_t)acc;
    int32_t e = p - 16;
    if (e & 1) {
        y_adj = (int32_t)(((int64_t)y_adj * (int64_t)inv_sqrt2 + (1 << 15)) >> 16);
        e -= 1;
    }
    *sh_out = e >> 1;
    return y_adj;
}

/* ---- buffers (real-size) ---- */
#define MAXLEN 2048
static int8_t  buf_a[MAXLEN], buf_b[MAXLEN], buf_d[MAXLEN];
static int16_t wq_buf[640];
static int16_t rope_tab[2 * 160];
static uint16_t exp_lut[256];
static int32_t rms_params[8];

/* ---- kernels (verbatim loop bodies) ---- */
static void k_ewise_mul_scalar(u32 len, int32_t mult, int32_t shift)
{
    volatile int8_t *a = buf_a, *b = buf_b, *d = buf_d;
    u32 i;
    for (i = 0u; i < len; i++) {
        int32_t prod = (int32_t)a[i] * (int32_t)b[i];
        int32_t q = seq_rdbpot(seq_srdhm(prod, mult), shift - 31);
        if (q < -128) q = -128;
        if (q > 127)  q = 127;
        d[i] = (int8_t)q;
    }
}

/* E1b RVV version — verbatim mirror of the vectorized CQ_OP_MAT_EWISE_MUL
 * handler (cq_sequencer.c, post-E1b). */
static void k_ewise_mul_rvv(u32 len, int32_t mult, int32_t shift)
{
    const signed char *pa = (const signed char *)buf_a;
    const signed char *pb = (const signed char *)buf_b;
    signed char *pd = (signed char *)buf_d;
    int32_t S = shift - 31;
    u32 i;
    size_t vl;
    if (S < 0) S = 0;
    __asm__ volatile ("csrw vxrm, zero" ::: "memory");
    for (i = 0u; i < len; i += vl) {
        vl = __riscv_vsetvl_e8mf4(len - i);
        vint16mf2_t p16 = __riscv_vwmul_vv_i16mf2(
            __riscv_vle8_v_i8mf4(pa + i, vl),
            __riscv_vle8_v_i8mf4(pb + i, vl), vl);
        vint32m1_t q = __riscv_vwcvt_x_x_v_i32m1(p16, vl);
        q = __riscv_vsmul_vx_i32m1(q, mult, vl);
        q = __riscv_vssra_vx_i32m1(q, (uint32_t)S, vl);
        q = __riscv_vmax_vx_i32m1(q, -128, vl);
        q = __riscv_vmin_vx_i32m1(q, 127, vl);
        __riscv_vse8_v_i8mf4(pd + i,
            __riscv_vncvt_x_x_w_i8mf4(__riscv_vncvt_x_x_w_i16mf2(q, vl), vl), vl);
    }
}

static void k_rmsnorm_rvv(u32 H)
{
    const signed char *psrc = (const signed char *)buf_a;
    signed char *pdst = (signed char *)buf_d;
    volatile int32_t *ph = rms_params;
    const int16_t *wq = wq_buf;
    u32 i, k, out_num;
    int32_t sum_sq, coeff[4], y_adj, sh, M, S;
    uint32_t mean_sq;
    uint64_t arg_q, P, Mu;
    size_t vl;
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
    mean_sq = (uint32_t)sum_sq / H;
    arg_q = (uint64_t)mean_sq * (uint32_t)ph[0] + (uint32_t)ph[2];
    y_adj = rsqrt_q31(arg_q, coeff, (uint32_t)ph[7], &sh);
    out_num = (uint32_t)ph[1];
    P = (uint64_t)(uint32_t)y_adj * (uint64_t)out_num;
    for (k = 0u; k < 64u; k++) {
        Mu = (k == 0u) ? P : ((P + (1ull << (k - 1u))) >> k);
        S = 30 + sh - (int32_t)k;
        if (Mu <= 0x7FFFFFFFull && S >= 0 && S <= 31)
            break;
    }
    M = (int32_t)Mu;
    __asm__ volatile ("csrw vxrm, zero" ::: "memory");
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
}

static void k_ewise_add_rvv(u32 len, int32_t r_num, int32_t x_num, uint32_t shift)
{
    const signed char *pa = (const signed char *)buf_a;
    const signed char *pb = (const signed char *)buf_b;
    signed char *pd = (signed char *)buf_d;
    int32_t vbias = (shift > 0u) ? (1 << (shift - 1u)) : 0;
    u32 i;
    size_t vl;
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
}

static void k_rope_scalar(u32 hd, int32_t mult, int32_t shift)
{
    u32 half = hd >> 1;
    volatile int8_t *s = buf_a;
    volatile int8_t *d = buf_d;
    volatile int16_t *cs = rope_tab;
    volatile int16_t *sn = rope_tab + hd;
    u32 i;
    for (i = 0u; i < hd; i++) {
        int32_t rot = (i < half) ? -(int32_t)s[i + half] : (int32_t)s[i - half];
        int32_t acc = (int32_t)s[i] * cs[i] + rot * sn[i];
        int32_t q = seq_rdbpot(seq_srdhm(acc, mult), shift - 31);
        if (q < -128) q = -128;
        if (q > 127)  q = 127;
        d[i] = (int8_t)q;
    }
}

static void k_softmax_scalar(u32 n, u32 valid, u32 prob_scale)
{
    volatile int8_t *s = buf_a;
    volatile int8_t *d = buf_d;
    volatile uint16_t *lut = exp_lut;
    int32_t mx = -128;
    u32 sm = 0u, i;
    for (i = 0u; i < valid; i++) {
        int32_t v = s[i];
        if (v > mx) mx = v;
    }
    for (i = 0u; i < valid; i++)
        sm += lut[mx - (int32_t)s[i]];
    for (i = 0u; i < n; i++) {
        if (i < valid) {
            u32 e = lut[mx - (int32_t)s[i]];
            d[i] = (int8_t)((e * prob_scale + (sm >> 1)) / sm);
        } else {
            d[i] = 0;
        }
    }
}

#define MEASURE(name, size, call)            \
    do {                                     \
        u32 t0 = rdcycle();                  \
        call;                                \
        u32 t1 = rdcycle();                  \
        report(name, (size), t1 - t0);       \
    } while (0)

int main(void)
{
    u32 i;

    /* enable the Zve32x vexu before any vector instruction (mstatus.VS=Initial,
     * same idiom as cq_sequencer.c:121) */
    __asm__ volatile ("li t0, 0x200\ncsrs mstatus, t0" ::: "t0", "memory");

    for (i = 0; i < MAXLEN; i++) {
        buf_a[i] = (int8_t)(i * 7 + 3);
        buf_b[i] = (int8_t)(i * 13 + 5);
    }
    for (i = 0; i < 640; i++) wq_buf[i] = (int16_t)(16384 + (i & 255));
    for (i = 0; i < 160; i++) {
        rope_tab[i] = (int16_t)(30000 - i * 17);
        rope_tab[160 + i] = (int16_t)(i * 23 + 100);
    }
    for (i = 0; i < 256; i++) exp_lut[i] = (uint16_t)(65535u >> (i / 12));
    /* representative rsqrt params (S1 blob shape): SA2_Q / OUT_NUM / EPS_Q /
     * degree-3 coeffs / INV_SQRT2_Q16 — typical magnitudes so bit_length(arg_q)
     * lands in the production range. */
    rms_params[0] = 1 << 16;  rms_params[1] = 3 << 20;  rms_params[2] = 1 << 10;
    rms_params[3] = 0x5A827999; rms_params[4] = (int32_t)0xD2BEC333;
    rms_params[5] = 0x1E3779B9;  rms_params[6] = (int32_t)0xF7000000;
    rms_params[7] = 46341;

    puts_mmio("REALSIZE PERF START\n");

    MEASURE("rmsnorm_rvv", 640, k_rmsnorm_rvv(640));
    MEASURE("rmsnorm_rvv", 160, k_rmsnorm_rvv(160));      /* QK-norm per head */
    MEASURE("ewise_mul_scalar", 2048, k_ewise_mul_scalar(2048, 0x40000000, 40));
    MEASURE("ewise_mul_scalar", 640, k_ewise_mul_scalar(640, 0x40000000, 40));
    MEASURE("ewise_mul_rvv", 2048, k_ewise_mul_rvv(2048, 0x40000000, 40));
    MEASURE("ewise_mul_rvv", 640, k_ewise_mul_rvv(640, 0x40000000, 40));
    MEASURE("ewise_add_rvv", 640, k_ewise_add_rvv(640, 20000, 17000, 15));
    MEASURE("rope_scalar", 160, k_rope_scalar(160, 0x40000000, 40));
    MEASURE("softmax_scalar", 4, k_softmax_scalar(4, 4, 255));
    MEASURE("softmax_scalar", 64, k_softmax_scalar(64, 64, 255));
    MEASURE("softmax_scalar", 256, k_softmax_scalar(256, 256, 255));

    puts_mmio("REALSIZE PERF DONE\n");
    __asm__ volatile("ebreak");
    return 0;
}
