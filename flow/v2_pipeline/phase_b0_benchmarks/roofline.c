/* Magpie_M1 GEMV/bandwidth roofline microkernels (Phase 0, M1A evaluation).
 * Measures, cycle-exact via rdcycle:
 *   1) loadstream : sustained lw rate (bytes/cycle)        -> memory roofline
 *   2) macstream  : scalar int32 MAC rate (MAC/cycle)      -> mul.v 2-cycle cost
 *   3) gemv_i8    : int8 dot-product C kernel (cycles/MAC) -> the LLM GEMV baseline
 * Output via MMIO putchar (same bench TB). Ends with ebreak (crt0).
 */

typedef unsigned int u32;

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

#define N 8192                 /* 32KB int32 buffer */
static u32 buf[N];
static signed char a8[4096], w8[4096];

int main(void)
{
    u32 t0, t1, i;
    volatile u32 sink = 0;

    for (i = 0; i < N; i++) buf[i] = i * 2654435761u;
    for (i = 0; i < 4096; i++) { a8[i] = (signed char)(i * 7); w8[i] = (signed char)(i * 13 + 5); }

    /* 1) loadstream: 8x unrolled lw; 32 bytes per iteration */
    {
        u32 s0 = 0, s1 = 0, s2 = 0, s3 = 0;
        const u32 *p = buf;
        t0 = rdcycle();
        for (i = 0; i < N / 8; i++) {
            s0 += p[0]; s1 += p[1]; s2 += p[2]; s3 += p[3];
            s0 += p[4]; s1 += p[5]; s2 += p[6]; s3 += p[7];
            p += 8;
        }
        t1 = rdcycle();
        sink += s0 + s1 + s2 + s3;
        puts_mmio("LOADSTREAM bytes="); putu(N * 4);
        puts_mmio(" cycles="); putu(t1 - t0); puts_mmio("\n");
    }

    /* 2) macstream: 8x unrolled independent int32 MACs (mul + add) */
    {
        u32 acc0 = 1, acc1 = 2, acc2 = 3, acc3 = 4;
        u32 x = 0x12345678, y = 0x9abcdef0;
        t0 = rdcycle();
        for (i = 0; i < 4096; i++) {
            acc0 += x * y;  x += 17;
            acc1 += x * y;  y += 29;
            acc2 += x * y;  x += 31;
            acc3 += x * y;  y += 37;
            acc0 += x * y;  x += 41;
            acc1 += x * y;  y += 43;
            acc2 += x * y;  x += 47;
            acc3 += x * y;  y += 53;
        }
        t1 = rdcycle();
        sink += acc0 + acc1 + acc2 + acc3;
        puts_mmio("MACSTREAM macs="); putu(4096 * 8);
        puts_mmio(" cycles="); putu(t1 - t0); puts_mmio("\n");
    }

    /* 3) gemv_i8: plain C int8 dot product (the scalar LLM GEMV inner loop) */
    {
        int acc = 0;
        t0 = rdcycle();
        for (i = 0; i < 4096; i++) acc += (int)a8[i] * (int)w8[i];
        t1 = rdcycle();
        sink += (u32)acc;
        puts_mmio("GEMV_I8 macs="); putu(4096);
        puts_mmio(" cycles="); putu(t1 - t0); puts_mmio("\n");
    }

    puts_mmio("ROOFLINE DONE sink="); putu(sink); puts_mmio("\n");
    return 0;
}
