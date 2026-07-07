#include "../include/command_descriptor.h"

#ifndef N_TILES
#define N_TILES 8u
#endif

#define CSR_ML_NTILES 0x84u
#define CSR_ML_GO     0x88u
#define CSR_ML_CFG    0x8Cu
#define CSR_ML_STATUS 0x90u

#define ML_STATUS_DONE 0x2u

static volatile uint32_t *const csr = (volatile uint32_t *)CQ_CORE_WINDOW_BASE;
static volatile uint32_t *const mailbox = (volatile uint32_t *)CQ_MAILBOX_BASE;

__attribute__((naked, section(".init"))) void _start(void)
{
    __asm__ volatile (
        "li   sp, 0x8000\n"
        "call main\n"
        "1: j 1b\n"
    );
}

static __attribute__((noinline)) uint32_t csr_read(uint32_t off)
{
    return csr[off >> 2];
}

static __attribute__((noinline)) void csr_write(uint32_t off, uint32_t value)
{
    csr[off >> 2] = value;
}

int main(void)
{
    csr_write(CSR_ML_CFG, 0u);
    csr_write(CSR_ML_NTILES, (uint32_t)N_TILES);
    csr_write(CSR_ML_GO, 1u);

    while ((csr_read(CSR_ML_STATUS) & ML_STATUS_DONE) == 0u)
        ;

    mailbox[0] = 1u;
    for (;;)
        ;
}
