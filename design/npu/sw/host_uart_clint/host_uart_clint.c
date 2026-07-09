#include <stdint.h>

#define UART_BASE        0x10000000u
#define UART_THR         (UART_BASE + 0x00u)
#define UART_IER         (UART_BASE + 0x04u)
#define UART_LSR         (UART_BASE + 0x14u)
#define UART_LSR_THRE    (1u << 5)
#define UART_IER_THRE    (1u << 1)

#define CLINT_BASE       0x02000000u
#define CLINT_MSIP       (CLINT_BASE + 0x0000u)
#define CLINT_MTIMECMP_L (CLINT_BASE + 0x4000u)
#define CLINT_MTIMECMP_H (CLINT_BASE + 0x4004u)
#define CLINT_MTIME_L    (CLINT_BASE + 0xBFF8u)
#define CLINT_MTIME_H    (CLINT_BASE + 0xBFFCu)

#define PLIC_BASE        0x0C000000u
#define PLIC_PRIO_UART   (PLIC_BASE + 0x00000008u)  /* UART = PLIC ID 2 (NPU keeps ID 1) */
#define PLIC_ENABLE      (PLIC_BASE + 0x00002000u)
#define PLIC_THRESHOLD   (PLIC_BASE + 0x00200000u)

#define SHARED_BASE      0x80000000u
#define FLAG_BASE        (SHARED_BASE + 0x0000FE00u)
#define FLAG_MIP_INIT    (FLAG_BASE + 0x00u)
#define FLAG_EXT_IRQ     (FLAG_BASE + 0x04u)
#define FLAG_TIMER_IRQ   (FLAG_BASE + 0x08u)
#define FLAG_SOFT_IRQ    (FLAG_BASE + 0x0Cu)
#define FLAG_ERROR       (FLAG_BASE + 0x10u)
#define DONE_ADDR        (SHARED_BASE + 0x0000FF00u)
#define DONE_PASS        0xC0DE0087u
#define DONE_FAIL        0xBAD00087u

#define MSTATUS_MIE      (1u << 3)
#define MIE_MSIE         (1u << 3)
#define MIE_MTIE         (1u << 7)
#define MIE_MEIE         (1u << 11)
#define MIP_MSIP         (1u << 3)
#define MIP_MTIP         (1u << 7)

extern void trap_entry(void);
extern void arm_soft_and_wait(void);

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

static inline uint32_t read_mip(void)
{
    uint32_t value;
    __asm__ volatile ("csrr %0, mip" : "=r"(value));
    return value;
}

static inline void write_mtvec(uint32_t value)
{
    __asm__ volatile ("csrw mtvec, %0" :: "r"(value) : "memory");
}

static inline void set_mie(uint32_t mask)
{
    __asm__ volatile ("csrs mie, %0" :: "r"(mask) : "memory");
}

static inline void clear_mie(uint32_t mask)
{
    __asm__ volatile ("csrc mie, %0" :: "r"(mask) : "memory");
}

static inline void set_mstatus(uint32_t mask)
{
    __asm__ volatile ("csrs mstatus, %0" :: "r"(mask) : "memory");
}

static void fail(uint32_t stage, uint32_t evidence)
{
    store32(FLAG_ERROR, (stage << 16) | (evidence & 0xFFFFu));
    store32(DONE_ADDR + 4u, stage);
    store32(DONE_ADDR + 8u, evidence);
    store32(DONE_ADDR, DONE_FAIL);
    for (;;) { }
}

static void uart_putc(uint8_t ch)
{
    while ((load32(UART_LSR) & UART_LSR_THRE) == 0u) { }
    store32(UART_THR, (uint32_t)ch);
}

static void wait_flag(uint32_t addr, uint32_t value)
{
    while (load32(addr) != value) { }
}

static uint64_t read_mtime(void)
{
    uint32_t hi0;
    uint32_t hi1;
    uint32_t lo;

    do {
        hi0 = load32(CLINT_MTIME_H);
        lo = load32(CLINT_MTIME_L);
        hi1 = load32(CLINT_MTIME_H);
    } while (hi0 != hi1);

    return (((uint64_t)hi1) << 32) | lo;
}

static void write_mtimecmp(uint64_t value)
{
    store32(CLINT_MTIMECMP_H, 0xFFFFFFFFu);
    store32(CLINT_MTIMECMP_L, (uint32_t)value);
    store32(CLINT_MTIMECMP_H, (uint32_t)(value >> 32));
}

int main(void)
{
    uint32_t mip0;
    uint64_t now;

    store32(FLAG_MIP_INIT, 0u);
    store32(FLAG_EXT_IRQ, 0u);
    store32(FLAG_TIMER_IRQ, 0u);
    store32(FLAG_SOFT_IRQ, 0u);
    store32(FLAG_ERROR, 0u);
    store32(DONE_ADDR, 0u);

    write_mtvec((uint32_t)trap_entry);

    mip0 = read_mip();
    store32(FLAG_MIP_INIT, mip0);
    if ((mip0 & (MIP_MTIP | MIP_MSIP)) != 0u)
        fail(1u, mip0);

    uart_putc('M');
    uart_putc('3');
    uart_putc('V');
    uart_putc('\n');

    store32(PLIC_PRIO_UART, 1u);
    store32(PLIC_ENABLE, 2u);   /* enable bit1 = ID 2 (UART); bit0 = ID 1 (NPU) untouched */
    store32(PLIC_THRESHOLD, 0u);
    set_mie(MIE_MEIE);
    set_mstatus(MSTATUS_MIE);
    store32(UART_IER, UART_IER_THRE);
    uart_putc('!');
    wait_flag(FLAG_EXT_IRQ, 2u);   /* handler stores PLIC claim id; UART = ID 2 */

    now = read_mtime();
    write_mtimecmp(now + 64u);
    set_mie(MIE_MTIE);
    wait_flag(FLAG_TIMER_IRQ, 1u);
    clear_mie(MIE_MTIE);

    arm_soft_and_wait();

    fence_all();
    store32(DONE_ADDR, DONE_PASS);
    for (;;) { }
    return 0;
}
