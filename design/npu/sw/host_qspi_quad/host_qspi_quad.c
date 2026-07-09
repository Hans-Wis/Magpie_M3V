/* gate_93 firmware (ADR-0071 D1): quad e2e — MODE.QUAD on, D-side reads
 * bit-exact, then CALL an XIP-resident routine (instruction fetch over quad).
 * Boot stays single-lane (imem) — quad cold boot is NOT claimed (ADR honesty). */
#include <stdint.h>

#define XIP_BASE       0x40000000u
#define CSR_MODE       0x41000000u
#define ROUTINE_ADDR   (XIP_BASE + 0x800u)
#define ROUTINE_MAGIC  0x51AD600Du

#define SHARED_BASE    0x80000000u
#define DONE_ADDR      (SHARED_BASE + 0xFF00u)
#define DONE_PASS      0x534F4350u
#define DONE_FAIL      0x534F4346u

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

int main(void)
{
    uint32_t i, v;

    store32(DONE_ADDR, 0u);

    /* 1. single-lane baseline */
    if (load32(XIP_BASE) != golden(0u)) fail(1u, load32(XIP_BASE));
    if (load32(XIP_BASE + 0x100u) != golden(0x100u)) fail(1u, 1u);

    /* 2/3. quad: same words bit-exact + a sequential warm streak */
    store32(CSR_MODE, 1u);
    if (load32(XIP_BASE) != golden(0u)) fail(2u, load32(XIP_BASE));
    if (load32(XIP_BASE + 0x100u) != golden(0x100u)) fail(2u, 1u);
    for (i = 0; i < 8; i++) {
        v = load32(XIP_BASE + 0x200u + i * 4u);
        if (v != golden(0x200u + i * 4u)) fail(3u, v);
    }

    /* 4. execute FROM flash in quad mode */
    v = ((uint32_t (*)(void))ROUTINE_ADDR)();
    if (v != ROUTINE_MAGIC) fail(4u, v);

    /* 5. back to single, still exact */
    store32(CSR_MODE, 0u);
    if (load32(XIP_BASE) != golden(0u)) fail(5u, load32(XIP_BASE));

    store32(DONE_ADDR, DONE_PASS);
    for (;;) { }
    return 0;
}
