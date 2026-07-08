#include <stdint.h>

#define NPU_BASE        0x30000000u
#define PLIC_BASE       0x0C000000u
#define SHARED_BASE     0x80000000u
#define DONE_ADDR       (SHARED_BASE + 0x0000FF00u)
#define IRQ_FLAG_ADDR   (SHARED_BASE + 0x0000FE00u)
#define IRQ_ID_ADDR     (SHARED_BASE + 0x0000FE04u)
#define IRQ_STATUS_ADDR (SHARED_BASE + 0x0000FE08u)
#define IRQ_CQST_ADDR   (SHARED_BASE + 0x0000FE0Cu)
#define DONE_PASS       0x534F4350u
#define DONE_FAIL       0x534F4346u

#define A_CTRL          (NPU_BASE + 0x04u)
#define A_STATUS        (NPU_BASE + 0x08u)
#define A_BASE          (NPU_BASE + 0x40u)
#define A_SIZE          (NPU_BASE + 0x44u)
#define A_TAIL          (NPU_BASE + 0x4Cu)
#define A_CQCTRL        (NPU_BASE + 0x50u)
#define A_CQST          (NPU_BASE + 0x54u)
#define A_ERRC          (NPU_BASE + 0x58u)

#define PLIC_PRIO_1     (PLIC_BASE + 0x00000004u)
#define PLIC_ENABLE     (PLIC_BASE + 0x00002000u)
#define PLIC_THRESHOLD  (PLIC_BASE + 0x00200000u)
#define PLIC_CLAIM      (PLIC_BASE + 0x00200004u)

extern void trap_entry(void);
extern void arm_tail_and_wait(void);

static inline void store32(uint32_t addr, uint32_t data)
{
    *(volatile uint32_t *)addr = data;
}

static inline uint32_t load32(uint32_t addr)
{
    return *(volatile uint32_t *)addr;
}

static inline void fence_all(void)
{
    __asm__ volatile ("fence iorw, iorw" ::: "memory");
}

static inline void write_mtvec(uint32_t value)
{
    __asm__ volatile ("csrw mtvec, %0" :: "r"(value) : "memory");
}

static inline void set_mie(uint32_t mask)
{
    __asm__ volatile ("csrs mie, %0" :: "r"(mask) : "memory");
}

#include "npu_fw_load.inc"

static inline uint32_t pack_a(uint32_t base)
{
    uint32_t w = 0;
    for (uint32_t j = 0; j < 4; j++) {
        uint32_t idx = base + j;
        w |= (((idx * 7u - 100u) & 0xFFu) << (8u * j));
    }
    return w;
}

static inline uint32_t pack_b(uint32_t base)
{
    uint32_t w = 0;
    for (uint32_t j = 0; j < 4; j++) {
        uint32_t idx = base + j;
        w |= (((idx * 5u - 60u) & 0xFFu) << (8u * j));
    }
    return w;
}

static void fail(uint32_t stage, uint32_t evidence)
{
    store32(DONE_ADDR + 4u, stage);
    store32(DONE_ADDR + 8u, evidence);
    store32(DONE_ADDR, DONE_FAIL);
    for (;;) { }
}

int main(void)
{
    uint32_t i;

    store32(IRQ_FLAG_ADDR, 0u);
    store32(IRQ_ID_ADDR, 0u);
    store32(IRQ_STATUS_ADDR, 0u);
    store32(IRQ_CQST_ADDR, 0u);

    write_mtvec((uint32_t)trap_entry);
    set_mie(1u << 11);

    store32(PLIC_PRIO_1, 1u);
    store32(PLIC_ENABLE, 1u);
    store32(PLIC_THRESHOLD, 0u);

    load_npu_firmware();

    for (i = 0; i < 8; i++)
        store32(0x30010700u + (i * 4u), pack_a(i * 4u));
    for (i = 0; i < 8; i++)
        store32(0x30010740u + (i * 4u), pack_b(i * 4u));

    store32(SHARED_BASE + 0x0400u, 0x00000001u);
    store32(SHARED_BASE + 0x0404u, 0x00080008u);
    store32(SHARED_BASE + 0x0408u, 32u);
    store32(SHARED_BASE + 0x040Cu, 0u);
    store32(SHARED_BASE + 0x0410u, 0x00000006u);
    store32(SHARED_BASE + 0x0414u, 1u);
    store32(SHARED_BASE + 0x0418u, 0u);
    store32(SHARED_BASE + 0x041Cu, 0u);
    store32(SHARED_BASE + 0x0420u, 0x00040003u);
    store32(SHARED_BASE + 0x0424u, 0x00000700u);
    store32(SHARED_BASE + 0x0428u, 0x00000740u);
    store32(SHARED_BASE + 0x042Cu, 0u);
    store32(SHARED_BASE + 0x0430u, 0x00000004u);
    store32(SHARED_BASE + 0x0434u, 0x54C4699Au);
    store32(SHARED_BASE + 0x0438u, 0x00008026u);
    store32(SHARED_BASE + 0x043Cu, 0x00007F80u);
    store32(SHARED_BASE + 0x0440u, 0x00005005u);
    store32(SHARED_BASE + 0x0444u, 0x00001800u);
    store32(SHARED_BASE + 0x0448u, 0x00000800u);
    store32(SHARED_BASE + 0x044Cu, 0x00000404u);

    fence_all();
    store32(A_BASE, 0x00000400u);
    store32(A_SIZE, 8u);
    store32(A_CQCTRL, 1u);
    store32(A_CTRL, 0x9u);
    arm_tail_and_wait();

    if (load32(IRQ_FLAG_ADDR) != 1u)
        fail(7u, load32(IRQ_FLAG_ADDR));
    if (load32(IRQ_ID_ADDR) != 1u)
        fail(8u, load32(IRQ_ID_ADDR));
    if ((load32(IRQ_STATUS_ADDR) & 0x2u) == 0u)
        fail(9u, load32(IRQ_STATUS_ADDR));
    if (load32(IRQ_CQST_ADDR) & 0x8u)
        fail(6u, load32(A_ERRC));

    (void)load32(SHARED_BASE + 0x1800u);
    store32(DONE_ADDR + 4u, load32(IRQ_STATUS_ADDR));
    store32(DONE_ADDR + 8u, load32(IRQ_CQST_ADDR));
    store32(DONE_ADDR, DONE_PASS);
    for (;;) { }
    return 0;
}
