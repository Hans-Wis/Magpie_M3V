/* gate_92 firmware (ADR-0071 D2): program/erase via QSPI CSR, self-checking.
 * Flash image = xip_img_p2.hex: w(o)=0x5EED0000+(o>>2); playground sectors
 * 0x1000/0x3000 get destroyed here, all goldens read outside them.
 * Stages land in DONE+4 on fail — a red names the failing step. */
#include <stdint.h>

#define XIP_BASE       0x40000000u
#define CSR_MODE       0x41000000u
#define CSR_PROG_CTRL  0x41000004u
#define CSR_PROG_ADDR  0x41000008u
#define CSR_PROG_LEN   0x4100000Cu
#define CSR_STATUS     0x41000010u
#define CSR_WBUF       0x41000100u

#define OP_PP 0u
#define OP_SE 1u
#define OP_CE 3u
#define START (1u << 8)

#define SHARED_BASE    0x80000000u
#define DONE_ADDR      (SHARED_BASE + 0xFF00u)
#define DONE_PASS      0x534F4350u
#define DONE_FAIL      0x534F4346u
#define FLAG_COLDMARK  (SHARED_BASE + 0xFE30u)  /* TB samples cold counters */

static inline void store32(uint32_t a, uint32_t d) { *(volatile uint32_t *)a = d; }
static inline uint32_t load32(uint32_t a) { return *(volatile uint32_t *)a; }

static uint32_t golden(uint32_t off) { return 0x5EED0000u + (off >> 2); }

static void fail(uint32_t stage, uint32_t evidence)
{
    store32(DONE_ADDR + 4u, stage);
    store32(DONE_ADDR + 8u, evidence);
    store32(DONE_ADDR, DONE_FAIL);
    for (;;) { }
}

/* Returns the STATUS value of the FIRST read observing busy==0 — done(bit1)
 * is read-clear, so that same read is the only place the sticky can be seen. */
static uint32_t wait_idle_collect(uint32_t stage, uint32_t *busy_seen)
{
    uint32_t i, st;
    for (i = 0; i < 200000u; i++) {
        st = load32(CSR_STATUS);
        if (st & 1u) *busy_seen = 1u;
        else return st;
    }
    fail(stage, 0xDEADu);
    return 0u;
}

static void kick(uint32_t op, uint32_t addr, uint32_t len)
{
    store32(CSR_PROG_ADDR, addr);
    store32(CSR_PROG_LEN, len);
    store32(CSR_PROG_CTRL, START | op);
}

int main(void)
{
    uint32_t busy_seen, v, i;

    store32(DONE_ADDR, 0u);
    store32(FLAG_COLDMARK, 0u);

    /* 1. pre-image golden */
    if (load32(XIP_BASE + 0x1000u) != golden(0x1000u)) fail(1u, load32(XIP_BASE + 0x1000u));

    /* 2/3. SE @0x1000 -> busy seen, sector 0xFF, outside intact */
    busy_seen = 0u;
    kick(OP_SE, 0x1000u, 0u);
    v = wait_idle_collect(2u, &busy_seen);
    if (!busy_seen) fail(2u, 0u);
    for (i = 0; i < 3; i++)
        if (load32(XIP_BASE + 0x1000u + i * 4u) != 0xFFFFFFFFu) fail(3u, i);
    if (load32(XIP_BASE + 0x0u) != golden(0u)) fail(3u, 0xAAu);

    /* 4. done was set on the busy==0 read (v) and that read cleared it */
    if ((v & 2u) == 0u) fail(4u, v);
    v = load32(CSR_STATUS);
    if ((v & 2u) != 0u) fail(4u, 0x100u | v);

    /* 5. WBUF + PP 16B @0x1000, readback (cold-mark for TB around first read) */
    for (i = 0; i < 4; i++)
        store32(CSR_WBUF + i * 4u, 0xC0DE0000u + i);
    store32(FLAG_COLDMARK, 1u);
    kick(OP_PP, 0x1000u, 16u);
    busy_seen = 0u;
    wait_idle_collect(5u, &busy_seen);
    for (i = 0; i < 4; i++) {
        v = load32(XIP_BASE + 0x1000u + i * 4u);
        if (v != 0xC0DE0000u + i) fail(5u, v);
    }
    store32(FLAG_COLDMARK, 2u);

    /* 6. AND semantics: re-PP without erase */
    for (i = 0; i < 4; i++)
        store32(CSR_WBUF + i * 4u, 0xFF00FF00u);
    kick(OP_PP, 0x1000u, 16u);
    busy_seen = 0u;
    wait_idle_collect(6u, &busy_seen);
    for (i = 0; i < 4; i++) {
        v = load32(XIP_BASE + 0x1000u + i * 4u);
        if (v != ((0xC0DE0000u + i) & 0xFF00FF00u)) fail(6u, v);
    }

    /* 7. serialization: SE @0x3000 then immediate XIP read stalls, data exact */
    kick(OP_SE, 0x3000u, 0u);
    if (load32(XIP_BASE + 0x0u) != golden(0u)) fail(7u, 0u);
    if ((load32(CSR_STATUS) & 1u) != 0u) fail(7u, 1u);   /* read completed after prog */

    /* 8. busy-start ignored: SE @0x3000 again, CE start during busy -> no CE */
    kick(OP_SE, 0x3000u, 0u);
    store32(CSR_PROG_CTRL, START | OP_CE);
    busy_seen = 0u;
    wait_idle_collect(8u, &busy_seen);
    if (load32(XIP_BASE + 0x0u) != golden(0u)) fail(8u, load32(XIP_BASE + 0x0u));

    /* 9. MODE write during busy defers to idle; quad readback then back */
    kick(OP_SE, 0x3000u, 0u);
    store32(CSR_MODE, 1u);
    busy_seen = 0u;
    wait_idle_collect(9u, &busy_seen);
    if (load32(XIP_BASE + 0x0u) != golden(0u)) fail(9u, 0u);       /* quad read */
    if (load32(XIP_BASE + 0x100u) != golden(0x100u)) fail(9u, 1u);
    store32(CSR_MODE, 0u);
    if (load32(XIP_BASE + 0x0u) != golden(0u)) fail(9u, 2u);       /* single again */

    store32(DONE_ADDR, DONE_PASS);
    for (;;) { }
    return 0;
}
